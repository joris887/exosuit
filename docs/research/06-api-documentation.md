# API documentation optimized for AI-assisted development

**The single most important finding: every undocumented endpoint, parameter, error code, and edge case is an opportunity for an AI model to hallucinate.** Documentation accuracy is not just a content quality problem — it is a hallucination prevention strategy. With **84% of developers** relying on technical documentation as their primary learning resource and AI coding assistants now generating a growing share of integration code, API documentation must serve two audiences simultaneously: humans who scan for intent and AI agents that parse for precision.

This report synthesizes research across industry-leading API docs, specification standards, AI consumption patterns, testing approaches, and internal documentation practices to propose a concrete, language-agnostic API documentation template for the JD-LLM Development Framework. The template uses **JSON Schema as the universal type lingua franca** (the canonical format for both Anthropic and OpenAI tool calling), structures content for optimal retrieval-augmented generation, and adapts gracefully across REST, GraphQL, gRPC, WebSocket, and event-driven APIs.

---

## 1. Executive summary of key findings

The research reveals a clear convergence: the best API documentation for AI-assisted development follows a **contract-first, schema-anchored, example-rich** approach. Stripe's documentation — universally regarded as the gold standard — succeeds because of structural decisions that happen to align perfectly with what AI agents need: every endpoint fully specified, code examples that actually work, error conditions exhaustively documented, and a single-page architecture that makes information retrieval deterministic.

Five core findings drive the template design:

- **JSON Schema is the universal type format for LLMs.** Both Anthropic and OpenAI use JSON Schema for tool/function calling. TypeScript types compiled to JSON Schema with validation feedback loops pushed API call accuracy from **6.75% to 100%** in the AutoBe benchmark. The template should embed JSON Schema for every request/response.
- **The llms.txt standard reduces token consumption by 90%+** compared to HTML. Adopted by Anthropic, Stripe, Cloudflare, and others, this Markdown-based format should be auto-generated from the template's structured content.
- **Examples are the #1 developer priority** (70% rank them first per SmartBear surveys), and Anthropic's `input_examples` feature confirms that examples demonstrating parameter combinations and edge cases dramatically improve AI tool selection accuracy.
- **No single specification covers all API types.** OpenAPI handles REST, AsyncAPI handles event-driven, GraphQL SDL handles GraphQL, and Protobuf handles gRPC. The template must provide a protocol-agnostic abstraction layer with protocol-specific annotation sections, using shared JSON Schema for data models.
- **Contract testing closes the documentation-reality gap.** Tools like Dredd, Schemathesis, Pact, and Spectral create a CI/CD pipeline where documentation is automatically verified against implementation, preventing the #1 developer complaint: outdated, inaccurate docs.

---

## 2. Per-topic detailed findings

### 2.1 What makes Stripe, Twilio, GitHub, and AWS docs effective

Stripe's three-column layout — persistent navigation, plain-English explanations, and copy-paste code — became the industry standard for a reason. Its **single-page infinite scroll** means any information is a Ctrl+F away, which is exactly how RAG systems retrieve documentation chunks. When logged in, code snippets are pre-populated with the developer's actual test API keys, reducing time-to-first-call to near zero. Most significantly for the JD-LLM context, Stripe recently added **"Copy for LLM"** and **"View as Markdown"** features, acknowledging that AI agents are now a primary documentation consumer.

Stripe's versioning model deserves special attention. Since 2011, every API version uses a **date-based identifier** (e.g., `2026-02-25.clover`). Developers pin versions via the `Stripe-Version` header, test newer versions without commitment, and roll back within 72 hours. The changelog is **programmatically generated** as services deploy. This pattern — machine-generated changelogs from spec diffs — is directly replicable in the JD-LLM template.

Twilio takes a **tutorial-first** approach, organizing docs around tasks ("Send messages," "Record a call") rather than endpoints. Research from the ACM (Meng et al., 2019) confirms this is optimal: developers split into "systematic" and "opportunistic" groups, with the majority jumping straight to code examples and skipping overviews. The lesson: **present conceptual information integrated with tasks, not in separate sections**.

GitHub uniquely documents **both REST and GraphQL APIs** coexisting. Their strategy: separate documentation linked by shared Node IDs, with a dedicated comparison page helping developers choose. They demonstrate that a single GraphQL query can replace 11+ REST API calls, giving consumers clear guidance on when each paradigm is appropriate. For GraphQL, docs are **auto-generated from the schema** with introspection, ensuring perpetual accuracy.

