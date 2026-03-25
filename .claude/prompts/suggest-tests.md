---
## name: suggest-tests description: Suggest test cases for a file argument-hint: <file-path> user-invocable: true allowed-tools: Read, Glob, Grep
---

Read `$1` and suggest test cases that would provide meaningful coverage.

For each suggested test:
1. **Test name:** `test_[action]_[condition]_[expected]` format
2. **What it verifies:** The specific behavior being tested
3. **Category:** Happy path / edge case / error handling / boundary
4. **Priority:** Must-have / should-have / nice-to-have

Apply the framework's test quality criteria:
- Would it fail if you reverted to a naive implementation? (Revert test)
- Would changing `>` to `>=` make it fail? (Mutation test)
- Does it validate behavior from the caller's perspective? (Independence test)
- Does it have meaningful assertions, not just `assert True`? (Assertion quality)
- Aim for ≥3 meaningful assertions per test — hardcoded expected values, never computed from production logic
- For each happy-path test, suggest a corresponding negative/error test (aim for proportional coverage)
- If the function has complex inputs or maintains invariants: suggest a property-based test (Hypothesis, fast-check, proptest, etc.)
- If >3 mocks would be needed: suggest an integration test without mocks instead
- Prefer parameterized/table-driven tests over duplicated test methods for similar scenarios

Look at existing test files in the project for patterns and conventions to follow.
