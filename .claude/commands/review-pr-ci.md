# CI PR Review

Non-interactive PR review for CI/CD context. Read-only analysis — no edits.

## Process

1. **Discover PR scope:**
   ```bash
   git diff --stat main...HEAD
   git diff --name-only main...HEAD
   git log main..HEAD --oneline
   ```

2. **Code quality analysis:**
   - Check cyclomatic complexity of changed functions (flag >10)
   - Identify duplicated code blocks (>10 lines)
   - Verify pattern consistency with existing codebase
   - Check error handling in new code paths

3. **Test validation:**
   - Verify test files exist for new source files
   - Check for weakened assertions (toBeTruthy replacing specific checks)
   - Check for deleted or skipped tests
   - Verify assertion density (≥1.5 per test)

4. **Security scan:**
   - Scan changed files for hardcoded secret patterns
   - Check imported packages exist in dependency files
   - Verify input validation on user-facing code
   - Check CWE top 10 patterns (injection, XSS, path traversal)

5. **Post structured review as PR comment:**

```markdown
## Claude Code Review

### Summary
[1-3 sentences on overall quality]

### Findings
| Severity | File | Line | Issue | Confidence |
|----------|------|------|-------|------------|
| [HIGH/MED/LOW] | [path] | [line] | [description] | [0-100] |

### Test Coverage
- New files with tests: [X/Y]
- Assertion density: [X.X]
- Degradation detected: [yes/no]

### Security
- Secret patterns: [PASS/findings]
- Dependency check: [PASS/findings]
- Input validation: [PASS/findings]

### Verdict: [APPROVE / REQUEST_CHANGES / COMMENT]
[One-line rationale]
```

Only report findings with confidence ≥80 as actionable. Lower confidence goes in a Notes section.

## Rules

- NEVER edit files or create commits
- NEVER approve PRs that fail security checks (≥80 confidence)
- ALWAYS provide file:line references for findings
- ALWAYS run fresh analysis — never use cached results
