import LFSE.Finance.Engine
import LFSE.Finance.Greeks

namespace LFSE
namespace Python

def forceNpvJson (_scenarioJson : String) : IO String := do
  let scenario : Finance.Scenario := { name := "python", ctx := Finance.baseContext, instrument := .option .call "ACME" 100.0 1.0 0.20 }
  match ← scenario.eval with
  | .ok result => pure result.toJson
  | .error err => pure ("{" ++ "\"error\":" ++ escapeJson err.message ++ "}")

def traceJson (_scenarioJson : String) : IO String := do
  let scenario : Finance.Scenario := { name := "python", ctx := Finance.baseContext, instrument := .option .call "ACME" 100.0 1.0 0.20 }
  match ← scenario.eval with
  | .ok result => pure result.toJson
  | .error err => pure ("{" ++ "\"error\":" ++ escapeJson err.message ++ "}")

def greeksJson (_scenarioJson : String) : IO String := do
  let scenario : Finance.Scenario := { name := "python", ctx := Finance.baseContext, instrument := .option .call "ACME" 100.0 1.0 0.20 }
  match ← computeGreeks scenario with
  | .ok greeks =>
      let pairs := greeks.map pairJson |> String.intercalate ","
      pure ("{" ++ "\"greeks\":[" ++ pairs ++ "]}")
  | .error err => pure ("{" ++ "\"error\":" ++ escapeJson err.message ++ "}")

end Python
end LFSE
