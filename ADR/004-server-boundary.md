# ADR 004: Server Boundary

The Lean server layer is modeled as request handlers with auth, size limits, and
structured responses. This keeps route behavior testable even when deployment
uses a thin HTTP adapter.
