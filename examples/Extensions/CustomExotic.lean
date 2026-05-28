import LFSE

open LFSE

syntax "myExotic(" str ", " term ")" : term

macro_rules
  | `(myExotic($u:str, $m:term)) =>
      `(LFSE.Finance.Instrument.exotic "custom-exotic" $u [("multiplier", $m)])

def customDslSpec : DSL.ExtensionSpec := {
  name := "custom-exotic-dsl",
  moduleName := "examples.Extensions.CustomExotic",
  syntaxName := "myExotic",
  expandsTo := "Finance.Instrument.exotic",
  description := "Third-party-style custom exotic syntax"
}

def registryExample : LFSEExcept Registry := do
  let base <- Registry.defaultCore
  let base <- DSL.registerExtension base customDslSpec
  registerInstrument base ((Finance.Instrument.exotic "custom-exotic" "ACME" [("multiplier", 1.1)]).toRegistryEntry)

def customScenario : LazyScenario :=
  #scenario CustomExotic => myExotic("ACME", 1.1)

def customEngine : Registry.PricingEngineEntry := {
  descriptor := {
    kind := Registry.ComponentKind.engine,
    name := "custom-engine",
    version := "2.1.0",
    description := "Example engine supplied outside core finance"
  },
  implementationKey := "examples.custom-engine.v1",
  price := fun input => do
    let (res, _stats, trace) <- LazyCore.force input.ctx input.payoff
    pure <| res.map fun npv => {
      scenario := input.scenarioName,
      npv := npv + 1.0,
      trace := trace,
      lineage := LazyCore.exportLineage input.payoff
    }
}

def customEngineResult : IO (LFSEExcept Result) := do
  match registryExample.bind (fun r => registerEngine r customEngine) with
  | .ok registry => forceWithEngineUsing registry { key := "custom-engine" } customScenario
  | .error err => pure (.error err)

#eval forceNPV customScenario
#eval customEngineResult
#eval pure (registryExample.map (fun r => Registry.contains r .dslExtension "custom-exotic-dsl" && Registry.contains r .instrument "custom-exotic"))
