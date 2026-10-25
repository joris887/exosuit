---
name: lanes
version: 1.1.0
description: Parallel work inside tmux, for a server you reach over SSH (also from a phone). Each lane is a branch off the sprint branch, a git worktree, and a tmux window with Claude Code already started on its story. Shows lane status and cleans up merged lanes. Lanes merge with /merge-down and /merge-up, like /parallel-work's streams.
trigger: manual
depends-on: [parallel-work]
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[start <a:STORY b:STORY ...> | status | cleanup]"
---
______________________________________________________________________

## lanes

`/parallel-work` opens each stream in a new tab of a desktop terminal. Over SSH
there is no desktop: `/lanes` opens each stream as a window in the tmux session
you are in. The session keeps running when the connection drops, so the lanes
keep working while your laptop sleeps or your phone locks.

```
main ──► sprint-3 (main checkout, the window you started from)
            ├─ sprint-3-a   ~/lanes/<repo>/a   tmux window "a"
            ├─ sprint-3-b   ~/lanes/<repo>/b   tmux window "b"
            └─ ... one letter per lane
```

- Lanes are made by `/parallel-work`'s `new-worktree.sh`: `.env`, `.env.local`,
  `.claude/settings.local.json`, `CLAUDE.local.md` and `.mcp.json` are copied in,
  and the parent is recorded, so `/merge-up`, `/merge-down` and `/sprint-end`
  treat a lane as a stream.
- The worktrees live outside the repository (`~/lanes/<repo>/`), so a Docker
  build context or a dirty-tree check in the main checkout never sees them.
- All worktrees share one object store: merges between a lane and its parent are
  local, with no push or fetch.

## Commands

Run the scripts directly; there is no need to read them first. Paths are relative
to the skills folder (`${CLAUDE_PLUGIN_ROOT:-.claude}/skills`).

### `start <letter>[:<story-id>] ...`

Run from the main checkout, on the sprint branch, with a clean tree. Check the
plan first, as `/parallel-work` start does in its step 2: stories that depend on
each other or touch the same files go in the same lane, one after the other.

```bash
bash "${CLAUDE_PLUGIN_ROOT:-.claude}/skills/lanes/scripts/lane-start.sh" a:E03-S03 b:E03-S04 c
```

Per lane: branch `<sprint>-<letter>`, worktree `~/lanes/<repo>/<letter>`, and a
window named after the letter that installs dependencies (from the lockfile:
pnpm, npm, yarn, bun, uv or poetry) and then runs `claude '/story-cycle <story>'`,
or plain `claude` without a story. Outside tmux the windows go into a session
named after the repo; the script prints how to attach to it. It also binds
Alt+<number> to jump to a window, and prints each lane's window number and key.

Settings, as environment variables:

| Variable | Default | Use |
|---|---|---|
| `EXOSUIT_LANES_DIR` | `~/lanes/<repo>` | where the worktrees go |
| `EXOSUIT_LANE_SETUP` | from the lockfile | first command in each lane; empty skips it |
| `EXOSUIT_LANE_CLAUDE` | `claude` | how Claude Code starts, for example with `--model` |
| `EXOSUIT_LANE_SESSION` | the current session | which tmux session gets the windows |
| `EXOSUIT_LANE_ALT_KEYS` | on | `0` leaves Alt+<number> unbound |

The first start in a new folder shows Claude Code's folder-trust question once:
press Enter in that window and the story starts.

### `status` (default)

```bash
bash "${CLAUDE_PLUGIN_ROOT:-.claude}/skills/lanes/scripts/lane-status.sh"
```

Tell the user what it means: BEHIND above 0, that lane should run `/merge-down`;
AHEAD above 0, work not merged up yet; DIRTY above 0, work in progress; WINDOW no,
the lane's window was closed (open one with `tmux new-window -c <worktree>`).
Status also binds the Alt keys again, for a tmux server that restarted.

### `cleanup`

```bash
bash "${CLAUDE_PLUGIN_ROOT:-.claude}/skills/lanes/scripts/lane-cleanup.sh"
```

Run from the main checkout. For every lane fully merged into its parent: removes
the worktree, deletes the branch (`git branch -d` only) and closes its window.
Lanes with uncommitted or unmerged work are kept and listed. Also closes windows
whose lane folder is gone. **Tell the user first:** closing a window ends the
Claude Code session in it.

## Lane lifecycle

1. `/sprint-start` on the sprint branch, then `/lanes start a:<story> b:<story>`.
2. Each window runs `/story-cycle` on its story.
3. Story done in a lane: `/merge-down` first, so conflicts are solved in the lane
   that knows the story; then the project's test and typecheck commands (from
   `CLAUDE.md`); then `/merge-up`, which is now a fast-forward of the parent.
   Never merge red work up.
4. The other lanes run `/merge-down` when `status` shows them behind.
5. Next story in a lane: type `/story-cycle <story>` in that lane's Claude Code.
6. All lanes merged: `/lanes cleanup`, then `/sprint-end` from the main checkout.

## Rules

- Two or three lanes. Every lane runs its own Claude Code, and they share one
  usage limit.
- Only the main checkout deploys, migrates a shared database or touches a live
  service. Lanes run unit tests and the typecheck.
- One lane at a time owns database migrations. A second migration waits for that
  lane's `/merge-up`, then `/merge-down`, so migration numbers do not collide.
- A dev server in a lane gets its own port, never one a running service uses.
- Create lanes from the sprint branch, never from another lane.
- Keep lanes short: merge up after every story, clean up when the lane's scope
  is done.

## Moving between lanes in tmux

| Keys | What it does |
|---|---|
| `Alt+1` to `Alt+9` | go straight to that window, without Ctrl-b. In Termius: tap Alt, then the number |
| `Alt+0` | back to the window you were in before |
| `Ctrl-b w` | list of windows to pick from |
| `Ctrl-b <number>` | go to that window; the status bar shows each number and name |
| `Ctrl-b n` / `Ctrl-b p` | next / previous window |
| `Ctrl-b d` | leave tmux; every lane keeps running |

The Alt keys are bound by `start` and `status` (`scripts/lane-keys.sh`) on the
running tmux server, for every session, until the server stops. A key the user
bound already is left as it is. With tmux's defaults the first window is 0, so
lanes a, b, c sit on windows 1, 2, 3 and Alt+1, Alt+2, Alt+3 reach them. In a
Mac terminal the Option key must send Meta: iTerm2, Profiles, Keys, Left Option
key: Esc+; Terminal.app, Profiles, Keyboard, Use Option as Meta key.

`status` from the window you started the lanes from shows every lane without
visiting them.
