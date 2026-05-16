import LFSE.LazyCore.Node

namespace LFSE
namespace Finance

structure Curve where
  name : String
  rate : Float
  deriving Repr, BEq

structure Surface where
  name : String
  volatility : Float
  deriving Repr, BEq

inductive Observable where
  | spot (name : String)
  | rate (name : String)
  | volatility (name : String)
  | scalar (value : Float)
  deriving Repr, BEq

def Observable.key : Observable → String
  | .spot name => "spot." ++ name
  | .rate name => "rate." ++ name
  | .volatility name => "vol." ++ name
  | .scalar value => s!"scalar.{value}"

def Observable.toNode (id : Nat) : Observable → LazyCore.LazyNode
  | .scalar value => LazyCore.const id value
  | obs => LazyCore.observable id obs.key

def baseContext : Context :=
  (((({} : Context).withMarket "spot.ACME" 100.0).withMarket "rate.usd" 0.05)
    |>.withMarket "vol.ACME" 0.20
    |>.withMarket "spread.swap" 0.01
    |>.withMarket "recovery.abs" 0.92)

end Finance
end LFSE
