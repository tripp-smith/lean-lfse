# Phase A Cleanup Plan: Making the LSMC Transition Clean

**Date:** 2026-05-30  
**Context:** Phase B (core algorithm) is complete and verified. Phase A (Instrument variants + basic Engine integration) has basic functionality working, but the codebase is in a transitional state with significant technical debt.

**Goal:** Turn the current "it works" state into a *nice, clean* Lean codebase with minimal legacy debt around the LSMC feature.

---

## Current Problems (Summary)

1. **Module Duality / Legacy Debt** (Biggest issue)
   - Legacy flat `LFSE/Finance/LSMC.lean` still defines old `LSMCConfig` + has non-full LSMC logic.
   - New clean implementation lives in `LSMC/` subdirectory.
   - `EngineParams.lsmc` and public API still use the old type.
   - Constant import/qualification friction.

2. **Incomplete Adoption of New Instruments**
   - New `bermudanOption` / `americanOption` exist but are barely used outside Instrument/Engine/Scenario.
   - DSL, Python, CLI, many tests still only know the old variants.

3. **Public API Inconsistency**
   - Users of `PricingEngine.lsmc` still get the old config shape.
   - New instruments have good field population, but the Engine doesn't fully leverage the modern `LSMC.Config` for them yet.

4. **Documentation Lag**
   - CHANGELOG still says Phase A "not started".
   - No ADR explaining the design decisions and transition strategy.
   - README is decent but could be clearer.

5. **Transitional Code**
   - Old `monomialBasis`, outdated comments, etc.

---

## Prioritized Cleanup Plan

### Phase 1: Resolve the Core Duality (Highest Impact)

**Goal:** Make the new `LSMC.Config` the primary type used for LSMC pricing in the public API.

**Tasks:**

1. **Refactor Engine surface (Option 1 from previous discussion)**
   - Change `EngineParams.lsmc : NewLSMCConfig.Config`
   - Update `PricingEngineRef.lsmc`, `PricingEngine.lsmc`, and `lsmcEngineEntry` signature.
   - In `lsmcEngineEntry`, for new instrument keys, use the passed modern config (enriching `style` from instrument data when available).
   - For the old "call-option" special case: add a conversion from legacy `LSMCConfig` → new `LSMC.Config` (or keep calling the shim temporarily).

2. **Clean up the legacy shim (`LFSE/Finance/LSMC.lean`)**
   - Make `priceBermudanPut` / `Call` / `priceAmericanPut` true thin wrappers:
     - Convert old `LSMCConfig` → new `LSMC.Config`
     - Delegate to `LSMC.Algorithm.lsmcPrice`
   - Remove or deprecate `monomialBasis` and other transitional helpers.
   - Update comments to clearly mark this as compatibility layer only.

3. **Update `builtinRegistryFor` and related registration logic** to work with the new config type.

**Success Criteria:**
- `EngineParams.lsmc` accepts the modern `LSMC.Config`.
- New instruments go through the clean `LSMC.Algorithm` path.
- Old call sites using legacy `LSMCConfig` still compile (via conversion or shim).
- No more qualification fights in Engine.lean for the new modules.

**Estimated Effort:** Medium-High (biggest bang for buck).

---

### Phase 2: Complete Instrument Adoption

**Goal:** Make the new variants feel first-class everywhere, not just "they exist".

**Tasks:**

1. Update all construction sites:
   - `LFSE/Test.lean`
   - `LFSE/Finance/Synthetic.lean`
   - `LFSE/CLI/Commands.lean`
   - `LFSE/Python/Bindings.lean`
   - `LFSE/Server/Basic.lean`
   - `LFSE/Finance/Scenario.lean` (already has helpers — good)

2. Add proper DSL support:
   - Extend `LFSE/DSL/Syntax.lean` and `Macros.lean` with `bermudanOption(...)` and `americanOption(...)` syntax (or at minimum document the raw construction well).

3. Update Greeks and any other special-cased logic to handle the new variants elegantly (remove the current hacky patches if possible).

4. Add `isEarlyExercise` helper on `Instrument` (or similar) to reduce future match duplication.

**Success Criteria:**
- All major construction paths support the new instruments.
- DSL can create them.
- Python/CLI examples work with Bermudan/American options.

---

### Phase 3: Documentation & Communication

**Goal:** Make the current state of the world clear and professional.

**Tasks:**

1. **CHANGELOG.md**
   - Add proper "Unreleased" entry for Phase A.
   - Clearly mark breaking changes (`Instrument` inductive, `EngineParams.lsmc` type change if we take the breaking path).

2. **Create ADR**
   - New file: `ADR/007-lsmc-instrument-integration.md`
   - Explain: why we kept a legacy shim, the `ExerciseStyle` design, decision on `EngineParams` type, module structure choice.

3. **README.md**
   - Improve the "Bermudan / American" section.
   - Show both legacy and modern config usage during transition.
   - Link to the new ADR.

4. **Update `_tmp/PHASE_A_BLAST_RADIUS.md`** (or move key parts into the ADR).

5. **Update handoff docs** if relevant.

---

### Phase 4: Test & Verification Hardening

**Tasks:**

1. Add dedicated tests for the new instrument kinds (registry, dispatch, pricing).
2. Add regression tests that prove old instruments are unaffected.
3. Consider adding a simple golden-style test for a known Bermudan case using the new instruments.
4. Clean up any remaining `sorry` or transitional tests related to LSMC.

---

### Phase 5: Polish & Removal (Lower Priority)

