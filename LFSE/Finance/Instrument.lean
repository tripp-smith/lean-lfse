import LFSE.Finance.Observable
import LFSE.LazyCore.Memo

namespace LFSE
namespace Finance

inductive OptionKind where
  | call
  | put
  deriving Repr, BEq

inductive Instrument where
  | forward (underlying : String) (strike maturity : Float)
  | option (kind : OptionKind) (underlying : String) (strike maturity volatility : Float)
  | swap (notional fixedRate floatRate maturity : Float)
  deriving Repr, BEq

def max0 (x : Float) : Float :=
  if x < 0.0 then 0.0 else x

def normalCdfApprox (x : Float) : Float :=
  1.0 / (1.0 + Float.exp (-1.702 * x))

def blackScholes (kind : OptionKind) (spot strike rate vol maturity : Float) : Float :=
  if maturity <= 0.0 || vol <= 0.0 || strike <= 0.0 then
    match kind with
    | .call => max0 (spot - strike)
    | .put => max0 (strike - spot)
  else
    let sqrtT := Float.sqrt maturity
    let d1 := (Float.log (spot / strike) + (rate + 0.5 * vol * vol) * maturity) / (vol * sqrtT)
    let d2 := d1 - vol * sqrtT
    let df := Float.exp (-(rate * maturity))
    match kind with
    | .call => spot * normalCdfApprox d1 - strike * df * normalCdfApprox d2
    | .put => strike * df * normalCdfApprox (-d2) - spot * normalCdfApprox (-d1)

def Instrument.payoffNode (baseId : Nat) : Instrument → LazyCore.LazyNode
  | .forward underlying strike maturity =>
      let spot := LazyCore.observable (baseId + 1) ("spot." ++ underlying)
      let k := LazyCore.const (baseId + 2) strike
      let r := LazyCore.observable (baseId + 3) "rate.usd"
      let t := LazyCore.const (baseId + 4) maturity
      LazyCore.discount baseId r t (LazyCore.sub (baseId + 5) spot k)
  | .option kind underlying strike maturity volatility =>
      let spot := LazyCore.observable (baseId + 1) ("spot." ++ underlying)
      let rate := LazyCore.observable (baseId + 2) "rate.usd"
      LazyCore.LazyNode.binary baseId "black-scholes"
        (fun s r => blackScholes kind s strike r volatility maturity) spot rate
  | .swap notional fixedRate floatRate maturity =>
      LazyCore.const baseId (notional * (floatRate - fixedRate) * maturity)

def price (ctx : Context) (instrument : Instrument) : IO (LFSEExcept Result) := do
  let (res, _stats, trace) ← LazyCore.force ctx (instrument.payoffNode 100)
  pure <| res.map (fun npv => { scenario := "instrument", npv := npv, trace := trace })

end Finance
end LFSE
