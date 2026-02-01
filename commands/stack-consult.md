---
description: "Interactive stack consultation: requirements interview, dynamic research, and project scaffolding"
argument-hint: "[optional: project name or brief description]"
allowed-tools: AskUserQuestion, WebSearch, WebFetch, Read, Write, Bash, Glob, Grep, Task, TodoWrite, Edit
---

# /stack-consult - Interactive Stack Consultation

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

A domain-agnostic consultation system that guides users from "I have an idea" to "I have a working project structure" through requirements-based interviews and dynamic technology research.

## Design Principles

| Principle | Implementation |
|-----------|----------------|
| **No hardcoded technologies** | All options discovered via WebSearch |
| **Requirements-first** | Understand needs before researching solutions |
| **Domain-agnostic** | Works for any project type |
| **Dynamic discovery** | RAG (WebSearch + WebFetch) for current info |
| **Transparent trade-offs** | Evidence-based comparisons |

---

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Requirements Discovery                            │
│  "What does your system need to do?"                       │
├─────────────────────────────────────────────────────────────┤
│  Phase 2: Constraint Mapping                                │
│  "What are your limitations and preferences?"              │
├─────────────────────────────────────────────────────────────┤
│  Phase 3: Dynamic Research (RAG)                            │
│  WebSearch + WebFetch to discover current options          │
├─────────────────────────────────────────────────────────────┤
│  Phase 4: Analysis & Comparison                             │
│  Evaluate options against requirements                     │
├─────────────────────────────────────────────────────────────┤
│  Phase 5: Collaborative Decision                            │
│  Present findings, decide together                         │
├─────────────────────────────────────────────────────────────┤
│  Phase 6: Scaffolding                                       │
│  Set up project with decided stack                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Execution Instructions

### Phase 1: Requirements Discovery

**Goal**: Understand what the user needs in terms of system capabilities, not technology categories.

#### 1.1 Core Purpose

Start with an open question to understand the project vision:

```
"What is the primary purpose of what you're building? Who will use it and what problem does it solve?"
```

Allow free-form response. If vague, ask follow-up:
- "What does success look like for this project?"
- "Can you describe a typical use case?"

#### 1.2 Interaction Model

```
Question: "How will users or other systems interact with this?"
Header: "Interaction"
Options:
- "Humans via visual interface (screens, graphics)"
- "Humans via text/voice commands (CLI, chatbot)"
- "Other software via API/messages"
- "Physical world (sensors, actuators, hardware)"
- "No direct interaction (background/batch processing)"
```

#### 1.3 Data Characteristics

```
Question: "What kind of data will this system handle?"
Header: "Data"
MultiSelect: true
Options:
- "Structured records (users, orders, inventory)"
- "Unstructured content (text, documents, media)"
- "Real-time streams (events, sensors, logs)"
- "Large datasets requiring batch processing"
```

#### 1.4 Communication Patterns

```
Question: "What communication patterns are needed?"
Header: "Comms"
MultiSelect: true
Options:
- "Request-response (user asks, system answers)"
- "Real-time bidirectional (chat, collaboration)"
- "Push notifications (alerts, updates)"
- "Offline-capable (works without network)"
```

#### 1.5 Deployment Environment

```
Question: "Where will this system run?"
Header: "Deploy"
Options:
- "User's device (phone, desktop, browser)"
- "Cloud servers"
- "Edge/embedded devices"
- "Hybrid (multiple environments)"
- "Not sure yet"
```

### Phase 2: Constraint Mapping

**Goal**: Identify practical limitations that affect technology choices.

#### 2.1 Team Skills

```
Question: "What programming languages or tools does your team know well? (if any specific)"
Header: "Skills"
```

Accept free-form response. Don't constrain with predefined language options.

#### 2.2 Existing Systems

```
Question: "Are there existing systems this must work with?"
Header: "Integration"
Options:
- "Yes, I'll describe the systems/APIs"
- "Must follow organizational/company standards"
- "No constraints, completely new project"
```

If "Yes", ask follow-up to understand integration requirements.

#### 2.3 Resource Constraints