- Remove `monomialBasis` and other dead transitional code once nothing uses the old paths.
- Consistent naming and error messages across LSMC-related code.
- Review and clean outdated comments in `Instrument.lean`, `Engine.lean`, `LSMC.lean`, etc.
- Consider whether the old `LSMCConfig` should be fully removed in a future minor version bump (with migration guide).

---

## Recommended Execution Order

1. **Phase 1** (Core Duality) — Do this first. Everything else is easier once the types are consistent.
2. **Phase 3** (Docs) — Do in parallel with Phase 1 or right after. High communication value.
3. **Phase 2** (Adoption) — Spread out as you touch files.
4. **Phase 4** (Tests)
5. **Phase 5** (Polish)

---

## Success Criteria for "Clean"

- A new developer can understand the LSMC story by reading the ADR + README without being confused by legacy code.
- `EngineParams.lsmc` and the public API are on the modern `LSMC.Config`.
- New instruments have first-class support in DSL, Python, CLI, and examples.
- No more "this is transitional because of X" comments in the hot path.
- Full `lake build && lake test` is green with no special workarounds.

---

**Execution Status (as of latest session):**

**Phase 1 (Core Duality) — COMPLETE** (shipped via ccp)

**Phase 3 (Documentation) — Substantially Complete**
- ADR 007 (`ADR/007-lsmc-instrument-integration.md`) created and accepted. It serves as the central design record for the LSMC integration decisions.
- CHANGELOG.md enhanced with Phase A hygiene + adoption progress and ADR link.
- README "Bermudan / American" section significantly expanded: modern `LSMC.Config` examples, legacy shim comparison, DSL syntax, CLI usage (`--engine lsmc`), and strong cross-link to ADR 007.
- `_tmp/PHASE_A_BLAST_RADIUS.md` brought up to date with current state (DSL, CLI, Python, tests, ADR).

**Next Tranche Active:** Phase 2 (Instrument Adoption) + Phase 3 (Docs/ADR) — "make the new variants feel first-class everywhere" + professional documentation.

**Progress in current session:**
- Added `Instrument.isEarlyExercise` helper (reduces match duplication).
- Cleaned up `supportedEngineKeys` logic using the new helper.
- Added full DSL syntax + macro support for all four early-exercise forms.
- Updated `LFSE/Test.lean` with new instrument + LSMC tests.
- Updated Python bindings placeholder to demonstrate bermudan usage.
- **Created ADR 007** (`ADR/007-lsmc-instrument-integration.md`): Documents the key decisions around `LSMC.Config` as primary type, the legacy shim strategy, `ExerciseStyle` enrichment in the engine, and why we accepted the public API break instead of adapters.
- **Finalized CLI updates** (`LFSE/CLI/Commands.lean`):
  - Added `--engine analytic|monte-carlo|lsmc` flag (wired through `evalCmd` using `forceWithEngine`).
  - `scenarioFromPath` now supports `examples/BermudanOption.lean` with real `bermudanPut`.
  - `register` command now registers all four new instrument descriptors.
  - Updated usage text.
  - Verified: `lake exe lfse eval examples/BermudanOption.lean --engine lsmc` successfully prices a Bermudan put end-to-end.
- Build and manual CLI smoke tests remain green.

- `EngineParams.lsmc` (and `PricingEngine.lsmc` / `lsmcEngineEntry`) now use the modern `LSMC.Config` as the public type. This is the authoritative structure with `ExerciseStyle`, `BasisFamily`, `ridge`, `antithetic`, etc.
- Legacy flat `LSMCConfig` + `priceBermudan*` shims in `LFSE/Finance/LSMC.lean` are now a thin, well-documented compatibility layer only. They contain a `legacyConfigToModern` converter and delegate 100% of work to `LSMC.priceBermudan*` / `lsmcPrice`.
- Removed transitional `monomialBasis`, outdated comments, and all broken naive-averaging stubs from the shim.
- In `lsmcEngineEntry` (Engine.lean:136), the hot path for new instruments (`bermudan-*` / `american-*`) now:
  - Uses the passed modern `cfg` for tuning parameters.
  - Reconstructs a precise `ExerciseStyle` (`.bermudan` dates array or `.american` step count) by reading the `exerciseDateN` / `steps` / `exerciseDateCount` fields that `Instrument.fields` populates from the first-class variants.
  - Builds `effCfg := { cfg with style := instrumentStyle }`.
  - Calls `LSMC.priceBermudanPut` / `priceBermudanCall` (from Algorithm) directly.
- The old "call-option" special case was also migrated to a direct modern call (no more legacy shim in the Engine dispatch hot path).
- Import hygiene resolved cleanly: `import LFSE.Finance.LSMC.Config` + `import ...Algorithm` + `open LFSE.Finance.LSMC` + `LSMC.Config` / `LSMC.ExerciseStyle` / `LSMC.price*` qualifiers. No clashes with the (now purely compat) legacy `LSMCConfig`.
- Legacy import removed from Engine entirely.
- All call sites (examples/BermudanOption.lean, LFSE/Test.lean) continue to work unchanged because `{ paths := ..., seed := ... }` and `{}` are valid for the new `Config` (defaults fill the rest; instrument-specific style is enriched in dispatch for berm/amer instruments).

**Verification**: `lake build` clean, `lake test` fully green, `examples/BermudanOption.lean` executes successfully and produces consistent NPV.

**Phase 1 success criteria met** (public API on modern type, new instruments on clean direct path, no qualification fights, legacy shim is honest thin layer, tree green).

Remaining phases (Instrument adoption in DSL/CLI/Python, docs/ADR, removal of more transitional code) can now proceed on a solid foundation.

**This plan document will be updated as execution continues.**