AWS provides the cautionary tale. Despite hundreds of thousands of documentation pages, their **cross-service inconsistency** — where `List` and `Describe` mean different things in different services, and response field naming varies unpredictably — creates enormous friction. AWS has recently structured content specifically for LLM consumption, recognizing that "many developers are learning AWS from AI tools." Their lesson: **consistency across the entire API surface matters more than depth on any single endpoint**.

Developer productivity data reinforces these patterns. Engineers spend **3–10 hours per week** searching for information that should be documented, which for a 100-person team equals **8–25 full-time engineers** worth of lost productivity. Companies with poor documentation take **18% longer** to release features. Codebases with high-quality documentation reduce defect rates by **21%** and increase productivity by **19%**.

### 2.2 API documentation formats and the multi-protocol challenge

**OpenAPI 3.1** achieved full JSON Schema 2020-12 alignment — the single biggest improvement over 3.0. This means type arrays (`type: [string, integer]`), nullable via union types, `$ref` with sibling keywords, and proper `examples` embedded in schemas all work natively. The new top-level `webhooks` object supports event documentation without tying it to callback operations, and `paths` is now optional, enabling webhook-only API descriptions. OpenAPI 4.0 "Moonwalk" is in development with no release date, aiming to describe all HTTP-based APIs including RPC-style, but explicitly not targeting non-HTTP protocols.

**AsyncAPI 3.1.0** is the de facto standard for event-driven API documentation, supporting **12+ protocols** through its bindings system: Kafka, AMQP/RabbitMQ, MQTT, WebSockets, HTTP (SSE/long polling), STOMP, IBM MQ, Amazon SNS, Google Cloud Pub/Sub, and others. It was intentionally modeled after OpenAPI, reusing structural concepts (info, servers, components, schemas). Critically, message payloads can use **the same JSON Schema** as OpenAPI documents, enabling shared data model definitions across synchronous and asynchronous APIs.

**GraphQL SDL** provides built-in documentation through triple-quoted string descriptions on types, fields, arguments, and enum values. The `@deprecated` directive with a `reason` argument handles versioning inline. Introspection queries (`__schema`, `__type`) power tools like GraphiQL, SpectaQL, and Apollo GraphOS Explorer. The key insight: GraphQL schemas are inherently self-documenting for structure, but teams still need supplementary docs for authentication flows, rate limiting (GitHub uses a point-based complexity system), and cross-cutting concerns.

**Protocol Buffers** for gRPC are inherently contract-first — you must write `.proto` files before implementation. The Buf ecosystem (buf lint, buf breaking, Buf Schema Registry) has become the modern standard, providing style enforcement, breaking change detection, auto-generated browsable documentation, and version diffing. Tools like `openapi2proto` can bridge gRPC and REST documentation.

The critical finding for the template: **no single specification covers all API types**, and the industry has converged on using the right spec for each protocol while sharing JSON Schema as the common data model layer. Platforms like Bump.sh and Postman provide unified portals rendering multiple spec formats, and Specmatic demonstrates a practical "DRY" pattern of defining shared JSON schemas referenced by both OpenAPI and AsyncAPI specs.

The contract-first vs. code-first comparison is decisive for AI-optimized documentation. Contract-first produces **significantly better documentation** because the spec is the documentation — no separate maintenance, machine-readable from day one, and CI/CD can enforce compliance. Code-first documentation tends to be an afterthought and is prone to staleness. For the JD-LLM Framework, **contract-first is the clear recommendation**, with the specification file serving as both the source of truth and the AI-readable reference.

### 2.3 Documentation sections ranked by developer impact

SmartBear's survey of 3,500+ respondents provides the most direct ranking of what developers consult most: **examples (70%)**, status and errors (51%), authentication (50%), and error messages (49%). The Postman State of API reports (5,600+ respondents) confirm that **39% cite inconsistent documentation** as their biggest roadblock and **44% resort to reading source code** rather than trusting docs.

The "Minimum Viable Documentation" framework identifies exactly three required documents: an **API reference** (complete catalog of operations with schemas and examples), a **quickstart guide** (shortest path to a meaningful task), and an **overview** (what the API does and why). Everything else is additive.

For the template, sections tier as follows. **Tier 1 (essential at launch):** authentication/authorization, endpoint/operation reference, error handling with specific codes and remediation, code examples in 3+ formats (cURL, language-specific, and AI-friendly JSON Schema), and a quickstart guide. **Tier 2 (high priority):** rate limiting, pagination patterns, versioning strategy, SDK references, and changelog. **Tier 3 (maturity indicators):** webhooks/events documentation, migration guides, and architecture overviews.

### 2.4 How AI agents consume API documentation

