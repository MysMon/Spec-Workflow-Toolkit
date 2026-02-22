# API 設計

一貫性のある保守しやすい API を設計するためのスタック非依存パターン。

## 設計原則

### 1. コントラクトファースト設計

実装より先に必ず API コントラクトを定義する。REST なら OpenAPI、GraphQL なら SDL、gRPC なら Protocol Buffers。具体的なコントラクト例は `EXAMPLES.md` を参照。

### 2. 一貫性

| 側面 | 標準 |
|------|------|
| 命名 | 一貫したケースを使用（snake_case または camelCase） |
| エラー | 統一されたエラーレスポンス形式 |
| ページネーション | 全リストエンドポイントで同じパターン |
| バージョニング | 単一のバージョニング戦略 |

## REST API 設計

リソース命名は名詞・複数形・小文字を基本とする。ネストされたリソースやアクション（activate, cancel 等）のパターンは `EXAMPLES.md` を参照。

ステータスコード、エラーレスポンス形式、ページネーション、フィルタリング・ソートの標準パターンは `REFERENCE.md` を参照。

## GraphQL API 設計

- ミューテーションには `input` 型と `payload` 型を使用
- ページネーションには Connection パターンを使用
- エラーは `extensions` または Union 型で表現

スキーマ設計とエラーハンドリングの具体例は `EXAMPLES.md` を参照。

## gRPC API 設計

- `proto3` 構文を使用
- パッケージにバージョンを含める（例: `user.v1`）
- ページネーションには `page_size` / `page_token` パターンを使用

サービス定義の具体例は `EXAMPLES.md` を参照。

## API バージョニング

URL パス・ヘッダー・クエリパラメータの3戦略から選択する。非推奨化ヘッダーで移行を通知する。各戦略の比較表と非推奨化ヘッダーは `REFERENCE.md` を参照。

## セキュリティ

認証（Bearer トークン、API キー、Basic 認証）とレート制限ヘッダーの標準パターンは `REFERENCE.md` を参照。

## ドキュメント

OpenAPI ベストプラクティス: summary、description、operationId、tags、examples を含める。具体例は `EXAMPLES.md` を参照。

## チェックリスト

API 設計確定前のチェックリストは `REFERENCE.md` を参照。

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
