# Error Recovery — /live-test

Phase-specific failure handling. Find your phase, find the error, apply the recovery.
Universal rule: a scenario that cannot be executed after one recovery attempt is
BLOCKED (not FAIL) — record why in the findings file and move on; never let one
scenario kill the run.

## Phase 0: Prerequisites

| Error | Cause | Recovery |
|-------|-------|----------|
| `docs/testing/APP_MAP.md` missing | First run in this project | Offer the first-run interview (`references/first-run.md`) — never scaffold silently |
| App map declares `surface: none` | Project has no runnable surface (library) | Report: dynamic testing not applicable — route to `/quality-check` (test suite) and `/manual-test`; stop |
| Preflight check fails | Service/stack not running | Offer the failing check's remedy command from the app map, re-run preflight (max 2 remediation rounds, then HALT with the summary) |
| Browser MCP tools not found (web surface) | Playwright/Chrome DevTools MCP not installed | Do NOT halt: produce the plan as a `/manual-test`-style checklist for the user; suggest `claude mcp add playwright -- npx @playwright/mcp@latest` |
| Preflight passes with warnings | Optional dependency down (map marks it optional) | Ask user: run the unaffected subset (mark affected scenarios BLOCKED), or stop |
| Credentials env var unset | Test-account password/token not exported | Show the env var name from the app map, ask user to set it; never proceed with guessed or default credentials |

## Phases 3–4: Execution

| Error | Cause | Recovery |
|-------|-------|----------|
| Element ref not found / stale (web) | Page changed since snapshot | Re-snapshot, re-locate by role/text, retry once. Twice failed → BLOCKED, move on |
| Wait timeout | Known flake (map § Known issues) OR real failure | Apply the map's retry policy for that flake (typically retry once); persistent → FAIL with evidence |
| Blank page / connection refused mid-run | App crashed or JS boot error | Check console/server log — that error IS the finding; re-run preflight before continuing |
| Browser session hangs / tools stop responding | MCP session corrupted | Close the browser, start a new session; re-run the interrupted scenario from its start |
| Unhandled native dialog blocks actions (web) | Confirm/alert not handled | Handle the dialog (accept/dismiss per scenario intent), continue |
| Auth rejected after account switch | Stale token/cookie/state | Clear session state per the app map's logout recipe, re-authenticate |
| Scenario needs data that doesn't exist | Stack not seeded for this scope | Run the app map's seed commands for the scope (if declared), else test against existing data and note empty-state coverage |

## Phase 5: Fix loop

| Error | Cause | Recovery |
|-------|-------|----------|
| Cannot reproduce the live failure in an automated test | No test harness for that layer (map § Harness facts) | The re-run probe IS the regression check — fix, re-verify live, note "no automated test — harness absent" in the finding |
| Fix attempt makes other tests fail | Fix is wrong or collides with existing behavior | Revert (`git restore <files>`), reclassify as Gap, hand off via `/ideate` |
| Root cause is in a `ready`/`in-review` story's scope | Known gap, already planned | Do NOT fix. Classify as Known Issue, reference the story ID |
| 3 fix attempts exhausted | Too deep for this run | HALT the loop: revert uncommitted changes, reclassify as Gap, `/ideate` handoff with root-cause notes and repro steps |

## Phase 6: Reporting

| Error | Cause | Recovery |
|-------|-------|----------|
| `docs/testing/findings/` write fails | Directory missing | `mkdir -p docs/testing/findings/assets` |
| Run interrupted mid-execution | Context loss / user interrupt | The findings file is written incrementally — completed scenario verdicts are already on disk; set frontmatter `status: interrupted`, list un-run scenarios in the `Scenarios not run` field under `## Results summary`, stop cleanly |
| Resuming an interrupted run | Prior run's findings file has `status: interrupted` | Re-run preflight, then continue from the first scenario not recorded in that file (append to the SAME file; new sessions for a new scope get a new file) |