This is the most consequential finding for the template design. The **llms.txt standard**, proposed by Jeremy Howard in September 2024, places a Markdown file at `/llms.txt` (analogous to `robots.txt`) with structured content sections and page links. A companion `/llms-full.txt` combines entire documentation into a single file. Platforms including Fern, Mintlify, and GitBook now auto-generate these files, and adopters include Anthropic, Stripe, Cloudflare, and Zapier. Fern reports **90%+ token consumption reduction** compared to HTML.

Both Anthropic and OpenAI use **JSON Schema** as the canonical format for tool/function definitions. Anthropic's tool definition format includes `name`, `description`, and `input_schema` (a JSON Schema object), with an optional `strict: true` mode guaranteeing schema validation. The November 2025 `input_examples` feature was explicitly designed because "JSON schemas define what's structurally valid, but can't express usage patterns."

The **Typia library** demonstrated a breakthrough finding: raw LLM function calling on complex TypeScript compiler AST types succeeded only **6.75%** of the time. With a validation feedback loop — letting the LLM construct arguments, validating against compiled TypeScript types, reporting detailed errors back — success reached **100%** within 1–2 feedback cycles. This argues strongly for the template including both the JSON Schema definition and explicit validation rules with descriptive error messages.

Research benchmarks confirm the challenge and the solutions. The **Gorilla benchmark** (UC Berkeley, NeurIPS 2024) showed GPT-4 struggles with accurate API calls due to hallucinated parameters, but Retriever-Aware Training significantly mitigated hallucination. The **Berkeley Function Calling Leaderboard** tests across 2K question-function-answer pairs and recommends fewer than 100 tools and fewer than 20 arguments per tool for reliable performance. Anthropic's **Tool Search Tool** improved accuracy from 49% to 74% by discovering tools on-demand rather than loading all upfront — meaning documentation should support progressive disclosure rather than dumping everything at once.

Practical hallucination prevention strategies for the template: document every endpoint, parameter, error code, and edge case (undocumented features are hallucination opportunities); use one clear topic per documentation page with descriptive headings (improves RAG retrieval); provide explicit constraints and limitations (what the API does NOT support); and maintain consistent terminology throughout (AI struggles with semantic drift and coreference).

### 2.5 Living documentation and contract testing

The doc-as-tests ecosystem provides the tooling to keep the template accurate. **Dredd** validates API description documents against backend implementations by reading OpenAPI specs, sending requests, and validating responses match documented schemas. **Schemathesis** generates property-based tests from OpenAPI or GraphQL schemas, finding 5–15 real bugs on first run through fuzzing. Together, they cover both spec compliance (Dredd) and robustness (Schemathesis).

For contract testing, **Pact** (consumer-driven, truly language-agnostic with support for Java, JavaScript, Ruby, Python, Go, Rust, C++, .NET, Swift) is the strongest choice for polyglot environments. The Pact Broker enables cross-team contract sharing and auto-generates network diagrams. **Spring Cloud Contract** is optimal for JVM-heavy teams.

The SDK generation landscape has matured significantly. **Fern** (acquired by Postman) generates clean, idiomatic SDKs in 9 languages from a single source and syncs documentation with SDKs — ensuring docs and client libraries never diverge. **Speakeasy** is OpenAPI-native with MCP server generation capabilities. **OpenAPI Generator** provides the broadest language coverage (50+ targets) but with inconsistent output quality.

The recommended CI/CD pipeline: **Lint** (Spectral or Redocly CLI) → **Validate** (spec validity check) → **Contract Test** (Dredd/Schemathesis) → **Generate** (auto-build docs and SDKs) → **Diff** (oasdiff for breaking change detection). This pipeline should run on every PR that touches API-related files.

### 2.6 Internal APIs require different documentation depth

Internal API documentation can be significantly more streamlined because the audience shares domain context, technical vocabulary, and access to the team that built it. However, internal APIs are **commonly under-documented**, creating scaling problems when multiple teams depend on undocumented contracts.

Amazon's 2002 "API Mandate" — requiring all teams to document APIs as if they would be externalized — drove documentation quality. Netflix uses a federated platform console built on Backstage with GraphQL Federation. Google uses Protocol Buffers as the source of truth for internal service definitions.

The decision framework: **full documentation** when the API is consumed by more than 2 teams, has complex state machines, involves business-critical operations, or will be consumed by AI agents. **Lightweight documentation** (OpenAPI spec + README + ADRs) when consumed by the same team, simple CRUD with clear naming, or strongly typed with self-descriptive types. **Types only** when prototyping or when the API is internal utility within the same team.

