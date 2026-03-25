# API Documentation

<!--
  TEMPLATE USAGE:
  - Fill in sections relevant to your API type (REST, GraphQL, gRPC, WebSocket, Event-Driven)
  - Delete sections marked "if applicable" that don't apply
  - JSON Schema is the universal type format — include it for every operation
  - For multi-API projects, create one file per API: API_[SERVICE].md

  DOCUMENTATION TIERS — what to include by audience:

  | Section           | Full (external)      | Standard (cross-team) | Lightweight (same-team) |
  |-------------------|----------------------|-----------------------|-------------------------|
  | Overview          | Detailed             | Brief                 | One line                |
  | Authentication    | Full tutorial        | Reference secrets mgr | Reference only          |
  | Operations        | Full + multi-example | Full + one example    | Schema + one example    |
  | Data Models       | JSON Schema + table  | JSON Schema           | Types may suffice       |
  | Error Handling    | Every code + fix     | Every code            | Non-obvious only        |
  | Rate Limiting     | Per-tier details     | If applicable         | Omit                    |
  | Pagination        | Full loop example    | Pattern reference     | Omit                    |
  | Versioning        | Full policy          | Policy reference      | Omit                    |
  | Events/Webhooks   | Full + signatures    | Full                  | Schema reference        |
  | Changelog         | Public, auto-gen     | Auto-generated        | Git history suffices    |
  | Contract Testing  | Consumer guides      | Pact/contract setup   | Optional                |
  | Owner/Contact     | Optional             | Team + on-call        | Team reference          |
  | ADRs              | N/A                  | Critical              | Critical                |

  FILE ORGANIZATION (for projects with API spec files):

  docs/api/                     # Use this structure when you have spec files
  ├── openapi.yaml              # OpenAPI spec (REST) — source of truth
  ├── asyncapi.yaml             # AsyncAPI spec (events/WebSocket)
  ├── schemas/                  # Shared JSON Schema (referenced by specs AND this doc)
  │   └── [domain-entity].json
  └── examples/                 # Tested example request/response pairs

  For single-API projects, keep the spec file at repo root and this doc here.
  Shared JSON Schema in schemas/ follows the DRY pattern — one schema definition
  referenced by OpenAPI, AsyncAPI, and this document to prevent drift.
-->

> **API Type:** <!-- REST | GraphQL | gRPC | WebSocket | Event-Driven | Hybrid -->
> **Spec Files:** <!-- `openapi.yaml` | `asyncapi.yaml` | `schema.graphql` | `service.proto` -->
> **Status:** <!-- Draft | Active | Deprecated | Sunset [DATE] -->
> **Doc Tier:** <!-- Full | Standard | Lightweight -->
> **Owner:** <!-- [Team/Person] | Contact: [Channel/Email] -->
> **Last Verified:** <!-- [DATE] — [How: CI pipeline | manual review] -->

## Overview

<!-- 2-3 sentences: What this API does, what problem it solves, who consumes it. -->

- **Base URL:** `https://api.example.com/v1`
- **Transport:** <!-- HTTPS | gRPC/HTTP2 | WebSocket | Kafka | [Protocol] -->
- **Content Type:** `application/json` <!-- or application/protobuf, etc. -->

### Key concepts

<!-- Define domain terms used throughout. Inconsistent terminology causes AI hallucination. -->

- **[Term]**: [Definition]. Maps to `field_name` in the API.

## Authentication

<!-- CRITICAL: First thing an AI agent needs to construct valid API calls. -->

- **Method:** <!-- Bearer Token | API Key | OAuth 2.0 | mTLS | None (internal) -->
- **Header:** <!-- `Authorization: Bearer <token>` | `X-API-Key: <key>` -->
- **Scopes:** <!-- List scopes with descriptions if OAuth. Omit if not applicable. -->

### Obtaining credentials

<!-- Step-by-step. For internal APIs, reference the secrets management system. -->

### Example authenticated request

```bash
curl -X GET "https://api.example.com/v1/resource" \
  -H "Authorization: Bearer sk_test_abc123" \
  -H "Content-Type: application/json"
```

## Operations

<!--
  Document each operation using the format below.
  Order by common workflow sequence (create → read → update → delete), not alphabetically.
  Include ONLY protocol rows that apply to your API type.
-->

### [Operation Name]

> [One sentence: what this operation does and when to use it]

