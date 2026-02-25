#!/usr/bin/env bash
# Find the next available TODO story from the backlog
# Zero context cost: execute directly, do NOT read source
set -euo pipefail

echo "=== Next Available Stories ==="
echo ""

BACKLOG_DIR="docs/reference/backlog"

if [[ ! -d "$BACKLOG_DIR" ]]; then
    echo "No backlog directory found at $BACKLOG_DIR"
    echo "Run /ideate to create stories."
    exit 0
fi

# Find TODO stories across all epic files
FOUND=0
for epic_file in "$BACKLOG_DIR"/E*.md; do
    [[ -f "$epic_file" ]] || continue
    EPIC_NAME=$(basename "$epic_file" .md)

    # Extract TODO story lines (patterns: [TODO], Status: TODO, - [ ])
    TODO_LINES=$(grep -n '\[TODO\]\|Status: TODO\|- \[ \]' "$epic_file" 2>/dev/null || true)
    if [[ -n "$TODO_LINES" ]]; then
        if [[ $FOUND -eq 0 ]]; then
            echo "Epic: $EPIC_NAME"
        fi
        echo "$TODO_LINES" | head -5 | while IFS= read -r line; do
            echo "  $line"
        done
        FOUND=$((FOUND + 1))
        echo ""
    fi
done

if [[ $FOUND -eq 0 ]]; then
    echo "No TODO stories found in backlog."
    echo "Run /ideate to plan new work."
fi
