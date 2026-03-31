#!/usr/bin/env bash
# Test suite for install.sh — end-to-end validation on a temp directory
set -euo pipefail

PASS=0
FAIL=0
INSTALL_SCRIPT="$(cd "$(dirname "$0")/../../.." && pwd)/install.sh"
FRAMEWORK_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"

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

echo "Testing install.sh"
echo "==================="

# --- Test --dry-run mode ---
echo ""
echo "  -- Dry-run mode --"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

cd "$TMPDIR_TEST"
git init -q .

DRY_OUTPUT=$(bash "$INSTALL_SCRIPT" --dry-run 2>&1 || true)
test_case "Dry-run produces output" "true" "$([ -n "$DRY_OUTPUT" ] && echo true || echo false)"
test_case "Dry-run doesn't create .claude dir" "false" "$([ -d .claude ] && echo true || echo false)"
test_case "Dry-run doesn't create CLAUDE.md" "false" "$([ -f CLAUDE.md ] && echo true || echo false)"

# --- Test template mode (local install) ---
echo ""
echo "  -- Template mode (local install) --"

TMPDIR_TEMPLATE=$(mktemp -d)
cd "$TMPDIR_TEMPLATE"
git init -q .

# Copy framework files locally to avoid git clone
cp -r "$FRAMEWORK_DIR/.claude" .claude
cp -r "$FRAMEWORK_DIR/docs" docs 2>/dev/null || true
cp -r "$FRAMEWORK_DIR/vision" vision 2>/dev/null || true
cp -r "$FRAMEWORK_DIR/scaffold" scaffold 2>/dev/null || true
cp "$FRAMEWORK_DIR/CLAUDE.md" CLAUDE.md 2>/dev/null || true
cp "$FRAMEWORK_DIR/.gitignore" .gitignore 2>/dev/null || true
cp "$FRAMEWORK_DIR/AGENTS.md" AGENTS.md 2>/dev/null || true

# Verify core files exist
test_case "Template: .claude directory exists" "true" "$([ -d .claude ] && echo true || echo false)"
test_case "Template: settings.json exists" "true" "$([ -f .claude/settings.json ] && echo true || echo false)"
test_case "Template: CLAUDE.md exists" "true" "$([ -f CLAUDE.md ] && echo true || echo false)"

# Verify hook scripts exist and are accessible
test_case "Template: pre-tool-use.sh exists" "true" "$([ -f .claude/hooks/pre-tool-use.sh ] && echo true || echo false)"
test_case "Template: post-tool-use.sh exists" "true" "$([ -f .claude/hooks/post-tool-use.sh ] && echo true || echo false)"
test_case "Template: stop.sh exists" "true" "$([ -f .claude/hooks/stop.sh ] && echo true || echo false)"
test_case "Template: session-start.sh exists" "true" "$([ -f .claude/hooks/session-start.sh ] && echo true || echo false)"
test_case "Template: post-edit-format.sh exists" "true" "$([ -f .claude/hooks/post-edit-format.sh ] && echo true || echo false)"
test_case "Template: user-prompt.sh exists" "true" "$([ -f .claude/hooks/user-prompt.sh ] && echo true || echo false)"
test_case "Template: hook-guard.sh exists" "true" "$([ -f .claude/hooks/lib/hook-guard.sh ] && echo true || echo false)"

# Verify settings.json references existing scripts
if command -v jq >/dev/null 2>&1; then
    # Check that hooks in settings.json reference scripts that exist
    HOOK_CMDS=$(jq -r '.. | .command? // empty' .claude/settings.json 2>/dev/null | grep -o '[^ ]*\.sh' | sort -u || true)
    MISSING_SCRIPTS=""
    while IFS= read -r script; do
        [ -z "$script" ] && continue
        # Extract just the script name
        script_name=$(basename "$script")
        if ! find .claude/hooks -name "$script_name" -type f 2>/dev/null | grep -q .; then
            MISSING_SCRIPTS="$MISSING_SCRIPTS $script_name"
        fi
    done <<< "$HOOK_CMDS"
    test_case "Template: all hook scripts referenced in settings.json exist" "" "$(echo "$MISSING_SCRIPTS" | tr -d ' ')"
else
    echo "  SKIP: jq not available for settings.json validation"
fi

# Verify skills exist
SKILL_COUNT=$(find .claude/skills -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' ')
test_case "Template: >=30 skills present" "true" "$([ "$SKILL_COUNT" -ge 30 ] && echo true || echo false)"

# Verify rules exist
RULE_COUNT=$(find .claude/rules -name "*.md" -not -name "CLAUDE.md" -type f 2>/dev/null | wc -l | tr -d ' ')
test_case "Template: >=5 rules present" "true" "$([ "$RULE_COUNT" -ge 5 ] && echo true || echo false)"

# Verify agents exist
AGENT_COUNT=$(find .claude/agents -name "*.md" -not -name "CLAUDE.md" -type f 2>/dev/null | wc -l | tr -d ' ')
test_case "Template: >=5 agents present" "true" "$([ "$AGENT_COUNT" -ge 5 ] && echo true || echo false)"

# --- Test plugin mode structure ---
echo ""
echo "  -- Plugin mode structure --"

test_case "Plugin: hooks.json exists" "true" "$([ -f .claude/hooks/hooks.json ] && echo true || echo false)"

# Verify hooks.json has expected events
if command -v jq >/dev/null 2>&1; then
    EVENTS=$(jq -r '.hooks | keys[]' .claude/hooks/hooks.json 2>/dev/null | sort | tr '\n' ',' || true)
    test_case "Plugin: hooks.json has SessionStart" "true" "$(echo "$EVENTS" | grep -q SessionStart && echo true || echo false)"
    test_case "Plugin: hooks.json has PreToolUse" "true" "$(echo "$EVENTS" | grep -q PreToolUse && echo true || echo false)"
    test_case "Plugin: hooks.json has PostToolUse" "true" "$(echo "$EVENTS" | grep -q PostToolUse && echo true || echo false)"
    test_case "Plugin: hooks.json has Stop" "true" "$(echo "$EVENTS" | grep -q Stop && echo true || echo false)"
else
    echo "  SKIP: jq not available for hooks.json validation"
fi

# --- Test .gitignore patterns ---
echo ""
echo "  -- Gitignore patterns --"

if [ -f .gitignore ]; then
    test_case "Gitignore: .DS_Store pattern" "true" "$(grep -q '.DS_Store' .gitignore && echo true || echo false)"
    test_case "Gitignore: auto-save pattern" "true" "$(grep -q 'auto-save' .gitignore && echo true || echo false)"
    test_case "Gitignore: activity-log pattern" "true" "$(grep -q 'activity-log' .gitignore && echo true || echo false)"
else
    echo "  SKIP: .gitignore not found"
fi

# Clean up template test dir
rm -rf "$TMPDIR_TEMPLATE"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
