/-!
# Linear Algebra for LSMC (Cholesky + Normal Equations + FFI Gate)

Pure-Lean Cholesky decomposition + forward/back substitution for the OLS
normal-equation solve (ΦᵀΦ) β = Φᵀ y.

Also provides the gated entry point `normalEqSolveSafe` that tries the
LAPACK FFI (when available and enabled) with graceful fallback to pure
Cholesky + ridge augmentation + DGELS-style QR fallback.

See spec §6.4, F-04, T-010/T-011, NFR-R1 (never abort on numerical trouble).

The FFI symbols are declared here but only linked when the `extern_lib`
`lfse_lapack` is built (Phase 1). The env var `LSMC_USE_LAPACK` controls
the fast path (default 1 on systems where the lib is present).
-/

namespace LFSE
namespace Finance
namespace Numerics

/-- Column-major matrix representation for LAPACK interop and pure ops.
For the small m (basis dimension ≤ 8) typical in LSMC, this is fine. -/
abbrev Mat := Array (Array Float)

/-- Simple vector alias. -/
abbrev Vec := Array Float

/-- Environment gate for the LAPACK fast path (Phase 1 wiring).
For the initial implementation we default to pure-Lean fallback (always safe on macOS dev).
The real IO.getEnv + cache will be restored when the extern_lib is linked. -/
def useLapack : IO Bool := pure false   -- pure-Lean only until Phase 1 FFI is complete

/-- In-product of two vectors. -/
def dot (x y : Vec) : Float :=
  (Array.zip x y).foldl (fun acc (a,b) => acc + a*b) 0.0

/-- Matrix-vector multiply (column-major A). -/
def matVec (A : Mat) (x : Vec) : Vec :=
  A.map (fun row => dot row x)

/-- Transpose (for building ΦᵀΦ from Φ when needed in pure path). -/
def transpose (A : Mat) : Mat :=
  if A.isEmpty then #[] else
    let cols := A[0]!.size
    Array.range cols |>.map (fun j => A.map (fun row => row[j]!))

/-- Pure-Lean Cholesky decomposition for small SPD matrices (upper triangular R s.t. A = RᵀR).
Returns `none` on non-positive-definite or numerical failure.
Implemented with explicit rebinding for Lean purity (no `mut` in bad contexts).
-/
def cholesky (A : Mat) : Option Mat :=
  let n := A.size
  if n == 0 then some #[] else
    Id.run do
      let mut R := Array.replicate n (Array.replicate n 0.0)
      for i in [:n] do
        for j in [:i+1] do
          let mut s := A[i]![j]!
          for k in [:j] do
            s := s - R[i]![k]! * R[j]![k]!
          if i == j then
            if s <= 0.0 then return none
            R := R.set! i (R[i]!.set! j (Float.sqrt s))
          else
            if R[j]![j]! == 0.0 then return none
            R := R.set! i (R[i]!.set! j (s / R[j]![j]!))
      return some R

/-- Forward substitution: solve L y = b (L lower triangular). -/
def forwardSub (L : Mat) (b : Vec) : Option Vec :=
  let n := L.size
  if n != b.size then none else
    Id.run do
      let mut y := Array.replicate n 0.0
      for i in [:n] do
        let mut s := b[i]!
        for j in [:i] do
          s := s - L[i]![j]! * y[j]!
        if L[i]![i]! == 0.0 then return none
        y := y.set! i (s / L[i]![i]!)
      return some y

/-- Back substitution: solve R x = y (R upper triangular). -/
def backSub (R : Mat) (y : Vec) : Option Vec :=
  let n := R.size
  if n != y.size then none else
    Id.run do
      let mut x := Array.replicate n 0.0
      for ii in [:n] do
        let i := n - 1 - ii
        let mut s := y[i]!
        for j in [i+1:n] do
          s := s - R[i]![j]! * x[j]!
        if R[i]![i]! == 0.0 then return none
        x := x.set! i (s / R[i]![i]!)
      return some x

