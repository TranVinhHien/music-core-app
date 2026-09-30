# Personal Music App

Personal Music App is a private, offline-first music experience. It starts as a dependable music player and library, then evolves into a personalized listening system that can organize music, understand listening habits, create intelligent sessions, and act as a controlled AI music assistant.

The product direction is defined in [`personal_music_app_features.md`](personal_music_app_features.md). That document is the product target; the current implementation status is described separately below.

## Product vision

The app is planned in four capability levels:

1. **Core player and library** — playback controls, queue management, songs, artists, albums, genres, favorites, playlists, search, history, offline playback, and storage management.
2. **Personalization** — Internet music discovery, downloads, metadata recognition, automatic library organization, smart playlists, moods, recommendations, listening profiles, and statistics.
3. **Intelligent listening** — seamless playback, smooth transitions, BPM, key, energy, and melody analysis, energy-flow sessions, contextual sessions, and a personalized Auto DJ.
4. **AI Talk** — a controlled natural-language assistant that invokes supported app actions such as playback, search, downloads, playlists, mood sessions, and library questions.

AI Talk is intended to operate only through explicit application capabilities; it is not an unrestricted agent.

## Repository layout

```text
music-core-app/
├── music-core-api/                 # Go backend and HTTP API
│   ├── cmd/server/                 # API entry point
│   ├── internal/handlers/          # HTTP transport and DTOs
│   ├── internal/services/          # Business logic
│   ├── internal/repository/        # Persistence access
│   ├── internal/models/            # Database models
│   ├── internal/database/          # Connections and migrations
│   └── docs/                       # API and service contracts
├── personal_music_app_features.md  # Product requirements and roadmap
└── README.md                       # Project overview
```

## Current implementation

The `music-core-api` module currently provides the backend foundation:

- Account registration and login
- JWT access and refresh tokens
- Logout and token revocation
- User profile retrieval and updates
- Password changes
- Authenticated image upload boundary
- PostgreSQL/CockroachDB-compatible persistence and Goose migrations
- DTO-only service inputs and outputs
- A shared `{ code, message, meta, data }` response format

The product features in all four levels are the target roadmap. Music playback on a device, local media indexing, playlists, recommendations, audio analysis, and AI orchestration still need dedicated modules and endpoints.

## Architecture direction

```text
Client / music player
        ↓
     HTTP API
        ↓
     Handlers  →  DTO request/response boundary
        ↓
     Services  →  business rules
        ↓
   Repositories → persistence access
        ↓
      Database
```

The API is layered so future library, recommendation, Auto DJ, and AI Talk features can be added without coupling transports to database models. See [`music-core-api/README.md`](music-core-api/README.md) for setup, endpoints, and backend conventions.

## Quick start

```bash
cd music-core-api
go mod download
go test ./...
go run ./cmd/server
```

For local database setup, copy `music-core-api/app.development.yaml.example` to `music-core-api/app.development.yaml`, configure the connection, then run `docker compose up -d postgres` from `music-core-api`.

## Project principles

- Offline-first listening experience
- Personal data and music library ownership
- Incremental delivery from reliable core features to intelligent features
- Explicit, testable application capabilities for AI actions
- Clear separation between transport DTOs, business logic, and persistence
- Respect for the rights and terms of external music sources

## Documentation

- [Product feature brief](personal_music_app_features.md)
- [Music Core API](music-core-api/README.md)
- [Service DTO contract](music-core-api/docs/service-dto-contract.md)
