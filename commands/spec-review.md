---
description: "Interactively review and refine a spec and design with the user - feedback loop until approved"
argument-hint: "[path to spec file or feature name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, TodoWrite, TeamCreate, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage
---

# /spec-review - Interactive Plan Review

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

Review a specification and design document interactively with the user. This is a **user-driven feedback loop** — the user reads the plan, gives feedback, and the plan is revised until approved.

For automated machine review, use `--auto` to run parallel review agents before the feedback loop.

## Two Review Modes

| Mode | Command | What Happens |
|------|---------|--------------|
| **Interactive** (default) | `/spec-review feature.md` | User reads plan, gives feedback, iterate |
| **Auto + Interactive** | `/spec-review feature.md --auto` | 5 agents review first, then user feedback loop |

## Execution Instructions

### Step 1: Locate Spec and Design

**Reading vs Editing distinction:**
- **Reading for reference**: Orchestrator MAY read spec/design files directly for quick lookups
- **Editing/modifying**: ALWAYS delegate to product-manager agent

**CRITICAL: The orchestrator never EDITS spec/design files directly - delegate editing to product-manager.**

If `$ARGUMENTS` is provided:
- If it's a file path, use Glob to verify the file exists
- If it's a feature name, search in `docs/specs/` directory using Glob

**Also locate the corresponding design document:**
- If spec is `docs/specs/user-auth.md`, look for `docs/specs/user-auth-design.md` using Glob

If no arguments:
- List available specs in `docs/specs/` using Glob
- Ask user which one to review

**Content loading - choose based on file size:**

Refer to `subagent-contract` skill for unified quick lookup limits.

**For small files (≤200 lines per file, ≤300 lines total):**
- Orchestrator MAY read directly using Read tool for presentation purposes ONLY
- Show content as-is (do NOT synthesize, summarize, or analyze)
- If synthesis/analysis is needed (e.g., understanding trade-offs, identifying gaps), delegate to product-manager

**For large files (>200 lines) or when summary is needed:**
Delegate to `product-manager` agent:
```
Launch product-manager agent:
Task: Summarize spec and design for review presentation
Inputs: Spec file path + Design file path (if exists)
Output:
- Key requirements list
- Architecture summary
- Build sequence
- Trade-offs and decisions
```

**Error Handling for product-manager (content loading):**
If product-manager fails or times out:
1. Retry once with reduced scope (focus on key requirements list only)
2. **Fallback: Read files directly** if retry fails (respecting unified limits from `subagent-contract`):
   - Read spec file directly (≤200 lines)
   - Read design file directly (≤200 lines)
   - If file exceeds 200 lines, read first 200 lines with warning
   - Present raw content with section headers
   - Warn user: "Showing partial content (summarization failed, file exceeded 200 lines)"
3. Add warning to review log: "Content loading via agent failed, using direct read fallback"

### Step 2: Auto Review (only if `--auto` flag is present)

**If `--auto` is specified**, launch parallel review agents before the user feedback loop.

Load the `team-orchestration` skill for Agent Team detection and spawn prompt templates.

#### Agent Team Mode (team-orchestration skill による自動検出)

Agent Team が利用可能な場合（TeamCreate tool が使用可能）:

**Step 2a: チーム作成**

TeamCreate で `spec-review-{feature-name}` チームを作成する。

TeamCreate が失敗またはツールが利用不可の場合、以下の従来パターンにフォールバックし、ユーザーに通知:

```
Agent Team モードは現在利用できません。
サブエージェント（Task tool）モードでレビューを実行します。
```

**Step 2b: チームメイトスポーン（3体）**

以下の 3 体を Task tool で team_name を指定してスポーンする。
各チームメイトのスポーンプロンプトは team-orchestration skill の reference.md から取得:

