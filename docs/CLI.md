# LFSE CLI Guide

## Commands

```bash
lake exe lfse -- build examples/BermudanOption.lean
lake exe lfse -- eval examples/BermudanOption.lean --scenario base --format json
lake exe lfse -- eval examples/BermudanOption.lean --scenario base --format yaml
lake exe lfse -- trace examples/BermudanOption.lean --trace-level 2
lake exe lfse -- export-dot examples/BermudanOption.lean --output build/bermudan.dot
lake exe lfse -- export-graph examples/BermudanOption.lean --output build/graph.json
lake exe lfse -- serve --host 127.0.0.1 --port 8080 --token TOKEN
lake exe lfse -- register
lake exe lfse -- benchmark --dashboard
lake exe lfse -- test-suite
```

## Flags

- `--scenario NAME`: scenario selector, default `base`.
- `--format json|yaml`: stdout report format for `eval`.
- `--paths N`: Monte Carlo path count for `eval`.
- `--seed N`: deterministic RNG seed for `eval`.
- `--trace-level N`: `0` disables trace output; `1+` prints forced nodes.
- `--output PATH`: destination for `export-dot` or `export-graph`.
- `--host HOST`, `--port PORT`, `--token TOKEN`: server smoke settings.

## Exit Codes

- `0`: success.
- `1`: evaluation, data, or graph error.
- `2`: invalid CLI invocation or missing file for `build`.
