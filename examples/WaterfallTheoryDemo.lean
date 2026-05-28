import LFSEFinance

open LFSE
open LFSE.Finance

def demoTranches : List Tranche := [
  { name := "senior", balance := 1000.0, rate := 0.05 },
  { name := "mezz", balance := 500.0, rate := 0.08 },
  { name := "equity", balance := 250.0, rate := 0.12 }
]

#eval allocateWaterfall 100.0 demoTranches
#eval remainingAfterWaterfall 100.0 demoTranches

example :
    waterfallConservesCash 100.0 demoTranches = true := by
  native_decide

example :
    (remainingAfterWaterfall 200.0 demoTranches == 80.0) = true := by
  native_decide
