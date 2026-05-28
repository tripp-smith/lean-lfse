import LFSE.Registry.Engine
import LFSE.Finance.Greeks
import LFSE.Finance.LSMC
import LFSE.LazyCore.Provenance

namespace LFSE
namespace Finance

structure EngineParams where
  paths : Nat := 10000
  seed : UInt64 := 42
  lsmc : LSMCConfig := {}
  deriving Repr, BEq

structure PricingEngineRef where
  key : String
  params : EngineParams := {}
  deriving Repr, BEq

namespace PricingEngineRef

def analytic : PricingEngineRef :=
  { key := "analytic" }

def monteCarlo (paths : Nat) (seed : UInt64) : PricingEngineRef :=
  { key := "monte-carlo", params := { paths := paths, seed := seed } }

def lsmc (cfg : LSMCConfig) : PricingEngineRef :=
  { key := "lsmc", params := { lsmc := cfg } }

end PricingEngineRef

abbrev PricingEngine := PricingEngineRef

namespace PricingEngine

def analytic : PricingEngine :=
  PricingEngineRef.analytic

def monteCarlo (paths : Nat) (seed : UInt64) : PricingEngine :=
  PricingEngineRef.monteCarlo paths seed

def lsmc (cfg : LSMCConfig) : PricingEngine :=
  PricingEngineRef.lsmc cfg

end PricingEngine

def Instrument.fields : Instrument -> Std.HashMap String Float
  | .forward _ strike maturity =>
      ({} : Std.HashMap String Float) |>.insert "strike" strike |>.insert "maturity" maturity
  | .option _ _ strike maturity volatility =>
      ({} : Std.HashMap String Float) |>.insert "strike" strike |>.insert "maturity" maturity |>.insert "volatility" volatility
  | .swap notional fixedRate floatRate maturity =>
      ({} : Std.HashMap String Float) |>.insert "notional" notional |>.insert "fixedRate" fixedRate |>.insert "floatRate" floatRate |>.insert "maturity" maturity
  | .basketOption _ weights strike maturity volatility =>
      ({} : Std.HashMap String Float) |>.insert "weightCount" weights.length.toFloat |>.insert "strike" strike |>.insert "maturity" maturity |>.insert "volatility" volatility
  | .creditDefaultSwap _ notional spread hazardRate recovery maturity =>
      ({} : Std.HashMap String Float) |>.insert "notional" notional |>.insert "spread" spread |>.insert "hazardRate" hazardRate |>.insert "recovery" recovery |>.insert "maturity" maturity
  | .exotic _ _ params =>
      params.foldl (fun m p => m.insert p.fst p.snd) {}

def Instrument.underlying? : Instrument -> Option String
  | .forward u .. => some u
  | .option _ u .. => some u
  | .exotic _ u .. => some u
  | _ => none

def Scenario.toPricingInput (scenario : Scenario) : Registry.PricingInput := {
  scenarioName := scenario.name,
  ctx := scenario.ctx,
  payoff := scenario.instrument.payoffNode 100,
  instrumentKey := scenario.instrument.registryName,
  fields := scenario.instrument.fields,
  text := toString (repr scenario.instrument)
}

def builtInAnalyticOnlyInstrumentKeys : List String :=
  ["put-option", "forward", "swap", "basket-option", "credit-default-swap"]

