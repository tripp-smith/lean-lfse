import LFSE.DSL.Elab
import LFSE.Verify.Trace
import LFSE.Finance.Waterfall

namespace LFSE
namespace CLI
namespace Commands

def usage : String :=
  "usage: lfse <build|eval|trace|export-dot> <file.lean> [--scenario NAME] [--output json|yaml] [--paths N] [--seed N] [--trace-level N] [--output PATH]"

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
  let r ← scenario.eval
  match r with
  | .error err =>
      IO.eprintln err.message
      pure 1
  | .ok result =>
      let mcResult ← forceMonteCarlo (paths args) (seed args) scenario
      let result :=
        match mcResult with
        | .ok mc => { result with greeks := ("mc", mc) :: result.greeks }
        | .error _ => result
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

def runRaw : List String → IO UInt32
  | "build" :: file :: _ => buildCmd file
  | "eval" :: file :: args => evalCmd file args
  | "trace" :: file :: args => traceCmd file args
  | "export-dot" :: file :: args => exportDotCmd file args
  | _ => do
      IO.eprintln usage
      pure 2

def run : List String → IO UInt32
  | "--" :: args => runRaw args
  | args => runRaw args

end Commands
end CLI
end LFSE
