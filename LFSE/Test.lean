import LFSE

namespace LFSE
namespace Test

def approxEq (a b : Float) (eps : Float := 0.0001) : Bool :=
  Float.abs (a - b) <= eps

def approxRel (a b : Float) (eps : Float := 0.000001) : Bool :=
  let scale := max 1.0 (max (Float.abs a) (Float.abs b))
  Float.abs (a - b) <= eps * scale

def assert (label : String) (cond : Bool) : IO Unit :=
  unless cond do throw (IO.userError s!"assertion failed: {label}")

def assertOk (label : String) : LFSEExcept α → IO α
  | .ok value => pure value
  | .error err => throw (IO.userError s!"{label}: {err}")

def testLazySharing : IO Unit := do
  let counter ← IO.mkRef 0
  let shared : LazyCore.LazyNode := .effect 1 "counter" do
    counter.modify (· + 1)
    pure 5.0
  let graph := LazyCore.add 2 shared shared
  let (res, stats, _trace) ← LazyCore.force {} graph
  let value ← assertOk "lazy sharing" res
  let count ← counter.get
  assert "shared value" (approxEq value 10.0)
  assert "side effect forced once" (count == 1)
  assert "memo hit observed" (stats.memoHits >= 1)

def testCycleDetection : IO Unit := do
  let cyclic : LazyCore.LazyNode := .unary 7 "cycle" id (.const 7 "cycle" 1.0)
  let (res, _stats, _trace) ← LazyCore.force {} cyclic
  match res with
  | .error (.cycleDetected 7) => pure ()
  | other => throw (IO.userError s!"expected cycle error, got {repr other}")

def testFinance : IO Unit := do
  let scenario := scenarioOf "base" (.option .call "ACME" 100.0 1.0 0.20)
  let npv ← assertOk "forceNPV" (← forceNPV scenario)
  assert "option positive" (npv > 0.0)
  let shocked := Finance.shock scenario "spot.ACME" 10.0
  let shockedNpv ← assertOk "shock forceNPV" (← forceNPV shocked)
  assert "call monotonicity" (shockedNpv > npv)
  let payments := Finance.allocateWaterfall 100.0 [{ name := "A", balance := 1000.0, rate := 0.05 }, { name := "B", balance := 500.0, rate := 0.08 }]
  assert "waterfall conservation" (Finance.paymentsTotal payments <= 100.0)
  let remaining := Finance.remainingAfterWaterfall 100.0 [{ name := "A", balance := 1000.0, rate := 0.05 }, { name := "B", balance := 500.0, rate := 0.08 }]
  assert "waterfall cash conserved with residual" (approxEq (Finance.paymentsTotal payments + remaining) 100.0)

def testDiscountFormula : IO Unit := do
  let ctx := ({} : Context) |>.withMarket "spot.ACME" 110.0 |>.withMarket "rate.usd" 0.05
  let scenario := { name := "forward", ctx := ctx, instrument := Finance.Instrument.forward "ACME" 100.0 1.0 }
  let npv ← assertOk "forward discounted npv" (← forceNPV scenario)
  let expected := (110.0 - 100.0) * Float.exp (-0.05)
  assert "forward discount formula" (approxRel npv expected)

def testExerciseBackwardInduction : IO Unit := do
  let value := Finance.optimalExercise [
    { continuation := 1.0, immediate := 2.0 },
    { continuation := 3.0, immediate := 1.0 }
  ]
  assert "exercise propagates continuation" (approxEq value 4.0)

def testMonteCarlo : IO Unit := do
  let a ← Finance.monteCarloCall 100 42 100.0 100.0 0.05 0.20 1.0
  let b ← Finance.monteCarloCall 100 42 100.0 100.0 0.05 0.20 1.0
  let c ← Finance.monteCarloCall 100 43 100.0 100.0 0.05 0.20 1.0
  assert "fixed seed reproducible" (approxRel a b)
  assert "different seed changes sample" (a != c)

