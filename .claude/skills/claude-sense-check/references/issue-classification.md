# Issue Classification Guide

## 5a: Quick Fixes (code bugs, wiring issues, missing calls)

If the fix is localized (<=3 files, clear root cause, no architectural decisions):

1. Invoke `/story-cycle` with a description of the fix needed
2. After the fix is complete, re-verify the logic check passes for that case
3. Record the commit hash and one-line description of what was fixed

## 5b: Design Gaps (architectural changes, new features, multi-sprint work)

If the issue requires architectural decisions, new features, or touches >3 files:

1. Create a backlog story in the appropriate epic/backlog file
2. Include: story title, user story, acceptance criteria, depends-on, technical constraints
3. Reference the UAT case(s) that exposed the gap
4. Set status to `TODO`
5. Update backlog index totals if a new story was added

## Classification Guide

| Signal | Action |
| --- | --- |
| Missing function call, wrong variable, inverted condition | Quick fix (5a) |
| API contract mismatch, missing endpoint, wrong data flow | Quick fix (5a) |
| Feature not implemented, new integration, new UI flow | Design gap (5b) |
| Architectural decision needed (e.g., polling vs push) | Design gap (5b) |
| Cross-cutting concern (affects multiple layers) | Design gap (5b) |
