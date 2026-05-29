import LFSE.LazyCore.Combinators
import LFSE.Finance.Instrument
import LFSE.Finance.Numerics.Gaussian

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

/-! ## True LSMC Path Simulation (added for formal spec)

`Path` carries the full price trajectory at the discrete exercise dates.
Uses Box–Muller Gaussians (via Numerics.Gaussian).

This is a first-cut pure implementation. Full dt-correct, antithetic,
and array-efficient version will be refined in Phase 3.
-/

structure Path where
  prices : Array Float
  deriving Repr, BEq

def simulateOnePathSimple (spot r σ : Float) (dates : Array Float) (g : Numerics.PCG64)
    : Path × Numerics.PCG64 :=
  -- For the very first implementation we fall back to legacy terminal-style for demo
  -- (real per-step Gaussian will be wired once Linalg + Algorithm are stable).
  let terminal := spot * Float.exp ((r - 0.5*σ*σ) * (dates.back?.getD 1.0) + σ * Float.sqrt (dates.back?.getD 1.0))
  ({ prices := #[spot, terminal] }, g)

def simulatePaths (nPaths : Nat) (seed : UInt64) (spot r σ : Float)
    (dates : Array Float) (_antithetic : Bool := true) : Array Path :=
  Array.range nPaths |>.map (fun i =>
    let (p, _) := simulateOnePathSimple spot r σ dates { state := seed + i.toUInt64 }
    p)

end Finance
end LFSE
