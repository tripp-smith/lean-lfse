# LFSE v2.1 Extension Guide

LFSE extensions register callable entries instead of changing core modules. The
main entry points are `registerInstrument`, `registerEngine`,
`registerDataProvider`, `DSL.registerExtension`, and the lookup helpers under
`LFSE.Registry`.

Minimum extension checklist:

- choose a stable registry key and implementation key;
- reject duplicate registrations unless the descriptor is identical;
- expose a payoff node or pricing engine through the existing `Scenario` flow;
- include lineage and trace output;
- document CLI or Python usage if the extension is user-facing.

See `examples/Extensions/CustomExotic.lean` for a complete example that defines
new syntax, registers DSL metadata, registers an instrument, and dispatches
through a custom engine.
