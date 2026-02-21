# Coding Standards

Authoritative reference for all coding conventions, testing standards, and quality requirements. Referenced by all skills.

<!-- Language-specific sections are filled by /bootstrap based on detected stack -->

## Language: [Language 1]

<!-- Filled by /bootstrap. Example:
- **Version:** Python 3.12+
- **Package Manager:** uv
- **Formatter/Linter:** ruff
- **Testing:** pytest with pytest-asyncio
- **Type Hints:** Required (mypy strict mode)
-->

## Language: [Language 2]

<!-- Filled by /bootstrap if multiple languages detected -->

## Shared Conventions

### Git

- **Workflow:** GitHub Flow (feature branches, squash merge)
- **Branch Naming:** `feature/<description>` or `feature/<story-id>-<description>`
- **Commit Format:** Conventional commits: `<type>(<scope>): <description>`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
  - Footer: `Co-Authored-By: Claude <model> <noreply@anthropic.com>`
- **Never:** Push directly to main, force push, skip hooks

### Testing

**Full testing strategy:** `docs/reference/TESTING_STRATEGY.md` — read this for comprehensive guidelines.

Key rules:

- **TDD:** Mandatory for feature, bug fix, and refactoring stories (human owns RED, AI assists GREEN/REFACTOR)
- **Never:** Let the AI write both the test AND the implementation in the same prompt
- **Coverage:** Must not decrease sprint-over-sprint; tracked per-module
- **Isolation:** Tests should run without external dependencies where possible
- **Guard rails:** Test count and assertion count must never decrease on a PR
- **Quality:** Every test must have meaningful assertions; no tautological or mock-only tests

### Quality Gates

<!-- Filled by /bootstrap with detected tools. Example:
- **Complexity:** All functions CCN < 10 (monitored with lizard)
- **Duplication:** < 5% (monitored with jscpd)
- **Security:** No hardcoded secrets, parameterized SQL, encryption at rest
- **Pre-commit:** ruff, mypy, eslint, etc.
-->

### Documentation

- **When to create:** Only when explicitly required or when a story's AC demands it
- **When to update:** Epic file status, BACKLOG_INDEX counts, progress.md after sprint completion
- **When NOT to create:** No proactive READMEs, no extra markdown files, no docstrings on unchanged code
- **Architecture docs:** ADRs for decisions, ARCHITECTURE.md for overview — update only when architecture changes

### Security

- **Secrets:** Never hardcode credentials; use environment variables or secure stores
- **Scanning:** Use available tools (detect-secrets, npm audit, pip-audit, cargo audit, etc.)
- **Input validation:** Sanitize all user input at system boundaries
- **SQL:** Always use parameterized queries

## Key Commands

<!-- Filled by /bootstrap. Example:
| Command        | Purpose                          |
| -------------- | -------------------------------- |
| `npm test`     | Run all tests                    |
| `npm run lint` | Run linter                       |
| `npm run build`| Build project                    |
-->

## References

- Testing Strategy: `docs/reference/TESTING_STRATEGY.md`
- Architecture: `docs/architecture/ARCHITECTURE.md`
- ADRs: `docs/adr/README.md`
