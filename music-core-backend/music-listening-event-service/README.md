# Music Listening Event Service

Microservice phụ trách tiếp nhận (ingestion), xác thực, khử trùng lặp (deduplication/idempotency) và lưu trữ thô các sự kiện nghe nhạc và tương tác của người dùng.

## Công nghệ & Kiến trúc
- **Ngôn ngữ**: Golang (Go 1.26)
- **Framework**: Gin Gonic
- **Cơ sở dữ liệu**: MongoDB
- **Cổng dịch vụ**: Port `3004` (được định tuyến qua `music-api-gateway` tại `/api/v1/listening-events`)
- **Kiến trúc**: Layered Architecture (Handler -> Service -> Repository -> MongoDB)

## API Endpoints

### 1. Ingest Batch Events
- **Method**: `POST`
- **Path**: `/api/v1/listening-events/batch` (hoặc `/api/v1/listening-events`)
- **Headers**:
  - `Authorization: Bearer <token>`
  - `X-User-ID: <uuid>` (nếu gọi qua Gateway)
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
- **Path**: `/health` hoặc `/api/v1/listening-events/health`

## Chạy & Kiểm thử
```bash
# Chạy service
make run-listening-event

# Build binary
make build-listening-event

# Chạy unit tests
make test-listening-event
```