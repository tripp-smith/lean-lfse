import LFSE.LazyCore.Combinators
import LFSE.Finance.Instrument

namespace LFSE
namespace Finance

structure PCG64 where
  state : UInt64
  deriving Repr, BEq

def PCG64.next (g : PCG64) : UInt64 × PCG64 :=
  let newState := g.state * 6364136223846793005 + 1442695040888963407
  (newState, { state := newState })

def PCG64.nextUnit (g : PCG64) : Float × PCG64 :=
  let (x, g') := g.next
  let v := x.toNat.toFloat / 18446744073709551616.0
  (v, g')

partial def pathStream (spot drift vol dt : Float) (g : PCG64) : LazyCore.LazyStream :=
  let (u, nextG) := g.nextUnit
  let shock := (u - 0.5) * 2.0
  let nextSpot := spot * Float.exp ((drift - 0.5 * vol * vol) * dt + vol * Float.sqrt dt * shock)
  .cons (Thunk.mk fun _ => nextSpot) (Thunk.mk fun _ => pathStream nextSpot drift vol dt nextG)

def mean (xs : List Float) : Float :=
  match xs with
  | [] => 0.0
  | _ => xs.foldl (· + ·) 0.0 / xs.length.toFloat

partial def terminalSamples (n : Nat) (g : PCG64) (spot strike rate vol maturity : Float) : List Float :=
  match n with
  | 0 => []
  | n + 1 =>
      let (u, g') := g.nextUnit
      let shock := (u - 0.5) * 2.0
      let terminal := spot * Float.exp ((rate - 0.5 * vol * vol) * maturity + vol * Float.sqrt maturity * shock)
      max0 (terminal - strike) :: terminalSamples n g' spot strike rate vol maturity

def monteCarloCall (paths : Nat) (seed : UInt64) (spot strike rate vol maturity : Float) : IO Float := do
  let payoffs := terminalSamples paths { state := seed } spot strike rate vol maturity
  pure (Float.exp (-(rate * maturity)) * mean payoffs)

def antitheticCall (paths : Nat) (seed : UInt64) (spot strike rate vol maturity : Float) : IO Float := do
  let base ← monteCarloCall paths seed spot strike rate vol maturity
  let anti ← monteCarloCall paths (seed + 1) spot strike rate vol maturity
  pure ((base + anti) / 2.0)

end Finance
end LFSE
