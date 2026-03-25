---
name: retrospective
version: 2.5.0
description: Run a sprint or weekly retrospective using flow metrics and the 4Ls framework. Reads sprint spec Outcome data and progress.md Sprint History for trend analysis.
trigger: manual
depends-on: []
references: []
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

### Flow Metrics (from sprint spec Outcome section and progress.md Sprint History)

| Metric | This Sprint | Previous Sprint | Trend |
|--------|-------------|-----------------|-------|
| Goal achieved | [✅/❌] | [✅/❌] | [streak] |
| Throughput | [X stories] | [Y stories] | [+/-] |
| Cycle time (avg) | [X days] | [Y days] | [+/-] |
| Sprint churn | [X%] | [Y%] | [+/-] |
| Done-to-commit ratio | [X/Y = Z%] | [Z%] | [+/-] |

**Interpreting flow metrics:**
- **Goal achievement streak** — consecutive ✅ signals predictable delivery. Target: 80%+ over 5 sprints.
- **Throughput trend** — enables Monte Carlo forecasting. Stable throughput > increasing throughput (which may signal corner-cutting).
- **Cycle time** — lower is better, but track by story type (feature vs bug vs refactor) since they differ.
- **Sprint churn** — target below 20%. Above 40% signals broken upstream planning.
- **Done-to-commit ratio** — 80% is healthy; >95% means under-committing; <65% means over-committing.

### Quality Metrics

Run the project's test and quality commands (from CLAUDE.md Commands section):

| Metric | This Sprint | Previous Sprint | Trend |
|--------|-------------|-----------------|-------|
| Test count | [X] | [Y] | [+/-] |
| Coverage | [X%] | [Y%] | [+/-] |
| Test coverage delta | [+/-X%] | [+/-Y%] | [direction] |
| Defect escapes | [X] | [Y] | [+/-] |
| Security findings | [X] | [Y] | [+/-] |

<IF condition="docs/reference/GROUND_RULES.md exists">
### Ground Rule Compliance Trends

Read sprint spec `## Outcome` → **Ground rules** field across recent sprints. Analyze:
- **Violation trend** — increasing violations sprint-over-sprint signals architectural drift
- **Repeat violations** — same rule violated multiple sprints may indicate the rule is unrealistic or enforcement is insufficient
- **Coverage gaps** — rules never checked suggest the enforcement channel isn't working
</IF>

### AI-Specific Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| AI suggestion survival rate* | [estimate] | Code from AI that survives first review |
| Context resets | [count] | Number of /clear or compaction events |
| Agent invocations | [count] | Quality/test/security agents used |
| TDD compliance | [high/medium/low] | Were tests written first? |

*Estimate based on commit history — code added then immediately changed indicates low survival rate

### Activity Log Metrics

<IF condition="docs/sessions/.activity-log.jsonl exists">
Parse `docs/sessions/.activity-log.jsonl` to extract:
- Total tool invocations (Edit, Write, Bash) per session
- Most-edited files (hotspots indicating rework)
- Edit-to-Bash ratio (high Edit ratio = productive, high Bash ratio = debugging)
- Time distribution across files
</IF>
<ELSE>
Activity log not available — skip activity metrics. Note: enable the PostToolUse hook via post-tool-use.sh for richer retrospective data.
</ELSE>

### Skill Execution Metrics

Run the metrics script for quantitative skill data:

```bash
bash scripts/pm/metrics.sh
```

This reports: skill success/failure rates, per-skill breakdown, tool usage distribution, and rule trigger counts. Use this data to identify bottlenecks (skills with high failure rates), rework patterns (high Bash ratio), and underutilized quality gates.

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
| Metric | Value | Trend |
|--------|-------|-------|
| Goal achieved | [✅/❌] | [streak] |
| Throughput | [X stories] | [+/-] |
| Cycle time | [X days avg] | [+/-] |
| Sprint churn | [X%] | [+/-] |
| Tests | [X] | [+/-] |
| Coverage | [X%] | [+/-] |

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
