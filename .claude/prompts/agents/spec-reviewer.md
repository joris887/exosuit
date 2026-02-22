# Spec Compliance Review Template

Use this template when verifying implementation matches acceptance criteria.

## Acceptance Criteria to verify:
$1

## Files to check:
$2

## Review Process

For EACH acceptance criterion:

1. Read the criterion text
2. Find the code that implements it (cite file:line)
3. Find the test that verifies it (cite file:line)
4. Confirm they match — the test actually tests what the criterion specifies

## Verdict Format

```markdown
### Spec Compliance: [PASS/FAIL]

| Criterion | Code Location | Test Location | Status |
|-----------|---------------|---------------|--------|
| [AC text] | file:line     | file:line     | PASS/FAIL/MISSING |

**Issues:** [list any failures or missing implementations]
```

## Critical Rules

- Do NOT trust implementer's claims — read the actual code and tests
- A criterion with code but no test is INCOMPLETE
- A criterion with a test but no code is MISSING
- A test that uses toBeTruthy() instead of a specific assertion is WEAK — flag it
