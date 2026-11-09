# Music Common Go Library (`music-common`)

Shared Common Module for the backend microservices architecture (`music-core-backend`).

## Module Path
```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common"
```

---

## 1. DTO & Standard API Response Envelope (`response`)

All APIs across the ecosystem return a standardized response envelope:
```json
{
  "code": "200",
  "message": "ok",
  "meta": null,
  "data": { ... }
}
```

### Usage in Gin Handlers:
```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/response"

// 1. Successful response (200 OK)
response.Success(c, userProfile)
response.OK(c, "Updated successfully", userProfile)

// 2. Resource creation response (201 Created)
response.Created(c, "Playlist created successfully", newPlaylist)

// 3. Paginated list response
response.Paginated(c, items, meta)

// 4. Standard error responses
response.BadRequest(c, errors.New("Invalid email format"))
response.Unauthorized(c, "Token expired")
response.Forbidden(c, "Access denied")
response.NotFound(c, "Track not found")
response.InternalServerError(c, err)
```

---

## 2. Standard Pagination (`pagination`)

Standardizes query binding and pagination metadata formatting:

```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/pagination"

func ListSongs(c *gin.Context) {
    var query pagination.PaginationQuery
    if err := c.ShouldBindQuery(&query); err != nil {
        response.BadRequest(c, err)
        return
    }

    // Automatically validates and computes safe offset/limit
    offset := query.GetOffset()
    limit := query.GetLimit()
    order := query.GetOrder() // "ASC" or "DESC"

    songs, total, err := songRepo.Find(offset, limit, query.Sort, order)
    if err != nil {
        response.InternalServerError(c, err)
        return
    }

    meta := pagination.NewPaginationMeta(total, query.GetPage(), limit)
    response.Paginated(c, songs, meta)
}
```

---

## 3. Shared Middlewares (`middleware`)

### Middleware Registration in Router:
```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/middleware"

r := gin.New()
r.Use(middleware.RequestID())            // Generates or forwards X-Request-ID
r.Use(middleware.UserContextMiddleware()) // Extracts X-User-ID, X-User-Email, X-User-Roles from Gateway
r.Use(middleware.CORS())                 // Standard CORS policy
r.Use(middleware.Logger(logger))         // Zerolog HTTP Logger
```

### Extract User Context in Any Handler:
```go
func GetProfile(c *gin.Context) {
    // Safely extract typed uuid.UUID UserID
    userID, ok := middleware.GetUserID(c)
    if !ok {
        response.Unauthorized(c)
        return
    }

    // Extract Email
    email := middleware.GetUserEmail(c)

    // Extract Roles
    roles := middleware.GetUserRoles(c) // []string{"user", "creator"}

    // Evaluate permissions
    if middleware.HasRole(c, "creator") {
        // ...
    }
}
```

### Role-Based Route Protection:
```go
// Enforce authenticated requests (user_id present)
api.Use(middleware.RequireAuth())

// Require admin privileges
adminGroup := api.Group("/admin")
adminGroup.Use(middleware.RequireRole("admin"))
```

---

## 4. Inter-Service & External HTTP Client (`httpclient`)

The `httpclient` package provides a production-ready HTTP client:
- Automatic JSON serialization and deserialization.
- Automatic retries on network failures or 502, 503, 504 errors with exponential backoff.
- Context cancellation and timeout support.
- **Context propagation**: Automatically extracts and propagates headers from Gin context (`X-Request-ID`, `X-User-ID`, `X-User-Email`, `X-User-Roles`, `Authorization`) to downstream requests!

### Client Initialization:
```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/httpclient"

client := httpclient.NewClient(
    httpclient.WithBaseURL("http://music-audio-service:3005"),
    httpclient.WithTimeout(10 * time.Second),
    httpclient.WithRetries(3),
    httpclient.WithLogger(logger),
)
```

### Calling External APIs from a Gin Handler (with Context Propagation):
```go
func StreamTrack(c *gin.Context) {
    trackID := c.Param("id")

    // FromGinContext automatically binds X-Request-ID and X-User-ID of the current request to the outbound call
    scopedClient := client.FromGinContext(c)

    var trackMetadata TrackInfoDTO
    err := scopedClient.Get(c.Request.Context(), "/api/v1/audio/tracks/"+trackID, &trackMetadata)
    if err != nil {
        response.InternalServerError(c, err)
        return
    }

    response.Success(c, trackMetadata)
}
```

### Convenience HTTP Methods:
```go
// GET
err := client.Get(ctx, "/path", &resultDTO)

// POST with JSON body
err := client.Post(ctx, "/path", requestPayload, &resultDTO)

// PUT
err := client.Put(ctx, "/path", requestPayload, &resultDTO)

// DELETE
err := client.Delete(ctx, "/path", &resultDTO)
```
