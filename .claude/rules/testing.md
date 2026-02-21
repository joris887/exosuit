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

## Red Flags to Avoid

- Tautological tests (always pass regardless of implementation)
- Happy-path-only coverage (missing error cases and edge cases)
- Over-mocking (mocking so much that the test verifies nothing real)
- Testing the mock (assertions on mock return values, not real behavior)
- Catch-all exception handlers in tests that swallow real failures
