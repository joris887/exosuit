# Claude Code Hooks

Hook system that enforces quality and safety automatically during Claude Code sessions.

## Architecture

All hooks are self-contained **POSIX shell scripts** — no Python or other runtime required. Each hook event maps to its own script. Rules are stored in simple text formats readable by shell tools.

```
.claude/hooks/
  pre-tool-use.sh        — Block dangerous Bash commands + advisory warnings
  pre-read-check.sh      — Warn when reading sensitive files (advisory)
  post-tool-use.sh       — Activity logging + test/build failure tracking
  flow-pre-edit.sh       — Flow gate evidence check (advisory-first)
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
    graph-state.sh       — Flow cursor helper (called by flow-contract skills)
    test-paths.sh        — Shared test-path matcher (gate evidence + exemptions)
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
    flow/                — Per-session gate evidence markers (test-written,
                           tests-green) + advisory-dedup dotfiles
```

## Hook Profiles

Control hook strictness via the `EXOSUIT_HOOK_PROFILE` environment variable:

| Profile | Level | What's Active |
|---------|-------|---------------|
| `minimal` | 1 | Critical safety blocks only (force push, rm -rf, --no-verify), activity logging, session checks |
| `standard` | 2 | Everything in minimal + completion evidence, intent warnings, formatting, subagent checks, skill tracking (default) |
| `strict` | 3 | Everything in standard + strict-only patterns + sensitive-file read warnings |

### Noise Control (stop hook)

The stop hook is deliberately narrow about when it speaks. Both its checks —
the debug audit and the completion-evidence gate — are **skipped entirely**
unless the session changed at least one file matching `source_extensions` in
`rules/quality.conf`. A docs, config, or planning session has nothing to audit
and no tests to run.

Three further guards:

- The debug audit scans **only source files**, never the whole diff. Scanning
  everything meant a markdown table column named `TODO` tripped the code-debug
  patterns.
- The evidence gate is skipped when the project has **no detectable test suite**
  (`has_test_suite` in `stop.sh`). Demanding test output from a repo with no
  test runner is unfixable by the model.
- `completion_regex` requires a **subject** — "implementation is complete", not
  the bare word "complete". The bare-word form matched ordinary prose and fired
  on nearly every summary.

`todo-fixme-hack` in `rules/debug.patterns` is **commented out by default** —
TODO markers in real code are usually deliberate. Uncomment it if your team
treats them as ship-blockers.

`pre-read-check` was raised from `standard` to `strict`: it fired on every Read
to match a path regex and never blocked anything.

```bash
# Examples:
export EXOSUIT_HOOK_PROFILE=minimal    # Lightweight mode — safety only
export EXOSUIT_HOOK_PROFILE=standard   # Default — full enforcement
export EXOSUIT_HOOK_PROFILE=strict     # Maximum strictness
```

### Pattern Severity

Safety patterns support an optional severity field: `id@@regex@@message@@severity`

- `critical` — Active at all profiles (force push, rm -rf, etc.)
- `standard` — Active at standard and strict (default if omitted)
- `strict` — Active at strict only

## Explanation Mode

Control the verbosity of hook messages via `EXOSUIT_EXPLAIN_MODE`:

| Mode | Behavior |
|------|----------|
| `off` | Suppress advisory messages (blocks still exit non-zero with no output) |
| `brief` | Short messages — what was blocked/warned (default) |
| `verbose` | Full explanations — WHY it matters + safer alternatives |

```bash
export EXOSUIT_EXPLAIN_MODE=verbose   # Recommended for beginners and newcomers
export EXOSUIT_EXPLAIN_MODE=brief     # Default
export EXOSUIT_EXPLAIN_MODE=off       # Experienced users who know the rules
```

Pattern files support an optional 5th field for explanations: `id@@regex@@message@@severity@@explanation`. When `EXOSUIT_EXPLAIN_MODE=verbose`, the explanation is appended to the message.

## Runtime Hook Disabling

Disable specific hooks without editing settings.json:

```bash
export EXOSUIT_DISABLED_HOOKS="stop,post-edit-format"  # Comma-separated hook IDs
```

Available hook IDs: `pre-tool-use`, `pre-read-check`, `post-tool-use`, `post-edit-format`, `session-start`, `stop`, `user-prompt`, `subagent-stop`, `flow-pre-edit`

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

### PreToolUse (Edit|Write)
`flow-pre-edit.sh`: Flow gate evidence check (see `.claude/skills/FLOW_SPEC.md` → Gate Evidence & Enforcement). Advisory by default; blocks only with explicit `EXOSUIT_FLOW_MODE=block`. Test/docs edits always exempt; fails open.

### PreToolUse (Read)
`pre-read-check.sh`: Warns when reading sensitive files (.env, .key, .pem, credentials). Advisory only — never blocks.

### PostToolUse (Edit|Write|Bash)
Activity logging to `docs/sessions/.activity-log.jsonl`. Type-aware rotation: keeps the last 200 tool lines and the last 500 skill/story event lines, preserving order.
- Stamps flow gate evidence per session: `state/flow/test-written` (test-path Edit/Write, shared patterns in `lib/test-paths.sh`) and `state/flow/tests-green` (passing test run with no nonzero failure count — a failing run revokes it)
- Tracks successful test runs → sets `state/tests-passed`
- Tracks test/build failures → logs to `docs/sessions/.failure-log.jsonl`

### PostToolUse (Edit) — bash
`post-edit-format.sh`: Auto-formats edited files using detected project formatter.

### Stop
Auto-saves session state (git + active skill context), then:
1. Debug statement audit: scans git diff for leftover debug statements (advisory)
2. Completion evidence validation: blocks claims without test output
3. Safety valve: allows after max iterations (default 5, override via `EXOSUIT_STOP_MAX_ITERATIONS` env var or `quality.conf max_iterations`; ≤0 = no limit)
4. Flow check (only with explicit `EXOSUIT_FLOW_MODE=block`): refuses completion while a branch-matched flow cursor sits on a non-terminal node — bounded by the same safety valve

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

1. **Per-session:** `export EXOSUIT_DISABLED_HOOKS="hook-id-1,hook-id-2"`
2. **Per-profile:** `export EXOSUIT_HOOK_PROFILE=minimal` (only critical hooks active)
3. **Permanent:** Remove the relevant section in `.claude/settings.json`
