#!/bin/sh
# Requirements: git (always available)
# Optional: none
# Behavior: Detects git worktree context and prepends cd to Bash commands
#
# Claude Code resets the working directory between Bash invocations.
# When running in a git worktree, this causes every Bash command to
# silently execute in the wrong directory. This hook detects worktree
# context and transparently injects the correct cd prefix.
#
# POSIX-compliant (not bash-specific) for maximum portability.
# Registered as PreToolUse for Bash with apply_to_subagents: true.

# Read the command from tool_input JSON on stdin
if command -v jq >/dev/null 2>&1; then
    TOOL_INPUT=$(cat)
    CMD=$(printf '%s' "$TOOL_INPUT" | jq -r '.command // empty')
else
    # Fallback: extract command field with sed
    TOOL_INPUT=$(cat)
    CMD=$(printf '%s' "$TOOL_INPUT" | sed -n 's/.*"command"\s*:\s*"\(.*\)"/\1/p' | head -1)
fi

# If no command found, allow through
if [ -z "$CMD" ]; then
    exit 0
fi

# Check if we're inside a git worktree
# In a worktree, .git is a FILE (not a directory) containing "gitdir: /path/to/.git/worktrees/<name>"
GIT_FILE=".git"
if [ ! -f "$GIT_FILE" ]; then
    # Not a worktree (either a regular repo with .git/ directory, or not a git repo)
    exit 0
fi

# Parse the gitdir path from the .git file
GITDIR_LINE=$(head -1 "$GIT_FILE" 2>/dev/null)
case "$GITDIR_LINE" in
    gitdir:\ *)
        GITDIR_PATH=$(printf '%s' "$GITDIR_LINE" | sed 's/^gitdir: //')
        ;;
    *)
        # Not a valid worktree .git file
        exit 0
        ;;
esac

# Validate this is actually a worktree path (should contain /worktrees/)
case "$GITDIR_PATH" in
    */worktrees/*)
        ;;
    *)
        # gitdir doesn't point to a worktree location
        exit 0
        ;;
esac

# Get the worktree's actual path (current directory)
WORKTREE_PATH=$(pwd)

# Skip injection for commands that don't need directory context
# These are shell builtins or commands that work regardless of CWD
case "$CMD" in
    echo\ *|echo|export\ *|export|true|false|pwd|set\ *|unset\ *|alias\ *|type\ *)
        exit 0
        ;;
esac

# Skip if the command already starts with cd
case "$CMD" in
    cd\ *|cd)
        exit 0
        ;;
esac

# Skip for commands that are just variable assignments
case "$CMD" in
    [A-Za-z_]*=*)
        # Check it's not followed by a command (like VAR=x some_command)
        AFTER_ASSIGN=$(printf '%s' "$CMD" | sed 's/^[A-Za-z_][A-Za-z_0-9]*=[^ ]* *//')
        if [ -z "$AFTER_ASSIGN" ]; then
            exit 0
        fi
        ;;
esac

# Inject the cd prefix
# Handle background processes: inject before the trailing &
case "$CMD" in
    *' &')
        # Command ends with background operator
        CMD_BODY=$(printf '%s' "$CMD" | sed 's/ &$//')
        NEW_CMD="cd '${WORKTREE_PATH}' && ${CMD_BODY} &"
        ;;
    *)
        NEW_CMD="cd '${WORKTREE_PATH}' && ${CMD}"
        ;;
esac

# Output the modified tool input with the new command
# We need to replace the command in the JSON
if command -v jq >/dev/null 2>&1; then
    printf '%s' "$TOOL_INPUT" | jq --arg cmd "$NEW_CMD" '.command = $cmd'
else
    # Fallback: sed-based replacement (handles simple cases)
    printf '%s' "$TOOL_INPUT" | sed "s|\"command\"\\s*:\\s*\".*\"|\"command\": \"$(printf '%s' "$NEW_CMD" | sed 's/[&/\]/\\&/g')\"|"
fi

exit 0