```
1. security-auditor:
   subagent_type: general-purpose
   team_name: spec-review-{feature-name}
   mode: plan
   prompt: reference.md の security-auditor テンプレート
         + レビュー対象の spec/design パス

2. qa-engineer:
   subagent_type: general-purpose
   team_name: spec-review-{feature-name}
   mode: default
   prompt: reference.md の qa-engineer テンプレート
         + レビュー対象の spec/design パス

3. system-architect:
   subagent_type: general-purpose
   team_name: spec-review-{feature-name}
   mode: plan
   prompt: reference.md の system-architect テンプレート
         + レビュー対象の spec/design パス
```

**Step 2c: サブエージェント並列起動（2体、既存パターン）**

以下の 2 体は従来通り Task tool（チームなし）で起動:
- product-manager: 完全性レビュー
- verification-specialist: 仕様と設計の整合性チェック

Step 2b と 2c は並行して起動すること。

**Step 2d: 相互レビュー促進**

チームメイトは SendMessage で相互に発見を共有する。リーダーは以下を監視:
- security-auditor -> qa-engineer: セキュリティ発見のテスト可能性評価依頼
- system-architect -> security-auditor: 技術的妥当性の検証結果

**Step 2e: インサイト抽出（リーダー側処理）**

全チームメイトの完了報告（SendMessage）を受信後:

1. 各メッセージから `PATTERN` / `LEARNED` / `INSIGHT` / `DECISION` / `ANTIPATTERN` マーカーを検索
2. 発見されたマーカーごとに `insights/pending/` に JSON ファイルを Write:
   ```json
   {"id": "INS-{timestamp}", "category": "[marker-type]", "content": "[content]", "source": "team-member-[role]", "status": "pending"}
   ```
3. Confidence >= 85 の発見については verification-specialist サブエージェントで参照検証

**Step 2f: チームクリーンアップ**

全結果統合後:

1. 各チームメイトに shutdown_request を送信
2. チーム結果とサブエージェント結果を統合
3. Step 3 に進む

**Agent Team エラーリカバリ（サーキットブレイカー - 3段階判断）:**

1. **個別障害（1体無応答）- 3段階判断:**
   - **一次判断: TeammateIdle イベント受信時** → 当該チームメイトから中間報告（SendMessage）を受信済みか確認
     - 中間報告あり → 正常完了の可能性あり、結果待機を継続
     - 中間報告なし → ハングと判断、同ロールのサブエージェント（Task tool）を代替スポーン
   - **二次判断: フォールバックタイムアウト** → TeammateIdle 未受信でも以下の時間で強制タイムアウト
     - security-auditor: 7分（OWASP全項目横断+相互検証、実作業中央値6分+バッファ）
     - qa-engineer: 5分、system-architect: 5分
     - 上限キャップ: 全ロール共通10分（活動ベース延長含む）
   - → 元チームメイトに shutdown_request → 残チームはそのまま継続
   - → ユーザーに「[role] をサブエージェントに切り替えました」と通知
2. **チーム障害（2体以上無応答）**: チームモード全体をブレイク → 全チームメイトに shutdown_request → 下記の従来パターンにフォールバック（5体サブエージェント）。ログに `team-fallback-full` を記録
3. **API エラー（TeamCreate/SendMessage 失敗）**: 即時ブレイク → フォールバック通知をユーザーに表示 → 従来パターンで実行。同一セッション内でチームモードを再試行しない

**Agent Team が利用不可の場合**: 以下の従来パターンを使用（フォールバック）。

#### 従来パターン（Task tool による 5 並列レビュー）

**CRITICAL: Launch all agents in a single message.**

```
1. product-manager: Completeness review
2. system-architect: Technical feasibility review (spec + design)
3. security-auditor: Security review (spec + design)
4. qa-engineer: Quality/testability review
5. verification-specialist: Spec↔design consistency check (if design exists)
```

**Error Handling for Auto-Review agents:**

For each review agent (product-manager, system-architect, security-auditor, qa-engineer):
If agent fails or times out:
1. Check partial output for usable findings
2. Retry once with reduced scope
3. If retry fails, proceed with available results and note gap
4. Add warning to auto-review results: "[Agent] review incomplete"

**CRITICAL: security-auditor failure handling:**
If security-auditor fails after retry:
1. Warn user prominently: "Security review failed. Proceeding without security validation."
2. Add to findings: "MANUAL SECURITY REVIEW RECOMMENDED"
3. Proceed with user acknowledgment

