# Internal Architecture - Music User Service

> **Update Notice**: Update this file when changing internal structures, auth business logic, database models, or User Service APIs.

---

## 1. Directory Structure
```
music-user-service/
├── cmd/
│   └── server/
│       └── main.go       # HTTP server entry point and Dependency Injection (DI)
├── config/ or internal/config/
├── internal/
│   ├── handler/          # HTTP request controllers (auth, user, role)
│   ├── service/          # Business logic (JWT creation, password verification, role checks)
│   ├── repository/       # Database queries (GORM / SQLX)
│   └── model/            # Database entity structs & DTOs
├── app.example.yaml      # Sample configuration (DB, JWT secret, server port)
└── docs/
    └── architecture.md   # This document
```

---

## 2. Core Business Flows
### A. Login Flow
1. Client sends `POST /api/v1/auth/login` (email/username + password).
2. Handler binds the request and validates the payload.
3. Service looks up the user by email/username via Repository.
4. Verifies password hash.
5. Generates `AccessToken` (short-lived) and `RefreshToken` (long-lived) containing `user_id` and `roles`.
6. Returns tokens along with basic user profile information.

### B. Authorization & User Management Flow
- Provides APIs to query user info, change passwords, and manage assigned `roles`.

---

## 3. Data Model (Summary)
- `users`: ID, username, email, password_hash, full_name, avatar_url, status, created_at, updated_at.
- `roles`: ID, role_name, description.
- `user_roles`: user_id, role_id.
- `refresh_tokens`: ID, user_id, token_hash, expires_at.

---

## 4. Primary API Endpoints
- `POST /api/v1/auth/register`: Register a new account.
- `POST /api/v1/auth/login`: Authenticate and issue JWT tokens.
- `POST /api/v1/auth/refresh`: Issue a new AccessToken using a valid RefreshToken.
- `GET /api/v1/users/me`: Retrieve current user profile.
- `PUT /api/v1/users/me`: Update profile information.
