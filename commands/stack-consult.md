---
description: "Interactive stack consultation: interview, research, recommend, and scaffold new projects"
argument-hint: "[optional: project name or focus area]"
allowed-tools: AskUserQuestion, WebSearch, WebFetch, Read, Write, Bash, Glob, Grep, Task, TodoWrite, Edit
---

# /stack-consult - Interactive Stack Consultation

A comprehensive consultation system that guides users from "I have an idea" to "I have a working project structure" through structured interviews, real-time research, and collaborative decision-making.

## Purpose

This command helps when:
- Starting a completely new project
- Unsure what technology stack to use
- Want expert guidance on framework/database/hosting choices
- Need current (not outdated) technology recommendations
- Want to understand trade-offs before committing

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Discovery Interview                               │
│  "What are you building? Who is it for?"                   │
├─────────────────────────────────────────────────────────────┤
│  Phase 2: Constraint Mapping                                │
│  "What are your limitations? Team skills? Budget?"         │
├─────────────────────────────────────────────────────────────┤
│  Phase 3: Stack Research (RAG)                              │
│  WebSearch + WebFetch for current technology info          │
├─────────────────────────────────────────────────────────────┤
│  Phase 4: Recommendation                                    │
│  Present options with trade-offs based on research         │
├─────────────────────────────────────────────────────────────┤
│  Phase 5: Decision                                          │
│  Confirm final choices with user                           │
├─────────────────────────────────────────────────────────────┤
│  Phase 6: Scaffolding                                       │
│  Create project structure with decided stack               │
└─────────────────────────────────────────────────────────────┘
```

---

## Execution Instructions

### Phase 1: Discovery Interview

**Start by understanding the project vision.**

Use `AskUserQuestion` to gather information:

#### 1.1 Project Type
```
Question: "What type of application are you building?"
Header: "App Type"
Options:
- "Web Application (browser-based)"
- "Mobile App (iOS/Android)"
- "API/Backend Service"
- "CLI Tool or Script"
```

#### 1.2 Project Nature
```
Question: "What best describes your project?"
Header: "Nature"
Options:
- "MVP/Prototype (speed matters most)"
- "Production application (reliability matters)"
- "Learning project (educational)"
- "Enterprise system (scale & compliance)"
```

#### 1.3 Core Features
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

#### 1.4 Follow-up based on type

**If Web Application:**
```
Question: "What type of web application?"
Header: "Web Type"
Options:
- "Content site / Blog / Marketing"
- "SaaS / Dashboard / Admin panel"
- "E-commerce / Marketplace"
- "Social / Community platform"
```

**If Mobile App:**
```
Question: "What mobile development approach?"
Header: "Mobile"
Options:
- "Cross-platform (React Native, Flutter)"
- "Native iOS (Swift)"
- "Native Android (Kotlin)"
- "Progressive Web App (PWA)"
```

### Phase 2: Constraint Mapping

**Identify limitations that affect technology choices.**

#### 2.1 Team Experience
```
Question: "What languages/frameworks does your team know well?"
Header: "Experience"
MultiSelect: true
Options:
- "JavaScript/TypeScript"
- "Python"
- "Go / Rust / Java"
- "None specific (open to learn)"
```

#### 2.2 Infrastructure
```
Question: "Any infrastructure requirements?"
Header: "Infra"
Options:
- "Cloud (AWS/GCP/Azure) - flexible"
- "Serverless preferred (Vercel/Netlify)"
- "Self-hosted / On-premise required"
- "No preference"
```

#### 2.3 Budget
```
Question: "What's your infrastructure budget expectation?"
Header: "Budget"
Options:
- "Free tier / Minimal ($0-50/month)"
- "Startup budget ($50-500/month)"
- "Growth budget ($500-5000/month)"
- "Enterprise (cost not primary concern)"
```

#### 2.4 Timeline
```
Question: "When do you need the first version?"
Header: "Timeline"
Options:
- "ASAP (days to 1-2 weeks)"
- "Short-term (1-2 months)"
- "Medium-term (3-6 months)"
- "Long-term (6+ months)"
```

### Phase 3: Stack Research (RAG)

**Use web search to gather current technology information.**

Based on the interview responses, perform targeted searches:

#### 3.1 Construct Search Queries

Map requirements to search queries:

| Requirement | Search Query Pattern |
|-------------|---------------------|
| Web + React | "Next.js vs Remix [current year] production" |
| Web + Vue | "Nuxt 3 vs alternatives [current year]" |
| API + Python | "FastAPI vs Django REST [current year]" |
| Database need | "[detected type] database comparison [current year]" |
| Hosting | "[platform] pricing [current year]" |

#### 3.2 Execute Searches

```python
# Pseudocode for research process
for category in [frontend, backend, database, hosting]:
    results = WebSearch(f"{category} recommendation for {requirements}")
    for top_result in results[:3]:
        details = WebFetch(top_result.url, prompt="Extract pros, cons, use cases")
        compile_findings(category, details)
```

#### 3.3 Fetch Detailed Information

For promising technologies, use `WebFetch` on:
- Official documentation (latest versions, features)
- Comparison articles from reputable sources
- Engineering blogs with production experiences

#### 3.4 Compile Research Summary

Create a structured summary:

```markdown
## Technology Research Summary

### Frontend Options
| Technology | Pros | Cons | Best For |
|------------|------|------|----------|
| [Option A] | ... | ... | ... |
| [Option B] | ... | ... | ... |

