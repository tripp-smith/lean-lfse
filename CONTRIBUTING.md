# Contributing

Run the sequential local verification set before opening a PR:

```bash
lake build
lake test
lake exe lfse -- eval examples/BermudanOption.lean --scenario base --format json
lake exe lfse -- export-graph examples/BermudanOption.lean
python -m pytest python/tests
```

New user-facing capabilities should include a registry descriptor, a test, an
example or documentation note, and an entry in `CHANGELOG.md`.
