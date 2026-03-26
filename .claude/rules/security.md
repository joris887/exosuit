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
  - "**/crypto*"
  - "**/encrypt*"
  - "**/oauth*"
  - "**/jwt*"
  - "**/permission*"
  - "**/rbac*"
  - "**/acl*"
---

# Security Rules

AI-generated code contains vulnerabilities 40–45% of the time and increases secret leakage by 40%. These rules are non-negotiable.

## Core Rules

- Never hardcode secrets, API keys, passwords, or tokens in source code
- Always use environment variables or a secrets vault for credentials
- Always parameterize database queries — never string-concatenate user input
- Always validate and sanitize user input at every system boundary (API endpoints, CLI args, file uploads, webhook payloads)
- Always escape user-provided content before rendering (prevent XSS)
- Never log sensitive data (passwords, tokens, PII, request bodies containing credentials)
- Never expose internal error details to end users — return generic messages, log details server-side
- Never disable SSL/TLS verification (`verify=False`, `rejectUnauthorized: false`, `InsecureSkipVerify: true`)
- Never use `Access-Control-Allow-Origin: *` in production — restrict to specific allowed origins
- Never use deprecated cryptographic algorithms (MD5, SHA1 for security, DES, RC4) — use SHA-256+, AES-256, bcrypt/scrypt/argon2
- Never generate authentication or cryptographic code from scratch — use established libraries

## CWE Checklist (AI-Generated Code — Ranked by Frequency × Severity)

Check against these before committing security-sensitive code:

| Priority | CWE | Vulnerability | AI Frequency |
|----------|-----|---------------|-------------|
| CRITICAL | CWE-798/259 | Hardcoded credentials | All LLMs produce these |
| CRITICAL | CWE-89 | SQL injection | 20%+ of AI samples |
| CRITICAL | CWE-79 | Cross-site scripting (XSS) | 86% of AI XSS samples fail |
| CRITICAL | CWE-78 | OS command injection | Top AI CWE on GitHub |
| CRITICAL | CWE-94 | Code injection (eval, exec) | Rising — #11 on CWE Top 25 |
| HIGH | CWE-22 | Path traversal | Common in file handling |
| HIGH | CWE-287 | Improper authentication | Weak patterns, missing MFA |
| HIGH | CWE-306 | Missing auth for critical function | AI omits auth middleware |
| HIGH | CWE-862 | Missing authorization | AI skips business-logic authz |
| HIGH | CWE-327 | Broken cryptography | 14% insecurity rate |
| HIGH | CWE-918 | Server-side request forgery (SSRF) | URLs not validated |
| HIGH | CWE-502 | Insecure deserialization | Untrusted data deserialized |
| MEDIUM | CWE-200 | Information exposure | Verbose error messages |
| MEDIUM | CWE-20 | Improper input validation | AI skips server-side validation |
| MEDIUM | CWE-352 | Cross-site request forgery (CSRF) | State-changing endpoints unprotected |

## Fix Safety Issues Immediately

When you discover a safety issue during normal work — do NOT ask, do NOT defer, do NOT "note for later":

- Secret/credential exposed in code → Remove and commit immediately
- Worktree or temp directory not in .gitignore → Add it and commit immediately
- Unsafe file permissions on sensitive files → Fix immediately
- Missing input validation at a system boundary → Fix immediately
- Dependency with known critical vulnerability → Flag to user immediately
- `eval()` or equivalent with user-controlled input → Remove immediately

Fix, commit with `fix(security): <description>`, then continue your original task.

## AI-Specific Security Anti-Patterns

| Pattern | Detection Signal | Correct Action |
|---------|-----------------|----------------|
| Phantom packages (slopsquatting) | Package not in lockfile or registry — 19.7% of AI recommendations are hallucinated | Verify EVERY AI-suggested package exists in its registry before adding |
| Typosquatted dependencies | Name similar to popular package (e.g., `requets` vs `requests`) | Check exact name against official docs; compare download counts |
| Overly permissive CORS | `Access-Control-Allow-Origin: *` anywhere | Restrict to specific allowed origins; never wildcard in production |
| Logging sensitive data | `console.log(user)`, `logger.info(request.body)` | Sanitize before logging — redact passwords, tokens, PII |
| Disabled SSL verification | `verify=False`, `rejectUnauthorized: false`, `InsecureSkipVerify` | Fix the certificate issue — never disable verification |
| Wildcard permissions | `chmod 777`, `*` in IAM policies, `allowAll` | Apply least privilege — grant only what's needed |
| Missing auth middleware | API routes without authentication checks | Every endpoint needs explicit auth — opt-out, not opt-in |
| Deprecated crypto | MD5, SHA1 for hashing; DES, RC4 for encryption | Use SHA-256+, AES-256-GCM, bcrypt/scrypt/argon2 |
| Disabled security features | `CSRF_ENABLED=False`, `security.headers.disabled` | Never disable — fix the underlying issue |
| Memorized secrets | AI outputs real-looking keys from training data | NEVER trust AI-generated values for secrets — always generate fresh |

## Secret Rotation Awareness

When reviewing code that handles secrets or credentials:

- **Flag hardcoded expiry dates** — credentials with hardcoded expiration should use environment variables
- **Check for rotation-friendly patterns:**
  - Secrets loaded at runtime (not cached permanently in module-level variables)
  - Connection pools that can refresh credentials without restart
  - Token refresh flows that handle expiry gracefully
  - Key versioning for encryption keys (avoid re-encrypting all data on rotation)
- **During /weekly-maintenance:** If `docs/reference/SECRETS_INVENTORY.md` exists, review for:
  - Secrets past their rotation due date (flag as warning)
  - Secrets without a documented rotation method
  - Secrets classified as `critical` without automated rotation

