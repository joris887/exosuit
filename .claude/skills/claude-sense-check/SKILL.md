---
name: claude-sense-check
version: 3.4.0
description: Incremental code logic verification of UAT test cases — pick batch, trace code, fix issues, update tracking.
trigger: manual
depends-on: [story-cycle]
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## claude-sense-check

Performing incremental Claude Sense Check on UAT backlog.

## Phase 1: Read Current State

1. Find the UAT tracking file: check for `docs/testing/UAT_COVERAGE.md`, `docs/testing/UAT_INDEX.md`, or `docs/testing/uat/` directory
2. Scan for **Claude Sense Check** sections in every test case
3. Build a work queue: cases where `- [ ] Logic verified from code perspective` is unchecked
4. Skip cases where the checkbox is already `[x]`
5. If all cases are checked, report "All UAT cases have been sense-checked" and stop

## Phase 2: Pick Next Batch

From the unchecked cases (in ID order):

1. Select 2-5 cases that share the same module, feature area, or user flow
2. Present to the user:
   - **Batch**: which cases (e.g., UAT-005, UAT-006, UAT-007)
   - **Area**: the functional area they belong to
   - **Rationale**: why they belong together
   - **Relevant files**: source files and components expected to be involved
3. Proceed after presenting (no user confirmation needed — this is a code-only check)

## Phase 3: Gather Context

Before checking any logic, collect the full picture for the batch's feature area:

1. Read all source files relevant to the batch
2. Trace the data flow for the feature area end-to-end
3. Note dependencies, shared state, API contracts, and external integrations
4. Read existing tests for the relevant code — they reveal intent and edge cases
5. Check the **Covers** field on each test case to identify which backlog stories are involved
6. Read the story acceptance criteria from the relevant epic/backlog file

Do NOT proceed to logic checks until you have the full picture.

## Phase 4: Code Logic Check (per case)

For each case in the batch:

1. Read the test case steps and acceptance criteria carefully
2. Trace each step through the actual source code
3. For each acceptance criterion, verify:
   - The code path exists and is reachable
   - Conditionals are correct (no off-by-one, no inverted logic)
   - Data flows correctly between components
   - Error handling covers the expected failure modes
   - Edge cases mentioned in the test case are handled
4. Assign a verdict:
   - **Pass** — logic is correct, code handles the scenario properly
   - **Warning** — potential issue found, describe with file:line reference
   - **Fail** — confirmed broken, describe with file:line reference and root cause

## Phase 5: Resolve Issues

For every Warning or Fail verdict, classify the issue:

### 5a: Quick Fixes (code bugs, wiring issues, missing calls)

If the fix is localized (<=3 files, clear root cause, no architectural decisions):

1. Invoke `/story-cycle` with a description of the fix needed
2. After the fix is complete, re-verify the logic check passes for that case
3. Record the commit hash and one-line description of what was fixed

### 5b: Design Gaps (architectural changes, new features, multi-sprint work)

If the issue requires architectural decisions, new features, or touches >3 files:

1. Create a backlog story in the appropriate epic/backlog file
2. Include: story title, user story, acceptance criteria, depends-on, technical constraints
3. Reference the UAT case(s) that exposed the gap
4. Set status to `TODO`
5. Update backlog index totals if a new story was added

### Classification guide

| Signal | Action |
| --- | --- |
| Missing function call, wrong variable, inverted condition | Quick fix (5a) |
| API contract mismatch, missing endpoint, wrong data flow | Quick fix (5a) |
| Feature not implemented, new integration, new UI flow | Design gap (5b) |
| Architectural decision needed (e.g., polling vs push) | Design gap (5b) |
| Cross-cutting concern (affects multiple layers) | Design gap (5b) |

## Phase 6: Update Tracking

### Per-case: Update the UAT tracking file

For each case in the batch:

1. Check the **Claude Sense Check** checkbox: `- [x] Logic verified from code perspective`
2. Fill in the Notes line with verdict and what was checked or fixed:
   - Pass: `"Pass — verified [what was checked], code handles [scenario] correctly"`
   - Fixed: `"Fixed — [issue description], resolved in [commit-hash]"`
   - Design gap: `"Warning -> [story-id] — [gap description], backlog story created"`

### Per-area: Update UAT index

After updating the tracking file, update any status summary tables to reflect the new sense-check counts.

## Phase 7: Report & Hand Off

Output a summary:

```markdown
### Claude Sense Check Complete

**Batch:** UAT-### to UAT-### ([area name])
**Results:**
| Case | Title | Verdict | Notes |
| ---- | ----- | ------- | ----- |
| UAT-### | [title] | Pass/Warning/Fixed | [one-line summary] |

**Fixes Applied:** [count]
- [commit-hash]: [one-line description] (for UAT-###)

**Backlog Stories Created:** [count]
- [story-id]: [one-line description] (for UAT-###)

**Progress:** [x]/[total] UAT cases sense-checked
**Remaining:** [count] cases unchecked
**Suggested Next Batch:** UAT-### to UAT-### ([area name]) — [why]
```

## Rules

- Never re-check an already checked case
- Never check more than 5 cases in one run — stay focused
- Always update the tracking file before finishing — the checkboxes are the source of truth
- Always gather full context before starting logic checks — no guessing
- Always use `/story-cycle` for fixes — maintain TDD discipline
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
- Follow verification rules: run the project's test command before claiming fixes are complete
