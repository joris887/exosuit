# Error Recovery by Phase

Phase-specific recovery tables for story-cycle. When an error occurs, find the current phase and look up the recovery action.

---

## Phase 0: Intent Decomposition Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| User request is vague or single-word | Insufficient context to decompose | Ask 1-2 clarifying questions; do NOT guess scope |
| Scope has 5+ independent deliverables | Request is a project, not a story | Suggest running `/ideate` first to create proper stories |
| Cannot determine dependencies | Deliverables are loosely related | List them as independent; let user confirm ordering |

## Phase 1: Planning Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| No relevant code found during exploration | Wrong search terms or greenfield story | Broaden search patterns; if truly greenfield, note in plan as new files |
| Too many files affected (>8) | Story scope too large | Suggest splitting to user before writing plan |
| User rejects plan | Misunderstood requirements or wrong approach | Ask WHAT specifically to change; revise only those sections, don't rewrite |
| Cannot determine story type | Ambiguous request | Ask user to clarify: is this a feature, bug fix, or refactoring? |
| Explore agent returns no results | Sub-agent context issue or wrong query | Fall back to manual exploration; search imports and directory structure |

## Phase 2: Context Transition Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Plan lost after compaction | Plan was too long for context | Re-read from `docs/plans/` if persisted; otherwise re-enter plan mode |
| Cannot find files listed in plan | Files renamed or deleted since planning | Re-run file discovery; update plan paths before executing |

## Phase 3: Execution Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Test fails after 3 fix attempts | Likely wrong approach, not wrong fix | STOP. Re-read the test AND the code under test. Verify the test itself is correct |
| Import/module not found | Hallucinated dependency or wrong path | Search codebase for actual module name with Grep; NEVER guess import paths |
| Type error in unfamiliar API | Guessed API shape instead of reading it | Read the actual type definitions or source; NEVER assume API signatures |
| Test passes but behavior is wrong | Test is tautological or testing the mock | Re-read test against self-review checklist; ensure it tests real behavior |
| Build/compile error | Missing dependency or wrong syntax | Read the full error; check package.json/requirements.txt; do NOT add phantom packages |
| Pre-existing test breaks | Unintended side effect of new code | Understand WHY it broke; fix the root cause, don't patch the symptom |

## Phase 3.5: Self-Review Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Quality agent reports critical finding | Real issue caught in review | Fix before proceeding — do NOT defer critical findings |
| Quality agent unavailable | Sub-agents not supported in environment | Complete self-review checklist manually; do NOT skip quality checks |
| Checklist item fails | Incomplete or incorrect implementation | Loop back to Phase 3 for the specific failing item |

## Phase 4: Wrap-Up Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Lint/format fails after edit | Style violations in new code | Run auto-fix first; manual fix only for logic-related lint errors |
| Pre-commit hook blocks commit | Quality gate or format failure | Read hook output fully; fix the identified issue; do NOT use `--no-verify` |
| Commit message rejected | Wrong conventional format | Check `.claude/rules/git.md` for format; regenerate message |
| Test suite fails on final run | Regression introduced during implementation | Re-read failing test output; trace to the specific change that broke it |

## Phase 4.5: Completion Verification Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Acceptance criterion has no evidence | Implementation missed a requirement | Loop back to Phase 3 for that specific criterion (max 2 extra passes) |
| Evidence is stale (from earlier in session) | Tests not re-run after later changes | Re-run the test suite fresh; show current output |
| Max retry loops (2) exhausted | Story is larger than estimated | Report what IS complete with evidence; list remaining gaps; suggest continuing in next session |
