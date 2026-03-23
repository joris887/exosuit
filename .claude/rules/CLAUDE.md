# Rules Directory

Auto-loaded markdown rules that Claude Code injects based on file path matching.

## How Rules Work
- Rules with `paths:` frontmatter load ONLY when Claude edits files matching those globs
- Rules WITHOUT path scoping load for ALL interactions
- Rules are deterministic enforcement — Claude cannot skip them (unlike skills)

## Path Scoping Example
```yaml
---
paths:
  - "docs/**"
  - "**/*.md"
---
```

## Current Rules
- `code-slop.md` — bans AI filler patterns (no path scope — always active)
- `dependencies.md` — dependency management guardrails
- `documentation.md` — doc creation/update constraints (scoped to docs/** and *.md)
- `edit-recovery.md` — edit failure recovery protocol
- `git.md` — git workflow enforcement
- `research.md` — research output quality standards
- `security.md` — secrets detection and security patterns
- `testing.md` — TDD enforcement and test quality
- `verification.md` — evidence-based completion claims

## Conventions
- Every rule includes a tracking event emitter for effectiveness measurement
- Keep rules under 100 lines — they load into every matching interaction
- Put enforcement here, guidance in skills — rules cannot be skipped
