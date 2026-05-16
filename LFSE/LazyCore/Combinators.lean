import LFSE.LazyCore.Memo

namespace LFSE
namespace LazyCore

def lazyMap (id : NodeId) (label : String) (f : Float → Float) (node : LazyNode) : LazyNode :=
  .unary id label f node

def lazyBind (id : NodeId) (label : String) (node : LazyNode) (f : Float → LazyNode) : LazyNode :=
  .branch id label node (f 1.0) (f 0.0)

def lazyIf (id : NodeId) (cond yes no : LazyNode) : LazyNode :=
  .branch id "if" cond yes no

inductive LazyStream where
  | nil
  | cons (head : Thunk Float) (tail : Thunk LazyStream)
  deriving Inhabited

namespace LazyStream

partial def take : Nat → LazyStream → IO (List Float)
  | 0, _ => pure []
  | _, .nil => pure []
  | n + 1, .cons h t => do
      let xs ← take n t.get
      pure (h.get :: xs)

partial def map (f : Float → Float) : LazyStream → LazyStream
  | .nil => .nil
  | .cons h t => .cons (Thunk.mk fun _ => f h.get) (Thunk.mk fun _ => map f t.get)

partial def zipWith (f : Float → Float → Float) : LazyStream → LazyStream → LazyStream
  | .cons h1 t1, .cons h2 t2 => .cons (Thunk.mk fun _ => f h1.get h2.get) (Thunk.mk fun _ => zipWith f t1.get t2.get)
  | _, _ => .nil

partial def filter (p : Float → Bool) : LazyStream → LazyStream
  | .nil => .nil
  | .cons h t =>
      if p h.get then
        .cons h (Thunk.mk fun _ => filter p t.get)
      else
        filter p t.get

end LazyStream

end LazyCore
end LFSE
