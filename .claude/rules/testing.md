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

- Never weaken assertions (e.g., replacing `toBe(42)` with `toBeTruthy()`)
- Never delete test cases or test blocks without explicit user approval
- Never reduce the total test count
- Never replace real assertions with no-op or trivially-passing checks
- Tests must test behavior, not implementation details
- Mocks should mock external services only, never internal logic
- Every test must have at least one meaningful assertion
- Test names must describe the behavior being tested: `test_[action]_[condition]_[expected]`
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
