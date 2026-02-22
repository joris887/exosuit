# Code Review Template

Use this template when dispatching a code review subagent. Supports multi-perspective review via the optional `$3` lens parameter.

## What to review:
$1

## Context:
$2

## Review Lens: $3

If a review lens is specified, focus your review **exclusively** on that lens:

- **correctness**: Logic errors, edge cases, off-by-one, race conditions, null/undefined handling. Do NOT flag style or security — another reviewer handles those.
- **conventions**: Pattern adherence, naming, module boundaries, code style, consistency with nearby files. Do NOT flag correctness or security.
- **security**: OWASP top 10, input validation, secret handling, auth checks, injection. Do NOT flag style or correctness.

If no lens is specified (empty `$3`), review across all areas using the full checklist below.

## Review Checklist

### Correctness
- [ ] Code does what the acceptance criteria specify (not more, not less)
- [ ] Edge cases are handled
- [ ] Error paths are covered

### Patterns
- [ ] Follows existing patterns in the codebase (check nearby files first)
- [ ] No unnecessary abstraction or over-engineering
- [ ] Naming is consistent with project conventions

### Security
- [ ] No hardcoded secrets or credentials
- [ ] User input is validated at system boundaries
- [ ] SQL queries are parameterized (if applicable)

### Testing
- [ ] Tests are meaningful — would fail if implementation was naive
- [ ] No weakened assertions (toBeTruthy replacing toBe(42))
- [ ] Edge cases have test coverage

## Confidence Scoring

Rate each finding 0–100:
- **0–25:** Stylistic nitpick or likely false positive
- **26–50:** Possible issue, needs more context
- **51–75:** Probable issue worth noting
- **76–100:** Definite issue with clear evidence

**Report ONLY findings scoring ≥80.** Include the confidence score with each finding.

## Critical Rules

- Do NOT trust any claims from the implementer — read the actual code
- Reference specific file:line for every issue found
- Distinguish severity: **Critical** (blocks merge) | **Important** (should fix) | **Minor** (note for later)
- If no issues found, say so — do not invent issues
- Issues flagged by multiple independent reviewers are auto-elevated to Critical
