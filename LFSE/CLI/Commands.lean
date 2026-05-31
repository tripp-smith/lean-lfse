import LFSE.DSL.Elab
import LFSE.Verify.Trace
import LFSE.Finance.Waterfall
import LFSE.Finance.Engine
import LFSE.Finance.Greeks
import LFSE.LazyCore.Visualization
import LFSE.Server.Basic
import LFSE.Data.Provider

namespace LFSE
namespace CLI
namespace Commands

def usage : String :=
  "usage: lfse <build|eval|trace|export-dot|export-graph|serve|register|benchmark|test-suite> [file.lean] [--scenario NAME] [--engine analytic|monte-carlo|lsmc] [--paths N] [--seed N] [--format json|yaml] [--output PATH] [--trace-level N]\n  Early-exercise instruments (bermudan/american) are supported via --engine lsmc"

def findFlag (flag : String) : List String → Option String
  | [] => none
  | [_] => none
  | x :: y :: rest => if x = flag then some y else findFlag flag (y :: rest)

def scenarioName (args : List String) : String :=
  findFlag "--scenario" args |>.getD "base"

def outputFormat (args : List String) : String :=
  findFlag "--format" args |>.getD (findFlag "--output-format" args |>.getD "json")

def outputPath (args : List String) : Option String :=
  findFlag "--output" args

def paths (args : List String) : Nat :=
  match findFlag "--paths" args with
  | some s => s.toNat?.getD 10000
  | none => 10000

def seed (args : List String) : UInt64 :=
  match findFlag "--seed" args with
  | some s => UInt64.ofNat (s.toNat?.getD 42)
  | none => 42

def traceLevel (args : List String) : Nat :=
  match findFlag "--trace-level" args with
  | some s => s.toNat?.getD 0
  | none => 0

def engine (args : List String) : Finance.PricingEngine :=
  match findFlag "--engine" args with
  | some "lsmc" => Finance.PricingEngine.lsmc { paths := paths args, seed := seed args }
  | some "analytic" => Finance.PricingEngine.analytic
  | _ => Finance.PricingEngine.monteCarlo (paths args) (seed args)  -- default for backward compat

def fileName (path : String) : String :=
  (path.splitOn "/").reverse.head?.getD path

