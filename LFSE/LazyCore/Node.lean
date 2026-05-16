import LFSE.LazyCore.Basic

namespace LFSE
namespace LazyCore

inductive LazyNode where
  | const (id : NodeId) (label : String) (value : Float)
  | observable (id : NodeId) (name : String)
  | unary (id : NodeId) (label : String) (f : Float → Float) (child : LazyNode)
  | binary (id : NodeId) (label : String) (f : Float → Float → Float) (left right : LazyNode)
  | branch (id : NodeId) (label : String) (cond : LazyNode) (yes no : LazyNode)
  | effect (id : NodeId) (label : String) (action : IO Float)

def LazyNode.id : LazyNode → NodeId
  | .const id .. => id
  | .observable id .. => id
  | .unary id .. => id
  | .binary id .. => id
  | .branch id .. => id
  | .effect id .. => id

def LazyNode.label : LazyNode → String
  | .const _ label .. => label
  | .observable _ name => "obs:" ++ name
  | .unary _ label .. => label
  | .binary _ label .. => label
  | .branch _ label .. => label
  | .effect _ label .. => label

def LazyNode.children : LazyNode → List LazyNode
  | .const .. => []
  | .observable .. => []
  | .effect .. => []
  | .unary _ _ _ child => [child]
  | .binary _ _ _ left right => [left, right]
  | .branch _ _ cond yes no => [cond, yes, no]

def const (id : NodeId) (value : Float) : LazyNode :=
  .const id s!"const:{value}" value

def observable (id : NodeId) (name : String) : LazyNode :=
  .observable id name

def add (id : NodeId) (a b : LazyNode) : LazyNode :=
  .binary id "add" (· + ·) a b

def sub (id : NodeId) (a b : LazyNode) : LazyNode :=
  .binary id "sub" (· - ·) a b

def mul (id : NodeId) (a b : LazyNode) : LazyNode :=
  .binary id "mul" (· * ·) a b

def neg (id : NodeId) (a : LazyNode) : LazyNode :=
  .unary id "neg" (fun x => -x) a

def discount (id : NodeId) (rate time payoff : LazyNode) : LazyNode :=
  .binary id "discounted-payoff" (fun p df => p * df) payoff
    (.binary (id + 1002) "discount-factor" (fun r t => Float.exp (-(r * t))) rate time)

end LazyCore
end LFSE
