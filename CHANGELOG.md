# Changelog

## Unreleased

### LSMC Formal Upgrade (Grok 4.3 session)
- Began implementation of the true Longstaff–Schwartz algorithm per `_tmp/lsmc-formal-spec.md`.
- Added Gaussian sampler (Box–Muller + PCG64) with statistical validation.
- Added pure-Lean Cholesky + normal-equation solver (`Numerics/Linalg`).
- Created new `LSMC/` and `Numerics/` module structure.
- Wired improved Gaussian-based Monte Carlo into the legacy `LSMC` pricing surface.
- Added C FFI shim for optional LAPACK acceleration.
- Extensive session documentation in `_tmp/LSMC_GROK_IMPLEMENTATION_SESSION.md`.

**Note:** This work was performed by Grok 4.3 (xAI) in a large-context interactive session.

**Phase B Complete (autonomous follow-through):** Full correct core delivered and verified.
- `simulatePaths` + `lsmcPrice` now implement true multi-date Longstaff–Schwartz (ITM regression, stopping times, real basis families via `Numerics/Basis`, robust solver).
- All 5 B gates passed (Table 1 subset agreement within phase tolerance, zero sorry in core numerics/algorithm, clean builds).
- See `_plans/001_phase_b_core_lsmc_correctness.md` and signed `_tmp/PHASE_B_VERIFICATION_REPORT.md`.
- Phase A (Instrument/Engine integration) explicitly not started.

### LSMC Engine Hygiene (Phase A — Core Duality Resolution)
- Made `EngineParams.lsmc` (and `PricingEngine.lsmc` / dispatch) use the modern `LSMC.Config` as the primary public type (ExerciseStyle, BasisFamily, ridge, antithetic, etc.).
- Refactored the legacy `LFSE/Finance/LSMC.lean` into an honest, minimal compatibility shim with `legacyConfigToModern` converter + full delegation to `LSMC.Algorithm`.
- `lsmcEngineEntry` now builds properly enriched `LSMC.Config` instances for the new first-class `bermudanOption`/`americanOption` instruments (instrument exercise schedule merged with caller tuning params) and calls the real algorithm directly.
- Resolved import/qualification friction cleanly. Removed transitional code, broken stubs, and "blocked" comments from the hot paths.
- Full `lake build && lake test` green + Bermudan example verified.
- See `_plans/002_phase_a_lsmc_cleanup.md` (Phase 1 marked complete), `ADR/007-lsmc-instrument-integration.md`, and `_tmp/SESSION_2026-05-30_lsmc-engine-hygiene.md`.
- This puts the framework on a polished foundation for future LSMC functionality.

**Phase A Adoption & Documentation Progress**
- DSL syntax added for `bermudanCall`/`bermudanPut`/`americanCall`/`americanPut`.
- CLI extended with `--engine lsmc|monte-carlo|analytic` flag; `BermudanOption.lean` now supported directly; new instruments registered.
- Python bindings and internal tests updated to use the new instruments.
- `ADR/007-lsmc-instrument-integration.md` created explaining the `LSMC.Config` type change, legacy shim strategy, `ExerciseStyle` design, and module decisions.
- README Bermudan/American section significantly expanded with modern vs. legacy examples, DSL, and CLI usage.

### Developer Workflow
- Added `clean-commit-push` skill (invoked via `/ccp`).
- Automates end-of-session notes, temp file cleanup into `_tmp/`, .gitignore maintenance, and high-quality commits.
- Created as a project skill so the workflow can be versioned and improved alongside the codebase.

## 2.1.0

- Added typed plugin registries for instruments, engines, data providers, DSL
  extensions, and graph exporters.
- Added backend-aware lazy evaluation, effect policy checks, provenance, graph
  JSON/Mermaid export, and Prometheus-style metrics.
- Added advanced finance modules for registered engines, LSMC, Greeks, basket
  options, credit default swaps, and exotic compatibility hooks.
- Added provider wrappers around `lean-columnar` Parquet, mmap Parquet, Arrow IPC,
  and CSV-like market data.
- Added server request handling, Python package facade, governance primitives,
  security validation, Docker files, ADRs, and expanded tests.

## 0.1.0

- Initial lazy financial scenario engine with DSL, CLI, examples, tests, traces,
  DOT export, deterministic Monte Carlo, waterfalls, and synthetic scenarios.
