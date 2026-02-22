# Error Recovery by Step

Step-specific recovery tables for sprint-end. When an error occurs during sprint completion, find the current step and look up the recovery action.

---

## Step 1: Discover Sprint State Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| On main branch | No sprint branch checked out | Inform user — nothing to ship. Check if work was done directly on main (bad practice). |
| No commits ahead of main | Branch exists but no work done | Inform user — nothing to ship. Suggest deleting empty branch. |
| Detached HEAD state | Unusual git state | Run `git branch --show-current`; if empty, ask user which branch to ship |
| Worktree detection fails | Non-standard git setup | Proceed without worktree cleanup; note in output |

## Step 2: Quality Gate Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Tests fail | Code issues or flaky tests | Fix the failing tests. If pre-existing flaky test: inform user, do NOT mask it. |
| Test count decreased vs main | Tests were deleted or renamed | Investigate: were tests intentionally removed? If not, restore them. Requires user approval to proceed with fewer tests. |
| Coverage dropped for touched files | New code lacks tests | Write missing tests before proceeding. Do NOT reduce coverage thresholds. |
| Quality agent reports critical issue | Real problem found | Fix before proceeding — do NOT defer critical findings to next sprint. |
| Quality agent unavailable | Sub-agents not supported | Run quality checks manually in main context. Do NOT skip quality gates. |
| Lint/typecheck fails | Style or type violations | Run auto-fix; manual fix for remaining issues. All violations must be resolved. |

## Step 3: Documentation Update Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Epic file not found | Backlog structure missing or wrong path | Create the epic file, or update BACKLOG_INDEX.md with correct path |
| Story ID not found in epic | Story was ad-hoc (not from backlog) | Add the story retroactively to the appropriate epic, or skip backlog update with a note |
| progress.md has merge conflicts | Multiple concurrent sprints edited it | Resolve manually; keep both sets of data |

## Step 4: Push and PR Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Push rejected | Remote has newer commits | `git pull --rebase origin <branch>` then re-push. Re-run quality gates after rebase. |
| `gh` CLI not authenticated | Missing GitHub auth | Ask user to run `gh auth login`; or push manually and create PR via web |
| `gh` CLI not installed | Tool not available | Push with `git push -u origin <branch>`; instruct user to create PR via web |
| PR creation fails | Branch protection or permissions | Show the error; suggest user creates PR manually with the prepared body |

## Step 5: CI Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| CI fails on test | Environment difference from local | Read CI logs; fix the environment-specific issue; push fix; re-check |
| CI fails on lint | Stricter CI lint config | Fix lint issues locally; push; re-check |
| CI timeout | Long-running tests or resource limits | Check if tests can be parallelized; if CI issue, note and proceed with local verification |
| No CI configured | Project has no CI pipeline | Local quality gates (step 2) serve as verification; proceed to merge |

## Step 6: Merge and Cleanup Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Merge conflicts | Main diverged since branch creation | Resolve conflicts; re-run quality gates; push; re-merge |
| Squash merge fails | GitHub branch protection or review requirements | Check PR status; ensure required reviews are complete; ask user if needed |
| Worktree removal fails | Files still open or processes running | Warn user to close editors/terminals in worktree; retry removal |
| Branch deletion fails | Branch protection rules | Delete manually via GitHub web UI; note in output |
