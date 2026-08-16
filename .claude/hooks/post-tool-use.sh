#!/bin/sh
# PostToolUse handler: log tool invocations + track test execution.
# 1. Appends timestamped JSON lines for Edit, Write, and Bash tool use.
#    Rotates at 200 entries.
# 2. Detects successful test runs and sets session state so the Stop
#    handler doesn't redundantly require test evidence in the last message.
# Advisory only (always exit 0). POSIX-compliant — no bash required.

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOOKS_DIR/state"
MAX_ENTRIES=200

# --- Hook guard: profile + disable check ---
"$HOOKS_DIR/lib/hook-guard.sh" "post-tool-use" "minimal" || exit 0

# --- JSON field extraction ---
# Extracts a field from JSON. Supports dotted paths with jq, flat keys with sed.
extract_json() {
    _jq_path="$1"
    _sed_key="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -r "$_jq_path // empty"
    else
        sed -n 's/.*"'"$_sed_key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
    fi
}

# Read stdin once
INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | extract_json ".tool_name" "tool_name")

# Only log Edit, Write, Bash
case "$TOOL_NAME" in
    Edit|Write|Bash) ;;
    *) exit 0 ;;
esac

# Extract target (file_path for Edit/Write, command for Bash)
TARGET=$(printf '%s' "$INPUT" | extract_json ".tool_input.file_path" "file_path")
if [ -z "$TARGET" ]; then
    TARGET=$(printf '%s' "$INPUT" | extract_json ".tool_input.command" "command" | cut -c1-120)
fi
[ -z "$TARGET" ] && exit 0

# Resolve project log directory
LOG_DIR="docs/sessions"
LOG_FILE="$LOG_DIR/.activity-log.jsonl"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

# --- Flow gate evidence: test file edited this session ---
# (consumed by flow-pre-edit.sh / gate.hard nodes declaring evidence:
# test-written; lib/test-paths.sh is the single pattern source shared with
# the exemption check, so a stamping edit can never itself be blocked)
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
    if sh "$HOOKS_DIR/lib/test-paths.sh" "$TARGET" 2>/dev/null; then
        mkdir -p "$STATE_DIR/flow" 2>/dev/null
        date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/flow/test-written" 2>/dev/null
    fi
fi

# Timestamp
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Append entry (manual JSON to avoid jq dependency for writing)
# Escape double quotes in target for JSON safety
SAFE_TARGET=$(printf '%s' "$TARGET" | sed 's/"/\\"/g')
printf '{"ts":"%s","tool":"%s","target":"%s"}\n' "$TS" "$TOOL_NAME" "$SAFE_TARGET" >> "$LOG_FILE" 2>/dev/null

# Rotate: keep last MAX_ENTRIES lines
if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')
    if [ "$LINE_COUNT" -gt "$MAX_ENTRIES" ]; then
        TMPFILE="$LOG_FILE.tmp"
        tail -n "$MAX_ENTRIES" "$LOG_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$LOG_FILE" 2>/dev/null
    fi
fi

# --- Track successful test runs in session state ---
# When a Bash command runs tests and they pass, record it so the Stop
# handler can skip redundant evidence checks. Requires jq for reliable
# extraction of tool_output (multi-line, special chars). Without jq,
# skip tracking gracefully — the stop hook still works, just may ask
# for evidence even when tests passed earlier.
if [ "$TOOL_NAME" = "Bash" ] && command -v jq >/dev/null 2>&1; then
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
    TOOL_OUTPUT=$(printf '%s' "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null)

    # Generic test command patterns (project-specific commands are also caught
    # if they contain these common runners)
    TEST_CMD_MATCH=false
    case "$COMMAND" in
        *pytest*|*"npm test"*|*"npm run test"*|*"cargo test"*|*"go test"*|*jest*|*vitest*|*"dotnet test"*|*rspec*|*"gradle test"*|*"mvn test"*|*"make test"*|*"swift test"*) TEST_CMD_MATCH=true ;;
    esac

    if [ "$TEST_CMD_MATCH" = "true" ] && [ -n "$TOOL_OUTPUT" ]; then
        # Detect pass AND failure patterns up front: a mixed run
        # ('3 passed, 9 failed') is a FAILING run and must never stamp
        # green evidence.
        RUN_PASSED=false
        RUN_FAILED=false
        printf '%s' "$TOOL_OUTPUT" | grep -qEi '([0-9]+ passed|All tests passed|tests? (in [0-9]+ suites? )?passed|test run with [0-9]+ tests.*passed|BUILD SUCCEEDED|ok \(|Tests:.*[0-9]+ passed)' && RUN_PASSED=true
        # The green-evidence VETO must only trigger on ACTUAL failures:
        # nonzero failed-counts or hard build breaks. Green runs legitimately
        # contain '0 tests failed', 'Failed: 0', ERROR-level log lines, and
        # test names like test_handles_error — none of those may veto.
        printf '%s' "$TOOL_OUTPUT" | grep -qEi '((^|[^0-9])[1-9][0-9]* +(tests? +)?failed|failed: *[1-9]|failures: *[1-9]|BUILD FAILED|npm ERR)' && RUN_FAILED=true

        if [ "$RUN_PASSED" = "true" ] && [ "$RUN_FAILED" = "false" ]; then
            mkdir -p "$STATE_DIR" 2>/dev/null
            date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/tests-passed" 2>/dev/null
            # Flow gate evidence (evidence: tests-green)
            mkdir -p "$STATE_DIR/flow" 2>/dev/null
            date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/flow/tests-green" 2>/dev/null
        elif [ "$RUN_FAILED" = "true" ]; then
            # The marker reflects the MOST RECENT observed run, not the
            # best run of the session — a red suite revokes green evidence.
            rm -f "$STATE_DIR/flow/tests-green" 2>/dev/null
        fi

        # --- Track test/build failures for retrospective analysis ---
        # (keeps its original broad detection — logging is intentionally
        # noisier than the strict green-evidence veto above)
        if printf '%s' "$TOOL_OUTPUT" | grep -qEi '(FAILED|FAIL\b|ERROR\b|error:|BUILD FAILED|npm ERR|test.*failed|[0-9]+ failed)'; then
            FAIL_LOG="$LOG_DIR/.failure-log.jsonl"
            # Extract first error line (truncated for JSON safety)
            FIRST_ERROR=$(printf '%s' "$TOOL_OUTPUT" | grep -Ei '(FAILED|FAIL|ERROR|error:|failed)' | head -1 | cut -c1-120 | sed 's/"/\\"/g')
            # Count failure indicators
            FAIL_COUNT=$(printf '%s' "$TOOL_OUTPUT" | grep -cEi '(FAILED|FAIL\b|failed)' || echo "0")
            SAFE_CMD=$(printf '%s' "$COMMAND" | cut -c1-80 | sed 's/"/\\"/g')
            printf '{"ts":"%s","type":"test-failure","cmd":"%s","failures":%s,"first_error":"%s"}\n' \
                "$TS" "$SAFE_CMD" "$FAIL_COUNT" "$FIRST_ERROR" >> "$FAIL_LOG" 2>/dev/null
        fi
    fi
fi

exit 0
