---
trigger: model_decision
description: "Guidelines and roadmap status for the music-audio-service."
---

# Agent Guidelines - Music Audio Service

## 1. Service Status
> [!IMPORTANT]
> **Status: PLANNED / SKELETON REPO**
> This service currently does NOT have an active implementation in the repository (only placeholder `README.md`). Do not assume audio streaming engines or FFmpeg pipelines are already active.

## 2. Planned Domain Scope
- Audio file storage integration (AWS S3 / MinIO).
- Media transcoding (FFmpeg HLS segmentation: `.m3u8`, `.ts` chunks).
- Audio streaming endpoints with HTTP Range requests.

## 3. Implementation Instructions for Agents
When task involves starting implementation for this service:
1. Initialize Go module: `go mod init github.com/TranVinhHien/music-core-app/music-core-backend/music-audio-service`.
2. Register in root `go.work`: `go work use ./music-audio-service`.
3. Follow conventions defined in root `docs/coding-conventions.md`.
