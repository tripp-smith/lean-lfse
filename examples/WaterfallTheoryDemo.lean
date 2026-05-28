import LFSEFinance

open LFSE
open LFSE.Finance
open LFSE.Finance.Waterfall.Theory

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

def exactDemoTranches : List (Exact.Tranche Rat) := [
  { name := "senior", balance := (100 : Rat), rate := (1 : Rat) },
  { name := "mezz", balance := (50 : Rat), rate := (1 : Rat) }
]

example (cash : Rat) :
    Exact.waterfallCashTotal cash exactDemoTranches = cash := by
  simpa using Exact.waterfallCashTotal_eq_cash cash exactDemoTranches
