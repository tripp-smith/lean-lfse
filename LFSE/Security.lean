import LFSE.Config

namespace LFSE
namespace Security

def validateScenarioPayload (cfg : Config) (payload : String) : LFSEExcept Unit :=
  if payload.length > cfg.maxInputBytes then
    .error (.securityError "payload exceeds configured input limit")
  else if payload.contains '\x00' then
    .error (.securityError "payload contains NUL byte")
  else
    .ok ()

def redactToken (token : Option String) : String :=
  match token with
  | none => "<none>"
  | some _ => "****"

end Security
end LFSE
