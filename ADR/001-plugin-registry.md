# ADR 001: Plugin Registry

Use typed Lean descriptors plus a runtime registry map. This preserves compile
time safety while letting extension modules register instruments, engines, data
providers, and exporters without editing core modules.
