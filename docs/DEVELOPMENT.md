# Spec-Workflow Toolkit - 開発ガイド

プラグイン開発者向けの詳細仕様書。ユーザー向けドキュメントは `README.md` を参照。

---

## 設計思想

### このプラグインが存在する理由

**課題**: Claude はコンテキスト枯渇により、複雑な長時間実行の開発タスクで困難が生じる。

**解決策**: 探索を隔離しサマリのみを返す専門サブエージェントを用いたオーケストレーターパターン。

### 公式パターンとの意図的な差異

| 観点 | 公式 `feature-dev` | このプラグイン | 理由 |
|--------|------------------------|-------------|-----------|
| アーキテクチャ選択肢 | 3つのアプローチ | 単一の決定版 | 判断疲れを軽減 |
| 進捗フォーマット | `.txt` | `.json` | 機械可読、破損しにくい |
| 進捗の分離 | プロジェクトレベル | ワークスペースレベル | git worktree、並行プロジェクトに対応 |
| エージェント専門化 | 汎用3体 | 専門13体 | ドメイン専門性が品質を向上 |

### コンテキスト管理

Claude Code Best Practices より:

> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator."

| アプローチ | コンテキストコスト | 結果 |
|----------|-------------|--------|
| 直接探索 | 10,000+ トークン | コンテキスト枯渇 |
| サブエージェント探索 | 約500トークンのサマリ | クリーンなメインコンテキスト |

#### コマンド委任ガイドライン

コマンドはオーケストレーターのコンテキストウィンドウを保護するため、サブエージェントに委任すべき。ただし、すべてを委任する必要はない。

**読み取りと編集の区別:**

仕様/設計ファイルの重要な原則: 参照のための読み取りとコンテンツの変更を区別する。

| 操作 | オーケストレーターのアクション | 理由 |
|-----------|---------------------|-----------|
| **参照のための読み取り** | 直接読み取りしてもよい（MAY） | 簡単な参照、セクション確認、確認チェック |
| **編集/変更** | エージェントに委任しなければならない（MUST） | コンテンツ分析、意味的な変更にはエージェントの判断が必要 |

**クイックルックアップの制限（コマンド共通）:**

| 基準 | 制限 | 理由 |
|-----------|-------|-----------|
| ファイル数 | 3ファイル以下 | 3ファイル超過 = エージェントに委任 |
| ファイルあたりの行数 | 200行以下 | 200行超過 = エージェントに委任 |
| 読み取り総行数 | 300行以下 | コンテキスト保護のための総量制限 |
| 目的 | 単一値/セクションの確認 | 分析や理解のためではない |

詳細な例やエッジケースは `subagent-contract` スキルを参照。

**例:**
```markdown
# OK: クイックルックアップのための直接読み取り
仕様ファイルを読んで単一機能の受け入れ基準を確認（200行以下）

# OK: サイズ閾値付きの直接読み取り
仕様ファイルが200行以下なら直接読み取り、それ以外はサマリのため委任

# 委任が必須: コンテンツ変更
product-manager を起動して要件の文言を更新
```

**委任が必須（コンテキスト負荷が高い）:**

| タスク | 委任先 |
|------|-------------|
| 仕様/設計ファイルの分析とサマリ作成 | `product-manager` |
| 仕様/設計ファイルの編集 | `product-manager` |
| コードベースの探索とコンテキスト収集 | `code-explorer` |
| 複数ファイルの変更や複雑なロジック | 適切なスペシャリスト |
| CI ログの分析 | `code-explorer` |
| ドキュメントの調査 | `code-explorer` |

**直接実行OK（コンテキスト消費が最小限）:**

| タスク | 直接実行が可能な理由 |
|------|------------------|
| 仕様/設計ファイルの読み取り（参照目的のみ） | 簡単なセクション参照、分析不要 |
| 軽微な変更（タイポ、バージョン番号、日付） | 単一値の修正、意味的な影響なし |
| 単一の設定値変更 | 1行の変更 |
| ファイル存在確認 | Glob はパスのみ返し、コンテンツを含まない |
| エージェント出力のサマリ提示 | 既にサマリ化済み |

**タスク明確度に基づくコンテキスト収集:**

`/quick-impl` のようなコマンドでは、常にまずエージェントに調査を委任し、失敗時のフォールバックを用意する:

| シナリオ | アクション |
|----------|--------|
| ユーザーが正確なファイルパスを指定 | Explore（クイックモード）にファイルヒント付きで委任 |
| ユーザーが関数/クラス名を指定 | Explore（クイックモード）に委任して特定 |
| タスクが曖昧（「バグを修正して」） | Explore（ディスカバリモード）に委任 |
| 複数ファイルに影響する可能性 | Explore（中程度の徹底度）に委任 |

**フォールバック（エージェント失敗時のみ）:**
Explore エージェントがリトライ後も失敗またはタイムアウトした場合、オーケストレーターはフォールバックとして指定された1-2ファイル（各200行未満）を直接読み取ってもよい（MAY）。

**委任優先であり、直接読み取り優先ではない理由:**
1. **コンテキスト保護**: エージェントの読み取りはオーケストレーターのコンテキストを消費しない
2. **一貫性**: spec-implement、spec-review、spec-revise と同じパターン
3. **専門性**: エージェントは stack-detector やパターン認識を適用
4. **フォールバックの安全性**: 直接読み取りはセーフティネットであり、主要パスではない

**アンチパターン（避けるべき）:**
```markdown
# 悪い例: エージェント呼び出し前に読み取り
タスクが明確なら → ファイルを直接読み取り、エージェントをスキップ

# 良い例: エージェント優先、フォールバックは二番目
常に → エージェントに委任
エージェントが失敗したら → 直接読み取りにフォールバック + ユーザーに警告
```

**メタデータファイルの例外（進捗ファイル、feature-list.json）:**

進捗ファイルやその他のオーケストレーターメタデータは委任ルールの例外。これらのファイルを直接読み取る場合は、正当性ブロックを含める:

```markdown
**進捗ファイルの直接読み取りが許容される理由（委任不要）:**
- 進捗ファイルはオーケストレーターの状態メタデータ（プロジェクトコンテンツではない）
- ステータス確認は簡単なバリデーション（通常 JSON 20行未満）
- [具体的な目的: 重複作業の回避 / レビュー状況の判定 / 等]に不可欠
- 仕様/設計コンテンツの分析と比較してコンテキスト消費が最小限
- resume.md Phase 3 パターンと一貫
```

**重要な区別:**
- **仕様/設計ファイル** → 委任が必須（MUST）（コンテンツ分析）
- **進捗/メタデータファイル** → 正当性付きで直接読み取りOK（状態バリデーション）

**ユーザー提示パターン（重要なアクション前に必須）:**

エージェント出力を受け取った後、オーケストレーターは処理を進める前に主要な調査結果をユーザーに提示しなければならない（MUST）:

```markdown
# 良い例: 実装前にコンテキストを提示
1. product-manager に仕様サマリを委任
2. ユーザーにサマリを提示:
   「仕様からの理解は以下の通りです: [サマリ]」
3. AskUserQuestion を使用: 「この理解で正しいですか？」
4. その後、実装に進む

# 悪い例: ユーザー確認をスキップ
1. product-manager に仕様サマリを委任
2. サマリを内部的に使用して実装（ユーザーには見えない）
```

**このパターンを適用するタイミング:**
- 実装開始前（spec-implement、quick-impl）
- 調査/探索後（quick-impl、doc-audit）
- 分類/診断後（ci-fix、debug）
- 重要なワークフロー判断の前

**アンチパターン: 過剰委任（コードファイルのみ対象）**

軽微なコード変更をサブエージェントに委任すると、リソースの無駄とレイテンシの増加を招く:

```markdown
# 悪い例: 1行のコードタイポ修正を委任
frontend-specialist エージェントを起動:
タスク: コメント内のタイポ "recieve" → "receive" を修正

# 良い例: 軽微なコード変更は直接編集
Edit ツールを使用してコードファイルのタイポを修正
```

**注意:** 仕様/設計ドキュメントについては、委任優先の原則が適用される。軽微な仕様/設計の編集でも、適切なコンテキスト追跡を確保するため、デフォルトで `product-manager` に委任すべき。直接編集はエージェントが失敗した場合のフォールバックのみ。詳細は `spec-revise.md` Phase 5 を参照。

### フェーズ一貫性ルール

複数フェーズを持つコマンドは、ルーティング指示と実行指示の一貫性を確保する必要がある。これは矛盾の一般的な原因。

**アンチパターン: フェーズの矛盾**

