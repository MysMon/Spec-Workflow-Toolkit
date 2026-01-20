---
name: stack-consultation
description: |
  Interactive technology stack consultation for new projects. Use when:
  - Starting a completely new project with no existing codebase
  - User doesn't know what technology stack to use
  - User wants recommendations for frameworks, databases, or tools
  - Need to research and compare technology options
  - User says "what stack should I use" or "help me choose"
  Trigger phrases: stack consultation, recommend stack, what framework, choose technology, new project stack, tech stack advice, which database, help me decide stack
allowed-tools: AskUserQuestion, WebSearch, WebFetch, Read, Write, Bash, Glob, Grep, Task, TodoWrite
model: sonnet
user-invocable: true
---

# Stack Consultation

Interactive consultation system that helps users choose and set up technology stacks for new projects through structured interviews, real-time research, and guided scaffolding.

## Overview

This skill combines:
1. **Structured Interviewing** - Understand what you're building
2. **RAG-Powered Research** - Fetch latest technology information
3. **Trade-off Analysis** - Compare options with pros/cons
4. **Collaborative Decision** - Make choices together
5. **Project Scaffolding** - Set up the decided stack

## Workflow Phases

```
Phase 1: Discovery Interview    → Understand project needs
Phase 2: Constraint Mapping     → Identify limitations
Phase 3: Stack Research (RAG)   → Fetch current best practices
Phase 4: Recommendation         → Present options with trade-offs
Phase 5: Decision              → Confirm choices with user
Phase 6: Scaffolding           → Build the project structure
```

---

## Phase 1: Discovery Interview

**Goal**: Understand what the user wants to build.

### 1.1 Project Type

```
Question: "What type of application are you building?"
Header: "App Type"
Options:
- "Web Application (browser-based)"
- "Mobile App (iOS/Android)"
- "API/Backend Service"
- "CLI Tool or Script"
```

### 1.2 Project Nature

```
Question: "What best describes your project?"
Header: "Nature"
Options:
- "MVP/Prototype (speed matters most)"
- "Production application (reliability matters)"
- "Learning project (educational)"
- "Enterprise system (scale & compliance)"
```

### 1.3 Core Features

```
Question: "What are the main features? (select all that apply)"
Header: "Features"
MultiSelect: true
Options:
- "User authentication & accounts"
- "Real-time updates (chat, notifications)"
- "File uploads & media handling"
- "Payment processing"
```

### 1.4 Additional Context

If user selects "Web Application":
```
Question: "What type of web application?"
Header: "Web Type"
Options:
- "Content site / Blog / Marketing"
- "SaaS / Dashboard / Admin panel"
- "E-commerce / Marketplace"
- "Social / Community platform"
```

---

## Phase 2: Constraint Mapping

**Goal**: Identify technical and practical limitations.

### 2.1 Team Experience

```
Question: "What languages/frameworks does your team know well?"
Header: "Experience"
MultiSelect: true
Options:
- "JavaScript/TypeScript"
- "Python"
- "Go / Rust"
- "None specific (open to learn)"
```

### 2.2 Infrastructure Constraints

```
Question: "Any infrastructure requirements?"
Header: "Infra"
Options:
- "Cloud (AWS/GCP/Azure) - flexible"
- "Serverless preferred (Vercel/Netlify/Cloudflare)"
- "Self-hosted / On-premise required"
- "No preference"
```

### 2.3 Budget Considerations

```
Question: "What's your infrastructure budget expectation?"
Header: "Budget"
Options:
- "Free tier / Minimal ($0-50/month)"
- "Startup budget ($50-500/month)"
- "Growth budget ($500-5000/month)"
- "Enterprise (cost not primary concern)"
```

### 2.4 Timeline

```
Question: "When do you need the first version?"
Header: "Timeline"
Options:
- "ASAP (days to 1-2 weeks)"
- "Short-term (1-2 months)"
- "Medium-term (3-6 months)"
- "Long-term (6+ months)"
```

