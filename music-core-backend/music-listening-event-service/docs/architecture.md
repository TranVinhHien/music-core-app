# Music Listening Event Service - Architecture

---

## 1. System Overview & Ingestion Flow

The service uses a high-throughput, non-blocking ingestion pipeline designed for event-driven telemetry:

```
[ Web / Mobile Client ]
         │
         ▼ (HTTP POST /api/v1/listening-events/batch)
┌──────────────────────────────────────────────┐
│            music-api-gateway                 │
│  - JWT Verification                          │
│  - Injects X-User-ID, X-Request-ID           │
└──────────────────────┬───────────────────────┘
                       │
                       ▼ (HTTP Reverse Proxy)
┌──────────────────────────────────────────────┐
│        music-listening-event-service         │
│                                              │
│  1. AuthMiddleware                           │
│     Extracts UserID from Header or JWT       │
│                                              │
│  2. EventHandler (Gin)                       │
│     Binds IngestBatchRequest (1-100 items)   │
│                                              │
│  3. EventService                             │
│     Validates 12 event schemas               │
│     Injects received_at, normalized types    │
│                                              │
│  4. EventRepository                          │
│     Unordered BulkWrite (SetOrdered=false)   │
│     Isolates DuplicateKey (Code 11000)       │
└──────────────────────┬───────────────────────┘
                       │
                       ▼ (MongoDB Wire Protocol)
        ┌─────────────────────────────┐
        │     MongoDB Collection      │
        │      "listening_events"     │
        └─────────────────────────────┘
```

---

## 2. Idempotency & Deduplication Design

In high-concurrency mobile and web environments, network blips cause automatic client retries. To ensure duplicate requests never corrupt listening counts or royalty analytics:

1. **Client-Assigned `event_id`**: Every event MUST supply a client-generated UUID `event_id`.
2. **Database Unique Index**: On startup, MongoDB creates a unique index on `event_id` (`uniq_event_id`).
3. **Unordered Bulk Write**: 
   - Uses `options.BulkWrite().SetOrdered(false)`.
   - If 1 out of 100 events has already been stored, MongoDB executes the remaining 99 inserts without aborting the batch.
4. **Duplicate Tallying**:
   - The repository catches `mongo.BulkWriteException`.
   - Any error with `Code == 11000` (DuplicateKey) is treated as an idempotency hit and counted under `duplicate_count`.
   - The response returns `200 OK` with counts: `total_count`, `ingested_count`, and `duplicate_count`.

---

## 3. Database Indexes

On service bootstrap, `mongo.go` verifies and ensures the following compound and unique indexes:

| Index Name | Keys | Purpose |
|---|---|---|
| `uniq_event_id` | `{ event_id: 1 }` (Unique) | Idempotency and deduplication |
| `idx_user_occurred_at` | `{ user_id: 1, occurred_at: -1 }` | Fast retrieval of user's playback history |
| `idx_session_occurred_at` | `{ session_id: 1, occurred_at: 1 }` | Chronological session event reconstruction |
