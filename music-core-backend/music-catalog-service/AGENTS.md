---
trigger: model_decision
description: "Guidelines and roadmap status for the music-catalog-service."
---

# Agent Guidelines - Music Catalog Service

## 1. Service Status
> [!IMPORTANT]
> **Status: PLANNED / SKELETON REPO**
> This service currently does NOT have an active implementation in the repository (only placeholder `README.md`). Do not hallucinate existing database schemas, models, or endpoints.

## 2. Planned Domain Scope
- Management of music catalog metadata: tracks, artists, albums, genres, and discographies.
- Search indexing (Elasticsearch / Meilisearch / PostgreSQL Full-Text Search).

## 3. Implementation Instructions for Agents
When task involves starting implementation for this service:
1. Initialize Go module: `go mod init github.com/TranVinhHien/music-core-app/music-core-backend/music-catalog-service`.
2. Register in root `go.work`: `go work use ./music-catalog-service`.
3. Follow layered architecture pattern defined in root `docs/coding-conventions.md`.