```
Question: "What are your primary constraints?"
Header: "Constraints"
MultiSelect: true
Options:
- "Limited budget (prefer free/cheap options)"
- "Tight timeline (prefer familiar, proven tools)"
- "Small team (prefer simpler stacks)"
- "Regulatory/compliance requirements"
```

#### 2.4 Scale Expectations

```
Question: "What scale do you anticipate?"
Header: "Scale"
Options:
- "Personal/small team use (<100 users)"
- "Department/organization (100-10,000)"
- "Public service (10,000+)"
- "Unknown/variable"
```

### Phase 3: Dynamic Research (RAG)

**Goal**: Discover current technology options through web research.

**CRITICAL**: Never recommend technologies from memory. Always use WebSearch.

#### 3.1 Map Requirements to Search Queries

Based on interview responses, construct targeted searches:

| Gathered Requirement | Query Pattern |
|---------------------|---------------|
| Visual interface needed | `"[platform] UI frameworks [year] comparison"` |
| API backend needed | `"backend frameworks [year] [language] production"` |
| Real-time needed | `"real-time communication tools [year]"` |
| Data storage needed | `"database comparison [year] [data type]"` |
| Deployment needed | `"deployment platforms [year] [constraints]"` |

Use the system clock for the year (e.g., `CURRENT_YEAR=$(date +%Y)`), not model memory.
If current-year results are thin (e.g., early in the year), broaden queries by adding the previous year and a yearless "latest/recent" variant.

Example query generation:
```
Requirements: Visual interface, structured data, real-time updates, Python team

CURRENT_YEAR=$(date +%Y)
PREV_YEAR=$((CURRENT_YEAR - 1))

Queries:
1. "web UI frameworks ${CURRENT_YEAR} comparison"
2. "Python backend frameworks ${CURRENT_YEAR} real-time"
3. "database real-time applications ${CURRENT_YEAR}"

Fallbacks (if results are sparse):
- "web UI frameworks ${PREV_YEAR} comparison"
- "Python backend frameworks ${PREV_YEAR} real-time"
- "database real-time applications ${PREV_YEAR}"
- "web UI frameworks latest comparison"
- "Python backend frameworks recent real-time"
- "database real-time applications recent comparison"
```

#### 3.2 Execute Research

For each technology category:

1. **WebSearch** with constructed query
2. **Identify top 3-5 candidates** from results
3. **WebFetch** authoritative sources:
   - Official documentation (version, features)
   - Recent comparison articles (< 1 year)
   - Production experience reports

**Error Handling for WebSearch/WebFetch:**

If WebSearch returns no results or fails:
1. Retry with broader query (remove year, add "latest" or "recent")
2. Try alternative search terms (synonyms, related concepts)
3. If still no results, inform user:
   ```
   Research for [category] returned limited results.

   Options:
   1. Try different search terms (I'll suggest alternatives)
   2. Skip this category and proceed with available information
   3. You provide candidate technologies to research
   ```

If WebFetch fails (timeout, blocked, or unavailable):
1. Try alternative sources from search results
2. Fall back to search snippets for basic information
3. Document limitations: `"Note: Could not verify from official source"`

#### 3.3 Extract Key Information

For each candidate:
- Current version
- Primary strengths and weaknesses
- Use cases it's designed for
- Community health indicators
- License and cost model

#### 3.4 Compile Research Summary

```markdown
## Research Results: [Category]

### Candidates Discovered
| Name | Version | Best For | Source |
|------|---------|----------|--------|
| [A]  | [ver]   | [use]    | [url]  |
| [B]  | [ver]   | [use]    | [url]  |

### Analysis
[Findings for each candidate with strengths/weaknesses]
```

### Phase 4: Analysis & Comparison

**Goal**: Evaluate discovered options against user's requirements.

#### 4.1 Apply Evaluation Framework

For each candidate, assess:

| Axis | Question |
|------|----------|
| **Requirement Fit** | Does it solve the stated problem? |
| **Constraint Match** | Compatible with skills, budget, timeline? |
| **Maturity** | Production-ready? Maintained? |
| **Ecosystem** | Documentation? Libraries? Tools? |
| **Integration** | Works with other chosen components? |