| Property | Value |
|----------|-------|
| REST | `POST /v1/resources` |
| GraphQL | `mutation createResource(input: CreateResourceInput!): Resource!` |
| gRPC | `rpc CreateResource(CreateResourceRequest) returns (Resource)` |
| Event trigger | Emits `resource.created` on success |

<!-- Keep only the row(s) for your API type. -->

**Authorization:** <!-- Required scope or "None" -->

#### Parameters

| Name | Location | Type | Required | Default | Description |
|------|----------|------|----------|---------|-------------|
| `name` | body | `string` | Yes | — | Display name. 1-255 characters. |
| `workspace_id` | body | `string (uuid)` | Yes | — | Parent workspace. Must exist. |
| `metadata` | body | `object` | No | `{}` | Key-value pairs. Max 50 keys. |

<!-- Location: path | query | header | body. For GraphQL: "argument". For gRPC: "message field". -->

#### Input schema

```json
{
  "type": "object",
  "properties": {
    "name": { "type": "string", "minLength": 1, "maxLength": 255 },
    "workspace_id": { "type": "string", "format": "uuid" },
    "metadata": {
      "type": "object",
      "maxProperties": 50,
      "additionalProperties": { "type": "string" }
    }
  },
  "required": ["name", "workspace_id"],
  "additionalProperties": false
}
```

#### Example

```bash
curl -X POST "https://api.example.com/v1/resources" \
  -H "Authorization: Bearer sk_test_abc123" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Resource",
    "workspace_id": "ws_01H8MZXK9Q4D",
    "metadata": { "env": "production" }
  }'
```

#### Success response

**Status:** `201 Created`

```json
{
  "id": "res_01H8N2VX7Q3K",
  "name": "My Resource",
  "workspace_id": "ws_01H8MZXK9Q4D",
  "status": "active",
  "metadata": { "env": "production" },
  "created_at": "2026-03-23T10:30:00Z"
}
```

#### Error responses

| Scenario | Status | Error Code | Example Body |
|----------|--------|-----------|--------------|
| Name too long | 400 | `INVALID_PARAMETER` | `{"error":{"code":"INVALID_PARAMETER","message":"name must be 255 chars or fewer","details":{"field":"name"}}}` |
| Workspace not found | 404 | `RESOURCE_NOT_FOUND` | `{"error":{"code":"RESOURCE_NOT_FOUND","message":"Workspace ws_invalid not found"}}` |
| Duplicate name | 409 | `CONFLICT` | `{"error":{"code":"CONFLICT","message":"Resource already exists in workspace"}}` |

#### Side effects

<!-- What else happens when this operation succeeds. Omit if none. -->

- Emits `resource.created` event
- Increments workspace resource count

#### Constraints and edge cases

<!-- Business rules, idempotency, temporal constraints — things JSON Schema can't express. -->

- Resource names must be unique within a workspace
- NOT idempotent — use `Idempotency-Key` header to prevent duplicates
- `metadata` values are stored as strings; numeric values will be stringified

<!-- === Copy the operation block above for each operation === -->

## Data Models

<!-- JSON Schema definitions for domain entities. THE source of truth for AI type generation. -->

### [Model Name]

**Schema file:** `schemas/[model].json` <!-- if using shared schema files -->

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `string (uuid)` | Read-only | Unique identifier |
| `name` | `string` | Yes | Display name. 1-255 chars. |
| `status` | `enum: [active, archived]` | Yes | Lifecycle state |
| `created_at` | `string (date-time)` | Read-only | ISO 8601 timestamp |
| `metadata` | `object` | No | Key-value pairs. Max 50 keys. |

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid", "readOnly": true },
    "name": { "type": "string", "minLength": 1, "maxLength": 255 },
    "status": { "type": "string", "enum": ["active", "archived"] },
    "created_at": { "type": "string", "format": "date-time", "readOnly": true },
    "metadata": {
      "type": "object",
      "maxProperties": 50,
      "additionalProperties": { "type": "string" }
    }
  },
  "required": ["name", "status"]
}
```

## Error Handling

All errors return a consistent structure:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "No resource found with ID 'abc-123'",
    "status": 404,
    "details": {}
  }
}
```

### Error code reference

