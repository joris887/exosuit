______________________________________________________________________

## name: testing-cycle description: Process a single user testing feedback item — classify, fix or log, verify, and report. argument-hint: <feedback-description> disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Processing feedback: **$ARGUMENTS**

## Phase 1: Classify Feedback

Analyze the feedback and assign a classification:

| Type            | Indicators                                           | Effort  |
| --------------- | ---------------------------------------------------- | ------- |
| Bug (Critical)  | Functionality broken, crash, data loss, core feature | High    |
| Bug (Minor)     | UI glitch, cosmetic, edge case, non-blocking         | Low     |
| Gap             | Missing feature, expected capability not implemented | Backlog |
| Test Correction | Automated test tests wrong behavior, false positive  | Medium  |
| Enhancement     | UX improvement, better wording, nice-to-have         | Varies  |

**Present the classification to the user for confirmation before proceeding.**

Show:

- **Feedback**: (original, quoted)
- **Classification**: \[type\]
- **Rationale**: (why this classification)
- **Proposed action**: (what will be done)

Wait for user confirmation. They may reclassify.

## Phase 2: Act by Type

### Bug (Critical)

1. **Investigate**: Find relevant code, understand the root cause
   - Search for related files using the feedback keywords
   - Read the relevant source files
   - Check if there's an existing test covering this behavior
1. **Test first**:
   - If a test exists but tests the wrong thing → fix the test first (it should now fail)
   - If no test exists → write a failing test that captures the bug
   - Run the test to confirm it fails
1. **Fix the code**: Make the minimal change to fix the bug
1. **Verify tests pass**: Run the project's test command (from CLAUDE.md)
1. **Ask user to verify**: "Can you verify this fix in the running app?"
1. **Commit**: `fix(scope): description`

### Bug (Minor)

1. **Identify** the issue in code
1. **Fix** the code (minimal change)
1. **Add test** only if the behavior is non-trivial or regression-prone
1. **Run** the project's test command
1. **Commit**: `fix(scope): description`

### Gap

1. **Document** the gap clearly
1. **Write a user story** with:
   - Type, estimated effort
   - Description explaining what's missing and why it matters
   - INVEST-style acceptance criteria
   - Technical notes if relevant
1. **Add to** the appropriate backlog file in `docs/reference/backlog/`:
   - Add the story section (use next available story number)
   - Update the summary table
1. **Update** `docs/reference/BACKLOG_INDEX.md` if a new story was added
1. **Do NOT implement** — this is scope control
1. **Report** what was logged

### Test Correction

1. **Find** the problematic test
1. **Understand** the correct behavior from user feedback
1. **Fix the test** to match correct behavior
1. **Run the corrected test** — if it now fails, also fix the code
1. **Run** the project's test command
1. **Commit**: `test(scope): correct [description]` (add `fix` prefix if code also changed)

### Enhancement

1. **Evaluate scope**:
   - Trivial (< 10 lines, obvious improvement) → ask user if should fix now
   - Larger → create backlog story (same process as Gap)
1. **Act accordingly**:
   - If fixing now: implement, test, commit as `feat(scope):` or `fix(scope):`
   - If deferring: log to backlog and report

## Phase 3: Verify

After any code change:

1. Run the project's test command (from CLAUDE.md) to verify all tests pass
1. If the app is running, ask the user: "Can you verify this in the running app?"
1. If tests fail, fix the issue before proceeding

## Phase 4: Report

Present a summary:

```markdown
### Feedback Processed

**Feedback:** [original feedback]
**Classification:** [type]
**Action taken:** [what was done]
**Files modified:** [list of files]
**Tests:** [added/modified/none] — tests [pass/fail]
**Commit:** [hash and message] (or "logged to backlog as [story-ID]" for gaps)

Ready for next feedback item (`/testing-cycle <feedback>`) or finish testing.
```
