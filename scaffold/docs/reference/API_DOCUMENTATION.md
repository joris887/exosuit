# API Documentation

<!-- Template for documenting REST, GraphQL, or gRPC APIs -->
<!-- Replace placeholders with your project's specifics -->
<!-- Budget: keep under 200 lines (see documentation.md rule) -->

## Overview

- **Base URL:** `https://api.example.com/v1`
- **Protocol:** REST (JSON over HTTPS)
- **API Style:** <!-- REST | GraphQL | gRPC | WebSocket -->
- **Spec file:** <!-- e.g., openapi.yaml, schema.graphql, *.proto -->

## Authentication

<!-- How clients authenticate. Pick the relevant method. -->

| Method | Header/Field | Format |
|--------|-------------|--------|
| API Key | `X-API-Key` | `<key>` |
| Bearer Token | `Authorization` | `Bearer <token>` |
| OAuth2 | `Authorization` | `Bearer <access_token>` |

<!-- Token lifecycle: how to obtain, refresh, and revoke tokens -->

- **Obtain:** `POST /auth/token` with credentials
- **Refresh:** `POST /auth/refresh` with refresh token
- **Expiry:** <!-- e.g., 1 hour for access, 30 days for refresh -->

## Versioning

- **Strategy:** <!-- URL path (`/v1/`), header (`Accept-Version`), or query param (`?v=1`) -->
- **Current version:** v1
- **Deprecation policy:** <!-- e.g., previous version supported for 6 months after new release -->

## Endpoints

<!-- Group endpoints by resource. For each endpoint: method, path, description, auth requirement. -->

### Resource: [Name]

#### `GET /resource`

- **Description:** List all resources
- **Auth required:** Yes
- **Query parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 1 | Page number |
| `limit` | integer | No | 20 | Items per page (max 100) |
| `sort` | string | No | `created_at` | Sort field |
| `order` | string | No | `desc` | Sort direction: `asc` or `desc` |

- **Response:** `200 OK`

```json
{
  "data": [
    {
      "id": "abc123",
      "name": "Example",
      "created_at": "2025-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42
  }
}
```

#### `POST /resource`

- **Description:** Create a new resource
- **Auth required:** Yes
- **Request body:**

```json
{
  "name": "string (required)",
  "description": "string (optional)"
}
```

- **Response:** `201 Created`
- **Errors:** `400` (validation), `409` (conflict)

#### `GET /resource/:id`

- **Description:** Get a single resource by ID
- **Auth required:** Yes
- **Response:** `200 OK` (single object) or `404 Not Found`

#### `PUT /resource/:id`

- **Description:** Update a resource (full replacement)
- **Auth required:** Yes
- **Response:** `200 OK` or `404 Not Found`

#### `DELETE /resource/:id`

- **Description:** Delete a resource
- **Auth required:** Yes
- **Response:** `204 No Content` or `404 Not Found`

<!-- Copy the resource block above for each API resource -->

## Request/Response Conventions

### Content Type

- Request: `Content-Type: application/json`
- Response: `Content-Type: application/json`

### Pagination

- Cursor-based or offset-based (pick one and document it)
- Response includes `pagination` object with total count

### Filtering

<!-- Document your filtering convention, e.g.: -->
- `GET /resource?status=active&created_after=2025-01-01`

## Error Handling

All errors return a consistent JSON structure:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description",
    "details": [
      {
        "field": "name",
        "issue": "Required field missing"
      }
    ]
  }
}
```

### Error Codes

| HTTP Status | Code | Meaning |
|-------------|------|---------|
| 400 | `VALIDATION_ERROR` | Request body or parameters invalid |
| 401 | `UNAUTHORIZED` | Missing or invalid authentication |
| 403 | `FORBIDDEN` | Authenticated but not authorized |
| 404 | `NOT_FOUND` | Resource does not exist |
| 409 | `CONFLICT` | Resource state conflict (e.g., duplicate) |
| 422 | `UNPROCESSABLE` | Valid syntax but semantic error |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Server error (include request ID for support) |

## Rate Limiting

- **Default limit:** <!-- e.g., 100 requests per minute per API key -->
- **Headers returned:**

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Max requests per window |
| `X-RateLimit-Remaining` | Remaining requests in window |
| `X-RateLimit-Reset` | Unix timestamp when window resets |

- **Exceeded response:** `429 Too Many Requests`

## Webhooks

<!-- If applicable — document webhook events, payload format, and retry policy -->

- **Events:** <!-- e.g., resource.created, resource.updated, resource.deleted -->
- **Payload format:** Same as API response for the resource
- **Retry policy:** <!-- e.g., 3 retries with exponential backoff -->
- **Signature header:** <!-- e.g., X-Webhook-Signature using HMAC-SHA256 -->
