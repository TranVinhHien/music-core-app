---
trigger: model_decision
description: "Guidelines, domain boundaries, data models, and implementation standards for the music-user-service."
---

# Agent Guidelines - Music User Service

## 1. Service Responsibility

### What it does (Core Responsibilities)
- **Identity & Authentication**: Manages user registration, credential verification, login, logout, and token refresh.
- **Token Generation**: Issues signed HMAC-SHA256 JWT `AccessToken` (short-lived) containing user ID, email, and user roles, as well as `RefreshToken` (long-lived).
- **User Profile Management**: Retrieval and updating of user account details, display names, and profile avatars.
- **Media Asset Upload for Users**: Handles avatar uploads integrated with AWS S3 / MinIO (`uploadHandler`, `uploadService`).
- **Role-Based Access Control (RBAC)**: Persists user roles (`admin`, `user`, `artist`, etc.) and assigns permissions.

### What it does NOT do (Out of Scope)
- **No Music Catalog Management**: Does not manage songs, albums, or artist diskographies (delegated to `music-catalog-service`).
- **No Personal Library/Playlists**: Does not store playlists, liked tracks, or listening history (delegated to `music-library-service`).
- **No Audio Streaming or Transcoding**: Does not handle media streaming or HLS encoding (delegated to `music-audio-service`).
- **No Ingress Routing**: Does not handle external traffic routing or global CORS/rate-limiting (handled by `music-api-gateway`).

---

## 2. Required Context

Before making modifications in `music-user-service`, review:
- @[Global Architecture](../docs/architecture.md): System boundaries and auth token propagation across the cluster.
- @[Service Communication](../docs/service-communication.md): Inbound HTTP endpoints called via API Gateway.
- @[User Service Architecture](docs/architecture.md): Internal data model, table schema, and endpoint definitions.
- @music-user-service/app.example.yaml: Configuration schema for HTTP port, JWT secrets, CockroachDB/PostgreSQL credentials, and AWS S3 settings.

---

## 3. Code Structure & Request Lifecycle

### Package Layout
```
music-user-service/
├── cmd/
│   └── server/
│       └── main.go       # Dependency injection, database initialization, server start
├── internal/
│   ├── config/           # YAML config loader (server, token, DB, AWS)
│   ├── database/         # CockroachDB / PostgreSQL connection setup with GORM
│   ├── handlers/         # HTTP controllers & input binding
│   │   ├── dto/          # Request and response Data Transfer Objects
│   │   ├── auth.go       # Handlers for login, register, refresh, logout, getMe
│   │   └── upload.go     # Handlers for avatar/file upload
│   ├── integration/      # AWS S3 / MinIO client implementation
│   ├── middleware/       # Internal auth middleware for protected endpoints
│   ├── models/           # GORM database entities (User, Role, etc.)
│   ├── repository/       # Data access layer (UserRepository database queries)
│   ├── router/           # Gin router configuration, Swagger, static files
│   └── services/         # Core business logic (AuthService, UploadService)
└── app.example.yaml      # Configuration blueprint
```

### Request Flow
1. **Incoming Request**: Arrives from `music-api-gateway` (or direct in dev mode) into `router.SetupRouter`.
2. **Handler Layer (`internal/handlers`)**:
   - Binds and validates request body using Gin's `ShouldBindJSON` with `dto` structs.
   - Extracts authenticated identity from `X-User-ID` header (or local `middleware.AuthMiddleware`).
3. **Service Layer (`internal/services`)**:
   - Executes domain rules (e.g., verifying password hashes via `bcrypt`, generating JWT tokens).
4. **Repository Layer (`internal/repository`)**:
   - Executes GORM queries against CockroachDB/PostgreSQL.
5. **Response Serialization**:
   - Returns standard JSON response with HTTP status code and message.

---

## 4. Dependencies & Boundaries

- **Database**: Dedicated database instance (CockroachDB / PostgreSQL) managed via GORM. Never share database connections with other services.
- **Object Storage**: AWS S3 or MinIO bucket for storing avatar images.
- **Upstream Gateway**: Sits behind `music-api-gateway`. Consumes forwarded headers (`X-User-ID`, `X-User-Roles`, `X-Request-ID`).
- **Shared Module (`music-common`)**:
  - Leverages shared constants, response envelopes, error handling, and validation helpers.

---

## 5. Implementation Rules

1. **Password Security**:
   - Passwords must always be hashed with `bcrypt.GenerateFromPassword` (cost factor >= 10).
   - Never log passwords, store plain text credentials, or return password hashes in JSON responses.
2. **Token Integrity**:
   - Ensure `claims.UserRoles` is always embedded in the JWT payload so `music-api-gateway` can perform stateless authorization.
3. **Data Isolation**:
   - All database models (`internal/models`) must reside strictly within this service. Do not import models from or export models to other services.
4. **Strict DTO Validation**:
   - Every input payload must be bound to a well-typed struct in `internal/handlers/dto` with explicit validation tags (e.g., `binding:"required,email"`).

---

## 6. Testing & Documentation

### Testing Requirements
Run unit and integration tests from the user service directory:
```bash
go test -v -race ./...
```
Key test suites:
- `internal/services/auth_service_test.go`: Validates registration, duplicate user rejection, password hashing, and token issuance.
- `internal/services/upload_service_test.go`: Validates avatar upload and S3 integration mock.

### Documentation Requirements
Update documentation whenever making functional changes:
- If adding or updating endpoints: update @music-user-service/docs/architecture.md and Swagger annotations.
- If altering the database schema: update the data model diagram in @music-user-service/docs/architecture.md.
