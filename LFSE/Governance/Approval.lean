import LFSE.Governance.Model

namespace LFSE
namespace Governance

def canRunProduction (m : ModelVersion) : Bool :=
  m.status == .approved

def auditLine (m : ModelVersion) : String :=
  s!"{m.name}@{m.version}:{repr m.status}:{m.lineageHash}"

end Governance
end LFSE
