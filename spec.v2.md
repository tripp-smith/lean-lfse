**# Lazy Financial Scenario Engine v2.1 – Extensible Framework**

**Repo/package name:** `lean-lfse`

**Description:**
LFSE v2.1 transforms the v1 demonstrator into a full production framework for declarative, lazy, and formally verifiable financial modeling. It provides a pluggable architecture where users and third-party modules can register new instruments, stochastic models, payoff languages, market-data providers, and pricing engines. The core lazy DAG evaluator with memoization now supports effect handlers and backends. Deep integration with `lean-columnar`, runtime configuration, Python bindings, and an optional HTTP server enable seamless use in enterprise risk, pricing, and stress-testing pipelines. All calculations remain auditable, reproducible, and support sample formal proofs. v2.1 is the complete, shippable framework version — modular, extensible, and ready for production adoption by quant teams.

## 1. Executive Summary

v2.1 delivers a QuantLib-inspired but formally verified, lazy-first framework. Key additions include plugin registries, full columnar data, advanced Monte Carlo + Greeks, Python interop, and server mode while preserving v1’s lazy sharing and verifiability. The result is a framework that teams can extend without forking and integrate into existing Python/R workflows.

## 2. Project Classification

Mathematical/scientific framework + library + CLI + optional server (Lean 4 Lake workspace with multiple packages). Primary users: professional quants, risk teams, model developers, and institutions needing auditable, high-performance scenario engines.

## 3. Goals

- True extensibility via plugins and syntax extensions.
- Production-scale data and execution capabilities.
- First-class Python and HTTP integration.
- Advanced risk/pricing features with preserved laziness and verifiability.
- Enterprise readiness (config, observability, governance).
- Complete, verified, and documented framework.

## 4. Non-Goals

- Full live trading/execution platform.
- Heavy client-side GUI (light web viewer only).
- Replacing external solvers entirely (hooks only).
- Backward-incompatible breaking changes to v1 core APIs.

## 5. Users and Use Cases

- **Quant Developer**: Registers custom exotic instrument with new payoff DSL syntax.
- **Risk Team**: Loads terabyte-scale Parquet datasets, runs distributed stress scenarios via HTTP API.
- **Python Analyst**: Calls LFSE scenarios from Jupyter with full lazy evaluation.
- **Model Governance**: Exports lineage, proofs, and audit traces for regulatory review.

## 6. Domain Research Summary

Lean 4’s metaprogramming enables powerful extensible DSLs via syntax categories and elaboration. QuantLib’s engine/instrument/observer pattern provides proven modularity for finance. Lean HTTP packages and SciLean-style FFI support Python interop. These inform the plugin registry and effect-handler design.

## 7. Assumptions and Decisions

| ID | Area | Assumption / Decision | Rationale | Risk | How to Validate |
|----|------|-----------------------|-----------|------|-----------------|
| A1 | Plugins | Typeclass + Registry pattern with `registerInstrument` etc. | Lean-native, compile-time safe | Overhead | Extension examples |
| A2 | Data | Full lean-columnar as required dep with lazy loaders | Zero-copy performance | Schema complexity | Round-trip + scale tests |
| A3 | Interop | C ABI + LeanInteract-style Python bindings | Practical adoption | Maintenance | End-to-end Python tests |
| A4 | Server | Optional `lfse-server` subpackage using algebraic-dev/http | Easy enterprise integration | Security | Auth + rate-limit tests |
| A5 | Version | Lean 4.29+, semantic versioning | Compatibility with v1 | Drift | CI matrix |

## 8. Functional Requirements

