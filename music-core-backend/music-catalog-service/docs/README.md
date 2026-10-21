# Music Catalog Service - Documentation

## Status: Implemented & Active

- **Stack**: NestJS 10, TypeScript, Prisma ORM, PostgreSQL
- **Active Port**: `3002` (Base URL: `http://localhost:3002/api/v1/catalog`)
- **Swagger Docs**: `http://localhost:3002/api/v1/catalog/docs`
- **Domain Boundaries**:
  - Management and taxonomy for Tracks, Artists, Albums, and Genres.
  - Multi-source audio linking (external IDs/streaming links).
  - Search, filtration, and pagination conforming to `music-common/response`.
- **Database**:
  - Schema file: `prisma/schema.prisma`
  - Versioned migrations & rollback scripts: `prisma/migrations/`
- **Agent Operating Guidelines**:
  - See @music-catalog-service/AGENTS.md