If ALL 5 agents fail:
1. Inform user: "Auto-review failed. Cannot provide automated findings."
2. Offer options:
   - "Retry auto-review"
   - "Skip auto-review and proceed to manual feedback loop"
   - "Cancel and investigate"

**Delegate result consolidation to verification-specialist agent:**
```
Launch verification-specialist agent:
Task: Consolidate review results from 5 agents
Rules:
- Filter by confidence (>= 80)
- De-duplicate across agents (boost confidence by 10 when multiple agents agree)
- Categorize: spec-only / design-only / both
- Sort by severity
Output: Consolidated findings list with confidence scores
```

Use the agent's consolidated output for presentation. Do NOT consolidate results manually.

**Error Handling for verification-specialist:**
If verification-specialist fails or times out:
1. Retry once with reduced scope (focus on de-duplication and severity sorting only)
2. If retry fails:
   - Attempt basic de-duplication: group identical issues from multiple agents
   - Issues reported by 2+ agents: treat as high-confidence (boost by 10)
   - Issues reported by 1 agent: keep original confidence
3. Warn user: "Auto-review consolidation incomplete. Basic de-duplication applied."
4. Proceed with user feedback loop using partially consolidated findings

**Present auto-review results to user:**
```markdown
## Auto-Review Results

Found [N] issues ([X] critical, [Y] important).

### Critical Issues (>= 90)
1. **[Title]** ([Category], affects [Spec/Design/Both])
   [Description]
   Suggested fix: [fix]

### Important Issues (80-89)
...

These will be incorporated into the feedback loop below.
```

**Apply auto-fixes for issues where:**
- Confidence >= 90
- Fix is a simple addition (e.g., adding a missing "Out of Scope" section)
- Fix does NOT change architecture decisions or user-approved requirements
- Always inform the user what was auto-fixed

**Escalate to user** any issue that:
- Changes architecture or core design decisions
- Contradicts user-approved spec requirements
- Has confidence 80-89 (ambiguous)

### Step 3: Present Plan for User Review

Display both spec and design (or summaries for long documents), then provide **guided review questions** to help the user focus:

```
Here is your plan. I'll walk you through key areas to check.

## Guided Review

1. **Requirements**: Do these capture what you want to build?
   [List key requirements from spec]

2. **Architecture**: Does this approach fit your codebase and team?
   [Summary of approach from design]

3. **Build Sequence**: Is this order realistic?
   [Build sequence from design]

4. **Security & Edge Cases**: Anything missing?
   [Key security items and edge cases from spec]

5. **Trade-offs**: Do you agree with these choices?
   [Trade-offs from design]

What would you like to change? (Or "approve" if it looks good)
```

### Step 4: User Feedback Loop

**Loop until the user approves or exits.**

#### Handling Ambiguous Feedback

**CRITICAL:** When user feedback is unclear or contains multiple possible interpretations:

1. **MUST use AskUserQuestion** to present structured options
2. **Do NOT guess** the user's intent
3. Frame questions with concrete trade-offs

Example scenarios requiring AskUserQuestion:

| User Says | Use AskUserQuestion To |
|-----------|----------------------|
| "Make it faster" | Ask: Faster load time? Faster response? Faster build? |
| "Add better error handling" | Ask: Which errors? User-facing messages? Logging? Recovery? |
| "This feels too complex" | Ask: Simplify API? Reduce features? Split into phases? |
| "I'm not sure about this" | Ask: What concerns them? Present alternatives with trade-offs |

After each user message, determine the feedback type:

| User Says | Action |
|-----------|--------|
| "approve" / "looks good" / "LGTM" | Exit loop → Step 5 |
| Specific change request (e.g., "use sessions instead of JWT") | Apply change → re-present affected section |
| Question (e.g., "why did you choose PostgreSQL?") | Answer from design rationale, ask if they want to change it |
| "add X" (new requirement) | Add to spec, check if design needs updating |
| "remove X" | Remove from spec, check if design needs updating |
| "I'm not sure about X" | Discuss trade-offs, present alternatives if relevant |
| "start over" / "re-plan" | Suggest re-running `/spec-plan` |

