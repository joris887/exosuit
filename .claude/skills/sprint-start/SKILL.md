---
name: sprint-start
version: 2.8.0
description: Pre-sprint checks, feature branch creation, and sprint planning. Ensures clean state, defines sprint goal and scope, creates sprint spec document.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: "[branch-name] [--worktree]"
---
______________________________________________________________________

## sprint-start

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"sprint-start\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

**Flow cursor:** This skill has a flow contract (`flow.yaml` — see `.claude/skills/FLOW_SPEC.md`). At each node transition, update the cursor (advisory, never blocks):

```bash
sh .claude/hooks/lib/graph-state.sh enter sprint-start <node-id>
```

Node ids are defined in this skill's `flow.yaml` — one per prose section; pass the node whose `doc:` anchor matches the section you are executing. Use `attempt` instead of `enter` when retrying the same node, and `clear sprint-start` at terminal nodes (deletes the cursor-owned state file, or strips the cursor keys from a skill-owned one).

Starting a new sprint.

## Profile-Adaptive Behavior

Read the `**Profile:**` line from CLAUDE.md to determine the active project profile.

<IF condition="Profile is lean">
**Lean mode:** Skip steps 1.5 (Metrics Health Check), 1.6 (Debt Health Check), and step 3 (Sprint Planning ceremony — no sprint spec generation, no story selection, no PRD check). Perform only: 1a-1d (pre-flight checks), step 2 (create feature branch), and update `docs/progress.md` with branch name and sprint number.
</IF>

<IF condition="Profile is strict">
**Strict mode:** All steps mandatory. Metrics and debt checks must produce actionable output (not just "all clear"). Sprint spec generation is required with explicit quality gate plan section.
</IF>

## 1. Pre-flight Checks

Verify the workspace is ready for new work:

### 1a. Check for open PRs

```bash
gh pr list --author @me --state open
```

**If open PRs exist:**

- Check if any are approved → merge them: `gh pr merge --squash --delete-branch`
- If awaiting review → inform user and ask whether to proceed or wait

### 1b. Verify clean working tree

```bash
git status
```

**If uncommitted changes exist:**

- Warn user — they must commit, stash, or discard before proceeding
- Do NOT proceed with dirty working tree

### 1c. Ensure on default branch and up to date

Read the **Default branch** from CLAUDE.md's Git Workflow section. If not set, detect it at runtime:

```bash
# Read from CLAUDE.md first, fall back to detection
DEFAULT_BRANCH=$(grep -oP '^\- \*\*Default branch:\*\* \K\S+' CLAUDE.md 2>/dev/null)
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
fi
if [ -z "$DEFAULT_BRANCH" ]; then
    for branch in main master develop; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            DEFAULT_BRANCH="$branch"
            break
        fi
    done
fi
```

```bash
git checkout $DEFAULT_BRANCH
git pull origin $DEFAULT_BRANCH
```

If the default branch was detected at runtime (not in CLAUDE.md), persist it by updating CLAUDE.md's Git Workflow section.

### 1d. Verify tests pass on default branch

Read CLAUDE.md Commands section to find the project's test command.

- **If test command exists:** Run it. If tests fail on the default branch, stop and alert user — default branch should always be green.
- **If NO test command configured:** Skip this check. Note in output: "No test command configured — consider running /bootstrap to set up."

## 1.5. Metrics Health Check

Read `docs/progress.md` → `## Metrics` table. If the table has data (not all "—"), check for quality signals that should influence sprint planning:

| Metric signal | Planning guidance |
|---|---|
| Cycle time ↑ or 🟡/🔴 | Fewer or smaller stories this sprint |
| Change failure rate 🟡/🔴 | Prioritize quality: include a bugfix or stabilization story |
| Code churn ratio 🟡/🔴 | Include a refactoring story targeting hotspot files (see sprint note for file list) |
| Test coverage Δ declining 3 sprints | Enforce strict TDD compliance for all stories |
| Sprint satisfaction declining 3 sprints | Investigate root cause before adding feature work |
| AI effectiveness declining | Review skill failure patterns; consider simpler story decomposition |

Present findings to the user before story selection in step 3, framed as recommendations not blockers:

> "Sprint metrics check: Code churn ratio is 🟡 (0.14, target ≤0.15). Consider including a refactoring story targeting [hotspot files from sprint note]."

If all metrics are 🟢 with stable trends, or if the Metrics table has no data yet, skip this section silently.

## 1.6. Debt Health Check

<IF condition="docs/technical-debt.md exists and contains active items (not just template comments)">
Scan `docs/technical-debt.md` for debt that should influence sprint planning:

