---
name: custom-hooks
version: 1.0.0
description: Create project-specific hook scripts and register them in settings.json. Extends the framework's enforcement layer.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: "<hook-event> \"<description>\""
---
______________________________________________________________________

## custom-hooks

Creating a custom hook: **$ARGUMENTS**

## Supported Hook Events

Present available Claude Code hook events:

| Event | When It Fires | Can Block? | Input Fields |
|---|---|---|---|
| `SessionStart` | Once at session start | No | session data |
| `PreToolUse` | Before any tool call | Yes (exit 2) | tool_name, tool_input |
| `PostToolUse` | After any tool call | No | tool_name, tool_input, tool_output |
| `Stop` | When model wants to stop | Yes (exit 2) | last_assistant_message |
| `UserPromptSubmit` | When user submits prompt | No | user_prompt |
| `SubagentStop` | When a subagent completes | No | last_assistant_message |
| `WorktreeCreate` | When a worktree is created | No | — |
| `WorktreeRemove` | When a worktree is removed | No | — |

**Matchers** (for PreToolUse and PostToolUse): Filter by tool name — `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, or combinations with `|` (e.g., `Edit|Write`).

## 1. Understand Requirements

Parse `$ARGUMENTS` to determine:
- **Event type:** Which hook event to listen to
- **Purpose:** What the hook should do
- **Blocking vs Advisory:** Should it block (exit 2) or just warn (exit 0)?

If unclear, ask:
- "Should this hook **block** the action or just **warn**?"
- "Should it fire on specific tools only, or all tools?"
- "Should it run on subagents too?"

## 2. Generate Hook Script

Create a POSIX shell script following the framework's hook conventions:

```bash
#!/bin/sh
# [Event] handler: [description].
# [Blocking|Advisory] — [behavior summary].
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin ([relevant fields])
# Output: exit 0 = allow, exit 2 = block (message on stderr)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

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
INPUT=$(cat)

# --- Hook logic ---
# [Custom logic here]

exit 0
```

### Convention Checklist

- [ ] POSIX sh (not bash) — for portability
- [ ] Reads JSON from stdin via `jq` with `sed` fallback
- [ ] Blocking hooks output message on stderr before `exit 2`
- [ ] Advisory hooks output warnings on stderr, always `exit 0`
- [ ] Graceful degradation — own errors never block the user
- [ ] One-off warnings use state files in `$HOOKS_DIR/state/` to avoid noise

## 3. Register in settings.json

Read `.claude/settings.json` and add the new hook entry under the appropriate event:

```json
{
    "matcher": "[tool-matcher or omit for all]",
    "hooks": [
        {
            "type": "command",
            "command": "cd \"$(git rev-parse --show-toplevel 2>/dev/null || echo .)\" && sh .claude/hooks/<script-name>.sh",
            "statusMessage": "[User-visible status message]..."
        }
    ]
}
```

**Important:** Use the `cd "$(git rev-parse --show-toplevel ...)"` pattern for path resolution, NOT `__PROJECT_ROOT__`.

## 4. Test the Hook

Guide the user to test:

1. **For blocking hooks:** Trigger the condition and verify the block message appears
2. **For advisory hooks:** Trigger the condition and verify the warning appears
3. **For all hooks:** Verify normal operations aren't affected (no false positives)

## 5. Document

Add the hook to `.claude/hooks/README.md`:
- Script name and purpose
- Event type and matcher
- Blocking or advisory
- Any rule files it uses

## Examples

```
/custom-hooks PreToolUse "Block npm install without --save-exact flag"
/custom-hooks PostToolUse "Log all database migration commands to a separate file"
/custom-hooks Stop "Require changelog entry when files in src/api/ were modified"
/custom-hooks UserPromptSubmit "Warn when user asks to skip tests"
```

## Rules

- ALWAYS use POSIX sh, never bash (matches framework convention)
- ALWAYS handle missing jq gracefully (sed fallback)
- ALWAYS test the hook before marking complete
- NEVER let a custom hook's own failure block the user — wrap logic in conditions
- If the hook uses external rule files, create them in `.claude/hooks/rules/` with the `@@`-delimited format
- Save the script to `.claude/hooks/` alongside the framework hooks
