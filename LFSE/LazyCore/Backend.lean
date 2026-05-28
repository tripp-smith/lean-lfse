import LFSE.LazyCore.Memo

namespace LFSE
namespace LazyCore

structure EvalBackend where
  name : String
  maxDepth : Nat := 100000
  allowEffects : Bool := true
  deriving Repr, BEq

def EvalBackend.default : EvalBackend :=
  { name := "default" }

def EvalBackend.audit : EvalBackend :=
  { name := "audit", allowEffects := false }

partial def hasEffect : LazyNode -> Bool
  | .effect .. => true
  | node => node.children.any hasEffect

def forceWithBackend (backend : EvalBackend) (ctx : Context) (node : LazyNode) : IO (LFSEExcept Float × EvalStats × List TraceEvent) := do
  if !backend.allowEffects && hasEffect node then
    pure (.error (.evaluationFailed s!"backend `{backend.name}` does not allow effects"), {}, [])
  else
    let cache <- MemoCache.empty
    let stats <- cache.stats.get
    cache.stats.set { stats with backendDispatches := stats.backendDispatches + 1 }
    let res <-
      match validateNodeIds node with
      | .ok () => forceWithFuel backend.maxDepth ctx cache node
      | .error err => pure (.error err)
    let stats <- cache.stats.get
    let trace <- cache.trace.get
    pure (res, stats, trace.reverse)

end LazyCore
end LFSE