#### Handling Changes That Affect Architecture

**CRITICAL: The orchestrator does NOT edit spec/design files directly. ALWAYS delegate.**

**If a change is small** (wording, adding an edge case, clarifying a requirement):

Delegate to product-manager:
```
Launch product-manager agent:
Task: Apply small change to spec/design during review
Change request: [user's feedback]
Spec file: [spec file path]
Design file: [design file path] (if applicable)
Constraint: Wording/clarification only, no architecture changes
Output: Summary of changes with before/after
```

Re-present the changed section using agent output.

**If a change requires re-architecture** (e.g., "use a different database", "change the auth approach"):
1. Inform the user: "This change affects the architecture design. I have two options:"
   - **Option A**: I'll delegate to code-architect for design analysis, then product-manager for edits (best-effort, no re-exploration)
   - **Option B**: Re-run `/spec-plan` with this new constraint for a thorough re-analysis
2. If Option A:
   - Delegate design revision analysis to code-architect agent
   - Delegate actual edits to product-manager agent using code-architect's output
   - Re-present the updated design, continue loop
3. If Option B: update progress file, exit, suggest `/spec-plan` command

#### After Each Change

After applying a change:
```
Updated [spec/design/both]. Here's what changed:

[Summary of change]

Anything else to change? (Or "approve" to finalize)
```

### Step 5: Approval and Handoff

When the user approves:

1. **Save final versions** of spec and design files
2. **Save review log** to `docs/specs/[feature-name]-review.md`:
   ```markdown
   ## Review Log: [Feature Name]

   ### Review Mode
   [Interactive / Auto + Interactive]

   ### Changes Made
   1. [Change description] (user requested)
   2. [Change description] (auto-review fix)
   ...

   ### Auto-Review Issues (if --auto was used)
   - Resolved: [N]
   - Deferred: [N]

   ### Verdict
   APPROVED by user
   ```

3. **Update progress file**:
   ```json
   {
     "currentPhase": "review-complete",
     "currentTask": "Review complete - approved by user",
     "resumptionContext": {
       "nextAction": "Run /spec-implement to begin implementation",
       "reviewVerdict": "APPROVED",
       "changesApplied": [N]
     }
   }
   ```

4. **Present next step:**
   ```
   Plan approved. Run `/spec-implement docs/specs/[feature-name].md` to start building.
   ```

## Usage Examples

```bash
# Interactive review (user feedback only)
/spec-review docs/specs/user-authentication.md

# Auto review first, then user feedback
/spec-review docs/specs/user-authentication.md --auto

# Review by feature name
/spec-review user-authentication

# Interactive - list and choose
/spec-review
```

---

## Rules (L1 - Hard)

- ALWAYS present guided review questions (don't just say "any feedback?")
- ALWAYS loop until user explicitly approves or exits
- NEVER auto-fix changes that affect architecture or user-approved requirements
- ALWAYS update progress file on completion
- ALWAYS save review log
- ALWAYS use AskUserQuestion when:
  - User feedback contains multiple possible interpretations
  - A decision requires choosing between trade-offs (e.g., "should we prioritize X or Y?")
  - Clarification is needed before making changes to spec or design
- NEVER guess user intent when feedback is ambiguous — ask first
- MUST fall back to Task tool pattern when Agent Team is unavailable (TeamCreate tool not accessible)
- NEVER allow team members to ask the user directly — all user interaction MUST go through the leader via AskUserQuestion

## Defaults (L2 - Soft)

- Present full guided review on first pass; show only changed sections on subsequent passes
- For `--auto` mode, apply fixes with confidence >= 90 that don't change architecture
- Save review log to docs/specs/[feature-name]-review.md
- Boost auto-review confidence by 10 when multiple agents agree

## Guidelines (L3)

- Consider presenting alternatives when user is unsure
- For large spec/design documents, summarize sections rather than displaying everything
