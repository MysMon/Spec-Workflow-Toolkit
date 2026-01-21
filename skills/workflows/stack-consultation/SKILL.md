---
name: stack-consultation
description: |
  Interactive technology stack consultation for new projects using dynamic research. Use when:
  - Starting a new project with no existing codebase
  - User doesn't know what technology stack to use
  - User wants recommendations based on current best practices
  - Need to research and compare technology options with latest information
  - User says "what stack should I use" or "help me choose"
  Trigger phrases: stack consultation, recommend stack, what technology, choose tools, new project stack, tech advice, help me decide
allowed-tools: AskUserQuestion, WebSearch, WebFetch, Read, Write, Bash, Glob, Grep, Task, TodoWrite
model: sonnet
user-invocable: true
---

# Stack Consultation

Interactive consultation that helps users choose and set up technology stacks through **requirements-based interviewing** and **dynamic research** using WebSearch/WebFetch.

## Design Principles

1. **No Hardcoded Technologies**: Never recommend specific frameworks by name from memory. Always use WebSearch to find current options.
2. **Requirements-First**: Understand what the user needs before researching solutions.
3. **Domain-Agnostic**: Support any project type (web, mobile, embedded, games, data, desktop, CLI, etc.).
4. **Dynamic Discovery**: Use RAG (WebSearch + WebFetch) to gather current technology landscape.
5. **Transparent Trade-offs**: Present options with pros/cons based on research, not assumptions.

---

## Workflow Phases

```
Phase 1: Requirements Discovery  → Understand what user needs (not what category)
Phase 2: Constraint Mapping      → Identify limitations and preferences
Phase 3: Dynamic Research (RAG)  → Search for current solutions
Phase 4: Analysis & Comparison   → Evaluate options against requirements
Phase 5: Collaborative Decision  → Present findings, decide together
Phase 6: Scaffolding            → Set up the decided stack
```

---

## Phase 1: Requirements Discovery

**Goal**: Understand the user's needs in terms of **what the system must do**, not what technology category it fits.

### 1.1 Core Purpose

```
Question: "What is the primary purpose of what you're building?"
Header: "Purpose"
(Free text response - don't constrain with options)
```

If user's response is vague, ask clarifying questions:
- "Who or what will use this system?"
- "What problem does it solve?"
- "What does success look like?"

### 1.2 Interaction Model

```
Question: "How will users/systems interact with this?"
Header: "Interaction"
Options:
- "Humans via visual interface (screens, graphics)"
- "Humans via text/voice commands"
- "Other software via API/messages"
- "Physical world (sensors, actuators, hardware)"
- "No direct interaction (background/batch processing)"
```

### 1.3 Data Characteristics

```
Question: "What kind of data will this handle?"
Header: "Data"
MultiSelect: true
Options:
- "Structured records (users, orders, inventory)"
- "Unstructured content (text, documents, media)"
- "Real-time streams (events, sensors, logs)"
- "Large datasets requiring batch processing"
```

### 1.4 Communication Patterns

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

### 1.5 Deployment Environment

```
Question: "Where will this run?"
Header: "Deploy"
Options:
- "User's device (phone, desktop, browser)"
- "Cloud servers"
- "Edge/embedded devices"
- "Hybrid (multiple environments)"
- "Not sure yet"
```

---

## Phase 2: Constraint Mapping

**Goal**: Identify practical limitations that affect technology choices.

### 2.1 Team Skills

```
Question: "What programming languages does your team know well? (if any)"
Header: "Languages"
(Free text - don't constrain options)
```

### 2.2 Existing Systems

```
Question: "Are there existing systems this must integrate with?"
Header: "Integration"
Options:
- "Yes, specific platforms/APIs (I'll describe)"
- "Must follow organizational standards"
- "No constraints, greenfield project"
```

### 2.3 Resource Constraints

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

### 2.4 Scale Expectations

