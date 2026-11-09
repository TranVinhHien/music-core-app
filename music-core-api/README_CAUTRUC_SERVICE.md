# Music App — Backend Services Architecture

## 1. Overview

The backend architecture is split into domain-driven microservices. Each service maintains a clear responsibility for its own data boundary and business logic; domain duplication across services is prohibited.

| Service | Target Tech Stack | Primary Responsibilities |
|---|---|---|
| `music-api-gateway` | Go | API Gateway for clients; gateway-level auth/RBAC, request routing, rate limiting, request ID propagation, and technical logging. |
| `music-user-service` | NestJS | User accounts, authentication profiles, settings, and personal preferences. |
| `music-catalog-service` | NestJS | Metadata for tracks, artists, albums, genres, and audio streaming source references. |
| `music-library-service` | NestJS | Personal user libraries, playlists, favorites, and multi-device library synchronization. |
| `music-listening-event-service` | Go | Ingestion and persistence of listening events and user playback interactions; supports batching, retry, and deduplication. |
| `music-audio-service` | Go | Background audio file processing: downloading from permitted sources, file integrity checks, metadata extraction, and audio analysis. |

> The technology choices above represent the current architectural direction. Do not change languages/frameworks or introduce new services unless explicitly requested.

## 2. Detailed Service Boundaries

### `music-api-gateway` — Go

**Purpose:** Provide a unified entry point for clients.

- Receives requests from the Flutter client and routes them to appropriate downstream services.
- Handles cross-cutting gateway concerns: token authentication, rate limiting, request ID tracking, logging, and timeouts.
- May aggregate lightweight responses when necessary.
- Does not contain deep business logic for user, catalog, library, or listening events.
- Does not proxy heavy audio streaming payloads if clients can stream directly from Object Storage / CDN via presigned URLs.

### `music-user-service` — NestJS

**Purpose:** Manage identity and personal user information.

- Creates and manages user accounts and profiles.
- Manages user settings and preferences.
- Exposes APIs for other services/clients to fetch necessary user information according to access permissions.
- Single source of truth for user profile data.
- Does not manage playlists, music catalog data, or granular playback telemetry.

### `music-catalog-service` — NestJS

**Purpose:** Manage descriptive music content data.

- Manages tracks, artists, albums, genres, and associated metadata.
- Stores content identifiers, streaming source URLs, and references to audio file storage locations.
- Exposes search and catalog lookup APIs across implemented scopes.
- Coordinates with `music-audio-service` when files require processing or technical metadata updates.
- Does not own personal user playlists or user playback history.

### `music-library-service` — NestJS

**Purpose:** Manage each user's personal music collection.

- Manages playlists and tracks within playlists.
- Manages favorite tracks and user-saved library items.
- Manages library states that require cross-device synchronization.
- Enforces ownership and domain constraints for personal user data.
- References canonical catalog tracks rather than duplicating catalog metadata.
- Does not process audio binaries directly or store full telemetry history.

### `music-listening-event-service` — Go

**Purpose:** Ingest and persist user behavioral events during app usage.

Sample events include:

- `PLAY_STARTED`, `PLAY_COMPLETED`
- `PAUSE`, `RESUME`, `SKIP`, `SEEK`, `REPLAY`
- Other playback and discovery events defined in the event schema.

Responsibilities:

- Ingest events from clients with support for batch uploading.
- Validates basic schema, timestamps, user/device context, and `event_id`.
- Persists events and enforces idempotency against client retries.
- Supports offline sync: clients buffer events in a local outbox when offline and sync once reconnected.
- Does not perform heavy audio analysis within the ingestion path.
- Does not directly compute recommendations; downstream recommendation workers consume this data asynchronously.

### `music-audio-service` — Go

**Purpose:** Handle asynchronous, background audio processing decoupled from latency-sensitive API requests.

- Manages or executes download jobs from permitted external sources.
- Validates file integrity, container formats, and readability.
- Extracts technical metadata such as duration, codec, and bitrate.
- Analyzes BPM, musical key, and energy when feature requirements dictate.
- Transcodes audio formats when specified by product requirements.
- Updates job statuses and technical metadata in the appropriate data store.
- Audio binaries reside in Object Storage / local storage; relational databases store metadata, job states, and file references rather than large binaries.
- Does not manage user playlists, user profiles, or playback event telemetry.

## 3. Data & Integration Conventions

- **PostgreSQL:** Structured transactional data such as users, catalog, playlists, and job states.
- **MongoDB:** High-throughput document store for raw listening events when selected in deployment configuration.
- **Neo4j:** Reserved for graph-relational queries in recommendation and network analysis; not a standalone service by default.
- **Redis:** Transient caching for reconstructible data; never the primary source of truth.
- **Object Storage:** Stores large audio binaries; PostgreSQL maintains metadata and file references.
- **Flutter + Drift:** Client playback state, queue, and local offline cache. Clients queue events in a local outbox while offline and sync when online.

The database selections above are architectural guidelines. When working on a service, always confirm the actual configured database in the repository rather than assuming all databases are active.

## 4. Guidelines for AI Agents Modifying Code

1. Review this document, existing folder structures, and repository conventions before making changes.
2. Only implement features within the service's defined domain; if another service's capability is required, use explicit API / event contracts rather than querying its database directly.
3. Do not introduce new services, databases, message brokers, or frameworks without explicit instructions.
4. Do not guess API contracts, table names, schemas, environment variables, or dependencies. Verify the existing code; if unspecified, state assumptions explicitly.
5. Prefer targeted, scoped changes; avoid refactoring unrelated components.
6. Implement error handling, timeouts, retries, and idempotency for operations subject to retries or offline sync.
7. Use unique event IDs for deduplication in listening events; do not assume events arrive in strict chronological order.
8. Safely manage job state transitions and retries for audio jobs; never download or store unauthorized content.
9. Add or update unit/integration tests for any altered behaviors.
10. If a request blurs service boundaries or contradicts this document, clarify the requirements before making major changes.

## 5. Capabilities Without Dedicated Services (Yet)

The following domains may be implemented within existing services or added later once requirements mature:

- **Recommendation:** No standalone service currently. Initially a modular component consuming listening events and audio analysis data; these ingestion services do not own recommendation logic.
- **AI Talk:** No standalone service currently.
- **Download:** Handled as background jobs within `music-audio-service` if the backend downloads files. If Flutter downloads directly to device storage, a backend download service is not needed.
- **Graph Synchronization:** Introduced only when concrete Neo4j use cases are established.
