# Spec-Workflow Toolkit

AIに「認証機能を作って」と依頼すると、いきなりコードを書き始めて方向がずれることがある。
このツールは「探索→設計→実装」の順序を強制し、各段階で確認してから次に進む。

---

## インストール

```bash
/plugin install spec-workflow-toolkit@claude-plugin-directory
```

開発用: `claude --plugin-dir /path/to/spec-workflow-toolkit`

---

## 最初に試すこと

```bash
/spec-workflow ユーザー認証機能を OAuth 対応で実装
```

7段階で進行し、各段階で確認を求められる。承認するか、修正を指示する。

---

## よく使うコマンド

| やりたいこと | コマンド |
|-------------|----------|
| 新機能を実装する | `/spec-workflow 〇〇を実装` |
| 小さな修正をする | `/quick-impl 〇〇を修正` |
| コミット前にレビューする | `/code-review staged` |
| 中断した作業を再開する | `/resume` |

全コマンドは `/help` で確認できる。

---

## いつ何を使うか

| 状況 | コマンド | 理由 |
|------|----------|------|
| 「どう実装すればいい？」と迷う | `/spec-workflow` | 探索→設計→実装の順で進み、手戻りを防ぐ |
| やることが明確（typo修正など） | `/quick-impl` | 仕様検討不要、すぐ実装 |
| コミット前 | `/code-review staged` | QA・セキュリティ観点でチェック |
| PRレビューで指摘を受けた | `/review-response` | 指摘を分析し対応を提案 |
| CIが落ちた | `/ci-fix` | ログを分析し原因を特定 |
| 本番障害 | `/hotfix` | 影響範囲を最小化しつつ迅速に修正 |
| マージコンフリクト | `/merge-conflict` | 両方の意図を理解して解決 |

---

## 7フェーズの流れ

`/spec-workflow` は以下の順序で進行する。

```mermaid
flowchart LR
    D[1. Discovery<br/>問題定義] --> E[2. Exploration<br/>コード探索]
    E --> C[3. Clarification<br/>質問]
    C --> A[4. Architecture<br/>設計]
    A --> I[5. Implementation<br/>実装]
    I --> R[6. Review<br/>品質確認]
    R --> S[7. Summary<br/>完了記録]

    style D fill:#e1f5fe
    style E fill:#e1f5fe
    style C fill:#fff3e0
    style A fill:#e8f5e9
    style I fill:#e8f5e9
    style R fill:#fce4ec
    style S fill:#f3e5f5
```

| フェーズ | あなたがやること |
|----------|-----------------|
| 1. Discovery | 作りたい機能を説明する |
| 2. Exploration | 既存コードの分析結果を確認する |
| 3. Clarification | 質問に答え、仕様を承認する |
| 4. Architecture | 設計案を確認・承認する |
| 5. Implementation | 実装の進捗を確認する |
| 6. Review | 指摘があれば対応を指示する |
| 7. Summary | 変更内容を確認する |

**なぜ7段階か**: 各段階で確認できるため、誤った方向に進み続けることを防げる。途中で中断しても `/resume` で再開できる。

---

## 中断と再開

| 状況 | 使うコマンド |
|------|-------------|
| 今日の作業を中断し、明日再開する | `/resume` |
| 別のターミナルで続きをやる | `/resume` |
| ネットワーク切断後すぐに再接続 | `claude --continue` |

---

## その他のコマンド

| コマンド | 用途 |
|----------|------|
| `/spec-review` | 仕様を検証してから実装に進む |
| `/review-insights` | 開発中に発見したパターンをルール化する |
| `/project-setup` | プロジェクト固有ルールを生成する |
| `/stack-consult` | 新規プロジェクトの技術選定を相談する |
| `/debug` | エラーの根本原因を特定する |
| `/doc-audit` | コードとドキュメントの整合性を検証する |

---

## 開発者向け

このプラグインを拡張・修正する場合は `docs/DEVELOPMENT.md` を参照。

---

## ライセンス

MIT
