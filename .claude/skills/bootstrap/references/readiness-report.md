# Framework Readiness Report Reference

Reference loaded by `/bootstrap` Path A step A5.8. Produces a structured assessment of whether the project is ready for framework-driven development.

## Purpose

Bootstrap detects what the project HAS. The Readiness Report assesses what the project NEEDS for each framework principle to function. Gaps drive the foundation backlog (A5.9).

## Readiness Checks

Each check maps a framework design principle to a concrete, verifiable project state:

| # | Principle | Check | Data Source | Ready Condition |
|---|-----------|-------|-------------|----------------|
| 1 | **TDD-first** | Test runner exists AND coverage tool available | A2 (commands) + A2.6 (coverage) | Test command works, coverage > 60% |
| 2 | **Sprint-based** | Git repo with clean state | A1 (project state) | `.git/` exists, no merge conflicts |
| 3 | **Git-disciplined** | Default branch exists, remote configured | A3.6 (default branch) | Default branch detected, remote set |
| 4 | **Verification-driven** | Test command works and produces output | A2 (commands) | Test command configured and passing |
| 5 | **CI-enforced** | CI/CD pipeline exists with framework PR review | A5.7 (CI/CD assessment) | CI config found AND framework PR review workflow present |
| 6 | **Secrets-aware** | Post-edit hook configured with secrets scan | A5.5 (hook config) | `post-edit-format.sh` registered in settings.json |
| 7 | **Anti-slop** | `code-slop.md` rule exists | File check | `.claude/rules/code-slop.md` exists |
| 8 | **Quality gates** | Formatter + linter + coverage + type checker available | A2 + A2.8 + A2.85 (tooling) | All four tool categories available |
| 9 | **Context-efficient** | Codebase LLM-ready: no oversized files, low coupling | A3.1 (LLM-readiness) | No files >500 LOC, avg ≤150 LOC, no high fan-out, no circular deps |
| 10 | **Documentation-lean** | Core docs generated and populated | A4 (config generation) | CLAUDE.md, ARCHITECTURE.md, TESTING_STRATEGY.md, progress.md all populated |
| 11 | **Pre-commit hooks** | Git pre-commit hooks configured | A5.65 (pre-commit assessment) | Pre-commit tool detected (.pre-commit-config.yaml, .husky/, lefthook.yml, or git hook) |
| 12 | **Type-safe** | Type checker configured for the stack | A2.8 (type checking) | Type checker available and configured (or built-in for Go/Rust/Dart/C#/Java) |

## Classification

Each check produces one of three statuses:

| Status | Meaning | Icon | Action |
|--------|---------|------|--------|
| **Ready** | Principle can function fully | ✓ | None needed |
| **Risk** | Principle partially met — may fail in some scenarios | ⚠️ | Foundation story generated (advisory) |
| **Missing** | Principle cannot function — critical dependency absent | ✗ | Foundation story generated (priority) |

## Classification Rules

| Check | Ready | Risk | Missing |
|-------|-------|------|---------|
| TDD-first | Tests pass + coverage > 60% | Tests pass but coverage < 60% or no coverage tool | No test runner detected |
| Sprint-based | Git repo, clean state | Git repo but dirty state or merge conflicts | Not a git repo |
| Git-disciplined | Default branch + remote | Default branch but no remote | No git repo or no branches |
| Verification-driven | Test command runs and passes | Test command exists but fails or has no output | No test command detected |
| CI-enforced | CI config + framework PR review workflow | CI config exists but no framework PR review | No CI config found |
| Secrets-aware | Post-edit hook registered | Hook registered but formatter/linter missing | Hook not registered |
| Anti-slop | code-slop.md rule exists | — | Rule file missing |
| Quality gates | Formatter + linter + coverage + type checker | 2-3 of the four available | 0-1 available |
| Context-efficient | No files >500 LOC, avg ≤150, no high fan-out | 1-3 files >500 LOC, or avg 150-300, or fan-out 5-10 | >3 files >500 LOC, or avg >300, or circular deps |
| Documentation-lean | All core docs populated (incl. TESTING_STRATEGY.md) | Some docs still have template placeholders | Core docs missing |
| Pre-commit hooks | Pre-commit tool configured | — | No pre-commit hooks detected |
| Type-safe | Type checker configured (or built-in) | Type checker available but not configured | No type checker available (not built-in) |

## Report Template

```markdown
## Framework Readiness Report

| Principle | Status | Detail |
|-----------|--------|--------|
| TDD-first | {status} | {detail} |
| Sprint-based | {status} | {detail} |
| Git-disciplined | {status} | {detail} |
| Verification-driven | {status} | {detail} |
| CI-enforced | {status} | {detail} |
| Secrets-aware | {status} | {detail} |
| Anti-slop | {status} | {detail} |
| Quality gates | {status} | {detail} |
| Context-efficient | {status} | {detail} |
| Documentation-lean | {status} | {detail} |
| Pre-commit hooks | {status} | {detail} |
| Type-safe | {status} | {detail} |

**Summary:** {ready_count}/12 ready, {risk_count} at risk, {missing_count} missing
```

## Output

1. **Display in A7 summary** — include the readiness report table in the bootstrap completion summary
2. **Save to file** — write to `docs/reference/READINESS_REPORT.md` for future reference
3. **Feed into foundation backlog** — pass Risk and Missing items to A5.9 for story generation

## Extensibility

New checks can be added by:
1. Adding a row to the Readiness Checks table above
2. Adding corresponding classification rules
3. The report generation logic picks up all rows automatically

E9 stories (detection enhancements) add checks for specific capabilities. They only need to update this reference file — the report generation in SKILL.md remains unchanged.
