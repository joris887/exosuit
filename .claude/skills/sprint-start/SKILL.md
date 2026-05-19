---
name: sprint-start
version: 3.0.0
description: Pre-sprint checks, feature branch creation, sprint planning, and story re-refinement against the current brain.
trigger: manual
depends-on: []
references: [references/story-refinement.md]
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

Starting a new sprint.

## Profile-Adaptive Behavior

Read the `**Profile:**` line from CLAUDE.md to determine the active project profile.

<IF condition="Profile is lean">
**Lean mode:** Skip steps 1.5 (Metrics Health Check), 1.6 (Debt Health Check), step 3 (Sprint Planning ceremony — no sprint spec generation, no story selection, no PRD check), and step 3.5 (Story Re-Refinement — no selected stories to refine). Perform only: 1a-1d (pre-flight checks), step 2 (create feature branch), and update `docs/progress.md` with branch name and sprint number.

If the user wants story re-refinement against the brain without the full sprint ceremony, they can invoke `/story-cycle` directly — Phase 1 will re-explore against the brain on demand.
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
- **Sizing**: TRIVIAL / STANDARD (default) / LARGE — bounded by verification breadth and PR reviewability. **No time estimates.** Typical sprint capacity: 3-6 STANDARD outcomes (LARGE counts as 2).
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

## 3.5. Story Re-Refinement (against the current brain)

Stories may have been written weeks ago. Their **Outcome** sections (Why, Acceptance Criteria, Out of Scope) are stable — those still apply. But their **Implementation Hints** (file lists, pattern references, dependencies) freeze at write-time and rot as the code moves. This step re-derives them.

**Skip when:** `docs/brain/` doesn't exist (pre-bootstrap project, or framework v4 project pre-migration). Note in summary: "Brain not present — skipping re-refinement. Stories will use frozen hints."

For each story selected for this sprint:

### 3.5a. Load context (fast — grep + brain reads only, no agents)

- Read the story's Outcome + Verification sections from the epic file (these stay).
- Read `docs/brain/index.md` to find the brain pages most relevant to the story's domain.
- Read those pages (≤3) plus `docs/brain/current-state.md`.
- Check `docs/brain/log.md` for entries since the story's `created:` date — these are the changes the story's hints don't know about.

### 3.5b. Re-derive Implementation Hints

Rewrite the story's `## Implementation Hints (refined at sprint-start)` section:

- **Affected files (now):** grep + brain to find which files the outcome touches *today*. The frozen list may be stale; the new list overwrites it.
- **Pattern to follow:** cite a current exemplar (file:line) from `system-patterns.md` or the codebase. If the pattern shifted since story creation, the new pattern wins.
- **Existing helpers to reuse:** anything the story can compose from rather than rebuild — pulled from brain or grep.
- **Dependencies (now):** check that listed story dependencies are still relevant; remove any that are now done, add any that emerged.

Bump the story's frontmatter `refined_at:` to today.

### 3.5c. Invalidation & Block flags

Apply two checks against the brain:

- **Outcome invalidated**: the world moved. E.g., the story is "add OAuth login" but `current-state.md` shows OAuth is already shipped (a previous sprint already delivered it). Flag for the user — kill or keep?
- **Outcome blocked**: the story is implementable but a load-bearing constraint changed. E.g., the story assumes the old session model but `system-patterns.md` shows session storage was migrated. Flag for the user — defer, re-scope, or proceed with brain-aware re-scoping?

Surface flags as:

```
Re-refinement found 1 flag:
  [INVALID] PROJ-014 — "Add OAuth login" — current-state.md says OAuth shipped in sprint 12 (src/auth/oauth.ts:1)
    Options: [K] Kill (mark won't-do), [D] Defer to backlog review, [E] Edit outcome
```

Wait for user decision before continuing.

### 3.5d. Update epic file

Write the refined Implementation Hints back to the story's section in `docs/reference/backlog/E##-*.md`. Set frontmatter `refined_at: YYYY-MM-DD` and `outcome_invalidated_by:` if the user kept an invalidated story (records the conflict for next time).

### 3.5e. Emit refinement events

```bash
for story in <selected-stories>; do
  echo "{\"type\":\"story\",\"event\":\"refined\",\"id\":\"<id>\",\"flags\":\"<none|invalid|blocked>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
done
```

### Profile adaptation

- **Lean profile:** Re-refinement is best-effort. Skip on stories with no Implementation Hints section (old format).
- **Standard profile (default):** Re-refine all selected stories.
- **Strict profile:** Re-refinement is mandatory. If any story lacks Implementation Hints structure, regenerate it from scratch using `/ideate` semantics before the sprint begins.

Target: ≤2 minutes per story. If a story consistently needs longer, that's a signal to split it.

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

## What This Skill Does NOT Do

- Does not load story context (that's `/story-cycle`'s job)
- Does not run analysis agents
- Does not update epic files or backlog
- Does not assume any particular project structure
