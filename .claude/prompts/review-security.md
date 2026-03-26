---
## name: review-security description: Security review of a specific file argument-hint: <file-path> user-invocable: true allowed-tools: Read, Glob, Grep
---

Review `$1` for security vulnerabilities. AI-generated code contains vulnerabilities 40-45% of the time — review thoroughly.

Focus on (ranked by AI vulnerability frequency):

- **Hardcoded credentials (CWE-798/259):** API keys, passwords, tokens, connection strings in source
- **Injection (CWE-89, 78, 79, 94):** SQL injection, command injection, XSS, code injection (eval/exec)
- **Input validation (CWE-20):** Server-side validation missing or client-side only
- **Authentication/Authorization (CWE-287, 306, 862):** Missing auth checks, missing authorization, bypass paths
- **Cryptography (CWE-327):** Deprecated algorithms (MD5, SHA1, DES), hardcoded keys, insufficient key lengths
- **Over-permissive configs:** CORS wildcards, disabled security features, excessive permissions
- **Supply chain:** Phantom packages (verify imports exist in registry), typosquatted names
- **Data exposure (CWE-200):** Verbose error messages, sensitive data in logs, PII in responses
- **SSRF (CWE-918):** User-controlled URLs in server-side requests
- **Deserialization (CWE-502):** Untrusted data deserialized without validation

Report findings as:

```markdown
### Security Review: [file]

| # | Severity | Issue | Line(s) | Recommendation |
|---|----------|-------|---------|----------------|
| 1 | [critical/high/medium/low] | [description] | [line numbers] | [fix] |

**Overall risk:** [low/medium/high]
```

If no issues found, say so clearly — don't invent problems.
