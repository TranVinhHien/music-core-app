# Music Core Backend - System Architecture

---

## 1. System Overview

**Music Core Backend** is a scalable, cloud-native music streaming platform engineered in **Golang**. The backend adopts a microservices architecture organized under a Go Multi-Module Workspace (`go.work`). It is designed to handle high-concurrency client requests, real-time media streaming, user catalog navigation, and event-driven listening telemetry.

---

## 2. Service Catalog & Domain Boundaries

The backend comprises **6 microservices** and **1 shared common module**:

```
                                  [ Client Layer ]
                     (Web Apps, Mobile Clients, Desktop Players)
                                         │
                                         ▼ (HTTP/REST)
                             ┌───────────────────────┐
                             │   music-api-gateway   │
                             └───────────┬───────────┘
                                         │
             ┌───────────────────────────┼───────────────────────────┐
             │                           │                           │
    (Reverse Proxy HTTP)        (Reverse Proxy HTTP)        (Reverse Proxy HTTP)
             ▼                           ▼                           ▼
  ┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
  │  music-user-service  │    │music-catalog-service │    │ music-audio-service  │
  └──────────┬───────────┘    └──────────┬───────────┘    └──────────┬───────────┘
             │                           │                           │
     [ CockroachDB / ]            [ Catalog DB ]             [ Object Storage ]
     [  PostgreSQL   ]                                        (S3 / MinIO)
             │
             ├───────────────────────────┬───────────────────────────┐
             ▼                           ▼                           │
  ┌──────────────────────┐    ┌──────────────────────┐               │
  │music-library-service │    │music-listening-event │               │
  └──────────┬───────────┘    └──────────┬───────────┘               │
             │                           │                           │
        [Library DB]             [ Event Broker ]                    │
                                 (Kafka/RabbitMQ)                    │
                                                                     │
  ===================================================================│====
  [ Shared Library Module: music-common (Headers, Envelopes, Utils) ]
```

### Detailed Service Responsibilities

| Service / Module | Ownership & Core Responsibilities | Out of Scope / Boundaries |
|---|---|---|
| **`music-api-gateway`** | **Central Ingress & Security**. Ingress reverse proxy, client request routing, stateless JWT validation, RBAC policy enforcement (`permissions.json`), header injection (`X-User-ID`, `X-User-Roles`, `X-Request-ID`), CORS, and request logging. | **No database connections**. No password hashing or token creation. No direct audio streaming. |
| **`music-user-service`** | **Identity, Auth & User Profiles**. User registration, authentication, JWT Access/Refresh token issuance, password hashing (`bcrypt`), RBAC role assignments, user profile management, and avatar asset uploads via AWS S3 / MinIO. | Does not manage catalog metadata (tracks/albums), playlists, audio transcoding, or analytics telemetry. |
| **`music-catalog-service`** | **Music Metadata & Exploration**. Management and search of tracks, artists, albums, genres, lyrics, and discographies. | Does not store user playlists, handle user credentials, or store binary audio files. |
| **`music-audio-service`** | **Audio Assets & Streaming**. Media ingestion, transcoding (HLS / chunking / bitrates), streaming delivery, and integration with S3/MinIO object storage. | Does not maintain track metadata or user authentication. |
| **`music-library-service`** | **Personalized User Content**. User-created playlists, favorite/liked tracks, saved albums, and followed artists. | Does not process audio files or authenticate credentials directly. |
| **`music-listening-event-service`** | **Telemetry & Stream Analytics**. High-throughput ingestion of playback events (`play`, `pause`, `seek`, `completed`), duration tracking, royalty calculations, and real-time dashboard analytics. | Does not serve customer-facing metadata or authenticate tokens. |
| **`music-common`** | **Shared Foundational Library**. Standard HTTP response envelopes (`Response[T]`, `AnyResponse`), canonical header constants (`headers.go`), pagination helpers, shared HTTP client, and common error definitions. | Contains no executable server daemon or runnable application entrypoint. |

