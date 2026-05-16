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

end Finance
end LFSE
