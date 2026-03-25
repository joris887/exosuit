# Foundation Backlog Generation Reference

Reference loaded by `/bootstrap` Path A step A5.9. Auto-generates dependency-ordered foundation stories from the Readiness Report (A5.8).

## Purpose

Existing repos typically need infrastructure work before feature development can follow framework methodology. Bootstrap detects these gaps; this step turns them into actionable, dependency-ordered stories. Stories at each level require all previous levels to be complete. Measurable improvement stories recommend `/optimize` as the execution method.

## Story Generation Mapping

For each Readiness Report item classified as `⚠️ Risk` or `✗ Missing`, generate a foundation story at the appropriate dependency level:

| Readiness Check | If Missing (✗) | If Risk (⚠️) | Level |
|----------------|-----------------|--------------|-------|
| TDD-first (no test runner) | `[Infrastructure]` Set up test framework for {language} | — | 0 |
| TDD-first (no coverage) | `[Infrastructure]` Install and configure coverage tool ({tool}) | — | 0 |
| TDD-first (low coverage) | — | `[Testing]` Improve test coverage to ≥60% (currently {pct}%) | 2 |
| TDD-first (no mutation testing) | — | `[Infrastructure]` Install and configure mutation testing tool ({tool}) | 2 |
| TDD-first (no PBT framework) | — | `[Infrastructure]` Install property-based testing framework ({tool}) | 2 |
| Sprint-based | — (unlikely for existing repos) | `[Infrastructure]` Clean up git state | 0 |
| Git-disciplined (no remote) | `[Infrastructure]` Configure git remote | — | 0 |
| Verification-driven (tests fail) | `[Infrastructure]` Fix failing tests ({count} failures) | — | 1 |
| CI-enforced (no CI) | `[Infrastructure]` Set up CI/CD pipeline with framework PR review | `[Infrastructure]` Add framework PR review workflow to existing CI | 3 |
| Secrets-aware | `[Infrastructure]` Configure post-edit secrets scanning hook | — | 1 |
| Anti-slop | — (framework provides this) | — | — |
| Quality gates (no formatter) | `[Infrastructure]` Install and configure {formatter} with project config file | — | 0 |
| Quality gates (no linter) | `[Infrastructure]` Install and configure {linter} with project config file | — | 0 |
| Quality gates (no coverage) | See TDD-first coverage row | See TDD-first coverage row | 0 |
| Quality gates (no type checker) | `[Infrastructure]` Install and configure type checker ({tool}) | — | 0 |
| Quality gates (lint warnings) | — | `[Testing]` Eliminate lint warnings | 2 |
| Quality gates (type errors) | — | `[Testing]` Fix type errors | 2 |
| Context-efficient (oversized files) | `[Refactoring]` Split oversized files to ≤500 LOC | — | 3 |
| Context-efficient (high fan-out) | — | `[Refactoring]` Reduce coupling in {module} (fan-out: {count}) | 3 |
| Context-efficient (circular deps) | `[Refactoring]` Break circular dependency between {module_a} and {module_b} | — | 3 |
| Documentation-lean | — (bootstrap just generated docs) | `[Documentation]` Review and complete generated documentation | 1 |
| Pre-commit hooks | `[Infrastructure]` Set up pre-commit hooks for {stack} | — | 2 |
| Type-safe (not configured) | `[Infrastructure]` Configure type checking ({tool}) for {language} | — | 1 |
| Ground-rules-governed (no rules) | `[Architecture]` Define project ground rules | — | 2 |
| Technical debt (high severity) | `[Infrastructure]` Address high-severity technical debt items | `[Refactoring]` Address medium-severity technical debt items | 3 |

## Dependency Levels

Foundation stories are organized into dependency levels. Stories at Level N require all Level N-1 stories to be complete. Only generate stories for detected gaps — skip levels with no stories.

### Level 0: Install Tools (no dependencies)

Stories that install missing tools. These have no prerequisites — they add capabilities the rest of the foundation depends on.

**Typical stories:** Install test framework, formatter (with config), linter (with config), coverage tool, type checker, configure git remote, clean git state.

**Execution method:** `/story-cycle` — these are one-shot installation tasks.

### Level 1: Configure & Stabilize (depends on Level 0)

Stories that configure commands in CLAUDE.md, fix broken baselines, and enable the tools installed in Level 0.

**Typical stories:** Fix failing tests, configure type checker, configure secrets hook, review generated documentation.

**Execution method:** `/story-cycle` — these require investigation and targeted fixes.

### Level 2: Measurable Improvements (depends on Level 1)

Stories that improve metrics toward framework thresholds. These have measurable targets and benefit from iterative optimization.

**Typical stories:** Improve coverage to ≥60%, eliminate lint warnings, fix type errors, set up pre-commit hooks, define ground rules.

**Execution method for measurable stories:** `/optimize` — these have numeric targets:

| Story | Metric command | Target | Direction |
|-------|---------------|--------|-----------|
| Improve test coverage | `{coverage_metric_command}` | 60 | max |
| Eliminate lint warnings | `{lint_metric_command}` | 0 | min |
| Fix type errors | `{typecheck_metric_command}` | 0 | min |

The metric commands are stack-specific — bootstrap substitutes the actual detected commands from the Readiness Report's Optimization Metrics section. See `references/readiness-report.md`.

**Execution method for non-measurable stories:** `/story-cycle` (pre-commit hooks, ground rules).

### Level 3: Structural Improvements (depends on Level 2, optional for starting features)

Refactoring and CI stories. These require the test safety net from Level 2 (tests passing, coverage adequate) because they change code structure.

