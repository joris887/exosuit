---
name: dashboard
version: 1.2.0
description: Sprint status overview with session insights, sprint trends, and actionable next steps.
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

## 8. Session Insights

Parse `docs/sessions/.activity-log.jsonl` (if it exists and has entries) for this session's activity:

```bash
# Count entries by tool type
ACTIVITY_LOG="docs/sessions/.activity-log.jsonl"
if [ -f "$ACTIVITY_LOG" ] && [ -s "$ACTIVITY_LOG" ]; then
  # Top 5 most edited files
  grep '"tool":"Edit\|Write"' "$ACTIVITY_LOG" | grep -o '"target":"[^"]*"' | sort | uniq -c | sort -rn | head -5
  # Count edits vs test runs
  EDIT_COUNT=$(grep -c '"tool":"Edit\|Write"' "$ACTIVITY_LOG" 2>/dev/null || echo 0)
  TEST_RUNS=$(grep -c '"test_result"' "$ACTIVITY_LOG" 2>/dev/null || echo 0)
  # Skill invocations
  grep '"type":"skill"' "$ACTIVITY_LOG" | grep -o '"skill":"[^"]*"' | sort | uniq -c | sort -rn | head -5
fi
```

Present insights (only sections with data):

```markdown
### Session Insights
- **Most edited:** `src/auth/login.ts` (8 edits), `src/api/users.ts` (5 edits)
- **Edit-to-test ratio:** 12 edits / 3 test runs (ratio: 4.0 — consider running tests more often)
- **Test failures this session:** 2 (both recovered)
- **Skills used:** /story-cycle (3x), /commit (2x), /debug-session (1x)
```

Edit-to-test ratio guidance:
- ≤2.0: Good TDD discipline
- 2.1-5.0: Acceptable, could test more frequently
- >5.0: TDD drift — many edits between test runs

## 9. Sprint Trends

<IF condition="docs/progress.md has ≥2 rows in Sprint History table">
Read `docs/progress.md` → `## Sprint History` table. Extract trends:

```markdown
### Sprint Trends
- **Cycle time:** 2.1 → 1.8 → 1.5 days (improving)
- **Coverage:** 78% → 82% → 84% (improving)
- **Change failure rate:** 15% → 12% → 8% (improving)
```

Flag any metric that worsened for 2+ consecutive sprints.
</IF>
<ELSE>
Skip this section — not enough sprint data yet.
</ELSE>

## 10. Present Dashboard

```markdown
## Sprint Dashboard

### Git
- **Branch:** `sprint-N` (X commits ahead, Y uncommitted files)
- **Last commit:** 2 hours ago — "feat(auth): add login endpoint"

### Sprint N: [Sprint Goal]
- **Progress:** 3/5 stories done (2 remaining: E01-004 🔄, E01-005 🔲)
- **Capacity:** 3/5 STANDARD outcomes shipped (typical capacity 3-6 STANDARD)
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

### Session Insights
- **Most edited:** `src/auth/login.ts` (8 edits)
- **Edit-to-test ratio:** 4.0 (12 edits / 3 test runs)
- **Skills used:** /story-cycle (3x), /commit (2x)

### Sprint Trends
- Cycle time: 2.1 → 1.8 → 1.5 days (improving)
- Coverage: 78% → 82% → 84%

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
