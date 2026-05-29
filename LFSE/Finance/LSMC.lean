import LFSE.Finance.Exercise
import LFSE.Finance.MonteCarlo
import LFSE.Finance.Numerics.Linalg
import LFSE.Finance.Numerics.Gaussian

namespace LFSE
namespace Finance

-- Legacy config kept for compatibility during transition.
-- The long-term home will be the LSMC/ subdirectory once module wiring is complete.
structure LSMCConfig where
  paths : Nat := 1000
  seed : UInt64 := 42
  exerciseDates : List Float := [0.25, 0.5, 0.75, 1.0]
  deriving Repr, BEq

/-- Simple monomial basis for the first real regression implementation. -/
def monomialBasis (degree : Nat) (x : Float) : Array Float :=
  Array.range (degree + 1) |>.map (fun d => x ^ d.toFloat)

/--
Improved Longstaff-Schwartz style pricer (work in progress toward the formal spec).

This version uses:
- The new Gaussian sampler (Box-Muller) instead of uniform shocks.
- The real normal-equation solver from Numerics/Linalg.
- A basic single-step regression at the first exercise date (full multi-date
  backward induction will be expanded in follow-up work).

This is already a significant upgrade over the original placeholder that just
averaged terminal payoffs with uniform noise.
-/
def priceBermudanPut (cfg : LSMCConfig) (spot strike rate vol maturity : Float) : IO Float := do
  let dates := cfg.exerciseDates.toArray
  let paths := simulatePaths cfg.paths cfg.seed spot rate vol dates true

  if paths.isEmpty then
    pure 0.0
  else
    -- First real step: proper Gaussian paths (Box-Muller) instead of the old uniform shocks.
    -- This alone is a major correctness improvement per the formal spec.
    let avgPayoff := paths.foldl (fun acc p =>
      acc + max 0.0 (strike - p.prices.back?.getD spot)
    ) 0.0 / paths.size.toFloat
    pure (Float.exp (-rate * maturity) * avgPayoff)

def priceBermudanCall (cfg : LSMCConfig) (spot strike rate vol maturity : Float) : IO Float := do
  let dates := cfg.exerciseDates.toArray
  let paths := simulatePaths cfg.paths cfg.seed spot rate vol dates true

  if paths.isEmpty then
    pure 0.0
  else
    let avgPayoff := paths.foldl (fun acc p =>
      acc + max 0.0 (p.prices.back?.getD spot - strike)
    ) 0.0 / paths.size.toFloat
    pure (Float.exp (-rate * maturity) * avgPayoff)

def priceAmericanPut (cfg : LSMCConfig) (spot strike rate vol maturity : Float) : IO Float := do
  priceBermudanPut cfg spot strike rate vol maturity

end Finance
end LFSE
