---
name: sync-system-context
description: >-
  Standard operating procedure to inspect code diffs and synchronize architectural documentation,
  data models, API contracts, and AGENTS.md context whenever backend features, schemas, or service boundaries are modified.
---

# Sync System Context Workflow

Use this skill whenever you complete a task that:
1. Adds or alters database schemas (GORM models, Prisma schemas, SQL migrations).
2. Adds, modifies, or deprecates HTTP endpoints or Gateway routing rules.
3. Implements or refactors a microservice (e.g., transition from skeleton to active service).
4. Changes inter-service communication contracts, headers, or environment variables.

---

## 1. Step-by-Step Procedure

### Step 1: Detect What Changed (Diff Inspection)
Run a status check or diff analysis across the modified directories:
- Check modified files or recent commits.
- Categorize changes into:
  - **Database & Persistence**: `schema.prisma`, `migrations/`, `internal/models/*.go`.
  - **API & Routing**: Controller/Handler endpoints, DTOs, Gateway `gateway.*.yaml`, `permissions.json`.
  - **Architecture / Boundaries**: New service created, new inter-service dependencies, event publishers.
  - **Environment & Config**: `.env.example`, port bindings, Docker Compose/K8s configs.

### Step 2: Context Mapping Matrix
Identify which documentation files MUST be updated according to the change type:

| Change Type | Primary Files to Update | Format / Details |
|---|---|---|
| **Database Schema** | `<service>/docs/data-model.md` | Table schemas, foreign keys, indexes, migration status |
| **API Endpoints** | `<service>/docs/api-contracts.md`, Gateway `permissions.json` | Method, path, headers required, request/response payload |
| **Service Status / Stack** | `<service>/AGENTS.md` & `docs/architecture.md` | Active ports, stack (Go/NestJS), implementation status |
| **Gateway Routing** | `music-api-gateway/docs/api-contracts.md` | Reverse proxy routes, RBAC matrix |
| **Shared Envelopes** | `music-common/docs/README.md` | Changes in response structures, shared constants |
| **Major Decision** | `docs/adrs/NNNN-<topic>.md` | Log Architecture Decision Records for significant changes |

### Step 3: Documentation Quality Standards (Prevent Context Bloat)
When updating context files, strictly observe these rules:
- **Concise & Scannable**: Use Markdown tables, bullet points, and Mermaid diagrams instead of long narrative paragraphs.
- **English Only**: All documentation must be 100% English.
- **Accurate Ground Truth**: Never document future assumptions as implemented. State clear statuses: `[Implemented]`, `[WIP]`, or `[Planned]`.
- **Single Source of Truth**: Link to active code files using standard relative links.

### Step 4: Verification
Confirm that:
1. `AGENTS.md` at service level and root accurately reflects what is currently running.
2. Any newly introduced endpoints conform to the unified envelope (`code`, `message`, `data`, `meta`).
3. Port mappings and environment configs match `.env.example`.