def monteCarloEngineEntry (params : EngineParams) : Registry.PricingEngineEntry := {
  descriptor := { kind := .engine, name := "monte-carlo", version := "2.1.0", description := "Registered deterministic Monte Carlo engine" },
  implementationKey := s!"lfse-finance.engine.monte-carlo.{params.paths}.{params.seed}",
  price := fun input => do
    if builtInAnalyticOnlyInstrumentKeys.contains input.instrumentKey then
      pure (.error (.unsupportedMonteCarlo s!"engine `monte-carlo` does not support instrument `{input.instrumentKey}`"))
    else if input.instrumentKey != "call-option" then
      let (res, _stats, trace) <- LazyCore.force input.ctx input.payoff
      pure <| res.map fun npv => {
        scenario := input.scenarioName,
        npv := npv,
        greeks := [("mc-delegated", npv)],
        trace := trace,
        lineage := LazyCore.exportLineage input.payoff
      }
    else
      match input.fields.get? "strike", input.fields.get? "maturity", input.fields.get? "volatility", input.ctx.lookup "spot.ACME", input.ctx.lookup "rate.usd" with
      | some strike, some maturity, some vol, .ok spot, .ok rate =>
          let npv <- monteCarloCall params.paths params.seed spot strike rate vol maturity
          pure (.ok {
            scenario := input.scenarioName,
            npv := npv,
            greeks := [("mc", npv)],
            lineage := LazyCore.exportLineage input.payoff
          })
      | _, _, _, .error err, _ => pure (.error err)
      | _, _, _, _, .error err => pure (.error err)
      | _, _, _, _, _ => pure (.error (.evaluationFailed "monte-carlo engine missing option fields"))
}

def lsmcEngineEntry (cfg : LSMCConfig) : Registry.PricingEngineEntry := {
  descriptor := { kind := .engine, name := "lsmc", version := "2.1.0", description := "Registered LSMC engine" },
  implementationKey := s!"lfse-finance.engine.lsmc.{cfg.paths}.{cfg.seed}",
  price := fun input => do
    if builtInAnalyticOnlyInstrumentKeys.contains input.instrumentKey then
      pure (.error (.unsupportedMonteCarlo s!"engine `lsmc` does not support instrument `{input.instrumentKey}`"))
    else if input.instrumentKey != "call-option" then
      let (res, _stats, trace) <- LazyCore.force input.ctx input.payoff
      pure <| res.map fun npv => {
        scenario := input.scenarioName,
        npv := npv,
        greeks := [("lsmc-delegated", npv)],
        trace := trace,
        lineage := LazyCore.exportLineage input.payoff
      }
    else
      match input.fields.get? "strike", input.fields.get? "maturity", input.fields.get? "volatility", input.ctx.lookup "spot.ACME", input.ctx.lookup "rate.usd" with
      | some strike, some maturity, some vol, .ok spot, .ok rate =>
          let npv <- priceBermudanCall cfg spot strike rate vol maturity
          pure (.ok { scenario := input.scenarioName, npv := npv, lineage := LazyCore.exportLineage input.payoff })
      | _, _, _, .error err, _ => pure (.error err)
      | _, _, _, _, .error err => pure (.error err)
      | _, _, _, _, _ => pure (.error (.evaluationFailed "lsmc engine missing option fields"))
}

def builtinRegistryFor (engine : PricingEngineRef) : LFSEExcept Registry := do
  let r <- Registry.defaultCore
  match engine.key with
  | "analytic" => pure r
  | "monte-carlo" => Registry.registerEngineEntry r (monteCarloEngineEntry engine.params)
  | "lsmc" => Registry.registerEngineEntry r (lsmcEngineEntry engine.params.lsmc)
  | other => .error (.registryError s!"unknown built-in engine `{other}`")

def forceWithEngineUsing (registry : Registry) (engine : PricingEngineRef) (scenario : Scenario) : IO (LFSEExcept Result) := do
  match Registry.lookupEngine registry engine.key with
  | .ok entry => entry.price scenario.toPricingInput
  | .error err => pure (.error err)

def forceWithEngine (scenario : Scenario) (engine : PricingEngineRef) : IO (LFSEExcept Result) := do
  match builtinRegistryFor engine with
  | .ok registry => forceWithEngineUsing registry engine scenario
  | .error err => pure (.error err)

end Finance

abbrev PricingEngine := Finance.PricingEngine
abbrev PricingEngineRef := Finance.PricingEngineRef
abbrev EngineParams := Finance.EngineParams
def forceWithEngine := Finance.forceWithEngine
def forceWithEngineUsing := Finance.forceWithEngineUsing

end LFSE
