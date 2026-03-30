# Claude Code Hooks

Hook system that enforces quality and safety automatically during Claude Code sessions.

## Architecture

All hooks are self-contained **POSIX shell scripts** — no Python or other runtime required. Each hook event maps to its own script. Rules are stored in simple text formats readable by shell tools.

```
.claude/hooks/
  pre-tool-use.sh        — Block dangerous Bash commands + advisory warnings
  pre-read-check.sh      — Warn when reading sensitive files (advisory)
  post-tool-use.sh       — Activity logging + test/build failure tracking
  session-start.sh       — Advisory environment checks
  stop.sh                — Auto-save + debug audit + completion evidence validation
  user-prompt.sh         — Intent classification + skill tracking + dependency advisory
  subagent-stop.sh       — Subagent quality warnings
  worktree.sh            — Worktree init + cleanup
  worktree-bash-fix.sh   — Worktree directory fix (apply_to_subagents)
  post-edit-format.sh    — Auto-format after edits (bash, not POSIX)
  status-line.sh         — Status bar output (not a hook)
  lib/
    paths.sh             — Path resolution helpers (sourced by bash hooks)
    hook-guard.sh        — Profile + disable check (called by all hooks)
  rules/
    safety.patterns      — PreToolUse blocking patterns (@@-delimited, with severity)
    advisory.patterns    — PreToolUse advisory patterns (warn only, @@-delimited)
    sensitive-files.patterns — PreToolUse (Read) sensitive file patterns
    debug.patterns       — Stop hook debug statement audit patterns
    quality.conf         — Stop quality gate rules (key=value)
    subagent.patterns    — SubagentStop validation patterns (@@-delimited)
    subagent.conf        — SubagentStop configuration (key=value)
    intent.patterns      — UserPromptSubmit intent patterns (@@-delimited)
  state/
    stop-iteration       — Stop hook iteration counter (plain number)
    session-started      — Session start timestamp
    tests-passed         — Test pass timestamp (set by post-tool-use.sh)
```

## Hook Profiles

Control hook strictness via the `JD_HOOK_PROFILE` environment variable:

| Profile | Level | What's Active |
|---------|-------|---------------|
| `minimal` | 1 | Critical safety blocks only (force push, rm -rf, --no-verify), activity logging, session checks |
| `standard` | 2 | Everything in minimal + completion evidence, intent warnings, formatting, subagent checks, skill tracking, sensitive file warnings (default) |
| `strict` | 3 | Everything in standard + strict-only patterns |

```bash
# Examples:
export JD_HOOK_PROFILE=minimal    # Lightweight mode — safety only
export JD_HOOK_PROFILE=standard   # Default — full enforcement
export JD_HOOK_PROFILE=strict     # Maximum strictness
```

### Pattern Severity

Safety patterns support an optional severity field: `id@@regex@@message@@severity`

- `critical` — Active at all profiles (force push, rm -rf, etc.)
- `standard` — Active at standard and strict (default if omitted)
- `strict` — Active at strict only

## Explanation Mode

Control the verbosity of hook messages via `JD_EXPLAIN_MODE`:

| Mode | Behavior |
|------|----------|
| `off` | Suppress advisory messages (blocks still exit non-zero with no output) |
| `brief` | Short messages — what was blocked/warned (default) |
| `verbose` | Full explanations — WHY it matters + safer alternatives |

```bash
export JD_EXPLAIN_MODE=verbose   # Recommended for beginners and newcomers
export JD_EXPLAIN_MODE=brief     # Default
export JD_EXPLAIN_MODE=off       # Experienced users who know the rules
```

Pattern files support an optional 5th field for explanations: `id@@regex@@message@@severity@@explanation`. When `JD_EXPLAIN_MODE=verbose`, the explanation is appended to the message.

## Runtime Hook Disabling

Disable specific hooks without editing settings.json:

```bash
export JD_DISABLED_HOOKS="stop,post-edit-format"  # Comma-separated hook IDs
```

Available hook IDs: `pre-tool-use`, `pre-read-check`, `post-tool-use`, `post-edit-format`, `session-start`, `stop`, `user-prompt`, `subagent-stop`

## Hook Events

### SessionStart
Advisory environment checks (never blocks):
- Tool existence from CLAUDE.md Commands
- Stale/recent session detection (auto-save >4h old → suggest /continue)
- Git state (on main, detached HEAD, uncommitted changes)
- Unicode anomaly scan in AI config files
- Initializes session state files

### PreToolUse (Bash)
Blocks dangerous commands via `rules/safety.patterns`:
- `git push --force` / `-f`, `git checkout .`, `git reset --hard`, `git clean -f`
- `rm -rf /` / `..` / `~`
- Package publishing, destructive DB operations, mass process killing
- Framework template repo protection

Advisory warnings via `rules/advisory.patterns`:
- Long-running dev servers (npm dev, flask run, rails server, etc.)

### PreToolUse (Read)
`pre-read-check.sh`: Warns when reading sensitive files (.env, .key, .pem, credentials). Advisory only — never blocks.

### PostToolUse (Edit|Write|Bash)
Activity logging to `docs/sessions/.activity-log.jsonl`. Rotates at 200 entries.
- Tracks successful test runs → sets `state/tests-passed`
- Tracks test/build failures → logs to `docs/sessions/.failure-log.jsonl`

### PostToolUse (Edit) — bash
`post-edit-format.sh`: Auto-formats edited files using detected project formatter.

### Stop
Auto-saves session state (git + active skill context), then:
1. Debug statement audit: scans git diff for leftover debug statements (advisory)
2. Completion evidence validation: blocks claims without test output
3. Safety valve: allows after max iterations (default 5, override via `JD_STOP_MAX_ITERATIONS` env var or `quality.conf max_iterations`; ≤0 = no limit)

### UserPromptSubmit
- Advisory warning for destructive-sounding requests (intent.patterns)
- Skill usage tracking: logs `/skill-name` invocations to activity log
- Bootstrap dependency advisory: warns if CLAUDE.md has placeholder content

### SubagentStop
Advisory quality check on subagent output. Warns on weak claims and missing file:line references.

### WorktreeCreate / WorktreeRemove
Copies state files to new worktrees. Merges activity logs on cleanup.

### PreToolUse (Bash) — worktree fix
`worktree-bash-fix.sh`: Transparent worktree directory fix with `apply_to_subagents`.

## Customization

- **Add safety rules:** Edit `rules/safety.patterns` — add lines with `id@@regex@@message` (or `id@@regex@@message@@severity`)
- **Add advisory rules:** Edit `rules/advisory.patterns` — same format, warn-only
- **Add sensitive file rules:** Edit `rules/sensitive-files.patterns`
- **Add debug patterns:** Edit `rules/debug.patterns`
- **Adjust quality checks:** Edit `rules/quality.conf` — adjust regex patterns
- **Add formatters:** Edit `post-edit-format.sh` case statement
- **Add intent warnings:** Edit `rules/intent.patterns`

## Configuration

Hooks are configured in `.claude/settings.json`. Each hook event points to its own shell script. No external runtime dependencies required.

## Disabling Hooks

Three options, from temporary to permanent:

1. **Per-session:** `export JD_DISABLED_HOOKS="hook-id-1,hook-id-2"`
2. **Per-profile:** `export JD_HOOK_PROFILE=minimal` (only critical hooks active)
3. **Permanent:** Remove the relevant section in `.claude/settings.json`
