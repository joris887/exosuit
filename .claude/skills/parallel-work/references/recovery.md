# parallel-work — recovery

Load this only when a step failed. Every row names the cause and the one action. Never work around a script; never paste git's `hint:` line into a command.

| Symptom | Cause | Action |
|---------|-------|--------|
| `new-worktree.sh` exits 1 with `ERROR:` | branch or dir exists, detached HEAD, missing base, base is itself a stream, bad name | fix the named cause; a half-built stream (git failed after the checks) is removed with `git worktree remove <dir>` then `git branch -d <b>` |
| launcher prints `Couldn't open` | the terminal could not be scripted; on Terminal.app the `note:` gives osascript's reason (a declined "wants to control Terminal" consent reads `-1743`) | run the printed `cd … && claude …` lines by hand |
| a window opened but stays silent (no HELLO, no `Next:`) | the first prompt was not run (trust dialog, a wrapper command, Escape) | type `/parallel-work hello` in that window |
| Session column stays `-` for a window that is open | session detection is unavailable (see the stderr ADVISORY), or the session runs under another config directory | install `jq`, or launch streams from a session with the same `CLAUDE_CONFIG_DIR` |
| the coordinator shows an Approve/Deny dialog for a HELLO/MERGED | the two sessions are in different permission classes | Approve delivers that message; for a dialog-free fleet launch streams with the same flags as the coordinator (`EXOSUIT_WORKTREE_LAUNCH_CMD`); never set `crossSessionInbound` in the repo |
| `SendMessage` fails, or a delivery notice says held/refused | the receiver holds or refuses peer messages | continue; the `Notified:` entry reads `held` / `refused` / `not-listed` |
| `Notified: none (no live session in <parent_dir>)` | no claude runs in the parent's worktree | not a failure; the roster shows it later |
| two rows share a session name | a stale session kept the name | address by the row whose working directory matches |
| `CLEANUP: keep … this is the current worktree` | cleanup was started inside a stream | run it from the base |
| `CLEANUP: keep … a Claude session (<name>) is live there` after BYE | that terminal is still open, or a session exited uncleanly and left a stale registry row | close it and run cleanup again; a stale row clears when `claude agents` next prunes it (start and quit a claude in that directory) |
| `CLEANUP: keep … its upstream <r>/<b> is behind it` | the stream was pushed once (`-u`) and committed again | push it, or `git branch --unset-upstream <b>`, then re-run |
| `CLEANUP: keep … recorded parent '<P>' does not exist locally` | the parent branch was deleted (typically after the sprint's squash merge) | restore it from the reflog or the pull request and re-run, or remove the worktree and delete the branch by hand once certain; safe delete refuses unreachable commits and the skill never forces |
| `CLEANUP: FAILED …` | an unexpected refusal; git's first line is quoted | inspect `git -C <parent-dir> log <parent>..<b>`; delete by hand only when certain; never force |
| `ADVISORY: session detection unavailable (…)` on stderr | no `claude`/`jq`/`python3`, or `claude agents --json` failed | close stream terminals by hand before confirming cleanup; messages are not attempted |
| `git -C …` refused with a "worktree isolation" message | this is a native Claude Code worktree session (`--worktree` / EnterWorktree), which blocks commands against the main checkout | run `/merge-up` and cleanup from a plain terminal in a sibling stream |
| a script prints a verdict you did not expect | the tree is not in the state the skill assumed | paste it; do what it says |
