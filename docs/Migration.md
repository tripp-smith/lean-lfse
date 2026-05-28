# Migration From LFSE v1

Most v1 code continues to work unchanged through the `LFSE` facade:

- `#scenario`, `forceNPV`, `forceTrace`, `forceMonteCarlo`, and `exportDot`
  remain available.
- `Instrument.forward`, `Instrument.option`, and `Instrument.swap` remain the
  compatibility constructors.
- CLI commands `build`, `eval`, `trace`, and `export-dot` keep their previous
  behavior.

New v2.1 code should prefer registered engines/providers, `forceWithEngine`,
`computeGreeks`, `loadMarketProvider`, and `exportLineage`.

`PricingEngine` is now a compatibility alias for an open `PricingEngineRef`.
Existing calls such as `forceWithEngine scenario (.monteCarlo 1000 42)` still
work, but implementation dispatch goes through `Registry.lookupEngine`.
