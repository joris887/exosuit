# Self-Review Checklist

Reference loaded by `/story-cycle` Phase 3.5. Complete before proceeding to Phase 4.

## Completeness
- [ ] Every acceptance criterion has been implemented
- [ ] Every acceptance criterion has a corresponding test
- [ ] No "TODO" or "FIXME" left in new code (unless explicitly deferred)

## Quality
- [ ] New code follows patterns found in existing codebase
- [ ] No unnecessary features added beyond acceptance criteria (YAGNI)
- [ ] Error handling covers realistic failure modes

## Testing
- [ ] All tests pass — run the test command and show output (not from memory)
- [ ] Tests are meaningful — would fail if implementation was naive
- [ ] Edge cases from planning phase are covered

## Discipline
- [ ] Did not weaken or delete any existing tests
- [ ] Did not add dependencies without noting them
- [ ] Implementation matches the approved plan

## Spec Compliance (for stories with 4+ acceptance criteria)

For each acceptance criterion:
1. Re-read the criterion text from the plan
2. Find the code that implements it (cite file:line)
3. Find the test that verifies it (cite file:line)
4. Confirm they match — do NOT rely on memory, re-read the plan and the code

## Red Flags — Stop If You're Thinking:

| Rationalization | Why It's Wrong | Correct Action |
|----------------|----------------|----------------|
| "The tests probably pass, I'll commit" | "Probably" is not evidence | Run the test command, show output |
| "This is a small change, no need for TDD" | Small changes cause big regressions | Write the test first |
| "I already verified this earlier" | Earlier is not fresh evidence | Re-run verification now |
| "The user wants this done fast, skip review" | Fast now = rework later | Complete the self-review |
| "Close enough to the acceptance criteria" | Close is not done | Implement exactly what was specified |

If any checklist item fails, go back to Phase 3 and fix the issue before proceeding.
