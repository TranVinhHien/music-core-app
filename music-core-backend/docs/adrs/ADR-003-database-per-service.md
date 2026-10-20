# ADR-003: Database-Per-Service Pattern and Strict Schema Isolation

## Status
Accepted

## Context
Sharing a single monolithic database among microservices creates tight schema coupling, risk of data corruption, and prevents services from scaling or choosing optimal storage engines independently.

## Decision
Enforce the **Database-per-service** architectural pattern:
1. Each microservice manages its own dedicated database connection and schema.
2. In the current implementation, `music-user-service` connects to its own CockroachDB/PostgreSQL instance (`music-core-db`), owning the `user_credentials`, `user_roles`, `user_profiles`, and `refresh_tokens` tables.
3. No service may query another service's tables directly. All inter-service data access must be requested via HTTP/gRPC APIs.

## Consequences
- **Positive**: Strict bounded contexts, independent schema migrations, and zero risk of cross-service database locks.
- **Negative**: Distributed transactions require eventual consistency or Saga patterns; joining data across domains requires API aggregation at Gateway or client layers.
