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
