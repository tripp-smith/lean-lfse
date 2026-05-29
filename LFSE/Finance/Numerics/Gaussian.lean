/-!
# Gaussian Sampler for LSMC (Box–Muller + PCG64)

Implements statistically sound N(0,1) sampling for risk-neutral GBM paths.
Replaces the placeholder uniform shocks in the old `MonteCarlo.lean`.

See spec §6.5, F-03, T-008/T-009.

The implementation is pure-Lean, deterministic by seed, and reproducible.
-/

namespace LFSE
namespace Finance
namespace Numerics

/-- Basic PCG64 state (same MCG as the legacy MonteCarlo.PCG64 for compatibility). -/
structure PCG64 where
  state : UInt64
  deriving Repr, BEq

namespace PCG64

/-- Advance the generator (multiplicative congruential). -/
def next (g : PCG64) : UInt64 × PCG64 :=
  let newState := g.state * 6364136223846793005 + 1442695040888963407
  (newState, { state := newState })

/-- Uniform [0,1) using the full 64-bit state. -/
def nextUnit (g : PCG64) : Float × PCG64 :=
  let (x, g') := g.next
  let v := x.toNat.toFloat / 18446744073709551616.0
  (v, g')

end PCG64

/-- Box–Muller transform: two independent standard normals from two uniforms.
Handles the u₁ = 0 singularity defensively (rare with good PRNG). -/
def boxMuller (u₁ u₂ : Float) : Float × Float :=
  let u₁' := if u₁ <= 0.0 then 1.0e-300 else u₁   -- avoid log(0)
  let u₂' := if u₂ <= 0.0 || u₂ >= 1.0 then 0.5 else u₂
  let r := Float.sqrt (-2.0 * Float.log u₁')
  let θ := 2.0 * (3.14159265358979323846 : Float) * u₂'
  (r * Float.cos θ, r * Float.sin θ)

/-- Extend PCG64 with a Gaussian pair generator (Box–Muller on two nextUnit draws). -/
def PCG64.nextGaussianPair (g : PCG64) : (Float × Float) × PCG64 :=
  let (u₁, g1) := g.nextUnit
  let (u₂, g2) := g1.nextUnit
  let (z₁, z₂) := boxMuller u₁ u₂
  ((z₁, z₂), g2)

/-- Single Gaussian draw (discards the second of the pair; fine for non-antithetic use). -/
def PCG64.nextGaussian (g : PCG64) : Float × PCG64 :=
  let ((z, _), g') := g.nextGaussianPair
  (z, g')

end Numerics
end Finance
end LFSE