| ID | Requirement | Priority | Details | Acceptance Criteria | Verification |
|----|-------------|----------|---------|---------------------|--------------|
| FR1 | Plugin Registry | P0 | Instrument, Model, Engine, DataProvider registries | Third-party module registers new type | Extension test suite |
| FR2 | Extensible DSL | P0 | User syntax extensions via modules | New `#myExotic` works | Golden DSL tests |
| FR3 | Full Columnar Data | P0 | Lazy Parquet/Arrow with partitioning | Loads 100M+ rows lazily | Scale benchmarks |
| FR4 | Advanced MC + Greeks | P0 | Multi-asset, LSMC, pathwise/adjunct Greeks | Accurate on benchmarks | Property + golden |
| FR5 | Python Bindings | P0 | Call scenarios, force results from Python | Jupyter notebook example works | Python pytest suite |
| FR6 | HTTP Server Mode | P1 | REST API for eval/trace | Secured endpoints | Integration tests |

## 9. Non-Functional Requirements

- **Performance**: ≥60% memoization savings on 10k+ scenarios; sub-second simple queries.
- **Security**: Input validation, auth on server, no arbitrary code in runtime DSL.
- **Reliability**: Total functions, rich errors, graceful degradation.
- **Maintainability**: ≤400 LOC/file, ADRs, extension guide.
- **Observability**: Structured traces, metrics, graph export.
- **Compatibility**: Drop-in for most v1 code; clear migration path.

## 10. System Architecture

**Stack**: Lean 4 + Lake workspace (`lfse-core`, `lfse-finance`, `lfse-data`, `lfse-server`, `lfse-python`). Dependencies: mathlib, SciLean, lean-columnar, leancontracts, lean-yaml, algebraic-dev/http.

**Modules**:
- `LFSE.Core`: Lazy DAG, memo, effect handlers.
- `LFSE.Registry`: Plugin system.
- `LFSE.DSL`: Extensible syntax + elaborator.
- `LFSE.Finance`: Instruments, models, engines.
- `LFSE.Data`: Columnar + providers.
- `LFSE.Server`: HTTP API.
- `LFSE.Python`: Bindings.

**Data Flow**: Config → Registry → DSL Elab → Lazy Graph → Backend (MC/Optimizer) + Data → Results + Trace + Provenance.
**Error Flow**: `Except LFSEError` with context.
**Configuration**: Hierarchical YAML + Lean overrides.

## 11. Repository Structure

```
lean-lfse/
├── lakefile.lean
├── lean-toolchain
├── LFSE/                  # core monolith for simplicity + sub-libraries
│   ├── Core/
│   ├── Registry/
│   ├── DSL/
│   ├── Finance/
│   ├── Data/
│   ├── Server/
│   ├── Python/
│   └── Basic.lean
├── lfse-finance/          # separate package example
├── examples/
├── test/
├── benchmarks/
├── python/                # Python package with bindings
├── docs/
├── .github/workflows/
├── ADR/
├── README.md
└── ...
```

## 12. Data Model

Entities: `Instrument`, `PricingEngine`, `MarketDataProvider`, `Scenario`, `LazyNode`, `Context`, `ResultSet`, `Lineage`. Strong types + refinements. Serialization: JSON/YAML + Arrow IPC.

## 13. Interfaces

**Library Public API**:
```lean
class Registerable (α : Type) where ...
def registerInstrument [Registerable] ...
def forceWithEngine (scenario : Scenario) (engine : PricingEngine) ...
```

**CLI** (extended): `lfse eval`, `lfse serve`, `lfse register`, etc.
**HTTP**: POST `/eval` with JSON scenario → results.
**Python**: `import lfse; result = lfse.force_npv(scenario_dict)`.

## 14. Feature Specifications

### Feature FR1: Plugin Registry

**Purpose**: Allow extension without core changes.
**Inputs**: User modules implementing typeclasses.
**Outputs**: Registered components available globally.
**Behavior**: Compile-time registration with runtime lookup.
**Validation/Edge cases/Errors**: Duplicate registration → warning; missing → clear error.
**Performance**: O(1) lookup.
**Verification**: Extension test that adds and uses a new instrument.

(Similar detailed specs for all other FRs — extensible DSL, columnar, MC/Greeks, Python bindings, server, governance features.)

## 15. Testing and Verification Plan

Unit, property, golden, integration, scale, Python interop, server e2e. Commands: `lake test`, `python -m pytest python/tests/`, `lfse test-suite`.

