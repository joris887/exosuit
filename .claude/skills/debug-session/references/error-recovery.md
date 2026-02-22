# Error Recovery by Phase

Phase-specific recovery tables for debug-session. When an error occurs during debugging, find the current phase and look up the recovery action.

---

## Phase 1: Root Cause Investigation Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Cannot reproduce the error | Environment difference or intermittent bug | Gather exact reproduction steps from user; check environment variables, dependencies, OS |
| Stack trace points to library code | Bug may be in how the library is called, not the library itself | Trace to the last application code in the stack; inspect the call site |
| Error message is generic (e.g., "undefined") | Multiple possible causes | Add temporary logging at suspected locations; narrow down before hypothesizing |
| `git bisect` inconclusive | Error is not regression-related | Abandon bisect; focus on data flow tracing instead |
| Error only occurs in production/CI | Environment-specific issue | Compare environment configs; check for race conditions, missing env vars, different versions |

## Phase 2: Pattern Analysis Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| No working example exists | This is the first implementation of this pattern | Skip pattern analysis; rely on Phase 1 trace and documentation |
| Working example differs too much | Not a valid comparison | Find a closer example or compare against the documented API/interface contract |

## Phase 3: Hypothesis and Testing Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Hypothesis was wrong | Misidentified root cause | REVERT the change; return to Phase 1 with new information |
| Fix works but you don't understand why | Coincidental fix, not root cause fix | STOP. Understand the mechanism before committing; an unexplained fix may mask the real bug |
| 3+ fix attempts have failed | Wrong root cause or wrong level of abstraction | STOP. Go back to Phase 1. Re-trace from scratch — the root cause identification was likely wrong |
| Fix causes new test failures | Side effects of the change | The fix is too broad; narrow it to affect only the buggy code path |

## Phase 4: Fix Implementation Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Reproduction test doesn't fail (before fix) | Test doesn't actually reproduce the bug | Rewrite the test to match the exact error conditions; verify it fails for the RIGHT reason |
| Reproduction test still fails after fix | Fix is incomplete or wrong | Re-read the test output; compare expected vs actual; refine the fix |
| Full test suite has new failures | Fix introduced regressions | Revert the fix; the original bug is better than two bugs |

## Phase 5: Verify and Document Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Original error reappears after fix | Fix addressed a symptom, not root cause | Return to Phase 1; the trace was insufficient |
| Commit fails pre-commit hooks | Format or lint issues in fix | Auto-fix first; manual fix for logic-related issues; do NOT use `--no-verify` |
