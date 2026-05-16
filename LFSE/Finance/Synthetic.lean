import LFSE.Finance.Waterfall

namespace LFSE
namespace Finance
namespace Synthetic

structure PortfolioPosition where
  name : String
  instrument : Instrument
  quantity : Float
  deriving Repr, BEq

structure ScenarioReport where
  name : String
  npv : Float
  traceNodes : Nat
  deriving Repr, BEq

def realisticMarket : Context :=
  ({} : Context)
    |>.withMarket "spot.ACME" 102.35
    |>.withMarket "spot.BETA" 47.80
    |>.withMarket "spot.OIL" 82.40
    |>.withMarket "spot.EURUSD" 1.09
    |>.withMarket "rate.usd" 0.0475
    |>.withMarket "rate.eur" 0.0325
    |>.withMarket "vol.ACME" 0.24
    |>.withMarket "vol.BETA" 0.31
    |>.withMarket "recovery.abs" 0.91

def recessionMarket : Context :=
  realisticMarket
    |>.withMarket "spot.ACME" 84.50
    |>.withMarket "spot.BETA" 35.25
    |>.withMarket "spot.OIL" 64.10
    |>.withMarket "rate.usd" 0.0320

def inflationShockMarket : Context :=
  realisticMarket
    |>.withMarket "spot.ACME" 96.20
    |>.withMarket "spot.BETA" 42.90
    |>.withMarket "spot.OIL" 104.75
    |>.withMarket "rate.usd" 0.0610

def creditTighteningMarket : Context :=
  realisticMarket
    |>.withMarket "rate.usd" 0.0725
    |>.withMarket "recovery.abs" 0.78

def equityDerivativesBook : List PortfolioPosition := [
  { name := "ACME 1Y ATM calls", instrument := .option .call "ACME" 100.0 1.0 0.24, quantity := 250.0 },
  { name := "ACME 6M protective puts", instrument := .option .put "ACME" 92.5 0.5 0.28, quantity := 150.0 },
  { name := "BETA upside calls", instrument := .option .call "BETA" 50.0 1.5 0.31, quantity := 400.0 }
]

def commodityHedgeBook : List PortfolioPosition := [
  { name := "OIL producer forward hedge", instrument := .forward "OIL" 78.0 1.0, quantity := 10000.0 },
  { name := "OIL downside put overlay", instrument := .option .put "OIL" 70.0 1.0 0.34, quantity := 1200.0 }
]

def ratesBook : List PortfolioPosition := [
  { name := "Receive-fixed USD swap", instrument := .swap 25000000.0 0.041 0.0475 5.0, quantity := 1.0 },
  { name := "Pay-fixed hedge swap", instrument := .swap 10000000.0 0.052 0.0475 3.0, quantity := 1.0 }
]

def multiAssetPortfolio : List PortfolioPosition :=
  equityDerivativesBook ++ commodityHedgeBook ++ ratesBook

partial def evalPortfolioAux (ctx : Context) : List PortfolioPosition → IO (LFSEExcept Float)
  | [] => pure (.ok 0.0)
  | pos :: rest => do
      match ← price ctx pos.instrument with
      | .error err => pure (.error err)
      | .ok result =>
          match ← evalPortfolioAux ctx rest with
          | .error err => pure (.error err)
          | .ok tail => pure (.ok (result.npv * pos.quantity + tail))

def evalPortfolio (ctx : Context) (positions : List PortfolioPosition) : IO (LFSEExcept Float) :=
  evalPortfolioAux ctx positions

def reportScenario (name : String) (ctx : Context) (positions : List PortfolioPosition) : IO (LFSEExcept ScenarioReport) := do
  match ← evalPortfolio ctx positions with
  | .error err => pure (.error err)
  | .ok npv => pure (.ok { name := name, npv := npv, traceNodes := positions.length * 3 })

def macroStressGrid : List (String × Context) := [
  ("base", realisticMarket),
  ("recession", recessionMarket),
  ("inflation-shock", inflationShockMarket),
  ("credit-tightening", creditTighteningMarket)
]

partial def runStressGridAux (positions : List PortfolioPosition) : List (String × Context) → IO (LFSEExcept (List ScenarioReport))
  | [] => pure (.ok [])
  | scenario :: rest => do
      match ← reportScenario scenario.fst scenario.snd positions with
      | .error err => pure (.error err)
      | .ok report =>
          match ← runStressGridAux positions rest with
          | .error err => pure (.error err)
          | .ok reports => pure (.ok (report :: reports))

def runStressGrid (positions : List PortfolioPosition := multiAssetPortfolio) : IO (LFSEExcept (List ScenarioReport)) :=
  runStressGridAux positions macroStressGrid

def absTranches : List Tranche := [
  { name := "Class A senior", balance := 75000000.0, rate := 0.045 },
  { name := "Class B mezzanine", balance := 18000000.0, rate := 0.075 },
  { name := "Equity residual", balance := 7000000.0, rate := 0.12 }
]

def monthlyAbsCashflowBase : Float := 5200000.0
def monthlyAbsCashflowStress : Float := 3600000.0

def absBasePayments : List Payment :=
  allocateWaterfall monthlyAbsCashflowBase absTranches

def absStressPayments : List Payment :=
  allocateWaterfall monthlyAbsCashflowStress absTranches

def mcRiskReport (paths : Nat) (seed : UInt64) : IO (LFSEExcept (Float × Float)) := do
  let base ← monteCarloCall paths seed 102.35 100.0 0.0475 0.24 1.0
  let recession ← monteCarloCall paths seed 84.50 100.0 0.0320 0.31 1.0
  pure (.ok (base, recession))

end Synthetic
end Finance
end LFSE
