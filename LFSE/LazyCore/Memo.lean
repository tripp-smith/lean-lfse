import Std.Data.HashMap
import LFSE.LazyCore.Node
import LFSE.LazyCore.Provenance

namespace LFSE
namespace LazyCore

structure MemoCache where
  values : IO.Ref (Std.HashMap NodeId Float)
  active : IO.Ref (Std.HashMap NodeId Unit)
  stats : IO.Ref EvalStats
  trace : IO.Ref (List TraceEvent)

def validateNodeIds (node : LazyNode) : LFSEExcept Unit :=
  let rec go (fuel : Nat) (seen : Std.HashMap NodeId String) (pending : List LazyNode) : LFSEExcept Unit :=
    match fuel with
    | 0 => .error (.evaluationFailed "node-id validation exceeded traversal fuel")
    | fuel + 1 =>
    match pending with
    | [] => .ok ()
    | n :: rest =>
        match seen.get? n.id with
        | some label =>
            if label == n.label then
              go fuel seen rest
            else
              .error (.duplicateNodeId n.id label n.label)
        | none => go fuel (seen.insert n.id n.label) (n.children ++ rest)
  go 100000 {} [node]

def MemoCache.empty : IO MemoCache := do
  pure {
    values := ← IO.mkRef {}
    active := ← IO.mkRef {}
    stats := ← IO.mkRef {}
    trace := ← IO.mkRef []
  }

def markTrace (cache : MemoCache) (node : LazyNode) (value : Float) (metadata : List (String × String) := []) : IO Unit := do
  let events ← cache.trace.get
  cache.trace.set ({
    nodeId := node.id,
    label := node.label,
    value := some value,
    provenance := some (nodeProvenanceHash node),
    metadata := metadata
  } :: events)

def bumpForced (cache : MemoCache) : IO Unit := do
  let s ← cache.stats.get
  cache.stats.set { s with forced := s.forced + 1 }

def bumpHit (cache : MemoCache) : IO Unit := do
  let s ← cache.stats.get
  cache.stats.set { s with memoHits := s.memoHits + 1 }

def bumpEffect (cache : MemoCache) : IO Unit := do
  let s ← cache.stats.get
  cache.stats.set { s with effectCalls := s.effectCalls + 1 }

def noteDepth (cache : MemoCache) (depth : Nat) : IO Unit := do
  let s ← cache.stats.get
  cache.stats.set { s with maxDepth := max s.maxDepth depth }

partial def forceWithFuelAt (fuel depth : Nat) (ctx : Context) (cache : MemoCache) (node : LazyNode) : IO (LFSEExcept Float) := do
  noteDepth cache depth
  if fuel == 0 then
    pure (.error (.evaluationFailed "lazy evaluation exceeded recursion depth"))
  else
  let values ← cache.values.get
  match values.get? node.id with
  | some value =>
      bumpHit cache
      markTrace cache node value [("cache", "hit")]
      pure (.ok value)
  | none =>
      let active ← cache.active.get
      if active.contains node.id then
        pure (.error (.cycleDetected node.id))
      else
        cache.active.set (active.insert node.id ())
        let finish (res : LFSEExcept Float) : IO (LFSEExcept Float) := do
          cache.active.set active
          match res with
          | .ok value =>
              cache.values.modify (fun m => m.insert node.id value)
              bumpForced cache
              markTrace cache node value [("cache", "miss")]
          | .error _ => pure ()
          pure res
        match node with
        | .const _ _ value => finish (.ok value)
        | .observable _ name => finish (ctx.lookup name)
        | .effect _ _ action =>
            bumpEffect cache
            let value ← action
            finish (.ok value)
        | .unary _ _ f child =>
            match ← forceWithFuelAt (fuel - 1) (depth + 1) ctx cache child with
            | .ok value => finish (.ok (f value))
            | .error err => finish (.error err)
        | .binary _ _ f left right =>
            match ← forceWithFuelAt (fuel - 1) (depth + 1) ctx cache left with
            | .error err => finish (.error err)
            | .ok lv =>
                match ← forceWithFuelAt (fuel - 1) (depth + 1) ctx cache right with
                | .ok rv => finish (.ok (f lv rv))
                | .error err => finish (.error err)
        | .branch _ _ cond yes no =>
            match ← forceWithFuelAt (fuel - 1) (depth + 1) ctx cache cond with
            | .error err => finish (.error err)
            | .ok cv =>
                if cv != 0.0 then
                  match ← forceWithFuelAt (fuel - 1) (depth + 1) ctx cache yes with
                  | .ok value => finish (.ok value)
                  | .error err => finish (.error err)
                else
                  match ← forceWithFuelAt (fuel - 1) (depth + 1) ctx cache no with
                  | .ok value => finish (.ok value)
                  | .error err => finish (.error err)

def forceWithFuel (fuel : Nat) (ctx : Context) (cache : MemoCache) (node : LazyNode) : IO (LFSEExcept Float) :=
  forceWithFuelAt fuel 0 ctx cache node

def forceWith (ctx : Context) (cache : MemoCache) (node : LazyNode) : IO (LFSEExcept Float) :=
  forceWithFuel 100000 ctx cache node

def force (ctx : Context) (node : LazyNode) : IO (LFSEExcept Float × EvalStats × List TraceEvent) := do
  let cache ← MemoCache.empty
  let res ←
    match validateNodeIds node with
    | .ok () => forceWith ctx cache node
    | .error err => pure (.error err)
  let stats ← cache.stats.get
  let trace ← cache.trace.get
  pure (res, stats, trace.reverse)

def forcePartial (ctx : Context) (node : LazyNode) : IO (LFSEExcept Float) := do
  let cache ← MemoCache.empty
  match validateNodeIds node with
  | .ok () => forceWith ctx cache node
  | .error err => pure (.error err)

end LazyCore
end LFSE
