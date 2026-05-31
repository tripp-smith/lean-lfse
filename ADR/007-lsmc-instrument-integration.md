# ADR 007: LSMC Instrument Integration and Engine Hygiene

**Date:** 2026-05-30  
**Status:** Accepted  
**Deciders:** Grok 4.3 (autonomous execution per user direction)  
**Related:** Phase B correctness work, `_plans/001_phase_b_core_lsmc_correctness.md`, `_plans/002_phase_a_lsmc_cleanup.md`

## Context

Phase B delivered a correct, production-grade Longstaff–Schwartz implementation in `LFSE.Finance.LSMC.Algorithm` using the rich `LSMC.Config` type (`ExerciseStyle`, `BasisFamily`, ridge regularization, antithetic variates, etc.).

When we added first-class `Instrument.bermudanOption` and `Instrument.americanOption` variants (to satisfy the formal spec), the existing public API surface was still built around the old flat `LSMCConfig` struct and the legacy `LFSE.Finance.LSMC` module. This created a dual-type problem:

- `EngineParams.lsmc : LSMCConfig`
- Modern algorithm lived under `LSMC/Config` + `LSMC/Algorithm`

Routing the new instruments through the old shims would have hidden the real algorithm and made future evolution painful. Small adapter layers were explicitly rejected.

## Decision

We made the following coordinated changes:

1. **Public API change**: `EngineParams.lsmc` (and `PricingEngine.lsmc` / `lsmcEngineEntry`) now use `LSMC.Config` as the primary type.
2. **Legacy shim**: `LFSE/Finance/LSMC.lean` was reduced to an explicit, thin compatibility layer containing only:
   - The old `LSMCConfig` struct (for existing call sites)
   - A `legacyConfigToModern` converter
   - Four delegating `priceBermudan*` / `priceAmerican*` functions
3. **Dispatch enrichment**: In `lsmcEngineEntry`, the engine now constructs a proper `LSMC.Config` for early-exercise instruments by:
   - Taking general tuning parameters (paths, seed, basis, ridge, antithetic, …) from the caller's `PricingEngine.lsmc` config
   - Overriding `style` with instrument-specific data (bermudan dates from `exerciseDateN` fields, or american steps) read from `Instrument.fields`
4. **Module organization**: Kept `LSMC/Config.lean` and `LSMC/Algorithm.lean` as the authoritative modules. The flat `LSMC.lean` is now clearly documented as transitional only.

## Rationale

- **Small blast radius**: Only a handful of call sites constructed `LSMCConfig` records directly (`examples/BermudanOption.lean`, one test). The record update syntax `{ paths := ..., seed := ... }` remains valid for the new `Config`.
- **Avoided technical debt**: Using adapters or keeping two parallel config types would have made the framework harder to maintain and evolve — exactly the opposite of the "polished framework" goal.
- **Correct separation of concerns**: `ExerciseStyle` belongs to the pricing configuration, not the instrument definition. Instruments declare *when* they can be exercised; the engine decides *how* to configure the LSMC run. Reconstructing the style in the dispatch layer keeps both Instrument and Config clean.
- **Pragmatic transition**: Deleting the old `LSMCConfig` immediately would have broken downstream users unnecessarily. The thin shim gives a clean migration path while making the modern path the only one that receives new features.

## Consequences

**Positive**
- New `bermudanOption` / `americanOption` instruments now have first-class, correct LSMC support through the public `forceWithEngine` + `PricingEngine.lsmc` surface.
- The CLI (`--engine lsmc`), DSL, Python bindings, and tests can (and do) use the new instruments.
- All future LSMC enhancements (better bases, variance reduction, multi-asset, etc.) only need to touch the modern `LSMC.*` modules.
- `lake build && lake test` remains green with no special workarounds.

**Negative / Trade-offs**
- Breaking change for anyone who was programmatically constructing `EngineParams { lsmc := { ... } }` using the old flat shape (documented in CHANGELOG and the Phase A session notes).
- The legacy `LSMCConfig` + shim functions will eventually be deprecated and removed (target: a future minor version with migration guide).

**Future Work**
- Phase 2/3 of the cleanup plan: deeper DSL/CLI/Python adoption, full ADR cross-linking in README, and eventual removal of the shim once adoption is complete.
- The design makes it straightforward to add `european` as a degenerate `ExerciseStyle` case later if desired.

## References

- `_plans/002_phase_a_lsmc_cleanup.md` (Phase 1 = Core Duality, now complete)
- `_tmp/SESSION_2026-05-30_lsmc-engine-hygiene.md`
- `LFSE/Finance/Engine.lean` (lsmcEngineEntry)
- `LFSE/Finance/LSMC.lean` (the shim)
- `LFSE/Finance/LSMC/Config.lean` and `Algorithm.lean` (the authoritative implementation)