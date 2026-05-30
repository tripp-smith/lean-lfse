import LFSE.Finance.LSMC.Algorithm
import LFSE.Finance.LSMC.Config

open LFSE.Finance.LSMC

/-!
# Smoke Test for Wired LSMC (B3)
Simple executable smoke that confirms the fully wired implementation runs.
-/

def main : IO Unit := do
  IO.println "Phase B Smoke Test (fully wired lsmcPrice + real Basis + solver)"

  let cfg : Config := {
    paths := 4000
    seed := 42
    style := .bermudan #[0.5, 1.0]
    basis := .laguerre 3
    antithetic := true
    ridge := 1e-8
  }

  let putNPV := lsmcPrice cfg (fun S => max 0.0 (100.0 - S)) 100.0 0.05 0.2 1.0
  IO.println ("  Bermudan Put NPV: " ++ toString putNPV)

  if putNPV > 0.0 then
    IO.println "Smoke: PASS"
  else
    IO.println "Smoke: FAIL"

#eval! main
