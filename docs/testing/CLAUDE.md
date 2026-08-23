# Testing Documentation

## Files
- `UAT_COVERAGE.md` — master UAT test case registry with pass/fail status
- `APP_MAP.md` — project facts for `/live-test` (surfaces, accounts, preflight checks); scaffolded on first run
- `findings/` — append-only `/live-test` run reports (+ `findings/assets/<run-id>/` evidence)

## How It Works
- `/story-cycle` Phase 4c creates UAT test cases from stories; `/claude-sense-check` verifies their logic against code
- `/UAT-cycle <test-case-id>` executes individual test cases with the user
- `/live-test <scope>` executes tests autonomously against the running app; appends `Claude (live-test)` result rows (human confirmation stays with `/UAT-cycle`)
- `/manual-test` creates manual test plans for non-automatable scenarios
- Results tracked in `UAT_COVERAGE.md` with evidence links

## Conventions
- Test cases follow the format: Given/When/Then
- Each test case has a unique ID for traceability
- Link test results to specific commits or sprint outputs