---

## 3. Real Infrastructure & Tech Stack in Use

The following components represent the active tech stack running in the repository:

- **Runtime & Toolchain**:
  - **Go Version**: `go 1.26.0` (managed via `go.work`).
  - **HTTP Framework**: `github.com/gin-gonic/gin` (used across gateway and user services).
  - **Structured Logging**: `github.com/rs/zerolog` (zero-allocation JSON logging with context).
- **Data Persistence**:
  - **Relational Database**: CockroachDB / PostgreSQL accessed through **GORM** (`gorm.io/gorm`, `gorm.io/driver/postgres`).
  - **Connection Pooling**: Configured max open connections, idle connections, and connection lifetime.
- **Object Storage**:
  - **AWS S3 / MinIO Compatible Storage**: Integrated using official AWS SDK (`aws-sdk-go-v2`) for avatar and media asset uploads.
- **Security & Authorization**:
  - **Stateless Tokens**: HMAC-SHA256 JWT tokens using `github.com/golang-jwt/jwt/v5`.
  - **Password Security**: `golang.org/x/crypto/bcrypt`.
  - **Access Control**: Declarative JSON RBAC policy matrix (`permissions.json`).
- **Build & Workflow Automation**:
  - Standardized `Makefile` providing unified targets (`run-gateway`, `run-user`, `test-all`, `build-gateway`, `build-user`).

---

## 4. Current Implementation Status vs Planned Roadmap

To maintain clear context, the platform is divided into implemented and planned milestones:

### Implemented & Production-Ready
1. **`music-api-gateway`**:
   - Dynamic reverse proxy engine (`net/http/httputil`).
   - Route mapping from YAML config (`gateway.*.yaml`).
   - Stateless JWT authentication middleware.
   - RBAC policy evaluation engine against `permissions.json`.
   - Context propagation (`X-User-ID`, `X-User-Email`, `X-User-Roles`, `X-Request-ID`).
   - CORS, RequestID, Zerolog middlewares, and health check.
2. **`music-user-service`**:
   - Clean layered architecture: `handlers` ➔ `services` ➔ `repository` ➔ `models`.
   - User registration and login with bcrypt hashing.
   - Dual-token issuance: AccessToken (short-lived) + RefreshToken (long-lived).
   - Profile management (`/api/v1/users/me`) and avatar upload to AWS S3.
   - GORM CockroachDB/PostgreSQL integration.
3. **`music-catalog-service`**:
   - Stack: NestJS + Prisma ORM (Port `3002`).
   - Catalog management: Artists, Albums, Tracks, and Genres taxonomy.
   - Audio analysis profiles: Camelot key, BPM, energy, LUFS loudness, cue points (`cueInMs`, `cueOutMs`).
   - Intelligent Harmonic Transition Engine (`GET /api/v1/catalog/transitions/next`): Multi-factor scoring (Camelot wheel + BPM drift + energy delta) with temperature-calibrated Softmax sampling.
   - Dynamic search, filters, pagination, and unified response envelope.
   - Versioned migrations & down scripts.
4. **`music-library-service`**:
   - Stack: NestJS + Prisma ORM (Port `3003`).
   - Personal user collections: Playlists, track relationships, favorites, and saved items.
   - Identity context consumption via forwarded headers (`X-User-ID`, `X-User-Roles`).
5. **`music-listening-event-service`**:
   - Stack: Go + Gin + MongoDB (Port `3004`).
   - High-throughput listening event ingestion (batch & single).
   - Event validation, deduplication, and persistence for analytics telemetry.
6. **`music-common`**:
   - Shared generic response envelopes (`Response[T]`) and pagination models.
   - Canonical header constants (`X-User-ID`, `X-Request-ID`, etc.).

### Planned (In Roadmap)
1. **`music-audio-service`**: FFmpeg transcoding pipelines, HLS playlist packaging (`.m3u8`, `.ts`), range-request audio streaming.
