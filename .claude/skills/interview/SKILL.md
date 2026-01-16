---
name: interview
description: Conducts structured requirements interviews to clarify vague requests. Use when user requirements are unclear or when starting a new feature to ensure complete understanding.
allowed-tools: AskUserQuestion, Read, Write
model: sonnet
user-invocable: true
---

# Requirements Interview

Conduct structured interviews to transform vague requirements into actionable specifications.

## Interview Framework

### Phase 1: Context Understanding

Start with open questions to understand the big picture:

1. **Goal**: "What problem are you trying to solve?"
2. **Users**: "Who will use this feature?"
3. **Success**: "How will you know this is successful?"

### Phase 2: Functional Requirements

Use trade-off questions (not open-ended):

**Bad**: "What features do you want?"
**Good**: "For user authentication, would you prefer:
- Social login (faster to implement, depends on third parties)
- Custom auth (more control, longer to build)
- Both (most flexibility, highest complexity)"

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

Gather constraints:

1. **Performance**: "What response time is acceptable? (<100ms, <500ms, <2s)"
2. **Scale**: "How many concurrent users do you expect? (10, 100, 1000, 10000+)"
3. **Availability**: "What uptime is required? (99%, 99.9%, 99.99%)"
4. **Security**: "What data sensitivity level? (Public, Internal, Confidential, Restricted)"

### Phase 4: Edge Cases

Ask about boundaries:

```
What should happen when:
- User has no internet connection?
- Data is invalid or malformed?
- User doesn't have permission?
- System is under heavy load?
```

### Phase 5: Existing Constraints

Identify limitations:

```
Are there any constraints we need to work within?
- Existing systems to integrate with?
- Technology restrictions?
- Budget or time limits?
- Compliance requirements (GDPR, HIPAA, etc.)?
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

## Output Format

After interview, produce:

```markdown
# Requirements Summary: [Feature Name]

## Context
- **Problem**: [What problem this solves]
- **Users**: [Target users]
- **Success Metric**: [How success is measured]

## Functional Requirements
1. [FR-001] User can...
2. [FR-002] System should...

## Non-Functional Requirements
- Performance: [Target]
- Security: [Requirements]
- Scalability: [Expectations]

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

## Rules

- NEVER assume requirements that weren't explicitly stated
- ALWAYS document trade-offs discussed
- NEVER skip non-functional requirements
- ALWAYS get explicit confirmation of scope boundaries
- NEVER proceed to implementation with open questions
