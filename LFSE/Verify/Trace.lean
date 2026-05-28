import LFSE.DSL.Elab

namespace LFSE
namespace Verify

inductive TraceLevel where
  | off
  | summary
  | verbose
  deriving Repr, BEq

def TraceLevel.ofNat : Nat → TraceLevel
  | 0 => .off
  | 1 => .summary
  | _ => .verbose

def renderTrace (events : List TraceEvent) : String :=
  String.intercalate "\n" (events.map (fun ev =>
    let provenance :=
      match ev.provenance with
      | some p => s!" provenance={p}"
      | none => ""
    match ev.value with
    | some v => s!"node={ev.nodeId} label={ev.label} value={v}{provenance}"
    | none => s!"node={ev.nodeId} label={ev.label}{provenance}"))

end Verify
end LFSE
