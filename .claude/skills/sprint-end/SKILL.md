---
name: sprint-end
version: 2.11.0
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

**Flow cursor:** This skill has a flow contract (`flow.yaml` — see `.claude/skills/FLOW_SPEC.md`). At each node transition, update the cursor (advisory, never blocks):

```bash
sh .claude/hooks/lib/graph-state.sh enter sprint-end <node-id>
```

Node ids are defined in this skill's `flow.yaml` — one per prose section; pass the node whose `doc:` anchor matches the section you are executing. Use `attempt` instead of `enter` when retrying the same node, and `clear sprint-end` at terminal nodes (deletes the cursor-owned state file, or strips the cursor keys from a skill-owned one).

Ending the sprint. Discovering and wrapping up all work on the current branch.

## Profile-Adaptive Behavior

Read the `**Profile:**` line from CLAUDE.md to determine the active project profile.

<IF condition="Profile is lean">
**Lean mode:** Simplified flow:
1. Discover sprint state
2. Run tests (HARD GATE: must pass) — skip quality agent dispatch
3. Commit any pending changes
4. Push and create PR (simplified PR body — summary of changes, test results, files changed)
5. Wait for CI (if configured)
6. Merge and clean up

Skip: Step 2 quality agent dispatch, Step 3 documentation updates (epics, backlog, metrics, context, architecture, PRD review, debt register), ground rules compliance check, ADR compliance check. Tests must still pass — safety is not reduced.
</IF>

