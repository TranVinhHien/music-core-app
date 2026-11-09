# Internal Architecture - Music API Gateway

> **Update Notice**: Update this file when changing routing mechanisms (proxy), middleware pipelines, or API Gateway configuration structures.

---

## 1. Directory Structure
```
music-api-gateway/
├── cmd/                # Gateway bootstrap and entry point
├── config/             # Parse and load gateway.*.yaml
├── middlewares/        # Auth, CORS, Logger, Rate-limit, Recovery
├── permissions/        # RBAC logic and route permission matching
├── permissions.json    # Detailed permission matrix per endpoint
├── proxy.go            # Reverse Proxy handler
├── server.go           # HTTP router and middleware chain initialization
└── gateway.example.yaml# Sample configuration for downstream routes and server port
```

---

## 2. Request Flow
1. **Client Request** ➔ Received by `server.go` via HTTP port.
2. **Global Middlewares**:
   - `RequestIDMiddleware`: Generates and attaches `X-Request-Id`.
   - `CORSMiddleware`: Handles CORS headers and preflight checks.
   - `LoggerMiddleware`: Logs request details and latency.
3. **Authentication & Authorization**:
   - `AuthMiddleware`: Validates JWT Bearer Token, extracts `user_id` and `user_roles`.
   - `PermissionMiddleware`: Evaluates request path and HTTP method against `permissions.json`.
4. **Proxy Forwarding (`proxy.go`)**:
   - Injects downstream headers: `X-User-ID`, `X-User-Roles`, `X-Request-ID`.
   - Forwards request to downstream services (User, Catalog, Library, Audio, etc.).
5. **Response Handler**:
   - Relays response from downstream service back to client.

---

## 3. Routes & Downstream Services Configuration (Summary)
- Configured in `gateway.*.yaml`.
- Mapping rules:
  - `/api/v1/users/**` ➔ `music-user-service`
  - `/api/v1/auth/**` ➔ `music-user-service`
  - `/api/v1/catalog/**` ➔ `music-catalog-service`
  - `/api/v1/library/**` ➔ `music-library-service`
  - `/api/v1/audio/**` ➔ `music-audio-service`
