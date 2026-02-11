# Spec-Workflow Toolkit Plugin - Developer Guide

This file is for **Claude working on this plugin repository**.
Users receive context via the `SessionStart` hook, not this file.

## What This Plugin Does

A Claude Code plugin implementing Anthropic's 6 composable patterns for long-running autonomous work:
Plan→Review→Implement→Revise workflow (4 commands with iterative refinement), 13 specialized subagents, TDD integration, evaluator-optimizer loops, checkpoint-based error recovery, and progress tracking.

## Project Structure

```
.claude-plugin/plugin.json   # Plugin metadata
commands/                    # 17 slash commands
agents/                      # 13 subagent definitions
skills/                      # 25 skill definitions
  core/                      #   6 core skills (subagent-contract, spec-philosophy, security-fundamentals, interview, bounded-autonomy, language-enforcement)
  detection/                 #   1 detection skill (stack-detector)
  workflows/                 #   18 workflow skills (including team-orchestration, discussion-protocol)
hooks/                       # Event handlers (9 event types, 14 handlers) + Python validators
docs/                        # DEVELOPMENT.md (detailed specs), specs/
```

## Key Entry Points

| Task | Start Here |
|------|------------|
| Understand planning (with refinement loops) | `commands/spec-plan.md` |
| Understand interactive plan review | `commands/spec-review.md` |
| Understand implementation phase | `commands/spec-implement.md` |
| Understand post-implementation changes | `commands/spec-revise.md` |
| See how agents work | `agents/code-explorer.md`, `agents/code-architect.md` |
| Understand skill pattern | `skills/core/subagent-contract/SKILL.md` |
| Check hook implementation | `hooks/hooks.json`, `hooks/spec_context.sh` |
| Understand insight tracking | `commands/review-insights.md`, `hooks/insight_capture.sh` |
| Understand Agent Team integration | `skills/workflows/team-orchestration/SKILL.md` |
| Understand multi-agent discussion | `commands/discuss.md`, `skills/workflows/discussion-protocol/SKILL.md` |

## Development Rules

### Editing Agents (`agents/*.md`)

YAML frontmatter fields:
- `model`: sonnet (default), opus, haiku, inherit
- `tools`: Available tools
- `disallowedTools`: Explicitly prohibited tools
- `permissionMode`: default, acceptEdits, plan, dontAsk
- `skills`: YAML array of skill names (minimize to preserve context)

### Editing Skills (`skills/**/SKILL.md`)

- `reference.md`, `examples.md` で詳細内容を分離（オンデマンド読み込み）
- `scripts/` に実行可能ヘルパーを配置（read ではなく run）

### Editing Commands (`commands/*.md`)

- `description`: Shown in `/help`
- `argument-hint`: Placeholder for arguments
- `allowed-tools`: Tools available during execution

### Editing Hooks (`hooks/hooks.json`)

PreToolUse hooks の exit code:
- exit 0 + `permissionDecision: "deny"` = 安全なブロック（推奨）
- exit 2 = blocking error
- exit 1, 3, etc. = non-blocking error（ツールが実行される可能性あり）

**Global hooks (9 event types, 14 handlers in hooks.json):**

| Hook | Script | Purpose |
|------|--------|---------|
| SessionStart | `spec_context.sh` | Load progress files and notify pending insights |
| SessionStart | `enforce_japanese_mode.sh` | Enforce Japanese language mode |
| PreToolUse (Bash) | `safety_check.py` | Block dangerous commands |
| PreToolUse (Write\|Edit) | `prevent_secret_leak.py` | Prevent secret leakage |
| PreToolUse (WebFetch\|WebSearch) | `external_content_validator.py` | Validate external URLs (SSRF prevention) |
| PostToolUse | `audit_log.sh` | Audit logging for tool usage tracking |
| PostToolUseFailure | `audit_log.sh` | Audit logging for failed tool calls |
| PreCompact | `pre_compact_save.sh` | Save progress before context compaction |
| SubagentStop | `subagent_summary.sh` | Summarize subagent results |
| SubagentStop | `insight_capture.sh` | Capture marked insights from subagent output |
| SubagentStop | `verify_references.py` | Validate file:line references in subagent output |
| Stop | `session_summary.sh` | Record session summary on exit |
| TeammateIdle | `teammate_quality_gate.sh` | Quality gate for team members |
| SessionEnd | `session_cleanup.sh` | Clean up resources on session termination |

**Agent-specific hooks:** Agents can define their own hooks in YAML frontmatter (e.g., `security-auditor.md` defines a stricter Bash validator). These run only when that agent is active. See `docs/DEVELOPMENT.md` "Component-Scoped Hooks" for details.

