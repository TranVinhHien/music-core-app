---
trigger: model_decision
description: "Guidelines, architecture, domain boundaries, and implementation standards for the music-library-service (NestJS + Prisma)."
---

# Agent Guidelines - Music Library Service

## 1. Service Responsibility

### What it does (Core Responsibilities)
- **Playlists Management**: Creating, editing, ordering, and deleting custom user playlists (`playlists`, `playlist_tracks`).
- **User Favorites / Loved Tracks**: Adding, removing, and retrieving favorite tracks for authenticated users (`user_favorite_tracks`).
- **Inter-service Catalog Enrichment**: Consumes `music-catalog-service` HTTP API via `CatalogClient` to enrich playlists and favorite responses with detailed track, album, and artist metadata.
- **Unified Response Envelope**: Formats all HTTP responses (`code`, `message`, `meta`, `data`) and errors matching `music-common/response` and other services.
- **Database & Migration Engine**: Utilizes Prisma ORM (`prisma/schema.prisma`) on dedicated schema `schema=library` with versioned migrations and rollback scripts.

### What it does NOT do (Out of Scope)
- **No Direct Authentication / Authorization**: Enforced upstream by `music-api-gateway`. Consumes forwarded identity headers (`X-User-ID`, `X-User-Roles`).
- **No Music Catalog Storage**: Does not store or manage canonical track, artist, album, or genre entities (delegated to `music-catalog-service`).
- **No User Identity or Profiles**: Managed by `music-user-service`.
- **No Audio File Streaming**: Managed by `music-audio-service`.

---

## 2. Architecture & Code Structure

### Package Layout
```
music-library-service/
├── .env.example                    # Environment variable template
├── .env                            # Local configuration (PORT=3003, etc.)
├── 01_init.sql                     # Reference SQL schema
├── prisma/
│   ├── schema.prisma               # Prisma Single Source of Truth
│   ├── migrations/                 # Versioned migrations
│   │   └── 20261020000001_init_library/
│   │       ├── migration.sql       # Up DDL
│   │       └── down.sql            # Down DDL
│   └── scripts/
│       └── rollback.ts             # Rollback runner for down.sql
├── src/
│   ├── common/                     # Filters, interceptors, decorators, and DTOs
│   │   ├── decorators/             # @CurrentUser
│   │   ├── dto/                    # ApiResponseDto, PaginationQueryDto, PaginationMetaDto
│   │   ├── filters/                # GlobalExceptionFilter
│   │   └── interceptors/           # ResponseTransformInterceptor
│   ├── config/                     # Environment configuration validation
│   ├── database/                   # PrismaService & PrismaModule
│   ├── integrations/
│   │   └── catalog/                # CatalogClient HTTP inter-service communication
│   ├── modules/
│   │   ├── playlists/              # Controller, Service, Repository (Interface & Prisma)
│   │   └── favorites/              # Controller, Service, Repository (Interface & Prisma)
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
- **Start Dev Server**: `npm run wdev` (Runs on `http://localhost:3003/api/v1/library`)
- **Swagger Docs**: `http://localhost:3003/api/v1/library/docs`
