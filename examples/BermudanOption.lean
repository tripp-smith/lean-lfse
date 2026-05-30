import LFSE

open LFSE
open LFSE.Finance

-- Phase A demo: Real Bermudan put using the new instrument + LSMC engine (post Phase B core)
def bermudanPutScenario : LazyScenario :=
  { name := "base"
    ctx := baseContext
    instrument := Finance.bermudanPut "ACME" 100.0 1.0 0.20 #[0.25, 0.5, 0.75, 1.0]
  }

def main : IO Unit := do
  let result ← Finance.forceWithEngine bermudanPutScenario (PricingEngine.lsmc { paths := 10000, seed := 42 })
  match result with
  | .ok r => IO.println s!"Bermudan Put NPV (LSMC): {r.npv}"
  | .error e => IO.println s!"Error: {e}"

#eval! main
