# Inter-Service Communication Specifications

---

## 1. Communication Topologies & Protocols

Inter-service communication in **Music Core Backend** is divided into two primary tiers:
1. **Synchronous Transport (Active / Implemented)**:
   - External clients communicate exclusively with `music-api-gateway` via HTTP/HTTPS REST APIs.
   - `music-api-gateway` proxies requests to downstream internal services via HTTP Reverse Proxy (`net/http/httputil.ReverseProxy`).
2. **Asynchronous Messaging (Planned / In Roadmap)**:
   - High-throughput events (playback telemetry, audio processing jobs) will use a distributed message broker (Apache Kafka or RabbitMQ).

---

## 2. Inbound Routing & Service Invocation Matrix

### Current Active Communication Flow

```
[ External Client ]
        │  Authorization: Bearer <JWT>
        ▼
┌────────────────────────────────────────────────────────┐
│                   music-api-gateway                    │
│  - Validates JWT signature                             │
│  - Checks permissions.json against claims.UserRoles    │
│  - Generates/Propagates X-Request-ID                   │
│  - Injects X-User-ID, X-User-Email, X-User-Roles       │
└───────────────────────────┬────────────────────────────┘
                            │ (HTTP Reverse Proxy)
                            ▼
               ┌─────────────────────────┐
               │   music-user-service    │
               │   (Port 8080)           │
               └─────────────────────────┘
```

### Detailed Route Forwarding Matrix

| Origin | Target Service | Path Prefix | Auth Policy | Forwarded Headers |
|---|---|---|---|---|
| Client ➔ Gateway | `music-user-service` | `/api/v1/auth/**` | Public (except `/me`) | `X-Request-ID`, `X-Forwarded-*` |
| Client ➔ Gateway | `music-user-service` | `/api/v1/users/**` | Protected (`auth_required: true`) | `X-User-ID`, `X-User-Email`, `X-User-Roles`, `X-Request-ID` |
| Client ➔ Gateway | `music-catalog-service` *(planned)* | `/api/v1/catalog/**` | Public / Role Protected | `X-User-ID`, `X-User-Roles`, `X-Request-ID` |
| Client ➔ Gateway | `music-library-service` *(planned)* | `/api/v1/library/**` | Protected (`auth_required: true`) | `X-User-ID`, `X-User-Roles`, `X-Request-ID` |
| Client ➔ Gateway | `music-audio-service` *(planned)* | `/api/v1/audio/**` | Protected / Token Signed | `X-User-ID`, `X-Request-ID` |

---

## 3. Authentication & Distributed Context Propagation

To keep downstream services decoupled from identity provider logic and to prevent redundant database lookups, authentication and authorization follow a **Stateless Perimeter Verification pattern**:

### 1. Token Verification at the Perimeter (API Gateway)
1. The client presents an HTTP Bearer JWT token in the `Authorization` header.
2. The Gateway’s `AuthMiddleware` verifies the token signature using the shared HMAC secret (`token.secret`).
3. If valid, the gateway extracts user identity claims:
   - `UserID` (UUID v4)
   - `Email` (string)
   - `UserRoles` (array of strings, e.g., `["user"]`, `["admin"]`)
4. The gateway evaluates whether the extracted roles have permission for the requested HTTP method and path against `permissions.json`.

### 2. Header Injection Contract
Upon successful authorization, the Gateway mutates the downstream HTTP request by injecting the canonical headers defined in `music-common/constants`:

```http
X-Request-ID: c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c
X-User-ID: a95c723f-e18e-4903-8d9e-c8524d62b9a7
X-User-Email: user@example.com
X-User-Roles: user,premium
X-Forwarded-Host: api.musicapp.com
X-Forwarded-For: 203.0.113.195
X-Forwarded-Proto: https
```

### 3. Consumption in Downstream Services
Downstream services (such as `music-user-service`) read `X-User-ID` directly from the incoming request to identify the user without querying user tables or re-parsing JWT signatures.

---

## 4. Message Broker Contracts (Planned Specifications)

For asynchronous, decouple workflows, message payloads will follow strict JSON contracts published to message topics:

### Topic: `music.listening.events`
- **Producer**: API Gateway / Client Telemetry Ingress.
- **Consumer**: `music-listening-event-service`.
- **Payload Schema**:
  ```json
  {
    "event_id": "uuid-v4",
    "user_id": "uuid-v4",
    "track_id": "uuid-v4",
    "session_id": "uuid-v4",
    "playback_time_seconds": 128.5,
    "duration_seconds": 210.0,
    "completed": false,
    "device_type": "mobile_ios",
    "timestamp": 1729080000
  }
  ```

### Topic: `music.track.transcode`
- **Producer**: `music-catalog-service` (on raw audio upload).
- **Consumer**: `music-audio-service`.
- **Payload Schema**:
  ```json
  {
    "track_id": "uuid-v4",
    "raw_audio_s3_url": "s3://raw-audio/tracks/uuid.flac",
    "target_bitrates": ["128k", "256k", "320k"],
    "output_format": "hls"
  }
  ```

---

## 5. Fault Tolerance, Timeouts & Error Contracts

### Upstream Service Outages (Bad Gateway Handling)
When a downstream microservice is unavailable, crashing, or unreachable, `music-api-gateway` intercepts the network error in `ReverseProxyHandler.ErrorHandler` and responds to the client immediately with a standard `502 Bad Gateway` JSON envelope:

```json
{
  "code": "502",
  "message": "Bad Gateway: upstream service unavailable (127.0.0.1:8080)",
  "meta": null,
  "data": null
}
```

### Request ID Tracing
Every request processed across the system maintains the `X-Request-ID` header. If the client does not provide one, the Gateway’s `RequestID` middleware generates a new UUID v4. Downstream services and loggers (`zerolog`) bind `request_id` into all structured log lines for end-to-end distributed tracing.
