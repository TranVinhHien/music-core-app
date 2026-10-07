# ADR 0001: Use deterministic local Demo authentication

- Status: Accepted
- Date: 2026-09-20

## Context

The reference app needs a complete sign-in, session restoration, and route-gate
flow, but it has no backend or identity provider. Network-shaped authentication,
tokens, or production security claims would add unsupported behavior and obscure
the teaching boundary.

## Decision

Use two public, deterministic Demo accounts behind the domain `AuthRepository`.
The contract exposes `restoreSession`, `signIn`, and `signOut`. Persist only the
active account identifier with `SharedPreferencesAsync`, and clear an unknown
identifier during restoration.

Invalid credentials remain an auth-owned failure. Operational session-storage
exceptions become the shared `StorageFailure` transported by `Result`.

## Consequences

The authentication flow is deterministic, offline, and testable, but it is not
OAuth or a production identity system. The credentials are intentionally public
and must not be reused for a real application. A future backend adapter may keep
the domain contract only when its session semantics remain compatible.
