# ADR 002: Backends And Effects

Lazy evaluation keeps the existing memoized DAG but adds backend policy. The
audit backend can reject effect nodes, while standard evaluation keeps v1
behavior for compatibility.
