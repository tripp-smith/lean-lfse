import LFSE.Finance.Exercise
import LFSE.Finance.MonteCarlo

namespace LFSE
namespace Finance

structure LSMCConfig where
  paths : Nat := 1000
  seed : UInt64 := 42
  exerciseDates : List Float := [0.25, 0.5, 0.75, 1.0]
  deriving Repr, BEq

def regressionContinuation (cashflows : List Float) : Float :=
  mean cashflows

def priceBermudanCall (cfg : LSMCConfig) (spot strike rate vol maturity : Float) : IO Float := do
  let terminal := terminalSamples cfg.paths { state := cfg.seed } spot strike rate vol maturity
  let continuation := regressionContinuation terminal
  let immediate := max0 (spot - strike)
  pure (Float.exp (-(rate * maturity)) * max immediate continuation)

end Finance
end LFSE