```markdown
# Phase 4: ルーティング（ユーザーに見える内容）
軽微な変更: 「直接適用できます。」
はいの場合: Edit ツールで直接修正を適用。

# Phase 5: 実行（オーケストレーターが行うこと）
重要: 軽微な変更でも product-manager エージェントに委任。
```

ユーザーメッセージは「直接」アクションを約束しているが、実行は委任する。これはユーザーとオーケストレーターの双方を混乱させる。

**正しいパターン:**

```markdown
# Phase 4: ルーティング（実行と整合）
軽微な変更: 「product-manager に委任して適用します。」
はいの場合: Phase 5 に進む（product-manager 委任経由）。

# Phase 5: 実行（ルーティングと一貫）
product-manager エージェントに委任...
```

**検証チェックリスト:**
1. ルーティングフェーズのユーザー向けメッセージが実際の実行動作と一致
2. 「直接」vs「委任」の言語がフェーズ間で一貫
3. 実行で委任が必要な場合、ルーティングでも委任に言及

### エージェント失敗ハンドリングパターン

サブエージェントに委任する際、コマンドはエージェント失敗（タイムアウト、クラッシュ、不完全な出力）のエラーハンドリングを含めなければならない（MUST）。

**標準パターン:**

```markdown
**[agent-name] のエラーハンドリング:**
[agent-name] が失敗またはタイムアウトした場合:
1. エージェントの部分出力から使用可能な調査結果を確認
2. スコープを縮小してリトライ（重要な場合）
3. 利用可能な結果で続行（重要でない場合）、ギャップを文書化
4. 重要なエージェントがリトライ後も失敗した場合はユーザーにエスカレート
```

**複数の並列エージェントパターン:**

複数のエージェントを並列起動する場合（例: spec-review で5つのレビューエージェント）、個別および全体で失敗をハンドリング:

```markdown
**並列エージェントのエラーハンドリング:**

各エージェント個別:
[agent] が失敗またはタイムアウトした場合:
1. 部分出力から使用可能な調査結果を確認
2. スコープを縮小してリトライ
3. リトライ失敗の場合、利用可能な結果で続行しギャップを記録
4. 警告を追加: 「[Agent] のレビューが不完全」

**重要: [critical-agent] の失敗ハンドリング:**
[critical-agent] がリトライ後も失敗した場合:
1. ユーザーに目立つ警告を表示
2. 続行前に明示的な承認を要求

全エージェントが失敗した場合:
1. ユーザーに通知: 「成功した結果がないため続行できません。」
2. オプションを提示: リトライ / スキップ / キャンセル
3. ユーザーの判断なしに自動続行しない
```

**ユーザー選択フォールバックパターン:**

エージェントの失敗により、オーケストレーターが分類や判断を行えない場合、状況に応じて2つのアプローチがある:

**アプローチ A: 純粋なユーザー選択（オーケストレーターにコンテキストがない場合）**

オーケストレーターに判断するための情報がない場合:

```markdown
**統合失敗時のエラーハンドリング:**
verification-specialist が失敗またはタイムアウトした場合:
1. 利用可能なエージェントからの生の調査結果を提示
2. 統合失敗についてユーザーに警告
3. ユーザーに分類オプションを提示:
   「利用可能な分析に基づき、分類を手伝ってください:」
   1. オプション A
   2. オプション B
   3. オプション C
4. ユーザーが選択したオプションで続行
```

**アプローチ B: ユーザー確認付き簡易分類（部分的なコンテキストがある場合）**

オーケストレーターにエージェント出力はあるが統合が失敗した場合、ユーザー確認付きで簡易分類ロジックを適用できる:

```markdown
**verification-specialist（統合）のエラーハンドリング:**
verification-specialist が失敗またはタイムアウトした場合:
1. product-manager と code-architect の調査結果を個別に提示
2. ユーザーに警告: 「統合が失敗しました。エージェントの生の調査結果を表示します。」
3. **フォールバック: 簡易分類ロジックを適用:**

   | 仕様への影響 | 設計への影響 | 分類 |
   |-------------|---------------|----------------|
   | 言及なし | 言及なし | TRIVIAL |
   | 「軽微」または「明確化」 | なしまたは「軽微」 | SMALL |
   | 「新規要件」を含む | 任意 | MEDIUM 以上 |
   | 「重大」または「破壊的」 | 任意 | LARGE |
   | 「スコープ外」 | 任意 | NEW |

4. 信頼度の注意書き付きで分類提案を提示:
   「提案された分類: [X]。これは完全な統合なしで導出されました。
   続行前に確認または調整してください。」
5. **重要:** 続行前にユーザーの明示的な確認を要求
```

**どちらのアプローチを使うべきか:**

| 状況 | アプローチ | 理由 |
|-----------|----------|-----------|
| エージェント出力がない | A（純粋なユーザー選択） | オーケストレーターに提案の根拠がない |
| エージェント出力はあるが統合が失敗 | B（簡易分類 + 確認） | 生の出力から提案を導出可能 |
| 分類が下流のルーティングに影響 | B（簡易分類 + 確認） | ワークフローの完全な停止を防止 |

**2025年1月以前の設計との主な違い:** オーケストレーターはフォールバックとして簡易分類ロジックを適用できるようになったが、明示的なユーザー確認を要求しなければならない（MUST）。これによりデッドロックを防ぎつつユーザーの監視を維持。

**コマンドタイプ別の実装:**

| コマンドタイプ | エージェント失敗時 |
|--------------|------------------|
| **探索**（spec-plan、code-review） | 部分出力を使用、レポートにギャップを記録 |
| **実装**（quick-impl、spec-implement） | 単一ファイルにフォーカスしてリトライ、その後ユーザーに確認 |
| **緊急対応**（hotfix） | ユーザー確認付き緊急オーバーライド |
| **検証**（spec-review、ci-fix） | 成功したエージェントで続行、カバレッジギャップを記録 |

**quick-impl.md からの例:**

```markdown
**スペシャリストエージェントのエラーハンドリング:**
スペシャリストエージェントが失敗またはタイムアウトした場合:
1. エージェントの部分出力から使用可能なコードを確認
2. スコープを簡素化してリトライ（単一ファイルフォーカス）
3. リトライ失敗の場合、具体的なエラーでユーザーに通知しオプションを提示:
   - 「別のアプローチで再試行」
   - 「/spec-plan で適切な計画に切り替え」
   - 「手動で対処します（リスクを理解した上で）」
```

### 並列検証パターン

複雑な変更（委任パターン、機能の完全性）の検証に高い信頼度が必要な場合、同じ基準を検証するために複数の独立エージェントを使用する。

**使用するタイミング:**
- 複数のコマンド/エージェントに影響する横断的な懸念
- コアパターン（委任ルール、エラーハンドリング）への準拠を検証
- リリース前の品質チェック
- 大規模リファクタリング後

**パターン:**

1. 検証基準を明確に定義（全エージェントに同じプロンプト）
2. N個のエージェント（通常3-5）を同一の指示で起動
3. 独立して調査結果を収集（相互汚染なし）
4. 合意に基づいて問題の優先度を判定

**合意ベースの優先度判定:**

| 報告したエージェント数 | 優先度 | アクション |
|------------------|----------|--------|
| 過半数（5中3以上） | 高 | 即座に修正 |
| 複数（5中2） | 中 | 慎重にレビュー、修正の可能性大 |
| 単一（5中1） | 低 | 偽陽性の可能性、手動でレビュー |

**例: 委任パターンの検証**

```markdown
5つの検証エージェントを並列起動:
タスク: 全コマンドの委任パターンの一貫性をレビュー。
基準:
1. コマンドはコンテキスト負荷の高いタスクをサブエージェントに委任しているか？
2. 例外（進捗ファイルの読み取り）は正当化されているか？
3. すべてのエージェント呼び出しにエラーハンドリングがあるか？

結果:
- 5/5 が特定: spec-plan のセルフレビューにエラーハンドリングが欠落 → 高
- 2/5 が特定: spec-implement のコンテキスト読み込みにエラーハンドリングが必要 → 中
- 1/5 が特定: 軽微な用語の不一致 → 低（手動でレビュー）
```

**利点:**
- 偽陽性を削減（単一エージェントでは過剰に警告する可能性）
- カバレッジを増加（異なるエージェントが異なる問題に気付く）
- 合意を通じた信頼度スコアリングを提供

**制約:**
- トークンコストが高い（N エージェント × タスクトークン）
- 高影響の検証にのみ使用、軽微なチェックには不要
- 明確で再現可能な基準が必要

### 緊急オーバーライドパターン（緊急対応コマンド）

`/hotfix` のような緊急対応コマンドでは、エージェントが応答しない場合に厳格な委任ルールを緩和できる。このパターンは安全性と緊急性のバランスを取る。

**適用するタイミング:**

