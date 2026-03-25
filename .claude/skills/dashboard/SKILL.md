---
name: dashboard
version: 1.1.0
description: Sprint status overview — sprint goal, story progress, capacity, work item age warnings, test health, and actionable next steps.
trigger: manual
depends-on: []
references: []
micro-components:
  step-1: [discover-commands]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---
______________________________________________________________________

## dashboard

Show sprint status overview.

## 1. Git State

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
AHEAD=$(git rev-list --count origin/$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)..HEAD 2>/dev/null || echo "?")
LAST_COMMIT=$(git log -1 --format="%cr — %s" 2>/dev/null || echo "no commits")
```

## 2. Sprint State

```bash
# Current sprint from progress.md
SPRINT=$(grep -m1 'Sprint\*\*:' docs/progress.md 2>/dev/null | sed 's/.*: *//' | tr -d ' ')
```

**Sprint spec:** Find the current sprint spec file (`docs/sprints/sprint-*.md`). Read it to extract:
- **Sprint goal** (from `## Goal` section) — display prominently as the first sprint line
- **Stories table** — count by status (🔲 todo, 🔄 in-progress, ✅ done, ⏭️ carried over)
- **Capacity** — sessions available vs sessions used (count ✅ stories as sessions consumed based on their Size)
- **Boundaries** — out of scope items (brief)

**Metrics snapshot:** Read `docs/progress.md` → `## Metrics` table. Extract rows that have data (Current column is not "—"). This data is displayed in section 8.

**Work item age check:** For any story with 🔄 status, check `docs/sessions/.activity-log.jsonl` for its `status-change` to `in-progress` event. Read the current cycle time value from `docs/progress.md` → `## Metrics` table (row "Cycle time (days)", Current column). If available, use this as the average cycle time reference. Fall back to computing from Sprint History if no data. Flag stories in-progress longer than the average:
> "⚠️ [Story ID] has been in-progress for [N] days (avg cycle time: [M] days)"

## 3. Backlog Snapshot

Read `docs/reference/BACKLOG_INDEX.md` for story counts:
- Total stories across all epics
- Done / In Progress / TODO counts
- Current focus area

## 4. Test Health

Run the `discover-commands` micro-component from `.claude/prompts/discover-commands.md`, then:

<IF condition="test command configured">
```bash
# Run tests and capture summary
```
Report: X passing, Y failing, coverage if available.
</IF>
<ELSE>
Report: "No test command configured"
</ELSE>

## 5. Open PRs

```bash
gh pr list --author @me --state open --json number,title,reviewDecision,statusCheckRollup 2>/dev/null || echo "gh not available"
```

## 6. Session State

Check for:
- `.failure-state.md` — interrupted workflow
- Latest `session-*.md` — last handoff date
- `.auto-save.md` — last auto-save

## 7. Framework Health (Quick)

Quick checks (subset of /doctor):
- Hook scripts exist and are executable
- At least one formatter available
- GROUND_RULES.md has content

## 8. Present Dashboard

```markdown
## Sprint Dashboard

### Git
- **Branch:** `sprint-N` (X commits ahead, Y uncommitted files)
- **Last commit:** 2 hours ago — "feat(auth): add login endpoint"

### Sprint N: [Sprint Goal]
- **Progress:** 3/5 stories done (2 remaining: E01-004 🔄, E01-005 🔲)
- **Capacity:** ~6/8 sessions used (buffer: 1 session)
- **Out of scope:** [from boundaries]
- ⚠️ E01-004 in-progress for 3 days (avg cycle time: 1.5 days)

### Backlog
- 3 done / 1 in progress / 8 TODO

### Tests
- **Status:** 47 passing, 0 failing
- **Coverage:** 82% (+3% this sprint)

### PRs
- None open

### Session
- **Last handoff:** 2 days ago
- **Interrupted workflow:** None

### Metrics Health
| Metric | Current | Target | Trend | Status |
|:-------|:-------:|:------:|:-----:|:------:|
| Cycle time (days) | 2.1 | ≤3.0 | ▇▆▅▄▃▂ | 🟢 |
| Change failure rate | 12% | ≤15% | ▂▃▂▄▅▃ | 🟡 |
[Show only metrics rows with data — skip rows where Current is "—"]
[If any 🟡/🔴: show sprint note from progress.md]

### Framework
- **Health:** All checks passing

### Suggested Next Action
→ `/story-cycle "E01-004"` — Continue with the next backlog story
```

## Suggested Actions Logic

Based on state, suggest the most relevant next action:

| State | Suggestion |
|---|---|
| On main, no sprint | `/sprint-start` |
| On sprint branch, no story in progress | `/story-cycle <next-TODO-story>` |
| Story in progress | "Continue current story" |
| Interrupted workflow | "Resume with `/continue`" |
| Sprint complete, no PR | `/sprint-end` |
| PR open and approved | "Merge PR: `gh pr merge --squash`" |
| PR with review feedback | "Address feedback on PR #N" |
| All stories done | `/sprint-end` or `/retrospective` |

## Rules

- This skill is READ-ONLY — no modifications, no side effects
- Keep output concise — this is a quick status check, not a deep analysis
- Show only relevant sections — skip sections with no data
- Always end with a suggested next action
