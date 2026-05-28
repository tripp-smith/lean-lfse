import LFSE.Finance.Waterfall.Theory

namespace LFSE
namespace Test

open Finance

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

end Test
end LFSE
