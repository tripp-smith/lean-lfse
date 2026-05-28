import LFSE.DSL.Macros
import LFSE.LazyCore.GraphViz
import LFSE.LazyCore.Provenance
import LFSE.Finance.Engine

namespace LFSE

abbrev LazyScenario := Finance.Scenario

def mkScenario (s : LazyScenario) : LazyScenario := s

def forceNPV (s : LazyScenario) (ctx : Context := s.ctx) : IO (LFSEExcept Float) := do
  let r ← Finance.forceWithEngine { s with ctx := ctx } Finance.PricingEngine.analytic
  pure (r.map (fun result => result.npv))

def forceTrace (s : LazyScenario) : IO (LFSEExcept (List TraceEvent)) := do
  let r ← s.eval
  pure (r.map (fun result => result.trace))

def forceMonteCarlo (nPaths : Nat) (seed : UInt64) (s : LazyScenario) : IO (LFSEExcept Float) := do
  let r ← Finance.forceWithEngine s (Finance.PricingEngine.monteCarlo nPaths seed)
  pure (r.map (fun result => result.npv))

def exportDot (s : LazyScenario) : String :=
  LazyCore.toDot (s.instrument.payoffNode 100)

def exportLineage (s : LazyScenario) : List String :=
  LazyCore.exportLineage (s.instrument.payoffNode 100)

end LFSE
