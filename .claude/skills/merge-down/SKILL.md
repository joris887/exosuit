---
name: merge-down
version: 1.1.0
description: Use when the user is inside a parallel stream and wants the parent branch's newer commits (sibling streams' merged work) pulled into this stream.
trigger: manual
depends-on: [parallel-work]
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
argument-hint: ""
---
______________________________________________________________________

## merge-down

A true merge of the recorded parent into this stream. Read-only on the parent: its ref and its worktree are never written.
Diagrams and the full schema for humans: docs/reference/PARALLEL_WORK.md (never loaded here).

### When to run

After a MERGED message, or a session banner that says `behind`, once the current step is committed · before a `/merge-up` (its runner refuses a stream that is behind) · never on a dirty tree.

### Step 1 — Gate

One call, no event — a run that stops here logs nothing:
```bash
bash "${CLAUDE_SKILL_DIR}/../parallel-work/scripts/worktree-status.sh" --gate merge-down
```

Paste it verbatim. Any `GATE merge-down: FAIL` line → STOP with the line. `behind: 0` → say "already up to date with <parent>" and STOP. The gate measures against the LOCAL parent ref, which already holds every local `/merge-up`. Only from this `behind: 0` stop, and only when the user says the parent was pushed from another machine: `git fetch <remote> "<parent>"` (never by default — a fetch moves `origin/*` for every worktree) and merge `<remote>/<parent>` in Step 2 in place of both `refs/heads/<parent>` revisions; the gate does not compare against it.

### Step 2 — Merge the parent into this stream

One call — the start event in front so both events belong to the mutating step; `;`, not `&&`, so the recount, the sha and the end event run on a conflict too. Both revisions are spelled in full: a tag sharing the parent's name wins a bare name lookup and merges the wrong ref.
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"merge-down\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl; git merge --no-edit "refs/heads/<parent>"; RC=$?; git rev-list --left-right --count "refs/heads/<parent>...HEAD"; git rev-parse --short HEAD; O=success; [ "$RC" -eq 0 ] || O="exit-$RC"; echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"merge-down\",\"outcome\":\"$O\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

- `Already up to date.` → Step 3 with the counts (left = behind, right = ahead).
- Fast-forward or a merge commit → Step 3 with the counts and the sha7 (`Merge branch 'refs/heads/…'` is the expected subject).
- Conflict → do NOT abort. Run `git diff --name-only --diff-filter=U`, then AskUserQuestion `Resolve now (git add … && git commit) or back out (git merge --abort)?`. Always state which state the tree is in; here the counts are the unmerged ones and the sha7 is the pre-merge HEAD, never a merge commit.

### Step 3 — Report
```markdown
### Merge-down: <parent> → <branch>
**Result:** already up to date | fast-forward | merge commit <sha7> | conflict (<n> files)
**Now:** +<ahead> ahead, <behind> behind
**Tree:** clean | merge in progress
```

## Rules

- Gate before merge; a FAIL line stops the skill. The gate refuses before any mutation; every STOP above is prose the model follows — nothing prevents a human from running git directly.
- Never fetch by default; the fetch path only from the `behind: 0` stop, on the user's say-so.
- Never abort a conflicted merge unasked; offer both paths.
- Read-only on the parent: its ref and its worktree are never written; the gate's own reads there (`status`, `rev-parse`) are the only commands that run in it.
- Every report states the tree's state.

## Recovery

| Symptom | Action |
|---------|--------|
| gate FAIL | fix the named cause, re-run |
| own half-merge state (`MERGE_HEAD` in THIS worktree from an earlier run) | finish with `git commit` or `git merge --abort` before re-running |
| own `index.lock` | no git running here → remove it by hand; the skill never does |
| conflict left in place | one of the two paths above: resolve and commit, or `git merge --abort` |
| `behind: 0` but a MERGED arrived | the parent moved on the remote only → the Step 1 fetch path, on the user's say-so |

## Graceful Degradation

| Dependency | If Missing |
|------------|------------|
| a remote | the fetch path is unavailable; the local merge is unaffected |
| session detection (stderr ADVISORY) | irrelevant here — no messages are sent |

## Evaluation Criteria

- [ ] Gate before merge
- [ ] Never fetches by default
- [ ] Never auto-aborts a conflicted merge
- [ ] Tree state always stated
- [ ] Two Bash calls on the happy path

### Pressure Scenarios

1. "Fetch first to be safe" → only on the user's say-so, with the reason stated
2. "Abort it, I'll redo it" → offered as one of two paths, never silently
3. Dirty tree, "merge anyway" → the gate refuses (`GATE merge-down: FAIL`); the skill stops
