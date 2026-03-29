---
name: bootstrap
version: 2.14.0
description: First-run framework setup. Detects existing project stack or guides new project creation from vision/braindump.
trigger: manual
depends-on: [skill-create]
references: [references/stack-detection.md, references/new-project.md, references/accuracy-safeguards.md, references/coverage-assessment.md, references/quality-tooling.md, references/readiness-report.md, references/foundation-backlog.md, references/llm-readiness.md, references/technical-debt-assessment.md, references/path-a-detailed-steps.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent
---
______________________________________________________________________

## bootstrap

Setting up the JD-LLM Development Framework for this project.

## Process Flow (authoritative)

```
START → 0. Detect Installation Mode
  → [Plugin mode?]
    → YES: CLAUDE_PLUGIN_ROOT is set, skip .claude/ setup
    → NO: Template mode, .claude/ already in project
  → 1. Detect Project State
    → [Source files exist?]
      → YES: Path A (Existing Repository)
        → A1-A3: Detect stack, commands, assess docs/coverage/architecture, measure codebase
          → A2.8: Assess type checking → A2.85: Offer quality tooling installation
            → A2.9: Stack best practices research (optional, quick depth)
              → A3.1: LLM-readiness assessment → A3.2: Technical debt assessment
                → A3.5: Generate architecture → A3.5b: Establish ground rules
                  → A3.7: Detect default branch
                    → A4: Generate config + populate TESTING_STRATEGY.md
                      → A5: Run /skill-create → A5.5-A5.6: Configure hooks/rules + assess pre-commit + CI/CD
                        → A5.8: Framework Readiness Report → A5.9: Generate foundation backlog
                          → A6: Clean up → A7: Present summary → DONE
      → NO: Path B (New Project)
        → Read references/new-project.md and follow B1-B4
          → B1: Check vision → B2: Guide braindump (if empty)
            → B2.7: Domain research (optional, standard depth)
              → B3: Generate from vision → B4: Present summary → DONE
```

## 0. Detect Installation Mode

Determine whether the framework is running as a **plugin** or as a **template**:

```bash
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    echo "Plugin mode: core at $CLAUDE_PLUGIN_ROOT"
else
    echo "Template mode: core at .claude/"
fi
```

**Plugin mode:** Core framework is a Claude Code plugin. Only scaffold files need to be in the project.
**Template mode (default):** Full framework cloned into the project directory.

This affects A5.5 (hook configuration) and A5.6 (rule configuration) — in plugin mode, these are managed by the plugin.

## 1. Detect Project State

```bash
find . -type f \
  -not -path './.git/*' -not -path './.claude/*' -not -path './vision/*' \
  -not -path './docs/*' -not -path './scripts/*' -not -path './CLAUDE.md' \
  -not -path './CLAUDE.local.md*' -not -path './README.md' -not -path './AGENTS.md' \
  -not -path './llms.txt' -not -path './install.sh' -not -path './.gitignore' \
  -not -path './.gitkeep' -not -name '.DS_Store' | head -20
```

**If source files exist:** → Path A (Existing Repository)
**If no source files:** → Path B — Read `references/new-project.md` and follow B1-B4.

---

## Path A: Existing Repository

### A1-A3. Detect Stack, Commands, and Measure Codebase

Run `scripts/detect-stack.sh` — execute directly, do NOT read source first.

Read `references/stack-detection.md` for detailed detection tables: technology stack (A1), commands (A2), documentation state (A2.5), API surface detection (A2.55), test coverage assessment (A2.6 — read `references/coverage-assessment.md`), architecture assessment (A2.7), codebase metrics (A3).

### A2.8. Assess Type Checking Readiness

Detect whether a type checker is configured for the detected stack:

| Stack | Type Checker | Config Files |
|-------|-------------|--------------|
| Python | mypy/pyright | `mypy.ini`, `pyrightconfig.json`, `pyproject.toml [tool.mypy]` |
| TypeScript | tsc (built-in) | `tsconfig.json` with `"strict": true` |
| Go/Rust/Dart/C#/Java | Built-in | Always ready |
| Ruby | sorbet/steep | `sorbet/config`, `.steep` directory |
| PHP | phpstan/psalm | `phpstan.neon`, `psalm.xml` |

Built-in → mark ready. Config found → mark ready. No config → record gap for Readiness Report and quality tooling offer (A2.85).

### A2.85. Offer Quality Tooling Installation

Read `references/quality-tooling.md` for the complete flow. Present missing-but-recommended quality tools with install commands. Stacks with built-in tools (Go, Rust, Dart): skip those categories. Also check for architecture enforcement tools per `references/quality-tooling.md`.

### A2.9. Stack Best Practices Research (Optional)

Compose `deep-research` at **QUICK** depth: "Current best practices for [language] + [framework]". Integrate findings into Readiness Report as "Best Practices Comparison". Skip with `--skip-research` or no internet.

### A3.1. LLM-Readiness Assessment

Read `references/llm-readiness.md`: file size analysis (>500 LOC), fan-out analysis (>5 importers), circular dependency check. Record metrics in `docs/progress.md`. Results feed into Readiness Report.

### A3.2. Technical Debt Assessment

Read `references/technical-debt-assessment.md`: stale markers (TODO/FIXME/HACK), missing types, unsafe patterns, dead code. Record items in `docs/technical-debt.md`. Critical/High items generate foundation stories.

### A3.5–A5.95. Architecture, Configuration, Hooks, CI, Readiness

Read `references/path-a-detailed-steps.md` for full details:
- **A3.5** Generate ARCHITECTURE.md from code structure (accuracy safeguards apply)
- **A3.55** Generate project context knowledge base (`docs/context/`)
- **A3.5b** Establish ground rules (3-7 principles in `GROUND_RULES.md`)
- **A3.5c** Team detection (CODEOWNERS, contributors, size-based guidance)
- **A3.7** Detect default branch (update CLAUDE.md)
- **A4** Generate config (CLAUDE.md, CODING_STANDARDS.md, progress.md, TESTING_STRATEGY.md)
- **A4.5** Detect MCP servers (optional)
- **A5** Run /skill-create
- **A5.5** Configure hooks (formatter, linter, safety)
- **A5.6** Configure rules (path-scoped for detected file types)
- **A5.62** Environment variable template (.env.example)
- **A5.65** Assess pre-commit hook readiness (Lefthook offer)
- **A5.7** Assess CI/CD foundation (GitHub Actions offer)
- **A5.75** Document quality check (sub-agent review of ARCHITECTURE.md)
- **A5.8** Framework Readiness Report (15 principles → Ready/Risk/Missing)
- **A5.9** Generate foundation backlog + initialize BACKLOG_INDEX.md
- **A5.95** Scaffold solutions/brainstorms/research directories

### A6. Clean Up

- Delete `vision/` directory (not needed for existing repos)
- Remove template placeholder comments from populated docs
- Delete any empty template sections that weren't filled

### A7. Present Summary

```markdown
### Bootstrap Complete (Existing Repository)

**Detected Stack:**
- Languages: [list]
- Package Manager: [name]
- Test Framework: [name] ([count] tests, [coverage]% coverage)
- Linter: [name]
- Formatter: [name]
- Type Checker: [name or "not configured"]
- CI/CD: [provider or "not found"]
- Pre-commit: [tool or "not configured"]

**Commands Configured:**
| Operation | Command |
|-----------|---------|
| Test      | [cmd]   |
| Lint      | [cmd]   |
| Format    | [cmd]   |
| Build     | [cmd]   |
| TypeCheck | [cmd]   |

**Codebase Health:**
- Total: [N] LOC across [N] files (avg [N] LOC/file)
- Largest file: [path] ([N] LOC)
- Files over 500 LOC: [N]
- Technical debt items: [N] critical / [N] high / [N] medium / [N] low

**Stack Research:** [summary or "Skipped"]

**Framework Readiness Report:**
| Principle | Status | Detail |
|-----------|--------|--------|
| [principle] | [✓/⚠️/✗] | [explanation] |

**Summary:** [N]/12 ready, [N] at risk, [N] missing

**Foundation Backlog:** [N] stories across [L] levels in E00-foundation — or "No gaps found"

**Files Updated:**
- CLAUDE.md, docs/reference/CODING_STANDARDS.md, docs/architecture/ARCHITECTURE.md
- docs/reference/READINESS_REPORT.md, docs/reference/backlog/E00-foundation.md (if gaps)
- docs/reference/BACKLOG_INDEX.md, docs/progress.md

**Hooks Configured:** [list]
**Technology Skills Generated:** [count]

**Next Steps:**
- Foundation work? → `/sprint-start` with E00-foundation Level 0, then work through levels. `/optimize` for Level 2+. After Framework Ready Gate, start features.
- No foundation work? → `/ideate` to plan features, then `/sprint-start`
```

## Graceful Degradation

| Dependency       | If Missing                                              |
|------------------|---------------------------------------------------------|
| Package manager  | Skip dependency analysis, note "manual setup required"  |
| Formatter        | Offer installation (A2.85) → if declined, skip hook, note in Readiness Report |
| Test runner      | Record "N/A" for test baseline, flag TDD-first as Missing |
| Coverage tool    | Offer installation → if declined, record "N/A", flag TDD-first as Risk |
| Type checker     | Offer installation (A2.85) → if declined, flag Type-safe as Missing |
| CI/CD            | Offer GitHub Actions (A5.7) → if declined, flag CI-enforced as Missing |
| Pre-commit hooks | Note gap in Readiness Report, generate low-priority foundation story |
| Internet         | Skip A2.9 silently, note "Research: skipped (no internet)" |

## Rules

- NEVER overwrite files that have user content (check for non-template content first)
- ALWAYS show what will be changed before writing
- ALWAYS present a summary with next steps
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
