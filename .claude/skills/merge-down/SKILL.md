---
name: merge-down
version: 1.0.0
description: Use when the user is inside a parallel stream (worktree branch) and wants to bring that branch up to date with the LATEST of its parent branch — typically after one or more sibling streams have merged their work up into the parent (via /merge-up). Pulls the parent's accumulated commits down into the current branch with a true merge. Inverse of /merge-up; the parent is recorded by /parallel-work in git config (branch.<name>.exosuitParent). Read-only on the parent — safe to run while the parent worktree is busy.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
argument-hint: ""
---
______________________________________________________________________

## merge-down

Bring the **current stream's branch** up to date with the parent it was created
from. Use it after a round of `/merge-up`s have landed sibling streams' work on
the parent: each sibling still only has its OWN commits, so run this in each
stream to integrate everyone else's merged work.

This is the complement of `/merge-up`:

- `/merge-up` — merge THIS branch **into** the parent (publish your work upward).
- `/merge-down` — merge the parent **into** this branch (pull everyone's work downward).

Because all worktrees of a repository share one object store and one set of
branch refs, the parent ref already reflects every local `/merge-up` — no
network fetch is needed for local merges. A fetch is only relevant if merges
were *pushed* from another machine (Step 3 handles that optionally). This skill
never writes to the parent's working tree, so it is safe to run even while the
parent worktree is in use.

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
    `sprint-3`) and verify it exists: `git show-ref --verify --quiet refs/heads/<cand>`.
  - If still unresolved or ambiguous, ASK the user which branch is the parent.
- If `P == B` or `P` doesn't exist, STOP and report.

### Step 2 — Pre-flight cleanliness (current worktree only)

```bash
git status --porcelain            # current worktree — must be empty
```
- If dirty, STOP: merging the parent in could collide with uncommitted work. Tell
  the user to commit or `git stash` first, then re-run.
- Unlike `/merge-up`, the parent worktree does **not** need to be clean — this skill
  only reads the parent branch ref; it never commits into the parent's working tree.

### Step 3 — Optionally refresh the parent from origin

Only needed if parent commits were **pushed from elsewhere** (local `/merge-up`s
already updated the shared parent ref). Best-effort; skip silently if there is no
remote.

```bash
git fetch origin "$P" 2>/dev/null || true
# Is origin/P ahead of local P?
git rev-list --left-right --count "$P...origin/$P" 2>/dev/null || true
```
- If `origin/$P` is ahead of local `$P` (right-count > 0), the canonical latest is
  on the remote. Note: local `$P` is usually checked out in the primary worktree, so
  it cannot be fast-forwarded from here. In that case ASK the user whether to merge
  `origin/$P` instead of local `$P` in Step 4 (substitute the ref). For the common
  all-local workflow, local `$P` already holds every merged sibling — proceed with it.

### Step 4 — Merge the parent into the current branch (true merge)

```bash
git merge "$P"          # or origin/$P if Step 3 selected it
```
- **"Already up to date."** → the current branch already contains everything on the
  parent. Report and SKIP to Step 5.
- **Fast-forward** when the current branch has no commits of its own ahead of `$P`.
- **On conflict** (the parent's merged work overlaps this branch's work): do NOT
  auto-abort — the user usually wants to integrate. STOP and:
  - Show the conflicting files: `git diff --name-only --diff-filter=U`.
  - Offer two paths: (a) help resolve the conflicts now, then
    `git add <files> && git commit` to complete the merge; or (b) back out with
    `git merge --abort` to return to the pre-merge state.
  - Do not leave the worktree half-merged without telling the user which state it's in.
- On success, show `git log --oneline -5`.

### Step 5 — Report

```bash
echo "$B now contains $P:"; git log --oneline -5
git status --short
git rev-list --left-right --count "$P...$B"   # left = parent-only (should be 0), right = this branch ahead
```
Summarize: the current branch is now up to date with `$P` (it contains every
sibling's merged work), and is ready for continued work or a later `/merge-up`
(whose Step 5 sync stays a clean fast-forward).

### Notes

- True merge by design, matching `/merge-up`, so history is preserved and a later
  `/merge-up` of this branch fast-forwards cleanly.
- Typical cadence: run all the `/merge-up`s for the round first, then run
  `/merge-down` in each still-active stream to redistribute the integrated parent
  to every branch.
- Read-only on the parent: this skill never moves the parent's branch tip and never
  touches the parent worktree's working files — only the current branch advances.
