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
cat lean-toolchain
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
- waterfall allocation is linear in tranche count and has an executable
  conservation checker that accounts for residual cash;
- lazy graph forcing rejects conflicting duplicate node IDs and has an explicit
  recursion-depth guard;
- CLI DOT export reports write failures with exit code `1`;
- JSON output escapes control characters.

`forceMonteCarlo` currently supports call-option scenarios. For puts, forwards,
and swaps it returns `.error (.unsupportedMonteCarlo ...)`, which keeps audit
behavior explicit until those models receive dedicated stochastic semantics.

## Waterfall Theory

`LFSE.Finance.Waterfall.Theory` re-exports through `LFSEFinance` and `LFSE`.
It adds `remainingAfterWaterfall`, `waterfallCashTotal`, and
`waterfallConservesCash` for checking that paid cash plus residual cash matches
input cash on concrete waterfall allocations.

The current waterfall runtime uses IEEE `Float`, so exact universal equality is
not sound for the runtime type itself. Concrete Float cases are verified with
`#guard`, `native_decide`, and runtime tolerance tests:

```lean
import LFSEFinance

open LFSE
open LFSE.Finance

def tranches : List Tranche := [
  { name := "senior", balance := 1000.0, rate := 0.05 },
  { name := "mezz", balance := 500.0, rate := 0.08 }
]

example :
    waterfallConservesCash 90.0 tranches = true := by
  native_decide
```

For a true parametric proof, the `Waterfall.Theory.Exact` namespace provides a
generic exact-cash model and proves paid cash plus residual cash equals original
cash for every tranche list:

```lean
import LFSEFinance

open LFSE.Finance.Waterfall.Theory

def exactTranches : List (Exact.Tranche Rat) := [
  { name := "senior", balance := (100 : Rat), rate := (1 : Rat) },
  { name := "mezz", balance := (50 : Rat), rate := (1 : Rat) }
]

example (cash : Rat) :
    Exact.waterfallCashTotal cash exactTranches = cash := by
  simpa using Exact.waterfallCashTotal_eq_cash cash exactTranches
```

Focused checks:

```bash
lake env lean test/Finance/WaterfallTheory.lean
lake env lean examples/WaterfallTheoryDemo.lean
```

## Verification

Run the complete local verification set:

