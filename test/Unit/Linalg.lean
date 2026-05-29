import LFSE.Finance.Numerics.Linalg

open LFSE.Finance.Numerics

/-!
# Unit Test: Linalg (T-011)

Tests for the pure-Lean normal equations solver used by LSMC.

Cases:
1. 3x3 SPD system solved to high residual.
2. OLS coefficient recovery on noiseless quadratic data.
3. Rank-deficient Φ returns `none` (graceful degradation).
-/

def approxEq (a b : Float) (eps : Float := 1e-10) : Bool :=
  (a - b).abs < eps

def main : IO Unit := do
  IO.println "Linalg unit tests (pure Cholesky path)"

  -- Test 1: 3x3 SPD solve
  let A : Mat := #[
    #[4.0, 1.0, 2.0],
    #[1.0, 3.0, 0.0],
    #[2.0, 0.0, 5.0]
  ]
  let b : Vec := #[7.0, 5.0, 9.0]
  let x? := solveNormalEqCholesky A b
  let residual := match x? with
    | none => 999.0
    | some x =>
        let Ax := matVec A x
        (List.zip (Ax.toList) (b.toList)).foldl (fun acc (ai, bi) => acc + (ai - bi).abs) 0.0
  let test1 : Bool := decide (residual < 1e-10)
  IO.println s!"  3x3 SPD residual < 1e-10: {test1} (residual={residual})"

  -- Test 2: OLS recovery (noiseless y = 2 + 3x - x², monomial basis degree 2)
  -- Phi rows: [1, x, x²] for x in some points
  let xs := #[0.0, 1.0, 2.0, -1.0]
  let Phi : Mat := xs.map (fun x => #[1.0, x, x*x])
  let y : Vec := xs.map (fun x => 2.0 + 3.0*x - x*x)   -- exact coefficients [2,3,-1]
  let beta? := solveNormalEqCholesky Phi y
  let test2 : Bool := match beta? with
    | none => false
    | some beta =>
        approxEq beta[0]! 2.0 1e-8 &&
        approxEq beta[1]! 3.0 1e-8 &&
        approxEq beta[2]! (-1.0) 1e-8
  IO.println s!"  OLS noiseless recovery [2,3,-1]: {test2}"

  -- Test 3: Rank deficiency should return none
  let PhiBad : Mat := #[
    #[1.0, 2.0],
    #[2.0, 4.0],   -- duplicate column
    #[3.0, 6.0]
  ]
  let yBad : Vec := #[1.0, 2.0, 3.0]
  let bad? := solveNormalEqCholesky PhiBad yBad
  let test3 : Bool := bad?.isNone
  IO.println s!"  Rank-deficient returns none: {test3}"

  if test1 && test2 && test3 then
    IO.println "OK"
  else
    IO.println "FAIL"
    IO.Process.exit 1

#eval! main
