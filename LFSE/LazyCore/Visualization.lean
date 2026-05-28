import LFSE.LazyCore.GraphViz
import LFSE.LazyCore.Provenance

namespace LFSE
namespace LazyCore

partial def mermaidLines (seen : List NodeId) (node : LazyNode) : List NodeId × List String :=
  if seen.contains node.id then
    (seen, [])
  else
    let current := s!"  n{node.id}[\"{node.label}\"]"
    let edgeLines := node.children.map (fun c => s!"  n{node.id} --> n{c.id}")
    node.children.foldl
      (fun acc child =>
        let (seenAcc, linesAcc) := acc
        let (seenNext, linesNext) := mermaidLines seenAcc child
        (seenNext, linesAcc ++ linesNext))
      (node.id :: seen, [current] ++ edgeLines)

def toMermaid (node : LazyNode) : String :=
  let (_, lines) := mermaidLines [] node
  "graph TD\n" ++ String.intercalate "\n" lines ++ "\n"

def toGraphJson (node : LazyNode) : String :=
  let lineage := exportLineage node |>.map LFSE.escapeJson |> String.intercalate ","
  "{" ++ "\"dot\":" ++ LFSE.escapeJson (toDot node) ++
    ",\"mermaid\":" ++ LFSE.escapeJson (toMermaid node) ++
    ",\"lineage\":[" ++ lineage ++ "]}"

end LazyCore
end LFSE
