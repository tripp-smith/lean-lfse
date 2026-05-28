# Changelog

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
