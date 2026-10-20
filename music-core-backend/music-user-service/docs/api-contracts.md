# Music User Service - API Contracts

---

## 1. Authentication Endpoints (Group: `/api/v1/auth`)

### `POST /api/v1/auth/register`
Creates a new user credential, default role (`user`), and profile.
- **Access**: Public
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "full_name": "John Doe",
    "avatar_url": "https://...",
    "phone_number": "+1234567890",
    "home_address": "123 Music St",
    "current_lat": 10.7769,
    "current_lng": 106.7009
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "code": "201",
    "message": "user registered",
    "data": {
      "id": "a95c723f-e18e-4903-8d9e-c8524d62b9a7",
      "email": "user@example.com",
      "is_active": true,
      "roles": ["user"],
      "profile": { ... },
      "created_at": "..."
    }
  }
  ```

---

### `POST /api/v1/auth/login`
Authenticates credentials and returns access and refresh tokens.
- **Access**: Public
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123!"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "code": "200",
    "message": "login successful",
    "data": {
      "access_token": "eyJhbGciOi...",
      "refresh_token": "d7a8b9c...",
      "token_type": "Bearer",
      "expires_in": 3600,
      "user": {
        "id": "a95c723f-e18e-4903-8d9e-c8524d62b9a7",
        "email": "user@example.com",
        "roles": ["user"],
        "profile": { ... }
      }
    }
  }
  ```

---

### `POST /api/v1/auth/refresh`
Exchanges an unrevoked, unexpired refresh token for a new access token.
- **Access**: Public
- **Request Body**:
  ```json
  {
    "refresh_token": "d7a8b9c..."
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "code": "200",
    "message": "token refreshed",
    "data": {
      "access_token": "eyJhbGciOi...",
      "refresh_token": "new-refresh-token...",
      "token_type": "Bearer",
      "expires_in": 3600
    }
  }
  ```

---

### `POST /api/v1/auth/logout`
Revokes the provided refresh token in the database.
- **Access**: Public
- **Request Body**:
  ```json
  {
    "refresh_token": "d7a8b9c..."
  }
  ```
- **Response**: `200 OK` (`{"code": "200", "message": "logged out successfully", "data": null}`)

---

## 2. User Profile Endpoints (Group: `/api/v1/users` & `/api/v1/auth`)

Both routes require authentication. When routed through `music-api-gateway`, user ID is provided via `X-User-ID` header. When called standalone, Bearer token is verified via local middleware.

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/users/me` or `/api/v1/auth/me` | Returns current user's profile and roles |
| `PUT` | `/api/v1/users/me` or `/api/v1/auth/me` | Updates full name, avatar URL, phone number, address |
| `PUT` | `/api/v1/users/me/password` or `/api/v1/auth/me/password` | Changes password (`old_password`, `new_password`) |

---

## 3. Media Upload Endpoint

### `POST /api/v1/upload`
Uploads an image (such as user avatar) directly to configured AWS S3 bucket.
- **Access**: Protected
- **Content-Type**: `multipart/form-data` (form field: `image`)
- **Response**: `200 OK`
  ```json
  {
    "code": "200",
    "message": "Image uploaded successfully",
    "data": {
      "url": "https://your-s3-bucket.s3.ap-northeast-2.amazonaws.com/uploads/uuid.png"
    }
  }
  ```

---

## 4. Diagnostics & Static Pages
- `GET /health`: Returns service health status (`200 OK`).
- `GET /swagger/*any`: Swagger UI documentation.
- `GET /login`, `GET /dashboard`, `GET /public/*`: Built-in HTML client demo files.
