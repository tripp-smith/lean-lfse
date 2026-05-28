import LFSE.Finance.Observable
import LFSE.LazyCore.Memo
import LFSE.LazyCore.Provenance
import LFSE.Registry.Basic

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
  | basketOption (underlyings : List String) (weights : List Float) (strike maturity volatility : Float)
  | creditDefaultSwap (reference : String) (notional spread hazardRate recovery maturity : Float)
  | exotic (name : String) (underlying : String) (parameters : List (String × Float))
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
  | .basketOption underlyings weights strike maturity volatility =>
      let weighted :=
        (List.zip underlyings weights).foldl
          (fun acc uw =>
            let obs := LazyCore.observable (baseId + acc.fst + 10) ("spot." ++ uw.fst)
            (acc.fst + 1, LazyCore.add (baseId + acc.fst + 100) acc.snd (LazyCore.mul (baseId + acc.fst + 200) (LazyCore.const (baseId + acc.fst + 300) uw.snd) obs)))
          (0, LazyCore.const (baseId + 9) 0.0)
      let rate := LazyCore.observable (baseId + 2) "rate.usd"
      LazyCore.LazyNode.binary baseId "basket-black-scholes"
        (fun s r => blackScholes .call s strike r volatility maturity) weighted.snd rate
  | .creditDefaultSwap _reference notional spread hazardRate recovery maturity =>
      let premium := notional * spread * maturity
      let defaultProb := 1.0 - Float.exp (-(hazardRate * maturity))
      let protection := notional * (1.0 - recovery) * defaultProb
      LazyCore.const baseId (protection - premium)
  | .exotic name underlying params =>
      let spot := LazyCore.observable (baseId + 1) ("spot." ++ underlying)
      let multiplier := params.find? (fun p => p.fst = "multiplier") |>.map (fun p => p.snd) |>.getD 1.0
      LazyCore.LazyNode.unary baseId ("exotic:" ++ name) (fun s => s * multiplier) spot

def Instrument.registryName : Instrument → String
  | .forward .. => "forward"
  | .option .call .. => "call-option"
  | .option .put .. => "put-option"
  | .swap .. => "swap"
  | .basketOption .. => "basket-option"
  | .creditDefaultSwap .. => "credit-default-swap"
  | .exotic name .. => name

def Instrument.toRegistryEntry (instrument : Instrument) : Registry.InstrumentEntry := {
  descriptor := {
    kind := .instrument,
    name := instrument.registryName,
    version := "2.1.0",
    description := toString (repr instrument)
  },
  implementationKey := "lfse-finance.instrument." ++ instrument.registryName,
  supportedEngineKeys := match instrument with
    | .option .call .. => ["analytic", "monte-carlo", "lsmc"]
    | _ => ["analytic"],
  payoffBuilder := instrument.payoffNode
}

def price (ctx : Context) (instrument : Instrument) : IO (LFSEExcept Result) := do
  let (res, _stats, trace) ← LazyCore.force ctx (instrument.payoffNode 100)
  pure <| res.map (fun npv => {
    scenario := "instrument",
    npv := npv,
    trace := trace,
    lineage := LazyCore.exportLineage (instrument.payoffNode 100)
  })

end Finance
end LFSE
