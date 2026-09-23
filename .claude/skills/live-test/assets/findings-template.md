---
skill: live-test
scope: {{scope}}
surface: {{surface name(s)}}
toolkit: {{playwright-mcp | chrome-devtools-mcp | curl | shell}}
data_environment: {{disposable | shared (MUTATION LOCK — read-only run)}}
fix_authorized: {{yes (--fix) | no (report-only)}}
run_id: {{YYYY-MM-DDTHH-MM-SSZ}}
duration: {{minutes — fill at run end}}
status: in-progress
summary: {scenarios: 0, passed: 0, failed: 0, blocked: 0, fixed_in_session: 0}
accounts_swept: []
---

# /live-test findings — {{scope}} ({{date}})

<!-- Created right after plan approval; each scenario's verdict is APPENDED as it
     completes, so an interrupted run leaves a usable scoreboard on disk.
     Set frontmatter status to complete|interrupted when the run ends. -->

## Environment

<!-- One row per preflight check, from the preflight output -->
| Check | Status |
|-------|--------|
| {{label}} | {{pass/fail/warn}} |

## Failure patterns

<!-- Only if ≥2 failures share a symptom. One /ideate line per pattern, not per scenario:
     - **<pattern-id>** — scenarios: S1, S4
       - symptom / hypothesis / fix hint
       - → /ideate "<scope>: <pattern>" — <one-line story seed> -->

## Main pass ({{account or "unauthenticated"}})

### S1 — {{scenario name}} ({{PASS|FAIL|BLOCKED|FIXED}})

- **Target:** {{route / endpoint / invocation}}
- **Steps:** {{compressed action list}}
- **Expected:** {{expected result}}
- **Signals:** {{signal 1: …}} · {{signal 2: …}} · {{signal 3: …}}
- **Evidence:** {{path under assets/<run-id>/ | "none (pass)"}}
- **Classification:** {{— | Bug (Critical) | Bug (Minor) | Gap | Known Issue (ref) | Enhancement}}
- **Action:** {{— | fixed in session (commit <hash>) | handed off below | logged}}

## Role sweep

### S{{n}} — {{scenario}} as {{account}} ({{PASS|FAIL|BLOCKED|FIXED}})

- **Positive check:** {{what the role should be able to do}} → {{result}}
- **Negative check:** {{what the role must NOT be able to do}} → {{result: hidden / 403 / refused}}
- **Signals:** {{…}}

## Fixes applied this session

<!-- Populated only when the run was invoked with --fix; otherwise every Critical
     is a handoff line below and this table stays empty. -->
| # | Scenario | Root cause | Fix | Tests | Commit | Live re-verify |
|---|----------|-----------|-----|-------|--------|----------------|

## UAT cases executed

<!-- Results rows were appended to docs/testing/UAT_COVERAGE.md with
     Verified By = "Claude (live-test)". Human UAT Check boxes untouched —
     list the cases here so the user can confirm pass/fail per UAT-cycle rules. -->
| Case | Result row appended | Needs human confirmation |
|------|---------------------|--------------------------|

## Redaction

<!-- MANDATORY before committing this file or its assets. The framework's secrets
     scanner does NOT inspect .md/.txt (post-edit-format.sh skip list) — this
     self-check is the only gate. 1) Replace every Authorization/Cookie/Set-Cookie
     value, token, session ID, and JWT with [REDACTED]. 2) Run:
       grep -rnEi -e 'authorization[": ]*[:=]' -e 'set-cookie' \
         -e '(api[_-]?key|secret|token|passw)[a-z_]*["'\'' ]*[:=]' \
         -e 'sk-[A-Za-z0-9_-]{20,}' -e 'eyJ[A-Za-z0-9_-]{10,}\.eyJ' \
         docs/testing/findings/<this-file> docs/testing/findings/assets/<run-id>/
     3) Every hit must be [REDACTED] or a false positive you can name here. -->
- Self-check run: {{clean | N hits scrubbed}}

## Handoff

<!-- One arrow line per unfixed finding, ready to run: -->
<!-- → /testing-cycle "<finding>" — process this bug -->
<!-- → /ideate "<gap or enhancement>" — create a story -->

## Results summary

- **Passed:** {{n}} / **Failed:** {{n}} / **Blocked:** {{n}} / **Fixed in session:** {{n}}
- **Scenarios not run:** {{none | list — set status: interrupted}}
