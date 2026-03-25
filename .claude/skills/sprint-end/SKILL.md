---
name: sprint-end
version: 2.10.0
description: Use when the user wants to ship a sprint's work to main via PR.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
references: [references/quality-gates.md, references/error-recovery.md]
micro-components:
  step-1: [discover-commands, verify-clean-git-state]
  step-2: [quality-gate-sequence]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## sprint-end

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"sprint-end\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

Ending the sprint. Discovering and wrapping up all work on the current branch.

**Progress tracking:** Create step-level tasks:

1. "Discover sprint state" — activeForm: "Discovering sprint state..."
2. "Run quality gates" — activeForm: "Running quality gates..." — blockedBy: [1]
3. "Update documentation" — activeForm: "Updating docs..." — blockedBy: [2]
4. "Commit documentation artifacts" — activeForm: "Committing docs..." — blockedBy: [3]
5. "Push and create PR" — activeForm: "Creating PR..." — blockedBy: [4]
6. "Wait for CI" — activeForm: "Waiting for CI..." — blockedBy: [5]
7. "Merge and clean up" — activeForm: "Merging to main..." — blockedBy: [6]

At each step boundary, mark current task completed and next task in_progress.

## Process Flow (authoritative — prose below is supporting detail)

```
START → 1. Discover Sprint State (from git, no assumptions)
  → [On main or no commits?] → STOP (nothing to ship)
  → 2. Quality Gates (tests, test protection, quality agents)
    → [All gates pass?]
      → NO: Fix issues → re-run gates
      → YES: 3. Documentation Updates (epics, backlog, progress)
        → 3.5. Commit Documentation Artifacts
          → 4. Push and Create PR
            → 5. Wait for CI
              → [CI green?]
                → NO: Fix → push → re-check
                → YES: 6. Merge and Clean Up (squash, delete branch, worktree)
                  → 7. Sprint Complete Summary → DONE
```

## Failure State Persistence

At step boundaries, write `docs/sessions/.failure-state.md` with YAML frontmatter so the Stop hook and `/continue` can programmatically detect incomplete workflows.

**At workflow start** (Step 1 entry):

```yaml
---
status: active
skill: sprint-end
phase: "1"
phase_name: "Discover Sprint State"
started_at: "[ISO-8601 timestamp from date -u +%Y-%m-%dT%H:%M:%SZ]"
story: "[branch name or sprint identifier]"
branch: "[from git branch --show-current]"
next_action: "Discover sprint state from git"
files_modified: []
---

## Context
[Free-form notes — stories in sprint, quality gate status, PR state]
```

**At each step transition:** Update the frontmatter fields: `phase`, `phase_name`, `next_action`, and append to `files_modified`. Update the Context section with current progress.

**On successful completion (Step 7 — Sprint Complete):** Delete `.failure-state.md` — clean state means no failure to recover from.

## 1. Discover Sprint State

No assumptions about previous context. Discover everything from git.

**Check story completion status:** Read `docs/progress.md` for the current story status. If it shows a phase earlier than "DONE" (e.g., "Phase 3 — tests pass, self-review pending"), the last story was only partially completed. Factor this into quality gates — run the missing steps as part of sprint-end rather than flagging them as new issues.

Read the **Default branch** from CLAUDE.md's Git Workflow section. If not set, detect at runtime:

```bash
DEFAULT_BRANCH=$(grep -oP '^\- \*\*Default branch:\*\* \K\S+' CLAUDE.md 2>/dev/null)
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
fi
if [ -z "$DEFAULT_BRANCH" ]; then
    for branch in main master develop; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then DEFAULT_BRANCH="$branch"; break; fi
    done
fi
```

Discover from git (using the detected default branch):

```bash
git branch --show-current
git log $DEFAULT_BRANCH..HEAD --oneline
git diff --stat $DEFAULT_BRANCH...HEAD
git diff --name-only $DEFAULT_BRANCH...HEAD
```

**If on the default branch:** There is no sprint to end. Inform user and stop.

**If no commits ahead of the default branch:** Nothing to ship. Inform user and stop.

**If in a worktree:** Detect with `git rev-parse --git-common-dir`. Note the worktree path for cleanup in step 6.

Analyze: branch name, all commits since branching, all files changed, stories completed (parse from commit messages).

