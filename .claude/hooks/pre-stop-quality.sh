#!/usr/bin/env bash
# Requirements: git (for session state), project-specific quality tools (lint, typecheck, test)
# Behavior: Auto-saves session state + runs quality gates before task completion
#
# Customize the quality commands below based on your project's stack.
# /bootstrap will configure these for your detected tools.

# --- Auto-save minimal session state (safety net for /continue) ---
SESSIONS_DIR="docs/sessions"
AUTO_SAVE="$SESSIONS_DIR/.auto-save.md"

if [ -d ".git" ]; then
    mkdir -p "$SESSIONS_DIR"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    LAST_COMMITS=$(git log --oneline -5 2>/dev/null || echo "no commits")
    UNCOMMITTED=$(git diff --name-only 2>/dev/null | head -10)
    STAGED=$(git diff --cached --name-only 2>/dev/null | head -10)

    cat > "$AUTO_SAVE" << AUTOSAVE
# Auto-Save Session State

**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Branch:** $BRANCH

## Recent Commits
\`\`\`
$LAST_COMMITS
\`\`\`

## Uncommitted Changes
$( [ -n "$UNCOMMITTED" ] && echo "\`\`\`" && echo "$UNCOMMITTED" && echo "\`\`\`" || echo "None" )

## Staged Changes
$( [ -n "$STAGED" ] && echo "\`\`\`" && echo "$STAGED" && echo "\`\`\`" || echo "None" )
AUTOSAVE
fi

# --- Quality checks ---
ERRORS=0

# Run linter (if configured)
# Uncomment and customize for your project:
# echo "Running linter..."
# npm run lint 2>&1 || ERRORS=$((ERRORS + 1))
# ruff check . 2>&1 || ERRORS=$((ERRORS + 1))
# cargo clippy 2>&1 || ERRORS=$((ERRORS + 1))

# Run type checker (if configured)
# echo "Running type checker..."
# npx tsc --noEmit 2>&1 || ERRORS=$((ERRORS + 1))
# mypy . 2>&1 || ERRORS=$((ERRORS + 1))

# Run tests
# echo "Running tests..."
# npm test 2>&1 || ERRORS=$((ERRORS + 1))
# pytest 2>&1 || ERRORS=$((ERRORS + 1))
# cargo test 2>&1 || ERRORS=$((ERRORS + 1))

if [ $ERRORS -gt 0 ]; then
    echo "QUALITY GATE FAILED: $ERRORS check(s) failed. Fix issues before completing."
    exit 1
fi

exit 0
