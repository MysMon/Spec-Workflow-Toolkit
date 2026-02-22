# API 設計

一貫性のある保守しやすい API を設計するためのスタック非依存パターン。

## 設計原則

### 1. コントラクトファースト設計

実装より先に必ず API コントラクトを定義する:

```yaml
# REST 向け OpenAPI
openapi: 3.1.0
info:
  title: User Service API
  version: 1.0.0

# GraphQL SDL
type Query {
  user(id: ID!): User
}

# gRPC 向け Protocol Buffers
service UserService {
  rpc GetUser (GetUserRequest) returns (User);
}
```

### 2. 一貫性

| 側面 | 標準 |
|------|------|
| 命名 | 一貫したケースを使用（snake_case または camelCase） |
| エラー | 統一されたエラーレスポンス形式 |
| ページネーション | 全リストエンドポイントで同じパターン |
| バージョニング | 単一のバージョニング戦略 |

## REST API 設計

### リソース命名

```
# 良い例 - 名詞、複数形、小文字
GET    /users
GET    /users/{id}
POST   /users
PUT    /users/{id}
DELETE /users/{id}

# ネストされたリソース
GET    /users/{id}/posts
POST   /users/{id}/posts

# アクション（必要な場合）
POST   /users/{id}/activate
POST   /orders/{id}/cancel

# 悪い例
GET    /getUsers          # URL に動詞
GET    /user_list         # 単数形、アンダースコア
POST   /createUser        # 動詞、RESTful でない
```

### HTTP ステータスコード

| コード | 意味 | 使用場面 |
|--------|------|----------|
| 200 | OK | GET、PUT 成功時 |
| 201 | Created | POST 成功時 |
| 204 | No Content | DELETE 成功時 |
| 400 | Bad Request | バリデーションエラー |
| 401 | Unauthorized | 認証なし/無効な認証 |
| 403 | Forbidden | 認証済みだが権限なし |
| 404 | Not Found | リソースが存在しない |
| 409 | Conflict | 重複、状態の競合 |
| 422 | Unprocessable | ビジネスロジックエラー |
| 429 | Too Many Requests | レート制限 |
| 500 | Server Error | 予期しないエラー |

### エラーレスポンス形式

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

### ページネーション

```json
// カーソルベース（大規模データセットに推奨）
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTAwfQ==",
    "has_more": true
  }
}

// オフセットベース
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

### フィルタリングとソート

```bash
# フィルタリング
GET /users?status=active&role=admin

# ソート
GET /users?sort=created_at:desc,name:asc

# フィールド選択
GET /users?fields=id,name,email

# 組み合わせ
GET /users?status=active&sort=name:asc&fields=id,name&page=1&per_page=20
```

## GraphQL API 設計

### スキーマ設計

```graphql
# ミューテーションには input 型を使用
input CreateUserInput {
  email: String!
  name: String!
  role: UserRole = MEMBER
}

# ミューテーションには payload 型を使用
type CreateUserPayload {
  user: User
  errors: [Error!]
}

type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
}

# ページネーション用の Connection パターン
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

### エラーハンドリング

```graphql
# extensions でのエラー
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

# 期待されるエラー用の Union 型
union CreateUserResult = User | ValidationErrors

type ValidationErrors {
  errors: [FieldError!]!
}
```

## gRPC API 設計

### サービス定義

```protobuf
syntax = "proto3";

package user.v1;

service UserService {
  // ID で単一ユーザーを取得
  rpc GetUser(GetUserRequest) returns (User);

  // ページネーション付きでユーザー一覧を取得
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);

  // 新しいユーザーを作成
  rpc CreateUser(CreateUserRequest) returns (User);

  // ユーザー更新をストリーミング
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

## API バージョニング

### 戦略

| 戦略 | 例 | 利点 | 欠点 |
|------|-----|------|------|
| URL パス | `/v1/users` | 明確、ルーティングが容易 | 複数の URL |
| ヘッダー | `Accept: application/vnd.api.v1+json` | クリーンな URL | 不可視 |
| クエリ | `/users?version=1` | 使いやすい | RESTful でない |

### 非推奨化

```http
# 非推奨化用ヘッダー
Deprecation: true
Sunset: Sat, 01 Jun 2025 00:00:00 GMT
Link: </v2/users>; rel="successor-version"
```

## セキュリティ

### 認証

```http
# Bearer トークン
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# API キー
X-API-Key: sk_live_abc123

# 複数方式
Authorization: Basic base64(client_id:client_secret)
```

### レート制限ヘッダー

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1704067200
Retry-After: 60
```

## ドキュメント

### OpenAPI ベストプラクティス

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

## チェックリスト

API 設計を確定する前に:

- [ ] コントラクト定義済み（OpenAPI/GraphQL SDL/Protobuf）
- [ ] 一貫した命名規則
- [ ] 適切な HTTP メソッド/ステータスコード（REST）
- [ ] エラーレスポンス形式を文書化
- [ ] リスト用ページネーション実装済み
- [ ] 認証/認可を定義
- [ ] レート制限戦略
- [ ] バージョニング戦略
- [ ] 非推奨化ポリシー
- [ ] 全エンドポイントの例

## Rules (L1 - Hard)

API のセキュリティと信頼性に不可欠。

- NEVER: 内部識別子を直接公開しない（セキュリティリスク）
- NEVER: 本番環境のエラーでスタックトレースを返さない（情報漏洩）
- ALWAYS: API 境界で入力をバリデーションする（セキュリティ要件）
- NEVER: バージョニングなしで後方互換性を壊さない

## Defaults (L2 - Soft)

API の品質に重要。適切な理由がある場合はオーバーライド可。

- 実装より先にコントラクトを設計する
- エンドポイント間で一貫した命名規則を使用する
- 適切な HTTP ステータスコードを使用する
- 全エンドポイントを例付きで文書化する

## Guidelines (L3)

優れた API 設計のための推奨事項。

- consider: 大規模データセットにはカーソルベースのページネーションを検討
- prefer: コントラクト定義には OpenAPI/GraphQL SDL/Protobuf を推奨
- consider: エンドポイント削除前に非推奨化ヘッダーの使用を検討
