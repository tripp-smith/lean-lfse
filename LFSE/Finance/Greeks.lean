import LFSE.Finance.Scenario

namespace LFSE
namespace Finance

def bumpContext (ctx : Context) (observable : String) (bump : Float) : Context :=
  let current := ctx.market.getD observable 0.0
  ctx.withMarket observable (current + bump)

def computeDelta (scenario : Scenario) (observable : String) (bump : Float := 0.01) : IO (LFSEExcept Float) := do
  let up := { scenario with ctx := bumpContext scenario.ctx observable bump }
  let down := { scenario with ctx := bumpContext scenario.ctx observable (-bump) }
  match ← up.eval, ← down.eval with
  | .ok u, .ok d => pure (.ok ((u.npv - d.npv) / (2.0 * bump)))
  | .error err, _ => pure (.error err)
  | _, .error err => pure (.error err)

def computeGamma (scenario : Scenario) (observable : String) (bump : Float := 0.01) : IO (LFSEExcept Float) := do
  let up := { scenario with ctx := bumpContext scenario.ctx observable bump }
  let down := { scenario with ctx := bumpContext scenario.ctx observable (-bump) }
  match ← up.eval, ← scenario.eval, ← down.eval with
  | .ok u, .ok mid, .ok d => pure (.ok ((u.npv - 2.0 * mid.npv + d.npv) / (bump * bump)))
  | .error err, _, _ => pure (.error err)
  | _, .error err, _ => pure (.error err)
  | _, _, .error err => pure (.error err)

def computeVega : Scenario -> Float -> IO (LFSEExcept Float)
  | s@{ instrument := .option kind u strike maturity vol, .. }, bump => do
      let up := { s with instrument := .option kind u strike maturity (vol + bump) }
      let down := { s with instrument := .option kind u strike maturity (vol - bump) }
      match ← up.eval, ← down.eval with
      | .ok ures, .ok dres => pure (.ok ((ures.npv - dres.npv) / (2.0 * bump)))
      | .error err, _ => pure (.error err)
      | _, .error err => pure (.error err)
  | _, _ => pure (.error (.unsupportedMonteCarlo "vega for non-option instrument"))

def computeGreeks (scenario : Scenario) (observable : String := "spot.ACME") : IO (LFSEExcept (List (String × Float))) := do
  match ← computeDelta scenario observable, ← computeGamma scenario observable, ← computeVega scenario 0.01 with
  | .ok d, .ok g, .ok v => pure (.ok [("delta", d), ("gamma", g), ("vega", v)])
  | .error err, _, _ => pure (.error err)
  | _, .error err, _ => pure (.error err)
  | _, _, .error _err =>
      match ← computeDelta scenario observable, ← computeGamma scenario observable with
      | .ok d, .ok g => pure (.ok [("delta", d), ("gamma", g)])
      | .error e, _ => pure (.error e)
      | _, .error e => pure (.error e)

end Finance

def computeGreeks := Finance.computeGreeks

end LFSE
