#!/bin/bash
# SessionStart Hook: Inject SDD context reminder
# This hook runs at the start of each session to remind about SDD principles

# Output is injected into the session context
cat << 'EOF'
## SDD Toolkit Active

**Remember the core principles:**

1. **No Code Without Spec** - Create specifications before implementing
2. **Ambiguity Tolerance Zero** - Ask questions when unclear
3. **Protect Main Context** - Delegate complex work to subagents

**Available Commands:**
- `/sdd` - Start full development workflow
- `/spec-review` - Review specification with parallel agents
- `/code-review` - Review code changes with parallel agents
- `/quick-impl` - Quick implementation for small, clear tasks

**Delegation Reminder:**
For complex tasks, always delegate to specialized agents:
- `product-manager` for requirements
- `architect` for design
- `*-specialist` for implementation
- `qa-engineer` for testing
- `security-auditor` for security review

EOF
