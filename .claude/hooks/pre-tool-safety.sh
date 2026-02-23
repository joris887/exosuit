#!/usr/bin/env bash
# Requirements: grep (always available)
# Behavior: Blocks dangerous Bash commands; warns once per pattern per session
# Pre-tool safety hook: Block dangerous operations.
# Intercepts Bash commands before execution and rejects destructive patterns.
#
# This script receives the command as $1.
# Uses per-session state tracking to avoid showing the same warning repeatedly.

CMD="$1"

if [ -z "$CMD" ]; then
    exit 0
fi

# Session state tracking: warn once per unique blocked pattern per session
STATE_DIR="${TMPDIR:-/tmp}/.claude-hook-state"
mkdir -p "$STATE_DIR" 2>/dev/null
STATE_FILE="$STATE_DIR/pre-tool-safety.state"

# Clean stale state files (older than 24 hours)
find "$STATE_DIR" -name "*.state" -mtime +1 -delete 2>/dev/null

# check_and_block: Block first occurrence, warn on repeat
# Usage: check_and_block "pattern_key" "Block message"
check_and_block() {
    local key="$1"
    local msg="$2"
    if grep -qF "$key" "$STATE_FILE" 2>/dev/null; then
        echo "BLOCKED (repeated): $msg"
    else
        echo "$key" >> "$STATE_FILE"
        echo "BLOCKED: $msg"
    fi
    exit 1
}

# Block destructive git operations
if echo "$CMD" | grep -qE 'git\s+push\s+.*--force(\s|$)'; then
    check_and_block "git-push-force" "git push --force is not allowed. Use --force-with-lease if necessary."
fi

if echo "$CMD" | grep -qE 'git\s+push\s+.*-f(\s|$)'; then
    check_and_block "git-push-f" "git push -f is not allowed. Use --force-with-lease if necessary."
fi

if echo "$CMD" | grep -qE 'git\s+checkout\s+\.\s*$'; then
    check_and_block "git-checkout-dot" "git checkout . discards all changes. Use git stash or commit first."
fi

if echo "$CMD" | grep -qE 'git\s+reset\s+--hard'; then
    check_and_block "git-reset-hard" "git reset --hard is destructive. Stash or commit changes first."
fi

if echo "$CMD" | grep -qE 'git\s+clean\s+-f'; then
    check_and_block "git-clean-f" "git clean -f permanently deletes untracked files. Review with git clean -n first."
fi

# Block destructive file operations
if echo "$CMD" | grep -qE 'rm\s+-rf\s+(/|\.\.|~)'; then
    check_and_block "rm-rf-dangerous" "rm -rf on root, parent, or home directory is not allowed."
fi

# Block accidental package publishing
if echo "$CMD" | grep -qE '(npm\s+publish|cargo\s+publish|twine\s+upload|gem\s+push|pod\s+trunk\s+push)'; then
    check_and_block "package-publish" "Package publishing requires manual execution outside Claude Code."
fi

# Block destructive database operations
if echo "$CMD" | grep -qiE '(DROP\s+(TABLE|DATABASE)|TRUNCATE\s+TABLE)'; then
    check_and_block "db-destructive" "Destructive database operations. Run manually with review."
fi

# Block mass process killing
if echo "$CMD" | grep -qE '(kill\s+-9\s+-1|killall\s|pkill\s+-9)'; then
    check_and_block "mass-kill" "Mass process killing is not allowed."
fi

# Block operations against the framework template repository
# Prevents accidental issue/PR creation or pushes to the framework repo instead of the user's project
FRAMEWORK_REPO="${JD_FRAMEWORK_REPO:-joris887/JD-LLM-Development_framework}"
if echo "$CMD" | grep -qE '(gh\s+(pr|issue)\s+create|git\s+push)'; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ] && echo "$REMOTE_URL" | grep -qF "$FRAMEWORK_REPO"; then
        check_and_block "framework-repo" "Remote points to the framework template repository ($FRAMEWORK_REPO). Run: git remote set-url origin <your-project-repo-url>"
    fi
fi

exit 0