---

## Phase 3: Stack Research (RAG)

**Goal**: Fetch current technology information using web search.

### Research Strategy

Based on interview responses, construct targeted searches:

#### For Web Applications
```
Search queries:
1. "[framework] vs [framework] 2025 comparison"
2. "best [category] framework [year] production"
3. "[framework] performance benchmarks latest"
4. "[framework] developer experience 2025"
```

#### For Databases
```
Search queries:
1. "[db type] comparison 2025 (PostgreSQL vs MySQL vs ...)"
2. "best database for [use case] 2025"
3. "[database] scalability production experience"
```

#### For Hosting/Infrastructure
```
Search queries:
1. "[platform] pricing 2025 comparison"
2. "best hosting for [framework] 2025"
3. "[platform] developer experience review"
```

### Information Extraction

After searching, use WebFetch on top results to extract:

1. **Pros/Cons** - Advantages and disadvantages
2. **Use Cases** - When to use vs. when not to use
3. **Production Stories** - Real-world experiences
4. **Performance Data** - Benchmarks if available
5. **Community Health** - Activity, support, ecosystem

### Research Output Template

```markdown
## Technology Research: [Category]

### Option A: [Technology Name]
- **Latest Version**: [version]
- **Best For**: [use cases]
- **Pros**: [list]
- **Cons**: [list]
- **Community**: [health assessment]
- **Source**: [publication/date]

### Option B: [Technology Name]
...

### Comparison Summary
| Aspect | Option A | Option B | Option C |
|--------|----------|----------|----------|
| Learning Curve | ... | ... | ... |
| Performance | ... | ... | ... |
| Ecosystem | ... | ... | ... |
| Cost | ... | ... | ... |
```

---

## Phase 4: Recommendation

**Goal**: Present analyzed options with clear trade-offs.

### Recommendation Template

```markdown
## Stack Recommendation for [Project Name]

Based on your requirements:
- Project type: [type]
- Key features: [features]
- Team experience: [experience]
- Timeline: [timeline]

### Recommended Stack

#### Frontend
**Recommendation: [Framework]**
- Why: [reasons based on requirements]
- Alternative: [alternative] if [condition]

#### Backend
**Recommendation: [Framework]**
- Why: [reasons]
- Alternative: [alternative]

#### Database
**Recommendation: [Database]**
- Why: [reasons]
- Alternative: [alternative]

#### Hosting
**Recommendation: [Platform]**
- Why: [reasons]
- Estimated Cost: [range]

### Trade-off Summary

| Decision | Optimized For | Trade-off |
|----------|---------------|-----------|
| [Choice] | [Benefit] | [Cost] |
```

### Present to User

```
Question: "Here's my recommended stack. How would you like to proceed?"
Header: "Decision"
Options:
- "Looks good, let's proceed with setup"
- "I'd like to discuss alternatives"
- "Can you research [specific technology] more?"
- "Let me adjust some requirements"
```

---

## Phase 5: Decision

**Goal**: Confirm final technology choices.

### Final Confirmation

```
Question: "Confirm your stack choices:"
Header: "Confirm"
Options:
- "Yes, proceed with: [summary of choices]"
- "I want to change: [component]"
```

### Document Decision

Create a stack decision record:

```markdown
# Stack Decision Record

**Project**: [name]
**Date**: [date]
**Decision Made By**: User + Claude consultation

## Final Stack

| Layer | Technology | Version | Rationale |
|-------|------------|---------|-----------|
| Frontend | [tech] | [ver] | [why] |
| Backend | [tech] | [ver] | [why] |
| Database | [tech] | [ver] | [why] |
| Hosting | [tech] | - | [why] |

## Alternatives Considered

| Layer | Alternative | Why Not Chosen |
|-------|-------------|----------------|
| ... | ... | ... |

## Research Sources

- [Source 1]
- [Source 2]
```

---

## Phase 6: Scaffolding

**Goal**: Set up the project with the decided stack.

### Scaffolding Strategy

