# Service DTO Contract

## Boundary rule

`internal/services` contains the system business logic. Every public business
operation in this package must accept DTO input and return DTO output. Services
must never return a GORM model to a handler or another transport layer.

Repositories are the only layer that reads and writes persistence models.
Services map repository models to response DTOs before returning them.

## Response rule

Every HTTP response must use `dto.Response`:

```go
type Response struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Meta    interface{} `json:"meta"`
	Data    interface{} `json:"data"`
}
```

- Create, update, and get-one operations set `Data` to that resource's response DTO.
- List operations set `Data` to `dto.BaseListDto`.
- Delete and other command-only operations set `Data` to `nil`; failures are
  represented by a non-2xx HTTP status and the same response envelope.

```go
type BaseListDto struct {
	Limit int   `json:"limit"`
	Page  int   `json:"page"`
	Total int64 `json:"total"`
	List  any   `json:"list"`
}
```

Handlers only bind transport requests, call services with DTOs, and write the
response envelope. They must not expose or mutate persistence models.
