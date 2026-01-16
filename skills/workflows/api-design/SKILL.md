---
name: api-design
description: |
  API design patterns and best practices for REST, GraphQL, and gRPC. Use when:
  - Designing new REST, GraphQL, or gRPC APIs
  - Reviewing or creating OpenAPI/Swagger specifications
  - Implementing API versioning or deprecation strategies
  - Designing pagination, filtering, or error responses
  - Working with HTTP status codes or API authentication
  Trigger phrases: API design, REST endpoint, GraphQL schema, OpenAPI, swagger, gRPC, API versioning, HTTP status code, pagination, error response
allowed-tools: Read, Glob, Grep, Write, Edit
model: sonnet
user-invocable: true
---

# API Design

Stack-agnostic patterns for designing consistent, maintainable APIs.

## Design Principles

### 1. Contract-First Design

Always define the API contract before implementation:

```yaml
# OpenAPI for REST
openapi: 3.1.0
info:
  title: User Service API
  version: 1.0.0

# GraphQL SDL
type Query {
  user(id: ID!): User
}

# Protocol Buffers for gRPC
service UserService {
  rpc GetUser (GetUserRequest) returns (User);
}
```

### 2. Consistency

| Aspect | Standard |
|--------|----------|
| Naming | Use consistent case (snake_case or camelCase) |
| Errors | Uniform error response format |
| Pagination | Same pattern across all list endpoints |
| Versioning | Single versioning strategy |

## REST API Design

### Resource Naming

```
# Good - Noun, plural, lowercase
GET    /users
GET    /users/{id}
POST   /users
PUT    /users/{id}
DELETE /users/{id}

# Nested resources
GET    /users/{id}/posts
POST   /users/{id}/posts

# Actions (when needed)
POST   /users/{id}/activate
POST   /orders/{id}/cancel

# Bad examples
GET    /getUsers          # Verb in URL
GET    /user_list         # Singular, underscore
POST   /createUser        # Verb, not RESTful
```

### HTTP Status Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 200 | OK | Successful GET, PUT |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Missing/invalid auth |
| 403 | Forbidden | Valid auth, no permission |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate, state conflict |
| 422 | Unprocessable | Business logic error |
| 429 | Too Many Requests | Rate limited |
| 500 | Server Error | Unexpected error |

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request contains invalid data",
    "details": [
      {
        "field": "email",
        "code": "INVALID_FORMAT",
        "message": "Must be a valid email address"
      }
    ],
    "requestId": "req_abc123",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

### Pagination

```json
// Cursor-based (preferred for large datasets)
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTAwfQ==",
    "has_more": true
  }
}

// Offset-based
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

### Filtering and Sorting

```bash
# Filtering
GET /users?status=active&role=admin

# Sorting
GET /users?sort=created_at:desc,name:asc

# Field selection
GET /users?fields=id,name,email

# Combining
GET /users?status=active&sort=name:asc&fields=id,name&page=1&per_page=20
```

## GraphQL API Design

### Schema Design

```graphql
# Use input types for mutations
input CreateUserInput {
  email: String!
  name: String!
  role: UserRole = MEMBER
}

# Use payload types for mutations
type CreateUserPayload {
  user: User
  errors: [Error!]
}

type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
}

# Connections for pagination
type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

### Error Handling

```graphql
# Errors in extensions
{
  "data": null,
  "errors": [
    {
      "message": "User not found",
      "path": ["user"],
      "extensions": {
        "code": "NOT_FOUND",
        "field": "id"
      }
    }
  ]
}

# Union types for expected errors
union CreateUserResult = User | ValidationErrors

type ValidationErrors {
  errors: [FieldError!]!
}
```

## gRPC API Design

### Service Definition

```protobuf
syntax = "proto3";

package user.v1;

service UserService {
  // Get a single user by ID
  rpc GetUser(GetUserRequest) returns (User);

  // List users with pagination
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);

  // Create a new user
  rpc CreateUser(CreateUserRequest) returns (User);

  // Stream user updates
  rpc WatchUsers(WatchUsersRequest) returns (stream UserEvent);
}

message GetUserRequest {
  string id = 1;
}

message ListUsersRequest {
  int32 page_size = 1;
  string page_token = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  string next_page_token = 2;
}
```

## API Versioning

### Strategies

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| URL Path | `/v1/users` | Clear, easy routing | Multiple URLs |
| Header | `Accept: application/vnd.api.v1+json` | Clean URLs | Hidden |
| Query | `/users?version=1` | Easy to use | Not RESTful |

### Deprecation

```http
# Headers for deprecation
Deprecation: true
Sunset: Sat, 01 Jun 2025 00:00:00 GMT
Link: </v2/users>; rel="successor-version"
```

## Security

### Authentication

```http
# Bearer token
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# API Key
X-API-Key: sk_live_abc123

# Multiple methods
Authorization: Basic base64(client_id:client_secret)
```

### Rate Limiting Headers

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1704067200
Retry-After: 60
```

## Documentation

### OpenAPI Best Practices

```yaml
paths:
  /users:
    get:
      summary: List all users
      description: Returns a paginated list of users
      operationId: listUsers
      tags:
        - Users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
              examples:
                default:
                  $ref: '#/components/examples/UserListExample'
```

## Checklist

Before finalizing an API design:

- [ ] Contract defined (OpenAPI/GraphQL SDL/Protobuf)
- [ ] Consistent naming conventions
- [ ] Proper HTTP methods/status codes (REST)
- [ ] Error response format documented
- [ ] Pagination implemented for lists
- [ ] Authentication/authorization defined
- [ ] Rate limiting strategy
- [ ] Versioning strategy
- [ ] Deprecation policy
- [ ] Examples for all endpoints

## Rules

- ALWAYS design the contract before implementation
- ALWAYS use consistent naming conventions
- NEVER expose internal identifiers directly
- ALWAYS validate input at API boundaries
- NEVER return stack traces in production errors
- ALWAYS use appropriate HTTP status codes
- NEVER break backwards compatibility without versioning
- ALWAYS document all endpoints
