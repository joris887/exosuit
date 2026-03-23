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
  - "**/api/**"
  - "**/routes/**"
  - "**/middleware/**"
  - "**/controllers/**"
  - "**/handlers/**"
  - "**/db/**"
  - "**/database/**"
  - "**/models/**"
  - "**/schema/**"
  - "**/upload*"
  - "**/session*"
  - "**/cookie*"
  - "**/cors*"
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

## AI-Specific Security Anti-Patterns

| Pattern | Detection Signal | Correct Action |
|---------|-----------------|----------------|
| Phantom package imports | Package not in lockfile or registry | Verify package exists before importing — check registry |
| Typosquatted dependencies | Name similar to popular package (e.g., `requets` vs `requests`) | Double-check exact package name against official docs |
| Overly permissive CORS | `Access-Control-Allow-Origin: *` in production code | Restrict to specific allowed origins |
| Logging sensitive data | `console.log(user)` or `logger.info(request.body)` where body contains credentials | Sanitize before logging — redact passwords, tokens, PII |
| Disabled SSL verification | `verify=False`, `rejectUnauthorized: false` | Never disable SSL in production — fix the certificate issue |

## Secret Rotation Awareness

When reviewing code that handles secrets or credentials:

- **Flag hardcoded expiry dates** — credentials with hardcoded expiration should use environment variables
- **Check for rotation-friendly patterns:**
  - Secrets loaded at runtime (not cached permanently)
  - Connection pools that can refresh credentials
  - Token refresh flows that handle expiry gracefully
- **During /weekly-maintenance:** If `docs/reference/SECRETS_INVENTORY.md` exists, review for:
  - Secrets not rotated in >90 days (flag as warning)
  - Secrets without documented rotation procedures

