# Music Catalog Service

NestJS + PostgreSQL microservice managing metadata for tracks, artists, albums, genres, and DJ audio transition profiles.

## Overview

The `music-catalog-service` acts as the single source of truth for the music catalog taxonomy:
- **Catalog Management**: Stores and manages metadata for artists, albums, tracks, and genres with relational integrity.
- **Relational Classifications**: Supports many-to-many relationships (`track_artists`, `album_artists`, `track_genres`) and external platform streaming sources (`track_sources`).
- **Hierarchical Taxonomy**: Handles hierarchical parent-child genre structures.
- **Audio Transition Profiles**: Stores BPM, Camelot keys, cue points, and loudness (LUFS) for Auto-DJ transition calculation.
- **High-Performance Search**: Provides full-text search (`to_tsvector`/`plainto_tsquery`) and trigram fuzzy matching (`pg_trgm`) across tracks, albums, and artists.
- **Unified Response Envelope**: Formats all HTTP responses (`code`, `message`, `data`, `meta`) conforming to `music-common/response`.

## Tech Stack

- **Framework**: NestJS 12
- **Language**: TypeScript
- **Database**: PostgreSQL (with `pgcrypto` and `pg_trgm` extensions)
- **ORM**: Prisma ORM
- **Documentation**: Swagger / OpenAPI

## Getting Started

### Prerequisites

- Node.js (v18+)
- PostgreSQL (v14+)

### Environment Variables

Copy `.env.example` to `.env` and configure your database connection:

```bash
PORT=3002
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/music_catalog?schema=public"
GLOBAL_PREFIX="api/v1/catalog"
CORS_ORIGIN="*"
```

### Installation

```bash
npm install
```

### Database Migrations

Generate Prisma client and apply database migrations:

```bash
npm run prisma:generate
npm run prisma:migrate
```

### Running the Application

```bash
# Development mode
npm run dev

# Watch mode
npm run wdev

# Production build & start
npm run build
npm run start:prod
```

### API Documentation

Once the server is running, explore the interactive Swagger documentation at:
- **Local Swagger UI**: `http://localhost:3002/api/v1/catalog/docs`