def testForceMonteCarloErrors : IO Unit := do
  let putScenario := scenarioOf "put" (.option .put "ACME" 100.0 1.0 0.20)
  match ← forceMonteCarlo 100 42 putScenario with
  | .error (.unsupportedMonteCarlo "engine `monte-carlo` does not support instrument `put-option`") => pure ()
  | other => throw (IO.userError s!"expected unsupported put MC, got {repr other}")
  let missingMarket := { name := "missing", ctx := {}, instrument := Finance.Instrument.option .call "ACME" 100.0 1.0 0.20 }
  match ← forceMonteCarlo 100 42 missingMarket with
  | .error (.missingObservable "spot.ACME") => pure ()
  | other => throw (IO.userError s!"expected missing spot MC, got {repr other}")

def testData : IO Unit := do
  let market ← assertOk "market parse" (Data.loadCsvLikeMarket "spot.ACME,101.5\nrate.usd,0.05\n")
  let ctx := market.toContext
  let spot ← assertOk "spot lookup" (ctx.lookup "spot.ACME")
  assert "parsed spot" (approxEq spot 101.5)
  let expectedEscape := "\"" ++ "line" ++ "\\u0001" ++ "break" ++ "\""
  let controlString := "line" ++ String.singleton (Char.ofNat 1) ++ "break"
  assert "json control escape" (escapeJson controlString == expectedEscape)

def testDSL : IO Unit := do
  let s := #scenario Demo => callOption("ACME", 100.0, 1.0, 0.20)
  let npv ← assertOk "dsl npv" (← forceNPV s)
  assert "dsl scenario" (s.name = "Demo")
  assert "dsl npv positive" (npv > 0.0)

def testRealisticSyntheticPortfolio : IO Unit := do
  let base ← assertOk "base stress grid" (← Finance.Synthetic.reportScenario
    "base" Finance.Synthetic.realisticMarket Finance.Synthetic.multiAssetPortfolio)
  let recession ← assertOk "recession stress grid" (← Finance.Synthetic.reportScenario
    "recession" Finance.Synthetic.recessionMarket Finance.Synthetic.multiAssetPortfolio)
  let inflation ← assertOk "inflation stress grid" (← Finance.Synthetic.reportScenario
    "inflation" Finance.Synthetic.inflationShockMarket Finance.Synthetic.multiAssetPortfolio)
  assert "base portfolio nonzero" (base.npv != 0.0)
  assert "recession changes valuation" (recession.npv != base.npv)
  assert "inflation changes valuation" (inflation.npv != base.npv)
  assert "trace count proxy populated" (base.traceNodes > 0)

def testStressGridReports : IO Unit := do
  let reports ← assertOk "stress grid" (← Finance.Synthetic.runStressGrid)
  assert "four macro regimes" (reports.length == 4)
  assert "base regime present" (reports.any (fun r => r.name = "base"))
  assert "credit regime present" (reports.any (fun r => r.name = "credit-tightening"))

def testAbsWaterfallScenarios : IO Unit := do
  let base := Finance.Synthetic.absBasePayments
  let stress := Finance.Synthetic.absStressPayments
  assert "base pays at least stress" (Finance.paymentsTotal base >= Finance.paymentsTotal stress)
  assert "cash cap base" (Finance.paymentsTotal base <= Finance.Synthetic.monthlyAbsCashflowBase)
  assert "cash cap stress" (Finance.paymentsTotal stress <= Finance.Synthetic.monthlyAbsCashflowStress)

def testMonteCarloRiskReport : IO Unit := do
  let (base, recession) ← assertOk "risk report" (← Finance.Synthetic.mcRiskReport 500 20260516)
  let (baseAgain, recessionAgain) ← assertOk "risk report repeat" (← Finance.Synthetic.mcRiskReport 500 20260516)
  assert "base MC reproducible" (approxRel base baseAgain)
  assert "recession MC reproducible" (approxRel recession recessionAgain)
  assert "macro regimes differ" (base != recession)

