# Coding Standards

<!-- This file is the authoritative reference for code conventions. Loaded on demand by skills.
     /bootstrap fills language sections and quality gates based on detected stack.
     Budget: ≤200 lines universal + ~50 per language section. Keep it tight. -->

## Critical Rules

<!-- These go first — LLMs pay most attention to the start and end of documents. -->

- **NEVER** hardcode secrets, API keys, or credentials — use environment variables
- **NEVER** use `any`/`object`/`interface{}` types without explicit justification in a comment
- **NEVER** write tests that can't fail when the code-under-test breaks
- **NEVER** swallow errors silently — handle, re-throw with context, or log with structured context
- **NEVER** use string concatenation for SQL/database queries — parameterized only
- **NEVER** commit commented-out code — use version control

## What This Document Covers

Tools handle formatting and simple linting — those rules are NOT documented here.

| Tier | Handled By | Examples | Documented Here? |
|------|-----------|----------|-----------------|
| **Formatting** | Formatter (Prettier, Black, gofmt, rustfmt) | Indentation, whitespace, line length, brace placement | No — configure once, never discuss |
| **Linting** | Linter (ESLint, Ruff, clippy, golangci-lint) | Unused vars, deprecated APIs, import ordering | No — linter config is the standard |
| **Judgment** | This document + code review | Naming intent, error strategy, code organization, API design | **Yes** |

<!-- /bootstrap guidance: When populating language sections, list the project's formatter and
     linter in the Tooling subsection. Do NOT add rules that the formatter/linter already enforces. -->

## Universal Conventions

### Philosophy

Clarity over cleverness. Code is read 10x more than written. Every name, function, and module
should be understandable without reading its implementation.

### Naming

Names communicate intent — not type, not implementation detail.

| What | Rule | Example |
|------|------|---------|
| Functions/methods | Verb + noun, describes the action | `parse_email`, `fetchUser`, `BuildConfig` |
| Booleans | Reads as a yes/no question | `is_valid`, `hasPermission`, `CanRetry` |
| Collections | Plural noun | `users`, `error_codes`, `pendingTasks` |
| Constants | Describes the value's meaning, not its content | `MAX_RETRY_ATTEMPTS` not `THREE` |
| Interfaces/traits | Capability or contract, not `IFoo` prefixes | `Serializable`, `AuthProvider` |
| Files | Match primary export | `user_service.py`, `UserService.ts`, `config.go` |

<!-- /bootstrap guidance: Add a row for language-specific conventions (e.g., receiver names in Go,
     Self in Rust) to the language section's naming table. -->

### Error Handling

Categorize errors at design time, not at catch time:

- **Recoverable** (retry, fallback, user message): Handle explicitly with structured error types
- **Unrecoverable** (config missing, invariant violated): Fail fast with descriptive panic/throw
- **Expected** (validation failure, not found): Return as values, not exceptions where the language supports it

Rules:
- Wrap errors with context when re-throwing: what operation failed and why
- Error messages for users: clear, actionable, no stack traces or internal IDs
- Error messages for logs: include request ID, user ID, operation, and root cause
- Empty catch/except blocks are banned — handle it or let it propagate

### Code Organization

- One module/class per file (exceptions: tightly coupled types, constants)
- Group by feature/domain, not by type: `auth/login.ts` not `controllers/login.ts`
- Maximum file size: 300 LOC — flag for splitting if exceeded
- Functions do one thing. Maximum 40 lines per function, cyclomatic complexity < 10.
- Extract a helper only when it's called from 2+ places — premature abstraction is worse than repetition

### Comments

Comments explain WHY, not WHAT. Full anti-patterns in `.claude/rules/code-slop.md`.

- **Required:** Edge cases, business logic rationale, workarounds (with ticket link), non-obvious algorithm choices
- **Prohibited:** Restating the code, parameter descriptions that repeat the type, "this file contains..." headers
- **Test:** If deleting the comment loses zero information, delete it

### Security Baseline

- All external input validated at system boundaries
- Database queries: parameterized only, never string interpolation
- Authentication tokens: short-lived, stored securely, never logged
- Dependencies: pinned versions, audited regularly (`npm audit`, `pip-audit`, `cargo audit`)

### API Design

<!-- Only applies to projects with APIs. /bootstrap: remove this section if not applicable. -->

- Consistent response envelope: `{ data, error, meta }`
- HTTP status codes match semantics — never 200 for errors
- Version from day one: `/api/v1/`
- Idempotency keys for mutating operations

