# Music Common Go Library (`music-common`)

Thư viện dùng chung (Shared Common Module) cho toàn bộ hệ thống microservices backend (`music-core-backend`).

## Module Path
```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common"
```

---

## 1. DTO & Chuẩn Hóa Phản Hồi API (`response`)

Mọi API trong hệ sinh thái trả về envelope chuẩn:
```json
{
  "code": "200",
  "message": "ok",
  "meta": null,
  "data": { ... }
}
```

### Sử dụng trong Gin Handler:
```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/response"

// 1. Phản hồi thành công (200 OK)
response.Success(c, userProfile)
response.OK(c, "Cập nhật thành công", userProfile)

// 2. Phản hồi tạo mới (201 Created)
response.Created(c, "Tạo playlist thành công", newPlaylist)

// 3. Phản hồi danh sách phân trang
response.Paginated(c, items, meta)

// 4. Phản hồi lỗi chuẩn
response.BadRequest(c, errors.New("Email không hợp lệ"))
response.Unauthorized(c, "Token hết hạn")
response.Forbidden(c, "Bạn không có quyền truy cập")
response.NotFound(c, "Không tìm thấy bài hát")
response.InternalServerError(c, err)
```

---

## 2. Phân Trang Chuẩn (`pagination`)

Hỗ trợ chuẩn hóa request query và metadata trả về:

```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/pagination"

func ListSongs(c *gin.Context) {
    var query pagination.PaginationQuery
    if err := c.ShouldBindQuery(&query); err != nil {
        response.BadRequest(c, err)
        return
    }

    // Tự động validate & tính offset/limit an toàn
    offset := query.GetOffset()
    limit := query.GetLimit()
    order := query.GetOrder() // "ASC" hoặc "DESC"

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

## 3. Middlewares Dùng Chung (`middleware`)

### Đăng ký Middleware trong Router:
```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/middleware"

r := gin.New()
r.Use(middleware.RequestID())            // Tự động sinh hoặc chuyển tiếp X-Request-ID
r.Use(middleware.UserContextMiddleware()) // Trích xuất X-User-ID, X-User-Email, X-User-Roles từ Gateway
r.Use(middleware.CORS())                 // CORS chuẩn
r.Use(middleware.Logger(logger))         // Zerolog HTTP Logger
```

### Trích xuất thông tin người dùng trong bất kỳ Handler nào:
```go
func GetProfile(c *gin.Context) {
    // Lấy UserID dạng uuid.UUID an toàn
    userID, ok := middleware.GetUserID(c)
    if !ok {
        response.Unauthorized(c)
        return
    }

    // Lấy Email
    email := middleware.GetUserEmail(c)

    // Lấy Roles
    roles := middleware.GetUserRoles(c) // []string{"user", "creator"}

    // Kiểm tra quyền
    if middleware.HasRole(c, "creator") {
        // ...
    }
}
```

### Bảo vệ Route theo Role:
```go
// Yêu cầu bắt buộc đăng nhập (có user_id)
api.Use(middleware.RequireAuth())

// Yêu cầu quyền admin
adminGroup := api.Group("/admin")
adminGroup.Use(middleware.RequireRole("admin"))
```

---

## 4. Gọi Request External & Gọi Giữa Các Microservices (`httpclient`)

Package `httpclient` cung cấp HTTP client production-ready:
- Tự động parse / serialize JSON.
- Tự động retry khi gặp lỗi mạng hoặc mã 502, 503, 504 (kèm exponential backoff).
- Context timeout support.
- **Tự động chuyển tiếp (propagate) headers từ Gin context** (`X-Request-ID`, `X-User-ID`, `X-User-Email`, `X-User-Roles`, `Authorization`) sang service tiếp theo!

### Khởi tạo Client:
```go
import "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/httpclient"

client := httpclient.NewClient(
    httpclient.WithBaseURL("http://music-audio-service:3005"),
    httpclient.WithTimeout(10 * time.Second),
    httpclient.WithRetries(3),
    httpclient.WithLogger(logger),
)
```

### Gọi External API từ trong một Gin Handler (chuyển tiếp context người dùng):
```go
func StreamTrack(c *gin.Context) {
    trackID := c.Param("id")

    // FromGinContext tự động gắn X-Request-ID và X-User-ID của request hiện tại sang request mới
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

### Các hàm gọi đơn giản:
```go
// GET
err := client.Get(ctx, "/path", &resultDTO)

// POST với JSON Body
err := client.Post(ctx, "/path", requestPayload, &resultDTO)

// PUT
err := client.Put(ctx, "/path", requestPayload, &resultDTO)

// DELETE
err := client.Delete(ctx, "/path", &resultDTO)
```