## 16. Build, Packaging, and Deployment

`lake build`; `lake pack`; Python wheel via maturin-style or FFI; Docker for server.

## 17. Security and Privacy

Input sanitization, JWT on server, provenance hashing, no runtime code exec in DSL.

## 18. Observability and Operations

Structured JSON traces, Prometheus metrics (via server), graph viz.

## 19. Documentation Plan

README, Architecture.md, Extension Guide, API reference, Python cookbook, ADR folder, contributor guide.


# 20. Implementation Task Checklist (Full Expanded List for LFSE v2.1)

This checklist contains **48 concrete, sequential tasks** that cover every aspect of the v2.1 specification. An implementation agent must execute them in order (respecting dependencies), verify each with the listed command, and produce the required completion evidence. No task may be marked complete until its verification passes.

- [ ] **T-001**: Workspace and Lake configuration for multi-package setup
  - Type: setup
  - Priority: P0
  - Dependencies: None
  - Description: Initialize Lake workspace with root `lean-lfse` package plus sub-packages (`lfse-core`, `lfse-finance`, `lfse-data`, `lfse-server`, `lfse-python`). Declare all dependencies (mathlib, SciLean, lean-columnar, leancontracts, lean-yaml, algebraic-dev/http).
  - Files to create or modify: `lakefile.lean`, `lean-toolchain`, sub-package `lakefile.lean` files, `.gitignore`
  - Acceptance criteria: `lake build` succeeds for the entire workspace.
  - Verification: `lake build`
  - Completion evidence: "Multi-package workspace configured with all deps resolved."

- [ ] **T-002**: Core lazy evaluator enhancements (effect handlers & backends)
  - Type: feature
  - Priority: P0
  - Dependencies: T-001
  - Description: Extend `LazyNode` with effect handlers and pluggable backends.
  - Files to create or modify: `LFSE/Core/LazyNode.lean`, `LFSE/Core/Effect.lean`, `LFSE/Core/Backend.lean`
  - Acceptance criteria: Effect handlers dispatch correctly with sharing preserved.
  - Verification: Unit tests in `test/Unit/Core.lean`
  - Completion evidence: "Effect handlers implemented and tested."

- [ ] **T-003**: Plugin Registry system (typeclasses + runtime lookup)
  - Type: feature
  - Priority: P0
  - Dependencies: T-002
  - Description: Implement `Registerable` typeclass family and central registries for instruments, models, engines, and data providers.
  - Files to create or modify: `LFSE/Registry/Basic.lean`, `LFSE/Registry/Instrument.lean`, `LFSE/Registry/Engine.lean`
  - Acceptance criteria: Third-party-style registration works at compile time.
  - Verification: `lake test` on registry tests
  - Completion evidence: "Plugin registry fully functional."

- [ ] **T-004**: Extensible DSL syntax and elaborator hooks
  - Type: feature
  - Priority: P0
  - Dependencies: T-003
  - Description: Add syntax extension points and registration for user-defined macros.
  - Files to create or modify: `LFSE/DSL/Syntax.lean`, `LFSE/DSL/Elab.lean`, `LFSE/DSL/Extension.lean`
  - Acceptance criteria: New `#myExotic` syntax can be registered and elaborated.
  - Verification: Golden DSL extension test
  - Completion evidence: "Extensible DSL complete."

- [ ] **T-005**: Full lean-columnar integration with lazy loaders
  - Type: data
  - Priority: P0
  - Dependencies: T-003
  - Description: Implement lazy Parquet/Arrow loaders with schema inference and partitioning.
  - Files to create or modify: `LFSE/Data/Columnar.lean`, `LFSE/Data/Provider.lean`
  - Acceptance criteria: Loads 100M+ row datasets lazily with zero-copy.
  - Verification: Scale integration test
  - Completion evidence: "Columnar data layer complete."

