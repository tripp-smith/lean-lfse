import LFSE.Finance.LSMC

def main : IO Unit := do
  let npv ← LFSE.Finance.priceBermudanPut {} 100 100 0.06 0.2 1.0
  IO.println s!"Bermudan put NPV (new Gaussian + Linalg LSMC): {npv}"

#eval main
