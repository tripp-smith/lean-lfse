import LFSE.Finance.Waterfall.Theory

namespace LFSE
namespace Test

open Finance
open Finance.Waterfall.Theory

def senior : Tranche := { name := "senior", balance := 1000.0, rate := 0.05 }
def mezz : Tranche := { name := "mezz", balance := 500.0, rate := 0.08 }
def equity : Tranche := { name := "equity", balance := 250.0, rate := 0.12 }

#guard paymentsTotal (allocateWaterfall 100.0 [senior, mezz, equity]) == 100.0
#guard remainingAfterWaterfall 100.0 [senior, mezz, equity] == 0.0
#guard paymentsTotal (allocateWaterfall 20.0 [senior, mezz, equity]) == 20.0
#guard remainingAfterWaterfall 20.0 [senior, mezz, equity] == 0.0
#guard paymentsTotal (allocateWaterfall 200.0 [senior, mezz, equity]) == 120.0
#guard remainingAfterWaterfall 200.0 [senior, mezz, equity] == 80.0
#guard paymentsTotal (allocateWaterfall 25.0 []) == 0.0
#guard remainingAfterWaterfall 25.0 [] == 25.0

example (cash : Float) :
    waterfallCashTotal cash [] = 0.0 + cash := by
  simpa using waterfall_cash_total_empty cash

example :
    waterfallConservesCash 100.0 [senior, mezz, equity] = true := by
  native_decide

def exactRatTranches : List (Exact.Tranche Rat) := [
  { name := "senior", balance := (100 : Rat), rate := (1 : Rat) },
  { name := "mezz", balance := (50 : Rat), rate := (1 : Rat) },
  { name := "equity", balance := (25 : Rat), rate := (1 : Rat) }
]

def exactIntTranches : List (Exact.Tranche Int) := [
  { name := "senior", balance := (100 : Int), rate := (1 : Int) },
  { name := "mezz", balance := (50 : Int), rate := (1 : Int) },
  { name := "equity", balance := (25 : Int), rate := (1 : Int) }
]

#guard Exact.paymentsTotal (Exact.allocateWaterfall (120 : Rat) exactRatTranches) == (120 : Rat)
#guard Exact.remainingAfterWaterfall (200 : Rat) exactRatTranches == (25 : Rat)
#guard Exact.paymentsTotal (Exact.allocateWaterfall (120 : Int) exactIntTranches) == (120 : Int)
#guard Exact.remainingAfterWaterfall (200 : Int) exactIntTranches == (25 : Int)
#guard Exact.waterfallCashTotal (0 : Int) exactIntTranches == (0 : Int)
#guard Exact.waterfallCashTotal (-10 : Int) exactIntTranches == (-10 : Int)

example (cash : Rat) :
    Exact.waterfallCashTotal cash exactRatTranches = cash := by
  simpa using Exact.waterfallCashTotal_eq_cash cash exactRatTranches

example (cash : Int) :
    Exact.waterfallCashTotal cash exactIntTranches = cash := by
  simpa using Exact.waterfallCashTotal_eq_cash cash exactIntTranches

example (cash : Rat) :
    Exact.paymentsTotal (Exact.allocateWaterfall cash []) +
      Exact.remainingAfterWaterfall cash [] = cash := by
  simpa using Exact.waterfallConservesCash cash ([] : List (Exact.Tranche Rat))

end Test
end LFSE
