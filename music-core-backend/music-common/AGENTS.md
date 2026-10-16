---
trigger: model_decision
description: "Guidelines and rules for the shared foundational library module music-common."
---

# Agent Guidelines - Music Common Library

## 1. Module Responsibility

### What it does
- **Single Source of Shared Code**: Provides cross-service data types, generic response envelopes, pagination structures, canonical header constants, and reusable HTTP clients.
- **Pure Library Package**: Exclusively exports reusable Go packages. Contains zero business logic, zero runnable main daemons, and zero database connections.

### What it does NOT do
- No executable main entry points (`cmd/` does not exist here).
- No direct database schema definitions or migrations.
- No service-specific business rules.

---

## 2. Package Catalog

- **`constants`**: Centralized HTTP header names (`HeaderUserID`, `HeaderRequestID`, `HeaderUserRoles`, etc.) and context keys.
- **`response`**: Standardized JSON envelopes (`Response[T]`, `AnyResponse`) and helper response functions.
- **`pagination`**: Unified pagination metadata and request parameter parsers.
- **`httpclient`**: Resilient internal HTTP client with timeout and header injection capabilities.
- **`middleware`**: Shared Gin middleware functions.

---

## 3. Implementation Rules

1. **Zero External Service Dependencies**: `music-common` must never import packages from any microservice (`music-api-gateway`, `music-user-service`, etc.).
2. **Backward Compatibility**: Any change to struct fields in `response` or `constants` affects all services simultaneously. Keep changes strictly additive.
3. **Run Tests**: Always run `go test ./...` in `music-common` before committing modifications.