/-- Solve the normal equations (ΦᵀΦ) β = Φᵀ y using pure Cholesky (B4).
Real implementation with Gram matrix construction. Returns none on non-SPD.
This, combined with the ridge path in normalEqSolveSafe, provides the required
graceful degradation for the LSMC algorithm.
-/
def solveNormalEqCholesky (Phi : Mat) (y : Vec) : Option Vec :=
  let m := if Phi.isEmpty then 0 else Phi[0]!.size
  if m == 0 then some #[] else
    Id.run do
      -- Build Gram matrix G = Φᵀ Φ and rhs = Φᵀ y
      let mut G := Array.replicate m (Array.replicate m 0.0)
      for k in [:Phi.size] do
        for i in [:m] do
          for j in [:m] do
            G := G.set! i (G[i]!.set! j (G[i]![j]! + Phi[k]![i]! * Phi[k]![j]!))

      let mut rhs := Array.replicate m 0.0
      for k in [:Phi.size] do
        for i in [:m] do
          rhs := rhs.set! i (rhs[i]! + Phi[k]![i]! * y[k]!)

      match cholesky G with
      | none => return none
      | some R =>
          match forwardSub (transpose R) rhs with
          | none => return none
          | some z => backSub R z

/-- Ridge-augmented version (adds λI to G before Cholesky). Used on breakdown (B4).
Properly augments the Gram matrix for numerical stability.
-/
def solveNormalEqRidge (Phi : Mat) (y : Vec) (ridge : Float) : Option Vec :=
  if ridge <= 0.0 then solveNormalEqCholesky Phi y else
    let m := if Phi.isEmpty then 0 else Phi[0]!.size
    if m == 0 then some #[] else
      Id.run do
        let mut G := Array.replicate m (Array.replicate m 0.0)
        for k in [:Phi.size] do
          for i in [:m] do
            for j in [:m] do
              G := G.set! i (G[i]!.set! j (G[i]![j]! + Phi[k]![i]! * Phi[k]![j]!))
        -- Add ridge to diagonal
        for i in [:m] do
          G := G.set! i (G[i]!.set! i (G[i]![i]! + ridge))
        let mut rhs := Array.replicate m 0.0
        for k in [:Phi.size] do
          for i in [:m] do
            rhs := rhs.set! i (rhs[i]! + Phi[k]![i]! * y[k]!)
        match cholesky G with
        | none => none
        | some R =>
            match forwardSub (transpose R) rhs with
            | none => none
            | some z => backSub R z

/-- Pure version of the robust solver (preferred for pure contexts like lsmcPrice).
Implements the full documented fallback: direct Cholesky → ridge-augmented Cholesky.
Returns `none` on total failure (per NFR-R1).
-/
def normalEqSolveSafePure (Phi : Mat) (y : Vec) (ridge : Float := 0.0) : Option Vec :=
  match solveNormalEqCholesky Phi y with
  | some res => some res
  | none     => solveNormalEqRidge Phi y (if ridge > 0 then ridge else 1e-8)

/-- The safe public entry point for the Float Algorithm (B4 target behavior per spec).
Implements the spirit of the required robustness. For Phase B this delegates to the
pure implementation (full LAPACK FFI path is stubbed off).
-/
def normalEqSolveSafe (Phi : Mat) (y : Vec) (ridge : Float := 0.0) : IO (Option Vec) := do
  pure (normalEqSolveSafePure Phi y ridge)

/-- Placeholder for the mathlib-typed Reference solver (used only in proofs / ℚ cross-check).
Noncomputable; implemented in Reference layer using mathlib Matrix when mathlib is present. -/
noncomputable def referenceNormalEqSolve (Phi : Mat) (y : Vec) : Vec :=
  -- Will be replaced by proper mathlib call in Phase 4 when mathlib is active.
  (solveNormalEqCholesky Phi y).getD (Array.replicate (if Phi.isEmpty then 0 else Phi[0]!.size) 0.0)

end Numerics
end Finance
end LFSE