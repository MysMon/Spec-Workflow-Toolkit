# Stack Consultation Reference

Evaluation frameworks and research methodologies for technology selection. Load on demand when deeper guidance is needed.

**Important**: This document contains no specific technology recommendations. All technology options must be discovered via WebSearch during consultation.

---

## Evaluation Framework

### Primary Evaluation Axes

Use these axes to compare any technology options discovered through research:

| Axis | Weight | Key Questions |
|------|--------|---------------|
| **Requirement Fit** | Critical | Does it directly solve the stated problem? |
| **Constraint Match** | Critical | Compatible with team skills, budget, timeline? |
| **Maturity** | High | Production-ready? Active maintenance? Security track record? |
| **Ecosystem** | High | Quality of documentation? Available libraries? Tooling support? |
| **Integration** | Medium | Works with other chosen components? Standard protocols? |
| **Community** | Medium | Active contributors? Responsive to issues? Learning resources? |
| **Future-proofing** | Low | Corporate backing? Clear roadmap? Migration paths? |

### Scoring Guidelines

| Score | Meaning |
|-------|---------|
| ✅ Strong | Clearly meets requirement with evidence |
| ⚠️ Partial | Meets requirement with caveats or workarounds |
| ❌ Weak | Does not meet requirement or significant gaps |
| ❓ Unknown | Insufficient information, needs more research |

---

## Research Methodology

### Source Prioritization

When gathering information via WebSearch/WebFetch, prioritize sources in this order:

| Priority | Source Type | Why |
|----------|-------------|-----|
| 1 | Official documentation | Most accurate, current |
| 2 | GitHub repository | Real activity metrics, issues |
| 3 | Recent (< 1 year) comparison articles | Contextual analysis |
| 4 | Production experience reports | Real-world validation |
| 5 | Stack Overflow activity | Community health indicator |
| 6 | Tutorial prevalence | Learning resource availability |

### Information to Extract

For each technology candidate discovered:

```markdown
## [Technology Name]

### Basic Info
- Current stable version: [from official docs]
- License: [open source type / commercial]
- Primary maintainer: [company / community]

### Strengths (from research)
- [Strength 1 with source]
- [Strength 2 with source]

### Weaknesses (from research)
- [Weakness 1 with source]
- [Weakness 2 with source]

### Fit Analysis
- Requirement match: [analysis]
- Constraint compatibility: [analysis]
- Risk factors: [analysis]

### Attribution
- [URL 1] (date accessed)
- [URL 2] (date accessed)
```

### Red Flags to Watch For

| Red Flag | What It Indicates |
|----------|-------------------|
| No commits in 6+ months | Potentially abandoned |
| Many open security issues | Maintenance concerns |
| Breaking changes in minor versions | Stability concerns |
| Sparse documentation | High learning curve |
| Single maintainer | Bus factor risk |
| No clear migration path | Lock-in risk |

### Green Flags to Look For

| Green Flag | What It Indicates |
|------------|-------------------|
| Active release cycle | Healthy maintenance |
| Corporate backing + community | Sustainable model |
| Comprehensive documentation | Lower learning curve |
| Large ecosystem | Problem-solving resources |
| Clear deprecation policy | Predictable evolution |
| Multiple successful case studies | Production-proven |

---

## Query Construction Guide

### Requirement-to-Query Mapping

Transform user requirements into effective search queries:

| Requirement Type | Query Pattern |
|-----------------|---------------|
| Interaction: Visual interface | `"[platform] UI frameworks [year] comparison"` |
| Interaction: CLI | `"CLI framework [language] [year]"` |
| Interaction: API | `"API framework [language] [year] production"` |
| Data: Structured | `"relational database [year] comparison"` |
| Data: Unstructured | `"document database [year] comparison"` |
| Data: Real-time | `"real-time database [year]"` |
| Data: Large-scale | `"big data processing [year] tools"` |
| Communication: Real-time | `"real-time communication [year] tools"` |
| Communication: Async | `"message queue [year] comparison"` |
| Deploy: Cloud | `"cloud deployment platform [year]"` |
| Deploy: Edge | `"edge computing platform [year]"` |
| Deploy: Embedded | `"embedded development [year] tools"` |

### Query Refinement

If initial search results are too broad:
- Add constraint: `"[query] for small teams"`
- Add use case: `"[query] for startups"`
- Add comparison: `"[query] vs alternatives"`

If results are too narrow or outdated:
- Remove year: `"[query]"` (then verify recency manually)
- Broaden scope: `"[category] tools comparison"`