#### 4.2 Create Trade-off Matrix

```markdown
| Aspect | [Option A] | [Option B] | [Option C] |
|--------|------------|------------|------------|
| Requirement 1 | Strong | Partial | Weak |
| Requirement 2 | Partial | Strong | Strong |
| Team skill match | Strong | Weak | Partial |
| Learning curve | Low | High | Medium |
```

#### 4.3 Formulate Recommendation

```markdown
## Recommendation

### Primary: [Technology]
**Why**: [Reasons tied to their specific requirements]

### Alternative: [Technology]
**Consider if**: [Conditions where this would be better]
```

### Phase 5: Collaborative Decision

**Goal**: Present findings and make decisions together.

#### 5.1 Present to User

Show:
1. Summary of their requirements
2. What was searched for
3. Candidates discovered
4. Trade-off analysis
5. Recommendation with reasoning

#### 5.2 Get User Decision

```
Question: "Based on this research, how would you like to proceed?"
Header: "Decision"
Options:
- "Your recommendation looks good, let's set up the project"
- "I'd like to explore [specific option] more"
- "Can you research alternative approaches?"
- "Let me reconsider my requirements"
```

#### 5.3 Iterate if Needed

- Additional research on specific technologies
- Deeper comparison between specific options
- Revisit requirements if changed

#### 5.4 Final Confirmation

```markdown
## Final Stack Decision

| Component | Choice | Rationale |
|-----------|--------|-----------|
| [Layer 1] | [Tech] | [Why]     |
| [Layer 2] | [Tech] | [Why]     |

Proceed with setup?
```

### Phase 6: Scaffolding

**Goal**: Set up the project with decided technologies.

#### 6.1 Research Setup Commands

**Do not assume setup commands.** Search for current official instructions:

Use the system clock for the year (e.g., `CURRENT_YEAR=$(date +%Y)`), not model memory.
If current-year results are thin, also try the previous year or a yearless "latest/recent" query.

```
WebSearch: "[technology] getting started official documentation ${CURRENT_YEAR}"
WebFetch: [official docs] → "Extract installation and setup commands"
```

#### 6.2 Execute Setup

Run officially documented commands.

#### 6.3 Post-Setup Tasks

1. **Initialize git** with appropriate .gitignore
2. **Create CLAUDE.md** documenting:
   - Decided stack with rationale
   - Commands used for setup
   - Key decisions made
3. **Verify setup** works (build, run)

#### 6.4 Handoff

```markdown
## Project Setup Complete

### Stack
[Technologies with versions]

### Commands Used
[Exact setup commands]

### Next Steps
- [First recommended action]
- [Second recommended action]

### Documentation Created
- CLAUDE.md - Context for Claude
- README.md - Human documentation
```

---

## Usage Examples

```bash
# Full consultation from scratch
/stack-consult

# With project context
/stack-consult inventory management system

# Restart consultation with different requirements
/stack-consult
```

---

## Rules (L1 - Hard)

Critical for providing accurate, current recommendations.

- NEVER recommend technologies without first researching via WebSearch
- NEVER assume features or setup commands from training data
- NEVER use technology-specific options in Phase 1 questions (requirements first)
- ALWAYS confirm decisions before scaffolding (user must approve)
- MUST use system clock to generate current year for all searches (`CURRENT_YEAR=$(date +%Y)`)
- NEVER use training data for years, versions, or command syntax — always verify via WebSearch
- MUST use year-aware search queries and add previous-year fallbacks if results are sparse
- MUST use AskUserQuestion for all Phase 1-2 requirement gathering
- NEVER guess user requirements — always ask explicitly

## Defaults (L2 - Soft)

Important for quality consultation. Override with reasoning when appropriate.

- Use WebSearch to discover current options
- Present trade-offs based on research evidence
- Verify setup commands from official documentation
- Create CLAUDE.md after project setup

## Guidelines (L3)

Recommendations for effective consultation.

- Consider presenting 3-5 candidates per technology category
- Prefer creating trade-off matrices for complex decisions
