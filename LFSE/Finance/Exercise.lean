import LFSE.Finance.Instrument

namespace LFSE
namespace Finance

structure ExerciseStep where
  continuation : Float
  immediate : Float
  deriving Repr, BEq

def optimalExercise (steps : List ExerciseStep) : Float :=
  steps.foldr (fun step acc => max step.immediate (step.continuation + acc)) 0.0

def bermudanTreeValue (spot strike rate : Float) (exercise : List Float) : Float :=
  let intrinsic := max0 (spot - strike)
  let bestExercise := exercise.foldl (fun acc v => max acc v) intrinsic
  bestExercise * Float.exp (-(rate * exercise.length.toFloat))

def americanPutApprox (spot strike rate maturity : Float) : Float :=
  max (blackScholes .put spot strike rate 0.20 maturity) (max0 (strike - spot))

end Finance
end LFSE
