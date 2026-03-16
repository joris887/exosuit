# Claude Code Hooks

Hook system that enforces quality and safety automatically during Claude Code sessions.

## Architecture

All hooks are self-contained **POSIX shell scripts** — no Python or other runtime required. Each hook event maps to its own script. Rules are stored in simple text formats readable by shell tools.

```
.claude/hooks/
  pre-tool-use.sh        — Block dangerous Bash commands
  post-tool-use.sh       — Activity logging
  session-start.sh       — Advisory environment checks
  stop.sh                — Auto-save + completion evidence validation
  user-prompt.sh         — Advisory intent classification
  subagent-stop.sh       — Subagent quality warnings
  worktree.sh            — Worktree init + cleanup
  worktree-bash-fix.sh   — Worktree directory fix (apply_to_subagents)
  post-edit-format.sh    — Auto-format after edits (bash, not POSIX)
  status-line.sh         — Status bar output (not a hook)
  rules/
    safety.patterns      — PreToolUse blocking patterns (@@-delimited)
    quality.conf         — Stop quality gate rules (key=value)
    subagent.patterns    — SubagentStop validation patterns (@@-delimited)
    subagent.conf        — SubagentStop configuration (key=value)
    intent.patterns      — UserPromptSubmit intent patterns (@@-delimited)
  state/
    stop-iteration       — Stop hook iteration counter (plain number)
    session-started      — Session start timestamp
  lib/
    paths.sh             — Path resolution helpers (sourced by bash hooks)
```

## Hook Events

### SessionStart
Advisory environment checks (never blocks):
- Tool existence from CLAUDE.md Commands
- Stale session detection (auto-save >24h old)
- Git state (on main, detached HEAD, uncommitted changes)
- Initializes session state files

### PreToolUse (Bash)
Blocks dangerous commands via `rules/safety.patterns`:
- `git push --force` / `-f`, `git checkout .`, `git reset --hard`, `git clean -f`
- `rm -rf /` / `..` / `~`
- Package publishing, destructive DB operations, mass process killing
- Framework template repo protection

### PostToolUse (Edit|Write|Bash)
Activity logging to `docs/sessions/.activity-log.jsonl`. Rotates at 200 entries. Used by `/retrospective` and `/handoff`.

### PostToolUse (Edit) — bash
`post-edit-format.sh`: Auto-formats edited files using detected project formatter. Uses bash (not POSIX sh) for array support.

### Stop
Auto-saves session state, then validates completion evidence via `rules/quality.conf`:
- Blocks completion claims without test output
- Safety valve: allows after 5 blocked attempts

### UserPromptSubmit
Advisory warning for destructive-sounding requests. Never blocks.

### SubagentStop
Advisory quality check on subagent output. Warns on weak claims and missing file:line references.

### WorktreeCreate / WorktreeRemove
Copies state files to new worktrees. Merges activity logs on cleanup.

### PreToolUse (Bash) — worktree fix
`worktree-bash-fix.sh`: Transparent worktree directory fix with `apply_to_subagents`.

## Customization

- **Add safety rules:** Edit `rules/safety.patterns` — add lines with `id@@regex@@message`
- **Add quality checks:** Edit `rules/quality.conf` — adjust regex patterns
- **Add formatters:** Edit `post-edit-format.sh` case statement
- **Add intent warnings:** Edit `rules/intent.patterns`

## Configuration

Hooks are configured in `.claude/settings.json`. Each hook event points to its own shell script. No external runtime dependencies required.

## Disabling Hooks

Remove or comment out the relevant section in `.claude/settings.json`.