See `docs/DEVELOPMENT.md` for full hook specification with code examples.

## Content Guidelines

**Skills and agents are fully injected into context. Keep content lean.**

### URL と参照

skills/agents/commands では URL を使わず、プレーンテキストで出典を示す。
URL は `README.md` と `docs/DEVELOPMENT.md` にのみ記載する。

| Do | Don't |
|----|-------|
| `From Claude Code Best Practices:` | `From [Claude Code Best Practices](https://...):` |
| Plain text source attribution | `## Sources` or `## References` sections |

外部リソースを採用する場合は `docs/DEVELOPMENT.md` "Official References" に URL を追加する。

### README

README.md is **user-facing documentation**（200-250 lines）。

**Include:** plugin summary, quick start, command list, one diagram, best practices, link to DEVELOPMENT.md

**Exclude (move to DEVELOPMENT.md):** implementation details, multiple diagrams, exhaustive references, L1/L2/L3 details

**Test**: Can a new user understand what this does and start using it in 30 seconds?

### Post-Change Checklist

コマンド・スキル・エージェント・フックの追加・削除・リネーム時のチェックリスト:

1. `CLAUDE.md`: Project Structure のカウントを更新
2. `README.md`: コマンド一覧テーブルに追加/削除（250行以内を維持）
3. `docs/DEVELOPMENT.md`: 関連セクションがあれば更新（テンプレート・スペック変更時）

### Version

Version は `plugin.json` のみで管理する（Single Source of Truth）。

### Obsolescence Prevention

外部ツール・API の変更で陳腐化するコンテンツを避ける。

| Avoid | Instead |
|-------|---------|
| Specific API method names | Conceptual descriptions ("find references") |
| Version numbers ("v2.1.0") | "When available" or omit |
| Prescriptive tool requirements | Examples with alternatives |

Skills ではプロセスを定義し、静的知識は避ける。年が必要な場合はシステム時刻から導出（`date +%Y`）。

See `docs/DEVELOPMENT.md` "Command and Agent Content Guidelines" for details.

## Validation

```bash
/plugin validate
```

## Rule Hierarchy (L1/L2/L3)

This plugin uses a 3-level rule hierarchy for balancing accuracy with creative problem-solving:

| Level | Name | Enforcement | In Skills/Commands |
|-------|------|-------------|-------------------|
| **L1** | Hard Rules | Never break | `NEVER`, `ALWAYS`, `MUST` |
| **L2** | Soft Rules | Default, override with reasoning | `should`, `by default` |
| **L3** | Guidelines | Recommendations | `consider`, `prefer`, `recommend` |

**When writing instructions:**
- Use L1 sparingly (security, safety, data integrity)
- L2 for best practices that may have exceptions
- L3 for suggestions that depend on context

See `docs/DEVELOPMENT.md` "Instruction Design Guidelines" for full specification.

## Rules (L1 - Hard)

- MUST: SKILL.md を 500 行・5,000 トークン以内に収める
- MUST: コマンドの `allowed-tools` にコマンド内で参照する全ツールを含める
- MUST: コマンド・スキル・エージェント・フックの追加・削除・リネーム時は Post-Change Checklist を実行し、3ファイル全ての更新が完了するまで作業完了としない
- MUST: PreToolUse hooks では JSON decision control (`permissionDecision: "deny"`) with exit 0 を使用
- MUST: Version は `plugin.json` のみで管理する（Single Source of Truth）
- NEVER: skills/agents/commands に URL を記載しない
- NEVER: ドキュメントタイトルや本文にバージョン番号を記載しない
- NEVER: PreToolUse hooks で exit 1, 3 等を安全なブロックとして使用しない

## Defaults (L2 - Soft)

- Semantic commits を使用: `feat:`, `fix:`, `docs:`, `refactor:`
- Hook スクリプトは bash と zsh の両方でテスト
- 外部リソース採用時は `docs/DEVELOPMENT.md` "Official References" に URL を追加
- skills/agents/commands ではプレーンテキスト帰属のみ使用
- README.md の参照は必要最小限（3-5件以内）
- README.md は 200-250 行以内に収める
- スキルの詳細内容は `reference.md`, `examples.md` に分離

## Guidelines (L3)

- consider: 実行可能ヘルパーは `scripts/` に配置（read ではなく run）
- consider: Skills ではプロセスを定義し、静的知識は避ける
- prefer: 年が必要な場合はシステム時刻から導出（`date +%Y`）
- consider: 外部ツール・API のバージョン固有情報を避け、陳腐化を防止

## More Info

- **For detailed specs and templates**: `docs/DEVELOPMENT.md`
- **For user-facing documentation**: `README.md`
