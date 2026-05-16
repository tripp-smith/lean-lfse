import LFSE.LazyCore.Node

namespace LFSE
namespace LazyCore

partial def dotLines (seen : List NodeId) (node : LazyNode) : List NodeId × List String :=
  if seen.contains node.id then
    (seen, [])
  else
    let current := s!"  n{node.id} [label=\"{node.label}\"];"
    let edgeLines := node.children.map (fun c => s!"  n{node.id} -> n{c.id};")
    let step := (node.children.foldl
      (fun acc child =>
        let (seenAcc, linesAcc) := acc
        let (seenNext, linesNext) := dotLines seenAcc child
        (seenNext, linesAcc ++ linesNext))
      (node.id :: seen, [current] ++ edgeLines))
    step

def toDot (node : LazyNode) : String :=
  let (_, lines) := dotLines [] node
  "digraph LFSE {\n" ++ String.intercalate "\n" lines ++ "\n}\n"

end LazyCore
end LFSE
