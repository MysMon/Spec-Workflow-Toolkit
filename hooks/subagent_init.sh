#!/bin/bash
# SubagentStart Hook: Initialize subagent context
# This hook runs when a subagent is started

# Get subagent info from environment
AGENT_NAME="${CLAUDE_AGENT_NAME:-unknown}"

# Log subagent start for tracking
echo "[SDD] Subagent started: ${AGENT_NAME}" >&2
echo "[SDD] Context isolation active - detailed output stays in subagent context" >&2

# Provide context-aware reminders based on agent type
case "$AGENT_NAME" in
  security-auditor)
    echo "[SDD] Security audit mode: read-only operations, document all findings" >&2
    ;;
  qa-engineer)
    echo "[SDD] QA mode: write tests before implementation, verify coverage" >&2
    ;;
  product-manager)
    echo "[SDD] PM mode: clarify requirements, create spec in docs/specs/" >&2
    ;;
  architect)
    echo "[SDD] Architecture mode: create ADRs, document trade-offs" >&2
    ;;
  *-specialist)
    echo "[SDD] Implementation mode: follow spec strictly, use TodoWrite for progress" >&2
    ;;
esac

exit 0
