---
name: bootstrap
version: 2.13.0
description: First-run framework setup. Detects existing project stack or guides new project creation from vision/braindump.
trigger: manual
depends-on: [skill-create]
references: [references/stack-detection.md, references/new-project.md, references/accuracy-safeguards.md, references/coverage-assessment.md, references/quality-tooling.md, references/readiness-report.md, references/foundation-backlog.md, references/llm-readiness.md, references/technical-debt-assessment.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent
---
______________________________________________________________________

## bootstrap

Setting up the JD-LLM Development Framework for this project.

## Process Flow (authoritative — prose below is supporting detail)

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
# Plugin mode: CLAUDE_PLUGIN_ROOT is set by Claude Code
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    echo "Plugin mode: core at $CLAUDE_PLUGIN_ROOT"
else
    echo "Template mode: core at .claude/"
fi
```

**Plugin mode** (`CLAUDE_PLUGIN_ROOT` set): Core framework (hooks, skills, agents, rules, prompts) is installed as a Claude Code plugin. Only scaffold files (docs/, vision/, CLAUDE.md) need to be in the project.

**Template mode** (default): Full framework cloned into the project. Both core and scaffold files are in the project directory.

This affects Path A steps A5.5 (hook configuration) and A5.6 (rule configuration) — in plugin mode, hook and rule configuration is managed by the plugin, not project-level settings.json.

## 1. Detect Project State

Determine which path to follow:

```bash
# Count non-framework source files
find . -type f \
  -not -path './.git/*' \
  -not -path './.claude/*' \
  -not -path './vision/*' \
  -not -path './docs/*' \
  -not -path './scripts/*' \
  -not -path './CLAUDE.md' \
  -not -path './CLAUDE.local.md*' \
  -not -path './README.md' \
  -not -path './AGENTS.md' \
  -not -path './llms.txt' \
  -not -path './install.sh' \
  -not -path './.gitignore' \
  -not -path './.gitkeep' \
  -not -name '.DS_Store' | head -20
```

**If source files exist:** → Path A (Existing Repository)
**If no source files (or only framework files):** → Path B — Read `references/new-project.md` and follow its steps. Path B now includes a domain research step (B2.7) — see `references/new-project.md`.

---

## Path A: Existing Repository

### A1-A3. Detect Stack, Commands, and Measure Codebase

Run `scripts/detect-stack.sh` — execute directly, do NOT read source first.

Read `references/stack-detection.md` for detailed detection tables and commands. This covers:
- Technology stack detection (A1)
- Command detection (A2)
- Documentation state assessment (A2.5)
- **API surface detection (A2.55)** — Scan for API spec files (OpenAPI, AsyncAPI, GraphQL, Proto) and API framework indicators. Record API type, spec files, contract-first status. Feeds into Readiness Report and foundation backlog.
- **Test coverage assessment (A2.6)** — Read `references/coverage-assessment.md` for the full flow: detect coverage tool → offer installation if missing → run coverage → record baseline → flag zero-coverage areas. This data feeds into the Readiness Report (A5.8).
- Architecture assessment (A2.7)
- Codebase metrics (A3)

### A2.8. Assess Type Checking Readiness

Detect whether a type checker is configured for the detected stack:

| Stack | Type Checker | Config Files to Check |
|-------|-------------|----------------------|
| Python | mypy or pyright | `mypy.ini`, `pyrightconfig.json`, `pyproject.toml [tool.mypy]`, `setup.cfg [mypy]` |
| TypeScript | tsc (built-in) | `tsconfig.json` with `"strict": true` |
| Go | Built-in | Always ready |
| Rust | Built-in | Always ready |
| Dart | Built-in | Always ready |
| C# | Built-in | Always ready |
| Java | Built-in (javac) | Always ready |
| Ruby | sorbet or steep | `sorbet/config`, `.steep` directory |
| PHP | phpstan or psalm | `phpstan.neon`, `psalm.xml` |

- **If built-in:** Mark as ready, no action needed.
- **If config found:** Mark as ready, record the type checker in use.
- **If no config found (and not built-in):** Record gap for the Readiness Report and quality tooling offer (A2.85).

### A2.85. Offer Quality Tooling Installation

Read `references/quality-tooling.md` for the complete flow. After detecting the stack and its available tools (including type checker from A2.8), present missing-but-recommended quality tools (formatter, linter, coverage, type checker) with correct install commands for the detected package manager. The user can select which tools to install or decline all. Declined tools are recorded for the Readiness Report and foundation backlog.

**For stacks with built-in tools** (Go, Rust, Dart): note as available, skip the offer for those categories.

Also check for architecture enforcement tools per `references/quality-tooling.md` — Architecture Enforcement Tools section. If the project has clear layered architecture (detected in A2.7) but no enforcement tool, mention it as an informational recommendation (not blocking).

### A2.9. Stack Best Practices Research (Optional)

After detecting the stack, perform a quick research pass to identify current best practices for comparison with the project's actual state.

Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **QUICK** depth:

- **Query:** "Current best practices for [detected primary language] + [detected framework] projects"
- **Sub-questions** (auto-generated from detected stack):
  1. "Recommended testing practices for [framework]"
  2. "Common architecture patterns for [framework] in [current year]"
- **Output format:** `plan-context` (compact, feeds into readiness report)

Integrate findings into the Readiness Report (A5.8) as a "Best Practices Comparison" — informational, not blocking.

**Skip when:** User explicitly requests fast bootstrap (`--skip-research` or answers "skip" when asked), or no internet access is available.

**Allowed tools for this step:** WebSearch, WebFetch, Agent (add to skill-level allowed-tools when composing deep-research).

### A3.1. LLM-Readiness Assessment

Read `references/llm-readiness.md` for the complete assessment flow. Using the codebase metrics from A3, assess whether the code structure supports effective LLM-assisted development:

1. **File size analysis** — flag files exceeding 500 LOC
2. **Fan-out analysis** — identify high-coupling modules (imported by >5 others)
3. **Circular dependency check** — detect mutual import patterns (where feasible)

Record metrics in `docs/progress.md` (codebase size, average file size, largest file, files over threshold). Results feed into the Context-efficient check in the Readiness Report (A5.8). Flagged files generate refactoring stories in the foundation backlog (A5.9).

### A3.2. Technical Debt Assessment

Read `references/technical-debt-assessment.md` for the complete assessment flow. Scan the codebase for common technical debt indicators:

1. **Stale markers** — count TODO, FIXME, HACK, XXX comments
2. **Missing types** — detect untyped code (stack-specific: Python functions without hints, TypeScript `any` usage)
3. **Unsafe patterns** — detect known risky defaults (stack-specific)
4. **Dead code indicators** — detect unused imports where tooling is available

Record detected items in `docs/technical-debt.md` under the matching severity heading, using the full item format (category, severity, origin, location, quantified impact, interest rate, effort, resolution). Set origin to `legacy` for all bootstrap-detected items. Critical/High-severity items generate foundation stories in the foundation backlog (A5.9).

### A3.5. Generate Architecture Overview

Auto-populate `docs/architecture/ARCHITECTURE.md` from code structure. Apply accuracy safeguards from `references/accuracy-safeguards.md` — every claim must reference actual files. Generate all sections of the template:

**Header:** Set project name, one-line purpose, `Last Verified` date to today.

**Tech Stack:** Populate from A1 detection results. Only include non-obvious entries — skip what AI can discover from package files.

**Architecture Overview (Mermaid `flowchart TD`):** Generate a diagram showing:
- Detected entry points as top-level nodes
- Major modules/services as labeled boxes (include technology: `[API Server<br/>Python FastAPI]`)
- Data stores with cylinder notation `[(PostgreSQL)]`
- External integrations and communication protocols on edges (`-->|REST|`, `-->|gRPC|`)
- Use `subgraph` for monorepos with multiple packages/services

**Module Map:** Map top-level source directories to responsibilities. List key entry point files.

**Dependency Rules:** Derive imperative rules from the actual import graph:
1. For each top-level module, identify what it imports from other modules
2. Identify the dependency direction (which modules depend on which)
3. Express as MUST/NEVER/MAY rules: "Controllers MUST only call services. Services NEVER import controllers."
4. If no clear layering exists, note: "No strict layer boundaries detected — consider establishing rules in GROUND_RULES.md"

**Key Data Flow (Mermaid `sequenceDiagram`):** Identify the primary user-facing operation and trace it through the system. For APIs: the most common endpoint. For CLIs: the main command flow. For libraries: the primary public API usage.

**Constraints:** Populate from CI config (timeout values → performance constraints), compliance markers in code (GDPR, SOC2, HIPAA references), version constraints (`engines`, minimum runtime versions). If nothing detected, leave with a guidance comment.

**Key Decisions:** If `docs/adr/` contains ADRs, summarize top 3-5 with trade-offs and populate the `## Architecture Rules` section in CLAUDE.md with the most critical ADR-derived constraints (format: `- [constraint] (ADR-NNNN)`). Otherwise, infer major technology choices from config (ORM, auth library, test framework) and suggest creating retroactive ADRs for undocumented decisions — list 2-3 candidate topics (e.g., "Why PostgreSQL over MongoDB?", "Why REST over GraphQL?") based on detected technologies.

**Quality Attributes:** Seed from Readiness Report data (A5.8): coverage baseline, CI requirements, type safety status.

**Cross-cutting Concerns:** Detect from codebase patterns — grep for error handling (try/catch, error middleware), logging (logging/winston/structlog/slog), authentication (auth middleware, JWT, sessions), validation (zod, pydantic, joi), configuration (dotenv, config loaders). One line per concern detected.

**Known Landmines:** Seed from A3.2 (Technical Debt) and A3.1 (LLM-readiness) data: files with high TODO/FIXME/HACK counts, circular dependencies, files > 500 LOC, `@deprecated` markers. If nothing detected, leave empty with guidance comment.

**Update Triggers:** Pre-populated (generic, applies to all projects): new modules/services added, data stores changed, API boundaries changed, dependency rules violated intentionally, deployment topology changed.

### A3.55. Generate Project Context Knowledge Base

Populate `docs/context/` files by analyzing the codebase. Apply accuracy safeguards from `references/accuracy-safeguards.md`:

- `project-overview.md` — What the project does, who it's for, core workflows
- `tech-context.md` — Stack, key libraries, API contracts, data layer
- `system-patterns.md` — Design patterns, conventions, error handling
- `project-structure.md` — Directory layout, module responsibilities, data flow
- `product-context.md` — Domain terminology, user personas, feature areas

Each file: ≤200 lines, evidence-based claims only, update YAML frontmatter timestamps.

### A3.5b. Establish Project Ground Rules

Prompt the user for 3-7 non-negotiable architectural principles. Populate `docs/reference/GROUND_RULES.md`:

- Fill the **Architecture Summary** with 2-3 sentences describing the pattern and key technology choices
- Walk through categories systematically — start with the 3 essential categories (dependencies, boundaries, data-flow), then ask about recommended categories based on context:
  - Security-sensitive stack (auth, payments, PII) → recommend security category
  - AI-assisted development → recommend technology category (locks choices, prevents AI introducing unapproved libs)
  - APIs or microservices → suggest api-design category
  - Production system with SLOs → suggest operational category
- Ask: "What architectural rules should NEVER be broken in this project?" Give examples from the BOOTSTRAP DEFAULTS comment in GROUND_RULES.md, selecting the section matching the detected architecture
- For each principle, use the `GR-NNN` format with fields: **Level** (MUST/SHOULD), **Category** (dependencies/boundaries/data-flow/security/technology/operational), **Statement** (one sentence with RFC 2119 keyword), **Rationale** (what breaks if violated), **Enforced-by** (ai/review/auto check), **Exceptions** (process or "None")
- If the user has no strong preferences, suggest 3-5 principles from the matching architecture defaults plus universal defaults
- **Brownfield baseline (Path A only):** If a new rule is defined but existing code already violates it, document existing violations in the Exception Log with scope "pre-existing", and suggest a foundation story to remediate incrementally. Rules that can't be enforced today are aspirational, not ground rules.
- The ground rules are checked during `/story-cycle` planning (Phase 1e), `/sprint-end` quality gates, `/architecture-check`, `/code-quality`, and `/weekly-maintenance`


### A3.5c. Team Detection

Check for team indicators:
- `.github/CODEOWNERS` exists → team project
- Multiple contributors in git log → team project
- Branch protection rules configured → team project

```bash
CONTRIBUTORS=$(git log --format="%aE" | sort -u | wc -l | tr -d ' ')
if [ "$CONTRIBUTORS" -gt 1 ] || [ -f ".github/CODEOWNERS" ]; then
    echo "Team project detected ($CONTRIBUTORS contributors)"
fi
```

**If team detected:**
- Suggest configuring CODEOWNERS if it doesn't exist
- Mention `docs/reference/TEAM_WORKFLOW.md` in the summary
- Add "Team coordination" to the readiness report
- **Size-based guidance** (based on `$CONTRIBUTORS` count):
  - **2–5 contributors:** "Small team — shared CLAUDE.md and informal review are sufficient. See TEAM_WORKFLOW.md for lightweight coordination patterns."
  - **6–15 contributors:** "Medium team — formal CODEOWNERS, 200-line PR caps, mandatory AI disclosure, and weekly architecture syncs recommended. See TEAM_WORKFLOW.md scaling guide."
  - **16+ contributors:** "Large team — sub-team decomposition, rotating AI review lead, and architecture fitness functions needed. See TEAM_WORKFLOW.md."

### A3.7. Detect Default Branch

Detect the repository's default branch name and store it in CLAUDE.md so all skills can reference it without guessing:

```bash
# Try remote HEAD first (most reliable for repos with a remote)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

if [ -z "$DEFAULT_BRANCH" ]; then
    # No remote HEAD — check common branch names
    for branch in main master develop; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            DEFAULT_BRANCH="$branch"
            break
        fi
    done
fi

# Final fallback: use current branch
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH=$(git branch --show-current)
fi

echo "Default branch: $DEFAULT_BRANCH"
```

Update CLAUDE.md's Git Workflow section: replace the `<!-- Detected by /bootstrap -->` comment with the detected branch name.

### A4. Generate Configuration

Update these files with detected information:

1. **`CLAUDE.md`** — Fill in Project Overview, Commands, Architecture one-liner, **Default branch** (from A3.7), **Tech Stack** (language + framework + key library versions from lockfiles), **Critical Rules** (promote 3-5 most damaging violations from CODING_STANDARDS.md)
2. **`docs/reference/CODING_STANDARDS.md`** — Fill in language-specific sections following the `<!-- /bootstrap guidance -->` comments in the template. For each detected language:
   - Reference the authoritative base standard (see `references/language-standards.md`)
   - Extract version pins from lockfiles/config (package.json, pyproject.toml, go.mod, Cargo.toml)
   - Fill the naming convention table with language-specific constructs
   - Add 2-3 do/don't code pairs from patterns observed in the existing codebase
   - List detected formatter, linter, and type checker in the Tooling subsection
   - Fill Quality Gates table with thresholds the project can actually enforce
   - Fill Key Commands table from A2 detected commands
3. **`docs/progress.md`** — Initialize with baseline metrics (including LLM-readiness metrics from A3.1)
4. **`docs/reference/TESTING_STRATEGY.md`** — Populate the "Test Infrastructure" section with detected test tooling:

```markdown
## Test Infrastructure

**Test Runner:** {test_framework} {version}
**Test Command:** `{test_command}`
**Fast Feedback:** `{fast_test_command}` (e.g., pytest -x --tb=short, npm test -- --bail)
**Coverage:** `{coverage_command}` (or "Not configured — see foundation backlog")
**Test Location:** {test_directory} (e.g., tests/, __tests__/, alongside source)
**Naming Convention:** {test_pattern} (e.g., test_*.py, *.test.ts, *_test.go)
**Fixtures:** {fixture_files_if_any} (e.g., tests/conftest.py — database session, test client)
```

All data comes from A2 (detect commands) and A2.6 (coverage assessment). If test setup files exist (conftest.py, jest.config.*, vitest.config.*, etc.), document key fixtures and configuration.

### A4.5. Detect MCP Servers (Optional)

Check if any MCP servers are available in the Claude Code environment. If detected, note them in `CLAUDE.md` under a `## MCP Servers` section so skills can conditionally leverage them. See `docs/reference/MCP_INTEGRATION.md` for server categories and integration guidance.

If no MCP servers are detected, skip this step — all skills function without them.

### A5. Run /skill-create

Generate technology-specific skills for the detected stack.

### A5.5. Configure Hooks

Based on detected stack, configure hooks:

- **Formatter detected** → uncomment/configure `post-edit-format.sh` for the language
- **Linter + test runner detected** → configure quality rules in `.claude/hooks/rules/quality.yaml`
- **Safety hooks** → always enabled (already in settings.json)

Update `.claude/settings.json` if adding PostToolUse or Stop hooks.

### A5.6. Configure Rules

Generate path-scoped rules for detected file types:

- If detected language has specific patterns, add to existing rules or create new ones
- Ensure `.claude/rules/testing.md` paths match the project's test file patterns
- Ensure `.claude/rules/dependencies.md` paths match the project's dependency files

### A5.62. Environment Variable Template

Check for `.env` usage and manage the template:

1. **Detect .env usage:**
```bash
# Check for .env references in code
grep -rl 'process\.env\.\|os\.environ\|os\.getenv\|ENV\[' --include='*.py' --include='*.ts' --include='*.js' --include='*.rb' --include='*.go' . 2>/dev/null | head -5
# Check for existing .env files
ls .env .env.* 2>/dev/null
```

2. **If .env is used but .env.example doesn't exist:**
   - Parse `.env` (if exists) to extract variable names (NOT values)
   - Generate `.env.example` with variable names and placeholder values
   - Add `.env` to `.gitignore` if not already present
   - Report: "Created .env.example with [N] variables. Review and customize."

3. **If .env.example exists:** Verify it covers all variables used in code.
   Report gaps if any.

4. **If no .env usage detected:** Skip silently.

### A5.65. Assess Pre-Commit Hook Readiness

Check for existing pre-commit hook infrastructure:

```bash
# Check for pre-commit tools (language-agnostic)
ls .pre-commit-config.yaml 2>/dev/null    # pre-commit (Python ecosystem)
ls -d .husky/ 2>/dev/null                  # Husky (Node.js ecosystem)
ls lefthook.yml 2>/dev/null                # Lefthook (any stack)
ls .git/hooks/pre-commit 2>/dev/null       # Raw git hook
```

- **If found:** Record the tool in use. Mark as ready for the Readiness Report.
- **If not found:** Offer to set up Lefthook for git hook enforcement:

  **If user accepts:**
  1. Check for Lefthook: `lefthook version 2>/dev/null`
  2. If available, create `lefthook.yml`:
     ```yaml
     commit-msg:
       commands:
         conventional:
           run: |
             MSG=$(head -1 {1})
             if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\(.+\))?!?:\ .+'; then
               echo "Commit message must follow Conventional Commits: <type>(<scope>): <description>"
               exit 1
             fi
     pre-push:
       commands:
         branch-check:
           run: |
             BRANCH=$(git rev-parse --abbrev-ref HEAD)
             if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
               echo "Direct push to $BRANCH blocked. Create a pull request instead."
               exit 1
             fi
     ```
  3. If Gitleaks is detected (`gitleaks version 2>/dev/null`), add pre-commit secret scanning:
     ```yaml
     pre-commit:
       parallel: true
       commands:
         secrets:
           run: gitleaks detect --staged --no-banner
     ```
  4. Run `lefthook install`
  5. Record as "Ready" in the Readiness Report
  - If Lefthook not available: suggest installing it (`go install github.com/evilmartians/lefthook@latest` or `brew install lefthook`), generate a foundation story for setup

  **If user declines:** Record gap for the Readiness Report. Generate a low-priority foundation story. The framework's Claude Code hooks protect during AI sessions, but pre-commit hooks protect manual commits too.

### A5.7. Assess CI/CD Foundation

Check for existing CI/CD configuration:

```bash
# Check for CI/CD providers
ls .github/workflows/*.yml 2>/dev/null     # GitHub Actions
ls .gitlab-ci.yml 2>/dev/null              # GitLab CI
ls Jenkinsfile 2>/dev/null                 # Jenkins
ls .circleci/config.yml 2>/dev/null        # CircleCI
ls bitbucket-pipelines.yml 2>/dev/null     # Bitbucket Pipelines
ls .travis.yml 2>/dev/null                 # Travis CI
```

- **If CI/CD found:** Check if the framework's `claude-pr-review.yml` workflow is included. If not, note separately — existing CI exists but framework PR review is missing.
- **If no CI/CD found:** Ask the user if they want to install the framework's GitHub Actions workflow (`claude-pr-review.yml`).
  - **If user accepts:** Copy the workflow to `.github/workflows/claude-pr-review.yml`.
  - **If user declines:** Generate a foundation story in the backlog.
- Feed CI/CD status into the Readiness Report (A5.8) under "CI-enforced".

### A5.75. Document Quality Check

After generating ARCHITECTURE.md, dispatch a fresh sub-agent to test the document from a reader's perspective:

- **Agent type:** Explore (read-only, forked context)
- **Input:** ONLY the generated `docs/architecture/ARCHITECTURE.md` — no conversation history
- **Instructions:** "You are a new developer reading this architecture document for the first time. List: (1) What questions would you have? (2) What's ambiguous or unclear? (3) What context does this assume the reader already has? (4) What's missing that a developer would need?"

Review findings. Fix genuine gaps before presenting the summary to the user.

### A5.8. Framework Readiness Report

Read `references/readiness-report.md` for the complete check definitions and classification rules.

Using data collected in earlier steps (A1-A3, A2.6, A2.8, A2.9, A3.1, A3.2, A3.5b, A3.7, A4, A5.5, A5.65, A5.7), assess each framework principle against the project's actual state. For each principle, classify as `✓ Ready`, `⚠️ Risk`, or `✗ Missing` with a brief explanation.

**Output:**
1. Display the readiness report table in the A7 summary
2. Save to `docs/reference/READINESS_REPORT.md`
3. Pass Risk and Missing items to A5.9 for foundation story generation

### A5.9. Generate Foundation Backlog & Initialize BACKLOG_INDEX.md

Read `references/foundation-backlog.md` for story generation templates.

Based on the Readiness Report (A5.8), auto-generate **dependency-ordered** foundation stories for Risk and Missing items. Stories are organized into four dependency levels:

- **Level 0:** Install missing tools (test framework, formatter, linter, coverage, type checker)
- **Level 1:** Configure commands and fix baselines (CLAUDE.md commands, failing tests, type checker config)
- **Level 2:** Measurable improvements (coverage ≥60%, lint warnings→0, type errors→0, ground rules, pre-commit)
- **Level 3:** Structural improvements (split oversized files, break circular deps, CI pipeline) — optional for starting features

Stories at Level N require all Level N-1 stories to be complete. Level 2+ stories with measurable targets include an `/optimize` execution method with metric command, target, and direction from the Readiness Report's Optimization Metrics section. A **Framework Ready Gate** is inserted between Levels 2 and 3, defining minimum thresholds for starting feature development.

Each story has a type, priority, level, description, execution method, and acceptance criteria. Present to the user for review — they can accept, modify, or discard stories. Write accepted stories to `docs/reference/backlog/E00-foundation.md`.

**Initialize BACKLOG_INDEX.md** — remove template comments and populate with actual content:

```markdown
# Backlog Index

**Last Updated:** {date}

## Status Summary

| Epic | Total | Done | In Progress | TODO |
|------|-------|------|-------------|------|
| E00-foundation | {n} | 0 | 0 | {n} |

## Current Focus

Foundation work: infrastructure and tooling gaps identified by the Framework Readiness Report.

## Epic Files

- @docs/reference/backlog/E00-foundation.md — Foundation (infrastructure + tooling)

## Story ID → Epic Mapping

| Story Range | Epic File |
|-------------|-----------|
| E00-S01 — E00-S{nn} | E00-foundation.md |

## Next Steps

- Run `/sprint-start` to begin foundation work
- Run `/ideate` to generate feature stories after foundation is complete
```

If no foundation stories were generated (all principles Ready), still initialize BACKLOG_INDEX.md with an empty status table and point the user to `/ideate`.

### A5.95. Scaffold Solutions Directory

Create `docs/solutions/` with a `.gitkeep` file. This directory stores structured learnings from completed stories (see `capture-learnings` micro-component). Each solution document has searchable YAML frontmatter (title, tags, module, component) so future story-cycle Phase 1b can grep for prior learnings on affected modules.

Also create `docs/brainstorms/` with a `.gitkeep` file. This directory stores design exploration documents from `/brainstorm` sessions for reference during `/ideate` and `/story-cycle`.

Also create `docs/research/` with a `.gitkeep` file. This directory stores structured research reports from `/research` sessions and spike stories. Reports have searchable YAML frontmatter (title, tags, confidence, date) so future research and story-cycle Phase 1 can check for prior findings.

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

**Stack Research:** [summary of best practices findings from A2.9, or "Skipped" if not run]

**Framework Readiness Report:**
| Principle | Status | Detail |
|-----------|--------|--------|
| [principle] | [✓/⚠️/✗] | [explanation] |
| ... | ... | ... |

**Summary:** [N]/12 ready, [N] at risk, [N] missing

**Foundation Backlog:** [N] stories across [L] levels in E00-foundation (Framework Ready Gate after Level 2: [N] checks) — or "No gaps found — project is ready"

**Files Updated:**
- CLAUDE.md (project overview, commands, architecture)
- docs/reference/CODING_STANDARDS.md (language standards)
- docs/architecture/ARCHITECTURE.md (module overview)
- docs/reference/READINESS_REPORT.md (principle assessment)
- docs/reference/backlog/E00-foundation.md (if gaps found)
- docs/reference/BACKLOG_INDEX.md (initialized)
- docs/progress.md (baseline metrics)

**Hooks Configured:**
- [list of enabled hooks]

**Technology Skills Generated:** [count]

**Next Steps:**
- Foundation work needed? → Run `/sprint-start` to begin with E00-foundation Level 0 stories, then work through levels in order. Use `/optimize` for Level 2+ measurable improvement stories. After passing the Framework Ready Gate, you can start feature work while completing optional Level 3 stories in parallel.
- No foundation work? → Run `/ideate` to plan your next feature, then `/sprint-start`
```

## Graceful Degradation

| Dependency       | If Missing                                              |
|------------------|---------------------------------------------------------|
| Package manager  | Skip dependency analysis, note "manual setup required"  |
| Formatter        | Offer installation (A2.85) → if declined, skip hook config, note in summary and Readiness Report |
| Test runner      | Record "N/A" for test baseline, flag TDD-first as Missing in Readiness Report |
| Coverage tool    | Offer installation → if declined, record "N/A — user declined", flag TDD-first as Risk |
| Type checker     | Offer installation (A2.85) → if declined, flag Type-safe as Missing in Readiness Report |
| CI/CD            | Offer GitHub Actions install (A5.7) → if declined, flag CI-enforced as Missing, generate foundation story |
| Pre-commit hooks | Note gap in Readiness Report (A5.65), generate low-priority foundation story |
| Internet/WebSearch | Skip A2.9 (stack research) silently, note "Research: skipped (no internet)" in summary. All other steps work offline |

## Rules

- NEVER overwrite files that have user content (check for non-template content first)
- ALWAYS show what will be changed before writing
- ALWAYS present a summary with next steps
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
