#!/bin/bash
# Workspace Utilities for Multi-Project Isolation
# Provides functions for workspace ID generation and path management
#
# Usage: source this file in other hook scripts
#   source "$(dirname "$0")/workspace_utils.sh"
#
# Based on:
# - https://code.claude.com/docs/en/common-workflows (Git worktrees)
# - https://github.com/anthropics/claude-code/issues/1985 (Session isolation)

# ============================================================================
# WORKSPACE ID GENERATION
# ============================================================================

# Generate a unique workspace ID based on git branch and working directory
# Format: {branch}_{path-hash}
# Example: main_a1b2c3d4, feature-auth_e5f6g7h8
#
# This ensures:
# - Different worktrees of same repo get different IDs
# - Same directory with different branches get different IDs
# - Human-readable branch name for easy identification
get_workspace_id() {
    local branch=""
    local path_hash=""

    # Get current git branch (sanitize for filesystem safety)
    # Remove all characters except alphanumeric, dots, underscores, and hyphens
    if git rev-parse --git-dir > /dev/null 2>&1; then
        branch=$(git branch --show-current 2>/dev/null | tr '/' '-' | tr ' ' '-' | tr -dc 'a-zA-Z0-9._-')
        # Fallback to HEAD if detached
        if [ -z "$branch" ]; then
            branch="detached-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
        fi
        # Limit branch name length for filesystem compatibility (max 50 chars)
        branch=$(echo "$branch" | cut -c1-50)
    else
        branch="no-git"
    fi

    # Generate hash of absolute working directory path
    # Using md5sum for cross-platform compatibility
    if command -v md5sum &> /dev/null; then
        # Linux: md5sum outputs "hash  filename", extract just the hash
        path_hash=$(pwd | md5sum | awk '{print $1}' | cut -c1-8)
    elif command -v md5 &> /dev/null; then
        # macOS: md5 outputs just the hash (or "MD5 (...) = hash" with -r)
        path_hash=$(pwd | md5 | awk '{print $NF}' | cut -c1-8)
    else
        # Fallback: use simple hash
        path_hash=$(pwd | cksum | awk '{print $1}' | head -c8)
    fi

    echo "${branch}_${path_hash}"
}

# ============================================================================
# PATH MANAGEMENT
# ============================================================================

# Get the workspace directory path
# Returns: .claude/workspaces/{workspace-id}/
get_workspace_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo ".claude/workspaces/${workspace_id}"
}

# Get the progress file path for current workspace
# Returns: .claude/workspaces/{workspace-id}/claude-progress.json
get_progress_file() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/claude-progress.json"
}

# Get the feature list file path for current workspace
# Returns: .claude/workspaces/{workspace-id}/feature-list.json
get_feature_file() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/feature-list.json"
}

# Get the session state file path for current workspace
# Returns: .claude/workspaces/{workspace-id}/session-state.json
get_session_state_file() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/session-state.json"
}

# Get the logs directory for current workspace
# Returns: .claude/workspaces/{workspace-id}/logs/
get_logs_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/logs"
}

# Get the subagent activity log path for current workspace
# Returns: .claude/workspaces/{workspace-id}/logs/subagent_activity.log
get_subagent_log() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_logs_dir "$workspace_id")/subagent_activity.log"
}

# Get the sessions directory for current workspace
# Returns: .claude/workspaces/{workspace-id}/logs/sessions/
get_sessions_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_logs_dir "$workspace_id")/sessions"
}

# ============================================================================
# WORKSPACE MANAGEMENT
# ============================================================================

# Ensure workspace directory structure exists
# Creates: .claude/workspaces/{workspace-id}/logs/sessions/
ensure_workspace_exists() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local workspace_dir="$(get_workspace_dir "$workspace_id")"
    local logs_dir="$(get_logs_dir "$workspace_id")"
    local sessions_dir="$(get_sessions_dir "$workspace_id")"

    mkdir -p "$workspace_dir"
    mkdir -p "$logs_dir"
    mkdir -p "$sessions_dir"
}

# List all workspaces in current project
# Returns: list of workspace IDs (one per line)
list_workspaces() {
    local workspaces_dir=".claude/workspaces"
    if [ -d "$workspaces_dir" ]; then
        ls -1 "$workspaces_dir" 2>/dev/null
    fi
}

# Check if a workspace has progress files
# Returns: 0 if has progress, 1 if not
workspace_has_progress() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local progress_file="$(get_progress_file "$workspace_id")"
    [ -f "$progress_file" ]
}

# Get workspace metadata (for display)
# Returns: JSON with workspace info
# Uses environment variables to safely pass data to Python
get_workspace_info() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local progress_file="$(get_progress_file "$workspace_id")"
    local feature_file="$(get_feature_file "$workspace_id")"

    if [ -f "$progress_file" ] && command -v python3 &> /dev/null; then
        WORKSPACE_ID_VAR="$workspace_id" \
        PROGRESS_FILE_VAR="$progress_file" \
        FEATURE_FILE_VAR="$feature_file" \
        python3 << 'PYEOF'
import json
import os

workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')
progress_file = os.environ.get('PROGRESS_FILE_VAR', '')
feature_file = os.environ.get('FEATURE_FILE_VAR', '')

info = {
    "workspaceId": workspace_id,
    "hasProgress": os.path.exists(progress_file) if progress_file else False,
    "hasFeatures": os.path.exists(feature_file) if feature_file else False
}

if progress_file and os.path.exists(progress_file):
    try:
        with open(progress_file, 'r') as f:
            data = json.load(f)
        info["project"] = data.get("project", "unknown")
        info["status"] = data.get("status", "unknown")
        info["lastUpdated"] = data.get("lastUpdated", "unknown")
        ctx = data.get("resumptionContext", {})
        info["position"] = ctx.get("position", "unknown")
    except:
        pass

print(json.dumps(info, indent=2))
PYEOF
    else
        echo "{\"workspaceId\": \"$workspace_id\", \"hasProgress\": false}"
    fi
}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

# Generate a session ID (timestamp + random suffix)
generate_session_id() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local random_suffix=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n' | head -c4)
    echo "${timestamp}_${random_suffix}"
}

# Get or create current session ID
# Stores in environment variable for consistency within session
get_session_id() {
    if [ -z "$CLAUDE_SESSION_ID" ]; then
        export CLAUDE_SESSION_ID="$(generate_session_id)"
    fi
    echo "$CLAUDE_SESSION_ID"
}

# Create session log file
# Returns: path to session log file
get_session_log() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local session_id="${2:-$(get_session_id)}"
    local sessions_dir="$(get_sessions_dir "$workspace_id")"

    ensure_workspace_exists "$workspace_id"
    echo "${sessions_dir}/${session_id}.log"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Pretty print workspace info for user display
print_workspace_info() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local workspace_dir="$(get_workspace_dir "$workspace_id")"

    echo "Workspace ID: $workspace_id"
    echo "Workspace Dir: $workspace_dir"
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo "Working Dir: $(pwd)"

    if workspace_has_progress "$workspace_id"; then
        echo "Status: Has progress files"
    else
        echo "Status: No progress files"
    fi
}
