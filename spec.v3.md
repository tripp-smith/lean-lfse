
Parametric Waterfall Conservation Laws for LFSERepo: tripp-smith/lean-lfse (extension)Description:

Adds LFSE.Finance.Waterfall.Theory proving parametric cash conservation (sum allocateWaterfall = inflow) via new stable cbv tactic.Upgrade to Lean 4.30.0  Edit/create lean-toolchain: leanprover/lean4:v4.30.0

Run lake update

Run lake exe cache get

Run lake build (rebuilds everything)



Core Lemma:  lean


lemma waterfall_conserves_cash (tranches : List Tranche) (inflow : Float) :
  List.sum (allocateWaterfall tranches inflow) = inflow := by
    cbv [allocateWaterfall, trancheAlloc, decide]; simp [List.sum]



Tasks (P0): Create Theory.lean, re-export, migrate Verify/, add tests/examples, update README/CI. All proofs use cbv.

Verification: lake build && lake test(Complete v1 module – ready to implement.)




# Parametric Waterfall Conservation Laws for LFSERepo/package name: tripp-smith/lean-lfse (existing repository – this is a v1 extension module)Description:

A production-grade extension to the existing lean-lfse Lazy Financial Scenario Engine that formalizes parametric cash-conservation invariants for waterfall allocation. The new LFSE.Finance.Waterfall.Theory module provides reusable Lean theorems proving sum (allocateWaterfall tranches inflow) = inflow (and related properties) for any ordered List Tranche and any Float inflow, using the new stable cbv tactic (Lean 4.30+). It replaces ad-hoc sample proofs in LFSE/Verify/ with a systematic, computation-driven theory that short-circuits decidable guards (decide (cash > 0)) and evaluates the entire recursive allocation loop inside proofs. The module integrates seamlessly with the existing LFSE.Finance.Waterfall, lazy DAG forcing, and Verify/ workflows, enabling compile-time verification of financial primitives without concrete numbers.1. Executive SummaryThis specification defines a complete, auditable, and reusable theory module that leverages cbv to prove the fundamental conservation law of cash in waterfalls parametrically. It turns the existing recursive allocateWaterfall implementation into a formally verified primitive, strengthening the library’s auditability claim. The work is scoped to v1 completeness: new module, full proofs, integration, tests, documentation, and CI updates. No new runtime behavior is added—only compile-time guarantees.2. Project ClassificationCategory: Mathematical or scientific package (Lean 4 library extension / formal verification module).

Primary users: Quant developers, risk-model auditors, and Lean users building auditable financial scenario engines inside lean-lfse.

Main jobs-to-be-done: Prove cash conservation for arbitrary tranche structures and inflows at compile time; reuse the proofs in downstream Verify/ checks and user scenarios; demonstrate the power of the new cbv tactic for recursive financial computations.

Failure modes: Proofs that only hold for concrete numbers, proofs that rely on manual simp hell instead of cbv, floating-point equality issues without tolerance rules, or breaking existing Waterfall.lean API.

“Complete” definition: The module compiles, all lemmas are proven using cbv, all tests pass, existing sample invariants in Verify/ are re-derived from the new theory, documentation and examples exist, and CI runs successfully.



3. GoalsProvide a single source of truth for waterfall conservation invariants using cbv.

Make the proofs parametric (no concrete numbers required).

Integrate with the existing lazy engine and Verify/ module.

Ship production-quality Lean code that follows the library’s style.

Demonstrate cbv utility for recursive, conditional financial logic.



4. Non-GoalsAdding new runtime waterfall features or changing allocateWaterfall implementation.

Supporting non-Float cash types (e.g., Rat or fixed-point) in v1.

GUI/CLI changes.

Generalizing to non-linear waterfalls (e.g., with triggers, OC curves) – deferred to v2.



5. Users and Use CasesUser story 1: A quant adds a new ABS tranche structure and wants to prove conservation holds before running Monte-Carlo scenarios.

User story 2: An auditor reviews the library and sees machine-checked proofs that total paid always equals total received.

User story 3: A developer re-uses the theory lemmas in their own Scenario proofs via cbv-driven computation.

Primary workflows: Import LFSE.Finance.Waterfall.Theory, apply the lemmas in by blocks or #guard statements, run lake build to verify.



6. Domain Research SummaryLean 4.30+ cbv tactic performs call-by-value evaluation inside proofs, short-circuits decide predicates, and works well on recursive functions over lists (official release notes).

Financial waterfalls follow standard structured-finance practice: senior-first allocation with caps/floors; conservation of cash is an industry invariant (total out = total in).

Existing lean-lfse already implements recursive allocation in LFSE/Finance/Waterfall.lean and has ad-hoc tests/proofs for empty/zero-cash cases.

No external standards conflict; the module will reference the existing Tranche and allocateWaterfall exactly as defined in the repo.



7. Assumptions and DecisionsID

Area

Assumption / Decision

Rationale

Risk

How to Validate

A1

Tranche type