## 2. Quality Gates

**Mindset:** Assume there are problems. Your job is to find them. Your first assessment is almost never "all clear."

Before running gates, present available checks using AskUserQuestion with `multiSelect: true`:

- **All quality gates (Recommended)** — description: "Run all checks below"
- **Run test suite** — description: "Execute all tests, verify zero failures"
- **Test count protection** — description: "Verify test count did not decrease from last sprint"
- **/code-quality** — description: "Complexity, duplication, dead code, naming patterns"
- **/test-validator** — description: "Weakened assertions, deleted tests, tautological tests, TDD compliance"
- **/security-audit** — description: "OWASP top 10, secrets, injection, auth issues, CWE checklist"
- **/architecture-check** — description: "Module boundaries, dependency direction, coupling, architectural drift"
- **Ground rules compliance** — description: "Check against GROUND_RULES.md principles"
- **Skip all quality gates** — description: "Skip all gates (not recommended)"

If "All quality gates" is selected, run all individual gates. If the user deselects any: "Note: skipping gates may allow issues to reach main. All gates recommended for production sprints."

### Quality Agent Dispatch

Dispatch quality agent **skills** (not native agents) as parallel Task agents using the Task tool with `subagent_type: "general-purpose"`. Each skill has its own methodology, scoring, and AI-specific anti-pattern checks.

**Skills to dispatch** (based on user selection above):
- `/code-quality` — code complexity, duplication, dead code, naming
- `/test-validator` — weakened assertions, deleted tests, tautological tests
- `/security-audit` — OWASP top 10, secrets, injection, auth issues
- `/architecture-check` — module boundaries, dependency direction, coupling

**Do NOT use native agents** (`.claude/agents/code-reviewer.md`, `.claude/agents/security-analyst.md`) for quality gates — they use persona-driven review methodology, not the structured quality checklists that the skills provide.

Run only selected gates. The HARD-GATE still applies: if any selected gate fails, do NOT proceed.

Read `references/quality-gates.md` for detailed checks (tests, test protection, quality agents with scope-based scaling, recovery). For error recovery during this step, consult `references/error-recovery.md` — search for `## Step 2`.

<IF condition="docs/reference/GROUND_RULES.md exists and has principles defined">
**Ground rules compliance:** Verify sprint changes don't introduce untracked ground rules violations. Check commit diffs against MUST principles. Any violations must have been documented in story plans with justification.

**Compliance ledger:** Record results in the sprint spec's `## Outcome` → **Ground rules** field (e.g., "5/5 checked, Clean" or "5/5 checked, 1 violation: [description]"). This data is available to `/retrospective` for longitudinal compliance analysis.
</IF>

<IF condition="docs/adr/ contains accepted ADR files">
**ADR compliance:** Cross-reference sprint changes against accepted ADRs. Check that no new code contradicts an accepted ADR's decision. If a contradiction is found, flag it — the team must either revert the change or create a new ADR that supersedes the old one through proper process.
</IF>

<HARD-GATE>
Do NOT proceed to documentation updates, PR creation, or merge if ANY quality gate has failed. All gates must pass. "It's probably fine" is not a pass.
</HARD-GATE>

## 3. Documentation Updates

Based on what was done in the sprint, update relevant documentation:

- **Epic file** (`docs/reference/backlog/E##-*.md`):
  - In the story checklist: change `- [ ] ID — Title (P#, in-progress)` → `- [x] ID — Title (P#, done)`
  - In story detail sections: update `**Status:** done`
  - Legacy format: mark as `[DONE]` if epic uses old markers
  - Emit story lifecycle event for each completed story:
    ```bash
    echo "{\"type\":\"story\",\"event\":\"status-change\",\"id\":\"<story-id>\",\"from\":\"review\",\"to\":\"done\",\"story_type\":\"<type>\",\"size\":\"<size>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
    ```
