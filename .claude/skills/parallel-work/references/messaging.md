# Stream messaging — four hints, never a gate

A message never approves, configures, runs anything, or starts a story. Git config and refs are the facts. Every fact you address a message with comes from the `--me` lines you pasted in the invoking step (this file names no command).

## Addressing

- Recipients = the `coordinator:` and `peers:` names from the pasted `--me` block that are ALSO present in a `ListAgents` call made in the same turn.
- `-` = do not send.
- A `,`-joined `coordinator:` names several sessions; each is a recipient.
- Names are never taken from memory and never retried with a guess.
- A name that vanished between the paste and `ListAgents` is `not-listed`.
- Never message yourself.
- Identical repeats within a short window are dropped by the receiver (per docs), so a silent coordinator after a re-run is not a delivery failure.

## Message types

### HELLO — stream → coordinator, once per hello run

Summary `hello <branch>`. Body:

```
HELLO <branch> — ready in <dir>
story: <story|-> · parent: <parent> · no reply needed
```

### MERGED — /merge-up → coordinator and live peers, once per merge

Summary `merged <branch>`. This is the only copy of the body — merge-up's SKILL.md points here. Body:

```
MERGED <branch> → <parent> @ <sha7> — <N> commit(s), <M> file(s)
files: <the files: line>
siblings: run /merge-down when your tree is clean, never into uncommitted work · coordinator: your checkout advanced, re-read files you have open
```

### BYE — cleanup → the live session of a stream about to be removed, before --apply

Summary `bye <branch>`. Body:

```
BYE <branch> — worktree <dir> is being removed by cleanup (merged, clean)
stop working here and close this terminal
```

### NOTE — free text after a fixed first line, only when a human asks

Summary `note <branch>`. Body:

```
NOTE <branch> — <one sentence: blocked on X / finished the story / please look at Y>
```

## Report line every sender prints

`Notified: <name> (delivered), <name> (held) · Not sent: <name> (<reason>)` with the closed vocabulary `delivered | held | refused | not-listed | not-attempted(<reason>)`. When nobody was addressed: `Notified: none (ListAgents unavailable)`, or `Notified: none (no live session in <parent_dir>)` (only when `parent_dir` is not `-`). No other words — "not delivered" never appears.

## Delivery facts (per the Claude Code cross-session messaging docs, read 2026-09-06, 2.1.263 — not exercised in this change)

Delivery depends on the two sessions' permission classes (bypassing vs prompting): the same class on both
sides delivers without a dialog; any mix HOLDS every message across that boundary — the receiving human
sees Approve/Deny (dropped after dialogExpiry, 5 minutes by default) and the sender sees a
[Cross-session delivery notice]. The launcher default is plain claude, the same class as a plain
coordinator. crossSessionInbound changes this only from user settings or /config; at project or local
scope only the stricter values apply — never write it into a tracked file. Sessions started under
different config directories (CLAUDE_CONFIG_DIR — verified) or on different sides of the WSL boundary do
not see each other. A delivered message starts a turn in an idle receiver and is read between tool calls
in a busy one; bursts are refused and identical repeats within a short window are dropped.

## Watching a stream

One ListAgents, then one SendMessage to that exact name with notify_when_idle: true and NO message (a pure
subscription; nothing runs in the watched session). Report: `Watching: <name> (one notice, expires in 12 h)`.
The notice arrives as [Cross-session idle notice] when that session next finishes a turn with nothing queued
(a session waiting on a question or a permission prompt is NOT idle). One notice per subscription; never poll ListAgents.