### Backend Options
...

### Database Options
...

### Sources Consulted
- [Source 1] (date)
- [Source 2] (date)
```

### Phase 4: Recommendation

**Present analyzed options with clear trade-offs.**

#### 4.1 Build Recommendation

Based on research, create a recommendation that considers:
- User requirements (from Phase 1)
- Constraints (from Phase 2)
- Current technology landscape (from Phase 3)

#### 4.2 Present to User

```markdown
## Stack Recommendation for [Project Name/Description]

### Your Requirements Summary
- Type: [Web App / API / etc.]
- Features: [Auth, Real-time, etc.]
- Team skills: [Languages/frameworks]
- Budget: [Tier]
- Timeline: [Urgency]

### Recommended Stack

| Layer | Recommendation | Why |
|-------|----------------|-----|
| Frontend | [Tech] | [Reason based on requirements] |
| Backend | [Tech] | [Reason] |
| Database | [Tech] | [Reason] |
| Hosting | [Tech] | [Reason] |

### Trade-offs to Consider

| Choice | You Get | You Give Up |
|--------|---------|-------------|
| [Choice 1] | [Benefit] | [Cost] |
| [Choice 2] | [Benefit] | [Cost] |

### Alternatives Considered

| Layer | Alternative | Why Not Primary |
|-------|-------------|-----------------|
| Frontend | [Alt] | [Reason] |
```

#### 4.3 Ask for Decision

```
Question: "How would you like to proceed with this recommendation?"
Header: "Decision"
Options:
- "Looks good, let's set up the project"
- "I'd like to discuss alternatives for [component]"
- "Can you research [specific technology] more?"
- "Let me adjust some of my requirements"
```

### Phase 5: Decision Confirmation

**Finalize choices before scaffolding.**

#### 5.1 Handle User Response

If user wants alternatives:
- Focus additional research on specific area
- Present comparison with primary recommendation
- Explain trade-offs more deeply

If user wants to change requirements:
- Return to relevant Phase 1/2 questions
- Re-run research as needed

#### 5.2 Final Confirmation

```
Question: "Confirm your final stack:"
Header: "Confirm"
Options:
- "Yes, create project with: [stack summary]"
- "I want to change [specific component]"
- "Let me think about it (end consultation)"
```

### Phase 6: Scaffolding

**Create the project structure with decided stack.**

#### 6.1 Determine Project Location

```
Question: "Where should I create the project?"
Header: "Location"
Options:
- "Current directory: [path]"
- "New subdirectory named: [suggested name]"
- "Let me specify a custom path"
```

#### 6.2 Execute Scaffolding

Based on decided stack, run appropriate commands:

**Next.js Project:**
```bash
npx create-next-app@latest [name] --typescript --tailwind --eslint --app --src-dir
```

**Vite + React:**
```bash
npm create vite@latest [name] -- --template react-ts
cd [name] && npm install
```

**FastAPI:**
```bash
mkdir [name] && cd [name]
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn sqlalchemy python-dotenv
```

**Express + TypeScript:**
```bash
mkdir [name] && cd [name]
npm init -y
npm install express cors dotenv
npm install -D typescript @types/express @types/node ts-node nodemon
npx tsc --init
```

#### 6.3 Post-Scaffolding Setup

1. **Create folder structure** based on best practices for the chosen stack
2. **Initialize git** with appropriate .gitignore
3. **Create CLAUDE.md** documenting the stack decision
4. **Create README.md** with setup instructions

#### 6.4 Generate CLAUDE.md

```markdown
# [Project Name]

## Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Frontend | [Tech] | [Version] |
| Backend | [Tech] | [Version] |
| Database | [Tech] | [Version] |
| Hosting | [Platform] | - |

## Stack Decision Context

This stack was chosen based on:
- [Requirement 1]
- [Requirement 2]
- [Constraint 1]

## Development Commands

```bash
# Start development
[command]

# Run tests
[command]

# Build for production
[command]
```

## Project Structure

```
[directory tree]
```
```

#### 6.5 Final Output

```markdown
## Project Setup Complete! 🎉

### Created: [project-name]/

### Stack Summary
- Frontend: [tech]
- Backend: [tech]
- Database: [tech]
- Hosting: [platform]

### Next Steps
1. `cd [project-name]`
2. Install dependencies: `[install command]`
3. Set up environment: `cp .env.example .env`
4. Start development: `[dev command]`

### Files Created
- `CLAUDE.md` - Project documentation for Claude
- `README.md` - Project documentation
- `.gitignore` - Git ignore rules
- [other files...]

### Recommended First Tasks
- [ ] Configure database connection
- [ ] Set up basic routing
- [ ] Implement authentication (if applicable)
- [ ] Create first feature

Happy coding!
```

---

## Usage Examples

```bash
# Full consultation from scratch
/stack-consult

# With a project name in mind
/stack-consult my-awesome-app

# Focused on specific area
/stack-consult frontend
/stack-consult database
```

---

## Rules for This Command

- ALWAYS complete the interview before making recommendations
- ALWAYS use WebSearch for current technology information (avoid outdated advice)
- ALWAYS present trade-offs, never just "use X"
- ALWAYS get explicit confirmation before scaffolding
- ALWAYS create CLAUDE.md after project creation
- NEVER skip research phase for technologies you're unsure about
- NEVER assume user preferences without asking
- NEVER proceed with scaffolding if user is uncertain
- NEVER install packages without explaining what they do
