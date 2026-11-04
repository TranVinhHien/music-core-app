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
- **Endpoints (Transitions)**:
  - `GET /transitions/next`: Calculate optimal next track transition plan via Camelot harmonic wheel, BPM tempo matching, energy analysis, and Softmax probability sampling. Query params: `currentTrackId`, `excludeTrackIds`, `temperature`.
- **Endpoints (Search)**:
  - `GET /search`: High-performance catalog search across tracks, albums, and artists. Powered by PostgreSQL Full-Text Search (`to_tsvector`/`plainto_tsquery`), `pg_trgm` fuzzy matching (`similarity()`), SQL `ILIKE` prefix/substring matching, and GIN indexes. Dispatches 3 parallel queries, returning distinct sections with items and total counts for each entity type. Query params: `query` (or `q`), `limit`, `page`, `type` (`all`, `tracks`, `albums`, `artists`).
- **Database**:
  - Schema file: `prisma/schema.prisma`
  - Versioned migrations & rollback scripts: `prisma/migrations/`
- **Agent Operating Guidelines**:
  - See @music-catalog-service/AGENTS.md
