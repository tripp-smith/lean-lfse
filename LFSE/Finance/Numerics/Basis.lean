/-!
# Basis Functions for LSMC Regression (Phase B)

Implements Monomial, Laguerre, and Hermite basis families as specified.

See formal spec for requirements on `BasisFamily`.
-/

namespace LFSE
namespace Finance
namespace Numerics

inductive BasisFamily where
  | monomial (degree : Nat)
  | laguerre (degree : Nat)
  | hermite  (degree : Nat)
  deriving Repr, BEq

/-- Evaluate a basis family at a point x (Float version for the Algorithm). -/
def BasisFamily.eval : BasisFamily → Float → Array Float
  | .monomial d, x =>
      Array.range (d + 1) |>.map (fun k => x ^ k.toFloat)
  | .laguerre d, x =>
      Id.run do
        let mut prev2 : Float := 1.0
        let mut prev1 : Float := 1.0 - x
        let mut coeffs : Array Float := #[1.0, 1.0 - x]

        for k in [2:d+1] do
          let curr := ((2 * k.toFloat - 1 - x) * prev1 - (k.toFloat - 1) * prev2) / k.toFloat
          coeffs := coeffs.push curr
          prev2 := prev1
          prev1 := curr
        coeffs
  | .hermite d, x =>
      Id.run do
        let mut prev2 : Float := 1.0
        let mut prev1 : Float := x
        let mut coeffs : Array Float := #[1.0, x]

        for k in [2:d+1] do
          let curr := x * prev1 - (k.toFloat - 1) * prev2
          coeffs := coeffs.push curr
          prev2 := prev1
          prev1 := curr
        coeffs

/-- Dimension of the basis (degree + 1). -/
def BasisFamily.dim : BasisFamily → Nat
  | .monomial d => d + 1
  | .laguerre d => d + 1
  | .hermite  d => d + 1

end Numerics
end Finance
end LFSE