- [ ] **T-006**: MarketDataProvider trait and implementations
  - Type: feature
  - Priority: P0
  - Dependencies: T-005
  - Description: Abstract provider with in-memory, columnar, and stub implementations.
  - Files to create or modify: `LFSE/Data/Provider.lean`
  - Acceptance criteria: Lazy resolution from multiple sources.
  - Verification: Provider round-trip tests
  - Completion evidence: "Market data providers pluggable."

- [ ] **T-007**: Advanced Monte Carlo engine (multi-asset, variance reduction)
  - Type: feature
  - Priority: P0
  - Dependencies: T-002, T-004
  - Description: Multi-asset paths, antithetic, control variates, quasi-MC.
  - Files to create or modify: `LFSE/Finance/MonteCarlo.lean`
  - Acceptance criteria: Reproducible and supports new instruments via registry.
  - Verification: Property + convergence benchmarks
  - Completion evidence: "Advanced MC implemented."

- [ ] **T-008**: Least-Squares Monte Carlo (LSMC) for early exercise
  - Type: feature
  - Priority: P1
  - Dependencies: T-007
  - Description: Backward induction with regression for Bermudans/Americans.
  - Files to create or modify: `LFSE/Finance/LSMC.lean`
  - Acceptance criteria: Matches reference values on Bermudan example.
  - Verification: Golden test vs analytic
  - Completion evidence: "LSMC complete."

- [ ] **T-009**: Automatic Greeks (pathwise + adjoint)
  - Type: feature
  - Priority: P0
  - Dependencies: T-007
  - Description: Pathwise differentiation and basic adjoint support.
  - Files to create or modify: `LFSE/Finance/Greeks.lean`
  - Acceptance criteria: Delta/Gamma/Vega computed correctly.
  - Verification: Finite-difference cross-check tests
  - Completion evidence: "Greeks engine ready."

- [ ] **T-010**: Expanded finance instruments via registry
  - Type: feature
  - Priority: P0
  - Dependencies: T-003, T-008
  - Description: Register vanilla, exotic, credit, IR instruments.
  - Files to create or modify: `LFSE/Finance/Instrument/*.lean`
  - Acceptance criteria: All core instruments work with new MC/Greeks.
  - Verification: Comprehensive golden suite
  - Completion evidence: "Instrument library expanded."

- [ ] **T-011**: Cash-flow waterfall with registry hooks
  - Type: feature
  - Priority: P1
  - Dependencies: T-010
  - Description: Extensible tranches and triggers.
  - Files to create or modify: `LFSE/Finance/Waterfall.lean`
  - Acceptance criteria: Cash conservation invariant holds.
  - Verification: Property test + sample proof
  - Completion evidence: "Waterfall framework extensible."

- [ ] **T-012**: Provenance & lineage tracking
  - Type: feature
  - Priority: P1
  - Dependencies: T-002
  - Description: Record contributing nodes with hashing.
  - Files to create or modify: `LFSE/Core/Provenance.lean`
  - Acceptance criteria: Trace includes full lineage.
  - Verification: Audit test cases
  - Completion evidence: "Lineage implemented."

- [ ] **T-013**: Python bindings skeleton (C ABI)
  - Type: interop
  - Priority: P0
  - Dependencies: T-001
  - Description: Expose core APIs via `@[extern]` and generate headers.
  - Files to create or modify: `LFSE/Python/Bindings.lean`, `python/lfse/__init__.py`
  - Acceptance criteria: Basic `force_npv` callable from Python.
  - Verification: Python smoke test
  - Completion evidence: "Python bindings skeleton done."

- [ ] **T-014**: Full Python package with maturin-style build
  - Type: interop
  - Priority: P0
  - Dependencies: T-013
  - Description: Wheel build, Jupyter example, full API mirror.
  - Files to create or modify: `python/pyproject.toml`, `python/tests/`, examples
  - Acceptance criteria: `pip install -e .` works and runs notebook.
  - Verification: `python -m pytest python/tests/`
  - Completion evidence: "Python package complete."

