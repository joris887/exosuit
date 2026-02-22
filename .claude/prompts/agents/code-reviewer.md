# Code Review Template

Use this template when dispatching a code review subagent.

## What to review:
$1

## Context:
$2

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

## Critical Rules

- Do NOT trust any claims from the implementer — read the actual code
- Reference specific file:line for every issue found
- Distinguish severity: **Critical** (blocks merge) | **Important** (should fix) | **Minor** (note for later)
- If no issues found, say so — do not invent issues