Architecture Decision Records (ADRs) are the most impactful lightweight practice for internal APIs. They preserve the "why" behind decisions — context that code cannot express and that dramatically improves AI coding assistant output. The code shows what exists, git history shows when it changed, but the **why** lives in ADRs.

For AI consumption of internal APIs, the minimum viable documentation is: endpoint URL + HTTP method, authentication scheme, required parameters with types, clear natural language description, error response schemas, and at least one working code example per endpoint. Without these, AI agents should follow a **fail-closed policy** and refuse to attempt the call.

---

## 3. Recommended template structure

The following template structure is designed for maximum AI utility while remaining human-readable. Each section is justified by research findings.

### 3.1 File organization

```
docs/api/
├── API.md                    # Main API document (this template)
├── openapi.yaml              # OpenAPI spec (REST endpoints)
├── asyncapi.yaml             # AsyncAPI spec (events/WebSocket)
├── schema.graphql            # GraphQL SDL (if applicable)
├── service.proto             # Protobuf definitions (if applicable)
├── schemas/                  # Shared JSON Schema definitions
│   ├── common.json
│   └── [domain-entity].json
├── examples/                 # Tested example request/response pairs
│   └── [operation-name]/
│       ├── request.json
│       └── response.json
├── adr/                      # Architecture Decision Records
│   └── 001-[decision].md
├── llms.txt                  # Auto-generated AI-optimized index
└── llms-full.txt             # Auto-generated full doc for AI consumption
```

**Justification:** Separating machine-readable specs from human-readable documentation allows both audiences to be served optimally. Shared JSON Schema definitions in `/schemas/` follow the Specmatic DRY pattern — referenced by both OpenAPI and AsyncAPI specs to prevent drift. The `llms.txt` files are auto-generated for AI consumption (90%+ token reduction). ADRs preserve decision rationale that dramatically improves AI code generation.

### 3.2 API.md template sections and ordering

```markdown
# [API Name] API Documentation

> **API Type:** REST | GraphQL | gRPC | WebSocket | Event-Driven | Hybrid
> **Spec Files:** `openapi.yaml` | `asyncapi.yaml` | `schema.graphql` | `service.proto`
> **Status:** Draft | Active | Deprecated | Sunset [DATE]
> **Owner:** [Team/Person] | **Contact:** [Channel/Email]
> **Last Verified:** [DATE] — [How: CI pipeline / manual review]

## Overview

[2-3 sentences: What this API does, what problem it solves, and who consumes it.]

**Base URL:** `https://api.example.com/v1`
**Authentication:** [Method] — see Authentication section
**Transport:** HTTPS | gRPC/HTTP2 | WebSocket | [Protocol]

### Key concepts

[Define domain-specific terms used throughout. AI agents need unambiguous 
terminology — inconsistent naming causes hallucination. Use a definition 
list format.]

- **Workspace**: A top-level container for projects. Maps to `workspace_id`.
- **Task**: An assignable unit of work within a project.

## Authentication

[CRITICAL for AI: This is the first thing an AI agent needs to construct 
valid API calls. Include the exact mechanism, header format, and a working 
example.]

**Method:** Bearer Token | API Key | OAuth 2.0 | mTLS
**Header:** `Authorization: Bearer <token>`
**Scopes:** [List scopes with descriptions if OAuth]

### Obtaining credentials
[Step-by-step for getting valid credentials. For internal APIs, reference 
the secrets management system.]

### Example authenticated request
```bash
curl -X GET "https://api.example.com/v1/resource" \
  -H "Authorization: Bearer sk_test_abc123" \
  -H "Content-Type: application/json"
```

## Operations

[This is the core reference section. Each operation follows the format 
defined in Section 4 below. Order operations by common workflow sequence, 
not alphabetically — this matches how developers and AI agents encounter 
them.]

### [Operation: Create Resource]
[See Section 4 for the detailed endpoint documentation format]

### [Operation: List Resources]
...

## Data models

[JSON Schema definitions for all domain entities. This section is THE 
source of truth for AI type generation. Include the schema inline AND 
reference the file path.]

### Resource

**Schema:** `schemas/resource.json`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `string (uuid)` | Read-only | Unique identifier |
| `name` | `string` | Yes | Display name. 1-255 chars. |
| `status` | `enum: [active, archived]` | Yes | Current lifecycle state |
| `created_at` | `string (date-time)` | Read-only | ISO 8601 timestamp |
| `metadata` | `object` | No | Arbitrary key-value pairs. Max 50 keys. |

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

## Error handling

[Exhaustive error documentation prevents the most common AI hallucination: 
generating code that doesn't handle errors correctly. List EVERY error code 
with cause and remediation.]

