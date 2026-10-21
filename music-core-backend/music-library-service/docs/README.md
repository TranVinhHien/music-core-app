# Music Library Service - Documentation

## Status: Implemented & Active

- **Stack**: NestJS 10, TypeScript, Prisma ORM, PostgreSQL
- **Active Port**: `3004` (Base URL: `http://localhost:3004/api/v1/library`)
- **Domain Boundaries**:
  - Personal user collections: Custom Playlists, Favorite/Liked Tracks, Saved Albums.
  - Playlist track sequencing & order management.
  - Consumes upstream identity forwarded headers (`X-User-ID`, `X-User-Roles`).
- **Database**:
  - Schema file: `prisma/schema.prisma`
  - Versioned migrations & rollback scripts: `prisma/migrations/`
- **Agent Operating Guidelines**:
  - See @music-library-service/AGENTS.md