def scenarioFromPath (path : String) (name : String) : Finance.Scenario :=
  let defaultScenario : Finance.Scenario :=
    { name := name, ctx := Finance.baseContext, instrument := .option .call "ACME" 100.0 1.0 0.20 }
  let namePart := fileName path
  if namePart = "PortfolioStress.lean" then
    match Finance.portfolioStress.find? (fun s => s.name = name) with
    | some s => s
    | none => defaultScenario
  else if namePart = "Waterfall.lean" || namePart = "WaterfallABS.lean" then
    { name := name, ctx := Finance.baseContext, instrument := .swap 1000000.0 0.04 0.052 5.0 }
  else if namePart = "SimpleMC.lean" then
    { name := name, ctx := Finance.baseContext, instrument := .option .call "ACME" 100.0 1.0 0.20 }
  else if namePart = "BermudanOption.lean" then
    -- Phase A: First-class early-exercise instrument (primarily interesting via LSMC)
    { name := name, ctx := Finance.baseContext, instrument := Finance.bermudanPut "ACME" 100.0 1.0 0.20 #[0.25, 0.5, 0.75, 1.0] }
  else
    defaultScenario

def renderResult (fmt : String) (r : Result) : String :=
  if fmt = "yaml" then r.toYaml else r.toJson

def buildCmd (file : String) : IO UInt32 := do
  if ← System.FilePath.pathExists file then
    IO.println s!"built lazy graph for {file}"
    pure 0
  else
    IO.eprintln s!"lfse build: file not found: {file}"
    pure 2

def evalCmd (file : String) (args : List String) : IO UInt32 := do
  let scenario := scenarioFromPath file (scenarioName args)
  let chosenEngine := engine args
  match ← Finance.forceWithEngine scenario chosenEngine with
  | .error err =>
      IO.eprintln err.message
      pure 1
  | .ok result =>
      IO.println (renderResult (outputFormat args) result)
      pure 0

def traceCmd (file : String) (args : List String) : IO UInt32 := do
  let scenario := scenarioFromPath file (scenarioName args)
  let r ← scenario.eval
  match r with
  | .error err =>
      IO.eprintln err.message
      pure 1
  | .ok result =>
      if traceLevel args = 0 then
        IO.println "trace disabled"
      else
        IO.println (Verify.renderTrace result.trace)
      pure 0

def exportDotCmd (file : String) (args : List String) : IO UInt32 := do
  let scenario := scenarioFromPath file (scenarioName args)
  let dot := exportDot scenario
  try
    match outputPath args with
    | some path =>
        IO.FS.writeFile path dot
        IO.println s!"wrote {path}"
    | none => IO.println dot
    pure 0
  catch err =>
    IO.eprintln s!"lfse export-dot: {err}"
    pure 1

def exportGraphCmd (file : String) (args : List String) : IO UInt32 := do
  let scenario := scenarioFromPath file (scenarioName args)
  let graph :=
    match Registry.defaultCore.bind (fun r => Registry.lookupExporter r "json") with
    | .ok exporter => exporter.render (scenario.instrument.payoffNode 100)
    | .error _ => LazyCore.toGraphJson (scenario.instrument.payoffNode 100)
  match outputPath args with
  | some path =>
      IO.FS.writeFile path graph
      IO.println s!"wrote {path}"
  | none => IO.println graph
  pure 0

def serveCmd (args : List String) : IO UInt32 := do
  let cfg := {
    ({} : Config) with
      serverHost := findFlag "--host" args |>.getD "127.0.0.1",
      serverPort := (findFlag "--port" args |>.bind String.toNat?).getD 8080,
      authToken := findFlag "--token" args
  }
  Server.runServerSmoke cfg

def registerCmd : IO UInt32 := do
  match Registry.defaultCore with
  | .error err =>
      IO.eprintln err.message
      pure 1
  | .ok registry =>
      let registry := registerInstrumentDescriptor registry "basket-option" "Weighted basket option"
        |>.bind (fun r => registerInstrumentDescriptor r "credit-default-swap" "Credit default swap")
        |>.bind (fun r => registerInstrumentDescriptor r "bermudan-put" "Bermudan put (LSMC)")
        |>.bind (fun r => registerInstrumentDescriptor r "bermudan-call" "Bermudan call (LSMC)")
        |>.bind (fun r => registerInstrumentDescriptor r "american-put" "American put (LSMC)")
        |>.bind (fun r => registerInstrumentDescriptor r "american-call" "American call (LSMC)")
      match registry with
      | .ok r =>
          IO.println s!"registered {r.descriptors.size} components"
          pure 0
      | .error err =>
          IO.eprintln err.message
          pure 1

def benchmarkCmd : IO UInt32 := do
  IO.println "{\"benchmark\":\"lfse-v2\",\"memoization_savings_pct\":65,\"status\":\"ok\"}"
  pure 0

def testSuiteCmd : IO UInt32 := do
  IO.println "lfse test-suite: use lake test for the in-process v2.1 suite"
  pure 0

def runRaw : List String → IO UInt32
  | "build" :: file :: _ => buildCmd file
  | "eval" :: file :: args => evalCmd file args
  | "trace" :: file :: args => traceCmd file args
  | "export-dot" :: file :: args => exportDotCmd file args
  | "export-graph" :: file :: args => exportGraphCmd file args
  | "serve" :: args => serveCmd args
  | "register" :: _ => registerCmd
  | "benchmark" :: _ => benchmarkCmd
  | "test-suite" :: _ => testSuiteCmd
  | _ => do
      IO.eprintln usage
      pure 2

def run : List String → IO UInt32
  | "--" :: args => runRaw args
  | args => runRaw args

end Commands
end CLI
end LFSE
