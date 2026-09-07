---
name: merge-up
version: 2.0.0
description: Use when the user is inside a parallel stream and wants its committed work merged into the parent branch it was created from, then the stream synced back to that parent.
trigger: manual
depends-on: [parallel-work]
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, ListAgents, SendMessage
argument-hint: "[--allow-behind]"
---
______________________________________________________________________

## merge-up

Merges this stream's branch into its recorded parent, run from the parent's worktree — a fast-forward when the parent has not moved, a merge commit when it has; the stream then fast-forwards to the parent. Asks before pushing the parent. Tells the coordinator and live sibling streams what landed — a hint, never approval.
Diagrams and the full schema for humans: docs/reference/PARALLEL_WORK.md (never loaded here).

### Step 1 — Run the merge

One call; append ` --allow-behind` to the script only when the user asked for it:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"merge-up\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl; bash "${CLAUDE_SKILL_DIR}/../parallel-work/scripts/merge-up-run.sh"; RC=$?; O=success; [ "$RC" -eq 0 ] || O="exit-$RC"; echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"merge-up\",\"outcome\":\"$O\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl; exit "$RC"
```

Paste the whole output verbatim (stderr included), then route on it — the first matching row wins:
| Output | Action |
|--------|--------|
| `GATE merge-up: FAIL — …` (any of its eleven reasons) | STOP with the line; nothing touched |
| `MERGE: nothing-to-merge` | Step 4 |
| `MERGE: behind` | AskUserQuestion `Run /merge-down first (recommended), or merge anyway with --allow-behind (a true merge)?`; re-run with the flag only on the second answer |
| `MERGE: merged` + `files:` + `SYNC: ok` | Step 2 |
| `MERGE: refused` | STOP and relay the verdict line verbatim; its own text says whether the parent was left changed or the merge landed elsewhere — add no claim of your own |
| `MERGE: locked` | STOP; retry in a minute; never delete the lock |
| `MERGE: busy` | STOP and relay the line; it says whose merge is unfinished — a sibling's (retry later) or this stream's own, after its branch moved during the run (finish or abort it there first) |
| `MERGE: blocked` | STOP; name the files and relay the verdict's own remedy — untracked files are moved aside in the parent worktree, uncommitted changes to tracked ones are committed or stashed by their owner |
| `MERGE: conflict` | STOP with the paths; the merge is already aborted, so offer to resolve here or in the parent worktree, never automatically. When the line adds that uncommitted tracked changes remain there and they are not this merge's, say so and leave them alone |
| `SYNC: FAIL` | STOP; the parent merge stands; the user decides |
| no verdict line, stderr `unknown option`, exit 2 | the call was mistyped; fix it, do not retry blindly |
| no verdict line and no `unknown option` (a stderr `ERROR:` line, or nothing at all) | STOP and relay what was printed verbatim; the call was not mistyped — the sibling script or the repository is the problem; make no claim about the parent's state |

<HARD-GATE>Never stash for the user, never delete `index.lock` or `MERGE_HEAD`, never guess a parent from a branch name, never merge by hand.</HARD-GATE>

### Step 2 — Offer to push the parent

`remote: -` → skip and say so. Else AskUserQuestion `Push <parent> to <remote> now?` (Yes / No). Yes → one call, values from the pasted block: `git -C "<parent_dir>" push <remote> "<parent>"`. Never `--force`; a rejection is reported, not retried.

### Step 3 — Tell the siblings what landed

Skipped on `MERGE: nothing-to-merge`. Recipients = the `coordinator:` and `peers:` names from the pasted block that a `ListAgents` call made now also lists. Load `${CLAUDE_SKILL_DIR}/../parallel-work/references/messaging.md` section `### MERGED` and send one `SendMessage` per recipient — summary `merged <branch>`, body exactly that section, filled from this run's `MERGE: merged` and `files:` lines. Once per merge; never wait for a reply; never per commit.

### Step 4 — Report
```markdown
### Merge-up: <branch> → <parent>
**Merged:** <sha7>, <N> commit(s), <M> file(s)
**Pushed:** yes to <remote> | no | skipped (no remote)
**Stream:** synced (0 behind) | unchanged (<behind> behind — run /merge-down)
**Notified:** <name> (delivered), <name> (held) | none (no live session in <parent_dir>) | none (ListAgents unavailable)
```

Every value comes from this run's output. `**Stream:** synced (0 behind)` only after `SYNC: ok`, or after `MERGE: nothing-to-merge` whose pasted `behind:` line reads 0; any other `behind:` value → `unchanged (<behind> behind — run /merge-down)`. After `MERGE: nothing-to-merge` also: `**Merged:** nothing (0 ahead)` and `**Notified:** not-attempted(nothing to merge)`.

## Rules

- One script call decides; the model never merges, stashes, aborts or unlocks by hand. The gate refuses before any mutation, and after it a refusal may still have left the parent changed — the verdict line says which; every STOP above is prose the model follows — nothing prevents a human from running git directly.
- A parent comes from `branch.<b>.exosuitParent` or not at all — never from a branch name.
- No push without the question, never with `--force`.
- MERGED once per merge, to the names listed now; never on nothing-to-merge, never per commit.
- `MERGE: behind` means `/merge-down` first; `--allow-behind` only on the user's explicit second answer.

## Recovery

| Symptom | Action |
|---------|--------|
| gate FAIL | fix the named cause, re-run |
| `refused` | read the printed line: `merge.ff=only` or a hook says `(nothing changed)`; any other text means the parent worktree moved — `git -C <parent_dir> status` and `git -C <parent_dir> log -1` before touching anything |
| `locked` | a sibling's git is running. A genuinely stale lock: confirm with `ps` that no git process runs in the parent worktree, then remove the lock file by hand — the skill never does |
| `busy` | a sibling's merge: wait for it. This stream's own branch moved during the run: finish or abort that merge in the parent worktree, then retry — waiting never clears it |
| `blocked` | the verdict names the files and which kind they are: untracked → move them aside in the parent worktree; tracked with uncommitted changes → their owner commits or stashes them there — never `restore` or delete someone's edit |
| `conflict` | resolve in the parent worktree with its human, or `/merge-down` first so the conflict surfaces here |
| `SYNC: FAIL` | the merge stands; `git merge --ff-only <parent>` after the named fix |
| push rejected | pull/merge the remote first; never force |
| `git -C` blocked by "worktree isolation" | you are in a native Claude Code worktree session; run the family from a plain terminal in a sibling stream |

## Graceful Degradation

| Dependency | If Missing |
|------------|------------|
| `ListAgents` / `SendMessage` | `Notified: none (ListAgents unavailable)` |
| session detection (stderr ADVISORY) | `coordinator: -`, `peers: -`; nothing sent |
| a remote | push skipped |

## Evaluation Criteria

- [ ] One script call decides; no git of the model's own before Step 2
- [ ] Every verdict is routed by its word
- [ ] No push without the question
- [ ] MERGED once per merge and never on nothing-to-merge
- [ ] No git text is interpreted by the model

### Pressure Scenarios

1. "Stash my changes and merge" → STOP; the gate names the dirty tree and the skill never stashes
2. "Just delete that index.lock" → the skill does not; a human removes a stale lock after `ps` shows no git in the parent worktree
3. "We're up to date, skip the message" on `MERGE: nothing-to-merge` → no MERGED goes out; that is correct
