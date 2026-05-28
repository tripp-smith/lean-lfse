import LFSE.LazyCore.Basic

namespace LFSE

structure Metrics where
  evaluations : Nat := 0
  cacheHits : Nat := 0
  forcedNodes : Nat := 0
  errors : Nat := 0
  deriving Repr, BEq

def Metrics.fromStats (stats : LazyCore.EvalStats) (evaluations : Nat := 1) (errors : Nat := 0) : Metrics :=
  { evaluations := evaluations, cacheHits := stats.memoHits, forcedNodes := stats.forced, errors := errors }

def Metrics.toPrometheus (m : Metrics) : String :=
  String.intercalate "\n" [
    "# HELP lfse_evaluations_total Total LFSE evaluations observed",
    "# TYPE lfse_evaluations_total counter",
    s!"lfse_evaluations_total {m.evaluations}",
    "# HELP lfse_cache_hits_total Total lazy memo-cache hits observed",
    "# TYPE lfse_cache_hits_total counter",
    s!"lfse_cache_hits_total {m.cacheHits}",
    "# HELP lfse_forced_nodes_total Total lazy nodes forced",
    "# TYPE lfse_forced_nodes_total counter",
    s!"lfse_forced_nodes_total {m.forcedNodes}",
    "# HELP lfse_errors_total Total LFSE errors observed",
    "# TYPE lfse_errors_total counter",
    s!"lfse_errors_total {m.errors}",
    ""
  ]

end LFSE
