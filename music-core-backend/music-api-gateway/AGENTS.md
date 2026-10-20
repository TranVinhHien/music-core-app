---
trigger: model_decision
description: "Guidelines, architecture boundaries, routing rules, and testing standards for the music-api-gateway service."
---

# Agent Guidelines - Music API Gateway

## 1. Service Responsibility

### What it does (Core Responsibilities)
- **Central Ingress & Reverse Proxy**: Acts as the single entry point for all external client traffic (Web, Mobile, Desktop), proxying requests to downstream microservices based on prefix routes configured in `gateway.*.yaml`.
- **Stateless Authentication**: Validates incoming JWT Bearer tokens using HMAC-SHA256 (`token.secret`) without connecting to any database.
- **RBAC Authorization**: Evaluates user roles (`claims.UserRoles`) against route permissions declared in `permissions.json` using `permissions.Evaluator`.
- **Context & Header Propagation**: Injects downstream headers (`X-User-ID`, `X-User-Email`, `X-User-Roles`, `X-Request-ID`, `X-Forwarded-Host`, `X-Forwarded-For`, `X-Forwarded-Proto`).
- **Cross-Cutting Concerns**: Manages CORS headers, structured request logging (`zerolog`), panic recovery, and health check endpoint (`GET /health`).

### What it does NOT do (Out of Scope)
- **No Database Persistence**: Must never connect directly to PostgreSQL, CockroachDB, MySQL, or Redis. The gateway is 100% stateless.
- **No User/Business Logic**: Does not handle user registration, credential verification, password hashing, or token issuance (delegated to `music-user-service`).
- **No Direct Media Processing**: Does not stream raw audio chunks or handle file uploads directly (proxies directly to `music-audio-service`).
- **No Message Broker Integration**: Does not publish or consume events from Kafka or RabbitMQ.

---

## 2. Required Context

Before making modifications in `music-api-gateway`, review:
- @[Global Architecture](../docs/architecture.md): Service boundaries and network placement.
- @[Service Communication](../docs/service-communication.md): Downstream routes and forwarded header specifications.
- @[Gateway Architecture](docs/architecture.md): Internal proxy mechanics, middleware chains, and route configurations.
- @music-api-gateway/gateway.example.yaml: Downstream route mapping schema (`prefix`, `target`, `auth_required`).
- @music-api-gateway/permissions.json: RBAC permission matrix for endpoints and HTTP methods.

---

## 3. Code Structure & Request Lifecycle

### Package Layout
```
music-api-gateway/
├── cmd/
│   └── main.go           # CLI bootstrap, parses config and launches gateway server
├── config/
│   └── config.go         # YAML loader for server, auth token secret, and route targets
├── middlewares/
│   ├── auth.go           # Stateless JWT validation, role extraction, header injection
│   ├── logger.go         # Zerolog HTTP request logging
│   ├── recovery.go       # Panic recovery returning standard JSON envelope
│   └── request_id.go     # Generates or propagates X-Request-ID (UUID v4)
├── permissions/
│   ├── evaluator.go      # Match URL patterns against permissions.json rules
│   └── permission.go     # Permission models and rule definitions
├── proxy.go              # ReverseProxyHandler wrapping httputil.NewSingleHostReverseProxy
├── server.go             # Gin engine setup, CORS, route registration, 404 handler
├── permissions.json      # Route authorization policy matrix
└── gateway.example.yaml  # Route forwarding configuration template
```

### Request Flow
1. **Client Request** ➔ Handled by Gin Engine in `server.go`.
2. **Global Middlewares**: `Recovery` ➔ `RequestID` ➔ `Logger` ➔ `CORS`.
3. **Route Match**:
   - If route has `auth_required: true`: Executes `middlewares.AuthMiddleware`.
     - Validates JWT token signature and expiration.
     - Evaluates role permissions via `permissions.Evaluator`.
     - Injects `X-User-ID`, `X-User-Email`, `X-User-Roles` into downstream request headers.
   - If route has `auth_required: false`: Skips auth check.
4. **Proxy Forwarding (`proxy.go`)**: `ReverseProxyHandler` forwards request to upstream target, preserving host and setting client IP headers.
5. **Error/Status**: Returns upstream response or `502 Bad Gateway` if upstream is unreachable.

---

## 4. Dependencies & Boundaries

- **Database**: NONE. No database drivers allowed.
- **Downstream Services**: Communicates over HTTP via reverse proxy to:
  - `music-user-service`: `/api/v1/auth/**`, `/api/v1/users/**`
  - `music-catalog-service`: `/api/v1/catalog/**`, `/api/v1/tracks/**`
  - `music-library-service`: `/api/v1/library/**`, `/api/v1/playlists/**`
  - `music-audio-service`: `/api/v1/audio/**`
- **Message Broker**: NONE.
- **Shared Module (`music-common`)**:
  - Uses `constants` for canonical header names (`HeaderUserID`, `HeaderUserRoles`, `HeaderAuthorization`).
  - Standard error codes and response envelopes.

---

## 5. Implementation Rules

1. **Keep Gateway Stateless**: Never add in-memory state or database connections. All user context must come from the JWT claims.
2. **Preserve Upstream Headers**: When proxying, always forward `X-Request-ID`, `X-User-ID`, `X-User-Email`, and `X-User-Roles`.
3. **Route & Permission Sync**: Whenever adding a new downstream route to `gateway.*.yaml`:
   - If protected, add corresponding permission definitions into `permissions.json`.
4. **Resilient Reverse Proxy**: Ensure `ErrorHandler` in `proxy.go` returns JSON formatted responses (`502 Bad Gateway`) matching the application standard envelope instead of plain text.

---

## 6. Testing & Documentation

### Testing Requirements
Run unit and integration tests from the gateway directory:
```bash
go test -v -race ./...
```
Specific test suites to run:
- `server_test.go`: Validates reverse proxy routing, CORS headers, and 404 responses.
- `middlewares/auth_test.go` (if present) / `permissions/evaluator_test.go`: Validates token verification and RBAC matrix.

### Documentation Requirements
Update documentation whenever making functional changes:
- If adding/updating routes or downstream targets: update @music-api-gateway/docs/architecture.md and @music-api-gateway/gateway.example.yaml.
- If modifying RBAC roles or endpoint permissions: update @music-api-gateway/permissions.json.
