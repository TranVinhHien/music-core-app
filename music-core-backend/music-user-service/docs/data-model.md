# Music User Service - Data Model & Database Schema

The database persistence layer uses **GORM** targeting **CockroachDB / PostgreSQL** (`music-core-db`). All models are defined in `internal/models/user.go`.

---

## 1. Entity-Relationship Diagram

```
┌─────────────────────────────────┐
│        user_credentials         │
├─────────────────────────────────┤
│ PK  id (uuid)                   │
│     email (varchar, unique)     │
│     password_hash (varchar)     │
│     provider (varchar: local)   │
│     provider_id (varchar, null) │
│     is_active (boolean)         │
│     created_at (timestamp)      │
│     updated_at (timestamp)      │
└───────────────┬─────────────────┘
                │ 1
                │
                ├──────────────────────────┐
                │ 1:1                      │ 1:N
                ▼                          ▼
┌─────────────────────────────────┐ ┌─────────────────────────────────┐
│          user_profiles          │ │           user_roles            │
├─────────────────────────────────┤ ├─────────────────────────────────┤
│ PK,FK user_id (uuid)            │ │ PK  id (uuid)                   │
│       full_name (varchar, null) │ │ FK  user_id (uuid, indexed)     │
│       avatar_url (varchar, null)│ │     role (varchar: user/admin)  │
│       phone_number (varchar)    │ │     created_at (timestamp)      │
│       home_address (text)       │ └─────────────────────────────────┘
│       current_lat (float64)     │
│       current_lng (float64)     │
│       current_checkin_at (ts)   │
│       updated_at (timestamp)    │
└─────────────────────────────────┘
                │ 1:N
                ▼
┌─────────────────────────────────┐
│         refresh_tokens          │
├─────────────────────────────────┤
│ PK  id (uuid)                   │
│ FK  user_id (uuid, indexed)     │
│     token (text, unique)        │
│     expires_at (timestamp)      │
│     is_revoked (boolean)        │
│     client_ip (varchar)         │
│     user_agent (text)           │
│     created_at (timestamp)      │
│     updated_at (timestamp)      │
└─────────────────────────────────┘
```

---

## 2. Table Specifications

### Table: `user_credentials`
Stores core authentication and identity data.
- `id` (UUID, Primary Key, generated with `uuid_generate_v4()`).
- `email` (VARCHAR(255), Unique Index, Not Null).
- `password_hash` (VARCHAR(255), Not Null, hidden from JSON serialization via `json:"-"`).
- `provider` (VARCHAR(50), default `'local'`; supported: `local`, `google`, `apple`).
- `provider_id` (VARCHAR(255), Nullable).
- `is_active` (BOOLEAN, default `true`).
- `created_at`, `updated_at` (TIMESTAMPTZ, auto-managed).

### Table: `user_profiles`
Stores user profile attributes and optional location metadata.
- `user_id` (UUID, Primary Key, Foreign Key referencing `user_credentials.id` with `ON DELETE CASCADE`).
- `full_name` (VARCHAR(255), Nullable).
- `avatar_url` (VARCHAR(500), Nullable, typically an S3 bucket URL).
- `phone_number` (VARCHAR(20), Nullable).
- `home_address` (TEXT, Nullable).
- `current_lat`, `current_lng` (DOUBLE PRECISION, Nullable, geolocation coordinates).
- `current_checkin_at` (TIMESTAMP, Nullable).
- `updated_at` (TIMESTAMPTZ).

### Table: `user_roles`
Maps users to permission roles.
- `id` (UUID, Primary Key).
- `user_id` (UUID, Not Null, Index `idx_user_roles_user_id`, Foreign Key referencing `user_credentials.id` with `ON DELETE CASCADE`).
- `role` (VARCHAR(50), Not Null, e.g. `'user'`, `'admin'`).
- `created_at` (TIMESTAMPTZ).

### Table: `refresh_tokens`
Tracks active long-lived refresh tokens for token renewal and revocation.
- `id` (UUID, Primary Key).
- `user_id` (UUID, Not Null, Index `idx_refresh_tokens_user_id`).
- `token` (TEXT, Not Null, Unique Index `idx_refresh_tokens_token`).
- `expires_at` (TIMESTAMP, Not Null).
- `is_revoked` (BOOLEAN, default `false`).
- `client_ip` (VARCHAR(45), Nullable).
- `user_agent` (TEXT, Nullable).
- `created_at`, `updated_at` (TIMESTAMPTZ).
