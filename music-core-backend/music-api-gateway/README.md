# Music API Gateway

Service API Gateway đóng vai trò là single entry point cho các client (Flutter mobile app, Web frontend, v.v.) kết nối đến hệ thống backend microservices của Personal Music App.

## 1. Trách nhiệm chính

- **Reverse Proxy & Routing:** Tiếp nhận request từ client và định tuyến đến các microservices tương ứng (`music-user-service`, `music-catalog-service`, `music-library-service`, `music-listening-event-service`, `music-audio-service`, `music-core-api`).
- **Request ID Tracking:** Tự động sinh hoặc forward header `X-Request-ID` cho mọi request.
- **Structured Logging:** Ghi log chi tiết (IP, method, path, status, latency, request ID) bằng zerolog.
- **CORS Handling:** Cấu hình CORS tập trung tại Gateway.
- **Authentication & Authorization (Placeholder):** Chuẩn bị sẵn middleware xác thực ở tầng gateway. Hiện tại đang ở chế độ passthrough (chưa chặn request, cho phép các service downstream hoặc giai đoạn tiếp theo xử lý auth).
- **Error Handling:** Trả về chuẩn phản hồi JSON và xử lý `502 Bad Gateway` khi upstream service không khả dụng.

## 2. Cấu trúc thư mục

```text
music-api-gateway/
├── cmd/
│   └── main.go                  # Entry point chạy standalone gateway
├── config/
│   ├── config.go                # Struct và loader cấu hình (Viper)
│   └── gateway.development.yaml # Cấu hình mẫu cho môi trường development
├── middlewares/
│   ├── auth.go                  # Auth middleware (placeholder passthrough)
│   ├── logger.go                # Structured logging middleware (zerolog)
│   └── request_id.go            # Request ID header tracking
├── proxy.go                     # Reverse proxy handler (httputil.ReverseProxy)
├── server.go                    # Gin engine server, routing, health check, CORS
└── README.md
```

## 3. Cấu hình định tuyến (gateway.development.yaml)

```yaml
gateway:
  routes:
    # User Service (NestJS)
    - prefix: "/api/v1/users"
      target: "http://localhost:3001"
      auth_required: true

    - prefix: "/api/v1/auth"
      target: "http://localhost:3001"
      auth_required: false

    # Catalog Service (NestJS)
    - prefix: "/api/v1/catalog"
      target: "http://localhost:3002"
      auth_required: false

    # Library Service (NestJS)
    - prefix: "/api/v1/library"
      target: "http://localhost:3003"
      auth_required: true

    # Listening Event Service (Go)
    - prefix: "/api/v1/listening-events"
      target: "http://localhost:3004"
      auth_required: true

    # Audio Service (Go)
    - prefix: "/api/v1/audio"
      target: "http://localhost:3005"
      auth_required: true

    # Core API Monolith
    - prefix: "/api/v1/core"
      target: "http://localhost:8080"
      auth_required: false
```

## 4. Cách chạy Gateway

Từ thư mục `music-core-api`:

```bash
# Chạy trực tiếp qua Makefile
make run-gateway

# Hoặc chạy trực tiếp với go
go run ./cmd/gateway/main.go

# Hoặc chạy từ thư mục music-api-gateway
go run ./music-api-gateway/cmd/main.go -config=./music-api-gateway/config/gateway.development.yaml
```

Kiểm tra health check:
```bash
curl http://localhost:8000/health
```
Phản hồi:
```json
{
  "service": "music-api-gateway",
  "version": "v1.0.0",
  "status": "OK",
  "time": "2026-10-16T08:30:00+07:00"
}
```