- 即座の修正が必要な本番障害
- 定義された閾値を超えるエージェントタイムアウト
- ユーザーが緊急性を確認済み

**閾値ガイドライン:**

| フェーズ | タイムアウト閾値 | オーバーライドアクション |
|-------|-------------------|-----------------|
| コンテキスト収集 | 60秒 | 手動の最小限チェック（単一 git コマンド） |
| 問題の特定 | 90秒 | 緊急の直接検索（単一 Grep） |
| 実装 | 2分 | ユーザー確認付きの手動修正（ドキュメント記録あり） |

**必須のセーフガード:**

1. **ユーザー確認**: 手動オーバーライド前に必ず確認
2. **ドキュメント記録**: コミットメッセージに「緊急手動修正」または「エージェントタイムアウト」を記録
3. **最小スコープ**: 必要な絶対最小限の直接アクションのみ
4. **修正後の検証**: プッシュ前に必ずテストを実行

**hotfix.md からの例:**

```markdown
**エラーハンドリング（緊急オーバーライド）:**
スペシャリストエージェントが失敗または2分以上かかった場合:
1. エージェントの部分出力から使用可能な修正を確認
2. 明示的な単一ファイルフォーカスでリトライ
3. リトライ失敗の場合: ユーザーに通知し緊急手動修正オプションを提示:
   ```
   質問: 「エージェントがタイムアウトしました。緊急事態です - 手動で修正を適用してよいですか？」
   ヘッダー: 「緊急オーバーライド」
   オプション:
   - 「はい、最小限の修正を直接適用」（リスクを理解）
   - 「いいえ、エージェントで再試行を待つ」
   - 「hotfix を中止し /debug を代わりに試す」
   ```
4. ユーザーが手動修正を承認した場合: 最小限の変更を適用、コミットに「緊急手動修正」を記録
```

### エージェントのツール制約

一部のエージェントは分析の整合性を確保するため、意図的に読み取り専用に設定されている。コマンドは委任時にこれらの制約を尊重する必要がある。

**読み取り専用エージェント（ファイル変更不可）:**

| エージェント | disallowedTools | 役割 |
|-------|-----------------|------|
| code-explorer | Write, Edit, Bash | コードベース分析 |
| code-architect | Write, Edit, Bash | アーキテクチャ設計 |
| verification-specialist | Write, Edit, Bash | 調査結果のファクトチェック |
| security-auditor | Write, Edit | セキュリティ監査 |
| ui-ux-designer | Bash, Edit | デザイン仕様 |

**よくあるミス:**

```markdown
# 悪い例: 読み取り専用エージェントに実装を委任
code-architect エージェントを起動:
タスク: マージ競合の解決を実装

```

**正しいアプローチ:**

```markdown
# 良い例: 読み取り専用エージェントで分析、スペシャリストに実装を委任
code-architect エージェントを起動:
タスク: 両バージョンを分析しマージ戦略を推奨

# その後、適切なスペシャリストに実装を委任
frontend-specialist エージェントを起動:
タスク: code-architect の推奨に基づいてマージを実装
```

**分割検証パターン:**

検証に分析（読み取り専用）と実行（Bash）の両方が必要な場合:

```markdown
**ステップ 1: verification-specialist で分析（読み取り専用）:**
タスク: コンフリクトマーカーの確認、構文の検証

**ステップ 2: qa-engineer で実行（Bash あり）:**
タスク: リンター、型チェック、テストを実行
```

---

## 指示設計ガイドライン

Anthropic の研究とコミュニティのベストプラクティスに基づき、正確性と創造的な問題解決のバランスを取る。

### 制限付き自律の原則

Claude Code Best Practices より:

> "Claude often performs better with high level instructions to just think deeply about a task rather than step-by-step prescriptive guidance. The model's creativity in approaching problems may exceed a human's ability to prescribe the optimal thinking process."

**重要な知見**: 目標、制約、検証については規定的に、実行については柔軟性を持たせる。

### ルール階層

すべてのルールが同等ではない。指示を適用レベルで分類する:

| レベル | 名前 | 適用 | 例 |
|-------|------|-------------|----------|
| **L1** | ハードルール | 絶対、例外なし | セキュリティ制約、秘密保護、安全性 |
| **L2** | ソフトルール | デフォルト動作、根拠があればオーバーライド可 | コードスタイル、コミットフォーマット、レビュー閾値 |
| **L3** | ガイドライン | 推奨事項、コンテキストに応じて適応 | 実装アプローチ、ツール選定 |

**このプラグインの構文規約:**

```markdown
## Rules (L1 - Hard)
- NEVER: commit secrets
- ALWAYS: validate user input

## Defaults (L2 - Soft)
- Use conventional commit format (unless project specifies otherwise)
- Confidence threshold >= 80% (adjust based on task criticality)

## Guidelines (L3)
- Consider using subagents for exploration
- Prefer JSON for state files
```

**重要:** `MUST`/`NEVER`/`ALWAYS`/`consider`/`prefer`/`recommend` はリテラルキーワード。
ファイルの言語（日本語/英語）に関わらず、これらのマーカーは英語のまま保持し翻訳しない。
コロン `:` の後にスペースを入れて本文と区切る。

表記の詳細基準（マーカー形式、見出し形式、用語リスト等）は `docs/specs/notation-standard.md` を参照。

### ゴール指向 vs ステップバイステップの指示

| アプローチ | 使用するタイミング | 例 |
|----------|-------------|---------|
| **ゴール指向** | 創造的なタスク、問題解決、設計 | 「制約 Y と Z を尊重しながら X を処理するソリューションを設計」 |
| **ステップバイステップ** | 安全性重視、コンプライアンス、検証 | 「1. X を確認、2. Y を検証、3. 続行前に Z を確認」 |

**コマンドとスキルのパターン:**

```markdown
## Goal
[成功の姿 - 最終状態の説明]

## Constraints (L1/L2)
[交渉不可の要件]

## Approach (L3)
[推奨戦略 - Claude は状況に応じて適応可能]

## Verification
[成功を確認する方法]
```

### 過剰仕様の回避

研究ノート:

> "Explicit constraints may lead to over-control problems that suppress emergent behaviors."

**過剰仕様の兆候:**
- すべてのステップが番号付きで規定されている
- 判断や適応の余地がない
- 指示が500行を超える
- コンテキストに関係なく同じ結果

**対処法:**
- 規定的なステップを成功基準に置き換える
- 「Claude はこの特定の状況に基づいてこのアプローチを適応させてもよい」を追加
- 思考プロンプトを使用: 「実装前に代替案を検討」

### 適切な主体性の促進

Claude Code Best Practices より:

Claude 4.x は指示を正確に遵守する。創造的な問題解決を促進するには:

```markdown
## 柔軟性条項

これらのガイドラインは出発点であり、厳格なルールではない。
同じ目標を達成するより良いアプローチを特定した場合:
1. 根拠を説明
2. そのアプローチが全ての L1（ハード）制約を満たすことを確認
3. 改善されたアプローチで進行
```

### 複雑な判断のための思考プロンプト

判断が必要なタスクには、思考プロンプトを追加:

```markdown
## 実装前に

以下について深く考える:
- 異なるアプローチのトレードオフは何か？
- シニアエンジニアなら何を考慮するか？
- まだ検討していないより良いソリューションはないか？
- このアプローチは全ての制約を満たしているか？

ステップを機械的に辿るのではなく、自分の判断を活用する。
```

### 指示の段階的開示（二段階ロード構造）

SKILL.md はコンテキストに常時注入されるため、**フロントマター + ポインター行のみ**（500バイト以内目標）に留め、詳細手順は `INSTRUCTIONS.md` に分離してオンデマンド読み込みにする:

```
my-skill/
├── SKILL.md           # Stage 1: 常時注入（フロントマター + ポインター、500B以内）
├── INSTRUCTIONS.md    # Stage 2: 詳細手順（オンデマンド読み込み）
├── REFERENCE.md       # 補足資料（オンデマンド読み込み）
│   └── [特定シナリオのステップバイステップ手順]
└── EXAMPLES.md        # 具体例（オンデマンド読み込み）
    └── [説明ではなく例示]
```

### 指示の効果測定

指示を改善する際:

1. **様々なコンテキストでテスト** - 同じ指示、異なる状況
2. **脆弱性を確認** - 軽微な言い換えで動作が壊れないか？
3. **創造的な余地を検証** - Claude はより良いソリューションを見つけられるか？
4. **制約の遵守を確認** - L1 ルールは常に守られているか？

---

## コンポーネントテンプレート

### エージェントテンプレート

`agents/[name].md` を作成:

