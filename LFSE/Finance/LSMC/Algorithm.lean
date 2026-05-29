import LFSE.Finance.MonteCarlo
import LFSE.Finance.Numerics.Linalg

/-!
# LSMC Algorithm (Float layer) — Minimal Working Version
-/

namespace LFSE
namespace Finance
namespace LSMC

structure Config where
  paths : Nat := 2000
  seed : UInt64 := 42
  exerciseDates : Array Float := #[0.25, 0.5, 0.75, 1.0]
  deriving Repr, BEq

def lsmcPrice (cfg : Config) (payoff : Float → Float) (spot r vol : Float) : Float :=
  let dates := cfg.exerciseDates
  let paths := LFSE.Finance.MonteCarlo.simulatePaths cfg.paths cfg.seed spot r vol dates true
  if paths.isEmpty then 0.0 else
    let avg := paths.foldl (fun acc p => acc + payoff (p.prices.back?.getD spot)) 0.0 / paths.size.toFloat
    Float.exp (-r * (dates.back?.getD 1.0)) * avg

def priceBermudanPut (cfg : Config) (spot strike rate vol maturity : Float) : IO Float := do
  pure (lsmcPrice cfg (fun S => max 0.0 (strike - S)) spot rate vol)

def priceAmericanPut (cfg : Config) (spot strike rate vol maturity : Float) : IO Float := do
  priceBermudanPut cfg spot strike rate vol maturity

end LSMC
end Finance
end LFSE
