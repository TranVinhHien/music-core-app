# Coding Conventions & Engineering Guidelines

---

## 1. Go Version & Multi-Module Workspace

- **Go Version**: `go 1.26.0` (compatible with modern Go features including generics and multi-module workspaces).
- **Workspace Configuration (`go.work`)**:
  All local microservice directories and shared modules are orchestrated under the root `go.work` file:
  ```go
  go 1.26.0

  use (
      ./music-api-gateway
      ./music-common
      ./music-user-service
  )
  ```
- **Adding a New Module to Workspace**:
  Whenever creating a new service (e.g., `music-catalog-service`), initialize it with `go mod init <module-path>` and add its path into `go.work`:
  ```bash
  go work use ./music-catalog-service
  go work sync
  ```
- **Cross-Service Imports**:
  Services must **never** import internal packages from other services. All shared domain contracts, utilities, and middleware must reside exclusively in `music-common`.

---

## 2. Naming & Language Conventions

- **100% English Standard**:
  All source code, identifiers, struct tags, comments, commit messages, and documentation must be written in English.
- **Go Naming Idioms**:
  - Packages: Short, concise, lowercase single words (e.g., `handlers`, `router`, `repository`, `dto`). No underscores or mixedCaps.
  - Structs & Interfaces: `PascalCase` (e.g., `AuthHandler`, `UserRepository`, `ReverseProxyHandler`).
  - Variables & Functions:
    - Exported: `PascalCase` (e.g., `NewServer`, `SetupRouter`).
    - Unexported: `camelCase` (e.g., `corsMiddleware`, `authMiddleware`).
  - Constants: `PascalCase` (e.g., `HeaderUserID`, `RoleAdmin`).
- **Database & Serialization**:
  - Database tables & columns: `snake_case` (e.g., `users`, `password_hash`, `created_at`).
  - JSON struct tags: `snake_case` (e.g., `json:"user_id"`, `json:"email"`).

---

## 3. Configuration & Secrets Management

- **Blueprint vs Secrets**:
  - Always commit non-sensitive config blueprints with example placeholders: `app.example.yaml` or `gateway.example.yaml`.
  - Concrete local environment configs (e.g., `app.development.yaml`, `gateway.development.yaml`) containing private keys, DB passwords, or tokens are ignored in `.gitignore`.
- **Environment Variable Overrides**:
  Configuration structures must support environment overrides using `UPPER_SNAKE_CASE` (e.g., `DATABASE_PASSWORD`, `TOKEN_SECRET`).
- **Secret Safety**:
  Never hardcode API keys, JWT signing secrets, or database connection strings in source code.

---

## 4. Error Handling & Structured Logging

### Error Handling Rules
- Always wrap errors with context using `%w` so errors can be inspected with `errors.Is` and `errors.As`:
  ```go
  if err := repo.Create(ctx, user); err != nil {
      return fmt.Errorf("failed to create user in repository: %w", err)
  }
  ```
- Do not swallow errors. If an error is caught and not returned, log it with full context.
- Never expose internal database errors or SQL query statements to clients in HTTP responses.

### Structured Logging with Zerolog
- Use `github.com/rs/zerolog` for all runtime logging.
- Always attach contextual identifiers such as `request_id`, `user_id`, or `path`:
  ```go
  logger.Info().
      Str("request_id", requestID).
      Str("user_id", userID.String()).
      Str("path", c.Request.URL.Path).
      Msg("User authenticated successfully")
  ```
- Use appropriate log levels:
  - `Debug`: High-frequency development debugging details.
  - `Info`: Key state changes, server startups, route registrations.
  - `Warn`: Non-critical operational warnings (token expired, permission denied).
  - `Error`: Operational failures, database disconnects, upstream outages.

---

## 5. Standardized API Response Envelopes

All HTTP handlers must return responses matching the standard envelope defined in `music-common/response`:

### Success Response Envelope
```json
{
  "code": "200",
  "message": "ok",
  "meta": null,
  "data": {
    "user_id": "a95c723f-e18e-4903-8d9e-c8524d62b9a7",
    "email": "user@example.com",
    "roles": ["user"]
  }
}
```

### Paginated Collection Response Envelope
```json
{
  "code": "200",
  "message": "ok",
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "total_pages": 8
  },
  "data": [
    { "id": "...", "title": "Track 1" },
    { "id": "...", "title": "Track 2" }
  ]
}
```

### Error Response Envelope
```json
{
  "code": "40001",
  "message": "Invalid email address format",
  "meta": null,
  "data": null
}
```

### Common Response Helpers (`music-common/response`)
Use the built-in helper functions from `music-common/response` rather than constructing manual maps:
- `response.Success(c, data)`: Sends `200 OK` with default message `"ok"`.
- `response.OK(c, message, data)`: Sends `200 OK` with custom message.
- `response.Created(c, message, data)`: Sends `201 Created`.
- `response.Paginated(c, list, meta)`: Sends `200 OK` with pagination metadata.
- `response.BadRequest(c, code, message)`: Sends `400 Bad Request`.
- `response.Unauthorized(c, message)`: Sends `401 Unauthorized`.
- `response.Forbidden(c, message)`: Sends `403 Forbidden`.
- `response.NotFound(c, message)`: Sends `404 Not Found`.
- `response.InternalServerError(c, message)`: Sends `500 Internal Server Error`.

---

## 6. Testing, Linting & Build Workflow

### Testing Standards
- Test files must be colocated with the code under test (suffix `_test.go`).
- Always run tests with the race detector enabled:
  ```bash
  go test -v -race ./...
  ```
- Before concluding features, verify test suites across all modules:
  ```bash
  make test-all
  ```

### Standard Makefile Targets
The repository root `Makefile` provides the standard interface for development and CI/CD:
- `make run-gateway`: Starts the API Gateway locally.
- `make run-user`: Starts the User Service locally.
- `make test-gateway`: Runs tests in `music-api-gateway`.
- `make test-user`: Runs tests in `music-user-service`.
- `make test-common`: Runs tests in `music-common`.
- `make test-all`: Runs all tests across the repository.
- `make build-gateway`: Compiles the gateway binary into `music-api-gateway/bin/gateway`.
- `make build-user`: Compiles the user service binary into `music-user-service/bin/server`.