Based on confirmed stack, execute appropriate setup:

#### JavaScript/TypeScript Projects

```bash
# Next.js
npx create-next-app@latest [project-name] --typescript --tailwind --eslint --app

# Vite + React
npm create vite@latest [project-name] -- --template react-ts

# Express + TypeScript
mkdir [project-name] && cd [project-name]
npm init -y
npm install express typescript @types/express @types/node ts-node
npx tsc --init
```

#### Python Projects

```bash
# FastAPI
mkdir [project-name] && cd [project-name]
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn sqlalchemy

# Django
pip install django
django-admin startproject [project-name]
```

#### Go Projects

```bash
mkdir [project-name] && cd [project-name]
go mod init [module-name]
# Install chosen framework (gin, echo, fiber, etc.)
```

### Post-Scaffolding Setup

1. **Initialize Git**
   ```bash
   git init
   echo "node_modules/\n.env\n.env.local" > .gitignore
   ```

2. **Create initial structure**
   - Set up recommended folder structure
   - Create placeholder files

3. **Configure development tools**
   - ESLint/Prettier (JS/TS)
   - Black/Ruff (Python)
   - golangci-lint (Go)

4. **Generate CLAUDE.md**
   - Document the decided stack
   - Add project-specific rules

### Scaffolding Output

```markdown
## Project Setup Complete

### Created Structure
```
[project-name]/
├── src/
│   └── ...
├── package.json (or equivalent)
├── .gitignore
├── CLAUDE.md
└── README.md
```

### Next Steps
1. `cd [project-name]`
2. Review generated files
3. Run `npm install` (or equivalent)
4. Start development with `npm run dev`

### Recommended First Tasks
- [ ] Set up database connection
- [ ] Implement basic routing
- [ ] Add authentication (if needed)
```

---

## Quick Decision Trees

### Web Application

```
User Auth Required?
├── Yes → Consider: Supabase, Firebase, Auth.js
└── No → Simpler setup

Real-time needed?
├── Yes → Consider: Socket.io, Supabase Realtime, Pusher
└── No → Standard REST/GraphQL

SEO important?
├── Yes → SSR/SSG: Next.js, Nuxt, Astro
└── No → SPA: Vite+React, Vue
```

### Database Selection

```
Data structure?
├── Relational → PostgreSQL (default), MySQL, SQLite
├── Document → MongoDB, Firestore
├── Key-Value → Redis, DynamoDB
└── Graph → Neo4j, Dgraph

Scale expectation?
├── Small (<10GB) → SQLite, Supabase
├── Medium → PostgreSQL, PlanetScale
└── Large → Managed services, sharding
```

---

## RAG Best Practices

### Effective Search Queries

| Need | Good Query | Bad Query |
|------|------------|-----------|
| Framework comparison | "Next.js vs Remix 2025 production" | "best framework" |
| Database choice | "PostgreSQL vs MongoDB for SaaS 2025" | "what database" |
| Hosting | "Vercel pricing tiers 2025" | "cheap hosting" |

### Source Evaluation

Prioritize information from:
1. Official documentation
2. Engineering blogs from reputable companies
3. Recent conference talks/articles (< 1 year old)
4. Community discussions with verified experiences

Deprioritize:
1. Outdated articles (> 2 years)
2. Promotional content
3. Unverified claims without sources

### When to Search

- Always search for: Latest versions, pricing, recent comparisons
- Sometimes search: Well-established best practices
- Rarely search: Basic syntax, fundamental concepts

---

## Rules

- ALWAYS start with discovery interview before recommending
- ALWAYS use WebSearch for current technology information
- ALWAYS present trade-offs, not just recommendations
- ALWAYS confirm decisions before scaffolding
- ALWAYS create CLAUDE.md after scaffolding
- NEVER recommend without understanding requirements
- NEVER proceed to scaffolding without explicit confirmation
- NEVER skip the research phase for unfamiliar technologies
- NEVER assume user preferences without asking
