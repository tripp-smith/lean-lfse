import LFSE.Finance.MonteCarlo

namespace LFSE
namespace Finance

structure Scenario where
  name : String
  ctx : Context
  instrument : Instrument
  deriving Repr

def Scenario.eval (scenario : Scenario) : IO (LFSEExcept Result) := do
  let r ← price scenario.ctx scenario.instrument
  pure (r.map fun result => { result with scenario := scenario.name })

def shock (scenario : Scenario) (observable : String) (bump : Float) : Scenario :=
  let old := scenario.ctx.market.getD observable 0.0
  { scenario with name := scenario.name ++ ".shock." ++ observable, ctx := scenario.ctx.withMarket observable (old + bump) }

def ifThenElse (cond : Bool) (yes no : Scenario) : Scenario :=
  if cond then yes else no

def portfolioStress : List Scenario :=
  let base : Scenario := { name := "base", ctx := baseContext, instrument := .option .call "ACME" 100.0 1.0 0.20 }
  [base, shock base "spot.ACME" 10.0, shock base "spot.ACME" (-10.0)]

-- Phase A convenience constructors for early-exercise instruments
def bermudanPut (underlying : String) (strike maturity volatility : Float) (dates : Array Float) : Instrument :=
  .bermudanOption .put underlying strike maturity volatility dates

def bermudanCall (underlying : String) (strike maturity volatility : Float) (dates : Array Float) : Instrument :=
  .bermudanOption .call underlying strike maturity volatility dates

def americanPut (underlying : String) (strike maturity volatility : Float) (steps : Nat) : Instrument :=
  .americanOption .put underlying strike maturity volatility steps

def americanCall (underlying : String) (strike maturity volatility : Float) (steps : Nat) : Instrument :=
  .americanOption .call underlying strike maturity volatility steps

end Finance
end LFSE