## AI-Specific Anti-Patterns

<!-- These address documented AI code quality issues. See research/02-coding-standards.md §5. -->

**Do not generate these patterns:**

```
❌ Unnecessary defensive code:
if (items !== null && items !== undefined && Array.isArray(items) && items.length > 0)
✅ Trust internal contracts:
if (items.length > 0)
Why: Internal code has type guarantees. Validate only at system boundaries.

❌ Verbose wrapper that adds nothing:
function getUserById(id: string): User {
  const user = db.users.findById(id)
  return user
}
✅ Use the underlying API directly unless adding logic:
const user = db.users.findById(id)
Why: Wrappers without behavior are indirection without value.

❌ Hallucinated API — using methods/flags that don't exist:
response.json(data, { status: 200 })
✅ Verify APIs exist before using them. When uncertain, check docs or types.
Why: LLMs mix API versions. Pin versions in the language section below.
```

## Language: [Language]

<!-- /bootstrap guidance: Create one section per detected language. Use this structure exactly.
     Reference an authoritative external guide as the base. Document ONLY project-specific
     deviations and version-pinned technology choices.
     Target: ~50 lines per language section. -->

<!--
### Base Standard
Follow [authoritative guide, e.g., PEP 8, Effective Go, Airbnb JS] with these project-specific exceptions:

### Version Pins
Pin versions to prevent AI from mixing incompatible APIs:
- **Language:** [language] [version]
- **Framework:** [framework] [version]
- **Key libraries:** [lib] [version], [lib] [version]

### Naming

| Construct | Convention | Example |
|-----------|-----------|---------|
| Variables | [convention] | `user_name` |
| Functions | [convention] | `get_user` |
| Classes/Types | [convention] | `UserService` |
| Constants | [convention] | `MAX_RETRIES` |
| Test files | [convention] | `test_user.py` |
| Test functions | [convention] | `test_parse_email_returns_none_when_missing_at` |

### Patterns We Use
[2-3 do/don't code pairs for project-specific conventions]
❌ [bad pattern]
✅ [good pattern]
Why: [one line]

### Patterns to Avoid
[2-3 explicit anti-patterns with alternatives]
❌ [anti-pattern]
✅ [preferred approach]
Why: [one line]

### Tooling
- **Formatter:** [tool] — handles spacing, line length, imports (don't fight it)
- **Linter:** [tool] with config at [path]
- **Type checker:** [tool] ([strict/basic] mode)
- **Test runner:** [tool] — `[test command]`
-->

## Multi-Language Projects

<!-- /bootstrap guidance: If multiple languages detected, add a language section for each.
     Shared conventions above apply to all. Language sections document deviations only. -->

- Each language gets its own section above with version pins and patterns
- Shared conventions apply to all languages — language sections add or override
- Post-edit-format hook auto-detects language by file extension
- Cross-language boundaries (API contracts, shared types) documented in `docs/architecture/ARCHITECTURE.md`

## Quality Gates

<!-- /bootstrap guidance: Fill with detected tools and thresholds.
     Format as a table. Only include gates the project can actually enforce. -->

<!--
| Gate | Threshold | Tool | Enforced By |
|------|-----------|------|-------------|
| Tests pass | 100% | [test runner] | CI + pre-push hook |
| Coverage (new code) | ≥ 80% | [coverage tool] | CI |
| Coverage (critical paths) | ≥ 90% branch | [coverage tool] | CI |
| Complexity | CCN < 10 per function | [tool] | Linter |
| Lint | Zero errors | [linter] | Pre-commit hook |
| Format | Auto-applied | [formatter] | Pre-commit hook |
| Security | No new vulnerabilities | [scanner] | CI |
| Duplication | < 5% | [tool] | CI (if available) |
-->

## Key Commands

<!-- /bootstrap guidance: Fill with actual detected commands. -->

<!--
| Command | Purpose |
|---------|---------|
| `[test cmd]` | Run all tests |
| `[lint cmd]` | Run linter |
| `[format cmd]` | Auto-format code |
| `[build cmd]` | Build project |
| `[typecheck cmd]` | Run type checker |
-->

## References

- Testing strategy: `docs/reference/TESTING_STRATEGY.md`
- Git workflow: `docs/reference/GIT_WORKFLOW.md`
- Architecture: `docs/architecture/ARCHITECTURE.md`
- Anti-slop patterns: `.claude/rules/code-slop.md`
- Ground rules: `docs/reference/GROUND_RULES.md`