### Error response format
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "No resource found with ID 'abc-123'",
    "status": 404,
    "details": { "resource_type": "workspace", "resource_id": "abc-123" }
  }
}
```

### Error code reference

| HTTP Status | Error Code | Cause | Remediation |
|-------------|-----------|-------|-------------|
| 400 | `INVALID_PARAMETER` | Request parameter fails validation | Check the `details` field for specific parameter errors |
| 401 | `AUTHENTICATION_REQUIRED` | Missing or invalid auth token | Verify token is present and not expired |
| 403 | `INSUFFICIENT_PERMISSIONS` | Token lacks required scope | Request the `[scope]` scope |
| 404 | `RESOURCE_NOT_FOUND` | Entity does not exist or is not accessible | Verify the ID and your access permissions |
| 409 | `CONFLICT` | Resource state prevents operation | Check current state before retrying |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests | Retry after `Retry-After` header seconds |
| 500 | `INTERNAL_ERROR` | Unexpected server error | Retry with exponential backoff; contact support if persistent |

## Rate limiting

**Default:** [N] requests per [period] per [scope]
**Headers:** `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
**Exceeded behavior:** Returns 429 with `Retry-After` header

[For GraphQL: Document point-based complexity system if applicable]

## Pagination

**Pattern:** Cursor-based | Offset-based | Keyset
**Parameters:** `cursor` (opaque string), `limit` (default: 20, max: 100)
**Response fields:** `data[]`, `has_more`, `next_cursor`

### Example
[Include a complete pagination loop example — AI agents frequently 
get pagination wrong without explicit iteration examples.]

## Versioning

**Strategy:** URL path (`/v1/`) | Header (`API-Version: 2026-03-01`) | Query param
**Current version:** [version]
**Deprecation policy:** [N months notice, Sunset header]
**Breaking change definition:** [What constitutes a breaking change]

## Events and webhooks

[For event-driven APIs. Reference the AsyncAPI spec file.]

**Spec file:** `asyncapi.yaml`
**Transport:** WebSocket | Kafka | Webhook (HTTP POST)
**Signature verification:** HMAC-SHA256 using `X-Signature` header

### Event types

| Event | Trigger | Payload Schema |
|-------|---------|---------------|
| `resource.created` | New resource created | `schemas/events/resource-created.json` |
| `resource.updated` | Any field changed | `schemas/events/resource-updated.json` |

## Changelog

[Auto-generated from spec diffs where possible. Use oasdiff or similar.]