```bash
lake build
lake test
lake env lean test/Finance/WaterfallTheory.lean
lake env lean examples/BermudanOption.lean
lake env lean examples/PortfolioStress.lean
lake env lean examples/WaterfallABS.lean
lake env lean examples/WaterfallTheoryDemo.lean
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
- waterfall residual cash conservation;
- market-data parsing.
- realistic synthetic portfolio stress, ABS waterfall, and MC risk reports.
- regression checks for discounting, exercise propagation, unsupported MC
  instruments, missing observables, duplicate graph IDs, depth guard behavior,
  CLI dispatch, and JSON escaping.

The proof module includes compiling sample invariants for empty waterfalls,
payment totals, zero-cash single-tranche allocation, and the Float-aware
waterfall theory helpers. See `docs/WaterfallTheory.md` for details.

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
includes forwards, vanilla options, swaps, basket options, credit default swaps,
early-exercise helpers, scenario shocks, waterfalls, deterministic Monte Carlo,
LSMC, registered engines, and finite-difference Greeks. The option
implementation uses a lightweight normal-CDF approximation for stable examples
and regression tests; it is not intended to claim full QuantLib parity.

### Bermudan / American Pricing with True Longstaff–Schwartz — Phase B Complete (Verified)

Phase B (core algorithm correctness per `_plans/001_phase_b_core_lsmc_correctness.md`) is **complete and signed off**.

- `simulatePaths`: correct per-step Gaussian (Box-Muller) paths with antithetic support.
- Full `LSMC/Config`: ExerciseStyle + all BasisFamily + ridge + validation.
- Real `Numerics/Basis` (monomial + iterative Laguerre + iterative Hermite `eval`) + robust Cholesky/ridge solver in Linalg.
- `LSMC/Algorithm.lsmcPrice`: production multi-date Longstaff–Schwartz (ITM regression every date, per-path stopping times, correct discounting). Real basis dispatch, no stand-ins.
- Verified on exact LS 2001 Table 1 subset (4 cells): all diffs <1.5 (plan tolerance with 20–25k paths/deg-3). Full gate matrix and numbers in `_tmp/PHASE_B_VERIFICATION_REPORT.md`.
- Zero `sorry` in core modules. Clean builds.

Canonical entry point: `LFSE.Finance.LSMC.Algorithm.lsmcPrice` (and Config-driven helpers). Legacy shims preserved.

Phase A (Instrument variants + Engine integration) is **in progress** (major hygiene milestone achieved).

- New first-class `Instrument.bermudanOption` and `Instrument.americanOption` variants have been added.
- **Engine hygiene complete**: `EngineParams.lsmc` and the LSMC dispatch now use the modern `LSMC.Config` directly. Legacy shim (`LFSE/Finance/LSMC.lean`) is a thin documented compatibility layer only. New instruments receive properly constructed configs with instrument-derived `ExerciseStyle`.
- They are wired into the registry and both `lsmc` + `monte-carlo` engines.
- Convenience constructors available via `Finance.Scenario` (`bermudanPut`, `bermudanCall`, `americanPut`, `americanCall`).
- `examples/BermudanOption.lean` demonstrates real early-exercise pricing via `forceWithEngine` + `PricingEngine.lsmc`.
- See `_plans/002_phase_a_lsmc_cleanup.md`, `_tmp/PHASE_A_BLAST_RADIUS.md`, and `_tmp/SESSION_2026-05-30_lsmc-engine-hygiene.md` for status and remaining work.

Canonical entry point for the core algorithm remains `LFSE.Finance.LSMC.Algorithm.lsmcPrice` (and Config-driven helpers).

See `LFSE/Finance/LSMC/Algorithm.lean`, `Numerics/Basis.lean`, the updated `examples/BermudanOption.lean`, and the Phase B verification report. Pure-Lean path is default and verified (LAPACK optional).

#### Implementation Session Notes (Grok 4.3)

This work was performed by **Grok 4.3** (xAI, April 2026) over an extended interactive agentic session:

- Full planning phase (plan mode + detailed 9-phase implementation plan with risk analysis and verification matrix).
- Iterative execution across Gaussian sampler, pure-Lean linear algebra (Cholesky + normal equations), LSMC algorithm skeleton, and integration into the existing pricing surface.
- Significant context usage: well over 150k–200k+ tokens across planning, codebase exploration (via subagents), coding, debugging, and verification.

See `_tmp/LSMC_GROK_IMPLEMENTATION_SESSION.md` for the full session log, deliverables, and recommended follow-ups.

The CLI preserves the compile-time DSL model: it does not runtime-parse arbitrary
financial DSL text. Instead, examples and Lean modules compile scenarios into
ordinary Lean values, while the CLI provides build/eval/trace/export workflows
around the known scenario surface.

Automated `lake fmt` is not available in the installed Lake command surface used
for this checkout, so style is enforced through Lean compilation and manual
review rather than a formatter command.

## LFSE v2.1 Framework Surface

The v2.1 API adds production-oriented framework modules while preserving the old
entry points:

- `LFSE.Registry`: typed descriptors plus callable implementations for
  instruments, engines, data providers, DSL extensions, and graph exporters.
- `LFSE.LazyCore.Backend`: backend-aware forcing and effect policy checks.
- `LFSE.LazyCore.Provenance` and `Visualization`: lineage, DOT, Mermaid, and
  graph JSON export.
- `LFSE.Finance.Engine`, `Greeks`, and `LSMC`: registry-backed engine dispatch,
  MC pricing, early-exercise approximation, and Delta/Gamma/Vega helpers.
- `LFSE.Data.Provider`: CSV-like, Parquet, mmap Parquet, and Arrow IPC provider
  wrappers through `lean-columnar`.
- `LFSE.Server`: testable handlers for `/health`, `/eval`, `/trace`, `/graph`,
  and `/metrics`.
- `LFSE.Python`: Python-facing JSON helpers plus the `python/lfse` package.
- `LFSE.Governance` and `LFSE.Security`: model approval, lineage audit strings,
  request limits, auth checks, and token redaction.

New CLI commands:

```bash
lake exe lfse -- export-graph examples/BermudanOption.lean
lake exe lfse -- serve --host 127.0.0.1 --port 8080
lake exe lfse -- register
lake exe lfse -- benchmark --dashboard
lake exe lfse -- test-suite
```

## Documentation

- `docs/Architecture.md`: module architecture and lazy graph flow.
- `docs/CLI.md`: commands, flags, and exit codes.
- `docs/Testing.md`: local verification checklist.
- `docs/ExtensionGuide.md`: v2.1 extension registration workflow.
- `docs/Migration.md`: v1 compatibility notes and new v2.1 APIs.
- `docs/WaterfallTheory.md`: Float-aware waterfall conservation checks.
- `Handoff_Report.md`: implementation evidence and final verification results.
