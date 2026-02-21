______________________________________________________________________

## name: retrospective description: Run a sprint or weekly retrospective using the 4Ls framework. Analyzes what worked, what was learned, what was lacking, and what we wish we had. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash

Run a sprint or weekly retrospective:

## 1. Gather Data

Review:

- @docs/progress.md recent entries
- Sprint specs from this period
- Git log for commits and their messages
- Any blockers or issues encountered

## 2. Metrics Review

Run the project's test and quality commands (from CLAUDE.md Commands section) to get current metrics.

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

### Top 3 Positives
1. [Most impactful positive]
2.
3.

### Top 3 Improvements Needed
1. [Most important improvement]
2.
3.

### Key Metrics
- Velocity: [stories/points completed]
- Quality: [test coverage, bugs found]
- Process: [adherence to TDD, doc updates]

### Action Items
[List from above]

### Process Adjustments
[Any changes to workflow]
```

Output the retrospective summary with action items.
