# Music Core API

The Music Core API is the backend foundation for the Personal Music App. It provides authentication, profile management, secure sessions, and media upload capabilities. It is designed to grow into the backend for the app's offline library, personalization, recommendation, intelligent playback, and AI Talk features.

## Current scope

Implemented today:

- User registration, login, logout, and refresh-token revocation
- JWT access and refresh tokens
- Current-user profile retrieval and updates
- Password changes
- Image upload service boundary
- PostgreSQL or CockroachDB-compatible persistence through GORM
- Goose database migrations
- Consistent DTO-based service boundaries and API responses

The music library, playlists, download orchestration, recommendations, Auto DJ, audio analysis, and AI Talk capabilities are product targets described in the repository-level README. They are not completed API endpoints unless listed above.

## Technology and structure

- Go 1.26, Gin, GORM, Goose, JWT, Viper, and Docker Compose

```text
music-core-api/
├── cmd/server/               # Application entry point
├── internal/config/          # Environment and YAML configuration
├── internal/database/        # Database connection and migrations
├── internal/handlers/        # HTTP handlers and response envelope
│   └── dto/                  # Request and response DTOs
├── internal/middleware/      # Authentication middleware
├── internal/models/          # GORM persistence models
├── internal/repository/      # Database access
├── internal/services/        # Business logic; DTO in and DTO out
├── internal/router/          # Route registration
├── docs/                     # Swagger and service contracts
└── public/                   # Development HTML pages
```

Request flow: `HTTP request → Handler → Service → Repository → Database`. Persistence models must not be returned directly from services or handlers. See [`docs/service-dto-contract.md`](docs/service-dto-contract.md).

## API response format

Every response uses:

```json
{
  "code": "200",
  "message": "user retrieved",
  "meta": null,
  "data": {}
}
```

Create, update, and get-one operations return a resource DTO. List operations use `BaseListDto` (`limit`, `page`, `total`, and `list`). Delete and command-only operations return `data: null`.

## Main endpoints

| Method | Endpoint | Purpose | Auth |
| --- | --- | --- | --- |
| POST | `/api/v1/auth/register` | Create a user | No |
| POST | `/api/v1/auth/login` | Sign in and issue tokens | No |
| POST | `/api/v1/auth/refresh` | Refresh an access token | No |
| POST | `/api/v1/auth/logout` | Revoke a refresh token | No |
| GET | `/api/v1/auth/me` | Read the current user | Bearer |
| PUT | `/api/v1/auth/me` | Update the current profile | Bearer |
| PUT | `/api/v1/auth/me/password` | Change the password | Bearer |
| POST | `/api/v1/upload` | Upload an image | Bearer |
| GET | `/health` | Health check | No |
| GET | `/swagger/index.html` | Swagger UI | No |

## Configuration and local development

Create `app.development.yaml` from [`app.development.yaml.example`](app.development.yaml.example), set database, token, HTTP, and storage values, and never commit real secrets.

```bash
cd music-core-api
go mod download
go test ./...
go run ./cmd/server
```

Start local PostgreSQL with `docker compose up -d postgres`. The server defaults to port `8080`.

## Conventions

- Keep business logic in `internal/services`.
- Keep database access in `internal/repository`; handlers must not bypass it.
- Use DTOs at service boundaries and never expose GORM models through HTTP.
- Use the shared response envelope for every API response.
- Wrap errors with context and never expose credentials or password hashes.

## Related documentation

- [Project overview and product roadmap](../README.md)
- [Service DTO and response contract](docs/service-dto-contract.md)
- [Swagger specification](docs/swagger.yaml)