- **BACKLOG_INDEX.md**: Update story counts per priority group. Update the Backlog Health section: recalculate Definition of Ready %, check for zombie stories (any story with `created:` date >2 sprint cycles old still not done)
- **Sprint spec** (`docs/sprints/sprint-N.md`):
  - Update all story statuses to final state (✅ done or ⏭️ carried over)
  - Fill in the `## Outcome` section with metrics:
    - **Goal achieved**: yes/no — did the sprint goal succeed?
    - **Stories completed**: X/Y
    - **Throughput**: X stories (count of ✅)
    - **Cycle time**: average days per completed story (from git log first/last commit per story)
    - **Sprint churn**: % of stories added or removed mid-sprint vs original plan (compare current stories table against the initial commit of the sprint spec: `git show $(git log --oneline --diff-filter=A -- docs/sprints/sprint-N.md | tail -1 | cut -d' ' -f1):docs/sprints/sprint-N.md`)
    - **Tests**: before → after (+delta)
    - **Coverage**: before% → after%
    - **Ground rules**: X/Y checked, Z violations or "Clean"
    - **PR**: #number
    - **Merged**: today's date
- **progress.md**:
  - Update `## Current Sprint` to show completed state
  - Append row to `## Sprint History` table: `| N | [goal summary] | ✅/❌ | X stories | X% | X→Y | X%→Y% | #N |`
  - Update `## Next Steps` with post-sprint actions
- **CLAUDE.md**: Update Current Focus if epic status changed
- **Project context** (`docs/context/`): If sprint changes affect architecture, patterns, or tech stack, incrementally update the relevant context files (use `git diff $DEFAULT_BRANCH...HEAD --name-only` to identify affected areas). Update `updated:` timestamps in YAML frontmatter.
- **Architecture doc** (`docs/architecture/ARCHITECTURE.md`): If any story in this sprint changed architecture (check the Update Triggers section), verify the doc was updated during story-cycle Phase 4e. If not, update it now and set `Last Verified` date to today.

### PRD Living Document Review

If `docs/reference/PRD_SUMMARY.md` exists, review it against sprint learnings:

- **Section 9 (Open questions):** Were any assumptions validated or invalidated this sprint? Update their Status (Assumed → Validated/Invalidated). Were any open questions answered? Update Status (Open → Resolved).
- **Section 5 (Requirements):** Did any requirement's scope change during implementation? If acceptance criteria were added, modified, or found insufficient, note the delta.
- **Section 3 (Success criteria):** Can any criteria now be measured? Note baseline values if available from test output.
- **Scope creep check:** Compare stories delivered against PRD Section 5 requirements. Flag stories that don't trace to any PRD requirement — these may indicate scope creep or legitimate new requirements that the PRD should absorb.

If changes are needed, update PRD_SUMMARY.md and bump the version in the header comment.

## 3.5 Commit Documentation Artifacts

Commit all documentation changes as a separate commit. This ensures documentation is preserved even if the push or PR step fails or is skipped.

```bash
# Check if there are uncommitted documentation changes
if ! git diff --quiet docs/ CLAUDE.md 2>/dev/null || \
   ! git diff --quiet --cached docs/ CLAUDE.md 2>/dev/null || \
   git ls-files --others --exclude-standard docs/ | grep -q .; then
    git add docs/ CLAUDE.md
    git commit -m "docs(sprint): update sprint documentation and session artifacts

Co-Authored-By: Claude <noreply@anthropic.com>"
fi
```

If there are no documentation changes, skip this step gracefully. This commit happens regardless of whether push will be performed.

## 4. Push and Create PR

```bash
git push -u origin $(git branch --show-current)
```

Create PR with GitHub CLI. The repository includes a PR template (`.github/pull_request_template.md`) — fill in its sections rather than providing a raw body:

