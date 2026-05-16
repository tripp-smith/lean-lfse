import LFSE.Finance.Waterfall

namespace LFSE
namespace Verify

theorem empty_payments_total_zero : Finance.paymentsTotal [] = 0.0 := rfl

theorem empty_waterfall_total_zero :
    Finance.paymentsTotal (Finance.allocateWaterfall 10.0 []) = 0.0 := by
  rfl

theorem empty_waterfall_no_payments (cash : Float) :
    Finance.allocateWaterfall cash [] = [] := by
  rfl

theorem zero_cash_single_tranche_payment (name : String) (balance rate : Float) :
    Finance.allocateWaterfall 0.0 [{ name := name, balance := balance, rate := rate }] =
      [{ tranche := name, amount := min 0.0 (balance * rate) }] := by
  rfl

end Verify
end LFSE
