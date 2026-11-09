# Music Listening Event Service

Microservice responsible for the ingestion, validation, deduplication/idempotency, and raw storage of user listening events and interaction behaviors.

## Tech Stack & Architecture
- **Language**: Golang (Go 1.26)
- **Framework**: Gin Gonic
- **Database**: MongoDB
- **Service Port**: Port `3004` (routed via `music-api-gateway` at `/api/v1/listening-events`)
- **Architecture**: Layered Architecture (Handler -> Service -> Repository -> MongoDB)

## API Endpoints

### 1. Ingest Batch Events
- **Method**: `POST`
- **Path**: `/api/v1/listening-events/batch` (or `/api/v1/listening-events`)
- **Headers**:
  - `Authorization: Bearer <token>`
  - `X-User-ID: <uuid>` (injected when routed via Gateway)
- **Request Body**:
  ```json
  {
    "events": [
      {
        "event_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
        "event_type": "TRACK_STARTED",
        "occurred_at": "2026-10-21T08:30:00Z",
        "session_id": "playback-session-uuid",
        "track_id": "track-uuid",
        "source": {
          "type": "playlist",
          "id": "playlist-uuid"
        },
        "properties": {
          "duration_ms": 210000,
          "position_ms": 0
        },
        "schema_version": 1
      }
    ]
  }
  ```
- **Response**:
  ```json
  {
    "code": "200",
    "message": "events ingested successfully",
    "data": {
      "total_count": 1,
      "ingested_count": 1,
      "duplicate_count": 0,
      "processed_event_ids": [
        "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c"
      ]
    }
  }
  ```

### 2. Health Check
- **Path**: `/health` or `/api/v1/listening-events/health`

## Run & Test
```bash
# Run service
make run-listening-event

# Build binary
make build-listening-event

# Run unit tests
make test-listening-event
```