def testDuplicateNodeIdDetection : IO Unit := do
  let graph := LazyCore.add 3 (.const 1 "left" 1.0) (.const 1 "right" 2.0)
  let (res, _stats, _trace) ← LazyCore.force {} graph
  match res with
  | .error (.duplicateNodeId 1 "left" "right") => pure ()
  | other => throw (IO.userError s!"expected duplicate node id error, got {repr other}")

def testEvaluationDepthGuard : IO Unit := do
  let cache ← LazyCore.MemoCache.empty
  let graph := LazyCore.add 3 (.const 1 "left" 1.0) (.const 2 "right" 2.0)
  match ← LazyCore.forceWithFuel 0 {} cache graph with
  | .error (.evaluationFailed "lazy evaluation exceeded recursion depth") => pure ()
  | other => throw (IO.userError s!"expected depth guard error, got {repr other}")

def testCliScenarioFileDispatch : IO Unit := do
  let tricky := CLI.Commands.scenarioFromPath "/tmp/PortfolioStress/BermudanOption.lean" "base"
  match tricky.instrument with
  | .option .call underlying strike maturity volatility =>
      assert "default underlying" (underlying == "ACME")
      assert "default strike" (approxEq strike 100.0)
      assert "default maturity" (approxEq maturity 1.0)
      assert "default volatility" (approxEq volatility 0.20)
  | other => throw (IO.userError s!"path directory should not select PortfolioStress, got {repr other}")

def testRegistry : IO Unit := do
  let base ← assertOk "default registry" Registry.defaultCore
  let customInstrument := (Finance.Instrument.exotic "custom-exotic" "ACME" [("multiplier", 1.0)]).toRegistryEntry
  let withInstrument ← assertOk "register instrument" (registerInstrument base customInstrument)
  assert "registry contains instrument" (Registry.contains withInstrument .instrument "custom-exotic")
  let lookedUp ← assertOk "lookup instrument implementation" (Registry.lookupInstrument withInstrument "custom-exotic")
  let (eval, _stats, _trace) ← LazyCore.force Finance.baseContext (lookedUp.payoffBuilder 500)
  let value ← assertOk "registered payoff dispatch" eval
  assert "registered instrument callable" (approxEq value 100.0)
  let duplicate := Registry.registerInstrumentEntry withInstrument {
    customInstrument with
      descriptor := { customInstrument.descriptor with description := "different" },
      implementationKey := "different"
  }
  match duplicate with
  | .error (.registryError _) => pure ()
  | _ => throw (IO.userError "expected duplicate registry error")
  let customEngine : Registry.PricingEngineEntry := {
    descriptor := { kind := .engine, name := "unit-engine", version := "2.1.0", description := "test engine" },
    implementationKey := "test.unit-engine",
    price := fun input => pure (.ok { scenario := input.scenarioName, npv := 123.0, lineage := LazyCore.exportLineage input.payoff })
  }
  let withEngine ← assertOk "register custom engine" (registerEngine withInstrument customEngine)
  let engine ← assertOk "lookup engine implementation" (Registry.lookupEngine withEngine "unit-engine")
  let result ← assertOk "custom engine dispatch" (← engine.price ((scenarioOf "unit" (.option .call "ACME" 100.0 1.0 0.20)).toPricingInput))
  assert "custom engine called" (approxEq result.npv 123.0)

def testConfigPrecedence : IO Unit := do
  let cfg ← assertOk "config merge" (Config.merge
    (some "paths: 10\nseed: 1\noutput: yaml\n")
    [("LFSE_PATHS", "20")]
    [("paths", "30"), ("output", "json")])
  assert "cli paths wins" (cfg.paths == 30)
  assert "cli output wins" (cfg.output == "json")
  assert "yaml seed remains" (cfg.seed == UInt64.ofNat 1)