```yaml
---
name: agent-name
description: |
  簡潔な説明。

  Use proactively when:
  - 条件 1
  - 条件 2

  Trigger phrases: keyword1, keyword2
model: sonnet
tools: Read, Glob, Grep, Write, Edit, Bash
disallowedTools: Write, Edit
permissionMode: acceptEdits
skills:
  - skill1
  - skill2
---

# 役割: [タイトル]

[指示...]
```

#### エージェントフィールドリファレンス

| フィールド | 必須 | 値 |
|-------|----------|--------|
| `name` | はい | kebab-case 識別子 |
| `description` | はい | サマリ + "Use proactively when:" + "Trigger phrases:" |
| `model` | いいえ | `sonnet`（デフォルト）、`opus`、`haiku`、`inherit` |
| `tools` | いいえ | カンマ区切りのツール名 |
| `disallowedTools` | いいえ | 明示的に禁止するツール |
| `permissionMode` | いいえ | `default`、`acceptEdits`、`plan`、`dontAsk` |
| `skills` | いいえ | スキル名の YAML 配列 |
| `hooks` | いいえ | エージェントスコープのライフサイクルフック（PreToolUse、PostToolUse、Stop） |

#### permissionMode オプション

| モード | 動作 | ユースケース |
|------|----------|----------|
| `default` | 標準プロンプト | 汎用エージェント |
| `acceptEdits` | 編集を自動承認 | 実装エージェント |
| `plan` | 読み取り専用 | 分析エージェント |
| `dontAsk` | 完全自動化 | バッチ処理 |

#### モデル選定戦略

| モデル | ユースケース | エージェント例 |
|-------|----------|----------------|
| **Opus** | 複雑な推論、高影響 | system-architect、product-manager |
| **Sonnet** | コスト/能力のバランス | code-explorer、qa-engineer、security-auditor、verification-specialist |
| **Haiku** | 高速、低コスト処理 | stack-detector、git-mastery、code-quality |
| **inherit** | ユーザーがトレードオフを制御 | frontend-specialist、backend-specialist |

#### スキル割り当てガイドライン

スキルの SKILL.md はエージェントのコンテキストに常時注入される（二段階ロード構造により各スキル約150-200トークン）。詳細手順は INSTRUCTIONS.md に分離されオンデマンド読み込みとなるが、スキル数が増えるとベースコストも増加するため、必要最小限に留める。

**エージェントが実際に使用するスキルのみを含める:**

| スキルタイプ | 含める対象 | 含めない対象 |
|------------|-------------|-------------------|
| `stack-detector` | プロジェクト技術の理解が必要なエージェント | 既知のコンテキストで作業するエージェント |
| `progress-tracking` | オーケストレーターコマンドのみ | スペシャリストエージェント（オーケストレーターが管理） |
| `parallel-execution` | オーケストレーターコマンドのみ | 個別エージェント |
| `long-running-tasks` | オーケストレーターコマンドのみ | 短時間のスペシャリスト |
| `insight-recording` | パターンを発見するエージェント | 非技術エージェント |

**過剰割り当てのアンチパターン:**

```yaml
# 悪い例: オーケストレータースキルを持つスペシャリスト（約8,000トークンの無駄）
skills: stack-detector, subagent-contract, progress-tracking, parallel-execution, long-running-tasks

# 良い例: 必要最小限のスキルのみのスペシャリスト
skills: stack-detector, subagent-contract, insight-recording, language-enforcement
```

**スキルの順序規約:**

保守性のため、スキルは一貫した順序で記載する:

```yaml
# 順序: ドメイン固有 → コアフレームワーク → インサイト → 言語（常に最後）
skills: stack-detector, testing, code-quality, subagent-contract, insight-recording, language-enforcement
```

| 位置 | スキルタイプ | 例 |
|----------|------------|----------|
| 1番目 | ドメイン固有 | stack-detector、testing、security-fundamentals、api-design |
| 2番目 | コアフレームワーク | subagent-contract |
| 3番目 | インサイトキャプチャ | insight-recording |
| 最後 | 言語 | language-enforcement（常に最後） |

**スキル削除時は孤立した参照を確認:**

`skills:` リストからスキルを削除する場合、エージェントファイルでそのスキルへの参照を grep:

```bash
grep -n "skill-name" agents/agent-name.md
```

削除したスキルを参照する指示を除去する。

---

### スキルテンプレート

**二段階ロード構造**: SKILL.md はコンテキストに常時注入されるため、フロントマター + ポインター行のみとする。詳細手順は `INSTRUCTIONS.md` に分離し、スキル起動時に Read ツールでオンデマンド読み込みする。

**Stage 1: `skills/[category]/[name]/SKILL.md`**（常時注入、500バイト以内目標）:

```yaml
---
name: skill-name
description: |
  概要（1行）。
  Use when: 条件1、条件2、条件3。
  Trigger phrases: keyword1, keyword2, keyword3
allowed-tools: Read, Glob, Grep
model: sonnet
user-invocable: false
---

詳細手順は同ディレクトリの `INSTRUCTIONS.md` を参照。
```

**Stage 2: `skills/[category]/[name]/INSTRUCTIONS.md`**（オンデマンド読み込み）:

```markdown
# スキル名

[詳細手順、ルール、パターン、ワークフロー...]

## ルール（L1 - ハード）
[...]

## デフォルト（L2 - ソフト）
[...]
```

#### スキルフィールドリファレンス

| フィールド | 必須 | 説明 |
|-------|----------|-------------|
| `name` | はい | kebab-case 識別子 |
| `description` | はい | 概要1行 + "Use when:" 1行 + "Trigger phrases:" 1行（3-4行に圧縮） |
| `allowed-tools` | いいえ | スキルがアクティブ時に利用可能なツール |
| `model` | いいえ | 使用するモデル |
| `user-invocable` | いいえ | `true` = ユーザーが `/skill-name` で実行可能 |
| `context` | いいえ | `fork` = 隔離されたサブエージェントコンテキストで実行 |
| `agent` | いいえ | `context: fork` 時のエージェントタイプ（例: `Explore`、`Plan`、`general-purpose`） |
| `hooks` | いいえ | スキルスコープのライフサイクルフック（PreToolUse、PostToolUse、Stop） |

#### 段階的開示ガイドライン（二段階ロード構造）

SKILL.md はコンテキストに常時注入される。フロントマター + ポインターのみに留める:

| 制限 | 推奨 |
|-------|----------------|
| SKILL.md サイズ | 500バイト以内（フロントマター + ポインター行のみ） |
| description | 概要1行 + Use when: 1行 + Trigger phrases: 1行（3-4行に圧縮） |
| INSTRUCTIONS.md | 詳細手順（サイズ制限なし、オンデマンド読み込み） |
| サポートファイル | `REFERENCE.md`、`EXAMPLES.md` を使用 |

**200-500バイト以下のスキルは未分割でも可。**

```
my-skill/
├── SKILL.md           # Stage 1: 常時注入（フロントマター + ポインター、500B以内）
├── INSTRUCTIONS.md    # Stage 2: 詳細手順（オンデマンド読み込み）
├── REFERENCE.md       # 補足ドキュメント（オンデマンド読み込み）
├── EXAMPLES.md        # 使用例（オンデマンド読み込み）
└── scripts/
    └── helper.py      # 実行されるもの、コンテキストには読み込まれない
```

#### スキルコンテンツガイドライン

| する | しない |
|----|-------|
| `From Claude Code Best Practices:` | `[Claude Code Best Practices](https://...)` |
| プレーンテキスト帰属 | `## Sources` や `## References` セクション |

#### スキル設計原則

スキルは**プロセスとフレームワーク**を定義すべきであり、陳腐化する可能性のある静的知識ではない。

| 原則 | 実装 |
|-----------|----------------|
| **ハードコードされた技術なし** | WebSearch で現在のオプションを発見 |
| **要件優先** | ソリューションを提案する前にユーザーのニーズを確認 |
| **ドメイン非依存** | 技術カテゴリの質問を避ける（例: 「Web？ Mobile？」） |
| **動的発見** | RAG（WebSearch + WebFetch）で最新情報を取得 |
| **評価フレームワーク** | 何を比較するかではなく、どう比較するかを定義 |

**良いスキルコンテンツ:**
- リサーチ方法論
- 評価フレームワークと基準
- クエリ構築パターン
- 意思決定プロセス

**スキルで避けるべきもの:**
- 特定の技術名/バージョン
- ハードコードされたオプションの比較表
- 特定ツールのセットアップコマンド
- 陳腐化する可能性のある推奨事項

---

### コマンドテンプレート

`commands/[name].md` を作成:

