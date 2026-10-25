---
name: wrap-up
version: 1.0.0
description: Use when the user is about to leave a session (closing the laptop, locking the phone, "wrap up", "I'm off"). First checks whether anything could be lost; when nothing can, says "you're all set to leave" and does nothing else. Otherwise commits, pushes and opens a PR, and only with the user's yes merges and deploys.
trigger: manual
depends-on: []
references: []
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
argument-hint: ""
---
______________________________________________________________________

## wrap-up

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"wrap-up\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

"All set to leave" means: nothing uncommitted in this worktree, and every branch
that is not a lane on a remote. Most of all on a server you reach from a phone,
where work left uncommitted is easy to forget. Deploying is an optional last step.

## Step 1: Can anything be lost? (always first)

```bash
bash "${CLAUDE_PLUGIN_ROOT:-.claude}/skills/wrap-up/scripts/wrap-up-check.sh"
gh pr view --json number,url,state 2>/dev/null || true
```

The script changes nothing. Its last line is the verdict:

- `VERDICT all-set`: **stop here** and report exactly:
  ```
  ✅ You're all set to leave.
  Working tree clean, nothing unpushed.
  ```
  Add one line per note the script printed (an open PR for this branch, `LANE`,
  `ELSEWHERE`, `GONE`, `STASH`), in plain words. Run none of the steps below.
- `VERDICT to-save`: go on to Step 2.

What each line means:

| Line | Meaning |
|---|---|
| `UNCOMMITTED` | changes in this worktree that no commit holds |
| `UNPUSHED` | a branch with commits no remote has |
| `DETACHED` | commits on no branch at all |
| `NO-REMOTE` | the repository cannot be pushed anywhere |
| `LANE` | a lane or stream; it merges into its parent locally with `/merge-up` |
| `ELSEWHERE` | another worktree with uncommitted work; its own session commits there |
| `GONE` | the branch's remote branch was deleted, usually after a merge |
| `STASH` | stashed changes, kept on this machine only |

## Step 2: Save the work

Only in this worktree. Never commit in another worktree: a lane's Claude Code
may be working there.

1. **On the default branch or a detached HEAD:** move onto a new branch first,
   named `<type>/<description>` from the diff (git rules): `git switch -c <name>`.
   Never commit on the default branch.
2. **Commit** what is uncommitted: a Conventional Commit that sums up the diff.
   Show the message, then `git add -A && git commit -m "<message>"`.
3. **Push**, unless this is a lane or stream branch (`git config
   branch.<name>.exosuitParent` is set): those merge up locally, so say
   "committed in the lane; run `/merge-up` when the story is done".
   ```bash
   git push -u origin "$(git branch --show-current)"
   ```
   Never `--force`. A rejected push: stop and report it.
4. **A PR:** when the branch is not the sprint branch, not a lane and has none,
   ask whether to open one (`gh pr create --fill`; ask for the base when it is not
   the default branch).
5. **Other `UNPUSHED` branches:** list them and ask before pushing each one.
6. **No remote** (`NO-REMOTE`): say so; nothing can be pushed until one is added.

Run the check again and report:
```
✅ Your work is safe: committed and pushed on <branch> (PR #<n>).
```

## Step 3: Ship it now? (optional)

Ask: "Merge and deploy now?" On no, stop: the PR waits.

On yes:
- A sprint branch is shipped by `/sprint-end`, with its gates. Say so and stop.
- Otherwise wait for CI, then squash-merge:
  ```bash
  gh pr checks --watch
  gh pr merge --squash --delete-branch
  ```
  Failing CI: stop, nothing is merged; the work is safe on its branch.
- Deploy with `/deploy`, or the deploy command the project's `CLAUDE.md` names,
  then its health check. A project with no deploy: report the merge and stop.
- A database migration in the diff: say before the merge that the deploy applies
  it and that it does not roll back.

## Report

```
## Wrap-up
- Work: committed and pushed on <branch> (PR #<n>) | already safe
- Shipped: merged and deployed, health ok | not shipped, PR #<n> open
- Notes: <LANE / ELSEWHERE / GONE / STASH lines, in plain words>

✅ You're all set to leave.
```

```bash
echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"wrap-up\",\"outcome\":\"success\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

## Rules

- Step 1 always runs first, and an `all-set` verdict ends the skill.
- Never commit on the default branch, never force-push, never merge without the
  user's yes, never merge failing CI.
- Never commit, stash or reset in another worktree.
- For notes on what was done and what is next, `/handoff` writes the session file;
  `/wrap-up` only makes sure nothing is lost.