```
Question: "What scale do you anticipate?"
Header: "Scale"
Options:
- "Personal/small team use (<100 users)"
- "Department/organization (100-10,000)"
- "Public service (10,000+)"
- "Unknown/variable"
```

---

## Phase 3: Dynamic Research (RAG)

**Goal**: Use WebSearch and WebFetch to discover current technology options based on gathered requirements.

### 3.1 Construct Search Queries

Transform requirements into search queries. **Never search for specific technology names from memory.**

#### Query Construction Patterns

| Requirement | Search Query Template |
|-------------|----------------------|
| Visual interface + browser | `"best frontend frameworks [year] comparison"` |
| API backend | `"backend frameworks [year] [language if specified] production"` |
| Real-time communication | `"real-time communication tools [year] comparison"` |
| Data storage | `"database comparison [year] [data type]"` |
| Deployment | `"deployment platforms [year] [constraint]"` |

Use the system clock for the year (e.g., `CURRENT_YEAR=$(date +%Y)`), not model memory.
If current-year results are thin (e.g., early in the year), broaden queries by adding the previous year and a yearless "latest/recent" variant.

#### Example Query Generation

```
User needs: Visual interface, structured data, real-time updates, cloud deployment, team knows Python

CURRENT_YEAR=$(date +%Y)
PREV_YEAR=$((CURRENT_YEAR - 1))

Queries to run:
1. "best frontend frameworks ${CURRENT_YEAR} comparison production"
2. "Python backend frameworks ${CURRENT_YEAR} real-time support"
3. "database for real-time applications ${CURRENT_YEAR}"
4. "cloud deployment platforms ${CURRENT_YEAR} Python applications"

Fallbacks (if results are sparse):
- "best frontend frameworks ${PREV_YEAR} comparison production"
- "Python backend frameworks ${PREV_YEAR} real-time support"
- "database for real-time applications ${PREV_YEAR}"
- "cloud deployment platforms ${PREV_YEAR} Python applications"
- "best frontend frameworks latest comparison production"
- "Python backend frameworks recent real-time support"
- "database for real-time applications recent comparison"
- "cloud deployment platforms recent Python applications"
```

### 3.2 Execute Research

For each technology category needed:

1. **WebSearch** with constructed query
2. **Identify top candidates** from search results (usually 3-5)
3. **WebFetch** on authoritative sources for each candidate:
   - Official documentation (for current version, features)
   - Recent comparison articles (< 1 year old)
   - Production experience reports

### 3.3 Extract Information

For each candidate technology, extract:

| Attribute | What to Find |
|-----------|--------------|
| Current version | Latest stable release |
| Primary use case | What it's designed for |
| Strengths | Documented advantages |
| Weaknesses | Known limitations |
| Learning curve | Complexity for new users |
| Community health | Activity, support availability |
| License/cost | Open source? Pricing model? |

### 3.4 Research Output

Compile findings into structured format:

```markdown
## Research Results: [Category]

### Candidates Discovered

| Name | Version | Best For | License |
|------|---------|----------|---------|
| [A]  | [ver]   | [use]    | [lic]   |
| [B]  | [ver]   | [use]    | [lic]   |
| [C]  | [ver]   | [use]    | [lic]   |

### Detailed Analysis

#### [Candidate A]
- **Strengths**: [from research]
- **Weaknesses**: [from research]
- **Fit for your requirements**: [analysis]

### Sources
- [Title] (date) - [url]
```

---

## Phase 4: Analysis & Comparison

**Goal**: Evaluate discovered options against user's specific requirements.

### 4.1 Evaluation Framework

Score each candidate against the evaluation axes:

| Axis | Question | Weight |
|------|----------|--------|
| **Requirement Fit** | Does it solve the stated problem? | High |
| **Constraint Compatibility** | Works with team skills, budget, timeline? | High |
| **Integration** | Works with other chosen components? | Medium |
| **Maturity** | Production-ready? Active maintenance? | Medium |
| **Ecosystem** | Libraries, tools, documentation quality? | Medium |
| **Future-proofing** | Long-term viability, migration path? | Low |