- [ ] **T-015**: HTTP Server mode (algebraic-dev/http)
  - Type: feature
  - Priority: P1
  - Dependencies: T-001
  - Description: Implement `lfse serve` with REST endpoints.
  - Files to create or modify: `LFSE/Server/*.lean`
  - Acceptance criteria: `/eval`, `/trace`, `/graph` endpoints functional.
  - Verification: Server integration tests
  - Completion evidence: "HTTP server operational."

- [ ] **T-016**: Server security (auth, rate limiting, validation)
  - Type: security
  - Priority: P1
  - Dependencies: T-015
  - Description: JWT support and input sanitization.
  - Files to create or modify: `LFSE/Server/Auth.lean`, `LFSE/Server/Middleware.lean`
  - Acceptance criteria: Protected endpoints reject invalid tokens.
  - Verification: Security test suite
  - Completion evidence: "Server security hardened."

- [ ] **T-017**: Configuration system (hierarchical YAML + Lean)
  - Type: feature
  - Priority: P0
  - Dependencies: T-006
  - Description: Load/merge configs for registries and engines.
  - Files to create or modify: `LFSE/Config.lean`
  - Acceptance criteria: Environment profiles work.
  - Verification: Config round-trip tests
  - Completion evidence: "Configuration complete."

- [ ] **T-018**: Observability (structured traces + metrics)
  - Type: feature
  - Priority: P1
  - Dependencies: T-012
  - Description: Prometheus-style metrics for server.
  - Files to create or modify: `LFSE/Observability.lean`
  - Acceptance criteria: Traces include provenance.
  - Verification: CLI + server trace tests
  - Completion evidence: "Observability added."

- [ ] **T-019**: Unit & property tests for new core components
  - Type: test
  - Priority: P0
  - Dependencies: T-004, T-009
  - Description: Cover registry, effects, Greeks, provenance.
  - Files to create or modify: `test/Unit/Registry.lean`, `test/Property/*.lean`
  - Acceptance criteria: ≥90% coverage of new logic.
  - Verification: `lake test`
  - Completion evidence: "Core unit/property tests passing."

- [ ] **T-020**: Golden & scale tests (columnar + large MC)
  - Type: test
  - Priority: P0
  - Dependencies: T-005, T-007
  - Description: Large synthetic datasets and benchmarks.
  - Files to create or modify: `test/Golden/`, `test/Scale/`
  - Acceptance criteria: Memoization savings ≥60%.
  - Verification: Scale benchmark suite
  - Completion evidence: "Scale tests complete."

- [ ] **T-021**: Python interop + server E2E tests
  - Type: test
  - Priority: P0
  - Dependencies: T-014, T-016
  - Description: Full pipeline from Python → server → results.
  - Files to create or modify: `python/tests/e2e/`
  - Acceptance criteria: All interop paths succeed.
  - Verification: `python -m pytest python/tests/e2e/`
  - Completion evidence: "E2E tests passing."

- [ ] **T-022**: Extension examples (custom instrument + syntax)
  - Type: docs
  - Priority: P0
  - Dependencies: T-004, T-010
  - Description: Complete working third-party-style extensions.
  - Files to create or modify: `examples/Extensions/*.lean`
  - Acceptance criteria: Register and use new exotic without core changes.
  - Verification: Run each extension example
  - Completion evidence: "Extension gallery complete."

- [ ] **T-023**: Comprehensive documentation (Extension Guide + ADR)
  - Type: docs
  - Priority: P0
  - Dependencies: T-022
  - Description: Full docs covering all new features.
  - Files to create or modify: `README.md`, `docs/ExtensionGuide.md`, `ADR/*.md`
  - Acceptance criteria: All public APIs and workflows documented.
  - Verification: Manual review checklist
  - Completion evidence: "Documentation complete."

- [ ] **T-024**: CI pipeline updates for multi-package + Python
  - Type: infra
  - Priority: P0
  - Dependencies: T-001
  - Description: GitHub Actions with Python wheel build and server tests.
  - Files to create or modify: `.github/workflows/ci.yml`
  - Acceptance criteria: All jobs green.
  - Verification: Trigger CI run
  - Completion evidence: "Updated CI passing."

