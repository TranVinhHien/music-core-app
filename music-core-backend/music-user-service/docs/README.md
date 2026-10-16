# Music User Service - Context & Documentation Index

This directory contains modular documentation for **`music-user-service`**. To avoid overloading context, consult the document tailored to your specific task:

| Document | When to Read / Purpose |
|---|---|
| [architecture.md](file:///Users/hienlazada/music-core-app/music-core-backend/music-user-service/docs/architecture.md) | High-level internal component layout, dependency injection in `main.go`, and layer separation (`handlers` ➔ `services` ➔ `repository`). |
| [data-model.md](file:///Users/hienlazada/music-core-app/music-core-backend/music-user-service/docs/data-model.md) | GORM database entities, table schemas (`user_credentials`, `user_roles`, `user_profiles`, `refresh_tokens`), constraints, and relationships. |
| [api-contracts.md](file:///Users/hienlazada/music-core-app/music-core-backend/music-user-service/docs/api-contracts.md) | Full specifications for HTTP endpoints (`/auth/login`, `/auth/register`, `/users/me`, `/upload`, etc.), request/response DTO schemas, and status codes. |
| [flows.md](file:///Users/hienlazada/music-core-app/music-core-backend/music-user-service/docs/flows.md) | Step-by-step logic flows: registration, authentication, token refresh, and S3 avatar media upload. |
| [../AGENTS.md](file:///Users/hienlazada/music-core-app/music-core-backend/music-user-service/AGENTS.md) | Service rules, constraints (bcrypt hashing, JWT claim requirements), testing commands, and implementation guidelines. |

---

## Service Status
- **Implementation Status**: Fully implemented with GORM, CockroachDB/PostgreSQL integration, and AWS S3 upload service.
- **Port**: Listens on `:8080`.
- **Primary Upstream**: Ingress traffic routed via `music-api-gateway`.