| HTTP Status | Error Code | Cause | Remediation |
|-------------|-----------|-------|-------------|
| 400 | `INVALID_PARAMETER` | Request fails validation | Check `details` for field-specific errors |
| 401 | `AUTHENTICATION_REQUIRED` | Missing or invalid auth token | Verify token is present and not expired |
| 403 | `INSUFFICIENT_PERMISSIONS` | Token lacks required scope | Request the needed scope |
| 404 | `RESOURCE_NOT_FOUND` | Entity doesn't exist or isn't accessible | Verify ID and access permissions |
| 409 | `CONFLICT` | Resource state prevents operation | Check current state before retrying |
| 422 | `UNPROCESSABLE` | Valid syntax but semantic error | Check business rule constraints |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests | Retry after `Retry-After` header seconds |
| 500 | `INTERNAL_ERROR` | Unexpected server error | Retry with exponential backoff |

## Rate Limiting

<!-- Omit for Lightweight tier internal APIs. -->

- **Default:** <!-- [N] requests per [period] per [scope] -->
- **Headers:** `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- **Exceeded:** Returns `429` with `Retry-After` header

## Pagination

<!-- Omit for Lightweight tier. Document the ONE pattern your API uses. -->

- **Pattern:** <!-- Cursor-based | Offset-based | Keyset -->
- **Parameters:** `cursor` (opaque string), `limit` (default: 20, max: 100)
- **Response:** `data[]`, `has_more`, `next_cursor`

### Pagination example

```bash
# First page
curl "https://api.example.com/v1/resources?limit=20"
# Next page (use next_cursor from previous response)
curl "https://api.example.com/v1/resources?limit=20&cursor=eyJpZCI6MTAwfQ"
```

## Versioning

<!-- Omit for Lightweight tier. -->

- **Strategy:** <!-- URL path (`/v1/`) | Header (`API-Version: 2026-03-01`) | Query param -->
- **Current version:** <!-- v1 -->
- **Deprecation policy:** <!-- [N] months notice, Sunset header -->
- **Breaking change definition:** <!-- Removing fields, changing types, removing endpoints -->

## Events and Webhooks

<!-- If applicable. Reference AsyncAPI spec file for event-driven APIs. -->

- **Spec file:** <!-- `asyncapi.yaml` -->
- **Transport:** <!-- WebSocket | Kafka | Webhook (HTTP POST) | SSE -->
- **Delivery:** <!-- At-least-once | Exactly-once -->
- **Signature:** <!-- HMAC-SHA256 via `X-Signature` header -->

### Event types

| Event | Trigger | Payload Schema |
|-------|---------|---------------|
| `resource.created` | New resource created | `schemas/events/resource-created.json` |
| `resource.updated` | Any field changed | `schemas/events/resource-updated.json` |

<!-- For WebSocket: document client→server and server→client message types separately. -->

## Contract Testing

<!--
  Aligns with TESTING_STRATEGY.md contract testing section.
  Both consumer and provider validate against the same contract (spec file).
-->

- **Contract source:** <!-- `openapi.yaml` | Pact Broker URL | shared types path -->
- **Provider verification:** Runs in CI on every merge to main
- **Consumer testing:** Validate requests/responses against the spec schema

### CI pipeline

<!-- Adapt to your tooling. See TESTING_STRATEGY.md for the full testing strategy. -->

```yaml
# Triggered on PRs modifying API-related files
lint:     redocly lint openapi.yaml        # or: buf lint, graphql-inspector
breaking: oasdiff breaking base head       # detect breaking changes
contract: dredd openapi.yaml $BASE_URL     # validate impl matches spec
# Optional: generate AI-optimized API summary (90%+ token reduction vs HTML)
# llms:   fern generate --llms-txt         # or custom script from spec → markdown
```

### Adding a consumer contract

1. Define the contract (OpenAPI, JSON Schema, Protocol Buffers, shared types)
2. Write tests on BOTH sides validating against the contract
3. Run in CI — schema changes that break either side fail the build
4. Update contract + both sides' tests in the same PR

## Changelog

<!-- Auto-generate from spec diffs (oasdiff) where possible. -->

### [DATE] — v[VERSION]

- **Breaking:** [Description with migration steps]
- **Added:** [New endpoints/fields]
- **Fixed:** [Bug fixes]
- **Deprecated:** [What and sunset date]

## Integration Checklist

<!-- For AI agents and developers verifying correct integration. -->

- [ ] Authentication configured and tested
- [ ] Error handling for all documented error codes
- [ ] Rate limiting respected with retry logic
- [ ] Pagination handled for list endpoints
- [ ] Webhook signature verification (if applicable)
- [ ] Contract tests added (if consumer)
