#!/bin/bash
# SessionEnd Hook: Clean up resources when Claude Code session terminates
# This hook runs when the session ends (user exits, timeout, etc.)
#
# Responsibilities:
# - Rotate old log files to prevent disk bloat
# - Clean up temporary files created during the session
# - Archive stale workspace data (older than 30 days)
#
# Based on Claude Code hooks specification.

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# Configuration
LOG_RETENTION_DAYS=30
MAX_LOG_SIZE_MB=10
WORKSPACE_BASE=".claude/workspaces"

# --- Cross-Platform Utilities ---
# Get file modification time in seconds since epoch (cross-platform)
get_file_mtime() {
    local file="$1"

    # Check if file exists first (prevents race condition)
    if [ ! -f "$file" ]; then
        echo 0
        return
    fi

    # Try platform-appropriate stat command (POSIX-compatible)
    case "$OSTYPE" in
        darwin*)
            # macOS: stat -f%m returns modification time
            stat -f%m "$file" 2>/dev/null || echo 0
            ;;
        *)
            # Linux: stat -c %Y returns modification time
            stat -c %Y "$file" 2>/dev/null || echo 0
            ;;
    esac
}

# --- Log Rotation ---
# Rotate logs that exceed size limit or are older than retention period

rotate_logs() {
    local workspace_id="$1"
    local log_dir="$WORKSPACE_BASE/$workspace_id/logs"

    if [ ! -d "$log_dir" ]; then
        return 0
    fi

    # Find and compress old session logs
    find "$log_dir/sessions" -name "*.log" -mtime +$LOG_RETENTION_DAYS 2>/dev/null | while read -r logfile; do
        if [ -f "$logfile" ] && [ ! -f "${logfile}.gz" ]; then
            gzip -f "$logfile" 2>/dev/null
        fi
    done

    # Remove very old compressed logs (double retention period)
    find "$log_dir/sessions" -name "*.log.gz" -mtime +$((LOG_RETENTION_DAYS * 2)) -delete 2>/dev/null

    # Rotate main activity log if too large
    local activity_log="$log_dir/subagent_activity.log"
    if [ -f "$activity_log" ]; then
        local size_kb=$(du -k "$activity_log" 2>/dev/null | cut -f1)
        local max_size_kb=$((MAX_LOG_SIZE_MB * 1024))

        if [ "${size_kb:-0}" -gt "$max_size_kb" ]; then
            # Keep last 1000 lines, archive the rest
            local timestamp=$(date +%Y%m%d_%H%M%S)
            tail -n 1000 "$activity_log" > "${activity_log}.tmp"
            mv "$activity_log" "${activity_log}.${timestamp}"
            mv "${activity_log}.tmp" "$activity_log"
            gzip -f "${activity_log}.${timestamp}" 2>/dev/null
        fi
    fi
}

# --- Temporary File Cleanup ---
# Remove temporary files created during the session

cleanup_temp_files() {
    local workspace_id="$1"
    local workspace_dir="$WORKSPACE_BASE/$workspace_id"

    if [ ! -d "$workspace_dir" ]; then
        return 0
    fi

    # Remove .tmp files
    find "$workspace_dir" -name "*.tmp" -type f -delete 2>/dev/null

    # Remove empty directories (but not the main workspace dir)
    find "$workspace_dir" -mindepth 1 -type d -empty -delete 2>/dev/null
}

# --- Stale Workspace Archival ---
# Archive workspaces not updated in a long time

archive_stale_workspaces() {
    if [ ! -d "$WORKSPACE_BASE" ]; then
        return 0
    fi

    local archive_dir="$WORKSPACE_BASE/.archive"

    # Find workspaces not modified in LOG_RETENTION_DAYS
    for workspace_dir in "$WORKSPACE_BASE"/*/; do
        [ -d "$workspace_dir" ] || continue

        local workspace_name=$(basename "$workspace_dir")

        # Skip archive directory
        [ "$workspace_name" = ".archive" ] && continue

        local progress_file="$workspace_dir/claude-progress.json"

        if [ -f "$progress_file" ]; then
            # Check if progress file is stale (using cross-platform mtime)
            local file_mtime
            file_mtime=$(get_file_mtime "$progress_file")
            local file_age_days=$(( ($(date +%s) - file_mtime) / 86400 ))

            if [ "$file_age_days" -gt "$LOG_RETENTION_DAYS" ]; then
                # Check if status is completed (safe to archive)
                local status=""
                if command -v python3 &> /dev/null; then
                    status=$(PROGRESS_FILE_PATH="$progress_file" python3 -c "
import json
import os
try:
    with open(os.environ.get('PROGRESS_FILE_PATH', ''), 'r') as f:
        data = json.load(f)
    print(data.get('status', ''))
except:
    pass
" 2>/dev/null)
                fi

                # Only archive completed workspaces
                if [ "$status" = "completed" ]; then
                    mkdir -p "$archive_dir"
                    local timestamp=$(date +%Y%m%d)
                    mv "$workspace_dir" "$archive_dir/${workspace_name}_${timestamp}" 2>/dev/null
                fi
            fi
        fi
    done
}

# --- Main Execution ---

# Get current workspace ID
WORKSPACE_ID=""
if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
fi

# Perform cleanup for current workspace
if [ -n "$WORKSPACE_ID" ]; then
    rotate_logs "$WORKSPACE_ID"
    cleanup_temp_files "$WORKSPACE_ID"
fi

# Archive stale workspaces (run periodically, not every session)
# Only run if a marker file is older than 1 day
ARCHIVE_MARKER="$WORKSPACE_BASE/.last_archive_check"
MARKER_MTIME=$(get_file_mtime "$ARCHIVE_MARKER")
if [ ! -f "$ARCHIVE_MARKER" ] || [ $(( ($(date +%s) - MARKER_MTIME) / 86400 )) -gt 0 ]; then
    archive_stale_workspaces
    touch "$ARCHIVE_MARKER" 2>/dev/null
fi

# Exit successfully (cleanup is best-effort)
exit 0
