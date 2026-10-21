# Music Listening Event Service - API Contracts

Base Ingress Path: `/api/v1/listening-events`

---

## 1. Batch Event Ingestion

- **Method**: `POST`
- **Path**: `/api/v1/listening-events/batch` or `/api/v1/listening-events`
- **Auth**: Protected (Requires `Authorization: Bearer <token>` or injected `X-User-ID: <uuid>`)
- **Headers**:
  - `Content-Type: application/json`
  - `X-User-ID: <uuid>` (forwarded by Gateway)

### Request Payload

```json
{
  "events": [
    {
      "event_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
      "event_type": "TRACK_STARTED",
      "occurred_at": "2026-10-21T08:30:00Z",
      "schema_version": 1,
      "session_id": "99999999-8888-7777-6666-555555555555",
      "track_id": "11111111-2222-3333-4444-555555555555",
      "source": {
        "type": "playlist",
        "id": "77777777-8888-9999-aaaa-bbbbbbbbbbbb"
      },
      "properties": {
        "duration_ms": 210000,
        "position_ms": 0
      }
    }
  ]
}
```

### Constraints:
- `events`: Array length between 1 and 100.
- `schema_version`: Must equal 1.
- `occurred_at`: Valid ISO 8601 UTC timestamp.

### Success Response (`200 OK`)

Conforms to standard `music-common/response` envelope:

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

### Error Responses

| HTTP Status | Reason / Code | Response Body |
|---|---|---|
| `400 Bad Request` | Empty batch, >100 items, schema violation, or missing property | `{"code": "400", "message": "event at index 0 invalid: missing required property 'duration_ms'"}` |
| `401 Unauthorized` | Missing `X-User-ID` and invalid Bearer token | `{"code": "401", "message": "unauthorized: missing user identity"}` |
| `500 Internal Error` | MongoDB connection failure or unhandled write error | `{"code": "500", "message": "failed to persist events: ..."}` |

---

## 2. Health Check

- **Method**: `GET`
- **Path**: `/health` or `/api/v1/listening-events/health`
- **Auth**: Public

### Response (`200 OK`)

```json
{
  "status": "UP",
  "time": "2026-10-21T08:35:00Z"
}
```
