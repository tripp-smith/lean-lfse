# Waterfall Theory

`LFSE.Finance.Waterfall.Theory` contains two related verification surfaces for
the waterfall allocator in `LFSE.Finance.Waterfall`: executable checks for the
Float runtime API, and a generic exact model with a true parametric conservation
theorem.

The runtime API returns `List Payment`, not a list of raw cash amounts, and a
waterfall may leave residual cash when inflow exceeds tranche dues. The checked
invariant is:

```lean
paymentsTotal (allocateWaterfall inflow tranches) +
  remainingAfterWaterfall inflow tranches == inflow
```

For arbitrary IEEE `Float` values, exact universal equality is not sound:
floating-point addition and subtraction do not form the algebra needed for a
parametric theorem. The Float-facing helpers therefore use `#guard`,
`native_decide`, or runtime tolerance checks for concrete allocations.

The `Exact` namespace provides a separate generic model for exact cash domains.
It proves:

```lean
Exact.paymentsTotal (Exact.allocateWaterfall cash tranches) +
  Exact.remainingAfterWaterfall cash tranches = cash
```

for any type with an `Exact.ExactCash` instance, including the provided `Int` and
`Rat` instances.

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
- `Exact.waterfallConservesCash`: generic parametric conservation theorem.
- `Exact.waterfallCashTotal_eq_cash`: packaged equality for paid plus residual
  exact cash.

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

Exact parametric theorem:

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

Run the focused checks with:

```bash
lake env lean test/Finance/WaterfallTheory.lean
lake env lean examples/WaterfallTheoryDemo.lean
```