### [DATE] — v[VERSION]
- **Breaking:** [Description with migration steps]
- **Added:** [New endpoints/fields]
- **Fixed:** [Bug fixes]
- **Deprecated:** [What's deprecated and sunset date]

## Contract testing

[How consumers can verify their integration. Reference Pact broker 
or contract testing setup.]

**Consumer contract location:** [Pact Broker URL / repo path]
**Provider verification:** Runs in CI on every merge to main
**How to add a new consumer contract:** [Steps]

## Appendix: Integration checklist

[Checklist for AI agents and developers to verify correct integration]

- [ ] Authentication configured and tested
- [ ] Error handling implemented for all documented error codes
- [ ] Rate limiting respected with retry logic
- [ ] Pagination handled for list endpoints
- [ ] Webhook signature verification implemented (if applicable)
- [ ] Contract tests added (if consumer)
```

**Justification for section ordering:** Authentication first (required for any API call), then operations (the core reference), then data models (needed to understand operations), then error handling (needed for robust implementations), then cross-cutting concerns (rate limiting, pagination, versioning), then events/webhooks (supplementary), then changelog and testing. This matches the developer workflow sequence and ensures AI agents encounter critical context before operation details.

### 3.3 Sections to include/exclude by context

| Section | External API | Internal API (cross-team) | Internal API (same team) |
|---------|-------------|---------------------------|--------------------------|
| Overview | ✅ Detailed | ✅ Brief | ✅ One line |
| Authentication | ✅ Full tutorial | ✅ Reference secrets system | ✅ Reference only |
| Operations | ✅ Full examples | ✅ Full examples | ✅ Schema + one example |
| Data models | ✅ JSON Schema + table | ✅ JSON Schema | ✅ Types may suffice |
| Error handling | ✅ Every code with remediation | ✅ Every code | ✅ Non-obvious errors only |
| Rate limiting | ✅ Per-tier details | ✅ If applicable | Optional |
| Pagination | ✅ Full iteration example | ✅ Pattern reference | Optional |
| Versioning | ✅ Full policy + migration | ✅ Policy reference | Optional |
| Events/Webhooks | ✅ Full with signatures | ✅ Full | ✅ Schema reference |
| Changelog | ✅ Public, auto-generated | ✅ Auto-generated | Git history may suffice |
| Contract testing | ✅ Consumer guides | ✅ Pact/contract setup | Optional |
| SLAs/Pricing | ✅ | ❌ | ❌ |
| Owner/Contact | Optional | ✅ Team + on-call | ✅ Team reference |
| ADRs | ❌ | ✅ Critical | ✅ Critical |
| Deployment info | ❌ | ✅ | ✅ |

---

## 4. Recommended endpoint documentation format

This format adapts across REST, GraphQL, gRPC, and event-driven APIs through a protocol-agnostic core with protocol-specific annotations.

### 4.1 Universal operation format

```markdown
### [Operation Name]

> [One sentence: what this operation does and when to use it]

**Protocol details:**

| Property | Value |
|----------|-------|
| REST | `POST /v1/resources` |
| GraphQL | `mutation createResource(input: CreateResourceInput!): Resource!` |
| gRPC | `rpc CreateResource(CreateResourceRequest) returns (Resource)` |
| Event trigger | Emits `resource.created` on success |

[Include ONLY the rows applicable to your API type. Most APIs will 
have just one row.]

**Authorization:** Requires `resources:write` scope

#### Parameters / Input

| Name | Location | Type | Required | Default | Description |
|------|----------|------|----------|---------|-------------|
| `name` | body | `string` | Yes | — | Display name. 1-255 characters. |
| `workspace_id` | body | `string (uuid)` | Yes | — | Parent workspace. Must exist and be accessible. |
| `metadata` | body | `object` | No | `{}` | Key-value pairs. Max 50 keys, string values only. |

[For GraphQL: use "argument" instead of "location". For gRPC: reference 
the message type. For events: document the channel/topic and message format.]

#### Input JSON Schema

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

#### Example request

```bash
# REST
curl -X POST "https://api.example.com/v1/resources" \
  -H "Authorization: Bearer sk_test_abc123" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Resource",
    "workspace_id": "ws_01H8MZXK9Q4D",
    "metadata": { "env": "production" }
  }'
```

```graphql
# GraphQL
mutation {
  createResource(input: {
    name: "My Resource"
    workspaceId: "ws_01H8MZXK9Q4D"
    metadata: { env: "production" }
  }) {
    id
    name
    status
    createdAt
  }
}
```

```protobuf
// gRPC (conceptual — actual call via generated client)
CreateResourceRequest {
  name: "My Resource"
  workspace_id: "ws_01H8MZXK9Q4D"
  metadata: { "env": "production" }
}
```

#### Success response

**Status:** `201 Created` (REST) | Data return (GraphQL/gRPC)

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

| Scenario | Status | Error Code | Response Body |
|----------|--------|-----------|---------------|
| Name too long | 400 | `INVALID_PARAMETER` | `{"error":{"code":"INVALID_PARAMETER","message":"name must be 255 chars or fewer","details":{"field":"name","max_length":255}}}` |
| Workspace not found | 404 | `RESOURCE_NOT_FOUND` | `{"error":{"code":"RESOURCE_NOT_FOUND","message":"Workspace ws_invalid not found"}}` |
| Duplicate name in workspace | 409 | `CONFLICT` | `{"error":{"code":"CONFLICT","message":"Resource 'My Resource' already exists in this workspace"}}` |

#### Side effects

- Emits `resource.created` event (see Events section)
- Increments workspace resource count
- Triggers webhook notifications to subscribed endpoints

#### Constraints and edge cases

- Resource names must be unique within a workspace
- Maximum 1,000 resources per workspace
- `metadata` values are stored as strings; numeric values will be stringified
- This operation is NOT idempotent — repeated calls create duplicate resources. 
  Use `Idempotency-Key` header to prevent duplicates.
```

**Justification for this format:** The parameter table provides human scannability, the JSON Schema provides machine precision for AI agents, the example request provides copy-paste implementation, the error responses prevent AI from generating happy-path-only code, the side effects prevent AI from missing downstream consequences, and the constraints/edge cases section prevents AI from making incorrect assumptions. The "Constraints and edge cases" section is particularly important — it captures information that cannot be expressed in JSON Schema alone (business rules, temporal constraints, idempotency behavior).

### 4.2 Protocol-specific adaptations

**For REST APIs:** Include HTTP method, URL path, query parameters with location indicators, request/response headers, and status codes. The format above is natively REST.

**For GraphQL APIs:** Replace the parameter table with argument documentation. Include the full SDL type definition instead of JSON Schema (or include both). Show the query/mutation with realistic field selections. Document resolver-specific behaviors like N+1 query patterns or dataloader batching.

**For gRPC APIs:** Reference the `.proto` service/method definition. Include the full message type definitions. Document streaming behavior (unary, server streaming, client streaming, bidirectional) with explicit lifecycle examples. Note deadline/timeout recommendations.

**For Event-Driven APIs:** Replace "request/response" with "publish/subscribe." Document the channel/topic name, message format with JSON Schema, delivery guarantees (at-least-once, exactly-once), ordering guarantees, retry policy, and dead letter handling. Include a subscription example showing how to connect and consume events.

**For WebSocket APIs:** Document the connection URL, handshake parameters, message frame format (text/binary), heartbeat/ping-pong behavior, reconnection strategy, and the full message type catalog for both client→server and server→client directions.

---

## 5. Internal vs. external APIs within a single template

The template uses a **progressive disclosure model** rather than separate templates. A single `API.md` file contains all sections, with clear markers indicating which sections are required at each documentation tier.

### Three documentation tiers

**Tier 1 — Full (external and cross-org APIs):** Every section populated, JSON Schema for all models, multiple code examples per operation, exhaustive error documentation, rate limiting details, pagination examples, versioning policy, migration guides, and consumer onboarding guides.

**Tier 2 — Standard (cross-team internal APIs):** Overview, authentication reference, all operations with schemas and one example each, error codes, events/webhooks if applicable, ADRs for design decisions, and contract testing setup. Rate limiting and pagination documented only if non-obvious. Changelog auto-generated from spec diffs.

**Tier 3 — Lightweight (same-team internal APIs):** One-line overview, authentication reference, OpenAPI/Protobuf spec file as the primary documentation, ADRs for non-obvious decisions. Strong type definitions (TypeScript interfaces, Rust traits, Go interfaces) may substitute for the Data Models section when property names are self-descriptive and types are precise. The spec file plus a README with key workflows may be the entire documentation.

### When types alone are sufficient

Research confirms types serve as adequate documentation when: property names are descriptive (`maxRetryCount: number` not `n: number`), types are precise (discriminated unions, branded types, enums rather than raw `string`), the domain is simple and well-understood by the team, and behavior is obvious from the signature alone. Types are **never sufficient** when the API has business rules and invariants, temporal constraints ("must be called before initialize()"), side effects, performance characteristics, error semantics beyond type information, or concurrency behavior. **For AI consumption, explicit natural language descriptions are always needed** even when types are strong, because AI agents cannot infer intent from types alone.

### The "Bezos Rule" for internal APIs

Amazon's API Mandate required all internal APIs to be documented as if they would be externalized. The template supports this through a `Status` field that can be set to `internal-lightweight`, `internal-standard`, or `external`. When promoting an internal API to external, the template's section headers serve as an explicit checklist of what documentation needs to be added — the gaps are immediately visible.

---

## 6. Tool recommendations

### Specification authoring and design

| Tool | Purpose | Best For |
|------|---------|----------|
| **Redocly CLI** | OpenAPI + AsyncAPI linting, bundling, building docs | All-in-one spec toolchain; supports OpenAPI 3.2 |
| **Spectral** (Stoplight) | Extensible JSON/YAML linting with custom rules | Teams needing highly customized linting rules |
| **Buf** | Protobuf linting, breaking change detection, registry | gRPC/Protobuf-heavy projects |
| **Apollo GraphOS** | GraphQL schema registry, field analytics, composition | GraphQL Federation environments |

### Documentation generation

| Tool | Purpose | Best For |
|------|---------|----------|
| **Fern** | Docs + SDK generation from OpenAPI/custom DSL | Synced docs and SDKs; acquired by Postman |
| **Redoc** | Beautiful OpenAPI documentation rendering | Static, clean REST API reference docs |
| **SpectaQL** | Static HTML generation from GraphQL introspection | GraphQL API reference documentation |
| **protoc-gen-doc** / **Buf BSR** | Documentation from `.proto` files | gRPC service documentation |

### Contract testing and validation

| Tool | Purpose | Best For |
|------|---------|----------|
| **Pact** | Consumer-driven contract testing (10+ languages) | Polyglot microservice environments |
| **Dredd** | Validates implementation matches OpenAPI spec | Ensuring docs match reality |
| **Schemathesis** | Property-based API fuzzing from OpenAPI/GraphQL | Finding edge cases and security issues |
| **oasdiff** | OpenAPI version comparison and breaking change detection | Automated changelog generation |
| **Redocly Respect** | Contract testing using Arazzo workflows | OpenAPI-driven acceptance testing |

### SDK generation

| Tool | Languages | Best For |
|------|-----------|----------|
| **Fern** | 9 languages (TS, Python, Go, Java, C#, Ruby, Swift, PHP, Rust) | Production quality + synced docs |
| **Speakeasy** | 10 languages | OpenAPI-native with MCP server generation |
| **OpenAPI Generator** | 50+ targets | Maximum language coverage (quality varies) |
| **Stainless** | Multiple | Production-ready SDKs; used by OpenAI |

### AI-specific tooling

| Tool | Purpose | Best For |
|------|---------|----------|
| **llms.txt generation** (Fern/Mintlify) | Auto-generate AI-optimized Markdown from specs | Making docs AI-consumable |
| **MCP server** (Speakeasy/custom) | Expose API operations as AI-callable tools | Direct AI agent integration |
| **Typia** (TypeScript) | Compile TS types to JSON Schema with validation | Maximizing LLM function calling accuracy |

### Recommended CI/CD pipeline

```yaml
# Triggered on PRs modifying api/ or openapi.yaml
steps:
  1. Lint:        redocly lint openapi.yaml --config=strict
  2. Validate:    redocly bundle openapi.yaml  # validates + bundles
  3. Breaking:    oasdiff breaking base.yaml head.yaml --fail-on=ERR
  4. Contract:    dredd openapi.yaml http://localhost:3000
  5. Fuzz:        schemathesis run openapi.yaml --base-url=http://localhost:3000
  6. Generate:    fern generate --docs --sdks
  7. LLMs:        generate-llms-txt openapi.yaml > docs/llms.txt
  8. Publish:     deploy docs + SDKs + Pact contracts
```

---

## 7. Knowledge gaps and areas requiring experimentation

**LLM accuracy across documentation formats lacks controlled studies.** While the Typia benchmark (6.75% → 100%) and Gorilla/ToolBench results are suggestive, no controlled experiment has compared LLM API integration accuracy across documentation formats (Markdown table vs. JSON Schema vs. TypeScript types vs. annotated examples) holding all other variables constant. The JD-LLM Framework should consider running its own A/B tests with Claude Code across different documentation formats to establish empirical baselines.

**Multi-protocol documentation unification has no proven template.** The template proposed here is informed by research but has not been validated at scale. No organization has published a case study of successfully documenting REST, GraphQL, gRPC, and event-driven APIs in a single unified template for AI consumption. This is uncharted territory requiring iterative refinement.

**Optimal documentation chunk size for RAG is unclear.** While llms.txt addresses the "full document" use case, the optimal granularity for chunking API documentation for retrieval-augmented generation (one page per endpoint vs. grouped by resource vs. full API in one document) has not been systematically studied. Different AI tools may perform differently — Claude Code's extended thinking window may prefer larger chunks while Copilot's inline completion may prefer smaller ones.

**Event-driven API documentation for AI is immature.** Most AI coding assistant research focuses on REST APIs. How AI agents should consume AsyncAPI specifications, construct WebSocket connections, or implement event handlers from documentation is largely unexplored. The template's event documentation section is based on REST documentation principles extrapolated to async patterns, not on empirical evidence of what works for AI consumers.

**Validation feedback loop integration needs design.** Typia's validation feedback approach (schema → attempt → validate → error feedback → retry) achieved 100% accuracy, but integrating this into a documentation template workflow (where the documentation itself provides the validation schemas and error message templates) has not been formalized. This is a high-value area for the JD-LLM Framework to pioneer.

**Internal API documentation thresholds are subjective.** The three-tier model (Full / Standard / Lightweight) is based on practitioner consensus rather than empirical measurement. The question of exactly when types alone are sufficient vs. when explicit documentation is needed for AI consumption likely depends on the specific AI model, the complexity of the domain, and the quality of the type definitions. Establishing concrete heuristics (e.g., "if the type has more than N fields or any field with non-obvious semantics, add explicit documentation") would require controlled experimentation.

**llms.txt is early and may evolve.** The standard is only ~18 months old, with no formal governance body. Its long-term trajectory — whether it becomes an IETF RFC, gets absorbed into MCP, or is superseded by something else — is uncertain. The template should generate llms.txt as one output format but not depend on it as the sole AI consumption mechanism.

**MCP server generation from documentation is emerging.** Speakeasy can generate MCP servers from OpenAPI specs, and GitBook auto-exposes MCP servers for published spaces, but the quality and reliability of AI interactions through auto-generated MCP servers vs. purpose-built ones has not been benchmarked. This is a rapidly evolving space worth monitoring quarterly.