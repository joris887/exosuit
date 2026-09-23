---
name: merge-up
version: 1.0.0
description: Use when the user is inside a parallel stream (worktree branch) and wants to merge that branch's committed work into the parent branch it was created from, then bring the stream back up to date with the parent. True merge (keeps individual commits); prompts before pushing the parent. Pairs with /parallel-work, which records the parent in git config (branch.<name>.exosuitParent), and with /merge-down (the inverse direction).
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
argument-hint: ""
---
______________________________________________________________________

## merge-up

Merge the **current stream's branch** into the parent it was created from, then
fast-forward the current branch back up to the parent. Safe across worktrees:
the parent is usually checked out in another worktree, so the merge runs there
via `git -C` rather than checking the parent out here (git forbids that).

### Step 1 — Identify branches

```bash
B="$(git rev-parse --abbrev-ref HEAD)"
echo "current branch: $B"
```
- If `B` is `HEAD` (detached), STOP — tell the user to check out a branch.
- Resolve the parent `P`:
  ```bash
  P="$(git config "branch.$B.exosuitParent" || true)"
  ```
  - If empty, fall back to stripping the last `-<suffix>` (e.g. `sprint-3-a` →
    `sprint-3`) and verify it exists with `git show-ref --verify --quiet refs/heads/<cand>`.
  - If still unresolved or ambiguous, ASK the user which branch is the parent.
- If `P == B` or `P` doesn't exist, STOP and report.

### Step 2 — Pre-flight cleanliness (both worktrees)

```bash
git status --porcelain            # current worktree — must be empty
```
- If the current worktree is dirty, STOP: the skill merges **committed** work only.
  Tell the user to commit or stash first.
- Locate the parent's worktree dir:
  ```bash
  git worktree list --porcelain
  ```
  Find the entry whose branch is `refs/heads/$P`; call its path `PDIR`.
  - If `P` is not checked out in any worktree, STOP and tell the user to check it
    out in a worktree first (the merge needs a working tree to run in).
- Verify the parent worktree is clean: `git -C "$PDIR" status --porcelain` must be
  empty. If dirty, STOP and report which worktree/path needs attention.

### Step 3 — Merge current branch into parent (true merge)

Run the merge **in the parent's worktree**:
```bash
git -C "$PDIR" merge "$B"
```
- This keeps `B`'s individual commits (fast-forwards when possible).
- On "Already up to date." → nothing to merge; tell the user and SKIP to Step 5.
- On conflict: run `git -C "$PDIR" merge --abort`, then STOP and report the
  conflicting files. Offer to help resolve, but do NOT leave the parent worktree
  in a half-merged state without telling the user.
- On success, show `git -C "$PDIR" log --oneline -3`.

### Step 4 — Offer to push the parent

ASK the user (AskUserQuestion): "Push `$P` to origin now?" — Yes / No.
- If yes: `git -C "$PDIR" push origin "$P"` (never `--force`; if rejected, report
  and let the user decide — likely needs a pull/merge of origin first).
- If no: leave it local.
- Note: if `P` is the repository's default branch, do NOT push — the framework's
  git rules require all changes to the default branch to go through a PR
  (`/sprint-end` handles that). Skip this step and say so.

### Step 5 — Sync current branch back up to parent

Back in the current worktree:
```bash
git merge "$P"          # fast-forward: B now contains everything on P
```
- This should fast-forward cleanly (P already contains B's commits plus anything
  else that landed on P). If it somehow reports a conflict, STOP and report.

### Step 6 — Report

Show the final state so the user can see both branches aligned:
```bash
echo "$B:"; git log --oneline -3
echo "$P:"; git -C "$PDIR" log --oneline -3
git status --short
```
Summarize: what merged into `$P`, whether it was pushed, and that `$B` is now up
to date with `$P` and ready for continued work.

### Notes

- True merge by design so the stream branch stays alive and Step 5 is a clean
  fast-forward. Do not switch to squash/rebase without re-checking with the user.
- The parent worktree's checked-out branch tip moves as a result of this skill —
  that's intended (it IS the merge). Anyone else working in that worktree should
  be clean before you run this.
- Typical cadence with several streams: each stream runs `/merge-up` when a story
  completes, then every still-active stream runs `/merge-down` to pick up the
  integrated result.