Use existing Tranche structure from LFSE/Finance/Waterfall.lean (no changes)

Matches user-provided lemma and current examples

None

Compile after import

A2

Cash type

Float with exact = equality (no tolerance in v1)

cbv reduces to exact arithmetic; tolerance can be added later via ≈

Floating-point drift in edge cases

Property tests with random inflows

A3

Allocation function

Target allocateWaterfall and internal trancheAlloc exactly

Matches the lemma and existing recursive logic

API rename in future

#guard tests

A4

Lean version

Require Lean 4.30.0+ (via lean-toolchain)

cbv is stable only from 4.30

Older users

Update toolchain + CI matrix

A5

File location

New directory LFSE/Finance/Waterfall/Theory.lean

Clear hierarchy, matches Verify/ style

None

Existing import paths unchanged



8. Functional RequirementsID

Requirement

Priority

Details

Acceptance Criteria

Verification

FR1

Parametric conservation lemma

P0

waterfall_conserves_cash using cbv

Proves for any List Tranche + Float inflow

lake build succeeds

FR2

Re-derive existing sample invariants

P0

Empty waterfall, zero-cash single-tranche, payment totals

Derived from FR1 via simp after cbv

LFSE/Verify/Proofs.lean updated

FR3

Family of helper lemmas

P1

trancheAlloc_preserves_cash, sum_nonnegative, monotonicity

All proved with cbv

Tests in test/Finance/WaterfallTheory.lean

FR4

Public API export

P0

Re-export from LFSE/Finance.lean

Users can open LFSE.Finance.Waterfall.Theory

Example files compile



9. Non-Functional RequirementsPerformance: Proofs compile in < 2 s on standard hardware (measured with time lake build).

Reliability: All lemmas are total and decidable where cbv is used.

Maintainability: Follow existing naming/style (camelCase, explicit imports).

Compatibility: Works with current lakefile.lean dependencies; no new deps.

Observability: Proofs emit no runtime trace; verification is compile-time only.



10. System ArchitectureStack: Lean 4.30.0+, Lake build system (existing).

Modules: LFSE.Finance.Waterfall.Theory imports LFSE.Finance.Waterfall; re-exports via LFSE/Finance.lean.

Data flow: Existing Tranche → allocateWaterfall → cbv reduction inside proofs.

Error flow: Proof failures are compile errors (Lean’s normal behavior).

Configuration: None (pure theory).

External dependencies: None new.



Text diagram:


LFSE/Finance/Waterfall.lean (existing impl)
          ↓ (import)
LFSE/Finance/Waterfall/Theory.lean (new cbv proofs)
          ↓ (re-export)
LFSE/Finance.lean
          ↓
LFSE/Verify/Proofs.lean + test/ + examples/



11. Repository Structure


lean-lfse/
├── LFSE/
│   ├── Finance/
│   │   ├── Waterfall.lean                 (existing – unchanged)
│   │   ├── Waterfall/
│   │   │   └── Theory.lean                (NEW)
│   │   └── Finance.lean                   (update re-export)
│   ├── Verify/
│   │   └── Proofs.lean                    (update to derive from Theory)
│   └── ...
├── test/
│   └── Finance/
│       └── WaterfallTheory.lean           (NEW)
├── examples/
│   └── WaterfallTheoryDemo.lean           (NEW)
├── lakefile.lean                          (update lean-toolchain if needed)
├── .github/workflows/ci.yml               (update Lean version matrix)
└── README.md                              (update with new section)



12. Data ModelNo new entities. Reference existing:Tranche (from Waterfall.lean): fields include priority/order, caps/floors, etc. (exact fields not changed).

List Tranche (ordered by seniority).

Float inflow/outflow.

Constraints: Tranches non-overlapping, ordered by attachment (enforced by existing code).

Serialization: None (pure Lean types).



13. InterfacesLibrary public API (in Theory.lean):lean


lemma waterfall_conserves_cash (tranches : List Tranche) (inflow : Float) :
    List.sum (allocateWaterfall tranches inflow) = inflow := by ...

-- Helpers
lemma trancheAlloc_preserves_cash ...
lemma allocateWaterfall_nonnegative ...



All lemmas marked @[simp] where appropriate for downstream use.14. Feature SpecificationsFeature FR1: Parametric Conservation LemmaPurpose: Prove cash conservation parametrically.

Inputs: List Tranche, Float inflow.

Outputs: Proven equality.

Behavior: cbv [allocateWaterfall, trancheAlloc, decide] reduces recursion; simp [List.sum] closes.

Validation: Exact = after reduction.

Edge cases: Empty list, zero inflow, negative inflow (still conserves), single tranche.

Errors: None (compile-time).

Security: N/A.

Performance: Instant proof.

Acceptance criteria:  Given any valid tranche list and inflow, when lemma is stated, then proof succeeds.

Verification: lake build + #guard in tests.



Feature FR2: Re-derive Existing InvariantsPurpose: Migrate sample proofs to new theory.

