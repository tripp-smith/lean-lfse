# Phase B: Core LSMC Algorithm Correctness

**Plan ID:** 001  
**Date:** 2026-05-29  
**Status:** COMPLETE — All gates B1–B5 + all post-review deltas closed (see final signed report in _tmp/PHASE_B_VERIFICATION_REPORT.md)  
**Priority:** High (Must complete before Instrument integration / Phase A)

---

## 1. Context & Decision

After the initial broad LSMC formal implementation plan (see session plan at `~/.grok/sessions/.../plan.md`), the team decided on a revised execution order:

**We will complete Phase B (Core Computational Correctness) before Phase A (Instrument Variants + Engine Integration).**

This decision was made because:
- The core `simulatePaths` + `lsmcPrice` logic must be demonstrably correct before exposing new `bermudanOption` / `americanOption` instrument types that depend on it.
- Adding Instrument variants too early would cause constant context-switching between algorithm bugs and integration plumbing.

---

## 2. Scope of Phase B

**Goal:** Deliver a fully correct, well-tested implementation of:
- `simulatePaths` (proper multi-date Gaussian paths)
- `lsmcPrice` (complete Longstaff–Schwartz with multi-date backward induction, ITM regression, per-path stopping times, and path-specific discounting)

Using the **full `LSMCConfig` shape** from the spec.

### Definition of "Fully Correct" (User Decision)

- Full multi-date backward induction with per-path stopping times and path-specific discounting.
- Support for all three basis families: Monomial, Laguerre, Hermite.
- Full `LSMCConfig` shape, including `ExerciseStyle` (bermudan + american discretization), `BasisFamily`, `antithetic`, `twoPass`, `itmOnly`, and `ridge`.
- Full proposed numerical robustness behavior (try dposv → ridge-augmented → dgels, return `none` gracefully).
- Reproducible by seed.

### Explicitly Out of Scope for Phase B

- New `Instrument` variants (`bermudanOption`, `americanOption`) and associated match-site updates (this is Phase A).
- Full formal Spec / Reference (ℚ) / Tier-A/B proof layers.
- LAPACK FFI wiring (can be done in parallel but not blocking for this phase).
- Python/CLI/Server exposure changes (beyond what's needed for testing).
- Performance optimization pass.
- Complete LS Table 1 golden suite (only a meaningful verification subset is required).

---

## 3. Questions Asked & Decisions Made

During planning, the following questions were asked and answered (with rationale):

### Q1: Definition of "fully correct"
**Asked:** What specific behaviors must the implementation demonstrate?

**Decision:** Full multi-date backward induction with per-path stopping times and path-specific discounting.

**Rationale:** This matches the canonical Longstaff–Schwartz algorithm as described in the formal spec. Anything less would be a partial implementation, violating the anti-partial rules.

### Q2: Basis families
**Asked:** Which basis families must be supported?

**Decision:** All three (Monomial, Laguerre, Hermite) as defined in the full spec.

**Rationale / Tradeoff:** 
- More complete and closer to the spec.
- Increases implementation surface in `Basis.lean`.
- Acceptable because the user explicitly wanted the full shape in this phase.
- Downside: More code to test and maintain in B phase.

### Q3: American option handling
**Asked:** How should we handle the exercise grid for American options?

**Decision:** Full support for both styles as defined in the spec's `LSMCConfig` (`ExerciseStyle.bermudan` + `ExerciseStyle.american`).

**Rationale:** Avoids deferring important configuration logic. Better to get the full `Config` shape right now rather than evolving it later during Instrument integration.

### Q4: Numerical robustness
**Asked:** What level of solver robustness is required?

**Decision:** Full proposed behavior — try `dposv` → ridge-augmented → `dgels`, return `none` gracefully (per spec NFR-R1 and D-15).

**Rationale:** This is production-grade behavior. Skipping it would mean the implementation is not yet "real" LSMC. The graceful degradation path is important for the algorithm's statistical properties.

### Q5: Verification bar
**Asked:** What must pass before we consider Phase B verified?

**Decision:** 
- Comprehensive property tests.
- Working binomial tree reference oracle.
- Statistical agreement on a meaningful subset of LS Table 1 cells (all T=1 cases + 1–2 T=2 cases) with documented tolerances.
- No `sorry` in core computational modules.
- Clean builds and manual review of examples.

**Rationale / Tradeoff:**
- Stronger than "just make it compile".
- Weaker than requiring the full 24-cell golden suite (which would be too slow for this phase).
- The binomial oracle tolerance was loosened to ~1e-2 for this phase (acceptable because this is an internal verification tool, not the final golden tests).

### Q6: ℚ Reference layer
**Asked:** Do we need the ℚ Reference implementation (`lsmcPriceQ`) in this phase?

**Decision:** No — pure Float + good binomial tree oracle is sufficient.

**Rationale:** 
- Reduces scope significantly.
- The binomial tree provides an independent ground truth.
- The ℚ layer can be added later if stronger cross-verification is needed (e.g., during formal proof work).

### Q7: LS Table 1 verification subset
**Asked:** Which cells must show agreement?

**Decision:** A meaningful subset (all T=1 cases + at least 1–2 T=2 cases).

**Rationale:** Provides good coverage of the classic benchmark without requiring the full expensive 24-assertion suite in this phase.

---

## 4. Sub-Phases & Execution Order

Recommended order with verification gates:

1. **B1** — `simulatePaths` (correct per-step Gaussian paths + antithetic + reproducibility)
2. **B2** — Full `LSMCConfig` shape + validation
3. **B4** — `BasisFamily` (all 3) + robust `normalEqSolveSafe`
4. **B3** — Full `lsmcPrice` implementation (core algorithm)
5. **B5** — Verification Package (property tests + binomial oracle + Table 1 subset agreement)

---

## 5. Success Criteria (Exit Gates for Phase B)

Before moving to Instrument integration (A), the following **must** be true:

- `lsmcPrice` implements true multi-date Longstaff–Schwartz with per-path stopping times.
- All three basis families work.
- Full `LSMCConfig` shape is supported and validated.
- Robust solver fallback chain is implemented.
- Verification package passes (see B5 in the plan).
- No `sorry` in `MonteCarlo`, `Numerics/*`, or `LSMC/Algorithm`.
- Clean `lake build`.

---

## 6. Risks & Mitigations (Phase B Specific)

- Numerical instability with high-degree bases or ill-conditioned matrices.
- Subtle bugs in multi-date discounting / stopping time logic.
- Binomial tree oracle accuracy becoming a bottleneck for verification.
- Scope creep (adding Instrument work too early).

**Mitigation:** Strict adherence to this plan + frequent verification gates.

---

*This plan was created during an autonomous planning session on 2026-05-29. It captures the questions asked and the explicit decisions + tradeoffs made by the user.*