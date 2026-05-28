import LFSE.LazyCore.Node

namespace LFSE
namespace LazyCore

structure Lineage where
  nodeId : NodeId
  label : String
  hash : String
  deriving Repr, BEq

structure HashAlgorithm where
  name : String
  hash : String -> String

def deterministicHash (s : String) : String :=
  toString (s.foldl (fun acc c => acc * 33 + c.toNat) 5381)

def defaultHashAlgorithm : HashAlgorithm := {
  name := "lfse-deterministic-v1",
  hash := deterministicHash
}

partial def nodeFingerprint (node : LazyNode) : String :=
  let childHashes := node.children.map nodeFingerprint |> String.intercalate "|"
  toString node.id ++ ":" ++ node.label ++ ":" ++ childHashes

def nodeProvenanceHash (node : LazyNode) (algorithm : HashAlgorithm := defaultHashAlgorithm) : String :=
  algorithm.name ++ ":" ++ algorithm.hash (nodeFingerprint node)

partial def collectLineage (node : LazyNode) : List Lineage :=
  let self := { nodeId := node.id, label := node.label, hash := nodeProvenanceHash node }
  self :: (node.children.map collectLineage).flatten

def exportLineage (node : LazyNode) : List String :=
  collectLineage node |>.map (fun l => s!"{l.nodeId}:{l.label}:{l.hash}")

end LazyCore
end LFSE
