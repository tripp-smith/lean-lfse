# lean-lfse

`lean-lfse` is the Lazy Financial Scenario Engine: a Lean 4 library and CLI for
describing financial scenarios as auditable lazy computation graphs. It is built
for workflows where the same expensive market data, pricing logic, and stress
inputs are reused across many reports, and where it matters that the model is
inspectable, reproducible, and backed by executable tests.

LFSE combines three ideas that are usually kept separate:

- a compile-time financial DSL embedded in Lean;
- a memoized lazy DAG that only forces demanded subcomputations;
- verification-oriented outputs: traces, DOT graph export, tests, and sample
  Lean proofs.

## Why This Project Is Different

Most pricing tools optimize for raw numerical breadth first. LFSE optimizes for
auditability and controlled evaluation. A scenario is not just a function from
market data to a number; it is a graph whose forced nodes can be traced, shared,
exported, and tested.

The unique pieces are:

- **Lazy by construction:** `LazyNode` graphs are forced through a shared
  `MemoCache`, so repeated subgraphs evaluate once and are reused.
- **Inspectable execution:** each forced node can emit a `TraceEvent`, and the
  same graph can be exported to DOT for review.
- **Lean-native DSL:** scenario syntax macro-expands into ordinary Lean values,
  avoiding a runtime parser while keeping examples readable.
- **Reproducible stochastic models:** Monte Carlo uses a deterministic PCG-style
  generator with explicit seed and path count.
- **Verification-friendly design:** errors are explicit, tests exercise sharing
  and cycle detection, and proof modules compile with the library.
- **CLI plus library:** the same core is usable from Lean code or from shell
  workflows such as JSON evaluation and graph export.

## How It Works

The engine follows a small pipeline:

```text
DSL / Lean scenario
  -> Finance instrument and market observables
  -> LazyNode DAG
  -> Memoized force with cycle detection
  -> Result, trace, JSON/YAML, or DOT graph
```

The central lazy evaluator lives in `LFSE.LazyCore`. A `LazyNode` can represent a
constant, observable lookup, unary/binary computation, conditional branch, or
effectful thunk. `forceWith` evaluates a node against a `Context`, writes computed
values into an `IO.Ref`-backed `HashMap`, tracks active node IDs to reject cycles,
and records trace events.

Finance modules then build these nodes:

- `Observable` resolves market keys such as `spot.ACME` and `rate.usd`.
- `Instrument` maps forwards, vanilla options, and swaps to lazy payoff graphs.
- `Scenario` adds stress/what-if behavior by transforming the market context.
- `MonteCarlo` provides deterministic lazy path generation and terminal sampling.
- `Waterfall` allocates cash through ordered tranches.

## Quickstart

```bash
lake build
lake test
lake exe lfse -- eval examples/BermudanOption.lean --scenario base --format json
lake exe lfse -- trace examples/BermudanOption.lean --trace-level 2
lake exe lfse -- export-dot examples/BermudanOption.lean --output build/bermudan.dot
lake run benchmarks
```

Package the project:

```bash
lake pack
```

## Library Usage

```lean
import LFSE

open LFSE

def scenario : LazyScenario :=
  #scenario base => callOption("ACME", 100.0, 1.0, 0.20)

#eval forceNPV scenario
#eval forceMonteCarlo 1000 42 scenario
#eval IO.println (exportDot scenario)
```

Key public APIs:

- `LFSE.mkScenario`
- `LFSE.forceNPV`
- `LFSE.forceMonteCarlo`
- `LFSE.forceTrace`
- `LFSE.exportDot`
- `LFSE.Context`
- `LFSE.Result`
- `LFSE.LFSEError`

Core DSL forms:

```lean
#scenario base => callOption("ACME", 100.0, 1.0, 0.20)
#scenario hedge => putOption("ACME", 95.0, 1.0, 0.25)
#scenario fwd => forward("ACME", 100.0, 1.0)
#scenario rates => swap(1000000.0, 0.04, 0.052, 5.0)
```

## CLI Usage

```bash
lake exe lfse -- build <file.lean>
lake exe lfse -- eval <file.lean> --scenario base --format json
lake exe lfse -- eval <file.lean> --scenario base --format yaml
lake exe lfse -- trace <file.lean> --trace-level 2
lake exe lfse -- export-dot <file.lean> --output build/graph.dot
```

Flags:

- `--scenario NAME`: choose a scenario name, default `base`.
- `--format json|yaml`: output format for `eval`, default `json`.
- `--paths N`: Monte Carlo path count used by `eval`.
- `--seed N`: deterministic Monte Carlo seed.
- `--trace-level N`: `0` disables trace output, `1+` prints forced nodes.
- `--output PATH`: destination path for `export-dot`.

Exit codes:

- `0`: success.
- `1`: evaluation, graph, or data error.
- `2`: invalid CLI invocation or missing file for `build`.

## Examples

- `examples/BermudanOption.lean` demonstrates a callable scenario shape using
  the option DSL and NPV forcing.
- `examples/PortfolioStress.lean` shows a base scenario plus spot shocks.
- `examples/WaterfallABS.lean` allocates cash through ordered ABS tranches.
- `examples/Waterfall.lean` evaluates a swap-like waterfall scenario through the
  public NPV API.
- `examples/SimpleMC.lean` runs deterministic Monte Carlo with a fixed seed.
- `examples/graphviz.lean` prints a DOT graph.
- `examples/RealWorldScenarios.lean` runs a synthetic multi-asset portfolio
  through macro regimes, Monte Carlo risk, and ABS waterfall cases.

## Realistic Synthetic Scenario Suite

