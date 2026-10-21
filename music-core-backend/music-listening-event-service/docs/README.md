# Music Listening Event Service - Documentation

## Status: Implemented & Active

The **Listening Event Service** is the telemetry backbone for Music Core App, receiving real-time user playback states, search telemetry, and library interactions.

- **Runtime**: Go 1.26
- **Database**: MongoDB (via `go.mongodb.org/mongo-driver/v2`)
- **Port**: `3004` (Ingress via Gateway at `/api/v1/listening-events`)
- **Idempotency**: Guaranteed by unique index on `event_id` and MongoDB unordered bulk operations.

---

## Documentation Index

- @[Architecture & Pipeline Design](architecture.md)
  - Detailed ingestion sequence, idempotency resolution, error taxonomy, and connection pooling.
- @[Event Schemas & Validation Matrix](event-schemas.md)
  - Full specifications for all 12 supported event schemas, required vs optional properties, and payload examples.
- @[API Contracts](api-contracts.md)
  - Request/response envelopes, HTTP status code mapping, and client retry guidelines.
- @[Agent Guidelines](../AGENTS.md)
  - Service operating constraints and package layout.
