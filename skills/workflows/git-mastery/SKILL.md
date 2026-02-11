---
name: git-mastery
description: |
  Conventional Commits に基づくセマンティックコミットメッセージ、変更ログ管理、git ワークフロー。以下の場合に使用:
  - 変更のコミット時に適切なコミットメッセージ形式が必要
  - 変更ログやリリースノートの管理
  - git ブランチ、マージ、リベースの操作
  - プルリクエストの作成や git 履歴のレビュー
  - セマンティックバージョニングのガイダンスが必要
  Trigger phrases: commit message, conventional commits, changelog, git workflow, semantic version, feat:, fix:, pull request
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
model: haiku
user-invocable: true
---

# Git マスタリー

セマンティックコミットメッセージと git のベストプラクティス。

## Conventional Commits

### 形式

```
<type>(<scope>): <description>

[オプションの本文]

[オプションのフッター]
```

### タイプ

| タイプ | 説明 | 例 |
|-------|------|-----|
| `feat` | 新機能 | `feat(auth): add OAuth2 login` |
| `fix` | バグ修正 | `fix(api): handle null response` |
| `docs` | ドキュメント | `docs: update README setup` |
| `style` | フォーマット（ロジック変更なし） | `style: fix indentation` |
| `refactor` | コード変更（機能/修正なし） | `refactor: extract helper` |
| `perf` | パフォーマンス改善 | `perf: optimize query` |
| `test` | テストの追加/修正 | `test: add user service tests` |
| `chore` | メンテナンス | `chore: update dependencies` |
| `ci` | CI/CD の変更 | `ci: add GitHub Actions` |
| `build` | ビルドシステム | `build: update webpack config` |

### スコープの例

- `auth`、`api`、`ui`、`db`、`config`
- 機能名やコンポーネント名
- オプションだが推奨

### 説明のルール

- 命令形: "added" ではなく "add"
- 末尾にピリオドなし
- 最大 50 文字
- 小文字で開始

## ワークフロー

### ステップ 1: 変更のレビュー

```bash
# 変更内容を確認
git status
git diff --staged
git diff

# 最近のコミットスタイル
git log --oneline -10
```

### ステップ 2: 変更のステージング

```bash
# 特定のファイルをステージング
git add path/to/file

# 全変更をステージング
git add .

# インタラクティブステージング
git add -p
```

### ステップ 3: コミットメッセージの生成

変更を分析してセマンティックメッセージを作成:

```bash
# 単一機能
git commit -m "feat(users): add email verification flow"

# 本文付きバグ修正
git commit -m "fix(api): handle timeout on external calls

- Add retry logic with exponential backoff
- Set 30s timeout for external API
- Log failures for monitoring"

# 破壊的変更
git commit -m "feat(auth)!: require MFA for admin users

BREAKING CHANGE: Admin users must now configure MFA before accessing admin panel."
```

### ステップ 4: 確認

```bash
git log --oneline -1
git show --stat
```

## 変更ログ管理

