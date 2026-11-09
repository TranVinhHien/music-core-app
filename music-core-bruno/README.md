# Music Core Bruno API Collection

API testing collection for the Music Core App microservices architecture using the Bruno API Client.

## Directory Structure

- `auth/`: Registration, login, token refresh (User Service).
- `user/`: User profile management (User Service).
- `media/`: Media asset & avatar uploads (User Service).
- `catalog/`: Music catalog management (Catalog Service).
  - `artists/`: Artist CRUD (Create, List, Details, Update, Delete).
  - `albums/`: Album CRUD and artist associations.
  - `tracks/`: Track CRUD, artist relations, genre tagging, streaming sources.
  - `genres/`: Music genre CRUD with hierarchical parent-child trees.
- `library/`: Personal user library management (Library Service).
  - `playlists/`: Playlist CRUD, add/remove tracks, auto-enrichment from Catalog.
  - `favorites/`: Add/remove favorites, fetch favorite list with Catalog metadata.
- `listening-events/`: Real-time music playback and user interaction telemetry (Listening Event Service).
  - `Health Check.bru`: Service health probe.
  - `Ingest Batch - Playback Events.bru`: Batch playback events (`TRACK_STARTED`, `TRACK_PAUSED`, `TRACK_COMPLETED`).
  - `Ingest Batch - Discovery & Search.bru`: Batch search events (`SEARCH_PERFORMED`).
  - `Ingest Batch - Library & Playlist.bru`: Batch library & playlist events (`TRACK_FAVORITED`, `TRACK_ADDED_TO_PLAYLIST`, `PLAYLIST_PLAYED`).
  - `Ingest Single Event.bru`: Ingest a single event.

## Usage Guide

1. Open this directory in the **Bruno** application.
2. Select Environment: **Local**.
3. Configure environment variables (`environments/Local.bru`):
   - `base_url`: `http://localhost:8000` (API Gateway URL).
   - `catalog_direct_url`: `http://localhost:3002` (Direct Catalog Service URL).
   - `library_direct_url`: `http://localhost:3003` (Direct Library Service URL).
   - `listening_events_direct_url`: `http://localhost:3004` (Direct Listening Event Service URL).
   - `token`: Bearer access token (obtained from login request in `auth` directory).
