# Foundation Backlog Generation Reference

Reference loaded by `/bootstrap` Path A step A5.9. Auto-generates foundation stories from the Readiness Report (A5.8).

## Purpose

Existing repos typically need infrastructure work before feature development can follow framework methodology. Bootstrap detects these gaps; this step turns them into actionable stories.

## Story Generation Mapping

For each Readiness Report item classified as `⚠️ Risk` or `✗ Missing`, generate a foundation story:

| Readiness Check | If Missing (✗) | If Risk (⚠️) |
|----------------|-----------------|--------------|
| TDD-first (no test runner) | `[Infrastructure]` Set up test framework for {language} | — |
| TDD-first (no coverage) | `[Infrastructure]` Install and configure coverage tool ({tool}) | `[Testing]` Improve test coverage (currently {pct}%) |
| Sprint-based | — (unlikely for existing repos) | `[Infrastructure]` Clean up git state (resolve conflicts, stash changes) |
| Git-disciplined (no remote) | `[Infrastructure]` Configure git remote | — |
| Verification-driven (tests fail) | `[Infrastructure]` Fix failing tests ({count} failures) | — |
| CI-enforced | `[Infrastructure]` Set up CI/CD pipeline | `[Infrastructure]` Review and complete CI configuration |
| Secrets-aware | `[Infrastructure]` Configure post-edit secrets scanning hook | — |
| Anti-slop | — (framework provides this) | — |
| Quality gates (no formatter) | `[Infrastructure]` Install and configure {formatter} | — |
| Quality gates (no linter) | `[Infrastructure]` Install and configure {linter} | — |
| Quality gates (no coverage) | See TDD-first coverage row | See TDD-first coverage row |
| Context-efficient (oversized files) | `[Refactoring]` Split {file} ({loc} LOC) into modules | — |
| Documentation-lean | — (bootstrap just generated docs) | `[Documentation]` Review and complete generated documentation |

## Story Template

Each generated story follows this structure:

```markdown
### E00-S{nn}: {title}

**Type:** {Infrastructure|Testing|Refactoring|Documentation}
**Priority:** {P0|P1|P2}
**Source:** Framework Readiness Report — {principle} ({status})

**Description:**
{What needs to be done and why, referencing the specific gap detected by bootstrap.}

**Acceptance Criteria:**
- [ ] {Specific, verifiable criterion}
- [ ] {Criterion that proves the gap is closed}
- [ ] Readiness Report would now classify {principle} as ✓ Ready
```

## Priority Assignment

| Source Status | Story Priority | Rationale |
|--------------|---------------|-----------|
| ✗ Missing (TDD-first) | P0 | Framework's #1 principle blocked |
| ✗ Missing (CI, Quality gates) | P1 | Framework functionality degraded |
| ✗ Missing (other) | P1 | Principle non-functional |
| ⚠️ Risk (any) | P2 | Principle functional but fragile |

## Story Ordering

Present stories in this order (highest impact first):
1. Test framework setup (unblocks TDD-first)
2. Coverage tool installation (unblocks coverage tracking)
3. Failing test fixes (unblocks verification)
4. Formatter + linter setup (unblocks quality gates)
5. CI/CD pipeline setup (unblocks CI-enforced)
6. Refactoring oversized files
7. Documentation gaps

## Epic File Format

Write to `docs/reference/backlog/E00-foundation.md`:

```markdown
# E00: Foundation

> **Priority:** P0 — Required for framework methodology
> **Source:** Bootstrap Readiness Report ({date})
> **Status:** TODO
> **Stories:** {count}

{readiness_report_summary}

---

{generated stories in order}
```

## User Review Gate

*** HARD GATE: Present the generated stories to the user before writing. ***

```
Foundation backlog generated from readiness gaps:

  1. [Infrastructure/P0] Set up test framework for Python
  2. [Infrastructure/P1] Install and configure ruff (formatter + linter)
  3. [Infrastructure/P1] Set up CI/CD pipeline
  4. [Testing/P2] Improve test coverage (currently 42%)

Accept all / Modify / Discard? [A/M/D]
```

- **Accept**: Write all stories to E00-foundation.md
- **Modify**: User edits the list (add, remove, reprioritize), then write
- **Discard**: Skip foundation backlog, note "User declined foundation stories" in READINESS_REPORT.md

## Integration with BACKLOG_INDEX.md

After writing E00-foundation.md, update BACKLOG_INDEX.md (see E8-S04):
- Add E00 to the status summary table
- Add E00 to the epic files list
- Add story range mapping
