---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/test_*"
  - "**/tests/**"
  - "**/conftest.py"
  - "**/__tests__/**"
---

# Test File Rules

- **Every acceptance criterion must have at least one test that would fail if the AC is not met.** This is the load-bearing rule in v5.0 — quality is "outcomes covered by tests," not "number of tests."
- Never weaken assertions (e.g., replacing `toBe(42)` with `toBeTruthy()`)
- Never delete a test without showing one of: (a) it was tautological/trivial, OR (b) the AC it covered is also gone, OR (c) another test now covers the same AC
- Never replace real assertions with no-op or trivially-passing checks
- Tests must test behavior, not implementation details
- Mocks should mock external services only, never internal logic
- Every test must have at least one meaningful assertion; aim for ≥3 per test method
- Expected values must be hardcoded from domain knowledge, never computed using production logic
- Test names must describe the OUTCOME being tested, mapped to an AC: `test_user_can_<observable_outcome>_when_<condition>`
- Structure tests as Arrange/Act/Assert (or Given/When/Then), separated by blank lines
- Act section: 1-3 lines — if longer, the test is testing too much
- Follow patterns in `docs/reference/TESTING_STRATEGY.md`

## Anti-Patterns

| Pattern | Detection Signal | Correct Action |
|---------|-----------------|----------------|
| Tautological tests | Always pass regardless of implementation | Delete and write a test that can actually fail |
| Happy-path-only coverage | Missing error cases and edge cases | Add failure, boundary, and error-state tests |
| Over-mocking | Mocking so much the test verifies nothing real | Mock only external services, not internal logic |
| Testing the mock | Assertions on mock return values | Assert on real behavior from the caller's perspective |
| Catch-all exception handlers | `try/catch` swallows real failures | Let unexpected exceptions fail the test |
| Hallucinated test APIs | Test calls methods that don't exist on the object | Run the test immediately after writing — don't batch |
| Copy-paste assertion drift | Multiple similar tests with subtly wrong expected values | Review each test's expected value against the actual domain |
| Weakened assertions to pass | Changed `toBe(42)` to `toBeTruthy()` to make a test pass | Fix the implementation, not the test |
| Over-specific snapshot tests | Snapshot includes timestamps, random IDs, or formatting | Use targeted assertions instead of snapshots for dynamic content |
| Testing framework internals | Assertions on framework lifecycle methods or hooks | Test observable behavior from the caller's perspective |
| Coverage-percentage tests | Tests written to push coverage % higher rather than verify an outcome | Delete — coverage is a side effect of good outcome tests, not a target |
| Implementation-detail tests | Tests on internal helpers/private methods with no observable behavior | Delete or replace with an outcome test exercising the helper through its caller |
| Unmapped tests | A test that doesn't trace to any AC | Delete OR justify by mapping it to a regression AC |