**Typical stories:** Split oversized files, break circular dependencies, reduce coupling, set up CI pipeline, address technical debt.

**Execution method for measurable stories:** `/optimize`:

| Story | Metric command | Target | Direction |
|-------|---------------|--------|-----------|
| Split oversized files | `{file_size_metric_command}` | 0 | min |

**Execution method for others:** `/story-cycle` (CI setup, circular deps, technical debt).

## Framework Ready Gate

Insert this gate in the generated E00-foundation.md **between Level 2 and Level 3 stories**. It defines the minimum threshold for starting feature development.

### Gate Template

```markdown
## Framework Ready Gate

Before starting feature development, verify these minimum thresholds are met.
Run each command — all must pass.

| Check | Command | Threshold | Status |
|-------|---------|-----------|--------|
| Test command works | `{test_command}; echo "exit: $?"` | exit: 0 | ⬜ |
| Tests pass | `{test_command} 2>&1` | ≥1 test passes, 0 failures | ⬜ |
| Coverage ≥ 60% | `{coverage_command}` | ≥ 60% | ⬜ |
| Lint available | `{lint_command} --help` | exits 0 | ⬜ |
| Formatter configured | `{format_command} --help` | exits 0 | ⬜ |
| Ground rules defined | `wc -l < docs/reference/GROUND_RULES.md` | ≥ 10 lines, ≥ 3 MUST/SHOULD rules | ⬜ |

> **After all gate checks pass**, you can start feature development with `/ideate`.
> Level 3 stories below are recommended but not required to start features.
```

### Gate Rules

- Level 3 stories are OPTIONAL for starting feature work — they improve the project but don't block the framework's core workflow
- If a check cannot be satisfied for this stack (e.g., no coverage tool exists for this language), mark as N/A with explanation
- The gate can be verified by running `/doctor` or manually checking the commands
- Substitute `{test_command}`, `{coverage_command}`, `{lint_command}`, `{format_command}` with the actual detected commands from bootstrap step A2

## Story Template

Each generated story follows this structure:

```markdown
### E00-S{nn}: {title}

**Type:** {Infrastructure|Testing|Refactoring|Documentation|Architecture}
**Priority:** {P0|P1|P2}
**Level:** {0|1|2|3}
**Source:** Framework Readiness Report — {principle} ({status})
**Execution method:** {see below}

**Description:**
{What needs to be done and why, referencing the specific gap detected by bootstrap.}

**Acceptance Criteria:**
- [ ] {Specific, verifiable criterion}
- [ ] {Criterion that proves the gap is closed}
- [ ] Readiness Report would now classify {principle} as ✓ Ready
```

### Execution Method Field

Populate based on story type:

| Story category | Execution method |
|---------------|-----------------|
| Tool installation (Level 0) | `/story-cycle "E00-S{nn}: {title}"` |
| Configuration & fixes (Level 1) | `/story-cycle "E00-S{nn}: {title}"` |
| Measurable improvement (Level 2-3) | `/optimize "{goal}" --metric "{metric_command}" --target {N} --direction {min\|max} --max 30` |
| Non-measurable improvement (Level 2-3) | `/story-cycle "E00-S{nn}: {title}"` |
| Ground rules definition | `/refine-loop "define ground rules" --until "3-7 MUST/SHOULD rules" --max 5` |
| Documentation review | `/refine-loop "review generated docs" --until "no placeholder text remains" --max 5` |

The execution method is a **recommendation**, not a mandate. Users can execute stories however they prefer.

## Priority Assignment

| Source Status | Story Priority | Rationale |
|--------------|---------------|-----------|
| ✗ Missing (TDD-first) | P0 | Framework's #1 principle blocked |
| ✗ Missing (CI, Quality gates) | P1 | Framework functionality degraded |
| ✗ Missing (other) | P1 | Principle non-functional |
| ⚠️ Risk (any) | P2 | Principle functional but fragile |

## Epic File Format

Write to `docs/reference/backlog/E00-foundation.md`:

```markdown
# E00: Foundation

> **Priority:** P0 — Required for framework methodology
> **Source:** Bootstrap Readiness Report ({date})
> **Status:** TODO
> **Stories:** {count} across {level_count} levels

{readiness_report_summary}

---

## Level 0: Install Tools

{Level 0 stories — or "No gaps at this level."}

---

## Level 1: Configure & Stabilize

{Level 1 stories — or "No gaps at this level."}

---

## Level 2: Measurable Improvements

{Level 2 stories — or "No gaps at this level."}

---

## Framework Ready Gate

{gate table with commands filled in from detected stack}

> After all gate checks pass, you can start feature development with `/ideate`.
> Level 3 stories below are recommended but not blocking.

---

## Level 3: Structural Improvements (Optional)

{Level 3 stories — or "No gaps at this level."}
```

## User Review Gate

*** HARD GATE: Present the generated stories to the user before writing. ***

```
Foundation backlog generated from readiness gaps ({count} stories across {level_count} levels):

Level 0 — Install Tools:
  1. [Infrastructure/P0] Set up test framework for Python
  2. [Infrastructure/P1] Install and configure ruff (formatter + linter)

Level 1 — Configure & Stabilize:
  3. [Infrastructure/P1] Fix failing tests (12 failures)

Level 2 — Measurable Improvements:
  4. [Testing/P2] Improve test coverage to ≥60% (currently 42%)
     → /optimize "increase test coverage" --metric "..." --target 60

--- Framework Ready Gate (pass all checks before feature work) ---

Level 3 — Structural Improvements (optional):
  5. [Infrastructure/P1] Set up CI/CD pipeline
  6. [Refactoring/P2] Split oversized files (3 files > 500 LOC)

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