Behavior: Replace ad-hoc proofs with apply waterfall_conserves_cash; cbv; simp.

Verification: All old tests still pass.(Additional features FR3/FR4 follow identical pattern – omitted for brevity but fully specified in task checklist.)15. Testing and Verification PlanTest types: Unit (compile-time #guard), property (random tranche lists via Nat generators), integration (with existing Verify/ and examples).

Required files: test/Finance/WaterfallTheory.lean.

Fixtures: 5 golden tranche lists (empty, single senior, ABS 3-tranche, etc.).

Exact commands:lake test

lake build

lean --run Test.lean (existing test harness)


Manual QA checklist:Open examples/WaterfallTheoryDemo.lean in VSCode + Lean server – all goals close.

Run lake build after changing one tranche – proof still holds.


16. Build, Packaging, and DeploymentBuild: lake build (existing).

Packaging: Part of the lean-lfse package (no separate release).

CI: Update .github/workflows/ci.yml to use Lean 4.30.0+.



17. Security and PrivacyN/A (pure mathematical library). No secrets, no I/O in proofs.18. Observability and OperationsCompile-time only; Lean server provides proof-state tracing.19. Documentation PlanUpdate README.md with new “Waterfall Theory” section + example.

Add module docstring in Theory.lean.

New docs/WaterfallTheory.md with proof walkthrough and cbv usage guide.



20. Implementation Task ChecklistT-001: Repository setup

- Type: setup

- Priority: P0

- Dependencies: None

- Description: Update lean-toolchain to 4.30.0 and run lake update.

- Files to create or modify: lean-toolchain

- Acceptance criteria: lake exe cache get succeeds on 4.30.0.

- Verification: cat lean-toolchain shows v4.30.0

- Completion evidence: Report toolchain version.

T-002: Create Theory module skeleton

- Type: architecture

- Priority: P0

- Dependencies: T-001

- Description: Create directory and empty file with proper imports.

- Files: LFSE/Finance/Waterfall/Theory.lean

- Acceptance criteria: Compiles with import LFSE.Finance.Waterfall.

- Verification: lake build

- Completion evidence: File exists and builds.

T-003: Implement core conservation lemma (FR1)

- Type: feature

- Priority: P0

- Dependencies: T-002

- Description: Write and prove waterfall_conserves_cash exactly as specified using cbv.

- Files: LFSE/Finance/Waterfall/Theory.lean

- Acceptance criteria: Lemma type-checks and closes.

- Verification: lake build

- Completion evidence: Proof shown in Lean server.

T-004: Add helper lemmas (FR3)

- Type: feature

- Priority: P1

- Dependencies: T-003

- Description: Implement trancheAlloc_preserves_cash, allocateWaterfall_nonnegative, etc.

- Files: LFSE/Finance/Waterfall/Theory.lean

- Acceptance criteria: All proved with cbv.

- Verification: lake build

T-005: Update Finance re-export

- Type: feature

- Priority: P0

- Dependencies: T-003

- Description: Add import LFSE.Finance.Waterfall.Theory and open in Finance.lean.

- Files: LFSE/Finance.lean

- Acceptance criteria: open LFSE.Finance.Waterfall.Theory works in examples.

T-006: Migrate Verify/Proofs.lean

- Type: refactor

- Priority: P0

- Dependencies: T-005

- Description: Replace old invariants with calls to new theory lemmas.

- Files: LFSE/Verify/Proofs.lean

- Acceptance criteria: All old proofs still hold.

T-007: Write test suite

- Type: test

- Priority: P0

- Dependencies: T-003

- Description: Create full test file with #guard and random property checks.

- Files: test/Finance/WaterfallTheory.lean

- Acceptance criteria: All tests pass.

- Verification: lake test

T-008: Create demo example

- Type: docs

- Priority: P1

- Dependencies: T-005

- Description: Add examples/WaterfallTheoryDemo.lean.

- Files: examples/WaterfallTheoryDemo.lean

T-009: Update documentation

- Type: docs

- Priority: P1

- Dependencies: T-008

- Description: Add sections to README and create docs/WaterfallTheory.md.

T-010: Update CI

- Type: infra

- Priority: P0

- Dependencies: T-001

- Description: Ensure CI matrix includes Lean 4.30.0.

T-011: Final verification run

- Type: verification

- Priority: P0

- Dependencies: T-010

- Description: Run full build + test suite.

- Verification: lake build && lake test



21. Final Definition of DoneAll P0 tasks complete, lake build and lake test pass cleanly, no TODOs in new files, documentation updated, and proofs use cbv as the primary tactic.22. Final Handoff Report TemplateFinal Handoff Report:  Project summary

Completed tasks

Deferred tasks, with reasons

Verification commands run + results

Known limitations

Security notes

Performance notes

Files changed

How to run locally (lake build)

How to test (lake test)

Recommended next steps (e.g., v2 triggers)



This specification is complete, unambiguous, and ready for implementation. The coding agent can begin with T-001 and finish with a fully verified, production-quality theory module.
