---
name: insight-recording
description: |
  Standard protocol for recording development insights that can be captured and reviewed later.

  Use when:
  - Discovering reusable patterns or anti-patterns
  - Learning something unexpected about the codebase
  - Making important decisions with clear rationale
  - Finding insights worth documenting for future reference

  This skill defines the insight markers that the insight_capture hook automatically extracts.
allowed-tools: Read
model: sonnet
user-invocable: false
---

# Insight Recording Protocol

A standardized protocol for recording development insights during autonomous work. Marked insights are automatically captured by the `insight_capture.sh` hook and can be reviewed via `/review-insights`.

## How It Works

```
Agent Output          insight_capture.sh          /review-insights
     │                       │                           │
     ├─ PATTERN: ...  ──────►│                           │
     ├─ LEARNED: ...  ──────►├─► pending.json ─────────►│
     └─ Other text           │                           ├─► CLAUDE.md
                             │                           ├─► .claude/rules/
                             │                           └─► Workspace only
```

## Insight Markers

Output insights with these markers (case-insensitive). Only marked content is captured.

| Marker | Use When | Example |
|--------|----------|---------|
| `PATTERN:` | Discovered a reusable pattern | `PATTERN: Repository pattern with Unit of Work at src/repositories/base.ts:15` |
| `ANTIPATTERN:` | Found an approach to avoid | `ANTIPATTERN: Global state in config.js makes testing difficult` |
| `LEARNED:` | Learned something unexpected | `LEARNED: The legacy auth module is deprecated but still used by admin` |
| `DECISION:` | Made an important decision with rationale | `DECISION: Chose event-driven over direct calls due to async patterns` |
| `INSIGHT:` | General observation worth documenting | `INSIGHT: Error handling uses custom AppError class consistently` |

## Marker Selection by Role

Different roles typically emphasize different markers:

| Role | Primary Markers |
|------|-----------------|
| Exploration (code-explorer) | PATTERN, LEARNED, INSIGHT |
| Architecture (code-architect, system-architect) | PATTERN, DECISION, INSIGHT |
| Security (security-auditor) | PATTERN, ANTIPATTERN, LEARNED |
| Quality (qa-engineer) | PATTERN, ANTIPATTERN, LEARNED |
| Legacy (legacy-modernizer) | PATTERN, ANTIPATTERN, LEARNED, DECISION |
| DevOps (devops-sre) | PATTERN, LEARNED, DECISION |
| Frontend (frontend-specialist) | PATTERN, LEARNED, DECISION |
| Backend (backend-specialist) | PATTERN, ANTIPATTERN, DECISION |

## Output Format

```markdown
PATTERN: This codebase uses Repository pattern with Unit of Work for all
database operations - see src/repositories/base.ts:15

LEARNED: The user.status field uses magic numbers (1=active, 2=inactive) -
no documentation exists, discovered through characterization testing

DECISION: Chose Strangler Fig pattern for migration due to existing
/api/v1/ that can coexist with new /api/v2/ endpoints
```

## Rules

### L1 (Hard Rules)
- ALWAYS include file:line references when applicable
- NEVER record trivial or obvious findings
- NEVER record secrets, credentials, or sensitive data

### L2 (Soft Rules)
- Insights should be actionable or educational
- Keep each insight concise (1-3 sentences)
- Focus on project-specific learnings, not general knowledge

### L3 (Guidelines)
- Include context about why the insight matters
- Reference specific code locations for verification
- Consider if the insight would help future developers
