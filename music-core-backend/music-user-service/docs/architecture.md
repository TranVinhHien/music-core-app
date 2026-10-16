# Kiến Trúc Nội Bộ - Music User Service

> **Lưu ý cập nhật**: Cập nhật file này khi thay đổi cấu trúc internal, logic nghiệp vụ auth, cơ sở dữ liệu hoặc API của User Service.

---

## 1. Cấu trúc thư mục (Directory Structure)
```
music-user-service/
├── cmd/
│   └── server/
│       └── main.go       # Khởi chạy HTTP server và DI (Dependency Injection)
├── config/ hoặc internal/config/
├── internal/
│   ├── handler/          # HTTP request controllers (auth, user, role)
│   ├── service/          # Business logic (JWT creation, password verify, role check)
│   ├── repository/       # Truy vấn DB (GORM / SQLX)
│   └── model/            # Struct database & DTOs
├── app.example.yaml      # Cấu hình mẫu (DB, JWT secret, server port)
└── docs/
    └── architecture.md   # Tài liệu này
```

---

## 2. Luồng xử lý nghiệp vụ chính (Core Flows)
### A. Luồng Đăng nhập (Login Flow)
1. Client gửi `POST /api/v1/auth/login` (email/username + password).
2. Handler bind request và validate payload.
3. Service tìm user theo email qua Repository.
4. Verify password hash.
5. Sinh `AccessToken` (short-lived) và `RefreshToken` (long-lived) đính kèm `user_id` và `roles`.
6. Trả về token và thông tin profile cơ bản.

### B. Luồng Phân quyền & Quản lý User
- Cung cấp các API kiểm tra thông tin user, đổi mật khẩu, phân bổ vai trò (`roles`).

---

## 3. Data Model (Sơ đồ dữ liệu tóm tắt)
- `users`: ID, username, email, password_hash, full_name, avatar_url, status, created_at, updated_at.
- `roles`: ID, role_name, description.
- `user_roles`: user_id, role_id.
- `refresh_tokens`: ID, user_id, token_hash, expires_at.

---

## 4. Danh sách API chính (Endpoints)
- `POST /api/v1/auth/register`: Đăng ký tài khoản mới.
- `POST /api/v1/auth/login`: Đăng nhập, nhận JWT token.
- `POST /api/v1/auth/refresh`: Cấp lại AccessToken từ RefreshToken.
- `GET /api/v1/users/me`: Lấy thông tin tài khoản hiện tại.
- `PUT /api/v1/users/me`: Cập nhật profile.
