---
## name: review-security description: Security review of a specific file argument-hint: <file-path> user-invocable: true allowed-tools: Read, Glob, Grep
---

Review `$1` for security vulnerabilities. Focus on:

- **Input validation:** Is all user input validated and sanitized before use?
- **Injection:** SQL injection, command injection, path traversal, XSS
- **Secrets:** Hardcoded credentials, API keys, tokens, passwords
- **Authentication/Authorization:** Proper checks, no bypasses
- **CWE top 10 for AI-generated code:** CWE-798, CWE-22, CWE-78, CWE-89, CWE-79, CWE-862, CWE-311, CWE-200, CWE-502, CWE-918

Report findings as:

```markdown
### Security Review: [file]

| # | Severity | Issue | Line(s) | Recommendation |
|---|----------|-------|---------|----------------|
| 1 | [critical/high/medium/low] | [description] | [line numbers] | [fix] |

**Overall risk:** [low/medium/high]
```

If no issues found, say so clearly — don't invent problems.
