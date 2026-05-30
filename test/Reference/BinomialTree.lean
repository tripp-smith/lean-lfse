/-!
# Binomial Tree Reference Oracle (B5a)

CRR binomial tree for American/Bermudan options.
This is the verification ground truth for Phase B.

For this phase, we accept ~1e-2 accuracy vs published LS Table 1 values
(as decided during planning), since it is only an internal oracle, not the final golden.
-/

namespace LFSE
namespace Test
namespace Reference

def binomialAmericanPut (spot strike rate vol maturity steps : Nat) : Float :=
  if steps == 0 then max 0.0 (strike - spot) else
    let dt := maturity / steps.toFloat
    let u := Float.exp (vol * Float.sqrt dt)
    let d := 1.0 / u
    let p := (Float.exp (rate * dt) - d) / (u - d)
    let disc := Float.exp (-rate * dt)

    let mut values : Array Float := Array.range (steps + 1) |>.map (fun j =>
      let S := spot * (u ^ (steps.toFloat - j.toFloat)) * (d ^ j.toFloat)
      max 0.0 (strike - S)
    )

    for i in [0:steps] do
      let step := steps - 1 - i
      let mut newValues : Array Float := #[]
      for j in [0:step+1] do
        let S := spot * (u ^ (step.toFloat - j.toFloat)) * (d ^ j.toFloat)
        let imm := max 0.0 (strike - S)
        let cont := disc * (p * values[j]! + (1.0 - p) * values[j+1]!)
        newValues := newValues.push (max imm cont)
      values := newValues

    values[0]!

-- Helper for Phase B verification: higher step count for better accuracy (~1e-2 target per plan)
def binomialAmericanPutAccurate (spot strike rate vol maturity : Float) : Float :=
  binomialAmericanPut spot strike rate vol maturity 5000   -- 5000 steps for tighter verification oracle

-- Exact cases from LS Table 1 for the verification subset (all T=1 + sample T=2)
-- K=40, r=0.06 for all
def lsTable1VerificationCases : List (String × Float × Float × Float × Float) :=
  [ ("S36_T1", 36.0, 0.20, 1.0, 4.478)   -- published ~4.478
  , ("S36_T2", 36.0, 0.20, 2.0, 4.840)
  , ("S40_T1", 40.0, 0.20, 1.0, 2.314)
  , ("S44_T1", 44.0, 0.20, 1.0, 1.110)
  ]

def binomialBermudanPut (spot strike rate vol maturity : Float) (exerciseDates : Array Float) (stepsPerInterval : Nat) : Float :=
  -- For Phase B verification, we use a fine American grid as proxy.
  -- A more precise discrete-exercise version can be added later.
  let totalSteps := max 10 (exerciseDates.size * stepsPerInterval)
  binomialAmericanPut spot strike rate vol maturity totalSteps

end Reference
end Test
end LFSE