<IF condition="Profile is strict">
**Strict mode:** All quality gates mandatory — skip the selection AskUserQuestion and run `/quality-check --all` automatically. PR body MUST include an Audit Trail section: files changed, agents run with verdicts, gates passed/failed, coverage delta. Ground rules compliance and ADR compliance checks are mandatory (if files don't exist, flag as a gap). On sprint completion, write a sprint-level audit entry to `docs/sessions/.audit-log.jsonl`:
```json
{"type":"sprint-audit","sprint":"<N>","profile":"strict","stories_completed":["<ids>"],"agents_run":["<names>"],"gates_passed":true,"coverage_delta":"+N%","ts":"<ISO-8601>"}
```
</IF>

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

**Child stream check (parallel work):** Discover any streams fanned out from this branch by `/parallel-work`:

```bash
# Branches whose recorded parent is the current branch.
# Note: git canonicalizes config keys to lowercase in --get-regexp output.
git config --get-regexp '^branch\..*\.exosuitparent$' 2>/dev/null \
  | awk -v P="$(git branch --show-current)" '$2==P {print $1}' \
  | sed 's/^branch\.//; s/\.exosuitparent$//'
```

For each child branch found, count work not yet merged into this branch:

```bash
git rev-list --count HEAD..<child-branch>
```

- **If any child has unmerged commits:** STOP and report:
  > "Stream `<child>` has [N] commits not merged into this sprint branch. Run `/merge-up` inside its worktree first, or explicitly confirm abandoning that work."
  Proceed only when every child is merged or the user has explicitly abandoned it.
- **If all children are merged (count 0):** note them, with their worktree paths from `git worktree list --porcelain`, for cleanup in step 6.

Analyze: branch name, all commits since branching, all files changed, stories completed (parse from commit messages).

## 1.5. Pre-Ship Smoke Test (Optional)

Check CLAUDE.md Commands for a `dev:` command. If one is configured:

1. Offer: "Before running quality gates, want to do a quick visual check of the app?"
2. If user accepts: run the dev command in background (`run_in_background: true`), show whatever output it produces (URLs, status, CLI output — do NOT assume localhost), let user verify
3. If user finds issues: fix them before proceeding to quality gates
4. If user declines or no dev command exists: skip and proceed to quality gates

This catches visual/UX issues that automated tests don't cover. Advisory, not blocking.

## 2. Quality Gates

**Mindset:** Assume there are problems. Your job is to find them. Your first assessment is almost never "all clear."

<IF condition="Profile is strict">
**Strict mode:** Skip the selection step — run `/quality-check --all` automatically. All gates are mandatory.
</IF>

<IF condition="Profile is lean">
**Lean mode:** Skip quality agent dispatch entirely. Run only the test suite (HARD GATE: must pass). Proceed to step 3.5 after tests pass.
</IF>

<IF condition="Profile is standard OR no profile set">
Present available check levels using AskUserQuestion:

- **Standard quality gates (Recommended)** — description: "Code quality + test validation + security audit"
- **All quality gates** — description: "All 5 quality agents + independent verification"
- **Run test suite only** — description: "Execute all tests, verify zero failures"
- **Test count protection** — description: "Verify test count did not decrease from last sprint"
- **Ground rules compliance** — description: "Check against GROUND_RULES.md principles"
- **UAT coverage check** — description: "Check UAT test case pass/fail summary (advisory, does not block)"
- **Skip all quality gates** — description: "Skip all gates (not recommended)"

If the user deselects any: "Note: skipping gates may allow issues to reach main. All gates recommended for production sprints."
</IF>

### Quality Agent Dispatch

Dispatch quality gates via `/quality-check`:

- **Standard selection:** `/quality-check` (defaults to code + tests + security based on profile)
- **All gates:** `/quality-check --all`
- **Custom:** `/quality-check --code --security` (any combination of flags)

The `/quality-check` skill handles parallel agent dispatch, profile-aware defaults, and unified reporting. See `.claude/skills/quality-check/SKILL.md` for details.

**Do NOT use native agents** (`.claude/agents/code-reviewer.md`, `.claude/agents/security-analyst.md`) for static quality gates — use the skill-based dispatch through `/quality-check`.

**Exception — integration-tester:** For "All quality gates" or strict profile, `/quality-check --all` automatically includes the integration-tester agent.

Run only selected gates. The HARD-GATE still applies: if `/quality-check` returns FAIL, do NOT proceed.

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

### 2.5 UAT Coverage Check (Advisory)

<IF condition="UAT coverage check was selected AND (docs/testing/UAT_COVERAGE.md exists OR docs/testing/uat/ directory exists)">
Read UAT tracking and report:

1. Parse the Dashboard table (or scan directory for test case statuses)
2. Count: total, pass, fail, untested, blocked, partial
3. Identify critical/high priority cases that are ❌ Fail or ⬜ Untested
4. Report:
   ```
   UAT Coverage: X/Y pass | Z untested | W fail
   Critical untested: [list or "none"]
   ```
5. **WARN** (do not block) if critical cases are untested or failing — include warning in PR body
</IF>

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
  - **Collect sprint satisfaction:** Ask the developer to rate LLM output quality this sprint (1–5). Use AskUserQuestion: "Sprint satisfaction (1–5)? 1=significant rework needed, 3=acceptable with corrections, 5=excellent, minimal intervention"
  - **Compute sprint metrics** from git and activity log:
    - **Tasks**: count of ✅ stories
    - **Cycle time**: avg days per story (git log first/last commit dates per story)
    - **Change failure rate**: post-merge fixes / total changes this sprint (count commits with "fix" type after initial implementation)
    - **Test coverage Δ**: coverage change on new/modified code (from CI output or test runner)
    - **Code churn ratio**: run `git log --numstat` to find lines modified within 14 days of creation / total lines (or use `scripts/pm/metrics.sh --churn`)
    - **AI effectiveness**: parse `docs/sessions/.activity-log.jsonl` — compute skill success rate and context reset frequency (or use `scripts/pm/metrics.sh --ai-effectiveness`)
    - **Sprint satisfaction**: from user input above (X/5 format)
  - **Append row to `## Sprint History`**: `| N | [goal] | ✅/❌ | X | X.Xd | X% | +X% | 0.XX | 0.XX | X/5 | #N |`
  - **Update `## Metrics` table**: For each metric row, update the Current column with this sprint's value. Recompute Trend sparklines from the last 6 Sprint History rows (use ▁▂▃▄▅▆▇█ — map values to 8 levels; for lower-is-better metrics like cycle time/CFR/churn, invert so up=improving). Compute Status using BOTH absolute and relative thresholds:
    - **Absolute**: 🟢 if within target, 🟡 if within 120% of target, 🔴 if beyond 120%. For "≥" targets, invert.
    - **Relative**: Also compute % change from the 3-sprint rolling average in Sprint History. If metric worsened >50% from average, set status to at least 🟡 regardless of absolute position. If >100% worse, set to 🔴. Example: CFR at 14% (target ≤15%) is 🟢 by absolute threshold, but if the 3-sprint average was 7%, the 100% increase makes it 🔴.
    - Take the worst status between absolute and relative checks.
  - **Sprint note**: If any metric is 🟡 or 🔴, write a one-sentence explanation of the likely cause. Include Δ3avg context when relative change triggered the status (e.g., "CFR doubled from 3-sprint average despite being within absolute target"). Check for three-sprint trends (3 consecutive sprints in same direction = strong signal requiring action). When code churn ratio is 🟡 or 🔴, run `scripts/pm/metrics.sh --churn` and include the top 3 hotspot files in the note (e.g., "Churn 🟡 — hotspots: src/auth/session.ts (7 changes), src/api/routes.ts (5 changes)").
  - Update `## Next Steps` with post-sprint actions
- **CLAUDE.md**: Update Current Focus if epic status changed
- **Project context** (`docs/context/`): If sprint changes affect architecture, patterns, or tech stack, incrementally update the relevant context files (use `git diff $DEFAULT_BRANCH...HEAD --name-only` to identify affected areas). Update `updated:` timestamps in YAML frontmatter.
- **System patterns** (`docs/context/system-patterns.md`): Review commit messages and story plans from this sprint for pattern-related changes. If any story introduced a new implementation pattern, established a new convention, or changed the error handling/testing approach, update the relevant section. Add new implementation recipes when a repeated entity type was added for the first time (e.g., first API endpoint, first background job). Remove patterns for approaches no longer used.
- **Architecture doc** (`docs/architecture/ARCHITECTURE.md`): If any story in this sprint changed architecture (check the Update Triggers section), verify the doc was updated during story-cycle Phase 4e. If not, update it now and set `Last Verified` date to today.
- **SBOM (informational):** If CycloneDX or Syft tools are available, generate or update `sbom.json` to reflect current dependencies. If no SBOM tool is available, skip — note "SBOM generation: no tool available" in the PR body. This is informational, not blocking.
- **Technical debt register** (`docs/technical-debt.md`):
  - If quality gates (step 2) identified issues logged to the debt register, ensure each item has the full format (category, severity, origin, quantified impact, interest rate, effort, resolution plan)
  - For debt introduced by AI-assisted code this sprint, set `origin: ai-generated`
  - For debt resolved by sprint stories, move items to "Resolved" section with actual effort and sprint reference
  - Update the header: `Active items: X | Resolved this quarter: Y`
  - Record in sprint spec `## Outcome`: **Debt delta**: +N added / -N resolved (net: +/-N). This data feeds into `/retrospective` for trend analysis.

### PRD Living Document Review

If `docs/reference/PRD_SUMMARY.md` exists, review it against sprint learnings:

- **Section 9 (Open questions):** Were any assumptions validated or invalidated this sprint? Update their Status (Assumed → Validated/Invalidated). Were any open questions answered? Update Status (Open → Resolved).
- **Section 5 (Requirements):** Did any requirement's scope change during implementation? If acceptance criteria were added, modified, or found insufficient, note the delta.
- **Section 3 (Success criteria):** Can any criteria now be measured? Note baseline values if available from test output.
- **Scope creep check:** Compare stories delivered against PRD Section 5 requirements. Flag stories that don't trace to any PRD requirement — these may indicate scope creep or legitimate new requirements that the PRD should absorb.

If changes are needed, update PRD_SUMMARY.md and bump the version in the header comment.

### Persona Assumption Update

If `docs/context/personas.md` exists and user-facing stories were delivered this sprint: check the Persona Assumptions table. Were any assumptions validated or invalidated by this sprint's work? Update their Confidence column (`ASSUMED` → `CONFIRMED` or `INVALIDATED`) with a brief note of the evidence. Bump the `updated:` date in frontmatter.

**Skip when:** No user-facing stories were delivered (pure infrastructure/refactoring sprint), or `personas.md` doesn't exist.

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

### PR Size Check

```bash
LINES_CHANGED=$(git diff --stat $DEFAULT_BRANCH...HEAD | tail -1 | grep -oE '[0-9]+ insertion|[0-9]+ deletion' | grep -oE '[0-9]+' | paste -sd+ | bc 2>/dev/null || echo "0")
```

If `LINES_CHANGED` exceeds 400 lines, warn:
> **Large PR detected** ([LINES_CHANGED] lines changed). Research shows PRs in the 200–400 line range have 40% fewer defects, and each additional 100 lines adds ~25 minutes of review time. Consider breaking this into stacked PRs for more effective review.

<IF condition="CODEOWNERS exists or CONTRIBUTORS > 1">
If `LINES_CHANGED` exceeds 200 lines, additionally note:
> For teams, `docs/reference/TEAM_WORKFLOW.md` recommends capping AI-generated PRs at 200 lines. Consider using stacked PRs to break this into reviewable chunks.
</IF>

Offer to proceed as-is or help split the PR.

<IF condition="User wants to split the PR">
**PR Splitting Strategies:**

1. **By story:** Create one PR per completed story. Cherry-pick each story's commits to a new branch:
   ```bash
   git checkout $DEFAULT_BRANCH
   git checkout -b feat/<story-description>
   git cherry-pick <story-commit-hashes>
   git push -u origin feat/<story-description>
   gh pr create --title "<type>(<scope>): <story summary>"
   ```
   Repeat for each story. Each PR should be ≤400 LOC.

2. **By layer:** Split into backend/frontend/infrastructure PRs if changes span layers.

3. **By module:** Split into separate PRs per module or package boundary.

Create split PRs in dependency order so CI passes on each. Reference the sprint spec in each PR for context. See `docs/reference/GIT_WORKFLOW.md` → Stacked PRs for advanced tooling.
</IF>

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

## AI Assistance
- **AI-assisted:** <list components where AI generated or significantly modified code>
- **Human-written:** <list components written or heavily edited by hand, or "N/A">
- **AI review focus:** <specific areas where reviewers should check for AI anti-patterns>

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
2. **Remind reviewers of Layer 4 focus** (see `docs/reference/TEAM_WORKFLOW.md` → Code Review Process):
   - Architecture alignment with documented ADRs
   - Business logic correctness — right problem solved?
   - Intent verification — matches the story spec?
   - AI-specific anti-patterns: phantom deps, code duplication, tautological tests, over-engineering
3. Request reviews if not already requested:
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

**Child stream cleanup (before the merge, while still on the sprint branch):** For each merged child stream noted in step 1:

```bash
git worktree remove <child-worktree-path>     # fails if the worktree is dirty — resolve first
git branch -d <child-branch>                  # safe delete works: the child is merged into this branch
git config --remove-section branch.<child-branch> 2>/dev/null || true
```

This must happen before switching to the default branch — after the squash merge, `git branch -d` would no longer recognize the children as merged. For any stream the user chose to abandon (unmerged commits), leave its branch in place and report it: safe delete will refuse, and force-deleting branches is blocked by the framework's git hooks on purpose. The user can delete it manually once they are certain.

Once CI is green (or local gates passed) and any required reviews are complete:

```bash
gh pr merge --squash --delete-branch
git checkout $DEFAULT_BRANCH
git pull origin $DEFAULT_BRANCH
git worktree prune
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

**Skill metrics:** Emit a completion event:

```bash
echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"sprint-end\",\"outcome\":\"success\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

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
