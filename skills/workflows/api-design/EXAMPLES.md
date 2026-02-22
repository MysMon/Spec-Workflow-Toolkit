# api-design Examples

REST、GraphQL、gRPC の具体的なスキーマ・コントラクト例。

## REST API: リソース命名

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

## REST API: コントラクトファースト（OpenAPI）

```yaml
openapi: 3.1.0
info:
  title: User Service API
  version: 1.0.0
```

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

## GraphQL API: スキーマ設計

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

## GraphQL API: エラーハンドリング

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

## gRPC API: サービス定義

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
