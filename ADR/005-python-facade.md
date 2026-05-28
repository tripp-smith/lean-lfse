# ADR 005: Python Facade

The Python package mirrors the C ABI shape and can call server deployments. It
ships with deterministic local fallbacks so notebooks and packaging tests do not
depend on native library loading.