1. **Active counts** — read the header (`Active items: X`). If 0, skip this section.
2. **Sprint candidates** — scan for items matching any of:
   - Severity: Critical (must be addressed this sprint)
   - Interest: Growing (compounding — gets worse each sprint it's deferred)
   - Priority score ≥ 4.5 (high impact-to-effort ratio)
3. **Debt neglect check** — scan the Resolved section for dates. If no items resolved in the last 2 sprints, flag: "No debt resolved in 2+ sprints — debt is accumulating without remediation."

Present findings before story selection in step 3, framed as recommendations:

> "Debt register: [N] active items ([N] critical, [N] growing). Sprint candidates: TD-NNN [title], TD-NNN [title]. Consider including at least 1 debt remediation story."

If Critical items exist, present them as P0 stories alongside backlog stories in the step 3 story table. If Growing items exist, note them as recommended additions.
</IF>

## 2. Create Feature Branch

Determine the next sprint number by reading `docs/progress.md` and finding the highest sprint number, then adding 1.

### Standard Mode (default)

Create a new branch from the default branch:

```bash
git checkout -b sprint-<number>
```

### Worktree Mode (when `--worktree` is in $ARGUMENTS or user requests it)

Create an isolated worktree for parallel development:

```bash
# Create worktree in sibling directory
git worktree add ../$(basename $(pwd))-sprint-<number> -b sprint-<number>
```

Inform the user:

```markdown
**Worktree created:** `../<project>-sprint-<number>`

To work in this worktree, open a new Claude Code instance in that directory.
Each worktree has its own branch and working tree, so you can work on multiple stories in parallel.

**Important:** When done, run `/sprint-end` from within the worktree. It will clean up after merge.
```

### Branch Naming

- Branch naming convention: `sprint-<number>` (e.g., `sprint-001`, `sprint-002`)
- The number is always the next sequential sprint number

### Optional: Draft PR for Early CI Feedback

<IF condition="CI is configured (.github/workflows/ detected) AND gh CLI is available">
After branch creation, ask the user if they want to create a draft PR for early CI feedback:

```bash
git push -u origin sprint-<number>
gh pr create --draft --title "Sprint <N>: <sprint-goal>" --body "Work in progress — sprint branch for early CI feedback."
```

Draft PRs enable CI to run on every push during the sprint, catching issues early. They block merging and suppress CODEOWNERS notifications until marked ready.

If user declines, skip — the branch is pushed and PR created at sprint-end.
</IF>

## 3. Sprint Planning

### Show Upcoming Stories

Read `docs/reference/BACKLOG_INDEX.md` and scan epic files for stories with status `ready`, grouped by priority:

```markdown
### Ready Stories (by priority)
| Priority | ID | Title | Type | Size | Epic |
|----------|----|-------|------|------|------|
| P0 | PROJ-001 | [title] | feature | S | E01 |
| P1 | PROJ-003 | [title] | bugfix | S | E01 |
```

If no stories have `ready` status, check for `draft` stories and suggest running `/ideate` to refine them, or `/backlog-review` to assess backlog health.

### Define Sprint Goal and Scope

Ask the user to select stories for this sprint and define a sprint goal. Guide them:

- **Sprint goal**: One sentence describing the outcome (not a list of stories). Example: "Enable users to authenticate via OAuth2"
- **Story selection**: Based on ready stories, capacity (estimated sessions available), and priority order
- **Sizing**: S (1 session), M (2-3 sessions), L (3-5 sessions) — based on complexity, not effort hours
- **Buffer**: Reserve ~15% of sessions for unplanned work

<IF condition="docs/reference/PRD_SUMMARY.md exists">
**Sprint Definition of Done** (derived from PRD): Read PRD Section 6 (NFRs) and Section 7 (scope boundaries). Include applicable thresholds:
- Performance targets from NFRs (e.g., "API < 200ms P95")
- Security requirements from NFRs (e.g., "all PII encrypted")
- Implementation boundaries from Section 7 (Always/Ask first/Never rules)
</IF>

### Create Sprint Spec

Copy `docs/sprints/_TEMPLATE.md` to `docs/sprints/sprint-<number>.md` and fill in:

- Sprint number and goal (from user input above)
- Start date (today)
- Branch name
- Stories table (from selected stories, with sizes)
- Boundaries: Done means, out of scope, risks
- Capacity: available sessions, buffer, constraints

Leave the Decisions, Notes, and Outcome sections empty — they're filled during and after the sprint.

### Update progress.md

Update `docs/progress.md` → `## Current Sprint` section with:
- Sprint number and goal
- Branch name and status
- Compact stories table (just #, title, size, status)
- Notes: empty (filled during sprint)

## 4. Done

Output a summary:

```markdown
### Sprint Ready

**Sprint [N]: [goal]**
**Branch:** `sprint-<number>`
**Mode:** [Standard / Worktree at ../<path>]
**Main status:** Tests passing, up to date
**Open PRs:** None (or list any that exist)
**Stories:** [count] selected ([total size estimate])
**Sprint spec:** `docs/sprints/sprint-<number>.md`

Ready to start work.

**Next steps:**
1. Clear your context window: `/clear`
2. Start the first story: `/story-cycle [first-story-id]`
```

Always show the actual first story ID from the sprint plan (e.g., `/story-cycle E01-S01`), not a placeholder.

**Skill metrics:** Emit a completion event:

```bash
echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"sprint-start\",\"outcome\":\"success\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

## What This Skill Does NOT Do

- Does not load story context (that's `/story-cycle`'s job)
- Does not run analysis agents
- Does not update epic files or backlog
- Does not assume any particular project structure
