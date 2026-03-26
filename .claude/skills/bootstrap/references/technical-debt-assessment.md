# Technical Debt Assessment Reference

Reference loaded by `/bootstrap` Path A step A3.2. Scans the codebase for common technical debt indicators and records them for tracking.

## Purpose

The framework maintains `docs/technical-debt.md` as a debt inventory. Bootstrap populates the initial inventory by scanning for patterns that indicate accumulated technical debt. High-severity items (security implications) generate foundation stories.

## Debt Indicators by Stack

### Universal (All Stacks)

| Category | Pattern | Severity |
|----------|---------|----------|
| Stale markers | `TODO`, `FIXME`, `HACK`, `XXX` comments | Low (count), Medium (if >20) |
| Disabled tests | `@skip`, `skip()`, `.skip`, `xtest`, `xit` | Medium |
| Suppressed warnings | `// nolint`, `# noqa`, `// eslint-disable`, `@SuppressWarnings` | Medium |
| Magic numbers | Hardcoded constants without named variables | Low |
| Wildcard CORS | `Access-Control-Allow-Origin: *` in production code | High |
| Disabled security | `CSRF_ENABLED=False`, `security.headers.disabled`, `verify=False` | High |
| Deprecated crypto | `MD5`, `SHA1` (for security), `DES`, `RC4` usage | High |
| Missing auth middleware | API routes without authentication/authorization checks | High |
| Eval with input | `eval()`, `exec()`, `Function()` with non-constant arguments | High |
| Hardcoded secrets | Strings matching API key, token, or password patterns | Critical |

### Python

| Category | Pattern | Severity |
|----------|---------|----------|
| Missing type hints | Functions without `->` return type annotation | Medium |
| Bare except | `except:` or `except Exception:` without specific types | Medium |
| Unsafe defaults | `check_same_thread=False`, `verify=False`, `shell=True` | High |
| Star imports | `from module import *` | Low |

### TypeScript / JavaScript

| Category | Pattern | Severity |
|----------|---------|----------|
| `any` type usage | Explicit `any` type annotations | Medium |
| `as` type assertions | Type casting that bypasses checks | Medium |
| `@ts-ignore` / `@ts-nocheck` | Suppressed type errors | Medium |
| `eval()` usage | Dynamic code execution | High |

### Go

| Category | Pattern | Severity |
|----------|---------|----------|
| `//nolint` directives | Suppressed linter checks | Medium |
| Ignored errors | `_ = someFunc()` on error-returning functions | High |
| `unsafe` package | Direct memory manipulation | High |

### Rust

| Category | Pattern | Severity |
|----------|---------|----------|
| `unsafe` blocks | Bypassing borrow checker | High |
| `#[allow(...)]` attributes | Suppressed compiler warnings | Medium |
| `.unwrap()` usage | Panics instead of error handling | Medium |

### Java / Kotlin

| Category | Pattern | Severity |
|----------|---------|----------|
| `@SuppressWarnings` | Suppressed compiler warnings | Medium |
| Empty catch blocks | `catch (Exception e) {}` | High |
| Raw types | Generic types without parameters | Medium |

### Ruby

| Category | Pattern | Severity |
|----------|---------|----------|
| `# rubocop:disable` | Suppressed linter checks | Medium |
| `eval` / `send` | Dynamic dispatch on user input | High |
| Missing frozen_string_literal | Mutable string default | Low |

### PHP

| Category | Pattern | Severity |
|----------|---------|----------|
| `@` error suppression | Suppressed errors | Medium |
| `eval()` usage | Dynamic code execution | High |
| `mysql_*` functions | Deprecated database API | High |

## Scan Procedure

For each detected stack, scan using the relevant patterns:

```bash
# Universal: count stale markers
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.{ext}" \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git \
  --exclude-dir=__pycache__ --exclude-dir=target --exclude-dir=build | wc -l

# Stack-specific: adapt patterns from the tables above
# Example: Python unsafe defaults
grep -rn "check_same_thread=False\|verify=False\|shell=True" --include="*.py"

# Example: TypeScript any usage
grep -rn ": any\b\|as any\b" --include="*.ts" --include="*.tsx"
```

