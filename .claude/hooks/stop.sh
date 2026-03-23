#!/bin/sh
# Stop handler: auto-save session state + completion evidence validation.
# 1. Always auto-saves git state (safety net for /continue).
# 2. Validates last assistant message for unverified completion claims.
#    Evidence check is skipped when post-tool-use.sh has already recorded
#    a successful test run (state/tests-passed). This prevents redundant
#    re-runs when story-cycle Phase 4b already verified tests.
# Safety valve: max iterations (default 5), then allows stop unconditionally.
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (last_assistant_message)
# Output: exit 0 = allow, exit 2 = block (message on stderr)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$HOOKS_DIR/rules"
STATE_DIR="$HOOKS_DIR/state"
QUALITY_FILE="$RULES_DIR/quality.conf"

# --- Helper: read config value ---
read_conf() {
    _key="$1"
    _default="$2"
    if [ -f "$QUALITY_FILE" ]; then
        _val=$(grep "^${_key}=" "$QUALITY_FILE" 2>/dev/null | sed "s/^${_key}=//" | head -1)
        if [ -n "$_val" ]; then
            printf '%s\n' "$_val"
            return
        fi
    fi
    printf '%s\n' "$_default"
}

# --- JSON field extraction ---
extract_json_string() {
    _field="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -r ".$_field // empty"
    else
        # For long fields like last_assistant_message, sed may truncate.
        # Use grep -o for a safer extraction of the value.
        sed -n 's/.*"'"$_field"'"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1
    fi
}

# Read stdin once
INPUT=$(cat)

# --- 1. Auto-save if there are uncommitted changes (safety net) ---
if [ -d ".git" ] && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
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

    cat > "$SESSIONS_DIR/.auto-save.md" 2>/dev/null <<AUTOSAVE_EOF
# Auto-Save Session State

**Generated:** $NOW
**Branch:** $BRANCH

## Recent Commits
\`\`\`
$COMMITS
\`\`\`

## Uncommitted Changes
$UNCOMMITTED_BLOCK

## Staged Changes
$STAGED_BLOCK
AUTOSAVE_EOF
fi

# --- 2. Safety valve: max iterations ---
MAX_ITER=$(read_conf "max_iterations" "5")
mkdir -p "$STATE_DIR" 2>/dev/null
ITER_FILE="$STATE_DIR/stop-iteration"
ITERATION=0
if [ -f "$ITER_FILE" ]; then
    ITERATION=$(cat "$ITER_FILE" 2>/dev/null | tr -d '[:space:]')
    # Ensure it's a number
    case "$ITERATION" in
        ''|*[!0-9]*) ITERATION=0 ;;
    esac
fi

if [ "$ITERATION" -ge "$MAX_ITER" ]; then
    exit 0
fi

# --- 3. Completion evidence check ---
# Skip if tests already passed this session (tracked by post-tool-use.sh)
TESTS_PASSED_FILE="$STATE_DIR/tests-passed"
if [ -f "$TESTS_PASSED_FILE" ]; then
    exit 0
fi

LAST_MESSAGE=$(printf '%s' "$INPUT" | extract_json_string "last_assistant_message")

if [ -n "$LAST_MESSAGE" ]; then
    COMPLETION_RE=$(read_conf "completion_regex" '(complete|done|finished|implemented|delivered|ready for review)')
    EVIDENCE_RE=$(read_conf "evidence_regex" '([0-9]+ tests?.*pass|PASS\b|Tests:[[:space:]]+[0-9]+|test result:.*ok|pytest.*passed|All [0-9]+ tests passed|[0-9]+ passed)')

    CLAIMS_COMPLETION=false
    HAS_EVIDENCE=false

    if printf '%s' "$LAST_MESSAGE" | grep -qEi "$COMPLETION_RE"; then
        CLAIMS_COMPLETION=true
    fi
    if printf '%s' "$LAST_MESSAGE" | grep -qEi "$EVIDENCE_RE"; then
        HAS_EVIDENCE=true
    fi

    if [ "$CLAIMS_COMPLETION" = "true" ] && [ "$HAS_EVIDENCE" = "false" ]; then
        # Increment iteration counter
        NEW_ITER=$((ITERATION + 1))
        echo "$NEW_ITER" > "$ITER_FILE" 2>/dev/null
        printf 'Quality check before completion:\n  - Task claimed complete but no test output found. Run tests and show output.\n' >&2
        exit 2
    fi
fi

exit 0
