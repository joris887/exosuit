#!/bin/sh
# Stop handler: auto-save session state + debug audit + completion evidence validation.
# 1. Always auto-saves git state + active skill context (safety net for /continue).
# 2. Scans diff for leftover debug statements (advisory warning).
# 3. Validates last assistant message for unverified completion claims.
#    Evidence check is skipped when post-tool-use.sh has already recorded
#    a successful test run (state/tests-passed). This prevents redundant
#    re-runs when story-cycle Phase 4b already verified tests.
# Safety valve: max iterations (default 5), then allows stop unconditionally.
# Override via EXOSUIT_STOP_MAX_ITERATIONS env var, or quality.conf max_iterations.
# Values <=0 disable the safety valve (infinite retries).
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (last_assistant_message)
# Output: exit 0 = allow, exit 2 = block (message on stderr)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$HOOKS_DIR/rules"
STATE_DIR="$HOOKS_DIR/state"
QUALITY_FILE="$RULES_DIR/quality.conf"
DEBUG_PATTERNS_FILE="$RULES_DIR/debug.patterns"

# --- Hook guard: profile + disable check ---
"$HOOKS_DIR/lib/hook-guard.sh" "stop" "standard" || exit 0

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

# --- Helper: list changed SOURCE files (code only, not docs/config) ---
# Both the debug audit and the evidence check are meaningless for a
# docs-only change. This is the single biggest source of false positives.
changed_source_files() {
    _ext=$(read_conf "source_extensions" \
        'go|ts|tsx|js|jsx|mjs|cjs|py|rb|rs|java|kt|kts|cs|php|swift|c|h|cc|cpp|hpp|m|scala|ex|exs|dart|vue|svelte')
    {
        git diff --name-only 2>/dev/null
        git diff --cached --name-only 2>/dev/null
    } | sort -u | grep -E "\.(${_ext})$" 2>/dev/null
}

# --- Helper: does this project have a test suite at all? ---
# Demanding test output from a repo with no test runner is incoherent.
# Cheap file-existence checks only — hooks must stay under 5s.
has_test_suite() {
    [ -f "go.mod" ] && return 0
    [ -f "Cargo.toml" ] && return 0
    [ -f "pyproject.toml" ] && return 0
    [ -f "pytest.ini" ] && return 0
    [ -f "tox.ini" ] && return 0
    [ -f "Gemfile" ] && return 0
    [ -f "pom.xml" ] && return 0
    [ -f "build.gradle" ] && return 0
    [ -f "build.gradle.kts" ] && return 0
    if [ -f "package.json" ]; then
        grep -q '"test"[[:space:]]*:' package.json 2>/dev/null && return 0
    fi
    return 1
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

$SKILL_CONTEXT
AUTOSAVE_EOF
fi

# --- 2. Safety valve: max iterations ---
# Priority: EXOSUIT_STOP_MAX_ITERATIONS env var > quality.conf > default (5)
# Values <=0 mean "no limit" (infinite retries — use with caution)
if [ -n "${EXOSUIT_STOP_MAX_ITERATIONS:-}" ]; then
    MAX_ITER="$EXOSUIT_STOP_MAX_ITERATIONS"
else
    MAX_ITER=$(read_conf "max_iterations" "5")
fi
# Ensure it's a number (fallback to 5 if not)
case "$MAX_ITER" in
    ''|*[!0-9-]*) MAX_ITER=5 ;;
esac
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

# Values <=0 mean no limit (never auto-allow)
if [ "$MAX_ITER" -gt 0 ] 2>/dev/null && [ "$ITERATION" -ge "$MAX_ITER" ]; then
    exit 0
fi

# --- 3. Completion evidence check ---
# Skip if tests already passed this session (tracked by post-tool-use.sh)
TESTS_PASSED_FILE="$STATE_DIR/tests-passed"
if [ -f "$TESTS_PASSED_FILE" ]; then
    exit 0
fi

# Skip entirely when no source files changed. A docs-only, config-only, or
# planning session has nothing to audit and no tests to run.
SOURCE_CHANGED=$(changed_source_files)
if [ -z "$SOURCE_CHANGED" ]; then
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

    # --- 3a. Debug statement audit (advisory, only when claiming completion) ---
    if [ "$CLAIMS_COMPLETION" = "true" ] && [ -f "$DEBUG_PATTERNS_FILE" ] && [ -d ".git" ]; then
        # Scan added lines for debug patterns — SOURCE FILES ONLY.
        # Scanning the whole diff meant a markdown table column named "TODO"
        # tripped the code-debug patterns. Restrict to files that are code.
        DIFF_ADDED=$(
            printf '%s\n' "$SOURCE_CHANGED" | while IFS= read -r sf; do
                [ -n "$sf" ] || continue
                git diff -- "$sf" 2>/dev/null | grep '^+[^+]'
                git diff --cached -- "$sf" 2>/dev/null | grep '^+[^+]'
            done
        )
        if [ -n "$DIFF_ADDED" ]; then
            DEBUG_WARNINGS=""
            while IFS= read -r pline; do
                case "$pline" in
                    '#'*|'') continue ;;
                esac
                p_regex=$(printf '%s' "$pline" | sed 's/^[^@]*@@//' | sed 's/@@.*//')
                p_message=$(printf '%s' "$pline" | sed 's/.*@@//')

                if printf '%s' "$DIFF_ADDED" | grep -qE -- "$p_regex"; then
                    if [ -z "$DEBUG_WARNINGS" ]; then
                        DEBUG_WARNINGS="$p_message"
                    else
                        DEBUG_WARNINGS="$DEBUG_WARNINGS
  - $p_message"
                    fi
                fi
            done < "$DEBUG_PATTERNS_FILE"

            if [ -n "$DEBUG_WARNINGS" ]; then
                printf 'Debug audit (review before shipping):\n  - %s\n' "$DEBUG_WARNINGS" >&2
            fi
        fi
    fi

    # --- 3b. Block completion without evidence ---
    # Only when the project actually has a test suite. Asking for test output
    # from a repo with no test runner is incoherent and unfixable by the model.
    if [ "$CLAIMS_COMPLETION" = "true" ] && [ "$HAS_EVIDENCE" = "false" ] && has_test_suite; then
        # Increment iteration counter
        NEW_ITER=$((ITERATION + 1))
        echo "$NEW_ITER" > "$ITER_FILE" 2>/dev/null
        EXPLAIN_MODE="${EXOSUIT_EXPLAIN_MODE:-brief}"
        if [ "$EXPLAIN_MODE" = "verbose" ]; then
            printf 'Quality check before completion:\n  - Task claimed complete but no test output found. Run tests and show output.\n  WHY: The framework requires evidence that tests pass before marking work complete. This prevents shipping untested code. Run your project'\''s test command (check CLAUDE.md Commands section) and include the passing output in your response.\n' >&2
        else
            printf 'Quality check before completion:\n  - Task claimed complete but no test output found. Run tests and show output.\n' >&2
        fi
        exit 2
    fi
fi

exit 0
