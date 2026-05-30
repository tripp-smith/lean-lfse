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