## Severity Classification

| Severity | Criteria | Action |
|----------|----------|--------|
| **Critical** | Active security vulnerability, data loss risk, blocks all development | Foundation story generated (P0) |
| **High** | Security implications (unsafe defaults, eval, ignored errors), significant velocity impact | Foundation story generated (P1) |
| **Medium** | Maintainability impact (missing types, suppressed warnings, disabled tests) | Recorded in debt register, foundation story if count >10 |
| **Low** | Cosmetic or minor (stale TODOs, magic numbers, star imports) | Recorded in debt register only |

## Category Mapping

Map each detected pattern to one of the 7 categories in `docs/technical-debt.md`:

| Pattern type | Category |
|-------------|----------|
| Stale markers (TODO/FIXME/HACK) | Code quality |
| Disabled/skipped tests | Test |
| Suppressed warnings | Code quality |
| Missing type hints/annotations | Code quality |
| Unsafe defaults, eval, bare except | Security |
| Star imports, magic numbers | Code quality |
| Deprecated API usage | Dependency |

## Recording Format

Place items under the matching severity heading in `docs/technical-debt.md`:

```markdown
## High

### TD-001: {count} unsafe defaults in Python code
- **Category:** Security
- **Severity:** High | **Since:** {date}
- **Origin:** legacy
- **Location:** `{files_list}`

**What:** {count} instances of unsafe defaults (`verify=False`, `shell=True`, `check_same_thread=False`) found across {n} files. These bypass security checks and enable injection vectors.

**Impact:** Each instance is a potential security vulnerability. Affects {n} files in {modules}.

**Interest:** Stable
**Effort:** Days — each instance requires understanding the call site context.
**Priority score:** (3 x 2) / 2 = 3.0

**Resolution:** Audit each instance. Replace `verify=False` with proper cert config, `shell=True` with subprocess list args, etc.

**Linked:** E00-S{nn}

## Low

### TD-002: {count} TODO/FIXME/HACK comments
- **Category:** Code quality
- **Severity:** Low | **Since:** {date}
- **Origin:** legacy
- **Location:** Across {n} files — top: `{top_3_files}`

**What:** {count} stale markers found. These represent unresolved work items that accumulate if not triaged.

**Impact:** Minor friction — developers encounter unresolved notes during code navigation.

**Interest:** Stable
**Effort:** Hours — triage each marker individually.
**Priority score:** (1 x 2) / 1 = 2.0

**Resolution:** Triage each marker — resolve, convert to backlog story, or remove if obsolete.

**Linked:** —
```

## Header Update

After recording items, update the header of `docs/technical-debt.md`:

```markdown
> Last reviewed: {date} | Next review: {date + 7 days}
> Active items: {total_count} | Resolved this quarter: 0
```

## Integration with Foundation Backlog

For Critical/High-severity items, generate a foundation story:

```markdown
### E00-S{nn}: Address {severity} {category} debt ({count} items)

**Type:** Infrastructure
**Priority:** P0 (Critical) | P1 (High)
**Source:** Framework Readiness Report — Technical debt ({severity})

**Description:**
Bootstrap detected {count} {severity}-severity technical debt items in category "{category}":
{list_of_items_with_TD_ids}

**Acceptance Criteria:**
- [ ] All {severity} items in "{category}" are resolved or mitigated
- [ ] No new {severity} items introduced
- [ ] Items moved to "Resolved" section in docs/technical-debt.md with actual effort recorded
```

For Medium-severity items with high count (>10 instances), generate a lower-priority story:

```markdown
### E00-S{nn}: Address {category} debt ({count} instances)

**Type:** Refactoring
**Priority:** P2
**Source:** Framework Readiness Report — Technical debt (Medium severity, high count)

**Description:**
Bootstrap detected {count} instances of {category} debt across {n} files (TD-{ids}).

**Acceptance Criteria:**
- [ ] Instance count reduced by at least 50%
- [ ] Resolved items moved to "Resolved" section in docs/technical-debt.md with actual effort
```
