# LFSE Testing Guide

Run the core gates sequentially:

```bash
lake build
lake test
lake env lean test/Finance/WaterfallTheory.lean
lake env lean examples/BermudanOption.lean
lake env lean examples/PortfolioStress.lean
lake env lean examples/WaterfallABS.lean
lake env lean examples/WaterfallTheoryDemo.lean
lake env lean examples/SimpleMC.lean
lake exe lfse -- eval examples/BermudanOption.lean --scenario base --format json
lake exe lfse -- trace examples/BermudanOption.lean --trace-level 2
lake exe lfse -- export-dot examples/BermudanOption.lean --output build/bermudan.dot
lake exe lfse -- export-graph examples/BermudanOption.lean
lake exe lfse -- serve
lake run benchmarks
python -m pytest python/tests
lake pack
```

The unit suite is centralized in `LFSE/Test.lean` and mirrored by files under
`test/` for source-level organization.
