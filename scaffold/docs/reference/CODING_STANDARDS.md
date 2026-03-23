# Coding Standards

Authoritative reference for all coding conventions, testing standards, and quality requirements. Referenced by all skills.

<!-- Language-specific sections are filled by /bootstrap based on detected stack -->

## Universal Conventions

### File Organization
- One module/class per file (exceptions: tightly coupled types, constants)
- File names match their primary export: `user_service.py`, `UserService.ts`
- Group by feature/domain, not by type: `auth/login.ts` not `controllers/login.ts`
- Maximum file size: 500 LOC (flag for splitting if exceeded)

### Naming Conventions
- **Files:** snake_case (Python, Ruby, PHP), kebab-case or camelCase (JS/TS, per project convention)
- **Directories:** lowercase, hyphenated for multi-word: `user-management/`
- **Branches:** `sprint-<number>` for sprint branches
- **Commits:** Conventional format: `<type>(<scope>): <description>`
- **Environment files:** `.env`, `.env.example`, `.env.test`

### Error Handling
- Fail fast at system boundaries — validate inputs early
- Use typed errors/exceptions — never catch-all without re-throwing
- Error messages for users: clear, actionable, no internal details
- Error messages for logs: include context (request ID, user ID, operation)
- Never silently swallow errors — log at minimum

### API Design (when applicable)
- Use consistent response envelope: `{ data, error, meta }`
- HTTP status codes must match semantics (don't return 200 for errors)
- Version APIs from day one: `/api/v1/`
- Document all endpoints in `docs/reference/API_DOCUMENTATION.md`

### Import Organization
- Standard library → third-party → local (with blank line separators)
- Absolute imports preferred over relative (except within a module)
- No circular imports — extract shared types to a separate file

### Configuration
- Environment variables for secrets and deployment-specific values
- Configuration files for application behavior (with defaults)
- Never commit `.env` — commit `.env.example` with placeholder values

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

## Multi-Language Projects

For monorepos or projects with multiple languages:
- Each language gets its own section in this file
- Shared conventions (above) apply to all languages
- Language-specific overrides go in their respective sections
- Per-language formatting is enforced by the post-edit-format hook (auto-detects by extension)
- Run `/bootstrap` at the project root to detect all languages

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

### Comment Quality

Comments explain WHY, not WHAT. Detailed patterns in `.claude/rules/code-slop.md`.

- **Required:** Edge cases, business logic rationale, workarounds with ticket links, non-obvious algorithm choices
- **Prohibited:** Restating the code, explaining standard library functions, parameter descriptions that repeat the type, file-level "this file contains..." comments
- **Rule of thumb:** If deleting the comment loses zero information, delete it

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
