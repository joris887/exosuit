#!/bin/sh
# PostToolUse handler: log tool invocations + track test execution.
# 1. Appends timestamped JSON lines for Edit, Write, and Bash tool use.
#    Rotates type-aware: last 200 tool lines + last 500 skill/story event
#    lines are kept (file max ~700 lines), preserving original order.
# 2. Detects successful test runs and sets session state so the Stop
#    handler doesn't redundantly require test evidence in the last message.
# Advisory only (always exit 0). POSIX-compliant — no bash required.

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOOKS_DIR/state"
MAX_ENTRIES=200
MAX_EVENT_ENTRIES=500

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

# Timestamp
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Append entry (manual JSON to avoid jq dependency for writing)
# Escape double quotes in target for JSON safety
SAFE_TARGET=$(printf '%s' "$TARGET" | sed 's/"/\\"/g')
printf '{"ts":"%s","tool":"%s","target":"%s"}\n' "$TS" "$TOOL_NAME" "$SAFE_TARGET" >> "$LOG_FILE" 2>/dev/null

# Rotate: type-aware. Skill/story lifecycle events are rare but feed sprint-end
# metrics and story-cycle calibration — a blind tail lets high-volume tool lines
# evict them. Cap each class separately, preserving line order (last N of each).
if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')
    if [ "$LINE_COUNT" -gt "$MAX_ENTRIES" ]; then
        TMPFILE="$LOG_FILE.tmp"
        awk -v max_tool="$MAX_ENTRIES" -v max_evt="$MAX_EVENT_ENTRIES" '
            { line[NR] = $0; is_evt[NR] = ($0 ~ /"type":"(skill|story)"/); if (is_evt[NR]) ec++; else tc++ }
            END {
                drop_evt = (ec > max_evt) ? ec - max_evt : 0
                drop_tool = (tc > max_tool) ? tc - max_tool : 0
                for (i = 1; i <= NR; i++) {
                    if (is_evt[i]) { if (++se > drop_evt) print line[i] }
                    else { if (++st > drop_tool) print line[i] }
                }
            }
        ' "$LOG_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$LOG_FILE" 2>/dev/null
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
        # Check for pass patterns in output
        if printf '%s' "$TOOL_OUTPUT" | grep -qEi '([0-9]+ passed|All tests passed|tests? (in [0-9]+ suites? )?passed|test run with [0-9]+ tests.*passed|BUILD SUCCEEDED|ok \(|Tests:.*[0-9]+ passed)'; then
            mkdir -p "$STATE_DIR" 2>/dev/null
            date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/tests-passed" 2>/dev/null
        fi

        # --- Track test/build failures for retrospective analysis ---
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
