#!/usr/bin/env bash
# Test suite for pre-tool-use.sh safety patterns
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../pre-tool-use.sh"
PASS=0
FAIL=0

# Builds a realistic PreToolUse payload. Claude Code nests tool arguments under
# tool_input — tests MUST use this shape or they validate nothing. A previous
# version of this suite passed flat {"command": ...}, which matched a bug in the
# hook and hid the fact that every safety pattern was being skipped in real use.
payload() {
    printf '{"session_id":"test","transcript_path":"/tmp/t.jsonl","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":%s}}' \
        "$SCRIPT_DIR" "$1"
}

test_case() {
    local desc="$1"
    local input="$2"
    local expected_exit="$3"

    actual_exit=0
    echo "$input" | sh "$HOOK" >/dev/null 2>/dev/null || actual_exit=$?

    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected exit $expected_exit, got $actual_exit)"
        FAIL=$((FAIL + 1))
    fi
}

echo "Testing pre-tool-use.sh"
echo "========================"

# Override framework repo check so it doesn't interfere with safety pattern tests
export EXOSUIT_FRAMEWORK_REPO="nonexistent/repo-that-wont-match"

# Should BLOCK (exit 2)
test_case "Block git push --force" "$(payload '"git push --force origin main"')" 2
test_case "Block git push -f" "$(payload '"git push -f"')" 2
test_case "Block git checkout ." "$(payload '"git checkout ."')" 2
test_case "Block git reset --hard" "$(payload '"git reset --hard HEAD"')" 2
test_case "Block git clean -f" "$(payload '"git clean -f"')" 2
test_case "Block git branch -D" "$(payload '"git branch -D feature/old"')" 2
test_case "Block rm -rf /" "$(payload '"rm -rf /"')" 2
test_case "Block npm publish" "$(payload '"npm publish"')" 2
test_case "Block DROP TABLE" "$(payload '"psql -c \"DROP TABLE users\""')" 2

# Should ALLOW (exit 0)
test_case "Allow git push" "$(payload '"git push origin feature/my-branch"')" 0
test_case "Allow git status" "$(payload '"git status"')" 0
test_case "Allow git branch -d" "$(payload '"git branch -d feature/merged"')" 0
test_case "Allow npm test" "$(payload '"npm test"')" 0
test_case "Allow rm file" "$(payload '"rm src/old-file.ts"')" 0
test_case "Allow empty command" "$(payload '""')" 0
test_case "Allow no tool_input" '{"hook_event_name":"PreToolUse","tool_name":"Bash"}' 0

# --- Regression: the command MUST be read from tool_input, not the payload root ---
# These two decoys fail if the hook ever reads the wrong field again. They are the
# tests that would have caught the original bug.
test_case "Reads tool_input, not root (dangerous nested, safe root)" \
    '{"hook_event_name":"PreToolUse","tool_name":"Bash","command":"git status","tool_input":{"command":"git reset --hard"}}' 2
test_case "Ignores root command (safe nested, dangerous root)" \
    '{"hook_event_name":"PreToolUse","tool_name":"Bash","command":"git reset --hard","tool_input":{"command":"git status"}}' 0

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
