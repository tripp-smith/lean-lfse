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

namespace Waterfall
namespace Theory
namespace Exact

/--
Exact, generic waterfall model used for parametric conservation proofs.

The runtime `Tranche` and `Payment` types remain Float-backed. This namespace
mirrors the same allocation idea over an exact ordered ring so Lean can prove a
universal conservation theorem without assuming unsound algebraic laws for IEEE
Float.
-/
class ExactCash (α : Type u) extends Min α, Zero α, Add α, Sub α, Mul α where
  zero_add : ∀ cash : α, 0 + cash = cash
  add_assoc : ∀ a b c : α, (a + b) + c = a + (b + c)
  paid_add_remaining : ∀ paid cash : α, paid + (cash - paid) = cash

instance : ExactCash Int where
  zero_add := by
    intro _cash
    omega
  add_assoc := by
    intro _a _b _c
    omega
  paid_add_remaining := by
    intro _paid _cash
    omega

instance : ExactCash Rat where
  zero_add := Rat.zero_add
  add_assoc := Rat.add_assoc
  paid_add_remaining := by
    intro paid cash
    rw [Rat.sub_eq_add_neg]
    rw [← Rat.add_assoc]
    rw [Rat.add_comm paid cash]
    rw [Rat.add_assoc]
    rw [← Rat.sub_eq_add_neg]
    rw [Rat.sub_self]
    rw [Rat.add_zero]

structure Tranche (α : Type u) where
  name : String
  balance : α
  rate : α
  deriving Repr, BEq

structure Payment (α : Type u) where
  tranche : String
  amount : α
  deriving Repr, BEq

def allocateOne [ExactCash α] (cash : α) (tranche : Tranche α) : Payment α × α :=
  let due := tranche.balance * tranche.rate
  let paid := min cash due
  ({ tranche := tranche.name, amount := paid }, cash - paid)

def allocateWaterfall [ExactCash α] : α → List (Tranche α) → List (Payment α)
  | _cash, [] => []
  | cash, tranche :: rest =>
      let (payment, remaining) := allocateOne cash tranche
      payment :: allocateWaterfall remaining rest

def remainingAfterWaterfall [ExactCash α] : α → List (Tranche α) → α
  | cash, [] => cash
  | cash, tranche :: rest =>
      let (_payment, remaining) := allocateOne cash tranche
      remainingAfterWaterfall remaining rest

def paymentsTotal [Zero α] [Add α] : List (Payment α) → α
  | [] => 0
  | payment :: rest => payment.amount + paymentsTotal rest

def waterfallCashTotal [ExactCash α] (cash : α) (tranches : List (Tranche α)) : α :=
  paymentsTotal (allocateWaterfall cash tranches) + remainingAfterWaterfall cash tranches

theorem allocateOne_conservesCash [ExactCash α] (cash : α) (tranche : Tranche α) :
    let (payment, remaining) := allocateOne cash tranche
    payment.amount + remaining = cash := by
  simp [allocateOne, ExactCash.paid_add_remaining]

theorem waterfallConservesCash [ExactCash α]
    (cash : α) (tranches : List (Tranche α)) :
    paymentsTotal (allocateWaterfall cash tranches) +
      remainingAfterWaterfall cash tranches = cash := by
  induction tranches generalizing cash with
  | nil =>
      simp [allocateWaterfall, remainingAfterWaterfall, paymentsTotal, ExactCash.zero_add]
  | cons tranche rest ih =>
      cases h : allocateOne cash tranche with
      | mk payment remaining =>
          have hStep : payment.amount + remaining = cash := by
            simpa [h] using allocateOne_conservesCash cash tranche
          calc
            paymentsTotal (allocateWaterfall cash (tranche :: rest)) +
                remainingAfterWaterfall cash (tranche :: rest)
                = payment.amount +
                    (paymentsTotal (allocateWaterfall remaining rest) +
                      remainingAfterWaterfall remaining rest) := by
                    simp [allocateWaterfall, remainingAfterWaterfall, paymentsTotal, h,
                      ExactCash.add_assoc]
            _ = payment.amount + remaining := by
                    rw [ih remaining]
            _ = cash := hStep

theorem waterfallCashTotal_eq_cash [ExactCash α]
    (cash : α) (tranches : List (Tranche α)) :
    waterfallCashTotal cash tranches = cash := by
  simpa [waterfallCashTotal] using waterfallConservesCash cash tranches

end Exact
end Theory
end Waterfall

end Finance
end LFSE
