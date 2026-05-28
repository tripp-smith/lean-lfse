import LFSE.Finance.Waterfall.Theory

namespace LFSE
namespace Verify

theorem empty_payments_total_zero : Finance.paymentsTotal [] = 0.0 := rfl

theorem empty_waterfall_total_zero :
    Finance.paymentsTotal (Finance.allocateWaterfall 10.0 []) = 0.0 := by
  simpa using Finance.waterfall_empty 10.0

theorem empty_waterfall_no_payments (cash : Float) :
    Finance.allocateWaterfall cash [] = [] := by
  rfl

theorem zero_cash_single_tranche_payment (name : String) (balance rate : Float) :
    Finance.allocateWaterfall 0.0 [{ name := name, balance := balance, rate := rate }] =
      [{ tranche := name, amount := min 0.0 (balance * rate) }] := by
  simpa using Finance.waterfall_zero_cash_single_tranche_payment name balance rate

theorem empty_waterfall_cash_total (cash : Float) :
    Finance.waterfallCashTotal cash [] = 0.0 + cash := by
  simpa using Finance.waterfall_cash_total_empty cash

end Verify
end LFSE
