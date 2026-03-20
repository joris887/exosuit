Capture measurable story outcomes after verification passes. Invoke at the end of `/story-cycle` Phase 4d (after all acceptance criteria verified, before Phase 4e docs+commit).

## When to Capture

- After `/story-cycle` Phase 4d passes with all criteria verified
- After any story completion that involved code changes (not documentation-only or spike stories)
- Skip for: Spike/Research stories (no code changes), Documentation stories (no measurable code delta)

## Capture Protocol

Run these commands and parse the results:

### 1. Code Delta
```bash
git diff --stat HEAD  # For unstaged changes (pre-commit)
# OR
git diff --stat HEAD~1  # For committed changes (post-commit)
```

Parse: lines added (`insertions`), lines removed (`deletions`)

### 2. Test Count (if test command configured)
```bash
# Run the project's test command and count test cases from output
# Parse framework-specific patterns:
# - pytest: "X passed"
# - jest/vitest: "Tests: X passed"
# - go test: "ok" lines
# - cargo test: "test result: ok. X passed"
```

### 3. Coverage Delta (if coverage command configured)
```bash
# Run coverage command if available
# Parse percentage from output
```

### 4. New Dependencies
```bash
git diff HEAD -- package.json pyproject.toml Cargo.toml go.mod Gemfile composer.json pubspec.yaml 2>/dev/null | grep "^+" | grep -v "^+++"
```

Count new dependency lines added (if any).

## Output

Append a row to `docs/sessions/.story-outcomes.tsv`:

```
story_id	story_type	lines_added	lines_removed	net_lines	tests_added	coverage_delta	new_deps	timestamp
```

| Column | Type | Description |
|--------|------|-------------|
| `story_id` | string | Story ID or description slug |
| `story_type` | string | Feature, Bug Fix, Refactoring, etc. |
| `lines_added` | number | Lines of code added |
| `lines_removed` | number | Lines of code removed |
| `net_lines` | number | `lines_added - lines_removed` |
| `tests_added` | number | Net new test cases (0 if not measurable) |
| `coverage_delta` | string | Coverage change (e.g., "+2.1%") or "N/A" |
| `new_deps` | number | New dependencies added |
| `timestamp` | string | ISO-8601 timestamp |

If the TSV file doesn't exist, create it with the header row first.

## Usage in Retrospective

The `/retrospective` skill can consume `.story-outcomes.tsv` to report:
- Average net code growth per story type
- Test-to-implementation ratio trends
- Coverage trajectory across sprints
- Stories with disproportionate code growth (potential over-engineering)
