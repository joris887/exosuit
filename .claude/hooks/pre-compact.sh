#!/bin/sh
# PreCompact handler: preserve critical session state before context compaction.
# Fires just before Claude Code summarizes older conversation turns.
# 1. Snapshots current session state to docs/sessions/.auto-save.md
# 2. Injects a systemMessage guiding what to preserve during compaction
# Advisory only (cannot block compaction). POSIX-compliant — no bash required.
#
# Output: JSON on stdout with systemMessage field (exit 0)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Hook guard: profile + disable check ---
"$HOOKS_DIR/lib/hook-guard.sh" "pre-compact" "minimal" || exit 0

# --- 1. Snapshot session state (same format as stop.sh auto-save) ---
if [ -d ".git" ]; then
    SESSIONS_DIR="docs/sessions"
    mkdir -p "$SESSIONS_DIR" 2>/dev/null

    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    COMMITS=$(git log --oneline -5 2>/dev/null || echo "no commits")
    UNCOMMITTED=$(git diff --name-only 2>/dev/null)
    STAGED=$(git diff --cached --name-only 2>/dev/null)
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

    UNCOMMITTED_BLOCK="None"
    [ -n "$UNCOMMITTED" ] && UNCOMMITTED_BLOCK=$(printf '```\n%s\n```' "$UNCOMMITTED")
    STAGED_BLOCK="None"
    [ -n "$STAGED" ] && STAGED_BLOCK=$(printf '```\n%s\n```' "$STAGED")

    # Extract active skill context from .failure-state.md (if exists)
    SKILL_CONTEXT=""
    FAILURE_STATE="$SESSIONS_DIR/.failure-state.md"
    if [ -f "$FAILURE_STATE" ]; then
        FS_SKILL=$(grep '^skill:' "$FAILURE_STATE" 2>/dev/null | sed 's/skill: *//' | head -1)
        FS_PHASE=$(grep '^phase_name:' "$FAILURE_STATE" 2>/dev/null | sed 's/phase_name: *//' | head -1)
        FS_GOAL=$(grep '^goal:' "$FAILURE_STATE" 2>/dev/null | sed 's/goal: *//' | head -1)
        if [ -n "$FS_SKILL" ]; then
            SKILL_CONTEXT="## Active Skill Context

**Skill:** $FS_SKILL
**Phase:** $FS_PHASE
**Goal:** $FS_GOAL"
        fi
    fi

    cat > "$SESSIONS_DIR/.auto-save.md" 2>/dev/null <<AUTOSAVE_EOF
# Auto-Save Session State (Pre-Compaction)

**Generated:** $NOW
**Trigger:** context compaction
**Branch:** $BRANCH

## Recent Commits
\`\`\`
$COMMITS
\`\`\`

## Uncommitted Changes
$UNCOMMITTED_BLOCK

## Staged Changes
$STAGED_BLOCK

$SKILL_CONTEXT
AUTOSAVE_EOF
fi

# --- 2. Inject compaction guidance as systemMessage ---
GUIDANCE="COMPACTION ACTIVE — Follow the Compaction Directive in CLAUDE.md. Priority: preserve goal, sprint_goal, commands, active_plan, branch, and decisions VERBATIM. Merge file lists into existing <files-read> and <files-modified>. Drop LOW items first. If docs/sessions/.auto-save.md exists, critical state is backed up there — read it after compaction to recover anything lost."

# Output JSON to stdout
if command -v jq >/dev/null 2>&1; then
    printf '%s' "$GUIDANCE" | jq -Rsc '{ systemMessage: . }'
else
    SAFE_GUIDANCE=$(printf '%s' "$GUIDANCE" | sed 's/"/\\"/g' | tr '\n' ' ')
    printf '{"systemMessage":"%s"}\n' "$SAFE_GUIDANCE"
fi

exit 0
