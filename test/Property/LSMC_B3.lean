import LFSE.Finance.LSMC.Algorithm
import LFSE.Finance.LSMC.Config

open LFSE.Finance.LSMC

/-!
# Property Tests for LSMC Core Algorithm (Phase B)

These tests exercise key correctness properties of the fully wired
simulatePaths + lsmcPrice implementation.
-/

def main : IO Unit := do
  IO.println "=== Phase B Property Tests (B3/B5) ==="

  let baseCfg : Config := {
    paths := 8000
    seed := 12345
    style := .bermudan #[0.333, 0.666, 1.0]
    basis := .laguerre 2
    antithetic := true
    ridge := 1e-8
  }

  -- 1. Reproducibility (same config + seed must give identical price)
  let p1 := lsmcPrice baseCfg (fun S => max 0.0 (100.0 - S)) 100.0 0.05 0.2 1.0
  let p2 := lsmcPrice baseCfg (fun S => max 0.0 (100.0 - S)) 100.0 0.05 0.2 1.0
  let reproOK := (p1 - p2).abs < 1e-12
  IO.println ("Reproducibility (same seed): " ++ toString reproOK ++ "  (p1=" ++ toString p1 ++ ", p2=" ++ toString p2 ++ ")")

  -- 2. Positive value for put with spot < strike (basic sanity)
  let putValue := lsmcPrice baseCfg (fun S => max 0.0 (110.0 - S)) 100.0 0.05 0.2 1.0
  let positiveOK := putValue > 0.0
  IO.println ("Positive value for ITM put: " ++ toString positiveOK ++ "  (value=" ++ toString putValue ++ ")")

  -- 3. Different seeds produce different (but reasonable) prices
  let cfgA := { baseCfg with seed := 1 }
  let cfgB := { baseCfg with seed := 999999 }
  let pa := lsmcPrice cfgA (fun S => max 0.0 (100.0 - S)) 100.0 0.05 0.2 1.0
  let pb := lsmcPrice cfgB (fun S => max 0.0 (100.0 - S)) 100.0 0.05 0.2 1.0
  let differentOK := (pa - pb).abs > 0.001
  IO.println ("Different seeds give different prices: " ++ toString differentOK ++ "  (pa=" ++ toString pa ++ ", pb=" ++ toString pb ++ ")")

  -- 4. American style with many steps produces reasonable early exercise value
  let americanCfg : Config := { baseCfg with style := .american 50 }
  let amer := lsmcPrice americanCfg (fun S => max 0.0 (100.0 - S)) 100.0 0.05 0.2 1.0
  let amerOK := amer > 0.0 && amer < 10.0
  IO.println ("American discretization produces plausible value: " ++ toString amerOK ++ "  (value=" ++ toString amer ++ ")")

  let allPass := reproOK && positiveOK && differentOK && amerOK
  IO.println ""
  if allPass then
    IO.println "Phase B Property Tests: PASS"
  else
    IO.println "Phase B Property Tests: SOME CHECKS FAILED"
    IO.Process.exit 1

#eval! main
