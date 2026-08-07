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

# --- Message bodies are prose, not commands ---
# Writing about a blocked command must not trip the blocker.
test_case "Allow commit message quoting a blocked command" \
    "$(payload '"git commit -m \"fix: a force-push used to run unblocked\""')" 0
test_case "Allow commit message quoting reset --hard" \
    "$(payload '"git commit -m \"docs: explain why git reset --hard is banned\""')" 0
test_case "Allow single-quoted commit message" \
    "$(payload "\"git commit -m 'note: git clean -f is destructive'\"")" 0
test_case "Allow heredoc commit body mentioning a blocked command" \
    "$(payload '"git commit -F - <<EOF\nfix: hooks\n\nA live git push --force ran unblocked.\nEOF"')" 0
test_case "Allow multi-line -m message mentioning a blocked command" \
    "$(payload '"git commit -m \"fix: hooks\n\nA live git push --force ran unblocked before this.\nNow it is blocked.\""')" 0

# --- The exclusions must not become a bypass ---
# Stripping a message body must never hide a real command elsewhere in the chain.
test_case "Still blocks a dangerous command after a safe -m" \
    "$(payload '"git commit -m \"chore: tidy\" && git push --force origin main"')" 2
test_case "Still blocks a dangerous command after a heredoc terminator" \
    "$(payload '"git commit -F - <<EOF\nchore: tidy\nEOF\ngit reset --hard HEAD~3"')" 2
test_case "Heredoc stripping does not apply to non-commit commands" \
    "$(payload '"bash <<EOF\nrm -rf /\nEOF"')" 2
test_case "Still blocks -c payloads, which do execute" \
    "$(payload '"psql -c \"DROP TABLE users\""')" 2

# --- Short-flag patterns must match flags, not hyphenated words ---
# -[a-zA-Z]*f once matched the "-f" inside any hyphenated word, so ordinary
# pushes to branches like my-feature or hot-fix were blocked, and so was
# --force-with-lease, the remedy the block message recommends.
test_case "Allow push to a branch containing -feature" \
    "$(payload '"git push -u origin my-feature"')" 0
test_case "Allow push to a branch containing -fix" \
    "$(payload '"git push origin hot-fix"')" 0
test_case "Allow push to a branch containing -form" \
    "$(payload '"git push origin feat/login-form"')" 0
test_case "Allow --force-with-lease" \
    "$(payload '"git push --force-with-lease origin main"')" 0
test_case "Block bare -f flag" "$(payload '"git push -f"')" 2
test_case "Block clustered -uf flag" "$(payload '"git push -uf origin main"')" 2
test_case "Allow git clean -n on a path containing -f" \
    "$(payload '"git clean -n src/my-feature"')" 0

# --- Framework template repo protection ---
# These need origin to resolve to the framework repo, which is true when the
# suite runs from a framework checkout. Skipped elsewhere so consumer clones
# do not report spurious failures.
ORIGIN_PATH=$(git remote get-url origin 2>/dev/null \
    | sed -e 's#\.git$##' -e 's#^.*[:/]\([^/][^/]*/[^/][^/]*\)$#\1#' || true)

protection_case() {
    local desc="$1" repo="$2" input="$3" expected_exit="$4"
    actual_exit=0
    echo "$input" | EXOSUIT_FRAMEWORK_REPO="$repo" sh "$HOOK" >/dev/null 2>/dev/null || actual_exit=$?
    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected exit $expected_exit, got $actual_exit)"
        FAIL=$((FAIL + 1))
    fi
}

if [ "$ORIGIN_PATH" = "joris887/exosuit" ]; then
    protection_case "Blocks push when origin is the framework repo" \
        "joris887/exosuit" "$(payload '"git push -u origin main"')" 2

    # `git -C <path> push` was not matched by the trigger regex, so it slipped
    # past this check entirely while still hitting the safety patterns.
    protection_case "Blocks git -C push (no bypass via -C)" \
        "joris887/exosuit" "$(payload '"git -C /tmp/elsewhere push -u origin main"')" 2

    # The remote was compared with a substring test, so joris887/exosuit-homepage
    # matched joris887/exosuit and could never be pushed. Match must be exact.
    protection_case "Exact match only: a prefix does not block" \
        "joris887/exo" "$(payload '"git push -u origin main"')" 0
else
    echo "  SKIP: framework repo protection (origin is '$ORIGIN_PATH', not a framework checkout)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
