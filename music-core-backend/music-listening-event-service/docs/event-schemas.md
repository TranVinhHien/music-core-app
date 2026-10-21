# Music Listening Event Service - Event Schemas

All events submitted to `/api/v1/listening-events/batch` must conform to `schema_version: 1` and provide valid client-generated UUIDs.

---

## 1. Common Base Event Structure

```json
{
  "event_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
  "event_type": "<ENUM>",
  "occurred_at": "2026-10-21T08:30:00Z",
  "schema_version": 1,
  "session_id": "optional-or-required-uuid",
  "track_id": "optional-or-required-uuid",
  "source": {
    "type": "playlist | album | search | artist | library",
    "id": "optional-uuid"
  },
  "properties": {}
}
```

---

## 2. Event Types & Properties Matrix

### 2.1 Playback Events (Requires `session_id` and `track_id`)

| Event Type | Required Properties | Optional Properties | Description |
|---|---|---|---|
| `TRACK_STARTED` | `duration_ms` (>= 0) | `position_ms` (defaults to 0) | Fired when a track begins playback |
| `TRACK_COMPLETED` | `duration_ms`, `listened_ms` | None | Fired when track reaches natural ending |
| `TRACK_SKIPPED` | `duration_ms`, `position_ms`, `listened_ms` | `next_track_id` | Fired when user skips forward/backward |
| `TRACK_PAUSED` | `position_ms`, `listened_ms` | None | Fired when user pauses playback |
| `TRACK_SEEKED` | `from_position_ms`, `to_position_ms` | None | Fired on progress bar scrub |
| `TRACK_REPLAYED` | `position_ms`, `replay_type` ("MANUAL_REPLAY") | None | Fired when user restarts the track |

### 2.2 Discovery & Search Events

| Event Type | Required Properties | Optional Properties | Description |
|---|---|---|---|
| `SEARCH_PERFORMED` | `query` (non-empty string), `search_type` ("track", "artist", "album", "all") | `results_count` (>= 0) | Fired when user submits a catalog search |

### 2.3 Library & Interaction Events

| Event Type | Required Fields / Properties | Optional Properties | Description |
|---|---|---|---|
| `TRACK_FAVORITED` | `track_id` (non-empty) | None | Track liked by user |
| `TRACK_UNFAVORITED` | `track_id` (non-empty) | None | Track unliked by user |
| `TRACK_ADDED_TO_PLAYLIST` | `track_id` (non-empty), `playlist_id` in properties | `position` (>= 0) | Track added into playlist |
| `TRACK_REMOVED_FROM_PLAYLIST`| `track_id` (non-empty), `playlist_id` in properties | None | Track removed from playlist |

### 2.4 Playlist Events

| Event Type | Required Properties | Optional Properties | Description |
|---|---|---|---|
| `PLAYLIST_PLAYED` | `playlist_id` | `track_count`, `playback_mode` ("SEQUENTIAL", "SHUFFLE") | Fired when playback starts from a playlist |
