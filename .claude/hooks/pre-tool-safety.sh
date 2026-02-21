#!/usr/bin/env bash
# Pre-tool safety hook: Block dangerous operations.
# Intercepts Bash commands before execution and rejects destructive patterns.
#
# This script receives the command as $1.

CMD="$1"

if [ -z "$CMD" ]; then
    exit 0
fi

# Block destructive git operations
if echo "$CMD" | grep -qE 'git\s+push\s+.*--force(\s|$)'; then
    echo "BLOCKED: git push --force is not allowed. Use --force-with-lease if necessary."
    exit 1
fi

if echo "$CMD" | grep -qE 'git\s+push\s+.*-f(\s|$)'; then
    echo "BLOCKED: git push -f is not allowed. Use --force-with-lease if necessary."
    exit 1
fi

if echo "$CMD" | grep -qE 'git\s+checkout\s+\.\s*$'; then
    echo "BLOCKED: git checkout . discards all changes. Use git stash or commit first."
    exit 1
fi

if echo "$CMD" | grep -qE 'git\s+reset\s+--hard'; then
    echo "BLOCKED: git reset --hard is destructive. Stash or commit changes first."
    exit 1
fi

if echo "$CMD" | grep -qE 'git\s+clean\s+-f'; then
    echo "BLOCKED: git clean -f permanently deletes untracked files. Review with git clean -n first."
    exit 1
fi

# Block destructive file operations
if echo "$CMD" | grep -qE 'rm\s+-rf\s+(/|\.\.|~)'; then
    echo "BLOCKED: rm -rf on root, parent, or home directory is not allowed."
    exit 1
fi

exit 0
