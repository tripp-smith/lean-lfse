# Security

LFSE does not execute runtime DSL text. Scenario syntax is Lean code compiled by
Lake, and server-mode payloads are validated before routing.

Security controls in v2.1:

- bearer-token checks for non-health server routes;
- request-size limits through `Config.maxInputBytes`;
- structured `LFSEError.securityError` failures;
- no secret logging; tokens are redacted by `LFSE.Security.redactToken`;
- deterministic audit lineage for graph exports and model governance.

Report private issues to the repository owner before publishing details.
