---
name: retrospective
version: 2.4.0
description: Run a sprint or weekly retrospective using the 4Ls framework with metrics dashboard. Analyzes what worked, what was learned, what was lacking, and what we wish we had.
trigger: manual
depends-on: []
references: []
---
______________________________________________________________________

## name: retrospective description: Run a sprint or weekly retrospective using the 4Ls framework with metrics dashboard. Analyzes what worked, what was learned, what was lacking, and what we wish we had. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash

Run a sprint or weekly retrospective:

## 1. Gather Data

Review:

- @docs/progress.md recent entries
- Sprint specs from this period
- Git log for commits and their messages
- Any blockers or issues encountered

## 2. Metrics Dashboard

Collect and present quantitative metrics:

### Sprint Metrics

```bash
# Commits this sprint
git log main..HEAD --oneline | wc -l

# Files changed
git diff --stat main...HEAD

# Test count (use project test command)
# Lines of code added/removed
git diff --stat main...HEAD | tail -1
```

### Quality Metrics

Run the project's test and quality commands (from CLAUDE.md Commands section):

| Metric | This Sprint | Previous Sprint | Trend |
|--------|-------------|-----------------|-------|
| Test count | [X] | [Y] | [+/-] |
| Coverage | [X%] | [Y%] | [+/-] |
| Code duplication | [X%] | [Y%] | [+/-] |
| Churn rate* | [X files] | [Y files] | [+/-] |
| Security findings | [X] | [Y] | [+/-] |
| Stories delivered | [X] | [Y] | [+/-] |

*Churn rate: files added then quickly modified or deleted within the same sprint (indicates rework)

### AI-Specific Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| AI suggestion survival rate* | [estimate] | Code from AI that survives first review |
| Context resets | [count] | Number of /clear or compaction events |
| Agent invocations | [count] | Quality/test/security agents used |
| TDD compliance | [high/medium/low] | Were tests written first? |

*Estimate based on commit history — code added then immediately changed indicates low survival rate

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

## 4. AI-Assisted Development Specific

Reflect on Claude Code usage:

- Context management: Did we hit limits? Use /clear effectively?
- Agent usage: Which agents were most valuable?
- TDD discipline: Did we maintain test-first?
- Quality gates: Did verification catch issues?
- Documentation: Did we keep docs updated?
- Test quality: Were any tests weakened or deleted?

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
| Stories | [X] | [+/-] |
| Tests | [X] | [+/-] |
| Coverage | [X%] | [+/-] |
| Quality | [score] | [+/-] |

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