The project includes a reusable synthetic scenario suite in
`LFSE.Finance.Synthetic`. It is designed to show why lazy scenario evaluation is
useful in real workflows without requiring proprietary market data.

The suite includes:

- **Market regimes:** base, recession, inflation shock, and credit tightening
  contexts with different equity, commodity, rate, volatility, and recovery
  assumptions.
- **Multi-asset portfolio:** equity options, commodity forwards/options, and
  rates swaps with quantities large enough to behave like a desk-level book.
- **Macro stress grid:** one call evaluates the same portfolio under all
  synthetic regimes and returns named `ScenarioReport` values.
- **ABS waterfall:** senior, mezzanine, and equity tranches under base and
  stressed monthly cash-flow assumptions.
- **Monte Carlo risk report:** deterministic base-vs-recession option estimates
  with an explicit seed.

Run it with:

```bash
lake env lean examples/RealWorldScenarios.lean
```

These examples are useful because they demonstrate the whole LFSE loop: declare
positions once, reuse the same pricing graph shape across market contexts, force
only the requested outputs, compare stress results, inspect traces, and keep the
entire workflow reproducible.

## Data Model

The core model is intentionally small:

- `Context`: valuation date, market values, and metadata.
- `MarketPoint`: one named numeric market value.
- `TraceEvent`: forced node ID, label, and optional value.
- `Result`: scenario name, NPV, Greeks-style report fields, and trace.
- `LFSEError`: missing observable, invalid input, cycle, evaluation, CLI, and
  data errors.

Market data can be loaded through `LFSE.Data.loadCsvLikeMarket` or
`loadMarketFile` into a `Context`. The package also depends on the sibling
`lean-columnar` project through a pinned Git dependency so heavier Parquet/Arrow-
backed workflows can live behind the same context boundary.

## Correctness Hardening

The current implementation includes regression coverage for issues that matter
in real scenario engines:

- discounted forward payoffs are checked against the expected discount formula;
- early-exercise helper logic propagates continuation value through backward
  induction;
- Monte Carlo returns explicit `LFSEError` values for unsupported instruments or
  missing market data instead of silently returning `0.0`;
- random samples use the full UInt64 state scaled to `[0, 1)` rather than a
  small modulo bucket;
- waterfall allocation is linear in tranche count;
- lazy graph forcing rejects conflicting duplicate node IDs and has an explicit
  recursion-depth guard;
- CLI DOT export reports write failures with exit code `1`;
- JSON output escapes control characters.

`forceMonteCarlo` currently supports call-option scenarios. For puts, forwards,
and swaps it returns `.error (.unsupportedMonteCarlo ...)`, which keeps audit
behavior explicit until those models receive dedicated stochastic semantics.

## Verification

Run the complete local verification set:

```bash
lake build
lake test
lake env lean examples/BermudanOption.lean
lake env lean examples/PortfolioStress.lean
lake env lean examples/WaterfallABS.lean
lake env lean examples/SimpleMC.lean
lake env lean examples/RealWorldScenarios.lean
lake exe lfse -- build examples/BermudanOption.lean
lake exe lfse -- eval examples/BermudanOption.lean --scenario base --format json
lake exe lfse -- trace examples/BermudanOption.lean --trace-level 2
lake exe lfse -- export-dot examples/BermudanOption.lean --output build/bermudan.dot
lake run benchmarks
lake pack
```

The test driver covers:

- lazy sharing with a side-effect counter;
- cycle detection;
- DSL macro expansion;
- option monotonicity under spot shocks;
- deterministic fixed-seed Monte Carlo;
- waterfall cash conservation;
- market-data parsing.
- realistic synthetic portfolio stress, ABS waterfall, and MC risk reports.
- regression checks for discounting, exercise propagation, unsupported MC
  instruments, missing observables, duplicate graph IDs, depth guard behavior,
  CLI dispatch, and JSON escaping.

The proof module currently includes compiling sample invariants for empty
waterfalls, payment totals, and zero-cash single-tranche allocation. These are
deliberately small but establish the pattern for adding stronger domain proofs as
the finance surface grows.

## Repository Layout

```text
LFSE/
  LazyCore/      -- lazy DAG, memoization, streams, DOT export
  DSL/           -- syntax, macros, scenario elaboration helpers
  Finance/       -- observables, instruments, MC, scenarios, waterfalls
  Data/          -- market-data loading boundary
  CLI/           -- command dispatch and renderers
  Verify/        -- trace rendering and sample proofs
examples/        -- runnable Lean examples
test/            -- unit/property/golden/integration entry files
benchmarks/      -- benchmark workspace
docs/            -- architecture, CLI, and testing guides
```

## Current Scope And Limitations

LFSE is production-shaped but intentionally compact. Current pricing support
includes forwards, vanilla options, swaps, early-exercise helpers, scenario
shocks, waterfalls, and deterministic Monte Carlo. The option implementation uses
a lightweight normal-CDF approximation for stable examples and regression tests;
it is not intended to claim full QuantLib parity.

The CLI preserves the compile-time DSL model: it does not runtime-parse arbitrary
financial DSL text. Instead, examples and Lean modules compile scenarios into
ordinary Lean values, while the CLI provides build/eval/trace/export workflows
around the known scenario surface.

Automated `lake fmt` is not available in the installed Lake command surface used
for this checkout, so style is enforced through Lean compilation and manual
review rather than a formatter command.

## Documentation

- `docs/Architecture.md`: module architecture and lazy graph flow.
- `docs/CLI.md`: commands, flags, and exit codes.
- `docs/Testing.md`: local verification checklist.
- `Handoff_Report.md`: implementation evidence and final verification results.
