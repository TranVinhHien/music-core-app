---
trigger: model_decision
description: "Guidelines, architecture, domain boundaries, and implementation standards for the music-catalog-service (NestJS + Prisma)."
---

# Agent Guidelines - Music Catalog Service

## 1. Service Responsibility

### What it does (Core Responsibilities)
- **Catalog Management**: Manages metadata for artists, albums, tracks, and genres.
- **Relational Classifications**: Handles many-to-many relationships (track_artists, album_artists, track_genres) and external track sources (YouTube, Spotify, etc.).
- **Hierarchical Taxonomy**: Supports parent-child genre hierarchies with unique slugs.
- **Unified Response Envelope**: Formats all HTTP responses (`code`, `message`, `meta`, `data`) and errors matching `music-common/response` and `music-user-service`.
- **Database & Migration Engine**: Utilizes Prisma ORM (`prisma/schema.prisma`) with versioned migrations and rollback scripts.

### What it does NOT do (Out of Scope)
- **No Direct Authentication / Authorization**: Authentication and role-based permissions are enforced upstream by `music-api-gateway`. Consumes forwarded identity headers (`X-User-ID`, `X-User-Roles`, `X-Request-ID`).
- **No User Profiles or Tokens**: Managed by `music-user-service`.
- **No Personal Playlists / Likes / History**: Managed by `music-library-service`.
- **No Audio File Transcoding or Streaming**: Managed by `music-audio-service`.

---

## 2. Architecture & Code Structure

### Package Layout
```
music-catalog-service/
├── .env.example                    # Environment variable template
├── .env                            # Local configuration (PORT=3002, etc.)
├── prisma/
│   ├── schema.prisma               # Prisma Single Source of Truth
│   ├── migrations/                 # Versioned migrations
│   │   └── 20261020000001_init_catalog/
│   │       ├── migration.sql       # Up DDL
│   │       └── down.sql            # Down DDL
│   └── scripts/
│       └── rollback.ts             # Rollback runner for down.sql
├── src/
│   ├── common/                     # Filters, interceptors, decorators, and DTOs
│   │   ├── decorators/             # @CurrentUser
│   │   ├── dto/                    # ApiResponseDto, PaginationQueryDto, PaginationMetaDto
│   │   ├── filters/                # GlobalExceptionFilter
│   │   ├── interceptors/           # ResponseTransformInterceptor
│   │   └── utils/                  # text normalization and slugify
│   ├── config/                     # Environment configuration validation
│   ├── database/                   # PrismaService & PrismaModule
│   ├── modules/
│   │   ├── artists/                # Controller, Service, Repository (Interface & Prisma)
│   │   ├── albums/                 # Controller, Service, Repository (Interface & Prisma)
│   │   ├── tracks/                 # Controller, Service, Repository (Interface & Prisma)
│   │   └── genres/                 # Controller, Service, Repository (Interface & Prisma)
│   ├── app.module.ts
│   └── main.ts
└── test/
```

---

## 3. Scripts & Commands

- **Build**: `npm run build`
- **Lint**: `npm run lint`
- **Test**: `npm test`
- **Generate Prisma Client**: `npm run prisma:generate`
- **Run Migrations (Up)**: `npm run prisma:migrate`
- **Rollback Migration (Down)**: `npm run prisma:down`
- **Migration Status**: `npm run prisma:status`
- **Start Dev Server**: `npm run dev` (Runs on `http://localhost:3002/api/v1/catalog`)
- **Swagger Docs**: `http://localhost:3002/api/v1/catalog/docs`