```yaml
---
description: "/help 用のコマンド説明"
argument-hint: "[arg]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, Task
---

# /command-name

## Language Mode
[言語設定の指示]

## 目的
[このコマンドが何をするか]

## ワークフロー
[ステップバイステップのフェーズ]

## 出力
[期待される成果物]

## ルール（L1 - ハード）
- MUST: [コマンド固有の義務]
- NEVER: [コマンド固有の禁止]

## デフォルト（L2 - ソフト）
- [デフォルト動作の記述]

## ガイドライン（L3）
- consider: [推奨事項]

## 使用例（任意）
[コマンドの典型的な使用パターン]
```

#### コマンドフィールドリファレンス

| フィールド | 必須 | 説明 |
|-------|----------|-------------|
| `description` | はい | `/help` に表示 |
| `argument-hint` | いいえ | 例: `[file]`、`[PR number]` |
| `allowed-tools` | いいえ | 実行中のツール |

---

### コマンドとエージェントのコンテンツガイドライン

コマンドとエージェントは明確さのために具体例を含めることができるが、変化に対して耐性があるべき。

#### 許容（例示）

```markdown
**リンターコマンドの例:**
npm run lint -- --fix
python -m black .
```

一般的なパターン（自動修正リンター）は安定しており、具体的なツールは例示。

#### リスクあり（規定的）

```markdown
**必須:** コミット前に `eslint --fix` を実行。
```

eslint が biome や他のツールに置き換えられた場合に壊れる。

#### ガイドライン

| コンテンツタイプ | ガイダンス |
|--------------|----------|
| **CLI の例** | 広く採用されているツール（gh、npm、git）を例として使用 |
| **ツール名** | 要件ではなく例として提示 |
| **API/SDK 呼び出し** | 具体的なメソッド名ではなく概念的な説明 |
| **バージョン番号** | 避ける; 「現在のバージョン」または「利用可能な場合」を使用 |
| **ファイルパス** | 具体的な名前（`eslint.config.js`）よりパターン（`*lint*`）を使用 |

#### 安定性スペクトラム

| 安定（ハードコードOK） | 中程度（例示のみ） | 不安定（避ける） |
|------------------------|-------------------------|------------------|
| OWASP Top 10、CVSS、CWE | eslint、prettier、black | 特定のバージョン |
| git コマンド | gh CLI、glab CLI | API メソッド名 |
| HTTP メソッド | npm audit、pip-audit | ライブラリ内部 |

---

## フック仕様

### サポートされるイベント

| イベント | 目的 | このプラグインでの使用 |
|-------|---------|------------------|
| `SessionStart` | コンテキスト注入 | `spec_context.sh` |
| `PreToolUse` | ツールの検証/ブロック | `safety_check.py`、`prevent_secret_leak.py` |
| `PostToolUse` | 実行後のアクション | `audit_log.sh` |
| `PostToolUseFailure` | ツール呼び出し失敗後 | `audit_log.sh` |
| `PreCompact` | コンパクション前の状態保存 | `pre_compact_save.sh` |
| `SubagentStop` | 完了ログ、インサイトキャプチャ、参照検証 | `subagent_summary.sh`、`insight_capture.sh`、`verify_references.py` |
| `Stop` | セッションサマリ | `session_summary.sh` |
| `TeammateIdle` | チームメンバーの品質ゲート | `teammate_quality_gate.sh` |
| `SessionEnd` | リソースクリーンアップ | `session_cleanup.sh` |
| `PermissionRequest` | カスタム許可ハンドリング | - |
| `Notification` | 外部通知 | - |
| `UserPromptSubmit` | 入力の前処理 | - |

### SessionStart フック出力ガイドライン

SessionStart の出力はすべてのセッションの開始時に注入され、メインコンテキストのトークンを消費する。

**出力を最小限に保つ（約500トークン以下）:**

| 含める | 除外する |
|---------|---------|
| ワークスペース ID | 詳細なルール説明 |
| 現在のブランチ | コマンドリスト（既に /help にある） |
| ロール（CODING/INITIALIZER） | パターン説明（スキルにある） |
| 再開可能な作業のサマリ | リファレンステーブル |
| 未評価インサイト数 | 利用可能なエージェントリスト |

**理由:** 詳細なコンテキストはオンデマンドで読み込まれるスキルに属する。SessionStart はセッションの方向付けに十分な最小限の情報のみを提供すべき。

**最小限の出力例:**

```
Workspace: main_a1b2c3d4
Branch: feature/auth
Role: CODING
Resumable: docs/specs/auth.md (Step 3/5)
Pending insights: 2
```

**アンチパターン: 冗長な SessionStart**

```markdown
# 悪い例: 完全なコンテキストダンプ（2,000+ トークン）
## オーケストレータールール
- ルール 1...
- ルール 2...

## 利用可能なコマンド
- /spec-plan: ...
- /spec-review: ...

## エージェント委任マトリクス
...

# 良い例: スキル参照付きの最小コンテキスト
Role: CODING. 委任ルールは `subagent-contract` スキルを参照。
Resumable: docs/specs/auth.md
```

**絵文字ガイドライン:** CLAUDE.md のコンテンツガイドラインに従い、フック出力では絵文字を避ける。

### フックスクリプティングセキュリティ

**シェル変数インジェクションリスク:**

シェル変数を Python コードに直接展開してはいけない:

```bash
# 危険 - シェル変数インジェクション脆弱性
python3 -c "
with open('$FILE_PATH', 'r') as f:  # FILE_PATH にクォートが含まれると破損/インジェクション
    data = json.load(f)
"

# 安全 - 環境変数を使用
FILE_PATH="$FILE_PATH" python3 -c "
import os
file_path = os.environ.get('FILE_PATH', '')
with open(file_path, 'r') as f:
    data = json.load(f)
"
```

**フェイルセーフエラーハンドリング:**

コマンドを検証するフックはフェイルセーフ（エラー時に拒否）にすべき:

```python
try:
    data = json.loads(sys.stdin.read())
    # ... 検証ロジック
except Exception as e:
    # 間違い: exit 1 はノンブロッキング、コマンドが実行される可能性あり
    # sys.exit(1)

    # 正しい: JSON decision control で拒否
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"Validation error: {e}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
```

### PreToolUse フックの実装

**終了コードの動作:**

| 終了コード | 動作 | 出力 |
|-----------|----------|--------|
| **0** | 成功 | stdout が JSON として解析される |
| **2** | ブロッキングエラー | stderr がエラーメッセージ |
| **1, 3, etc.** | ノンブロッキングエラー | ツールが実行される可能性あり！ |

**JSON Decision Control（推奨）:**

```python
#!/usr/bin/env python3
import json
import sys

data = json.loads(sys.stdin.read())
tool_input = data.get("tool_input", {})
command = tool_input.get("command", "")

if is_dangerous(command):
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "Blocked: dangerous command"
        }
    }
    print(json.dumps(output))
    sys.exit(0)  # JSON decision control で exit 0
else:
    sys.exit(0)
```

**Decision オプション:**

| Decision | 動作 |
|----------|----------|
| `"allow"` | 許可をバイパスし即座に実行 |
| `"deny"` | 実行を阻止、理由を表示 |
| `"ask"` | UI 確認を表示 |

**ツール入力の変更（v2.0.10+）:**

危険な操作をブロックする代わりに、フックはツール入力を変更して安全にすることが可能:

```python
#!/usr/bin/env python3
import json
import sys

data = json.loads(sys.stdin.read())
tool_input = data.get("tool_input", {})
command = tool_input.get("command", "")

# 例: 長時間実行の可能性があるコマンドにタイムアウトを追加
if command.startswith("npm install"):
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {
                "command": f"timeout 300 {command}"  # 5分のタイムアウト
            }
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# 例: 破壊的コマンドをドライランにリダイレクト
if "rm -rf" in command:
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {
                "command": f"echo '[DRY RUN] Would execute: {command}'"
            }
        }
    }
    print(json.dumps(output))
    sys.exit(0)

sys.exit(0)  # 変更なしで許可
```

**入力変更のユースケース:**

| シナリオ | 元の入力 | 変更後の入力 |
|----------|---------------|----------------|
| 安全ラッパーの追加 | `rm -rf temp/` | `trash temp/`（より安全な削除） |
| タイムアウトの追加 | `npm install` | `timeout 300 npm install` |
| 詳細出力の追加 | `git push` | `git push -v` |
| 出力のリダイレクト | `command` | `command \| tee log.txt` |

**変更 vs ブロックの判断:**

| 状況 | 推奨 |
|-----------|----------------|
| ラッパーで安全にできる | 変更 |
| 根本的に危険 | ブロック（deny） |
| ユーザーの認識が必要 | 確認を求める（ask） |
| 常に安全 | 変更なしで許可 |

**入力スキーマ:**

```json
{
  "tool_name": "Bash|Write|Edit|Read|...",
  "tool_input": {
    "command": "...",
    "file_path": "...",
    "content": "...",
    "new_string": "..."
  }
}
```

