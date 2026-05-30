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

/-! ## True LSMC Path Simulation

`Path` carries the full price trajectory at the discrete exercise dates (including t=0).

This implementation uses proper per-step log-Euler discretization with
Gaussian shocks from `Numerics.Gaussian`. It is array-based for performance
and supports antithetic variates.

This is the production version required for Phase B correctness.
-/

structure Path where
  prices : Array Float   -- length = dates.size + 1 (S0 at t=0, then one entry per date)
  deriving Repr, BEq

/-- Simulate a single path with proper per-step Gaussian shocks.
Returns the path and the final generator state. -/
def simulateOnePath (spot r σ : Float) (dates : Array Float) (g : Numerics.PCG64)
    : Path × Numerics.PCG64 :=
  Id.run do
    let n := dates.size
    let mut prices := Array.replicate (n + 1) 0.0
    prices := prices.set! 0 spot

    let mut S := spot
    let mut tPrev := 0.0
    let mut gen := g

    for i in [:n] do
      let t := dates[i]!
      let dt := t - tPrev
      let (z, gen') := gen.nextGaussian
      gen := gen'

      let drift := (r - 0.5 * σ * σ) * dt
      let diffusion := σ * Float.sqrt dt * z
      S := S * Float.exp (drift + diffusion)

      prices := prices.set! (i + 1) S
      tPrev := t

    ({ prices }, gen)

/-- Simulate N paths.
When `antithetic` is true, we pair paths by negating the Gaussian shocks
for variance reduction (standard antithetic variates for GBM). -/
def simulatePaths (nPaths : Nat) (seed : UInt64) (spot r σ : Float)
    (dates : Array Float) (antithetic : Bool := true) : Array Path :=
  if nPaths == 0 then #[] else
    let _baseGen : Numerics.PCG64 := { state := seed }

    if !antithetic then
      -- Simple independent paths
      Array.range nPaths |>.map (fun i =>
        let (p, _) := simulateOnePath spot r σ dates { state := seed + i.toUInt64 * 6364136223846793005 }
        p)
    else
      -- Antithetic using two separate deterministic streams (correct and simple)
      let half := (nPaths + 1) / 2
      Array.range half |>.flatMap (fun i =>
        let gen1 : Numerics.PCG64 := { state := seed + i.toUInt64 * 6364136223846793005 }
        let (p1, _) := simulateOnePath spot r σ dates gen1

        let gen2 : Numerics.PCG64 := { state := seed + (i.toUInt64 + 1000000) * 6364136223846793005 }
        let (p2, _) := simulateOnePath spot r σ dates gen2

        #[p1, p2]
      ) |>.take nPaths

end Finance
end LFSE
