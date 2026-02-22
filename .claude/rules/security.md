---
paths:
  - "**/*.env*"
  - "**/auth/**"
  - "**/security/**"
  - "**/credentials*"
  - "**/secrets*"
  - "**/*password*"
  - "**/*token*"
  - "**/*key*"
---

# Security Rules

- Never hardcode secrets, API keys, passwords, or tokens in source code
- Always use environment variables or secret management for credentials
- Always parameterize SQL queries — never use string concatenation
- Always validate and sanitize user input at system boundaries
- Always escape user-provided content before rendering (prevent XSS)
- Never log sensitive data (passwords, tokens, PII)
- Never expose internal error details to end users

## CWE Checklist (Most Common in AI-Generated Code)

Check against these before committing security-sensitive code:

- CWE-798: Hardcoded credentials
- CWE-79: Cross-site scripting (XSS)
- CWE-89: SQL injection
- CWE-22: Path traversal
- CWE-78: OS command injection
- CWE-200: Information exposure
- CWE-287: Improper authentication
- CWE-306: Missing authentication for critical function
- CWE-502: Deserialization of untrusted data
- CWE-918: Server-side request forgery (SSRF)

## Fix Safety Issues Immediately

When you discover a safety issue during normal work — do NOT ask, do NOT defer, do NOT "note for later":

- Secret/credential exposed in code → Remove and commit immediately
- Worktree or temp directory not in .gitignore → Add it and commit immediately
- Unsafe file permissions on sensitive files → Fix immediately
- Missing input validation at a system boundary → Fix immediately
- Dependency with known critical vulnerability → Flag to user immediately

Fix, commit with `fix(security): <description>`, then continue your original task.