### Keep a Changelog 形式

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- 新機能 X (#123)

### Changed
- 動作 Y を更新

### Fixed
- コンポーネント Z のバグ (#456)

## [1.2.0] - 2024-01-15

### Added
- 機能 A
- 機能 B

### Fixed
- 重大バグ C
```

### 変更ログの更新

変更を行う際:

1. `[Unreleased]` の下にエントリを追加
2. 適切なカテゴリを使用（Added、Changed、Fixed 等）
3. Issue/PR 番号を参照
4. エントリは簡潔に

## Git ベストプラクティス

### ブランチ命名

```
feature/user-authentication
fix/login-timeout
docs/api-reference
refactor/database-layer
```

### コミットの衛生

- 1 コミットにつき 1 つの論理的変更
- 早く頻繁にコミット
- シークレットをコミットしない
- コミット前に diff をレビュー

### インタラクティブリベース（整理用）

```bash
# 最後の 3 コミットをスカッシュ
git rebase -i HEAD~3

# エディタ内:
pick abc123 First commit
squash def456 Second commit
squash ghi789 Third commit
```

## コミットメッセージテンプレート

### 機能

```
feat(<scope>): <機能の内容>

- 実装の詳細 1
- 実装の詳細 2

Closes #<issue>
```

### バグ修正

```
fix(<scope>): <修正内容>

<バグの原因と修正方法>

Fixes #<issue>
```

### 破壊的変更

```
feat(<scope>)!: <破壊的変更の説明>

BREAKING CHANGE: <何が壊れるかの詳細説明>

Migration: <移行方法>
```

## 取り消しとリカバリパターン

### シナリオ別リカバリ

| 状況 | コマンド | リスクレベル |
|------|---------|------------|
| 最後のコミットを取り消す（変更を保持） | `git reset --soft HEAD~1` | 安全 |
| 最後のコミットを取り消す（変更を破棄） | `git reset --hard HEAD~1` | 破壊的 |
| 特定のコミットを取り消す（公開済み） | `git revert <hash>` | 安全 |
| ステージしていない変更を破棄 | `git checkout -- <file>` | 破壊的 |
| ローカル変更を全て破棄 | `git reset --hard HEAD` | 破壊的 |
| 削除されたブランチを復元 | `git reflog` + `git checkout -b <branch> <hash>` | 安全 |

### 安全なロールバックワークフロー

```bash
# 1. 現在の状態を確認
git status
git log --oneline -5

# 2. バックアップブランチを作成（必ず！）
git branch backup-$(date +%Y%m%d-%H%M%S)

# 3. ロールバックを実行
git revert <commit-hash>  # プッシュ済みコミットの場合
# または
git reset --soft HEAD~1   # 未プッシュコミットの場合

# 4. 確認
git log --oneline -5
git diff HEAD~1
```

### 一時保存用の Stash

```bash
# 現在の作業を保存
git stash push -m "WIP: feature description"

# スタッシュ一覧
git stash list

# 最新を復元
git stash pop

# 特定のスタッシュを復元
git stash apply stash@{2}

# スタッシュを削除
git stash drop stash@{0}
```

### 緊急リカバリ

```bash
# 失われたコミットを見つける
git reflog

# 失われたコミットを復元
git cherry-pick <hash>

# 履歴から削除されたファイルを復元
git checkout <commit-hash> -- path/to/file
```

### やってはいけないこと

| 危険な操作 | 理由 | 安全な代替 |
|-----------|------|----------|
| 共有ブランチで `git push --force` | 他者の作業を上書き | `git revert` + 通常のプッシュ |
| バックアップなしの `git reset --hard` | 永久的なデータ損失 | まずバックアップブランチを作成 |
| レビューなしの `git clean -fd` | 追跡外ファイルを削除 | まず `git clean -fdn`（ドライラン） |

## Rules (L1 - Hard)

データの安全性とチーム協業に不可欠。違反はデータ損失や他者への影響を引き起こす可能性。

- NEVER: 共有ブランチにフォースプッシュしない（他者の作業を上書き）
- ALWAYS: 破壊的操作の前にバックアップブランチを作成する
- NEVER: `--hard` リセットの影響を理解せずに使用しない
- NEVER: シークレットや認証情報をコミットしない

## Defaults (L2 - Soft)

一貫性と品質に重要。適切な理由がある場合はオーバーライド可。

- セマンティックバージョニングのために Conventional Commit 形式を使用
- コミット前に git status を確認
- 無関係な変更を一緒にコミットしない
- コミットメッセージに意味のある説明を記述
- ユーザー向け変更には変更ログを更新

## Guidelines (L3)

より良い git 運用のための推奨事項。

- consider: 部分的なステージングに `git add -p` の使用を検討
- prefer: フィーチャーブランチではリベースで線形履歴を推奨
- consider: 検証済みの作者確認のためにコミット署名を検討
