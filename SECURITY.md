# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 5.x     | ✅        |
| < 5.0   | ❌        |

Only the latest major version receives security fixes. Upgrade with
`/framework-upgrade`.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, use GitHub's private vulnerability reporting: go to the
[Security tab](https://github.com/joris887/exosuit/security) of this repository
and click **"Report a vulnerability"**. This opens a private advisory that only
the maintainer can see.

When reporting, please include:

- A description of the vulnerability and its impact
- Steps to reproduce (a minimal example is ideal)
- The framework version and platform (macOS/Linux, shell) affected

## What to Expect

- **Acknowledgment within 48 hours** of your report
- **An initial assessment within 7 days** — severity, affected versions, and a
  remediation plan
- Credit in the release notes when the fix ships (unless you prefer to remain
  anonymous)

## Scope

Exosuit is a development-time framework: it ships shell hooks, prompt files,
and configuration that run on a developer's machine inside Claude Code. Reports
we especially care about:

- Hook scripts that can be made to execute untrusted input
- Ways a repository's contents could hijack or bypass the enforcement layer
  (e.g., prompt injection through framework-managed files that disables safety
  hooks)
- The secrets-detection hook missing credential patterns it claims to catch
- `install.sh` behaving unsafely (overwriting files outside the target project,
  fetching unpinned remote code)

Vulnerabilities in Claude Code itself should be reported to
[Anthropic](https://www.anthropic.com/responsible-disclosure-policy), not here.
