# ADR-002: Multi-Module Workspace Management using Go Workspaces (`go.work`)

## Status
Accepted

## Context
The repository manages multiple autonomous Go microservices alongside a shared module (`music-common`). Developing across multiple modules without Go workspaces requires publishing modules to remote Git repositories or maintaining fragile `replace` directives in each service's `go.mod`.

## Decision
Adopt native **Go Workspaces (`go.work`)** at the root of `music-core-backend`.
1. Every active microservice (`music-api-gateway`, `music-user-service`, `music-common`) is registered under the `use (...)` block.
2. Local changes in `music-common` are immediately available in downstream services during local development and builds without committing or tagging versions.
3. Makefile manages build and test targets using workspace resolution.

## Consequences
- **Positive**: Seamless local multi-module development; no temporary `replace` directives in version-controlled `go.mod` files; clean continuous integration.
- **Negative**: Requires modern Go tooling (`>= 1.18`, currently using `1.26.0`). Docker builds must include the shared `music-common` module in build contexts.
