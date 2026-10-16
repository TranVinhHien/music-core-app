---
trigger: model_decision
description: "Guidelines and roadmap status for the music-library-service."
---

# Agent Guidelines - Music Library Service

## 1. Service Status
> [!IMPORTANT]
> **Status: PLANNED / SKELETON REPO**
> This service currently does NOT have an active implementation in the repository (only placeholder `README.md`). Do not assume playlist tables or liking services exist yet.

## 2. Planned Domain Scope
- User personal library: creating, editing, and ordering custom playlists.
- User favorites (liked tracks, followed artists, saved albums).

## 3. Implementation Instructions for Agents
When task involves starting implementation for this service:
1. Initialize Go module: `go mod init github.com/TranVinhHien/music-core-app/music-core-backend/music-library-service`.
2. Register in root `go.work`: `go work use ./music-library-service`.
3. Follow conventions defined in root `docs/coding-conventions.md`.
