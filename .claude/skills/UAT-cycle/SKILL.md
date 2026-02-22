---
name: UAT-cycle
version: 2.4.0
description: Execute a UAT test case — select, test, process findings, fix or log, and close the cycle.
trigger: manual
depends-on: []
references: []
---
______________________________________________________________________

## name: UAT-cycle description: Execute a UAT test case — select, test, process findings, fix or log, and close the cycle. argument-hint: <test-case-id-or-description> disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Executing UAT cycle: **$ARGUMENTS**

## Phase 1: Select Test Case

### If a test case ID was provided (e.g., UAT-001):

1. Read `docs/testing/UAT_COVERAGE.md`
1. Find the test case by ID
1. Present it to the user:
   - **Test Case ID**: UAT-###
   - **Title**: \[title\]
   - **Covers**: \[backlog story IDs or feature area\]
   - **Prerequisites**: \[what's needed\]
   - **Steps**: \[numbered steps\]
   - **Acceptance Criteria**: \[checklist\]
1. Ask: "Ready to start testing? Are all prerequisites met?"

### If a description was provided instead of an ID:

1. Read `docs/testing/UAT_COVERAGE.md`
1. Find the best matching test case(s)
1. If ambiguous, present options for the user to choose
1. Once selected, present as above

### If no argument was provided:

1. Read `docs/testing/UAT_COVERAGE.md`
1. Show the status summary table
1. List all test cases with status "Not Tested" (prioritized) or "Fail" (for retesting)
1. Ask the user to select which test case to execute

## Phase 2: Execute Test

The user performs the test steps manually (or with automation tooling). Claude assists by:

1. **Ensuring prerequisites**: Check that required services, data, or environments are available
   - If prerequisites aren't met, help the user set them up
1. **Guiding through steps**: Present steps one at a time or all at once (user preference)
1. **Collecting results**: After the user completes testing, ask for results on each acceptance criterion:
   - Pass / Fail / Blocked / Not Applicable
   - Any observations, screenshots, or feedback per criterion
1. **Recording findings**: For each failing criterion, ask:
   - What happened vs. what was expected?
   - Severity: Critical / Major / Minor / Cosmetic
   - Any error messages or unexpected behavior?

## Phase 3: Process Findings

For each finding (failing acceptance criterion), classify and act:

| Classification | Indicators                                           | Action                              |
| -------------- | ---------------------------------------------------- | ----------------------------------- |
| Bug (Critical) | Core functionality broken, data loss, crash          | Fix now (TDD: test → fix → verify)  |
| Bug (Minor)    | UI glitch, cosmetic, non-blocking, edge case         | Fix now (minimal change)            |
| Gap            | Feature missing entirely, expected capability absent | Log to backlog                      |
| Enhancement    | Works but could be better, UX improvement            | Log to backlog or fix if trivial    |
| Known Issue    | Already documented in known issues                   | Note as confirmed, skip fix         |

For each finding:

### Bug (Critical)

1. **Investigate**: Find the root cause in code
1. **Test first**: Write a failing test capturing the bug
1. **Fix**: Minimal code change
1. **Verify**: Run the project's test command (from CLAUDE.md)
1. **Ask user to re-verify** the specific acceptance criterion
1. **Commit**: `fix(scope): description`

### Bug (Minor)

1. **Identify** the issue in code
1. **Fix** with minimal change
1. **Add test** if regression-prone
1. **Run** the project's test command
1. **Commit**: `fix(scope): description`

### Gap

1. **Document** clearly
1. **Write a user story** (INVEST format) and add to the appropriate backlog file in `docs/reference/backlog/`
1. **Do NOT implement** — scope control
1. **Report** what was logged

### Enhancement

1. **Evaluate scope**: Trivial (< 10 lines) → ask user if should fix now
1. Larger → log to backlog
1. Act accordingly

### Known Issue

1. **Confirm** the issue matches the known issue description
1. **Note** it in the test results (no fix needed, already tracked)

## Phase 4: Update UAT Coverage

After all findings are processed:

1. **Update `docs/testing/UAT_COVERAGE.md`**:

   - Set the test case **Status** to: Pass (all criteria met) / Fail (any criteria failed and unfixed) / Pass (if all failures were fixed during this cycle)
   - Set **Tested On** to today's date
   - Add **Findings** notes summarizing what was found and done
   - Update the **Status Summary** table at the top of the file
   - Check/uncheck the acceptance criteria checkboxes based on results

1. **Update acceptance criteria checkboxes**:

   - `[x]` for criteria that passed
   - `[ ]` for criteria that still fail (with a note explaining why)

## Phase 5: Close Cycle

### Run verification

1. Run the project's test command (from CLAUDE.md) to confirm all automated tests still pass

### Commit changes

If any code was changed during this cycle:

1. Stage relevant files
1. Commit with: `test(UAT): <test-case-id> — <summary of findings>`
1. Include fixes in the commit or as separate commits with proper conventional format

### Completion Report

```markdown
### UAT Cycle Complete

**Test Case:** UAT-### — [title]
**Result:** Pass / Fail / Partial
**Acceptance Criteria:** [x/y] passed
**Findings:**
- [summary of each finding and action taken]

**Files Modified:** [list]
**Commits:** [hash(es) and message(s)]
**Backlog Items Created:** [story IDs if any gaps were logged]

**Next:** Select another test case (`/UAT-cycle <id>`) or finish testing session.
```

## Rules

- NEVER skip presenting the test case to the user first
- NEVER auto-pass acceptance criteria — only the user can confirm pass/fail
- ALWAYS update the UAT coverage file after each cycle
- ALWAYS commit code changes with proper conventional format
- Log gaps to the appropriate backlog file, not as inline TODOs
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
