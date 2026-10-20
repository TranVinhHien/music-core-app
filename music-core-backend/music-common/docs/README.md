# Music Common Library - Documentation & Package Index

This directory documents the reusable shared packages provided by **`music-common`**:

---

## 1. Package: `constants`
Location: `music-common/constants/headers.go`
Defines canonical HTTP header strings and Gin context keys across the entire backend:
- `HeaderRequestID`: `"X-Request-ID"`
- `HeaderUserID`: `"X-User-ID"`
- `HeaderUserEmail`: `"X-User-Email"`
- `HeaderUserRoles`: `"X-User-Roles"`
- `HeaderAuthorization`: `"Authorization"`
- `RoleAdmin`: `"admin"`
- `RoleUser`: `"user"`

---

## 2. Package: `response`
Location: `music-common/response/response.go`
Provides standardized JSON envelopes and status senders:
```go
type Response[T any] struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Meta    any    `json:"meta,omitempty"`
    Data    T      `json:"data"`
}
```
Available helpers:
- `Success(c, data)`: `200 OK` with default message `"ok"`.
- `OK(c, message, data)`: `200 OK` with custom message.
- `Created(c, message, data)`: `201 Created`.
- `Paginated[T](c, list, meta)`: `200 OK` for lists with pagination metadata.
- `Send(c, status, code, message, meta, data)`: Custom status and envelope.

---

## 3. Package: `pagination`
Location: `music-common/pagination/`
Contains `PaginationMeta` (`page`, `limit`, `total`, `total_pages`) and helper functions to calculate offset/limit from query params.

---

## 4. Package: `httpclient`
Location: `music-common/httpclient/`
Provides a reusable HTTP client wrapper pre-configured with connection timeouts and header propagation for inter-service communication.
