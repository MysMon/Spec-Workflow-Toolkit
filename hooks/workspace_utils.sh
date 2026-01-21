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
        with open(progress_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        info["project"] = data.get("project", "unknown")
        info["status"] = data.get("status", "unknown")
        info["lastUpdated"] = data.get("lastUpdated", "unknown")
        ctx = data.get("resumptionContext", {})
        info["position"] = ctx.get("position", "unknown")
    except Exception:
        pass  # Return partial info on read failure

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
# INSIGHT MANAGEMENT (v3.0 - Folder-Based Architecture)
# ============================================================================
#
# Directory structure:
#   .claude/workspaces/{id}/insights/
#   ├── pending/    # New insights awaiting review (one JSON file per insight)
#   ├── applied/    # Applied to CLAUDE.md or rules
#   ├── rejected/   # Rejected by user
#   └── archive/    # Old insights for reference

# Get the insights base directory for current workspace
# Returns: .claude/workspaces/{workspace-id}/insights/
get_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/insights"
}

# Get the pending insights directory (v3.0 - folder-based)
# Returns: .claude/workspaces/{workspace-id}/insights/pending/
get_pending_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/pending"
}

# Get the applied insights directory
# Returns: .claude/workspaces/{workspace-id}/insights/applied/
get_applied_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/applied"
}

# Get the rejected insights directory
# Returns: .claude/workspaces/{workspace-id}/insights/rejected/
get_rejected_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/rejected"
}

# Get the archive insights directory
# Returns: .claude/workspaces/{workspace-id}/insights/archive/
get_archive_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/archive"
}

# DEPRECATED: For backward compatibility only
# Returns: empty string (no longer used in v3.0)
get_pending_insights_file() {
    echo ""
}

# DEPRECATED: For backward compatibility only
get_approved_insights_file() {
    echo ""
}