### 4.2 Trade-off Matrix

For the top candidates, create explicit trade-off comparison:

```markdown
## Trade-off Analysis

| Aspect | [Option A] | [Option B] | [Option C] |
|--------|------------|------------|------------|
| Your requirement 1 | ✅ Strong | ⚠️ Partial | ❌ Weak |
| Your requirement 2 | ⚠️ Partial | ✅ Strong | ✅ Strong |
| Team skill match | ✅ | ❌ | ⚠️ |
| Learning curve | Low | High | Medium |
| Community activity | High | Medium | Growing |
```

### 4.3 Recommendation Formulation

Based on analysis, formulate recommendation:

```markdown
## Recommendation

### Primary Choice: [Technology]
**Why**: [Specific reasons tied to user's requirements]

### Alternative: [Technology]
**Consider if**: [Conditions where this would be better]

### Not Recommended: [Technology]
**Why not**: [Specific mismatch with requirements]
```

---

## Phase 5: Collaborative Decision

**Goal**: Present findings and make decisions together with the user.

### 5.1 Present Findings

Show the user:
1. Summary of their requirements
2. Research methodology used
3. Candidates discovered
4. Trade-off analysis
5. Your recommendation with reasoning

### 5.2 Decision Points

```
Question: "Based on this research, how would you like to proceed?"
Header: "Decision"
Options:
- "Your recommendation looks good, let's proceed"
- "I'd like to explore [specific technology] more"
- "Can you research alternative approaches?"
- "Let me reconsider my requirements"
```

### 5.3 Iterate if Needed

If user wants more research:
- Conduct additional WebSearch on specific topics
- Dive deeper with WebFetch on specific technologies
- Revisit requirements if they've changed

### 5.4 Final Confirmation

Before scaffolding, confirm the complete stack:

```markdown
## Final Stack Decision

| Layer | Choice | Rationale |
|-------|--------|-----------|
| [Layer 1] | [Tech] | [Why] |
| [Layer 2] | [Tech] | [Why] |

Proceed with project setup?
```

---

## Phase 6: Scaffolding

**Goal**: Set up the project with the decided technologies.

### 6.1 Research Setup Commands

**Do not assume setup commands from memory.** Use WebSearch/WebFetch to find current official setup instructions:

```
WebSearch: "[technology name] getting started official documentation [year]"
WebFetch: [official docs URL] → "Extract installation and project setup commands"
```

### 6.2 Execute Setup

Run the officially documented setup commands.

### 6.3 Post-Setup

1. **Initialize version control** (git init, .gitignore)
2. **Create CLAUDE.md** documenting:
   - Decided stack with rationale
   - Setup commands used
   - Key architectural decisions
3. **Verify setup** by running basic commands (build, test)

### 6.4 Handoff

```markdown
## Project Setup Complete

### Stack
[List of technologies with versions]

### Setup Commands Used
[Commands that were run]

### Next Steps
- [First recommended action based on the stack]
- [Second recommended action]

### Documentation Created
- CLAUDE.md - Project context for future sessions
- README.md - Human-readable project documentation
```

---

## Rules (L1 - Hard)

Critical for providing accurate, current recommendations.

- NEVER recommend technologies by name without first researching current options
- NEVER assume technology features from training data - always verify with WebFetch
- NEVER use technology-specific questions in Phase 1 (requirements first)
- ALWAYS confirm decisions before scaffolding (user must approve)

## Defaults (L2 - Soft)

Important for quality consultation. Override with reasoning when appropriate.

- Use WebSearch to discover current options
- Present trade-offs based on research, not assumptions
- Verify setup commands from official documentation
- Create CLAUDE.md after project setup

## Guidelines (L3)

Recommendations for effective stack consultation.

- Consider presenting 3-5 candidates for each technology category
- Prefer creating a trade-off matrix for complex decisions
- Consider future-proofing in technology evaluation
