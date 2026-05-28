import LFSE.Basic

namespace LFSE
namespace LazyCore

abbrev NodeId := Nat

structure EvalStats where
  forced : Nat := 0
  memoHits : Nat := 0
  effectCalls : Nat := 0
  backendDispatches : Nat := 0
  maxDepth : Nat := 0
  deriving Repr, BEq

end LazyCore
end LFSE
