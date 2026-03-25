---
name: retrospective
version: 3.0.0
description: Sprint retrospective — consumes progress.md Metrics table, adds leading-lagging analysis, anti-pattern detection, and 4Ls framework.
trigger: manual
depends-on: []
references: [references/metrics-analysis.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---
______________________________________________________________________

## retrospective

Run a sprint or weekly retrospective:

## 1. Gather Data

Read sprint specs and progress to build a complete picture:

- Read `docs/progress.md` → `## Sprint History` table for trend data
- Read the sprint spec(s) being reviewed: `docs/sprints/sprint-N.md` — especially the `## Outcome` and `## Decisions` sections
- Git log for commits and their messages
- Any blockers or issues encountered (from sprint spec `## Notes` and `## Decisions`)

## 2. Metrics Dashboard

### 2.1. Progress Metrics (single source of truth)

Read `docs/progress.md` → `## Metrics` table and display it directly — sprint-end already computed these values.

| Metric | Current | Target | Trend | Status |
|:-------|:-------:|:------:|:-----:|:------:|
[Copy all rows from progress.md Metrics table]

**Sprint note:** [Copy from progress.md if present]

### 2.2. Sprint-over-Sprint Comparison

Read `docs/progress.md` → `## Sprint History` table. Extract the last 2 rows (current and previous sprint):

| Metric | This Sprint | Previous | Δ | Direction |
|--------|-------------|----------|---|-----------|
| Goal achieved | [✅/❌] | [✅/❌] | — | [streak] |
| Tasks completed | [X] | [Y] | [+/-] | [↑/↓/→] |
| Cycle time | [X.Xd] | [Y.Yd] | [+/-] | [↑/↓/→] |
| Change failure rate | [X%] | [Y%] | [+/-] | [↑/↓/→] |
| Test coverage Δ | [+X%] | [+Y%] | [+/-] | [↑/↓/→] |
| Code churn ratio | [0.XX] | [0.YY] | [+/-] | [↑/↓/→] |
| AI effectiveness | [0.XX] | [0.YY] | [+/-] | [↑/↓/→] |
| Sprint satisfaction | [X/5] | [Y/5] | [+/-] | [↑/↓/→] |

Also extract from sprint spec (`docs/sprints/sprint-N.md` → `## Outcome`):
- **Sprint churn**: % stories added/removed mid-sprint (target <20%, >40% = broken planning)
- **Done-to-commit ratio**: completed/planned (80% healthy, >95% = under-committing, <65% = over-committing)

### 2.3. Leading vs Lagging Analysis

Read `references/metrics-analysis.md` for the leading/lagging classification.

From the Sprint History's last 3 rows, assess the trend direction for each group:
- **Leading indicators** (churn, coverage Δ, satisfaction): [improving / stable / degrading]
- **Lagging indicators** (CFR, tasks): [improving / stable / degrading]

Flag any divergence — see the reference file for interpretation guidance. This is the most actionable analysis: leading indicators predict what lagging will show in 1-2 sprints.

### 2.4. Anti-pattern Detection

Read `references/metrics-analysis.md` for the four anti-pattern definitions. Check each against Sprint History data:

1. **Perception gap**: satisfaction ≥4 AND (CFR or churn rising 2+ sprints)?
2. **Task fragmentation**: tasks rising AND cycle time shrinking 2+ sprints?
3. **Weak tests**: coverage Δ positive AND CFR rising 2+ sprints?
4. **Maintenance spiral**: <50% feature stories AND churn rising?

Flag any detected patterns with specific metric evidence.

### 2.5. Feature Time Ratio

<IF condition="docs/sessions/.activity-log.jsonl exists">
Parse `docs/sessions/.activity-log.jsonl` for story `status-change` events with `story_type` field. Count completed stories by type:

| Type | Count | % |
|------|-------|---|
| feature | [X] | [X%] |
| bugfix | [Y] | [Y%] |
| refactor | [Z] | [Z%] |
| other | [W] | [W%] |

If feature stories are <50% of total, flag: "Less than half of sprint work on features — investigate maintenance burden."
</IF>

### 2.6. Hotspot Investigation (conditional)

<IF condition="Code churn ratio in Metrics table is 🟡 or 🔴">
Run `scripts/pm/metrics.sh --churn` and display the high-churn files. Cross-reference with sprint stories — are these files being actively developed, or are they unrelated files being destabilized?
</IF>

### 2.7. Framework Metrics

Run the metrics script for framework-specific data not captured in progress.md:

```bash
bash scripts/pm/metrics.sh
```

Reports: skill success/failure rates, per-skill breakdown, tool usage, rule triggers. Identify: bottleneck skills (high failure), rework patterns (high Bash ratio), underutilized gates.

<IF condition="docs/reference/GROUND_RULES.md exists">
### 2.8. Ground Rule Compliance

Read sprint spec `## Outcome` → **Ground rules** field across recent sprints:
- **Violation trend** — increasing violations signals architectural drift
- **Repeat violations** — same rule violated multiple sprints: rule may be unrealistic or enforcement insufficient
- **Coverage gaps** — rules never checked suggest enforcement isn't working
</IF>

## 3. Retrospective Framework

Use the 4Ls format:

### Liked (What went well?)

- Consider: smooth processes, good decisions, effective patterns

### Learned (What did we discover?)

- Consider: technical discoveries, process improvements, gotchas found

### Lacked (What was missing?)

- Consider: tools, information, clarity, time

### Longed For (What do we wish we had?)

- Consider: automation, better docs, different approach

## 4. AI-Assisted Sprint Reflection

Sprint-goal-anchored questions (answer each with evidence, not impressions):

### Sprint Goal Effectiveness
- Did the sprint goal help scope decisions during story execution? Was it specific enough for AI to use as decision context?
- Were there moments where the sprint goal was ignored or forgotten? What caused that?
- Should the goal format change for next sprint? (e.g., too vague, too compound, too narrow)

### Session & Capacity Accuracy
- How many sessions were actually used vs estimated? Were S/M/L sizes accurate?
- Which stories took more sessions than sized? Why? (complexity surprise, external dependency, scope change)
- Should the session capacity estimate change for next sprint?

### AI Execution Quality
- Where did AI-generated code create review bottleneck? (time spent reviewing vs writing)
- Were any tests weakened or deleted? Were quality gates effective at catching this?
- Context management: Did we hit limits? Was the plan-then-execute pattern followed?
- TDD discipline: Was test-first maintained, or did time pressure cause shortcuts?

### Carry-Over & Churn Analysis
- Were carried-over stories goal-critical or non-critical? (Non-critical carry-over = correct prioritization)
- What was the sprint churn rate? If >20%, what caused mid-sprint additions?
- Were any stories added mid-sprint that should have waited for backlog?

## 4.5. Architecture Decision Audit

Review whether architectural decisions made during this sprint are properly documented:

- **Scan commit messages and story plans** for technology choices, pattern decisions, or trade-off discussions that aren't captured in `docs/adr/`
- **Check for "decisions in chat"** — if the team discussed architectural choices during the sprint but didn't create ADRs, flag specific candidates (e.g., "Chose Redis over Memcached for caching — warrants an ADR")
- **Ground rule candidates** — if a pattern was enforced informally during the sprint ("we always do X"), suggest formalizing it as a ground rule backed by an ADR

This prevents the "decisions in Slack" anti-pattern where architectural choices are made but never formalized.

## 5. Action Items

Convert insights into specific actions:

| Item       | Type             | Priority     | Owner | Due      |
| ---------- | ---------------- | ------------ | ----- | -------- |
| \[Action\] | Process/Tool/Doc | High/Med/Low | Self  | \[Date\] |

## 6. Update CLAUDE.md

If patterns or gotchas were discovered:

- Add to CLAUDE.md for future sessions
- Update any incorrect conventions
- Add new commands if needed

## 7. Retrospective Summary

```markdown
## Retrospective - [Date]

### Period Covered
[Sprint X / Week of Y]

### Metrics Summary
[Copy the Metrics table from docs/progress.md — single source of truth]

### Key Signals
- Leading indicators: [improving/stable/degrading]
- Lagging indicators: [improving/stable/degrading]
- Anti-patterns detected: [list or "none"]
- Feature time ratio: [X]%

### Top 3 Positives
1. [Most impactful positive]
2.
3.

### Top 3 Improvements Needed
1. [Most important improvement]
2.
3.

### Action Items
[List from above]

### Process Adjustments
[Any changes to workflow]
```

Output the retrospective summary with action items.