### PreCompact フック

コンテキストコンパクション前に発火。状態の保存に使用:

```bash
#!/bin/bash
# ワークスペース隔離の実装については hooks/pre_compact_save.sh を参照
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('trigger','unknown'))")

# ワークスペースユーティリティを読み込み（ワークスペース隔離パス用）
source "$(dirname "$0")/workspace_utils.sh"
PROGRESS_FILE=$(get_progress_file)

if [ -f "$PROGRESS_FILE" ]; then
    # データを安全に Python に渡すため環境変数を使用（フックスクリプティングセキュリティ参照）
    PROGRESS_FILE_PATH="$PROGRESS_FILE" python3 << 'PYEOF'
import os
progress_file = os.environ.get('PROGRESS_FILE_PATH', '')
# ... 進捗ファイルを更新
PYEOF
fi

echo "## Pre-Compaction State Saved"
exit 0
```

**入力スキーマ:**

```json
{
  "trigger": "manual|auto",
  "custom_instructions": "ユーザーの /compact メッセージ"
}
```

### SessionEnd フック

Claude Code セッション終了時に発火。クリーンアップ処理に使用:

```bash
#!/bin/bash
# session_cleanup.sh - セッション終了時のリソースクリーンアップ

# 古いログのローテーション
find ".claude/workspaces/$WORKSPACE_ID/logs/sessions" -name "*.log" -mtime +30 -exec gzip {} \;

# 一時ファイルの削除
find ".claude/workspaces/$WORKSPACE_ID" -name "*.tmp" -delete

# 30日以上前に完了したワークスペースのアーカイブ
# （完全な実装は hooks/session_cleanup.sh を参照）

exit 0
```

**ユースケース:**
- ログのローテーションと圧縮
- 一時ファイルのクリーンアップ
- 古いワークスペースのアーカイブ
- リソースの解放

**注意:** SessionEnd は Stop フックの後に実行される。セッションサマリには Stop を使用し、クリーンアップには SessionEnd を使用。

### プロンプトベースフック

