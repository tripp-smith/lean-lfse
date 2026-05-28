namespace LFSE
namespace Governance

inductive ApprovalStatus where
  | draft
  | approved
  | retired
  deriving Repr, BEq

structure ModelVersion where
  name : String
  version : String
  status : ApprovalStatus := .draft
  lineageHash : String := ""
  approver : Option String := none
  deriving Repr, BEq

def ModelVersion.approve (m : ModelVersion) (user : String) : ModelVersion :=
  { m with status := .approved, approver := some user }

end Governance
end LFSE
