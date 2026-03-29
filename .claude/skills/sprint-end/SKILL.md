---
name: sprint-end
version: 2.11.0
description: Use when the user wants to ship a sprint's work to main via PR.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
references: [references/quality-gates.md, references/error-recovery.md, references/documentation-updates.md, references/pr-and-merge.md]
micro-components:
  step-1: [discover-commands, verify-clean-git-state]
  step-2: [quality-gate-sequence]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## sprint-end

```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"sprint-end\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

Ending the sprint. Discovering and wrapping up all work on the current branch.

**Progress tracking:** Create step-level tasks (each blockedBy previous):
1. "Discover sprint state" 2. "Run quality gates" 3. "Update documentation" 4. "Commit docs" 5. "Push and create PR" 6. "Wait for CI" 7. "Merge and clean up"

## Process Flow (authoritative)

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

**Mindset:** Assume there are problems. Your job is to find them.

Present available checks using AskUserQuestion with `multiSelect: true`:

- **All quality gates (Recommended)** — description: "Run all checks below"
- **Run test suite** — description: "Execute all tests, verify zero failures"
- **Test count protection** — description: "Verify test count did not decrease from last sprint"
- **/code-quality** — description: "Complexity, duplication, dead code, naming patterns"
- **/test-validator** — description: "Weakened assertions, deleted tests, tautological tests, TDD compliance"
- **/security-audit** — description: "OWASP top 10, secrets, injection, auth issues, CWE checklist"
- **/architecture-check** — description: "Module boundaries, dependency direction, coupling, architectural drift"
- **Independent verification** — description: "Dispatch integration-tester agent to independently run tests and verify acceptance criteria (recommended)"
- **Ground rules compliance** — description: "Check against GROUND_RULES.md principles"
- **UAT coverage check** — description: "Check UAT test case pass/fail summary (advisory, does not block)"
- **Skip all quality gates** — description: "Skip all gates (not recommended)"

Dispatch quality agent **skills** as parallel Task agents. Read `references/quality-gates.md` for detailed checks (tests, test protection, quality agents with scope-based scaling, recovery). For error recovery, consult `references/error-recovery.md` — search for `## Step 2`.

**Exception — integration-tester:** If selected, dispatch the `integration-tester` native agent (`.claude/agents/integration-tester.md`) alongside skills. Include: test/lint/typecheck commands, all completed stories' AC, and `git diff --name-only $DEFAULT_BRANCH...HEAD`.

<IF condition="docs/reference/GROUND_RULES.md exists and has principles defined">
**Ground rules compliance:** Verify sprint changes don't introduce untracked violations. Record results in sprint spec `## Outcome` → **Ground rules** field.
</IF>

<IF condition="docs/adr/ contains accepted ADR files">
**ADR compliance:** Cross-reference sprint changes against accepted ADRs. Flag contradictions.
</IF>

<HARD-GATE>
Do NOT proceed to documentation updates, PR creation, or merge if ANY quality gate has failed. All gates must pass. "It's probably fine" is not a pass.
</HARD-GATE>

### 2.5 UAT Coverage Check (Advisory)

<IF condition="UAT coverage check was selected AND UAT tracking exists">
Read UAT tracking, count pass/fail/untested, report summary. WARN (do not block) if critical cases are untested or failing.
</IF>

## 3. Documentation Updates

Read `references/documentation-updates.md` for full details: epic file updates, BACKLOG_INDEX.md, sprint spec metrics, progress.md metrics computation, CLAUDE.md, project context, architecture doc, SBOM, technical debt register, PRD living document review.

## 3.5–6. Commit, Push, PR, CI, Merge

Read `references/pr-and-merge.md` for full details: documentation commit, PR size check, PR creation with template, CI monitoring, human review handling, squash merge, worktree cleanup.

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
