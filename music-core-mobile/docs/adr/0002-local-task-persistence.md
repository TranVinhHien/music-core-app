# ADR 0002: Store account-scoped tasks in Drift

- Status: Accepted
- Date: 2026-09-20

## Context

The reference app needs durable local task data and account isolation. An
in-memory list would not demonstrate a meaningful persistence boundary, while a
remote API would introduce credentials, network failure, and contract concerns
outside the product scope.

## Decision

Use Drift over SQLite as the local task source of truth. The version-1 `tasks`
table stores owner, title, completion, and `updatedAt` values. Every read and
mutation is owner-scoped; a missing task or one owned by another account produces
`TaskNotFoundFailure`.

The repository exposes a reactive owner- and filter-scoped stream so Drift
changes update the UI without a separate list cache. Each flavor uses a separate
database. An account with no stored tasks has an empty list, and reads never
perform seed writes.

## Consequences

The example has typed queries, explicit schema ownership, in-memory repository
tests, and a visible account-isolation invariant. It does not provide
synchronization, encryption, a remote source of truth, or migrations beyond the
current candidate schema. A released schema change must add a real Drift
migration and an upgrade test.
