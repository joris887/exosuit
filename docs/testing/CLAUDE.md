# Testing Documentation

UAT (User Acceptance Testing) tracking and test case management.

## Files
- `UAT_COVERAGE.md` — master UAT test case registry with pass/fail status

## How It Works
- `/claude-sense-check` generates UAT test cases from stories
- `/UAT-cycle <test-case-id>` executes individual test cases
- `/manual-test` creates manual test plans for non-automatable scenarios
- Results tracked in `UAT_COVERAGE.md` with evidence links

## Conventions
- Test cases follow the format: Given/When/Then
- Each test case has a unique ID for traceability
- Link test results to specific commits or sprint outputs
