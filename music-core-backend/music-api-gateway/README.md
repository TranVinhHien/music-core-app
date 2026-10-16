# Music API Gateway

Service API Gateway đóng vai trò là single entry point cho các client (Flutter mobile app, Web frontend, v.v.) kết nối đến hệ thống backend microservices của Personal Music App.

## 1. Trách nhiệm chính

- **Reverse Proxy & Routing:** Tiếp nhận request từ client và định tuyến đến các microservices tương ứng (`music-user-service`, `music-catalog-service`, `music-library-service`, `music-listening-event-service`, `music-audio-service`).
- **Xác thực Token tập trung & Stateless:**
  - Token JWT chứa `user_id`, `email`, và mảng `user_roles` (ví dụ: `["user"]` hoặc `["admin"]`).
  - API Gateway giải mã và kiểm tra tính hợp lệ của token mà **không cần gọi DB hay gọi sang user-service** trên từng request.
- **Phân quyền trên từng API (Role-Based Access Control):**
  - Gateway lấy mảng `user_roles` từ JWT token và đối chiếu với file ma trận quyền [config/permissions.json](config/permissions.json).
  - Hỗ trợ các pattern: wildcard `*`, prefix `/*`, và path param `:param`.
  - Trả về `401 Unauthorized` nếu token thiếu/không hợp lệ, hoặc `403 Forbidden` nếu role không có quyền truy cập API.
- **Context Header Injection:** Tự động inject và forward các header xuống service phía sau:
  - `X-User-ID`: UUID định danh người dùng.
  - `X-User-Email`: Email của người dùng.
  - `X-User-Roles`: Danh sách role phân tách bằng dấu phẩy (vd: `user,admin`).
  - `X-Request-ID`: Mã định danh request duy nhất.
- **Structured Logging & CORS:** Ghi log chi tiết và xử lý CORS tập trung.

## 2. Cấu trúc thư mục

```text
music-api-gateway/
├── cmd/
│   └── main.go                  # Entry point chạy standalone gateway
├── config/
│   ├── config.go                # Struct và loader cấu hình (Viper)
│   ├── gateway.development.yaml # Cấu hình routes và server
│   └── permissions.json         # Ma trận phân quyền theo từng role và method/path
├── middlewares/
│   ├── auth.go                  # Xác thực JWT stateless & phân quyền API
│   ├── logger.go                # Structured logging middleware (zerolog)
│   └── request_id.go            # Request ID header tracking
├── permissions/
│   └── evaluator.go             # Engine kiểm tra quyền theo role & pattern (*, /*, :param)
├── proxy.go                     # Reverse proxy handler (httputil.ReverseProxy)
├── server.go                    # Gin engine server, routing, health check, CORS
└── README.md
```

## 3. Ma trận phân quyền (permissions.json)

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

## 4. Cách chạy Gateway

Từ thư mục `music-api-gateway`:

```bash
# Tải dependencies nếu cần
go mod tidy

# Chạy standalone gateway
go run ./cmd/main.go -config=./config/gateway.development.yaml
```

Kiểm tra health check:
```bash
curl http://localhost:8000/health
```