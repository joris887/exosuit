---
name: claude-sense-check
version: 3.4.0
description: Incremental code logic verification of UAT test cases — pick batch, trace code, fix issues, update tracking.
trigger: manual
depends-on: [story-cycle]
references: [references/issue-classification.md]
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

From the unchecked cases, sorted by priority (critical > high > medium > low), then by ID within each priority level:

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
4. Assign a verdict with confidence (high = full code path traced, medium = partial trace or complex logic, low = inference without full trace):
   - **Pass** (high/medium/low) — logic is correct, code handles the scenario properly
   - **Warning** (high/medium/low) — potential issue found, describe with file:line reference
   - **Fail** (high/medium/low) — confirmed broken, describe with file:line reference and root cause

## Phase 5: Resolve Issues

For every Warning or Fail verdict, classify and act. Read `references/issue-classification.md` for the full classification guide (quick fix vs design gap).

## Phase 6: Update Tracking

### Per-case: Update the UAT tracking file

For each case in the batch:

1. Check the **Claude Sense Check** checkbox: `- [x] Logic verified from code perspective`
2. Fill in the Notes line with verdict and what was checked or fixed:
   - Pass: `"Pass (high) — verified [what was checked], code handles [scenario] correctly"`
   - Fixed: `"Fixed (high) — [issue description], resolved in [commit-hash]"`
   - Design gap: `"Warning (medium) -> [story-id] — [gap description], backlog story created"`

### Per-area: Update UAT index

After updating the tracking file, update any status summary tables to reflect the new sense-check counts.

## Phase 7: Report & Hand Off

Output a summary:

```markdown
### Claude Sense Check Complete

**Batch:** UAT-### to UAT-### ([area name])
**Results:**
| Case | Title | Verdict | Confidence | Notes |
| ---- | ----- | ------- | ---------- | ----- |
| UAT-### | [title] | Pass/Warning/Fixed | high/medium/low | [one-line summary] |

**Fixes Applied:** [count]
- [commit-hash]: [one-line description] (for UAT-###)

**Backlog Stories Created:** [count]
- [story-id]: [one-line description] (for UAT-###)

**Progress:** [x]/[total] UAT cases sense-checked
**Remaining:** [count] cases unchecked
**Suggested Next Batch:** UAT-### to UAT-### ([area name]) — [why]
```

Include a YAML block for machine-parseable results:
```yaml
sense_check:
  batch: [UAT-###, UAT-###]
  area: "[area name]"
  results:
    - id: UAT-###
      verdict: pass
      confidence: high
      notes: "[one-line]"
  fixes: 0
  stories_created: 0
  progress: "X/Y"
```

## Rules

- Never re-check an already checked case
- Never check more than 5 cases in one run — stay focused
- Always update the tracking file before finishing — the checkboxes are the source of truth
- Always gather full context before starting logic checks — no guessing
- Always use `/story-cycle` for fixes — maintain TDD discipline
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
- Follow verification rules: run the project's test command before claiming fixes are complete
