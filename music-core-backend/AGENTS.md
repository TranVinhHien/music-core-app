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
  - `music-user-service`: User authentication (register, login, refresh, logout), profile management, and AWS S3 avatar upload.
  - `music-common`: Shared response envelopes, header constants, pagination models, and utilities.
- **Roadmap / Skeleton Services (Unimplemented)**:
  - `music-catalog-service`, `music-audio-service`, `music-library-service`, `music-listening-event-service`.
  - *Strict Rule*: Do not hallucinate or assume database tables, business logic, or RPC endpoints for these unimplemented services.

---

## 2. Coding Guidelines & Standards

### Architecture & Layering Pattern
Every microservice adheres to Clean / Layered Architecture:
- `cmd/server/main.go`: Application bootstrap, configuration loading, dependency injection, and server lifecycle.
- `internal/handler/`: Transport layer (HTTP REST controllers). Handles request binding, DTO validation, and response serialization.
- `internal/service/`: Pure business logic domain. Completely decoupled from transport mechanisms.
- `internal/repository/`: Data persistence layer (PostgreSQL/CockroachDB with GORM, Redis, etc.).
- `internal/models/`: Domain entities and GORM database schemas.

### Core Implementation Rules
- **100% English**: All source code, identifiers, database schema definitions, log messages, error messages, and comments must be strictly in English.
- **Service Isolation**: Services must never import internal packages from one another. Shared models and utilities must reside strictly within `music-common`.
- **Database Boundary (Database-per-service)**: Cross-service database queries or shared connections are strictly prohibited. Inter-service queries must use HTTP endpoints.
- **Unified Response Envelope**: Every HTTP API response must adopt the shared envelope format from `music-common/response` (`code`, `message`, `data`, `meta`).
- **Error Handling**: Wrap errors with contextual detail (`fmt.Errorf("...: %w", err)`). Never expose raw SQL traces to clients.
- **Verification**: Always run `go test ./...` in the modified service module before concluding changes.

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
| **Working on Shared Code** | Read @music-common/AGENTS.md then consult index @[Common Docs](music-common/docs/README.md) |
| **Implementing a new Roadmap Service** | Read that service's local `AGENTS.md` (e.g. @music-catalog-service/AGENTS.md) |

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
- **`music-common`**:
  - Index & Packages: @[Common Index](music-common/docs/README.md)
