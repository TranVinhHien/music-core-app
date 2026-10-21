---
trigger: model_decision
description: "Guidelines, architecture, domain boundaries, and event ingestion standards for the music-listening-event-service (Go + Gin + MongoDB)."
---

# Agent Guidelines - Music Listening Event Service

## 1. Service Responsibility

### What it does (Core Responsibilities)
- **Telemetry Ingestion**: Ingests real-time playback and interaction events via batch (1 - 100 events) or single requests.
- **Strict Schema Validation**: Validates all incoming events against 12 supported event schemas (`schema_version = 1`).
- **Idempotent Ingestion**: Handles network retries and duplicate event submissions transparently via MongoDB unique index on `event_id` and unordered bulk writes (`SetOrdered(false)`).
- **Identity Context Extraction**: Extracts authenticated `user_id` from Gateway headers (`X-User-ID`) or fallback Bearer JWT token (`AuthMiddleware`).
- **Auto-Indexing**: Automatically sets up MongoDB indexes on startup:
  - Unique index: `{ "event_id": 1 }` (`uniq_event_id`)
  - Query index: `{ "user_id": 1, "occurred_at": -1 }` (`idx_user_occurred_at`)
  - Session index: `{ "session_id": 1, "occurred_at": 1 }` (`idx_session_occurred_at`)

### What it does NOT do (Out of Scope)
- **No Direct Authentication**: Enforced upstream by `music-api-gateway`.
- **No SQL Queries or Relational Joins**: Does not connect to CockroachDB or PostgreSQL. Inter-service data (e.g. tracks, playlists) are referenced solely by UUID string.
- **No Client Audio Streaming**: Managed by `music-audio-service`.
- **No Complex Pre-aggregations**: Ingests raw events for future stream processing (Kafka/TimescaleDB/ClickHouse pipelines).

---

## 2. Architecture & Code Structure

```
music-listening-event-service/
├── app.development.yaml            # Local development config (Port 3004, MongoDB connection)
├── app.example.yaml                # Configuration template
├── cmd/server/main.go              # Application bootstrap & lifecycle
├── docs/                           # Focused technical documentation
│   ├── README.md                   # Documentation index
│   ├── architecture.md             # Ingestion pipeline & idempotency design
│   ├── event-schemas.md            # 12 event types & validation rules
│   └── api-contracts.md            # HTTP REST specs
├── internal/
│   ├── config/                     # YAML configuration loader & validation
│   ├── database/                   # MongoDB v2 driver connection & index bootstrap
│   ├── handlers/                   # Transport layer (Gin REST controllers & DTOs)
│   │   ├── dto/                    # Request/Response data transfer objects
│   │   ├── event_handler.go        # Batch & single ingestion endpoints
│   │   └── response.go             # Envelope serialization matching music-common
│   ├── logging/                    # Contextual structured logging
│   ├── middleware/                 # AuthMiddleware (extracts X-User-ID or JWT)
│   ├── models/                     # ListeningEvent & EventSource domain entities
│   ├── repository/                 # MongoDB BulkWrite with DuplicateKey (11000) isolation
│   ├── router/                     # CORS, RequestID, and route registration
│   └── services/                   # Business logic & event schema validator
```

---

## 3. Supported Event Types Summary

| Category | Event Type | Required Fields / Properties |
|---|---|---|
| **Playback** | `TRACK_STARTED` | `session_id`, `track_id`, `duration_ms`, optional `position_ms` |
| | `TRACK_COMPLETED` | `session_id`, `track_id`, `duration_ms`, `listened_ms` |
| | `TRACK_SKIPPED` | `session_id`, `track_id`, `duration_ms`, `position_ms`, `listened_ms` |
| | `TRACK_PAUSED` | `session_id`, `track_id`, `position_ms`, `listened_ms` |
| | `TRACK_SEEKED` | `session_id`, `track_id`, `from_position_ms`, `to_position_ms` |
| | `TRACK_REPLAYED` | `session_id`, `track_id`, `position_ms`, `replay_type` ("MANUAL_REPLAY") |
| **Discovery** | `SEARCH_PERFORMED` | `query`, `search_type` ("track", "artist", "album", "all") |
| **Library** | `TRACK_FAVORITED` | `track_id` |
| | `TRACK_UNFAVORITED` | `track_id` |
| | `TRACK_ADDED_TO_PLAYLIST` | `track_id`, `playlist_id` in properties |
| | `TRACK_REMOVED_FROM_PLAYLIST` | `track_id`, `playlist_id` in properties |
| **Playlist** | `PLAYLIST_PLAYED` | `playlist_id` in properties, optional `playback_mode` ("SEQUENTIAL", "SHUFFLE") |

---

## 4. Scripts & Commands

- **Run Dev Server**: `make run-listening-event` (Runs on `http://localhost:3004`)
- **Build Binary**: `make build-listening-event`
- **Run Tests**: `cd music-listening-event-service && go test -v ./...`
