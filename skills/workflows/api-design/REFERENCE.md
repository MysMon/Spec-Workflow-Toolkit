# api-design Reference

HTTP ステータスコード、ページネーション、バージョニング、セキュリティヘッダー等の参照テーブル。

## HTTP ステータスコード

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

## エラーレスポンス形式

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

## ページネーション

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

## フィルタリングとソート

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

## API バージョニング

### 戦略

| 戦略 | 例 | 利点 | 欠点 |
|------|-----|------|------|
| URL パス | `/v1/users` | 明確、ルーティングが容易 | 複数の URL |
| ヘッダー | `Accept: application/vnd.api.v1+json` | クリーンな URL | 不可視 |
| クエリ | `/users?version=1` | 使いやすい | RESTful でない |

### 非推奨化ヘッダー

```http
Deprecation: true
Sunset: Sat, 01 Jun 2025 00:00:00 GMT
Link: </v2/users>; rel="successor-version"
```

## セキュリティヘッダー

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
