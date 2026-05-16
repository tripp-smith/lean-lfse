import LFSE.DSL.Macros
import LFSE.LazyCore.GraphViz

namespace LFSE

abbrev LazyScenario := Finance.Scenario

def mkScenario (s : LazyScenario) : LazyScenario := s

def forceNPV (s : LazyScenario) (ctx : Context := s.ctx) : IO (LFSEExcept Float) := do
  let r ← Finance.price ctx s.instrument
  pure (r.map (fun result => result.npv))

def forceTrace (s : LazyScenario) : IO (LFSEExcept (List TraceEvent)) := do
  let r ← s.eval
  pure (r.map (fun result => result.trace))

def forceMonteCarlo (nPaths : Nat) (seed : UInt64) (s : LazyScenario) : IO (LFSEExcept Float) := do
  match s.instrument with
  | .option .call underlying strike maturity vol =>
      match s.ctx.lookup ("spot." ++ underlying), s.ctx.lookup "rate.usd" with
      | .ok spot, .ok rate =>
          pure (.ok (← Finance.monteCarloCall nPaths seed spot strike rate vol maturity))
      | .error err, _ => pure (.error err)
      | _, .error err => pure (.error err)
  | .option .put .. => pure (.error (.unsupportedMonteCarlo "put option"))
  | .forward .. => pure (.error (.unsupportedMonteCarlo "forward"))
  | .swap .. => pure (.error (.unsupportedMonteCarlo "swap"))

def exportDot (s : LazyScenario) : String :=
  LazyCore.toDot (s.instrument.payoffNode 100)

end LFSE
