---
name: parallel-work
version: 3.0.0
description: Work on multiple stories at the same time. Creates isolated parallel streams (git worktrees) from the current branch, wires up local settings, and opens each in its own Claude Code session. Also shows stream status and cleans up finished streams. Pairs with /merge-up (publish a stream's work to the parent branch) and /merge-down (pull the parent's accumulated work into a stream).
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
argument-hint: "[status|start [count]|cleanup]"
---
______________________________________________________________________

## parallel-work

Manage parallel development streams. Each stream is an isolated copy of the
project (a git worktree) on its own branch, so multiple Claude Code sessions can
build different stories at the same time without touching each other's files.

## When Parallel Work Makes Sense (and When It Doesn't)

Parallel work is **opt-in, never required**. The default workflow is one branch,
one story at a time — that keeps the user fully aware of every change.

**Good fit:**
- Stories are self-contained: no dependencies on each other, no shared hot files
- Each story is a complete outcome on its own (outcome over output)
- The user is comfortable reviewing several streams of change

**Bad fit — advise sequential work instead:**
- Stories depend on each other (one needs the other's code or schema)
- Stories touch the same files or the same module's core
- The stories are parts of one mechanism (they should be ONE story, not parallel streams)

The `start` command checks this before creating anything (see below). When in
doubt, recommend sequential: merging conflicting parallel work costs more than
it saves.

## Commands

### Status (default, or "status"/"list")

Run the status script:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-.claude}/skills/parallel-work/scripts/worktree-status.sh"
```

Show all active streams with their branches, their parent (from
`git config branch.<name>.exosuitParent`), and ahead/behind counts vs the parent:

```markdown
### Active Streams

| Path | Branch | Parent | Ahead/Behind parent |
|------|--------|--------|---------------------|
| [path] | [branch] | [parent or "-"] | [+N/-M] |

**Options:**
- `/parallel-work start` — create new parallel streams
- `/merge-up` (inside a stream) — publish its work to the parent
- `/merge-down` (inside a stream) — pull the parent's accumulated work in
- `/parallel-work cleanup` — remove finished streams
```

### Start — Create Parallel Streams

If `$ARGUMENTS` contains "start", "create", a count, or story IDs:

**1. Detect context.**

```bash
git rev-parse --abbrev-ref HEAD    # base branch to fan out from
git worktree list                  # what already exists
git status --porcelain             # base should be clean
```

The base is whatever branch is currently checked out — typically the sprint
branch. If HEAD is detached, stop and ask the user to check out a branch first.
If the working tree is dirty, stop: commit or stash first, so every stream
starts from a known state.

**2. Sense-check the parallel plan.**

Ask which stories go into which stream (or accept story IDs from `$ARGUMENTS`).
If the stories exist in the backlog (`docs/reference/backlog/E*.md`), check
each pair of stories chosen for different streams:

- **Dependencies:** if story A lists story B in its Dependencies field, they
  cannot run in parallel. Warn and suggest sequencing.
- **Affected files:** if two stories list overlapping Affected files, warn:
  > "Stories [A] and [B] both touch [files]. Parallel streams will conflict at
  > merge time — consider running them sequentially, or reassigning one."

If the user just wants N identical sandboxes (no story mapping), skip this
check but state the ground rule: one story per stream, no shared files.

If every chosen pair conflicts, recommend NOT parallelizing and stop unless the
user insists.

**3. Decide how many.** From `$ARGUMENTS`, or ask with AskUserQuestion:
"How many parallel streams off `<base>`?" (offer 1 / 2 / 3, Other for more).

**4. Derive branch names.**

- With story IDs: `feat/<story-id>` per stream.
- Without: `<base>-a`, `<base>-b`, `<base>-c`, ... If a name collides with an
  existing branch (`git show-ref --verify refs/heads/<name>`), bump to the next
  free suffix.

**5. Create each stream.** One at a time, surfacing each script's output:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-.claude}/skills/parallel-work/scripts/new-worktree.sh" "<new-branch>"
```

The script creates the worktree as a sibling directory of the main working
tree, records the parent branch in `git config branch.<new-branch>.exosuitParent`
(which is how `/merge-up` and `/merge-down` later find their way home), and
propagates gitignored local settings (`.env`, `.env.local`,
`.claude/settings.local.json`, `CLAUDE.local.md`, and `.mcp.json` with absolute
paths rewritten). Its `Worktree ready: <dir>` line gives the path to reuse next.

**6. Offer to open each stream.** Ask with AskUserQuestion: "Open each stream
in its own terminal tab running Claude Code?"

- **Yes:** collect all `<dir>` paths from step 5 and hand them to the launcher
  in one call:
  ```bash
  bash "${CLAUDE_PLUGIN_ROOT:-.claude}/skills/parallel-work/scripts/open-worktree-terminals.sh" "<dir-a>" "<dir-b>" ...
  ```
  Cross-platform (iTerm2 / Terminal.app / Windows Terminal / gnome-terminal /
  konsole), degrades to printing the commands when tabs can't be scripted.
  On macOS Terminal.app, real tabs need Accessibility permission; without it
  new windows open instead. Override the per-tab command with
  `EXOSUIT_WORKTREE_LAUNCH_CMD`, or set `EXOSUIT_WORKTREE_TABS=0` to print
  `cd` hints only.
- **No:** print one `cd '<dir>' && claude` hint per stream.

**7. Report.** Print the final `git worktree list` and the working agreement:

```markdown
### Streams Ready

| Stream | Branch | Story |
|--------|--------|-------|
| [dir]  | [branch] | [story or "-"] |

**In each stream:** run `/story-cycle <story-id>` as normal.
**Publish finished work:** `/merge-up` (merges the stream into `<base>`).
**Pick up others' published work:** `/merge-down`.
**When the sprint ends:** `/sprint-end` on `<base>` verifies every stream is
merged and cleans up the worktrees.

Notes: streams share one git object store — a fetch in any stream updates
remote refs for all. Dependency directories (node_modules, .venv, vendor,
target) are not copied; install per stream if needed. Watch for port
collisions if you run more than one dev server.
```

### Cleanup — Remove Finished Streams

If `$ARGUMENTS` contains "cleanup":

1. List all worktrees: `git worktree list --porcelain`
2. For each worktree except the main one:
   - Resolve its parent: `git config branch.<branch>.exosuitParent` (fall back
     to the default branch if unset)
   - Check the branch is fully merged into its parent:
     `git rev-list --count <parent>..<branch>` — 0 means merged
   - If merged and the worktree is clean: `git worktree remove <path>`, then
     `git branch -d <branch>` (safe delete only — never `-D`)
   - If not merged: leave it and report ("has unmerged work — run /merge-up
     inside it first, or remove manually if abandoning")
3. Prune stale entries: `git worktree prune`

```markdown
### Stream Cleanup

**Removed:** [list]
**Kept (unmerged work):** [list with commit counts]
**Pruned:** [count of stale entries]
```

## Coordination Between Sessions

When using the `CLAUDE_CODE_TASK_LIST_ID` environment variable, multiple Claude
Code instances can share a task list. Set the same ID across streams to see
shared tasks.

## Rules

- Always create streams from a clean base branch (typically the sprint branch)
- One story per stream — never share a story across streams
- Never create a stream from inside another stream (fan out from one base)
- Publish with `/merge-up`, refresh with `/merge-down` — keep streams short-lived
- Clean up streams after their branches are merged (`cleanup`, or `/sprint-end`
  does it when the sprint ships)
- Parallel work is optional. When stories are dependent or touch the same
  files, one branch worked sequentially is the better tool.