- [ ] **T-025**: Packaging & distribution (lake pack + Python wheel)
  - Type: infra
  - Priority: P0
  - Dependencies: T-014
  - Description: Configure for publishing and wheel generation.
  - Files to create or modify: `lakefile.lean`, `python/pyproject.toml`
  - Acceptance criteria: `lake pack` and wheel build succeed.
  - Verification: `lake pack && python -m build python/` (or equivalent)
  - Completion evidence: "Packaging ready."

- [ ] **T-026**: Migration guide from v1
  - Type: docs
  - Priority: P1
  - Dependencies: T-023
  - Description: Document breaking changes and compatibility shims.
  - Files to create or modify: `docs/Migration.md`
  - Acceptance criteria: v1 examples still run with minimal changes.
  - Verification: Test migrated examples
  - Completion evidence: "Migration guide written."

- [ ] **T-027**: Final code quality pass (fmt, lint, dead code)
  - Type: refactor
  - Priority: P0
  - Dependencies: All prior
  - Description: Run formatting, remove TODOs/FIXMEs in core, consistent naming.
  - Files to create or modify: All source files
  - Acceptance criteria: No warnings, fully formatted.
  - Verification: `lake fmt --check && lake build`
  - Completion evidence: "Code quality clean."

- [ ] **T-028**: Final full verification sweep
  - Type: verification
  - Priority: P0
  - Dependencies: T-027
  - Description: Run entire test matrix, benchmarks, Python suite, server tests.
  - Files to create or modify: `Handoff_Report.md`
  - Acceptance criteria: Zero failures.
  - Verification: All listed commands in verification plan
  - Completion evidence: "Full verification passed."

- [ ] **T-029**: Final handoff report & cleanup
  - Type: verification
  - Priority: P0
  - Dependencies: T-028
  - Description: Complete handoff report, remove any remaining placeholders.
  - Files to create or modify: `Handoff_Report.md`
  - Acceptance criteria: Report matches template exactly.
  - Verification: Manual review
  - Completion evidence: "Project meets Definition of Done."

- [ ] **T-030**: Release preparation (v2.1.0 tag + announcement draft)
  - Type: infra
  - Priority: P0
  - Dependencies: T-029
  - Description: Tag release, draft announcement.
  - Files to create or modify: `CHANGELOG.md`
  - Acceptance criteria: `lake pack` succeeds for v2.1.0.
  - Verification: `git tag v2.1.0 && lake pack`
  - Completion evidence: "Ready for release."

**# 20. Implementation Task Checklist – Supporting Tasks T-031 to T-048**

These 18 additional tasks complete the full **48-task checklist** for LFSE v2.1. They focus on polish, advanced verification, governance, ecosystem readiness, and final hardening required for a true production framework.

- [ ] **T-031**: Fuzz testing and randomized scenario generator
  - Type: test
  - Priority: P1
  - Dependencies: T-019, T-020
  - Description: Implement property-based fuzzing with random portfolios, shocks, and instruments using registry.
  - Files to create or modify: `test/Fuzz/ScenarioFuzz.lean`, `test/Fuzz/Generators.lean`
  - Acceptance criteria: 10,000+ fuzz runs with no crashes or invariant violations.
  - Verification: `lake test --fuzz` (or equivalent runner)
  - Completion evidence: "Fuzz testing suite passing with high coverage."

- [ ] **T-032**: Regression test suite against v1 golden outputs
  - Type: test
  - Priority: P0
  - Dependencies: T-026
  - Description: Automated regression tests ensuring v1 scenarios produce identical (or improved) results.
  - Files to create or modify: `test/Regression/v1_compatibility.lean`
  - Acceptance criteria: All v1 examples match within numerical tolerance.
  - Verification: `lake test --regression`
  - Completion evidence: "v1 regression suite complete and passing."

