#!/usr/bin/env bash
# Test suite for user-prompt.sh — intent detection, skill tracking, skill suggestions
set -euo pipefail

HOOK="../user-prompt.sh"
PASS=0
FAIL=0

# Create temp state directory
TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

test_case() {
    local desc="$1"
    local expected="$2"
    local actual="$3"

    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

echo "Testing user-prompt.sh"
echo "======================"

# Ensure standard profile (the hook requires it)
export EXOSUIT_HOOK_PROFILE="standard"
export EXOSUIT_DISABLED_HOOKS=""
export EXOSUIT_PROJECT_PROFILE="standard"

# --- Intent pattern matching ---
echo ""
echo "  -- Intent pattern detection --"

# UserPromptSubmit carries the prompt text in the top-level "prompt" field. Tests
# MUST use that name — an earlier version passed "user_prompt", which matched a bug
# in the hook and made every prompt read as empty. The hook then exited early, so
# the "no warning" case passed for the wrong reason and the failure stayed hidden.
prompt_payload() {
    printf '{"session_id":"test","transcript_path":"/tmp/t.jsonl","cwd":"/tmp","hook_event_name":"UserPromptSubmit","prompt":%s}' "$1"
}

# Destructive intent should produce a warning
OUTPUT=$(echo "$(prompt_payload '"please delete all the test files and wipe everything"')" | sh "$HOOK" 2>&1 || true)
WARN_FOUND=$(echo "$OUTPUT" | grep -Ei "warning|caution|destructive" | head -1 || true)
test_case "Destructive intent triggers warning" "true" "$([ -n "$WARN_FOUND" ] && echo true || echo false)"

# Normal intent should not produce a warning
OUTPUT=$(echo "$(prompt_payload '"add a login form to the auth page"')" | sh "$HOOK" 2>&1 || true)
WARN_MATCH=$(echo "$OUTPUT" | grep -i "warning" || true)
test_case "Normal intent no warning" "" "$WARN_MATCH"

# Regression: reading the wrong field must not silently pass. A payload carrying
# only the old "user_prompt" name has no readable prompt, so no warning fires —
# this asserts the shape actually matters instead of passing vacuously.
OUTPUT=$(echo '{"hook_event_name":"UserPromptSubmit","user_prompt":"delete all the test files and wipe everything"}' | sh "$HOOK" 2>&1 || true)
WARN_LEGACY=$(echo "$OUTPUT" | grep -Ei "warning|caution|destructive" | head -1 || true)
test_case "Legacy user_prompt field is not read" "" "$WARN_LEGACY"

# --- Skill invocation tracking ---
echo ""
echo "  -- Skill invocation detection --"

# Detect /skill-name at start of prompt
SKILL=$(echo '/debug-session some error message' | sed -n 's|^/\([a-zA-Z][-a-zA-Z0-9]*\).*|\1|p')
test_case "Extract skill name from /debug-session" "debug-session" "$SKILL"

SKILL=$(echo '/story-cycle "add auth"' | sed -n 's|^/\([a-zA-Z][-a-zA-Z0-9]*\).*|\1|p')
test_case "Extract skill name from /story-cycle" "story-cycle" "$SKILL"

SKILL=$(echo 'just a normal prompt' | sed -n 's|^/\([a-zA-Z][-a-zA-Z0-9]*\).*|\1|p')
test_case "No skill name in normal prompt" "" "$SKILL"

SKILL=$(echo '/commit' | sed -n 's|^/\([a-zA-Z][-a-zA-Z0-9]*\).*|\1|p')
test_case "Extract skill name from /commit (no args)" "commit" "$SKILL"

# --- Skill suggestion patterns ---
echo ""
echo "  -- Skill suggestion pattern matching --"

PATTERNS_FILE="../rules/skill-suggestions.patterns"
if [ -f "$PATTERNS_FILE" ]; then
    # Test that patterns file is parseable
    LINE_COUNT=$(grep -cv '^#\|^$' "$PATTERNS_FILE" 2>/dev/null || echo 0)
    test_case "Suggestion patterns file has entries" "true" "$([ "$LINE_COUNT" -gt 0 ] && echo true || echo false)"

    # Test bug pattern matches debug-session
    MATCH=""
    while IFS= read -r line; do
        case "$line" in '#'*|'') continue ;; esac
        s_regex=$(printf '%s' "$line" | sed 's/@@.*//')
        s_rest=$(printf '%s' "$line" | sed 's/^[^@]*@@//')
        s_skill=$(printf '%s' "$s_rest" | sed 's/@@.*//')
        if printf '%s' "there is a bug in the login" | grep -qEi -- "$s_regex" 2>/dev/null; then
            MATCH="$s_skill"
            break
        fi
    done < "$PATTERNS_FILE"
    test_case "Bug intent matches debug-session" "debug-session" "$MATCH"

    # Test ship/merge matches sprint-end
    MATCH=""
    while IFS= read -r line; do
        case "$line" in '#'*|'') continue ;; esac
        s_regex=$(printf '%s' "$line" | sed 's/@@.*//')
        s_rest=$(printf '%s' "$line" | sed 's/^[^@]*@@//')
        s_skill=$(printf '%s' "$s_rest" | sed 's/@@.*//')
        if printf '%s' "let's ship this and merge to main" | grep -qEi -- "$s_regex" 2>/dev/null; then
            MATCH="$s_skill"
            break
        fi
    done < "$PATTERNS_FILE"
    test_case "Ship intent matches sprint-end" "sprint-end" "$MATCH"

    # Test plan/stories matches ideate
    MATCH=""
    while IFS= read -r line; do
        case "$line" in '#'*|'') continue ;; esac
        s_regex=$(printf '%s' "$line" | sed 's/@@.*//')
        s_rest=$(printf '%s' "$line" | sed 's/^[^@]*@@//')
        s_skill=$(printf '%s' "$s_rest" | sed 's/@@.*//')
        if printf '%s' "can you break down this feature into stories" | grep -qEi -- "$s_regex" 2>/dev/null; then
            MATCH="$s_skill"
            break
        fi
    done < "$PATTERNS_FILE"
    test_case "Plan intent matches ideate" "ideate" "$MATCH"

    # Test undo/revert matches undo-work
    MATCH=""
    while IFS= read -r line; do
        case "$line" in '#'*|'') continue ;; esac
        s_regex=$(printf '%s' "$line" | sed 's/@@.*//')
        s_rest=$(printf '%s' "$line" | sed 's/^[^@]*@@//')
        s_skill=$(printf '%s' "$s_rest" | sed 's/@@.*//')
        if printf '%s' "I need to revert my last change" | grep -qEi -- "$s_regex" 2>/dev/null; then
            MATCH="$s_skill"
            break
        fi
    done < "$PATTERNS_FILE"
    test_case "Revert intent matches undo-work" "undo-work" "$MATCH"
else
    echo "  SKIP: No skill-suggestions.patterns file found"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
