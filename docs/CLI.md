# LFSE CLI Guide

## Commands

```bash
lake exe lfse -- build examples/BermudanOption.lean
lake exe lfse -- eval examples/BermudanOption.lean --scenario base --format json
lake exe lfse -- eval examples/BermudanOption.lean --scenario base --format yaml
lake exe lfse -- trace examples/BermudanOption.lean --trace-level 2
lake exe lfse -- export-dot examples/BermudanOption.lean --output build/bermudan.dot
```

## Flags

- `--scenario NAME`: scenario selector, default `base`.
- `--format json|yaml`: stdout report format for `eval`.
- `--paths N`: Monte Carlo path count for `eval`.
- `--seed N`: deterministic RNG seed for `eval`.
- `--trace-level N`: `0` disables trace output; `1+` prints forced nodes.
- `--output PATH`: destination for `export-dot`.

## Exit Codes

- `0`: success.
- `1`: evaluation, data, or graph error.
- `2`: invalid CLI invocation or missing file for `build`.
