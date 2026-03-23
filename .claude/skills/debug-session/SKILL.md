---
name: debug-session
version: 2.9.0
description: Use when the user reports a bug, error, or unexpected behavior that needs investigation.
trigger: manual
depends-on: []
references: [references/root-cause-tracing.md, references/condition-based-waiting.md, references/error-recovery.md]
micro-components:
  phase-4: [record-failure]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, WebSearch
argument-hint: "[error-description]"
---
______________________________________________________________________

## debug-session

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"debug-session\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

Debug session for: **$ARGUMENTS**

## Failure State Persistence

At each phase transition, write `docs/sessions/.failure-state.md` with YAML frontmatter so the Stop hook and `/continue` can programmatically detect incomplete workflows.

**At workflow start** (Phase 1 entry):

```yaml
---
status: active
skill: debug-session
phase: "1"
phase_name: "Root Cause Investigation"
started_at: "[ISO-8601 timestamp from date -u +%Y-%m-%dT%H:%M:%SZ]"
story: "[from $ARGUMENTS — the error description]"
branch: "[from git branch --show-current]"
next_action: "Reproduce error and trace root cause"
files_modified: []
---

## Context
Error: [error description]
Root cause: not yet identified
Hypothesis: none
Fix attempts: 0
Files investigated: [list as investigation proceeds]
```

**At each phase transition:** Update the frontmatter fields: `phase`, `phase_name`, `next_action`, and append to `files_modified`. Update the Context section with investigation progress (root cause, hypothesis, fix attempts).

**On successful fix (Phase 5 complete):** Delete `.failure-state.md` — clean state means no failure to recover from.

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

Apply the `failure_diagnosis` reasoning tool from `.claude/skills/story-cycle/references/reasoning-tools.md`:

1. Read the FULL error output — every line, including stack trace and surrounding context
2. Identify: what was expected vs. what actually happened
3. Trace backward: which function produced the wrong result? What were its inputs?
4. If inputs are correct: the bug is in this function — inspect its logic
5. If inputs are wrong: trace one level further back — where do those inputs come from?
6. Repeat until you find the point where correct data becomes incorrect

For multi-component systems, trace across component boundaries — check API calls, database queries, event handlers.

See `references/root-cause-tracing.md` — search for `## Steps` for the detailed backward trace procedure.

<HARD-GATE>
Do NOT attempt any fix until the root cause is identified with evidence. "I think it might be X" without evidence is NOT identification. Show: where the bug is, why it happens, and what incorrect state or logic causes it.
</HARD-GATE>

**DO / DON'T:**
- DO trace backward from the symptom to the source before forming a hypothesis.
- DON'T jump to a fix based on the error message alone — the message describes the symptom, not the cause.
- DO add temporary logging to confirm data flow before changing logic.
- DON'T change multiple things at once hoping one will fix it.

## Phase 2: Pattern Analysis

1. Find a WORKING example of similar functionality in the codebase
2. Compare the working example against the broken code line by line
3. Identify specific differences — which difference explains the bug?
4. Understand the dependency chain — are all dependencies correct and available?

### 2b. Search for Known Issues (Optional)

<IF condition="error involves a third-party dependency or library">
Search for known issues before deep analysis — someone may have already solved this:

1. Identify the dependency name and version from `package.json`, `requirements.txt`, or equivalent
2. Use WebSearch to search for: `"[dependency] [error message or key phrase]"`
3. If a known issue or fix is found, verify it applies to your version and context
4. If no results: proceed to Phase 3 — the bug is likely project-specific
</IF>

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

<HALT reason="exceeded fix attempts">
After 3 failed fix attempts: STOP. Return to Phase 1 and re-trace from scratch. The root cause identification was likely wrong. Consult `references/error-recovery.md` — search for `## Phase 3`.
</HALT>

See `references/condition-based-waiting.md` — search for `## Patterns by Language` and load only your language's section.

## Phase 4: Fix Implementation (TDD)

1. Write a test that reproduces the bug (MUST fail before fix)
2. Verify the test fails for the RIGHT reason (matches reported behavior)
3. Implement the MINIMAL fix — change as little as possible
4. Verify the reproduction test passes
5. Run the FULL test suite for regressions

## Phase 4.5: Error Learning

If the root cause was initially misdiagnosed or the fix required changing approach, invoke the `record-failure` micro-component from `.claude/prompts/record-failure.md` to record the pattern in `docs/context/error-patterns.md`. This helps future sessions avoid the same diagnostic mistakes.

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

## Example

```
Input:  /debug-session "TypeError: Cannot read properties of undefined (reading 'map')"
Output: Phase 1 → traced to `fetchUsers()` returning `undefined` when API returns 404
        Phase 3 → hypothesis: missing error handling for non-200 responses
        Phase 4 → added guard clause + regression test
        Phase 5 → commit: "fix(api): handle non-200 response in fetchUsers"

Next Steps:
→ /story-cycle "[next story]" — continue with the next story
→ /sprint-end — if the fix was the last item in the sprint
→ /handoff — if ending the session
```

## Recovery

For phase-specific error recovery, consult `references/error-recovery.md` — search for the relevant `## Phase N` section.

General recovery:

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
