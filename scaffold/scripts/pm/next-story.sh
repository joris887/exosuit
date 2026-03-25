#!/usr/bin/env bash
# Find the next available story from the backlog, ordered by priority.
# Parses story checklist lines: - [ ] ID — Title (Priority, Status)
# Also supports legacy markers: [TODO], Status: TODO
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

FOUND=0

# Priority-ordered search: P0 first, then P1, P2, P3
for priority in P0 P1 P2 P3; do
    for epic_file in "$BACKLOG_DIR"/E*.md; do
        [[ -f "$epic_file" ]] || continue
        EPIC_NAME=$(basename "$epic_file" .md)

        # New format: - [ ] ID — Title (P#, ready)
        READY_LINES=$(grep -n "\- \[ \].*($priority, ready)" "$epic_file" 2>/dev/null || true)
        if [[ -n "$READY_LINES" ]]; then
            if [[ $FOUND -eq 0 ]]; then
                echo "Priority: $priority"
            fi
            echo "$READY_LINES" | head -3 | while IFS= read -r line; do
                echo "  [$EPIC_NAME] $line"
            done
            FOUND=$((FOUND + 1))
        fi
    done
    # Show top priority group, then stop
    if [[ $FOUND -gt 0 ]]; then
        break
    fi
done

# Fallback: legacy format support
if [[ $FOUND -eq 0 ]]; then
    for epic_file in "$BACKLOG_DIR"/E*.md; do
        [[ -f "$epic_file" ]] || continue
        EPIC_NAME=$(basename "$epic_file" .md)
        TODO_LINES=$(grep -n '\[TODO\]\|Status: TODO' "$epic_file" 2>/dev/null || true)
        if [[ -n "$TODO_LINES" ]]; then
            echo "Epic: $EPIC_NAME (legacy format)"
            echo "$TODO_LINES" | head -5 | while IFS= read -r line; do
                echo "  $line"
            done
            FOUND=$((FOUND + 1))
            echo ""
        fi
    done
fi

if [[ $FOUND -eq 0 ]]; then
    echo "No ready stories found in backlog."
    echo "Run /ideate to plan new work."
fi

# Show blocked stories if any
echo ""
BLOCKED=$(grep -rn "blocked)" "$BACKLOG_DIR"/E*.md 2>/dev/null | grep "\- \[ \]" || true)
if [[ -n "$BLOCKED" ]]; then
    echo "--- Blocked Stories ---"
    echo "$BLOCKED" | head -5 | while IFS= read -r line; do
        echo "  $line"
    done
fi
