import LFSE.Finance.Scenario

namespace LFSE
namespace Finance

structure Tranche where
  name : String
  balance : Float
  rate : Float
  deriving Repr, BEq

structure Payment where
  tranche : String
  amount : Float
  deriving Repr, BEq

def allocateOne (cash : Float) (tranche : Tranche) : Payment × Float :=
  let due := tranche.balance * tranche.rate
  let paid := min cash due
  ({ tranche := tranche.name, amount := paid }, cash - paid)

def allocateWaterfall (cash : Float) (tranches : List Tranche) : List Payment :=
  (tranches.foldl
    (fun acc tr =>
      let (payments, remaining) := acc
      let (p, r) := allocateOne remaining tr
      (p :: payments, r))
    ([], cash)).fst.reverse

def paymentsTotal (payments : List Payment) : Float :=
  payments.foldl (fun acc p => acc + p.amount) 0.0

theorem paymentsTotal_nil : paymentsTotal [] = 0.0 := rfl

end Finance
end LFSE