# Validate workspace ID to prevent path traversal and injection
# Returns: 0 if valid, 1 if invalid
# Usage: validate_workspace_id "workspace-id" || exit 1
validate_workspace_id() {
    local id="$1"

    # Must be non-empty
    if [ -z "$id" ]; then
        return 1
    fi

    # Must match allowed characters only (alphanumeric, dot, underscore, hyphen)
    if [[ ! "$id" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        return 1
    fi

    # Must not contain path traversal sequences
    if [[ "$id" == *".."* ]]; then
        return 1
    fi

    # Length check (reasonable limit)
    if [ ${#id} -gt 100 ]; then
        return 1
    fi

    return 0
}

# Count pending insights for a workspace (v3.0 - counts files in pending/)
# Returns: number of pending insights (0 if none)
count_pending_insights() {
    local workspace_id="${1:-$(get_workspace_id)}"

    # Validate workspace ID if provided externally
    if [ -n "$1" ] && ! validate_workspace_id "$1"; then
        echo "0"
        return
    fi

    local pending_dir="$(get_pending_insights_dir "$workspace_id")"

    if [ -d "$pending_dir" ]; then
        # Count .json files in pending directory
        find "$pending_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Check if workspace has pending insights
# Returns: 0 if has pending insights, 1 if not
workspace_has_pending_insights() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local count=$(count_pending_insights "$workspace_id")
    [ "$count" -gt 0 ]
}

# Ensure insights directory structure exists (v3.0)
ensure_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local insights_dir="$(get_insights_dir "$workspace_id")"

    mkdir -p "$insights_dir/pending"
    mkdir -p "$insights_dir/applied"
    mkdir -p "$insights_dir/rejected"
    mkdir -p "$insights_dir/archive"
}

# List pending insight files
# Returns: list of insight file paths (one per line)
list_pending_insights() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local pending_dir="$(get_pending_insights_dir "$workspace_id")"

    if [ -d "$pending_dir" ]; then
        find "$pending_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null | sort
    fi
}

# Move insight to a different status directory
# Usage: move_insight "insight-file-path" "applied|rejected|archive"
# SECURITY: Validates source path is within expected insights directory
move_insight() {
    local insight_file="$1"
    local target_status="$2"
    local workspace_id="${3:-$(get_workspace_id)}"

    if [ ! -f "$insight_file" ]; then
        echo "Error: Insight file not found: $insight_file" >&2
        return 1
    fi

    # SECURITY: Validate source file is within insights directory
    # Resolve to absolute path to prevent path traversal
    local resolved_source
    resolved_source=$(realpath "$insight_file" 2>/dev/null)
    if [ -z "$resolved_source" ]; then
        echo "Error: Could not resolve path: $insight_file" >&2
        return 1
    fi

    # Verify source is within insights directory (pending, applied, rejected, or archive)
    case "$resolved_source" in
        */insights/pending/*.json|*/insights/applied/*.json|*/insights/rejected/*.json|*/insights/archive/*.json)
            ;;
        *)
            echo "Error: Source path not in expected insights directory: $resolved_source" >&2
            return 1
            ;;
    esac

    local insights_dir="$(get_insights_dir "$workspace_id")"
    local target_dir=""

    case "$target_status" in
        applied)  target_dir="$insights_dir/applied" ;;
        rejected) target_dir="$insights_dir/rejected" ;;
        archive)  target_dir="$insights_dir/archive" ;;
        *)
            echo "Error: Invalid target status: $target_status" >&2
            return 1
            ;;
    esac

    mkdir -p "$target_dir"

    local filename
    filename=$(basename "$insight_file")
    mv "$resolved_source" "$target_dir/$filename"
}

# Read a single insight file and output its JSON
# Usage: read_insight "insight-file-path"
read_insight() {
    local insight_file="$1"

    if [ -f "$insight_file" ]; then
        cat "$insight_file"
    else
        echo "{}"
    fi
}

# ============================================================================
# LOG MANAGEMENT
# ============================================================================

# Get the insight capture log file path
# Returns: .claude/workspaces/{workspace-id}/insights/capture.log
get_insight_capture_log() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/capture.log"
}

# Rotate log file if it exceeds size limit
# Usage: rotate_log_if_needed "/path/to/log" 1048576  # 1MB
rotate_log_if_needed() {
    local log_file="$1"
    local max_size="${2:-1048576}"  # Default 1MB
    local keep_count="${3:-5}"       # Keep last 5 rotations

    if [ ! -f "$log_file" ]; then
        return 0
    fi

    local current_size
    current_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)

    if [ "$current_size" -gt "$max_size" ]; then
        local timestamp
        timestamp=$(date '+%Y%m%d_%H%M%S')
        local rotated_file="${log_file}.${timestamp}"

        # Rotate current log
        mv "$log_file" "$rotated_file" 2>/dev/null || return 1

        # Compress rotated file if gzip is available
        if command -v gzip &> /dev/null; then
            gzip "$rotated_file" 2>/dev/null
        fi

        # Remove old rotations beyond keep_count
        local pattern="${log_file}.*"
        # shellcheck disable=SC2086
        ls -t $pattern 2>/dev/null | tail -n +$((keep_count + 1)) | xargs rm -f 2>/dev/null
    fi
}

# Clean up temporary files in workspace
# Removes: .tmp files, .lock files older than 1 hour, empty directories
cleanup_workspace_temp_files() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local workspace_dir="$(get_workspace_dir "$workspace_id")"

    if [ ! -d "$workspace_dir" ]; then
        return 0
    fi

    # Remove .tmp files (leftover from interrupted atomic writes)
    find "$workspace_dir" -name "*.tmp" -type f -delete 2>/dev/null

    # Remove stale .lock files (older than 1 hour)
    find "$workspace_dir" -name "*.lock" -type f -mmin +60 -delete 2>/dev/null

    # Remove empty directories (but not the main workspace dir)
    find "$workspace_dir" -mindepth 1 -type d -empty -delete 2>/dev/null
}

# Archive old insights that have been processed
# Moves applied/rejected insights to archive file
archive_processed_insights() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local pending_file="$(get_pending_insights_file "$workspace_id")"
    local archive_file="$(get_insights_dir "$workspace_id")/archive.json"

    if [ ! -f "$pending_file" ] || ! command -v python3 &> /dev/null; then
        return 0
    fi

    PENDING_FILE_VAR="$pending_file" \
    ARCHIVE_FILE_VAR="$archive_file" \
    python3 << 'PYEOF'
import json
import os
from datetime import datetime

pending_file = os.environ.get('PENDING_FILE_VAR', '')
archive_file = os.environ.get('ARCHIVE_FILE_VAR', '')

if not pending_file or not archive_file:
    exit(0)

try:
    # Read pending insights
    with open(pending_file, 'r', encoding='utf-8') as f:
        pending_data = json.load(f)

    insights = pending_data.get('insights', [])

    # Separate pending from processed
    still_pending = []
    to_archive = []

    for insight in insights:
        status = insight.get('status', 'pending')
        if status in ('applied', 'rejected', 'workspace-approved'):
            to_archive.append(insight)
        else:
            still_pending.append(insight)

    if not to_archive:
        exit(0)  # Nothing to archive

    # Read or create archive
    try:
        with open(archive_file, 'r', encoding='utf-8') as f:
            archive_data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        archive_data = {
            'created': datetime.now().isoformat(),
            'insights': []
        }

    # Add to archive
    archive_data['insights'].extend(to_archive)
    archive_data['lastUpdated'] = datetime.now().isoformat()

    # Write archive
    with open(archive_file, 'w', encoding='utf-8') as f:
        json.dump(archive_data, f, indent=2, ensure_ascii=False)

    # Update pending (remove archived)
    pending_data['insights'] = still_pending
    pending_data['lastUpdated'] = datetime.now().isoformat()

    with open(pending_file, 'w', encoding='utf-8') as f:
        json.dump(pending_data, f, indent=2, ensure_ascii=False)

    print(f"Archived {len(to_archive)} processed insights")

except Exception as e:
    print(f"Archive error: {e}", file=__import__('sys').stderr)
PYEOF
}

# Get workspace statistics
# Returns: JSON with counts of insights, logs, etc.
get_workspace_stats() {
    local workspace_id="${1:-$(get_workspace_id)}"

    if ! command -v python3 &> /dev/null; then
        echo '{"error": "python3 not available"}'
        return
    fi

    WORKSPACE_ID_VAR="$workspace_id" \
    WORKSPACE_DIR_VAR="$(get_workspace_dir "$workspace_id")" \
    PENDING_FILE_VAR="$(get_pending_insights_file "$workspace_id")" \
    python3 << 'PYEOF'
import json
import os
from pathlib import Path

workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')
workspace_dir = os.environ.get('WORKSPACE_DIR_VAR', '')
pending_file = os.environ.get('PENDING_FILE_VAR', '')

stats = {
    'workspaceId': workspace_id,
    'exists': os.path.isdir(workspace_dir) if workspace_dir else False,
    'insights': {
        'pending': 0,
        'applied': 0,
        'rejected': 0,
        'total': 0
    },
    'storage': {
        'pendingFileSize': 0,
        'logFiles': 0,
        'totalSize': 0
    }
}

if workspace_dir and os.path.isdir(workspace_dir):
    # Count insights
    if pending_file and os.path.isfile(pending_file):
        try:
            with open(pending_file, 'r') as f:
                data = json.load(f)
            insights = data.get('insights', [])
            stats['insights']['total'] = len(insights)
            for i in insights:
                status = i.get('status', 'pending')
                if status == 'pending':
                    stats['insights']['pending'] += 1
                elif status == 'applied':
                    stats['insights']['applied'] += 1
                elif status == 'rejected':
                    stats['insights']['rejected'] += 1
            stats['storage']['pendingFileSize'] = os.path.getsize(pending_file)
        except Exception:
            pass

    # Count storage
    total_size = 0
    log_count = 0
    for root, dirs, files in os.walk(workspace_dir):
        for f in files:
            fpath = os.path.join(root, f)
            try:
                total_size += os.path.getsize(fpath)
                if f.endswith('.log') or f.endswith('.jsonl'):
                    log_count += 1
            except OSError:
                pass
    stats['storage']['totalSize'] = total_size
    stats['storage']['logFiles'] = log_count

print(json.dumps(stats, indent=2))
PYEOF
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

    # Show insight stats if available
    if workspace_has_pending_insights "$workspace_id"; then
        local count
        count=$(count_pending_insights "$workspace_id")
        echo "Pending Insights: $count"
    fi
}
