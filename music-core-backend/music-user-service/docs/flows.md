# Music User Service - Business Flows

---

## 1. User Registration Flow

```
[ Client ]                [ Handler ]            [ AuthService ]          [ UserRepository ]        [ CockroachDB ]
    │                          │                        │                         │                        │
    │ POST /auth/register      │                        │                         │                        │
    ├─────────────────────────>│                        │                         │                        │
    │                          │ Validate DTO           │                         │                        │
    │                          ├───────────────────────>│                         │                        │
    │                          │                        │ Check duplicate email   │                        │
    │                          │                        ├────────────────────────>│ SELECT FROM user_cred  │
    │                          │                        │                         ├───────────────────────>│
    │                          │                        │ Hashes password (bcrypt)│                        │
    │                          │                        │ ID = uuid_generate_v4() │                        │
    │                          │                        ├────────────────────────>│ INSERT user_cred,      │
    │                          │                        │                         │ user_profiles,         │
    │                          │                        │                         │ user_roles             │
    │                          │                        │                         ├───────────────────────>│
    │                          │                        │<────────────────────────┤ Returns User model     │
    │                          │<───────────────────────┤                         │                        │
    │<─────────────────────────┤ 201 Created            │                         │                        │
```

---

## 2. Authentication & Login Flow

1. **Client** issues `POST /api/v1/auth/login` with email and plain password.
2. **AuthHandler** binds client IP and user agent headers into `dto.LoginInput`.
3. **AuthService** queries `UserRepository.FindByEmail`:
   - Checks `is_active == true`.
   - Uses `bcrypt.CompareHashAndPassword(user.PasswordHash, req.Password)`.
4. **Token Generation**:
   - Generates JWT `AccessToken` containing `user_id`, `email`, and `user_roles` with HMAC-SHA256 signature (TTL: e.g. 1 hour).
   - Generates cryptographically secure random string for `RefreshToken` (TTL: e.g. 24 hours).
5. **Persistence**: Saves refresh token record in `refresh_tokens` table.
6. **Response**: Returns both tokens and user profile to client.

---

## 3. Token Refresh Flow

1. **Client** issues `POST /api/v1/auth/refresh` containing `refresh_token`.
2. **AuthService** queries `refresh_tokens` table:
   - Verifies `is_revoked == false` and `expires_at > time.Now()`.
3. **Revocation & Renewal (Token Rotation)**:
   - Marks current refresh token as revoked (`is_revoked = true`).
   - Issues a new `AccessToken` and a new `RefreshToken`.
   - Persists the new refresh token.
4. **Response**: Returns new token pair.

---

## 4. Avatar Media Upload Flow (AWS S3)

1. **Client** submits `POST /api/v1/upload` (`multipart/form-data`) with image file.
2. **UploadHandler** extracts image file and validates file size / MIME format.
3. **UploadService** connects to AWS S3 bucket:
   - Generates unique filename using UUID v4: `uploads/{uuid}.{ext}`.
   - Streams file bytes via `s3Client.PutObject`.
   - Sets object ACL / public read permissions.
4. **Response**: Returns full public S3 CDN URL.