---

## Decision Patterns

### When Requirements Conflict

| Situation | Resolution Strategy |
|-----------|---------------------|
| Speed vs. Quality | Clarify timeline criticality with user |
| Cost vs. Capability | Define minimum viable requirements |
| Familiarity vs. Fit | Assess learning curve vs. long-term benefit |
| Simplicity vs. Scale | Start simple with clear scale-up path |

### When No Clear Winner

If evaluation produces no obvious choice:

1. **Re-examine requirements**: Are all stated requirements truly essential?
2. **Identify deciding factor**: What single aspect matters most?
3. **Consider hybrid**: Can multiple tools solve different aspects?
4. **Default to simplicity**: When equal, choose the simpler option
5. **Acknowledge uncertainty**: Present to user with honest assessment

### When Research is Inconclusive

If WebSearch/WebFetch doesn't provide clear answers:

1. Search for alternative query formulations
2. Look for "lessons learned" or "post-mortem" articles
3. Check GitHub issues for real-world problems
4. Acknowledge gaps and note them in recommendations

---

## Common Pitfalls

### In Requirements Gathering

| Pitfall | Symptom | Resolution |
|---------|---------|------------|
| Solution bias | User asks for specific tech | Ask what problem they're solving |
| Scope creep | Requirements keep expanding | Establish MVP boundaries |
| Assumption | User says "standard" or "normal" | Ask for specific behaviors |
| Vagueness | "Fast", "scalable", "modern" | Quantify: how fast? how many users? |

### In Research

| Pitfall | Symptom | Resolution |
|---------|---------|------------|
| Recency bias | Newest = best | Verify production readiness |
| Popularity bias | Most stars = best | Check fit for specific needs |
| Tutorial bias | Many tutorials = good | Tutorials ≠ production quality |
| Benchmark bias | Fastest = best | Benchmarks ≠ real workload |

### In Recommendations

| Pitfall | Symptom | Resolution |
|---------|---------|------------|
| Overconfidence | Strong rec without evidence | Always cite sources |
| Analysis paralysis | Too many options presented | Limit to top 3 with clear ranking |
| Hidden assumptions | "Obviously you need X" | State all assumptions explicitly |
| Ignoring constraints | Perfect tech but wrong fit | Re-check constraint compatibility |

---

## Scaffolding Best Practices

### Before Running Any Commands

1. **Verify command currency**: Search for official getting-started guide
2. **Check prerequisites**: What must be installed first?
3. **Understand what it creates**: What files/folders will appear?
4. **Plan project location**: Where should project be created?

### After Scaffolding

1. **Verify success**: Can the project build/run?
2. **Document setup**: Record exact commands used
3. **Create .gitignore**: Based on technologies used (search for template)
4. **Initialize CLAUDE.md**: Capture decisions for future sessions

### CLAUDE.md Template for New Projects

```markdown
# [Project Name]

## Technology Stack

| Component | Technology | Version | Chosen Because |
|-----------|------------|---------|----------------|
| [Layer]   | [Name]     | [Ver]   | [Rationale]    |

## Setup Commands Used

```bash
# [Exact commands that were run]
```

## Key Decisions

| Decision | Choice | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| [Area]   | [What] | [Options]              | [Why]     |

## Project Structure

```
[Directory tree created by scaffolding]
```

## Development Commands

```bash
# Start development
[command]

# Run tests
[command]

# Build
[command]
```
```

---

## Domain-Specific Considerations

When researching, be aware of domain-specific evaluation criteria:

### Systems with Human Users
- Accessibility compliance requirements
- Localization/internationalization needs
- Device/browser compatibility

### Systems with High Reliability Needs
- Failure mode analysis
- Backup/recovery capabilities
- Monitoring/observability support

### Systems with Regulatory Requirements
- Compliance certification availability
- Audit logging capabilities
- Data residency options

### Systems with Performance Requirements
- Benchmark methodology validation
- Scaling characteristics
- Resource consumption patterns

---

## Research Query Templates

### For Initial Discovery

```
"best [category] tools [year] comparison"
"[category] framework comparison [year] production"
"top [category] solutions [year]"
```

### For Deep Evaluation

```
"[technology] production experience [year]"
"[technology] pros cons real world"
"[technology] vs [alternative] which to choose"
"[technology] problems issues"
```

### For Setup Information

```
"[technology] getting started official"
"[technology] installation guide [year]"
"[technology] project setup tutorial"
```
