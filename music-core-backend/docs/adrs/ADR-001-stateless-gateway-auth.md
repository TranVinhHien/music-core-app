# ADR-001: Stateless JWT Verification and Perimeter RBAC at API Gateway

## Status
Accepted

## Context
In a microservices architecture, authenticating requests and evaluating permissions on every downstream service can cause duplicate database calls, tight coupling to user databases, and latency spikes. We need an ingress mechanism that enforces security without centralizing database load at the edge.

## Decision
1. **Stateless JWT Verification**: The `music-api-gateway` verifies JWT Bearer tokens statelessly using a shared HMAC-SHA256 secret key (`token.secret`). No database queries are performed by the Gateway.
2. **Perimeter RBAC**: The Gateway reads user roles embedded in the JWT payload (`claims.UserRoles`) and evaluates access against a static policy matrix (`permissions.json`).
3. **Context Injection**: Upon authorization, the Gateway injects verified headers (`X-User-ID`, `X-User-Email`, `X-User-Roles`, `X-Request-ID`) into downstream HTTP requests. Downstream services trust these perimeter headers.

## Consequences
- **Positive**: Extremely low latency at Gateway; downstream services are relieved from token cryptographic verification; zero database dependency at the Gateway layer.
- **Negative**: Token revocation requires short expiration times or an external blacklist cache (e.g., Redis) if immediate revocation is required before token expiry.
