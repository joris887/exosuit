# Claude Code Hooks

Hook scripts that enforce quality and safety automatically during Claude Code sessions.

## Hook Types

### session-start.sh (SessionStart)
Runs at session start. Advisory-only environment checks (always exits 0, never blocks):
- **Tool existence:** Checks tools referenced in CLAUDE.md Commands are in PATH
- **Stale session:** Warns if `docs/sessions/.auto-save.md` is older than 24 hours
- **Git state:** Warns if on main, detached HEAD, or uncommitted changes
- **Hook coverage:** Warns if Stop or PostToolUse hooks are not configured

### activity-logger.sh (PostToolUse)
Runs after Edit, Write, and Bash tool invocations. Logs timestamped JSON lines to `docs/sessions/.activity-log.jsonl` for session activity tracking. Rotates at 200 entries. Used by `/retrospective` for metrics and `/handoff` for activity summaries.

### post-edit-format.sh (PostToolUse)
Runs after Claude edits a file. Auto-formats the file using your project's formatter, then runs the linter in auto-fix mode on the same file.

**Supported formatters:** prettier, biome, ruff, black, rustfmt, gofmt, swift-format, rubocop
**Supported linters (auto-fix):** ruff, eslint, biome, golangci-lint (Rust clippy and Swift swiftlint skipped — they require full project context)

### pre_stop_quality.py / pre-stop-quality.sh (Stop)
Runs before Claude reports a task as complete. The Python version (preferred) analyzes `last_assistant_message` for unverified completion claims ("should work", "I think", etc.) and blocks (exit 2) when completion is claimed without test evidence. Also auto-saves session state. Falls back to the bash version if Python is unavailable. The bash version executes lint, typecheck, and test suite checks.

### user-prompt-handler.sh (UserPromptSubmit)
Runs before processing user input. Advisory-only — warns when destructive-sounding phrases are detected (e.g., "delete everything", "drop database", "nuke"). Never blocks (always exits 0). Gracefully degrades if jq is unavailable.

### worktree-init.sh (WorktreeCreate)
Runs when a new worktree is created via `/parallel-work` or `EnterWorktree`. Copies framework state files (`.failure-state.md`, `.auto-save.md`) from the main worktree to the new one. Advisory only.

### worktree-cleanup.sh (WorktreeRemove)
Runs when a worktree is removed. Merges `docs/sessions/.activity-log.jsonl` back to the main worktree so activity logs are not lost. Advisory only.

### subagent_validator.py (SubagentStop)
Runs after each subagent completes. Warns (via stderr) when subagent output contains weak claim language ("should work", "I think") or lacks file:line references (for outputs >200 chars). Advisory only — never blocks.

### pre-tool-safety.sh (PreToolUse)
Runs before Bash commands execute. Blocks dangerous operations:
- `git push --force` / `git push -f`
- `git checkout .` (discard all changes)
- `git reset --hard`
- `git clean -f`
- `rm -rf /` or `rm -rf ..` or `rm -rf ~`
- Package publishing (`npm publish`, `cargo publish`, `twine upload`, `gem push`, `pod trunk push`)
- Destructive database operations (`DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`)
- Mass process killing (`kill -9 -1`, `killall`, `pkill -9`)

## Configuration

Hooks are configured in `.claude/settings.json`. The `/bootstrap` skill customizes them for your detected stack.

To enable hooks manually, add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "bash .claude/hooks/post-edit-format.sh $FILE_PATH"
      }
    ],
    "Stop": [
      {
        "command": "bash .claude/hooks/pre-stop-quality.sh"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "bash .claude/hooks/pre-tool-safety.sh \"$COMMAND\""
      }
    ]
  }
}
```

## Customization

Edit the hook scripts directly. They're plain bash scripts.

- **Add formatters:** Edit `post-edit-format.sh` case statement
- **Add quality checks:** Uncomment or add commands in `pre-stop-quality.sh`
- **Add safety rules:** Add grep patterns in `pre-tool-safety.sh`

## Requirements

Each hook declares its requirements in a comment header:

```bash
# Requirements: <required tools>
# Optional: <optional tools>
# Behavior: <what the hook does>
```

Hooks degrade gracefully when optional tools are missing — they report the missing tool once per session and skip that step. Required tools (like `grep` for safety hooks) are always available on standard systems.

Run `/doctor` to check all hook dependencies at once.

## Disabling Hooks

Remove or comment out the relevant section in `.claude/settings.json`.
