# Kiến Trúc Nội Bộ - Music API Gateway

> **Lưu ý cập nhật**: Cập nhật file này khi thay đổi cơ chế định tuyến (proxy), middleware pipeline hoặc cấu trúc config của API Gateway.

---

## 1. Cấu trúc thư mục (Directory Structure)
```
music-api-gateway/
├── cmd/                # Khởi chạy gateway
├── config/             # Parse gateway.*.yaml
├── middlewares/        # Auth, CORS, Logger, Rate-limit, Recovery
├── permissions/        # Logic phân quyền (RBAC) và match route permissions
├── permissions.json    # Bảng phân quyền chi tiết cho từng endpoint
├── proxy.go            # Reverse Proxy handler
├── server.go           # Khởi tạo HTTP router và middleware chain
└── gateway.example.yaml# File mẫu cấu hình downstream routes và server port
```

---

## 2. Luồng xử lý một Request (Request Flow)
1. **Client Request** ➔ `server.go` tiếp nhận qua HTTP port.
2. **Global Middlewares**:
   - `RequestIDMiddleware`: Tạo và đính kèm `X-Request-Id`.
   - `CORSMiddleware`: Kiểm tra header CORS.
   - `LoggerMiddleware`: Ghi log request/latency.
3. **Authentication & Authorization**:
   - `AuthMiddleware`: Validate JWT Bearer Token, trích xuất `user_id` và `role`.
   - `PermissionMiddleware`: Đối chiếu path và method với `permissions.json`.
4. **Proxy Forwarding (`proxy.go`)**:
   - Gắn header `X-User-Id`, `X-User-Role`, `X-Request-Id`.
   - Forward sang Downstream Service (User, Catalog, Library, Audio, v.v.).
5. **Response Handler**:
   - Trả dữ liệu từ downstream về cho Client.

---

## 3. Cấu hình Routes & Downstream Services (Tóm tắt)
- Cấu hình được định nghĩa trong file `gateway.*.yaml`.
- Quy tắc mapping:
  - `/api/v1/users/**` ➔ `music-user-service`
  - `/api/v1/auth/**` ➔ `music-user-service`
  - `/api/v1/catalog/**` ➔ `music-catalog-service`
  - `/api/v1/library/**` ➔ `music-library-service`
  - `/api/v1/audio/**` ➔ `music-audio-service`
