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
| **High** | Security implications (unsafe defaults, eval, missing validation on user input, ignored errors) | Foundation story generated (P1) |
| **Medium** | Maintainability impact (missing types, suppressed warnings, disabled tests) | Recorded in debt inventory, foundation story if count is high |
| **Low** | Cosmetic or minor (stale TODOs, magic numbers, star imports) | Recorded in debt inventory only |

## Recording Format

Populate `docs/technical-debt.md`:

```markdown
## Active Items

### TD-001: {count} TODO/FIXME/HACK comments
- **Priority:** Low
- **Location:** Across {n} files
- **Description:** {count} stale markers found. Top files: {top_3_files}
- **Impact:** Unresolved work items accumulate if not triaged
- **Remediation:** Triage each marker — resolve, convert to backlog story, or remove
- **Created:** {date}
- **Sprint:** Bootstrap

### TD-002: {count} functions missing type hints
- **Priority:** Medium
- **Location:** {files_list}
- **Description:** {count} Python functions lack return type annotations
- **Impact:** Type checker can't catch hallucinated types in these functions
- **Remediation:** Add type hints progressively, starting with public API functions
- **Created:** {date}
- **Sprint:** Bootstrap
```

## Summary Table Update

After recording items, update the summary table at the top of `docs/technical-debt.md`:

```markdown
| Priority | Count | Oldest |
| -------- | ----- | ------ |
| High     | {n}   | Bootstrap |
| Medium   | {n}   | Bootstrap |
| Low      | {n}   | Bootstrap |
```

## Integration with Foundation Backlog

For High-severity items, generate a foundation story:

```markdown
### E00-S{nn}: Address high-severity technical debt ({category})

**Type:** Infrastructure
**Priority:** P1
**Source:** Framework Readiness Report — Technical debt (High severity)

**Description:**
Bootstrap detected {count} high-severity technical debt items in category "{category}":
{list_of_items}

**Acceptance Criteria:**
- [ ] All high-severity items in "{category}" are resolved or mitigated
- [ ] No new high-severity items introduced
- [ ] Items moved to "Resolved" in docs/technical-debt.md
```

For Medium-severity items with high count (>10 instances), generate a lower-priority story:

```markdown
### E00-S{nn}: Address {category} technical debt ({count} instances)

**Type:** Refactoring
**Priority:** P2
**Source:** Framework Readiness Report — Technical debt (Medium severity, high count)

**Description:**
Bootstrap detected {count} instances of {category} across {n} files.

**Acceptance Criteria:**
- [ ] Instance count reduced by at least 50%
- [ ] Updated count recorded in docs/technical-debt.md
```
