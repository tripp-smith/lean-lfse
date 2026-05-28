import LFSE.Finance.Engine
import LFSE.LazyCore.Visualization
import LFSE.Observability

namespace LFSE
namespace Server

structure Request where
  path : String
  body : String := ""
  token : Option String := none
  deriving Repr, BEq

structure Response where
  status : Nat
  contentType : String := "application/json"
  body : String
  deriving Repr, BEq

def jsonError (status : Nat) (message : String) : Response :=
  { status := status, body := "{" ++ "\"error\":" ++ escapeJson message ++ "}" }

def authorize (cfg : Config) (req : Request) : LFSEExcept Unit :=
  if req.path = "/health" then
    .ok ()
  else
    match cfg.authToken with
    | none => .ok ()
    | some expected =>
        if req.token == some expected then .ok () else .error (.securityError "invalid bearer token")

def defaultScenario : Finance.Scenario :=
  { name := "base", ctx := Finance.baseContext, instrument := .option .call "ACME" 100.0 1.0 0.20 }

def handleEval : IO Response := do
  match ← defaultScenario.eval with
  | .ok result => pure { status := 200, body := result.toJson }
  | .error err => pure (jsonError 500 err.message)

def handleTrace : IO Response := do
  match ← defaultScenario.eval with
  | .ok result => pure { status := 200, body := result.toJson }
  | .error err => pure (jsonError 500 err.message)

def handleGraph : IO Response := do
  pure {
    status := 200,
    body := LazyCore.toGraphJson (defaultScenario.instrument.payoffNode 100)
  }

def handleMetrics : IO Response := do
  pure { status := 200, contentType := "text/plain", body := Metrics.toPrometheus { evaluations := 1 } }

def handleRequest (cfg : Config) (req : Request) : IO Response := do
  if req.body.length > cfg.maxInputBytes then
    pure (jsonError 413 "request too large")
  else
    match authorize cfg req with
    | .error err => pure (jsonError 401 err.message)
    | .ok () =>
        match req.path with
        | "/health" => pure { status := 200, body := "{\"status\":\"ok\"}" }
        | "/eval" => handleEval
        | "/trace" => handleTrace
        | "/graph" => handleGraph
        | "/metrics" => handleMetrics
        | other => pure (jsonError 404 s!"unknown route `{other}`")

def runServerSmoke (cfg : Config) : IO UInt32 := do
  let health ← handleRequest cfg { path := "/health" }
  let eval ← handleRequest cfg { path := "/eval", token := cfg.authToken }
  IO.println s!"lfse server smoke: health={health.status} eval={eval.status} bind={cfg.serverHost}:{cfg.serverPort}"
  pure (if health.status == 200 && eval.status == 200 then 0 else 1)

end Server
end LFSE
