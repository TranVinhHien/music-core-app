# Music API Gateway

The API Gateway service acts as the single entry point for clients (Flutter mobile app, Web frontend, etc.) connecting to the backend microservices ecosystem of the Personal Music App.

## 1. Primary Responsibilities

- **Reverse Proxy & Routing:** Receives incoming client requests and routes them to the appropriate downstream microservices (`music-user-service`, `music-catalog-service`, `music-library-service`, `music-listening-event-service`, `music-audio-service`).
- **Centralized & Stateless Token Authentication:**
  - JWT tokens encode `user_id`, `email`, and a `user_roles` array (e.g., `["user"]` or `["admin"]`).
  - The API Gateway validates and decodes the token **statelessly without querying a database or calling the user-service** on every request.
- **Role-Based Access Control (RBAC):**
  - Gateway inspects `user_roles` from the JWT claims against the permission matrix defined in [config/permissions.json](config/permissions.json).
  - Supports route patterns: wildcard `*`, prefix `/*`, and path parameter `:param`.
  - Rejects unauthorized requests with `401 Unauthorized` (missing/invalid token) or `403 Forbidden` (insufficient role privileges).
- **Context Header Injection:** Automatically injects and propagates standard headers to downstream services:
  - `X-User-ID`: User UUID identifier.
  - `X-User-Email`: User email address.
  - `X-User-Roles`: Comma-separated list of roles (e.g., `user,admin`).
  - `X-Request-ID`: Unique correlation request ID.
- **Structured Logging & CORS:** Centralized CORS policy enforcement and structured request logging.

## 2. Directory Structure

```text
music-api-gateway/
├── cmd/
│   └── main.go                  # Standalone gateway entry point
├── config/
│   ├── config.go                # Configuration structs and Viper loader
│   ├── gateway.development.yaml # Route and server configuration
│   └── permissions.json         # RBAC permission matrix by role, HTTP method, and path
├── middlewares/
│   ├── auth.go                  # Stateless JWT authentication & RBAC middleware
│   ├── logger.go                # Structured logging middleware (zerolog)
│   └── request_id.go            # Request ID correlation tracking
├── permissions/
│   └── evaluator.go             # Permission evaluation engine (*, /*, :param)
├── proxy.go                     # Reverse proxy handler (httputil.ReverseProxy)
├── server.go                    # Gin engine initialization, routing, health check, CORS
└── README.md
```

## 3. Permission Matrix (permissions.json)

```json
{
  "roles": [
    {
      "role": "admin",
      "permissions": {
        "GET": ["*"],
        "POST": ["*"],
        "PUT": ["*"],
        "DELETE": ["*"],
        "PATCH": ["*"]
      }
    },
    {
      "role": "user",
      "permissions": {
        "GET": [
          "/health",
          "/swagger/*",
          "/api/v1/auth/me",
          "/api/v1/users/me",
          "/api/v1/catalog/*",
          "/api/v1/library/*",
          "/api/v1/audio/*"
        ],
        "POST": [
          "/api/v1/auth/logout",
          "/api/v1/library/*",
          "/api/v1/listening-events/*",
          "/api/v1/upload"
        ],
        "PUT": [
          "/api/v1/auth/me",
          "/api/v1/auth/me/password",
          "/api/v1/users/me",
          "/api/v1/library/*"
        ],
        "DELETE": [
          "/api/v1/library/*"
        ]
      }
    }
  ]
}
```

## 4. Running the Gateway

From the `music-api-gateway` directory:

```bash
# Download dependencies if needed
go mod tidy

# Run standalone gateway
go run ./cmd/main.go -config=./config/gateway.development.yaml
```

Check health status:
```bash
curl http://localhost:8000/health
```
