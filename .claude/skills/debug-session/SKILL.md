---
name: debug-session
version: 2.4.0
description: Use when the user reports a bug, error, or unexpected behavior that needs investigation.
trigger: manual
depends-on: []
references: [references/root-cause-tracing.md, references/condition-based-waiting.md]
---
______________________________________________________________________

## name: debug-session description: Use when the user reports a bug, error, or unexpected behavior that needs investigation. argument-hint: [error-description] disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash

Debug session for: **$ARGUMENTS**

## Phase 1: Root Cause Investigation (MANDATORY)

Do NOT skip this phase. Do NOT jump to a fix.

### 1a. Understand the Error

- Read the FULL error message — every line, including stack trace
- What is the exact error? (copy it verbatim)
- Where does it occur? (file:line from stack trace)
- When does it occur? (always, intermittently, under specific conditions)

### 1b. Reproduce Consistently

Run the relevant test or command to reproduce:

```bash
# Run the failing test or trigger the error
```

If it cannot be reproduced, gather more context before proceeding.

### 1c. Check Recent Changes

```bash
git log --oneline -10
git diff HEAD~3
```

Did a recent change introduce this? Use `git bisect` for non-obvious regressions.

### 1d. Trace Backward from Symptom

Start at the error location and trace BACKWARD through the call stack:

1. Where does the error occur? (file:line)
2. What function called that code? (one level up)
3. What data was passed to that function? (add logging if needed)
4. Where does that data originate? (trace to source)
5. At which point does the data become incorrect?

For multi-component systems, trace across component boundaries — check API calls, database queries, event handlers.

See `references/root-cause-tracing.md` for detailed backward tracing technique.

<HARD-GATE>
Do NOT attempt any fix until the root cause is identified with evidence. "I think it might be X" without evidence is NOT identification. You must show: where the bug is, why it happens, and what incorrect state or logic causes it.
</HARD-GATE>

## Phase 2: Pattern Analysis

1. Find a WORKING example of similar functionality in the codebase
2. Compare the working example against the broken code line by line
3. Identify specific differences — which difference explains the bug?
4. Understand the dependency chain — are all dependencies correct and available?

## Phase 3: Hypothesis and Testing

### Form a Single Hypothesis

Based on evidence from Phases 1-2, state:
- **Hypothesis:** "The bug is caused by [specific cause] because [evidence]"
- **Prediction:** "If I change [specific thing], the error should [specific expected change]"

### Test Minimally

- Change ONE variable at a time
- Run the reproduction command after each change
- If the hypothesis is wrong, REVERT the change and form a new hypothesis

### Stopping Points — STOP If:

| Situation | Action |
|-----------|--------|
| 3+ fix attempts have failed | STOP. Question the approach. Are you fixing the right thing? |
| "Just try X and see if it works" | STOP. Form a hypothesis first. |
| Making multiple changes at once | STOP. One variable at a time. |
| "It's probably X" without evidence | STOP. Gather evidence. |
| Fix works but you don't understand why | STOP. Understand before committing. |

See `references/condition-based-waiting.md` for fixing timing-related bugs.

## Phase 4: Fix Implementation (TDD)

1. Write a test that reproduces the bug (MUST fail before fix)
2. Verify the test fails for the RIGHT reason (matches reported behavior)
3. Implement the MINIMAL fix — change as little as possible
4. Verify the reproduction test passes
5. Run the FULL test suite for regressions

## Phase 5: Verify and Document

- [ ] All tests pass (show output)
- [ ] The original error is no longer reproducible
- [ ] The fix addresses the root cause, not just the symptom
- [ ] Commit message explains what caused the bug and why

```bash
git add <files>
git commit -m "fix(<scope>): <what was fixed>

Root cause: <explanation>

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Recovery

- **Cannot reproduce:** Gather more context. Check environment differences. Ask user for exact reproduction steps.
- **Root cause unclear after investigation:** Document findings so far. Ask user for additional context. Do NOT guess.
- **Fix introduces new failures:** Revert the fix. The original bug is better than two bugs.
- **Timing/race condition:** See `references/condition-based-waiting.md`. Replace arbitrary sleeps with condition polling.

## Rules

- NEVER apply a fix without understanding the root cause
- NEVER make multiple changes at once — one hypothesis, one change, one verification
- NEVER weaken or delete tests to make them pass
- NEVER say "it should work now" without showing test output
- If 3+ fixes fail, STOP and discuss the approach with the user
