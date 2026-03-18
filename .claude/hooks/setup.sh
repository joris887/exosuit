#!/bin/sh
# Setup hook: framework health check on `claude --init` or `claude --maintenance`.
# Validates hook scripts, settings, and required tools.
#
# Input:  JSON on stdin (Setup event data)
# Output: exit 0 always, stderr = health check results

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
ERRORS=0
WARNINGS=0

printf '=== JD-LLM Framework Health Check ===\n' >&2

# --- 1. Verify hook scripts exist and are executable ---
printf '\n[Hooks]\n' >&2
for script in pre-tool-use.sh post-tool-use.sh session-start.sh stop.sh \
              post-edit-format.sh user-prompt.sh subagent-stop.sh worktree.sh \
              worktree-bash-fix.sh status-line.sh pre-compact.sh post-compact.sh \
              stop-failure.sh session-end.sh; do
    SCRIPT_PATH="$HOOKS_DIR/$script"
    if [ -f "$SCRIPT_PATH" ]; then
        if [ -x "$SCRIPT_PATH" ] || [ "$(head -1 "$SCRIPT_PATH" 2>/dev/null)" = "#!/bin/sh" ]; then
            printf '  PASS: %s\n' "$script" >&2
        else
            printf '  WARN: %s exists but may not be executable\n' "$script" >&2
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        printf '  MISS: %s not found\n' "$script" >&2
        WARNINGS=$((WARNINGS + 1))
    fi
done

# --- 2. Verify settings.json is valid ---
printf '\n[Settings]\n' >&2
SETTINGS_FILE=".claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import json; json.load(open('$SETTINGS_FILE'))" 2>/dev/null; then
            printf '  PASS: settings.json is valid JSON\n' >&2
        else
            printf '  FAIL: settings.json is invalid JSON\n' >&2
            ERRORS=$((ERRORS + 1))
        fi
    elif command -v jq >/dev/null 2>&1; then
        if jq empty "$SETTINGS_FILE" 2>/dev/null; then
            printf '  PASS: settings.json is valid JSON\n' >&2
        else
            printf '  FAIL: settings.json is invalid JSON\n' >&2
            ERRORS=$((ERRORS + 1))
        fi
    else
        printf '  SKIP: no JSON validator available (install jq or python3)\n' >&2
    fi

    # Check key settings
    for setting in attribution plansDirectory includeGitInstructions; do
        if grep -q "\"$setting\"" "$SETTINGS_FILE" 2>/dev/null; then
            printf '  PASS: %s configured\n' "$setting" >&2
        else
            printf '  WARN: %s not found in settings\n' "$setting" >&2
            WARNINGS=$((WARNINGS + 1))
        fi
    done
else
    printf '  FAIL: settings.json not found\n' >&2
    ERRORS=$((ERRORS + 1))
fi

# --- 3. Verify required directories ---
printf '\n[Structure]\n' >&2
for dir in .claude/hooks .claude/rules .claude/skills .claude/agents .claude/prompts; do
    if [ -d "$dir" ]; then
        printf '  PASS: %s/\n' "$dir" >&2
    else
        printf '  MISS: %s/ not found\n' "$dir" >&2
        WARNINGS=$((WARNINGS + 1))
    fi
done

# --- 4. Verify rule files ---
printf '\n[Rules]\n' >&2
RULE_COUNT=0
for rule in .claude/rules/*.md; do
    [ -f "$rule" ] && RULE_COUNT=$((RULE_COUNT + 1))
done
printf '  %d rule files found\n' "$RULE_COUNT" >&2

# --- 5. Summary ---
printf '\n=== Summary ===\n' >&2
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    printf 'Framework health: ALL PASS\n' >&2
elif [ "$ERRORS" -eq 0 ]; then
    printf 'Framework health: %d warnings (no errors)\n' "$WARNINGS" >&2
else
    printf 'Framework health: %d errors, %d warnings\n' "$ERRORS" "$WARNINGS" >&2
fi

exit 0
