import LFSE.Finance.MonteCarlo

open LFSE.Finance

/-!
# Property Tests for MonteCarlo Path Simulation (B1)

These tests verify that `simulatePaths` produces statistically correct
GBM trajectories under the risk-neutral measure.
-/

def main : IO Unit := do
  IO.println "MonteCarlo Path Simulation Property Tests (B1)"

  let nPaths := 50000
  let seed := 123456789
  let spot := 100.0
  let r := 0.05
  let σ := 0.2
  let dates := #[0.25, 0.5, 0.75, 1.0]

  let paths := simulatePaths nPaths seed spot r σ dates true

  -- Test 1: Reproducibility
  let paths2 := simulatePaths nPaths seed spot r σ dates true
  let reproOk : Bool := paths == paths2
  IO.println ("  Reproducibility (same seed): " ++ toString reproOk)

  -- Test 2: Drift check on log returns (first step)
  let mut sumLogReturn := 0.0
  for p in paths do
    if p.prices.size >= 2 then
      let ret := Float.log (p.prices[1]! / p.prices[0]!)
      sumLogReturn := sumLogReturn + ret

  let meanLogReturn := sumLogReturn / nPaths.toFloat
  let expectedDrift := (r - 0.5 * σ * σ) * 0.25
  let driftError := (meanLogReturn - expectedDrift).abs
  let driftOk : Bool := decide (driftError < 0.01)   -- tolerance for 50k paths
  IO.println ("  Drift check (first step): meanLogReturn=" ++ toString meanLogReturn ++
              ", expected=" ++ toString expectedDrift ++
              ", error=" ++ toString driftError ++
              ", ok=" ++ toString driftOk)

  if reproOk && driftOk then
    IO.println "B1 Property Tests: OK"
  else
    IO.println "B1 Property Tests: FAIL"
    IO.Process.exit 1

#eval! main
