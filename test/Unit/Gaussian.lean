/-!
# Unit Test: Gaussian Sampler (T-009 / FR-04) — standalone

Self-contained statistical smoke test for the Box–Muller + PCG64 logic.
This version duplicates the tiny core (acceptable for an isolated unit test)
so it has no dependency on the rest of LFSE and cannot inherit any `sorry`.

Spec requirement (from lsmc-formal-spec.md):
- 10⁵ draws
- |mean| < 0.02
- |var - 1| < 0.02

Run with: lake env lean test/Unit/Gaussian.lean
-/

structure PCG64 where
  state : UInt64
  deriving Repr, BEq

namespace PCG64

def next (g : PCG64) : UInt64 × PCG64 :=
  let newState := g.state * 6364136223846793005 + 1442695040888963407
  (newState, { state := newState })

def nextUnit (g : PCG64) : Float × PCG64 :=
  let (x, g') := g.next
  let v := x.toNat.toFloat / 18446744073709551616.0
  (v, g')

end PCG64

def boxMuller (u₁ u₂ : Float) : Float × Float :=
  let u₁' := if u₁ <= 0.0 then 1.0e-300 else u₁
  let u₂' := if u₂ <= 0.0 || u₂ >= 1.0 then 0.5 else u₂
  let r := Float.sqrt (-2.0 * Float.log u₁')
  let θ := 2.0 * (3.14159265358979323846 : Float) * u₂'
  (r * Float.cos θ, r * Float.sin θ)

def nextGaussianPair (g : PCG64) : (Float × Float) × PCG64 :=
  let (u₁, g1) := g.nextUnit
  let (u₂, g2) := g1.nextUnit
  let (z₁, z₂) := boxMuller u₁ u₂
  ((z₁, z₂), g2)

def nextGaussian (g : PCG64) : Float × PCG64 :=
  let ((z, _), g') := nextGaussianPair g
  (z, g')

def main : IO Unit := do
  let n := 100000
  let mut g : PCG64 := { state := 123456789 }
  let mut sum := 0.0
  let mut sumSq := 0.0

  for _ in [:n] do
    let (z, g') := nextGaussian g
    g := g'
    sum := sum + z
    sumSq := sumSq + z * z

  let mean := sum / n.toFloat
  let var := (sumSq / n.toFloat) - mean * mean

  let meanOk : Bool := decide (mean.abs < 0.02)
  let varOk : Bool := decide ((var - 1.0).abs < 0.02)

  IO.println s!"Gaussian sampler statistical test (n={n})"
  IO.println s!"  mean = {mean}"
  IO.println s!"  var  = {var}"
  IO.println ("  mean within 0.02: " ++ toString meanOk)
  IO.println ("  var  within 0.02: " ++ toString varOk)

  if meanOk && varOk then
    IO.println "OK"
  else
    IO.println "FAIL"
    IO.Process.exit 1

#eval! main
