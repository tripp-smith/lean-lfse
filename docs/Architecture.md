# LFSE Architecture

LFSE is organized as a DSL-to-lazy-graph pipeline.

1. `LFSE.DSL` expands compile-time scenario syntax into ordinary Lean values.
2. `LFSE.Finance` converts observables and instruments into `LazyNode` graphs.
3. `LFSE.LazyCore` forces graph nodes through `Thunk` payloads and an `IO.Ref`
   memo cache keyed by stable node IDs.
4. `LFSE.Verify.Trace` records forced node events for audit output.
5. `LFSE.CLI` exposes build, eval, trace, and DOT export commands.

The lazy evaluator uses a shared `MemoCache` containing computed values, an
active stack for cycle detection, aggregate force/memo-hit statistics, and trace
events. Reusing a node ID inside a graph causes the second force to reuse the
memoized value; a recursive active ID is reported as `LFSEError.cycleDetected`.

Finance support includes spot/rate/vol observables, forwards, vanilla options,
swaps, early-exercise approximations, deterministic Monte Carlo streams,
scenario shocks, and cash-flow waterfalls.

## v2.1 Additions

The framework surface is now layered around registries and policy-aware forcing:

- `Registry` stores typed descriptors plus callable implementations for
  instruments, pricing engines, data providers, DSL extensions, and graph
  exporters.
- `LazyCore.Backend` controls effect policy and max-depth behavior.
- `LazyCore.Provenance` records lineage hashes and embeds provenance in forced
  trace events.
- `Finance.Engine` dispatches analytic, Monte Carlo, LSMC, and extension engines
  through registry lookups rather than a closed engine inductive.
- `Data.Provider` adapts CSV-like fixtures and `lean-columnar` Parquet/Arrow
  readers into `Context`.
- `Server.Basic` models `/health`, `/eval`, `/trace`, `/graph`, and `/metrics`
  as testable request handlers.

The root Lake package also exposes boundary libraries (`LFSECore`,
`LFSEFinance`, `LFSEData`, `LFSEServer`, and `LFSEPython`) so CI can validate
module boundaries while `LFSE` remains the v1-compatible facade.