```bash
gh pr create --title "<type>(<scope>): <summary>" --body "$(cat <<'EOF'
## Type of Change

- [x] <matching type from template>

## Summary
<1-3 sentences summarizing what was done and why>

## Changes
<list of key changes, grouped by area>

## Test Evidence
<paste test output from step 2>

## Quality Gates
- [x] All tests pass
- [x] Test count did not decrease
- [x] Code quality agent reviewed
- [x] Test validator agent reviewed
- [x/n/a] Security audit reviewed
- [x] No hardcoded secrets introduced
- [x] Coding standards followed

## Self-Review Checklist
- [x] I read the diff and it matches the intent
- [x] No debug code or TODOs left behind
- [x] Error handling is appropriate
- [x] New code follows existing patterns
- [x/n/a] Documentation updated where needed

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## 5. Wait for CI

<IF condition="CI is configured (.github/workflows/, .gitlab-ci.yml, etc. detected)">
```bash
gh pr checks --watch
```
If CI fails, diagnose and fix. Commit fixes and push.

**Note:** The framework includes a Claude PR Review workflow (`.github/workflows/claude-pr-review.yml`). If configured with an `ANTHROPIC_API_KEY` secret, it runs automated code review on PRs. Check its status alongside other CI checks.
</IF>
<ELSE>
No CI detected — the local quality gates in step 2 serve as verification. Proceed to merge.
</ELSE>

### Human Review Handling

<IF condition="CODEOWNERS exists or PR requires human reviewers">
After CI passes, check for required human reviewers:

```bash
gh pr view --json reviewRequests,reviews
```

**If human review is required:**
1. List required reviewers from CODEOWNERS or branch protection rules
2. Request reviews if not already requested:
   ```bash
   gh pr edit --add-reviewer <reviewer>
   ```
3. Present to user:
   ```markdown
   **Human review required before merge.**
   - Reviewer(s): [list]
   - Status: [Pending / Approved / Changes Requested]

   Options:
   → Wait for review (recommended)
   → Continue to other work while waiting (`/story-cycle` or `/sprint-start --worktree`)
   ```
4. If "Changes Requested": guide user through addressing feedback, pushing updates, and re-requesting review

**If no human review required:** Proceed to merge.
</IF>

## 6. Merge and Clean Up

Once CI is green (or local gates passed) and any required reviews are complete:

```bash
gh pr merge --squash --delete-branch
git checkout $DEFAULT_BRANCH
git pull origin $DEFAULT_BRANCH
```

**Worktree cleanup** (if running in a worktree detected in step 1):

```bash
WORKTREE_PATH=$(pwd)
cd <main-worktree-path>
git worktree remove "$WORKTREE_PATH"
git worktree prune
```

Inform the user that the worktree has been removed and they should close the Claude Code instance that was using it.

Verify clean state:

```bash
git status
git log --oneline -3
```

## 7. Sprint Complete

```markdown
### Sprint Complete

**Sprint [N]: [goal]**
**Goal achieved:** [yes/no]
**Branch:** `sprint-<number>` (merged and deleted)
**PR:** #<number> (<url>)
**Stories:** [completed]/[total] delivered
**Throughput:** [X] stories | **Churn:** [X]%
**Tests:** [total] passing ([+delta] vs main) | **Coverage:** [X]%

**Carried over:** [count] stories
- [Goal-critical]: [list — these threaten the sprint goal, prioritize in next sprint]
- [Non-critical]: [list — correct prioritization, schedule when ready]

Non-critical carry-over is a positive signal — it means the team correctly prioritized goal-critical work over lower-priority items.

**Main is clean and up to date.**
**Sprint spec:** `docs/sprints/sprint-<number>.md`

**Next Steps:**
→ `/retrospective` — review sprint metrics and process
→ `/sprint-start` — begin the next sprint
→ `/handoff` — if ending the session
```

## Graceful Degradation

| Dependency   | If Missing                                          |
|--------------|-----------------------------------------------------|
| Sub-agents   | Run quality checks manually in the main context     |
| CI pipeline  | Local quality gates (step 2) serve as verification  |
| Test runner  | Warn user, skip test count delta, note in PR body   |
| Linter       | Skip lint check, note in PR body                    |
| Type checker | Skip typecheck, note in PR body                     |
| `gh` CLI     | Push manually, create PR via web UI                 |

## Project State Adaptation

Read CLAUDE.md Commands section before running quality gates (or use the `discover-commands` micro-component from `.claude/prompts/discover-commands.md`):

<IF condition="test command exists in CLAUDE.md Commands">
Run full test suite as part of quality gates.
</IF>
<ELSE>
Skip test gate, note "No test command configured" in PR body.
</ELSE>

<IF condition="build command exists in CLAUDE.md Commands">
Include build verification in quality gates.
</IF>
<ELSE>
Skip build step.
</ELSE>

## Rules

- NEVER merge without CI passing (or local gates if no CI)
- NEVER force push or skip hooks
- NEVER merge without running quality agents
- NEVER merge if test count decreased (without explicit user approval)
- ALWAYS discover state from git — assume no prior context
- ALWAYS update documentation for completed stories
- ALWAYS squash merge to keep main history clean
- ALWAYS clean up worktrees after merge
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
