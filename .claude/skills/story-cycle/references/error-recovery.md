# Error Recovery by Phase

Phase-specific recovery tables for story-cycle. When an error occurs, find the current phase and look up the recovery action.

______________________________________________________________________

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
| External library error (any type) | Version mismatch, deprecated API, known bug | **Web search first:** `WebSearch` for `"<library> <version> <error snippet>"`. Check GitHub issues and changelogs before guessing at a fix. 60s max. |
| Unfamiliar framework behavior | Assumed behavior from training data | **Web search:** Fetch the official docs for the pinned version. Training data may be stale — verify the actual API contract. |
| TDD test is impossible to make green | Test design was wrong, not implementation | Re-read the acceptance criterion. The test may be testing the wrong behavior. Rewrite the test to match the actual requirement, then implement |
| Characterization test captures buggy behavior | Testing existing bug as if correct | Compare test expectations against the story's intended behavior. If the "current behavior" IS the bug, adjust the characterization test to expect the CORRECT behavior after refactoring |
| No quality commands configured at all | Project lacks lint, typecheck, and test | Note in plan and completion report. Suggest creating a foundation story to set up tooling. Proceed with manual review only |

## Phase 4a: Self-Review Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Quality agent reports critical finding | Real issue caught in review | Fix before proceeding — do NOT defer critical findings |
| Quality agent unavailable | Sub-agents not supported in environment | Complete self-review checklist manually; do NOT skip quality checks |
| Checklist item fails | Incomplete or incorrect implementation | Loop back to Phase 3 for the specific failing item |

## Phase 4b: Quality Gate Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Lint/format fails after edit | Style violations in new code | Run auto-fix first; manual fix only for logic-related lint errors |
| Pre-commit hook blocks commit | Quality gate or format failure | Read hook output fully; fix the identified issue; do NOT use `--no-verify` |
| Commit message rejected | Wrong conventional format | Check `.claude/rules/git.md` for format; regenerate message |
| Test suite fails on final run | Regression introduced during implementation | Re-read failing test output; trace to the specific change that broke it |

## Phase 4d: Completion Verification Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Acceptance criterion has no evidence | Implementation missed a requirement | Loop back to Phase 3 for that specific criterion (max 2 extra passes) |
| Evidence is stale (from earlier in session) | Tests not re-run after later changes | Re-run the test suite fresh; show current output |
| Max retry loops (2) exhausted | Story is larger than estimated | Report what IS complete with evidence; list remaining gaps; suggest continuing in next session |

## Phase 1c.5: Online Verification Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| WebSearch returns no results | Query too specific or service unavailable | Broaden search terms; try alternative phrasing. If service is down, note "Research: web unavailable" and proceed with codebase-only evidence |
| WebFetch fails or times out | URL unreachable or rate limited | Try alternative sources from search results. If all fail, note in Research Decision with reduced confidence score |
| Conflicting sources found | Different docs/articles disagree | Note BOTH positions in the Research Decision block with source URLs. Flag to user for judgment call |
| Research takes >2 minutes | Over-researching, too many sub-questions | Stop. Summarize what you have. Mark confidence as lower. Proceed — don't spiral |

## Phase 1c.5+: Dependency Freshness Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| CVE found for a dependency | Known vulnerability in a library the story uses | Flag to user IMMEDIATELY. This may change story scope or require a dependency upgrade first |
| Deprecation notice for API used | Library has deprecated the API the story plans to use | Update plan to use the recommended replacement API. Note in Research Decision |

## Phase 1d.5: Discovery Gate Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| User unavailable for clarification | Cannot resolve unknowns interactively | Document the unknowns as explicit assumptions in the plan with [ASSUMPTION: ...] markers. Proceed, but flag for user review at plan approval |
| User answers contradict codebase | User's understanding differs from code reality | Show the user the specific code evidence. Ask which is correct — the code or their expectation |

## Phase 1d.7: Story Refinement Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Gap analysis reveals story is unfeasible | Prerequisites missing, dependencies not met | Flag to user. Suggest: (a) create prerequisite stories first, or (b) reduce story scope to what IS feasible |
| Forward context conflicts with existing stories | Related stories in the epic have contradictory assumptions | Flag the conflict. Let user decide which story's assumptions take precedence. Update the other story's notes |

## Phase 3a: Parallel Stream Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Merge conflict between streams | File overlap not detected during analysis | Resolve conflicts manually in the main worktree. Re-run tests after merge |
| Agent fails mid-stream | Sub-agent error or context exhaustion | Merge what succeeded. Continue remaining work serially in the main worktree |
| Worktree creation fails | Git state issue or permissions | Fall back to serial Phase 3 execution. Note in completion report |

## Phase 3.pre: Git Checkpoint Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Tag creation fails | Detached HEAD or permission issue | Try `git stash` as alternative checkpoint. Record stash ref in .failure-state.md instead of tag |
| .failure-state.md not writable | Directory missing or permissions | Create `docs/sessions/` directory. If still fails, proceed without checkpoint — note the risk |

## Phase 4c: UAT Generation Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| UAT directory structure unexpected | Non-standard project layout | Search for any test case files (*.yaml, *.md in test directories). Adapt to whatever convention exists |
| UAT numbering inconsistent | Gaps or duplicates in existing IDs | Find the highest existing number, increment by 1. Do not try to fill gaps |

## Phase 4e: Docs + Commit Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Epic file not found | Wrong path or file renamed | Search for the epic file by story ID using Grep. If truly missing, note in completion report and skip epic update |
| BACKLOG_INDEX.md format unexpected | Template was modified | Read the actual format, adapt the update to match. Do not force the template format |
| /commit skill fails | Pre-commit hook failure or git state issue | Read the hook output. Fix the issue (usually formatting or lint). Retry the commit. Do NOT use --no-verify |
| Activity log not writable | docs/sessions/ missing | Create the directory. If still fails, skip metric logging — it's advisory, not critical |
