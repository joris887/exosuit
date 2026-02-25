# Claude Code Hooks

Hook system that enforces quality and safety automatically during Claude Code sessions.

## Architecture

All hooks are dispatched through a unified **Python engine** (`engine.py`) with YAML-based rule configuration. Two bash hooks are kept for POSIX-specific and file-type-specific tasks.

```
.claude/hooks/
  engine.py              — Unified dispatch entry point
  rules/                 — YAML rule configuration
    safety.yaml          — PreToolUse blocking patterns
    quality.yaml         — Stop quality gate rules
    subagent.yaml        — SubagentStop validation rules
    intent.yaml          — UserPromptSubmit intent rules
  handlers/              — Per-event handler modules
    pre_tool_use.py      — Block dangerous Bash commands
    post_tool_use.py     — Activity logging
    stop.py              — Auto-save + completion evidence validation
    user_prompt.py       — Advisory intent classification
    subagent_stop.py     — Subagent quality warnings
    session_start.py     — Advisory environment checks
    worktree.py          — Worktree init + cleanup
  state/
    session.json         — Per-session state (warnings, iterations)
  worktree-bash-fix.sh   — Worktree directory fix (bash, apply_to_subagents)
  post-edit-format.sh    — Auto-format after edits (bash)
  status-line.sh         — Status bar output (not a hook)
```

## Hook Events

### SessionStart
Advisory environment checks (never blocks):
- Tool existence from CLAUDE.md Commands
- Stale session detection (auto-save >24h old)
- Git state (on main, detached HEAD, uncommitted changes)
- Initializes session state

### PreToolUse (Bash)
Blocks dangerous commands via `rules/safety.yaml`:
- `git push --force` / `-f`, `git checkout .`, `git reset --hard`, `git clean -f`
- `rm -rf /` / `..` / `~`
- Package publishing, destructive DB operations, mass process killing
- Framework template repo protection

### PostToolUse (Edit|Write|Bash)
Activity logging to `docs/sessions/.activity-log.jsonl`. Rotates at 200 entries. Used by `/retrospective` and `/handoff`.

### PostToolUse (Edit) — bash
`post-edit-format.sh`: Auto-formats edited files using detected project formatter. Stays as bash for file-type switching.

### Stop
Auto-saves session state, then validates completion evidence via `rules/quality.yaml`:
- Blocks weak claims ("should work", "I think")
- Blocks completion claims without test output

### UserPromptSubmit
Advisory warning for destructive-sounding requests. Never blocks.

### SubagentStop
Advisory quality check on subagent output. Warns on weak claims and missing file:line references.

### WorktreeCreate / WorktreeRemove
Copies state files to new worktrees. Merges activity logs on cleanup.

### PreToolUse (Bash) — bash
`worktree-bash-fix.sh`: Transparent worktree directory fix. Stays as bash with `apply_to_subagents`.

## Customization

- **Add safety rules:** Edit `rules/safety.yaml` — add patterns with id, regex, message
- **Add quality checks:** Edit `rules/quality.yaml` — adjust regex patterns
- **Add formatters:** Edit `post-edit-format.sh` case statement
- **Add intent warnings:** Edit `rules/intent.yaml`

## Configuration

Hooks are configured in `.claude/settings.json`. All hooks route through `python3 .claude/hooks/engine.py <event>` except the two kept bash hooks.

## Disabling Hooks

Remove or comment out the relevant section in `.claude/settings.json`.
