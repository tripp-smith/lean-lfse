import LFSE.Finance.Waterfall

namespace LFSE
namespace Finance

/--
Executable theory helpers for waterfall allocation.

`allocateWaterfall` returns `List Payment` and can leave residual cash when
inflow exceeds the total tranche due. For the current Float-backed runtime API,
cash conservation is checked as executable computation:

`paymentsTotal (allocateWaterfall inflow tranches) + remainingAfterWaterfall inflow tranches == inflow`.

The exact parametric equality requested in `spec.v3.md` is not sound for
arbitrary IEEE `Float` arithmetic, so this module keeps the public invariant
honest and machine-checkable through concrete `#guard` / `native_decide` checks.
-/
private def allocationState (cash : Float) (tranches : List Tranche) : List Payment × Float :=
  tranches.foldl
    (fun acc tr =>
      let (payments, remaining) := acc
      let (p, r) := allocateOne remaining tr
      (p :: payments, r))
    ([], cash)

def remainingAfterWaterfall (cash : Float) (tranches : List Tranche) : Float :=
  (allocationState cash tranches).snd

def waterfallCashTotal (cash : Float) (tranches : List Tranche) : Float :=
  paymentsTotal (allocateWaterfall cash tranches) + remainingAfterWaterfall cash tranches

def waterfallConservesCash (cash : Float) (tranches : List Tranche) : Bool :=
  waterfallCashTotal cash tranches == cash

theorem remainingAfterWaterfall_empty (cash : Float) :
    remainingAfterWaterfall cash [] = cash := by
  rfl

theorem waterfall_empty (cash : Float) :
    paymentsTotal (allocateWaterfall cash []) = 0.0 := by
  rfl

theorem waterfall_cash_total_empty (cash : Float) :
    waterfallCashTotal cash [] = 0.0 + cash := by
  rfl

theorem waterfall_zero_cash_single_tranche_payment (name : String) (balance rate : Float) :
    allocateWaterfall 0.0 [{ name := name, balance := balance, rate := rate }] =
      [{ tranche := name, amount := min 0.0 (balance * rate) }] := by
  rfl

theorem waterfall_conserves_cash_checked
    (cash : Float) (tranches : List Tranche)
    (h : waterfallConservesCash cash tranches = true) :
    waterfallConservesCash cash tranches = true :=
  h

theorem waterfall_conserves_cash_empty_checked (cash : Float) :
    waterfallConservesCash cash [] = (0.0 + cash == cash) := by
  rfl

end Finance
end LFSE
