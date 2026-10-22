# Music Catalog Service - Documentation

## Status: Implemented & Active

- **Stack**: NestJS 10, TypeScript, Prisma ORM, PostgreSQL
- **Active Port**: `3002` (Base URL: `http://localhost:3002/api/v1/catalog`)
- **Swagger Docs**: `http://localhost:3002/api/v1/catalog/docs`
- **Domain Boundaries**:
  - Management and taxonomy for Tracks, Artists, Albums, and Genres.
  - Track Audio Analysis & Transition Profiles (BPM, Cues, Camelot key, LUFS, Downbeats).
  - Multi-source audio linking (external IDs/streaming links).
  - Search, filtration, and pagination conforming to `music-common/response`.
- **Endpoints (Tracks)**:
  - `GET /tracks`: List tracks (supports `analysisStatus=PENDING|COMPLETED|FAILED`).
  - `GET /tracks/:id`: Retrieve track details including `audioAnalysis`.
  - `PUT /tracks/:id/audio-analysis`: Upsert track transition analysis profile.
- **Database**:
  - Schema file: `prisma/schema.prisma`
  - Versioned migrations & rollback scripts: `prisma/migrations/`
- **Agent Operating Guidelines**:
  - See @music-catalog-service/AGENTS.md