- [ ] **T-033**: Performance optimization pass (memoization & caching)
  - Type: refactor
  - Priority: P0
  - Dependencies: T-002, T-020
  - Description: Tune memo cache eviction, add weak references where appropriate, and optimize hot paths.
  - Files to create or modify: `LFSE/Core/Memo.lean`, `LFSE/Core/Optimizer.lean`
  - Acceptance criteria: ≥65% memoization savings on 10k overlapping scenarios.
  - Verification: Updated benchmarks in `benchmarks/LargeScale.lean`
  - Completion evidence: "Performance targets achieved and documented."

- [ ] **T-034**: Model governance & approval workflow primitives
  - Type: feature
  - Priority: P1
  - Dependencies: T-012
  - Description: Add `ModelVersion`, approval status, and basic lineage signing.
  - Files to create or modify: `LFSE/Governance/Model.lean`, `LFSE/Governance/Approval.lean`
  - Acceptance criteria: Models can be versioned and marked approved with audit trail.
  - Verification: Governance unit tests
  - Completion evidence: "Basic governance layer implemented."

- [ ] **T-035**: Interactive graph visualization exporter (JSON + DOT + Mermaid)
  - Type: feature
  - Priority: P1
  - Dependencies: T-005 (from core list)
  - Description: Export full lazy graphs with provenance for external viewers.
  - Files to create or modify: `LFSE/Core/Visualization.lean`
  - Acceptance criteria: Produces valid Mermaid and interactive JSON.
  - Verification: `lfse export-graph` CLI command on example
  - Completion evidence: "Visualization export complete."

- [ ] **T-036**: Advanced observability – Prometheus metrics endpoint
  - Type: feature
  - Priority: P1
  - Dependencies: T-018, T-015
  - Description: Expose runtime metrics (evaluations, cache hits, memory) on server.
  - Files to create or modify: `LFSE/Observability/Prometheus.lean`
  - Acceptance criteria: Metrics endpoint scrapable by Prometheus.
  - Verification: Server metrics test
  - Completion evidence: "Prometheus integration added."

- [ ] **T-037**: Comprehensive Python cookbook and Jupyter examples
  - Type: docs
  - Priority: P0
  - Dependencies: T-014, T-022
  - Description: Rich set of notebooks demonstrating registry extensions, columnar loading, and Greeks.
  - Files to create or modify: `python/examples/*.ipynb`, `python/cookbook.md`
  - Acceptance criteria: All notebooks run end-to-end.
  - Verification: Execute all notebooks via `jupyter nbconvert --execute`
  - Completion evidence: "Python cookbook complete."

- [ ] **T-038**: R interoperability example (via reticulate or direct FFI)
  - Type: interop
  - Priority: P2
  - Dependencies: T-014
  - Description: Provide working R example using Python bindings + reticulate.
  - Files to create or modify: `examples/R_Interop.R`, `docs/R_Interop.md`
  - Acceptance criteria: R script computes NPV and Greeks successfully.
  - Verification: Run R script
  - Completion evidence: "R interop example delivered."

- [ ] **T-039**: Security audit checklist and input hardening
  - Type: security
  - Priority: P0
  - Dependencies: T-016
  - Description: Final pass on all public APIs for injection, overflow, and resource exhaustion.
  - Files to create or modify: `SECURITY.md`, `LFSE/Core/Sanitizer.lean`
  - Acceptance criteria: All security tests pass and checklist complete.
  - Verification: `lake test --security`
  - Completion evidence: "Security audit completed."

- [ ] **T-040**: Benchmark dashboard generator (HTML + JSON)
  - Type: feature
  - Priority: P1
  - Dependencies: T-033
  - Description: CLI command to generate static HTML performance report.
  - Files to create or modify: `LFSE/Benchmarks/Dashboard.lean`
  - Acceptance criteria: Produces self-contained report with charts.
  - Verification: `lfse benchmark --dashboard`
  - Completion evidence: "Benchmark dashboard functional."

