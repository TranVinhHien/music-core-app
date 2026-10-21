---
trigger: always_on
description: "Master architecture guidelines, microservices catalog, Go coding standards, and documentation index for the Music Core Backend platform."
---

# Music Core Backend - Agent Operating Guidelines

## 1. Project Overview & Operational Reality

**Music Core App** is a Golang-based microservices music streaming backend organized as a Go Multi-Module Workspace (`go.work`).

### Implementation Reality
- **Implemented Services**:
  - `music-api-gateway`: Ingress reverse proxy, stateless JWT authentication, and RBAC policy evaluation (`permissions.json`).
  - `music-user-service`: User authentication (register, login, refresh, logout), profile management, and AWS S3 avatar upload (Go + GORM).
  - `music-catalog-service`: Catalog management for artists, albums, tracks, and genres (NestJS + Prisma). Port `3002`.
  - `music-library-service`: Personal playlists, favorite tracks, liked albums, and user library management (NestJS + Prisma). Port `3003`.
  - `music-listening-event-service`: High-throughput listening event ingestion (Go + Gin + MongoDB). Port `3004`.
  - `music-common`: Shared response envelopes, header constants, pagination models, and utilities.
- **Roadmap / Skeleton Services (Unimplemented)**:
  - `music-audio-service`.
  - *Strict Rule*: Do not hallucinate or assume database tables, business logic, or RPC endpoints for these unimplemented services.

---

## 2. Coding Guidelines & Standards

### Architecture & Layering Pattern
Every microservice adheres to Clean / Layered Architecture:
- `cmd/server/main.go` / `src/main.ts`: Application bootstrap, configuration loading, dependency injection, and server lifecycle.
- `internal/handler/` / `src/modules/*/controllers`: Transport layer (HTTP REST controllers). Handles request binding, DTO validation, and response serialization.
- `internal/service/` / `src/modules/*/services`: Pure business logic domain. Completely decoupled from transport mechanisms.
- `internal/repository/` / `src/modules/*/repositories`: Data persistence layer (PostgreSQL/CockroachDB with GORM or Prisma).
- `internal/models/` / `prisma/schema.prisma`: Domain entities and database schemas.

### Core Implementation Rules
- **100% English**: All source code, identifiers, database schema definitions, log messages, error messages, and comments must be strictly in English.
- **Service Isolation**: Services must never import internal packages from one another. Shared models and utilities must reside strictly within `music-common` (or aligned HTTP contracts).
- **Database Boundary (Database-per-service)**: Cross-service database queries or shared connections are strictly prohibited. Inter-service queries must use HTTP endpoints.
- **Unified Response Envelope**: Every HTTP API response must adopt the shared envelope format from `music-common/response` (`code`, `message`, `data`, `meta`).
- **Error Handling**: Wrap errors with contextual detail (`fmt.Errorf("...: %w", err)` or standard NestJS exception filters). Never expose raw SQL traces to clients.
- **Verification**: Always run tests and lint checks in the modified service module before concluding changes.

---

## 3. Documentation Routing Protocol (Progressive Disclosure)

To avoid loading unnecessary context into prompt memory, consult documents strictly according to your task:

### By Task Type
| Task / Inquiry | Document to Read |
|---|---|
| **System boundaries, high-level architecture** | @[Architecture Overview](docs/architecture.md) |
| **Inter-service routing, token forwarding, headers** | @[Service Communication](docs/service-communication.md) |
| **Code styles, naming, logging, responses, Go workspace** | @[Coding Conventions](docs/coding-conventions.md) |
| **Architectural decisions (Auth, Go Workspace, DB boundary)** | @[ADR Index](docs/adrs/README.md) |
| **Working on API Gateway** | Read @music-api-gateway/AGENTS.md then consult index @[Gateway Docs](music-api-gateway/docs/README.md) |
| **Working on User Service** | Read @music-user-service/AGENTS.md then consult index @[User Service Docs](music-user-service/docs/README.md) |
| **Working on Catalog Service** | Read @music-catalog-service/AGENTS.md then consult index @[Catalog Docs](music-catalog-service/docs/README.md) |
| **Working on Library Service** | Read @music-library-service/AGENTS.md then consult index @[Library Docs](music-library-service/docs/README.md) |
| **Working on Listening Event Service** | Read @music-listening-event-service/AGENTS.md then consult index @[Listening Event Docs](music-listening-event-service/docs/README.md) |
| **Working on Shared Code** | Read @music-common/AGENTS.md then consult index @[Common Docs](music-common/docs/README.md) |
| **Implementing a new Roadmap Service** | Read that service's local `AGENTS.md` (e.g. @music-audio-service/AGENTS.md) |

### Service Documentation Map
Each service maintains its own `docs/README.md` functioning as a focused index:
- **`music-api-gateway`**:
  - Index: @[Gateway Index](music-api-gateway/docs/README.md)
  - Architecture: @[Gateway Architecture](music-api-gateway/docs/architecture.md)
  - Contracts & Permissions: @[Gateway API Contracts](music-api-gateway/docs/api-contracts.md)
- **`music-user-service`**:
  - Index: @[User Service Index](music-user-service/docs/README.md)
  - Architecture: @[User Architecture](music-user-service/docs/architecture.md)
  - Data Model (GORM Schema): @[User Data Model](music-user-service/docs/data-model.md)
  - API Contracts: @[User API Contracts](music-user-service/docs/api-contracts.md)
  - Business Flows (Auth & S3 Upload): @[User Flows](music-user-service/docs/flows.md)
- **`music-catalog-service`**:
  - Guidelines: @music-catalog-service/AGENTS.md
  - Index: @[Catalog Index](music-catalog-service/docs/README.md)
  - Schema: `prisma/schema.prisma`
- **`music-library-service`**:
  - Guidelines: @music-library-service/AGENTS.md
  - Index: @[Library Index](music-library-service/docs/README.md)
  - Schema: `prisma/schema.prisma`
- **`music-listening-event-service`**:
  - Guidelines: @music-listening-event-service/AGENTS.md
  - Index: @[Listening Event Index](music-listening-event-service/docs/README.md)
  - Ingestion Architecture: @[Architecture & Idempotency](music-listening-event-service/docs/architecture.md)
  - Event Schemas: @[Event Schemas](music-listening-event-service/docs/event-schemas.md)
  - API Contracts: @[API Contracts](music-listening-event-service/docs/api-contracts.md)
- **`music-common`**:
  - Index & Packages: @[Common Index](music-common/docs/README.md)

---

## 4. Context Preservation & Definition of Done (DoD)

Whenever you complete any coding task involving:
- Schema updates (Prisma schemas, migrations, GORM entities).
- New, modified, or deprecated API endpoints / Gateway routing rules.
- Service bootstrap, refactoring, or new inter-service dependencies.

**Mandatory Action**:
You MUST execute the `sync-system-context` workflow before concluding the task:
1. Verify if documentation in `docs/` and `<service>/docs/` matches current code.
2. Update `<service>/AGENTS.md` if the service state, tools, or dependencies changed.
3. Keep documentation concise, formatted as tables or Mermaid diagrams to preserve token efficiency.