def testBackendAndProvenance : IO Unit := do
  let graph := LazyCore.add 10 (LazyCore.const 11 1.0) (LazyCore.const 12 2.0)
  let (res, stats, trace) ← LazyCore.forceWithBackend { name := "audit", allowEffects := false } {} graph
  let value ← assertOk "backend force" res
  assert "backend value" (approxEq value 3.0)
  assert "backend dispatch counted" (stats.backendDispatches == 1)
  assert "trace populated" (!trace.isEmpty)
  assert "trace provenance populated" (trace.all (fun ev => ev.provenance.isSome))
  assert "max depth tracked" (stats.maxDepth > 0)
  assert "lineage populated" (!(LazyCore.exportLineage graph).isEmpty)
  let effectGraph : LazyCore.LazyNode := .effect 99 "io" (pure 1.0)
  let (blocked, _, _) ← LazyCore.forceWithBackend { name := "audit", allowEffects := false } {} effectGraph
  match blocked with
  | .error (.evaluationFailed _) => pure ()
  | other => throw (IO.userError s!"expected effect rejection, got {repr other}")

def testAdvancedFinance : IO Unit := do
  let scenario := scenarioOf "base" (.option .call "ACME" 100.0 1.0 0.20)
  let greeks ← assertOk "compute greeks" (← computeGreeks scenario)
  assert "delta present" (greeks.any (fun p => p.fst = "delta"))
  let mc ← assertOk "engine mc" (← forceWithEngine scenario (.monteCarlo 100 42))
  assert "engine mc positive" (mc.npv > 0.0)
  let lsmc ← assertOk "engine lsmc" (← forceWithEngine scenario (.lsmc {}))
  assert "lsmc nonnegative" (lsmc.npv >= 0.0)
  let basket := { scenario with instrument := .basketOption ["ACME", "ACME"] [0.5, 0.5] 100.0 1.0 0.20 }
  let basketNpv ← assertOk "basket npv" (← forceNPV basket)
  assert "basket evaluates" (basketNpv > 0.0)

def testDataProviderAndServer : IO Unit := do
  let provider : MarketDataProvider := { name := "inline", kind := .csvLike, source := "spot.ACME,123.0\nrate.usd,0.04\n" }
  let ctx ← assertOk "provider context" (← loadMarketProvider provider)
  let spot ← assertOk "provider spot" (ctx.lookup "spot.ACME")
  assert "provider spot parsed" (approxEq spot 123.0)
  let cfg : Config := { authToken := some "secret" }
  let denied ← Server.handleRequest cfg { path := "/eval", token := some "wrong" }
  assert "server denies bad token" (denied.status == 401)
  let ok ← Server.handleRequest cfg { path := "/eval", token := some "secret" }
  assert "server eval ok" (ok.status == 200)
  let metrics ← Server.handleRequest cfg { path := "/metrics", token := some "secret" }
  assert "metrics ok" (metrics.status == 200)
  assert "metrics help format" (metrics.body.contains '#')

def testGovernanceSecurityAndPython : IO Unit := do
  let model := ({ name := "model", version := "2.1.0", lineageHash := "abc" } : Governance.ModelVersion)
  assert "draft not prod" (!Governance.canRunProduction model)
  assert "approved prod" (Governance.canRunProduction (model.approve "qa"))
  match Security.validateScenarioPayload { maxInputBytes := 4 } "12345" with
  | .error (.securityError _) => pure ()
  | other => throw (IO.userError s!"expected security error, got {repr other}")
  let py ← Python.forceNpvJson "{}"
  assert "python binding json" (py.contains '"')

def runAll : IO UInt32 := do
  testLazySharing
  testCycleDetection
  testFinance
  testDiscountFormula
  testExerciseBackwardInduction
  testMonteCarlo
  testForceMonteCarloErrors
  testData
  testDSL
  testRealisticSyntheticPortfolio
  testStressGridReports
  testAbsWaterfallScenarios
  testMonteCarloRiskReport
  testDuplicateNodeIdDetection
  testEvaluationDepthGuard
  testCliScenarioFileDispatch
  testRegistry
  testConfigPrecedence
  testBackendAndProvenance
  testAdvancedFinance
  testDataProviderAndServer
  testGovernanceSecurityAndPython
  IO.println "LFSE tests passed"
  pure 0

end Test
end LFSE