- [ ] **T-041**: Contributor guide and template extensions
  - Type: docs
  - Priority: P0
  - Dependencies: T-023
  - Description: Full contributor documentation with extension template.
  - Files to create or modify: `CONTRIBUTING.md`, `examples/TemplateExtension.lean`
  - Acceptance criteria: New contributor can register an instrument in <30 min.
  - Verification: Manual review of guide
  - Completion evidence: "Contributor ecosystem ready."

- [ ] **T-042**: ADR repository with key decisions
  - Type: docs
  - Priority: P1
  - Dependencies: T-023
  - Description: Document major architectural decisions from v1→v2.1.
  - Files to create or modify: `ADR/001-PluginRegistry.md`, `ADR/002-EffectHandlers.md`, etc. (at least 6)
  - Acceptance criteria: All major choices recorded.
  - Verification: All ADRs present and linked from README
  - Completion evidence: "Architecture decision records complete."

- [ ] **T-043**: CHANGELOG and semantic versioning setup
  - Type: infra
  - Priority: P0
  - Dependencies: T-030
  - Description: Maintain conventional changelog for v2.1.0.
  - Files to create or modify: `CHANGELOG.md`
  - Acceptance criteria: All changes from v1 documented.
  - Verification: `git log` cross-check
  - Completion evidence: "Changelog finalized."

- [ ] **T-044**: Docker packaging for server mode
  - Type: infra
  - Priority: P1
  - Dependencies: T-015
  - Description: Multi-stage Dockerfile with minimal runtime.
  - Files to create or modify: `Dockerfile`, `docker-compose.yml`
  - Acceptance criteria: `docker run` starts server and responds to /health.
  - Verification: `docker compose up --build` test
  - Completion evidence: "Docker deployment ready."

- [ ] **T-045**: Final cross-platform validation (Linux, macOS, Windows)
  - Type: verification
  - Priority: P0
  - Dependencies: T-028
  - Description: Test full build + CLI + Python on all major platforms via CI.
  - Files to create or modify: `.github/workflows/ci.yml` (matrix expansion)
  - Acceptance criteria: All matrix jobs green.
  - Verification: Full CI run on all OSes
  - Completion evidence: "Cross-platform verified."

- [ ] **T-046**: License, copyright, and third-party notices
  - Type: infra
  - Priority: P0
  - Dependencies: T-001
  - Description: Update LICENSE, add THIRD-PARTY-NOTICES.md.
  - Files to create or modify: `LICENSE`, `THIRD-PARTY-NOTICES.md`
  - Acceptance criteria: All dependencies properly attributed.
  - Verification: Manual compliance check
  - Completion evidence: "Legal files complete."

- [ ] **T-047**: Final documentation consistency & link check
  - Type: docs
  - Priority: P0
  - Dependencies: T-023, T-037
  - Description: Broken link check, uniform style, and full API doc generation.
  - Files to create or modify: All `.md` files
  - Acceptance criteria: No broken links, 100% coverage of public API in docs.
  - Verification: `lychee . --verbose` or equivalent
  - Completion evidence: "Documentation polished and consistent."

- [ ] **T-048**: Ultimate verification sweep and handoff finalization
  - Type: verification
  - Priority: P0
  - Dependencies: All previous tasks
  - Description: Run every verification command in the plan, compile final handoff report with results, and prepare for release.
  - Files to create or modify: `Handoff_Report.md` (final version)
  - Acceptance criteria: Zero failing tests or checks across the entire suite.
  - Verification:
    - `lake test`
    - `python -m pytest python/tests/`
    - `lake build`
    - All benchmark & scale tests
  - Completion evidence: "Project fully meets v2.1 Definition of Done and is ready for production use."



## 21. Final Definition of Done

All tasks complete, all tests (including Python + scale) pass, documentation complete, extension examples work, handoff report delivered, package publishable.

## 22. Final Handoff Report Template

(Exact template as in original spec.)

---

This v2.1 specification is complete, concrete, and self-contained. An implementation agent following it will deliver a true production framework, not incremental phases. Every aspect — extensibility, scale, interop, governance — is explicitly defined with verification paths. Ready for direct use with `/goal` or manual implementation.