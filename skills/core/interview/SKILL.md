---
name: interview
description: |
  Structured requirements interview framework for clarifying vague requests. Use when:
  - User requirements are unclear or incomplete
  - Starting a new feature and need to gather requirements
  - Need to understand user needs, constraints, or priorities
  - Translating business requests into technical specifications
  - User says "I want" or "can you add" without details
  Trigger phrases: gather requirements, clarify request, what do you need, interview user, requirements gathering, unclear request
allowed-tools: AskUserQuestion, Read, Write
model: sonnet
user-invocable: true
---

# Requirements Interview

A structured framework for transforming vague requests into actionable specifications.

## Interview Framework

### Phase 1: Context Understanding

Start with open questions to understand the big picture:

```
1. Goal: "What problem are you trying to solve?"
2. Users: "Who will use this feature?"
3. Success: "How will you know this is successful?"
4. Motivation: "Why is this needed now?"
```

### Phase 2: Functional Requirements

Use trade-off questions (not open-ended):

**Bad Question:**
> "What features do you want?"

**Good Question:**
> "For user authentication, would you prefer:
> - Social login (faster to implement, depends on third parties)
> - Custom auth (more control, longer to build)
> - Both (most flexibility, highest complexity)"

### Question Templates

#### Technology Decisions
```
For [feature], would you prefer:
A) [Option A] - [Pros] but [Cons]
B) [Option B] - [Pros] but [Cons]
C) Let me recommend based on your constraints
```

#### Scope Boundaries
```
Should [feature] include:
- [Sub-feature 1]: Yes / No / Later
- [Sub-feature 2]: Yes / No / Later
- [Sub-feature 3]: Yes / No / Later
```

#### Priority
```
Rank these by importance (1-5):
- [ ] Feature A
- [ ] Feature B
- [ ] Feature C
```

### Phase 3: Non-Functional Requirements

Gather constraints with specific options:

**Performance**
```
What response time is acceptable?
- Real-time (<100ms)
- Interactive (<500ms)
- Background (<2s)
- Async (minutes-hours)
```

**Scale**
```
How many concurrent users do you expect?
- Team (10-50)
- Departmental (50-500)
- Organization (500-5000)
- Public (5000+)
```

**Availability**
```
What uptime is required?
- Best effort (95%)
- Business hours (99%)
- Always available (99.9%)
- Critical (99.99%)
```

**Security**
```
What data sensitivity level?
- Public (no restrictions)
- Internal (employees only)
- Confidential (need-to-know)
- Restricted (regulated data)
```

### Phase 4: Edge Cases

Ask about boundaries:

```
What should happen when:
- User has no internet connection?
- Data is invalid or malformed?
- User doesn't have permission?
- System is under heavy load?
- User cancels mid-operation?
- Concurrent edits occur?
```

### Phase 5: Existing Constraints

Identify limitations:

```
Are there any constraints we need to work within?
- Existing systems to integrate with?
- Technology restrictions?
- Budget or time limits?
- Compliance requirements (GDPR, HIPAA, SOC2)?
- Team skill constraints?
```

## Interview Checklist

Before concluding, verify:

- [ ] User personas identified
- [ ] Primary use cases documented
- [ ] Success metrics defined
- [ ] Functional requirements listed
- [ ] Non-functional requirements specified
- [ ] Edge cases considered
- [ ] Constraints documented
- [ ] Out-of-scope items clarified
- [ ] Dependencies identified

## Output Format

After interview, produce this summary:

```markdown
# Requirements Summary: [Feature Name]

## Context
- **Problem**: [What problem this solves]
- **Users**: [Target users]
- **Success Metric**: [How success is measured]

## Functional Requirements
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | User can... | P0 |
| FR-002 | System should... | P1 |

## Non-Functional Requirements
| Category | Requirement |
|----------|-------------|
| Performance | [Target] |
| Security | [Requirements] |
| Scalability | [Expectations] |

## Constraints
- [Constraint 1]
- [Constraint 2]

## Out of Scope
- [Item 1]
- [Item 2]

## Open Questions
- [Any remaining ambiguities]

## Next Steps
1. Review and approve requirements
2. Create detailed specification
3. Begin implementation planning
```

## Tips for Effective Interviews

1. **Listen First**: Let the user explain before asking specific questions
2. **Summarize Often**: "So what I'm hearing is..." to confirm understanding
3. **Avoid Jargon**: Use plain language unless user is technical
4. **Document Everything**: Even "obvious" requirements
5. **Ask "Why"**: Understand motivation, not just requests
6. **Offer Trade-offs**: Present options with pros/cons
7. **Be Patient**: Good requirements take time

## Common Pitfalls to Avoid

| Pitfall | Why It's Bad | Instead |
|---------|--------------|---------|
| Leading questions | Biases answers | Ask neutrally |
| Yes/No only | Misses nuance | Ask for context |
| Assuming expertise | Confuses users | Define terms |
| Skipping NFRs | Incomplete spec | Always ask |
| Rushing | Misses details | Take time |

## Rules

- NEVER assume requirements that weren't stated
- ALWAYS document trade-offs discussed
- NEVER skip non-functional requirements
- ALWAYS get explicit scope confirmation
- NEVER proceed with open questions
- ALWAYS summarize understanding back to user
