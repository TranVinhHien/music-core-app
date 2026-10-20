# Music API Gateway - API Routing & Authorization Contracts

---

## 1. Gateway Native Endpoints

| Method | Endpoint | Auth Required | Description | Response Status |
|---|---|---|---|---|
| `GET` | `/health` | No | Gateway liveness check | `200 OK` (`{"service":"music-api-gateway","status":"OK",...}`) |

---

## 2. Downstream Proxy Routes (From `gateway.example.yaml`)

All non-native requests are mapped to upstream targets using prefix matching:

| Route Prefix | Upstream Target | Auth Required | Target Service |
|---|---|---|---|
| `/api/v1/auth/**` | `http://localhost:8080` | `false` | `music-user-service` |
| `/api/v1/users/**` | `http://localhost:8080` | `true` | `music-user-service` |
| `/api/v1/upload/**` | `http://localhost:8080` | `true` | `music-user-service` |
| `/api/v1/catalog/**` | `http://localhost:3002` *(stub)* | `false` | `music-catalog-service` |
| `/api/v1/library/**` | `http://localhost:3003` *(stub)* | `true` | `music-library-service` |
| `/api/v1/listening-events/**` | `http://localhost:3004` *(stub)* | `true` | `music-listening-event-service` |
| `/api/v1/audio/**` | `http://localhost:3005` *(stub)* | `true` | `music-audio-service` |

---

## 3. RBAC Policy Matrix (From `permissions.json`)

The Gateway evaluates role permissions in `middlewares.AuthMiddleware` using `permissions.Evaluator`:

### Role: `admin`
- Full wildcard access: `GET: ["*"]`, `POST: ["*"]`, `PUT: ["*"]`, `PATCH: ["*"]`, `DELETE: ["*"]`.

### Role: `user`
- `GET`: `/api/v1/users/*`, `/api/v1/catalog/*`, `/api/v1/library/*`, `/api/v1/audio/*`
- `POST`: `/api/v1/library/*`, `/api/v1/listening-events/*`, `/api/v1/upload`
- `PUT`: `/api/v1/users/*`, `/api/v1/library/*`
- `DELETE`: `/api/v1/library/*`

---

## 4. Error Responses
- **401 Unauthorized**: Missing or malformed `Authorization: Bearer <token>`, invalid signature, or expired token.
- **403 Forbidden**: Token valid, but user role is not permitted for the requested HTTP method and path in `permissions.json`.
- **404 Not Found**: Path does not match any registered route in `gateway.*.yaml`.
- **502 Bad Gateway**: Downstream target is unreachable or timed out.
