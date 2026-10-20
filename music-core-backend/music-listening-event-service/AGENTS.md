---
trigger: model_decision
description: "Guidelines and roadmap status for the music-listening-event-service."
---

# Agent Guidelines - Music Listening Event Service

## 1. Service Status
> [!IMPORTANT]
> **Status: PLANNED / SKELETON REPO**
> This service currently does NOT have an active implementation in the repository (only placeholder `README.md`). Do not assume Kafka consumers or analytics storage are currently deployed.

## 2. Planned Domain Scope
- Real-time ingestion of playback events (`play`, `pause`, `seek`, `duration`).
- Telemetry batching and analytical time-series storage.

## 3. Implementation Instructions for Agents
When task involves starting implementation for this service:
1. Initialize Go module: `go mod init github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service`.
2. Register in root `go.work`: `go work use ./music-listening-event-service`.
3. Follow conventions defined in root `docs/coding-conventions.md`.