シェルコマンドの代わりに、LLM 評価を使用したコンテキスト認識型の判断が可能:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if this command is safe to run in a production environment. Command: $ARGUMENTS. Return JSON: {\"ok\": true/false, \"reason\": \"explanation\"}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**プロンプトフックがサポートするイベント:**
- `PreToolUse` - ツール呼び出しの評価
- `PermissionRequest` - カスタム許可ロジック
- `UserPromptSubmit` - 入力バリデーション
- `Stop` / `SubagentStop` - 出力の検証

**プロンプト vs コマンドフックの使い分け:**

| シナリオ | 推奨 |
|----------|-------------|
| パターンマッチング（正規表現、キーワード） | コマンド |
| コンテキスト認識型の評価 | プロンプト |
| 複雑なビジネスロジック | コマンド |
| 自然言語の評価 | プロンプト |
| パフォーマンス重視 | コマンド |

### コンポーネントスコープフック

フックはエージェント/スキルのフロントマターで定義でき、コンポーネント固有の動作を実現:

**エージェントフロントマターの例:**

```yaml
---
name: security-auditor
description: セキュリティレビュースペシャリスト
model: sonnet
tools: Read, Glob, Grep, Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./hooks/security_audit_bash_validator.py"
---
```

**スキルフロントマターの例:**

```yaml
---
name: code-quality
description: コード品質分析
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint-check.sh"
          once: true
---
```

**グローバルフックとの主な違い:**

| 観点 | グローバルフック | コンポーネントスコープ |
|--------|--------------|------------------|
| スコープ | 全セッション | コンポーネントがアクティブな間 |
| 定義場所 | `hooks/hooks.json` | エージェント/スキルフロントマター |
| イベント | 全て | PreToolUse、PostToolUse、Stop |
| `once` フラグ | 適用外 | スキルでサポート |

**ユースケース:**
- エージェント固有のバリデーション（security-auditor の Bash バリデーション）
- スキル固有の後処理
- 特定ワークフロー中の一時的なフック

**現在の実装:**
現在、コンポーネントスコープフックを使用しているのは `security-auditor` のみ（Bash バリデーション用の PreToolUse）。他のエージェントは `hooks/hooks.json` で定義されたグローバルフックを使用。特定のバリデーションニーズが生じた場合に、他のエージェントへのコンポーネントスコープフックの追加を検討。

### インサイト追跡システム

インサイト追跡システムは、開発中に発見された価値ある知見を自動キャプチャし、ユーザーがレビューして適用できるようにする。フォルダベースのアーキテクチャを使用し、各インサイトが個別のファイルとして保存されるため、ファイルロックが不要で並行キャプチャとレビューが可能。

**アーキテクチャ:**

```
SubagentStop
    ↓ (metadata with transcript_path)
insight_capture.sh
    ↓ (コードブロックフィルタリング、ステートマシン解析)
    ↓ (アトミックファイル作成、重複排除)
.claude/workspaces/{id}/insights/pending/INS-*.json
    ↓ (/review-insights コマンド)
ユーザー判断
    ├─► applied/    (CLAUDE.md or .claude/rules/)
    ├─► rejected/   (ユーザーが却下)
    └─► archive/    (過去のインサイト参照用)
```

**ディレクトリ構造:**

```
.claude/workspaces/{id}/insights/
├── pending/       # レビュー待ちの新規インサイト
│   ├── INS-20250121143000-a1b2c3d4.json
│   └── INS-20250121143500-e5f6g7h8.json
├── applied/       # CLAUDE.md やルールに適用済み
├── rejected/      # ユーザーが却下
└── archive/       # 過去のインサイト参照用
```

**スキルリファレンス:**

`insight-recording` スキル（`skills/workflows/insight-recording/SKILL.md`）は、エージェントが従う標準化されたプロトコルを提供する。`skills:` フロントマターにこのスキルを持つエージェントは、価値あるインサイトを発見した際にマーカーを出力する。

**インサイトマーカー:**

サブエージェントは記録すべきことを発見した際にこれらのマーカーを出力:

| マーカー | 目的 | 例 |
|--------|---------|---------|
| `INSIGHT:` | 一般的な学び | `INSIGHT: This codebase uses Repository pattern for all DB access` |
| `LEARNED:` | 経験に基づく学び | `LEARNED: PreToolUse exit 1 is non-blocking - use JSON decision control` |
| `DECISION:` | 根拠付きの重要な決定 | `DECISION: Using event-driven architecture due to existing async patterns` |
| `PATTERN:` | 発見された再利用可能パターン | `PATTERN: Error handling always uses AppError class - see src/errors/` |
| `ANTIPATTERN:` | 避けるべきアプローチ | `ANTIPATTERN: Direct database queries in controllers - use services` |

**insight_capture.sh の実装:**

```bash
#!/bin/bash
# SubagentStop フック - サブエージェントのトランスクリプトからマーカーを抽出
# フォルダベースアーキテクチャ（ファイルロック不要）

# 主な機能:
# - 各インサイトを個別ファイルとして保存（ロック不要）
# - コードブロックフィルタリング（```...``` 内の偽一致を防止）
# - インラインコードフィルタリング（`...` 内の偽一致を防止）
# - ステートマシン解析（ReDoS 安全、O(n) 時間）
# - コンテンツ長制限（最大10,000文字）
# - レート制限（キャプチャあたり100インサイト）
# - コンテンツハッシュによる重複排除（SHA256）
# - セキュリティのためのパス検証（TOCTOU 防止）
# - アトミック書き込み（temp + fsync + os.replace）
# - トランスクリプトサイズ制限（最大100MB）

# 処理フロー:
# 1. transcript_path を検証（セキュリティチェック、解決済みパスを返す）
# 2. JSONL をストリーム、アシスタントメッセージを抽出
# 3. コードブロックとインラインコードをフィルタリング
# 4. ステートマシンで解析（正規表現ではない）
# 5. コンテンツハッシュで重複排除
# 6. インサイトごとに個別 JSON ファイルを作成（アトミック）
```

**制約:**

| 制約 | 値 | 理由 |
|------------|-------|-----------|
| 最小コンテンツ長 | 11文字 | ノイズをフィルタリング |
| 最大コンテンツ長 | 10,000文字 | ストレージ肥大を防止 |
| 最大トランスクリプトサイズ | 100MB | メモリ保護 |
| キャプチャあたりの最大インサイト数 | 100 | レート制限 |
| 重複排除 | SHA256 ハッシュ | 同一インサイトは1回のみキャプチャ |

**個別インサイトファイルスキーマ:**

```json
{
  "id": "INS-20250121143000-a1b2c3d4",
  "timestamp": "2025-01-21T14:30:00Z",
  "category": "pattern",
  "content": "Error handling uses AppError class with error codes",
  "source": "code-explorer",
  "status": "pending",
  "contentHash": "a1b2c3d4e5f6g7h8",
  "workspaceId": "main_a1b2c3d4"
}
```

**ディレクトリベースのステータス:**

| ディレクトリ | 意味 |
|-----------|---------|
| `pending/` | ユーザーのレビュー待ち |
| `applied/` | CLAUDE.md や .claude/rules/ に適用済み |
| `rejected/` | ユーザーが却下 |
| `archive/` | 過去のインサイト参照用 |

**設計原則:**

1. **明示的マーカーのみ**: 自動推論なし - サブエージェントはインサイトを明示的にマークする必要がある
2. **ワークスペース隔離**: 各ワークスペースが独自のインサイトディレクトリを持つ
3. **フォルダベースストレージ**: 各インサイトが個別ファイル（ロック不要）
4. **ユーザー主導の評価**: `/review-insights` が AskUserQuestion で1つずつインサイトを処理
5. **段階的な反映先**: ワークスペース → .claude/rules/ → CLAUDE.md
6. **コードブロック安全性**: コードブロック内のマーカーは無視
7. **多層防御**: パス検証、サイズ制限、タイムアウト保護

**エージェントへのインサイト記録の追加:**

インサイト記録を有効にするには、エージェントの `skills:` フロントマターに `insight-recording` を追加し、スキルを参照する簡潔な「インサイトの記録」セクションを追加:

```yaml
skills: stack-detector, subagent-contract, insight-recording
```

```markdown
## インサイトの記録

パターン発見時に `insight-recording` スキルのマーカー（PATTERN:、LEARNED:、INSIGHT:）を使用。インサイトは後のレビュー用に自動キャプチャされる。
```

**エージェントのインサイト記録カバレッジ:**

| エージェント | インサイト記録あり | 理由 |
|-------|----------------------|-----------|
| **探索とアーキテクチャ** |||
| code-explorer | はい | 主要な探索役割、パターンを頻繁に発見 |
| code-architect | はい | 設計判断とパターン分析 |
| system-architect | はい | 高レベルのアーキテクチャ判断（ADR） |
| **レビューと監査** |||
| security-auditor | はい | セキュリティパターンと脆弱性 |
| qa-engineer | はい | テストパターンと品質インサイト |
| verification-specialist | はい | 参照検証、他のエージェント出力のファクトチェック |
| **モダナイゼーションと運用** |||
| legacy-modernizer | はい | レガシーパターン、モダナイゼーション判断 |
| devops-sre | はい | インフラパターン、運用インサイト |
| **実装** |||
| frontend-specialist | はい | コンポーネントパターン、アクセシビリティソリューション、フレームワーク規約 |
| backend-specialist | はい | サービスパターン、API 規約、パフォーマンス最適化 |
| **非技術** |||
| technical-writer | はい | ドキュメントパターン、API ドキュメント規約、ダイアグラム選択 |
| ui-ux-designer | はい | デザインパターン、アクセシビリティソリューション、コンポーネント仕様 |
| product-manager | いいえ | 要件フォーカスで、コードレベルではない |

**一部のエージェントにインサイト記録がない理由:**

非技術エージェント（product-manager）は異なる抽象レベルで動作し、コードパターンに関するインサイトを通常生成しない。注意: ui-ux-designer と technical-writer は例外で、再利用可能なデザインパターン、アクセシビリティソリューション、ドキュメント規約を発見する。

---

## エージェント設定

### ツール設定

| エージェント | ツール | 備考 |
|-------|-------|-------|
| `code-explorer` | Glob, Grep, Read, WebFetch, WebSearch, TodoWrite | Read は .ipynb に対応 |
| `code-architect` | Glob, Grep, Read, WebFetch, WebSearch, TodoWrite | 設計専用 |
| `security-auditor` | Read, Glob, Grep, Bash（検証済み） | PreToolUse フック経由で Bash |

### 信頼度スコアリング

`/code-review` やエージェント出力で使用:

| スコア | 意味 |
|-------|---------|
| **0** | 偽陽性、既存の問題 |
| **25** | 実在する可能性はあるが未検証 |
| **50** | 実在するが軽微 |
| **75** | 検証済み、重大 |
| **100** | 確実に実在、高頻度 |

**閾値**: 信頼度 80% 以上の問題のみ報告。

---

## 統合と環境

### MCP 統合

Model Context Protocol（MCP）サーバーは Claude Code の機能を拡張する。このプラグインは MCP サーバーと連携して動作可能。

#### MCP ツールの命名規約

MCP ツールは次のパターンに従う: `mcp__<server>__<tool>`

例:
- `mcp__memory__create_entities`
- `mcp__filesystem__read_file`
- `mcp__github__search_repositories`

#### MCP ツールのフック考慮事項

PreToolUse フックを書く際は、MCP ツールを考慮:

```python
# MCP ツールのチェック
tool_name = data.get("tool_name", "")

if tool_name.startswith("mcp__"):
    # MCP ツール - サーバーとツール名を抽出
    parts = tool_name.split("__")
    if len(parts) >= 3:
        server_name = parts[1]
        actual_tool = parts[2]
```

#### セキュリティ: コマンドを実行する MCP ツール

一部の MCP ツールはシェルコマンドを実行可能（例: `mcp__shell__exec`、`mcp__terminal__run`）。これらは Bash ツールと同様に検証すべき。

**hooks.json での MCP コマンドツールのマッチング:**

```json
{
  "matcher": "Bash|mcp__.*__(exec|run|shell|command|bash|terminal)",
  "hooks": [
    {
      "type": "command",
      "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/safety_check.py"
    }
  ]
}
```

**MCP ツール入力からのコマンド抽出:**

MCP ツールはコマンドに異なるフィールド名を使用する場合がある。堅牢なバリデーターは複数のフィールドをチェックすべき:

```python
def extract_command_from_mcp_input(tool_input: dict) -> str:
    """様々なスキーマの MCP ツール入力からコマンドを抽出。"""
    command_fields = [
        "command", "cmd", "script", "shell_command",
        "bash_command", "exec", "run", "code", "input"
    ]
    for field in command_fields:
        if field in tool_input and isinstance(tool_input[field], str):
            return tool_input[field]
    return ""
```

#### MCP フック検証のベストプラクティス

| 考慮事項 | 推奨 |
|--------------|----------------|
| **不明なスキーマ** | 危険なパターンのみブロック; 変換は避ける |
| **フェイルセーフデフォルト** | 不明な場合は拒否（MCP ツールは昇格した権限を持つ場合がある） |
| **監査ログ** | セキュリティレビュー用に全 MCP ツール呼び出しをログ |
| **入力抽出** | コマンド抽出に複数の一般的なフィールド名を試行 |

#### Spec-Workflow に推奨される MCP サーバー

| MCP サーバー | ユースケース | Spec-Workflow 統合 |
|------------|----------|-----------------|
| `@anthropic/mcp-server-memory` | 永続メモリ | progress-tracking を補完 |
| `@anthropic/mcp-server-github` | GitHub 操作 | PRレビュー対応フロー |
| `@anthropic/mcp-server-puppeteer` | ブラウザ自動化 | qa-engineer での E2E テスト |
| `@anthropic/mcp-server-filesystem` | ファイル操作 | 組み込みツールの代替 |

#### 設定例

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-memory"]
    }
  }
}
```

#### Spec-Workflow Toolkit + MCP ベストプラクティス

| パターン | 推奨 |
|---------|----------------|
| **進捗追跡** | ワークフロー状態には JSON ファイル（このプラグイン）、永続的な知識には MCP メモリを使用 |
| **コード探索** | 組み込みの `code-explorer` エージェントを使用; 特殊なアクセスには MCP filesystem |
| **GitHub 操作** | PR/Issue 操作には MCP GitHub サーバー; レビューワークフローには `/code-review` |
| **E2E テスト** | MCP Puppeteer + `qa-engineer` エージェントで包括的テスト |

### Web 環境（Claude Code on Web）

Claude Code を Web で実行する場合（`CLAUDE_CODE_REMOTE=true`）、CLI 使用時と一部の機能が異なる。

#### 環境検出

フックで Web 環境を検出可能:

```bash
#!/bin/bash
if [ "$CLAUDE_CODE_REMOTE" = "true" ]; then
    # Web 固有の動作
    echo "Running in Claude Code on Web"
