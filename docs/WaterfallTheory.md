# Waterfall Theory

`LFSE.Finance.Waterfall.Theory` contains executable conservation checks and
theorem-backed edge-case lemmas for the waterfall allocator in
`LFSE.Finance.Waterfall`.

The runtime API returns `List Payment`, not a list of raw cash amounts, and a
waterfall may leave residual cash when inflow exceeds tranche dues. The checked
invariant is:

```lean
paymentsTotal (allocateWaterfall inflow tranches) +
  remainingAfterWaterfall inflow tranches == inflow
```

For arbitrary IEEE `Float` values, the exact parametric equality form requested
by `spec.v3.md` is not a sound theorem: floating-point addition and subtraction
do not form the algebra needed for a universal proof. The module therefore keeps
the production API honest: use theorem-backed edge cases for structural facts,
and use `#guard` / `native_decide` or runtime tolerance checks for concrete
Float allocations.

## Public API

- `remainingAfterWaterfall`: computes residual cash with the same fold used by
  `allocateWaterfall`.
- `waterfallCashTotal`: computes paid cash plus residual cash.
- `waterfallConservesCash`: executable `Bool` checker for exact Float
  conservation on concrete inputs.
- `waterfall_conserves_cash_checked`: records checked conservation results as
  theorem evidence when the checker reduces to `true`.
- `waterfall_empty`, `remainingAfterWaterfall_empty`, and
  `waterfall_zero_cash_single_tranche_payment`: reusable edge-case invariants
  used by `LFSE.Verify.Proofs`.

## Example

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

Run the focused checks with:

```bash
lake env lean test/Finance/WaterfallTheory.lean
lake env lean examples/WaterfallTheoryDemo.lean
```
