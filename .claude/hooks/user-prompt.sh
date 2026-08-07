#!/bin/sh
# UserPromptSubmit handler: intent classification + skill tracking + dependency advisory.
# 1. Warns about potentially destructive user requests (intent.patterns).
# 2. Tracks skill invocations in the activity log.
# 3. Warns when skills are invoked before /bootstrap has run.
# Never blocks. POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (user_prompt)
# Output: advisory warnings on stderr, always exit 0

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$HOOKS_DIR/rules"
PATTERNS_FILE="$RULES_DIR/intent.patterns"

# --- Hook guard: profile + disable check ---
"$HOOKS_DIR/lib/hook-guard.sh" "user-prompt" "standard" || exit 0

# --- JSON field extraction ---
extract_json_string() {
    _field="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -r ".$_field // empty"
    else
        sed -n 's/.*"'"$_field"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
    fi
}

# Read stdin once
# UserPromptSubmit carries the prompt text in the top-level "prompt" field.
INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | extract_json_string "prompt")
[ -z "$PROMPT" ] && exit 0

# --- 1. Check intent patterns ---
WARNINGS=""
if [ -f "$PATTERNS_FILE" ]; then
    while IFS= read -r line; do
        case "$line" in
            '#'*|'') continue ;;
        esac

        # Split on @@ delimiter: regex@@message
        regex=$(printf '%s' "$line" | sed 's/@@.*//')
        message=$(printf '%s' "$line" | sed 's/^[^@]*@@//')

        if printf '%s' "$PROMPT" | grep -qEi -- "$regex"; then
            if [ -z "$WARNINGS" ]; then
                WARNINGS="Warning: $message"
            else
                WARNINGS="$WARNINGS
Warning: $message"
            fi
        fi
    done < "$PATTERNS_FILE"
fi

if [ -n "$WARNINGS" ]; then
    printf '%s\n' "$WARNINGS" >&2
fi

# --- 2. Skill usage tracking ---
# Detect /skill-name at the start of the prompt
SKILL_NAME=$(printf '%s' "$PROMPT" | sed -n 's|^/\([a-zA-Z][-a-zA-Z0-9]*\).*|\1|p')
if [ -n "$SKILL_NAME" ]; then
    # Resolve skills directory relative to hooks dir (hooks/ -> skills/)
    SKILLS_DIR="$HOOKS_DIR/../skills"
    if [ -d "$SKILLS_DIR/$SKILL_NAME" ]; then
        # Log skill invocation to activity log
        LOG_DIR="docs/sessions"
        mkdir -p "$LOG_DIR" 2>/dev/null
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
        printf '{"type":"skill","name":"%s","ts":"%s"}\n' "$SKILL_NAME" "$TS" >> "$LOG_DIR/.activity-log.jsonl" 2>/dev/null

        # --- 3. Bootstrap dependency advisory ---
        # Warn if CLAUDE.md still has placeholder content (bootstrap hasn't run)
        if [ "$SKILL_NAME" != "bootstrap" ] && [ "$SKILL_NAME" != "quickstart" ] && [ "$SKILL_NAME" != "help-me" ]; then
            if [ -f "CLAUDE.md" ] && grep -q '\[Project Name\]' CLAUDE.md 2>/dev/null; then
                printf 'Advisory: CLAUDE.md still has placeholder content -- consider running /bootstrap first to configure the framework for your project.\n' >&2
            fi
        fi
    fi
fi

# --- 4. Proactive skill suggestions ---
# Suggest relevant skills based on user intent when not already invoking a skill.
SUGGEST_FILE="$RULES_DIR/skill-suggestions.patterns"
SUGGEST_STATE="$HOOKS_DIR/state/suggestions-shown"
if [ -z "$SKILL_NAME" ] && [ -f "$SUGGEST_FILE" ]; then
    while IFS= read -r line; do
        case "$line" in '#'*|'') continue ;; esac

        # Parse: regex@@skill@@reason
        s_regex=$(printf '%s' "$line" | sed 's/@@.*//')
        s_rest=$(printf '%s' "$line" | sed 's/^[^@]*@@//')
        s_skill=$(printf '%s' "$s_rest" | sed 's/@@.*//')
        s_reason=$(printf '%s' "$s_rest" | sed 's/^[^@]*@@//')

        if printf '%s' "$PROMPT" | grep -qEi -- "$s_regex"; then
            # Session dedup: show each suggestion at most once
            if [ -f "$SUGGEST_STATE" ] && grep -qx "$s_skill" "$SUGGEST_STATE" 2>/dev/null; then
                continue
            fi
            printf 'Suggestion: /%s -- %s\n' "$s_skill" "$s_reason" >&2
            mkdir -p "$HOOKS_DIR/state" 2>/dev/null
            printf '%s\n' "$s_skill" >> "$SUGGEST_STATE"
            break  # At most one suggestion per prompt
        fi
    done < "$SUGGEST_FILE"
fi

exit 0