fi
```

#### 既知の違い

| 機能 | CLI | Web | 備考 |
|---------|-----|-----|-------|
| **ファイルシステム** | フルローカルアクセス | サンドボックスワークスペース | Web はパス制限あり |
| **Git 操作** | フル git アクセス | 制限あり | 一部の操作に回避策が必要な場合あり |
| **シェルコマンド** | ユーザーのシェル | コンテナ化 | 環境変数、パスが異なる |
| **対話型プロンプト** | サポート | 制限あり | 非対話型フラグを推奨 |
| **長時間実行プロセス** | サポート | タイムアウトの可能性 | タイムアウト、チェックポイントを使用 |
| **MCP サーバー** | 設定可能 | プリコンフィグ | カスタマイズ制限あり |

#### Web 互換性のベストプラクティス

| プラクティス | 推奨 |
|----------|----------------|
| **非対話型フラグを使用** | `git commit -m "msg"`（`-i` ではなく）、`rm -f`（`-i` ではなく） |
| **絶対パスを避ける** | `$CLAUDE_PROJECT_DIR` または相対パスを使用 |
| **コマンドの欠落に対応** | 使用前に `command -v` でチェック |
| **進捗ファイルを使用** | Web でのセッション再開に不可欠 |
| **明示的なタイムアウトを設定** | Web セッションは制限が短い場合あり |

#### フック互換性

このプラグインのフックは両環境で動作するよう設計:

- `spec_context.sh` での `CLAUDE_CODE_REMOTE` チェック
- コマンドが利用不可の場合のフォールバック動作
- 進捗ファイルは `.claude/` 内の相対パスを使用

#### Web 互換性のテスト

フックやスクリプトを変更する際:

1. `CLAUDE_CODE_REMOTE=true` 環境変数でテスト
2. 一般的な CLI コマンドが利用不可の場合の動作を検証
3. 進捗ファイルが `.claude/workspaces/` に書き込まれることを確認
4. 制限されたファイルシステムアクセスでテスト

---

## Agent Team 統合（実験的）

Agent Team は Claude Code の experimental API であり、サブエージェント（Task tool）とは異なり、チームメイト間で双方向通信が可能な並列エージェント実行基盤。

### team-orchestration スキル

`skills/workflows/team-orchestration/SKILL.md` で定義。Agent Team の検出、作成、フォールバックを管理する。

**主な責務:**
- Agent Team 利用可能性の検出（TeamCreate tool の有無）
- チームメイトのスポーンとロール割り当て
- スポーンプロンプトテンプレートの提供
- インサイトキャプチャ（リーダー側処理）
- チームクリーンアップ

**フォールバック設計:**
Agent Team が利用不可の場合、既存の Task tool パターンに自動フォールバックする（L1 ルール）。既存コマンドの動作に影響を与えない。

### TeammateIdle フック

`hooks/teammate_quality_gate.sh` で実装。Agent Team メンバーがアイドル状態になる際に発火する。

| 項目 | 値 |
|------|------|
| イベント | `TeammateIdle` |
| タイムアウト | 5s |
| 終了コード | exit 0（非ブロッキング）。exit 2 はフィードバック送信とメンバー再起動を引き起こすため使用しない |
| 目的 | 品質ゲート専用（Layer 2）。インサイトキャプチャは Layer 1（プロンプト + リーダー後処理）で実施 |

**2層アプローチ:**

| 層 | 機構 | 保証 |
|----|------|------|
| Layer 1（主） | スポーンプロンプトの L1 ルールでチームメイトに PATTERN/LEARNED/INSIGHT マーカーと file:line 検証を義務付け。リーダーが SendMessage 出力を解析して insights/pending/ に書き込む | 確実に動作 |
| Layer 2（副） | TeammateIdle hook で品質ゲート（成果物存在確認等）を実行。インサイトキャプチャには使用しない | 実験的（stdin 形式が未検証） |

### スポーンプロンプトテンプレート

チームメイトは agents/*.md の YAML frontmatter が適用されないため、スポーンプロンプトで制約を再現する。

**テンプレートに含める要素:**
- 役割名と責務説明
- ツール制約（L1: 使用禁止ツールの明示）
- 出力形式（subagent-contract フォーマット）
- チームメイト間連携ルール（誰と通信すべきか）
- 完了プロトコル（PATTERN/LEARNED/INSIGHT マーカー、file:line 検証）
- 言語モード（日本語）

**安全ネット:**
- スポーンプロンプトの L1 ルール（ツール制約）
- グローバル PreToolUse hooks（safety_check.py, prevent_secret_leak.py）がチームメイトにも発火
- リーダーが出力をモニタリング

詳細なテンプレート例は `skills/workflows/team-orchestration/REFERENCE.md` を参照。

### Phase 1 スコープ: spec-review --auto

初期スコープは `spec-review --auto` のみ。3 チームメイト + 2 サブエージェントのハイブリッド構成:

| 役割 | モード | 理由 |
|------|--------|------|
| security-auditor | チームメイト | qa-engineer と相互検証が品質向上に直結 |
| qa-engineer | チームメイト | セキュリティ指摘のテスト可能性を即座に評価 |
| system-architect | チームメイト | 技術的実現可能性の観点から他の指摘を補強・反論 |
| product-manager | サブエージェント（Task） | 完全性チェックは独立作業で十分 |
| verification-specialist | サブエージェント（Task） | SubagentStop hooks が確実に発火する利点を維持 |

### Phase 2: /discuss コマンド（構造化ディスカッション）

`commands/discuss.md` + `skills/workflows/discussion-protocol/` で定義。
設計判断・技術選定・方針決定について、複数エージェントが弁証法的に議論する。

**チーム構成（3+1+1 モデル）:**

| 役割 | モード | 理由 |
|------|--------|------|
| 議論参加者 x3 | チームメイト | トピックに応じて動的にロール選出。対立軸を含む構成を推奨 |
| devils-advocate | チームメイト（固定ロール） | 全ラウンドで批判的立場を維持。暗黙の前提を明示する義務 |
| モデレーター | リーダー | プロセス介入専任（L1: 内容判断を表明しない） |

**3ラウンド弁証法構造:**

| ラウンド | 目的 | 制約 |
|---------|------|------|
| Position（必須） | 探索空間の初期サンプリング | L1: 独立実行（他者の意見を参照しない） |
| Challenge（必須） | 探索空間の境界テスト | L1: 同意・賛同の表明を禁止 |
| Synthesis（条件付き） | 構造化された折衷 | モデレーター判定で実施/スキップ |

**同意バイアス対策（5層防御）:**
1. devils-advocate 固定ロール
2. Challenge Round の同意禁止 L1 ルール
3. 構造化ヘッダーによる立場変更の追跡
4. Position Round での独立実行（アンカリング防止）
5. CONSENSUS 時の偽合意検出 + ユーザー警告

詳細は `skills/workflows/discussion-protocol/SKILL.md` を参照。

---

## 運用ルール

### コミット前

- セマンティックコミット: `feat:`、`fix:`、`docs:`、`refactor:`
- NEVER: API キーや秘密情報をコミットする
- フックスクリプトを bash と zsh の両方でテスト

### リリース前

- 全エージェント定義の YAML フロントマターが有効であることを確認
- SessionStart フック出力をテスト
- `/plugin validate` を実行
- ドキュメントのカウントが実際のファイルと一致することを確認

---

## 公式リファレンス

全 URL はここに集約。スキルとエージェントファイルではプレーンテキスト帰属のみ使用すること。

### Anthropic エンジニアリングブログ

| 記事 | 主要コンセプト |
|---------|--------------|
| [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) | 6つの合成可能パターン |
| [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Initializer + Coding パターン |
| [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) | サブエージェントコンテキスト管理 |
| [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | コンテキストの劣化、コンパクション |
| [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk) | 検証アプローチ |
| [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) | オーケストレーター-ワーカーパターン |
| [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | スキルパターン |
| [The "think" tool](https://www.anthropic.com/engineering/claude-think-tool) | 構造化された推論 |
| [Demystifying evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | pass@k メトリクス |

### Claude Code ドキュメント

| ページ | 内容 |
|------|---------|
| [Subagents](https://code.claude.com/docs/en/sub-agents) | エージェント定義フォーマット |
| [Skills](https://code.claude.com/docs/en/skills) | スキルフォーマット、段階的開示 |
| [Hooks](https://code.claude.com/docs/en/hooks) | イベントハンドラー |
| [Plugins](https://code.claude.com/docs/en/plugins-reference) | plugin.json スキーマ |
| [Memory](https://code.claude.com/docs/en/memory) | .claude/rules/ |
| [Agent Teams](https://code.claude.com/docs/en/agent-teams) | Agent Team API、TeammateIdle/TaskCompleted フック |

### 公式サンプル

| リポジトリ | 内容 |
|------------|---------|
| [anthropics/claude-code/plugins](https://github.com/anthropics/claude-code/tree/main/plugins) | feature-dev、code-review |
| [anthropics/skills](https://github.com/anthropics/skills) | スキル例 |
