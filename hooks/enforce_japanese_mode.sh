#!/bin/bash
# SessionStart Hook: Enforce Japanese language mode for all outputs
# This hook runs once at session start to set language context
#
# Based on research findings:
# - Claude Opus 4.5 Japanese performance: 96.9% of English baseline
# - No evidence that English thinking is more efficient for Japanese users
# - Japanese documentation improves maintainability for Japanese teams

cat << 'EOF'

---

## 言語モード: 日本語 (Japanese Language Mode Active)

このセッションはすべての出力に**日本語を使用**します。

### L1 ルール (MUST - 必須)

- ユーザーへの応答は100%日本語
- 仕様書・設計書の本文は日本語
- エラーメッセージ・説明は日本語

### L2 ルール (Should - デフォルト)

- コードコメントは日本語
- 技術用語は英語併記可（例: アーキテクチャ/architecture）

### L3 ルール (Consider - 推奨)

- 変数名・関数名は英語のまま
- ファイルパス・URLは変更しない
- JSONキー名は英語のまま

### 技術用語マッピング

| English | 日本語 |
|---------|--------|
| specification | 仕様書 |
| architecture | アーキテクチャ |
| implementation | 実装 |
| refactoring | リファクタリング |
| dependency | 依存関係 |

---

EOF

exit 0
