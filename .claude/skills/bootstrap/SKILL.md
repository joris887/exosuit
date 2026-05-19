---
name: bootstrap
version: 2.13.0
description: First-run framework setup. Detects existing project stack or guides new project creation from vision/braindump.
trigger: manual
depends-on: [skill-create]
references: [references/stack-detection.md, references/new-project.md, references/phase-1-analysis.md, references/discovery-engine.md, references/accuracy-safeguards.md, references/coverage-assessment.md, references/quality-tooling.md, references/readiness-report.md, references/foundation-backlog.md, references/llm-readiness.md, references/technical-debt-assessment.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent, AskUserQuestion
---
______________________________________________________________________

## bootstrap

Setting up the JD-LLM Development Framework for this project.

**Interactive UX:** Read `@.claude/prompts/interactive-ux.md` for the shared protocol. Use AskUserQuestion for all closed-choice interactions. Show progress between major steps. Read `references/question-scaffolding.md` (in the discover skill) for question formatting rules — Rules 7-8 apply here too.

## Process Flow (authoritative — prose below is supporting detail)

```
START → 0. Detect Installation Mode
  → [Plugin mode?]
    → YES: CLAUDE_PLUGIN_ROOT is set, skip .claude/ setup
    → NO: Template mode, .claude/ already in project
  → 0.5. README Management (rename framework README → FRAMEWORK_README.md)
  → 1. Detect Project State
    → [Source files exist?]
      → YES: Path A (Existing Repository)
        → A1-A3: Detect stack, commands, assess docs/coverage/architecture, measure codebase
          → A2.8: Assess type checking → A2.85: Offer quality tooling installation
            → A2.9: Stack best practices research (optional, quick depth)
              → A3.1: LLM-readiness assessment → A3.2: Technical debt assessment
                → A3.5: Generate architecture → A3.5b: Establish ground rules
                  → A3.7: Detect default branch
                    → A3.8: Profile detection (recommend lean/standard/strict)
                      → [Lean?] → Skip A3.1-A3.5c, A5-A5.9, generate minimal docs
                      → A4: Generate config + populate TESTING_STRATEGY.md
                        → A4.2: Generate or update project README.md
                      → A5: Run /skill-create → A5.5-A5.6: Configure hooks/rules + assess pre-commit + CI/CD
                        → A5.8: Framework Readiness Report → A5.9: Generate foundation backlog
                          → A6: Clean up → A7: Present summary → DONE
      → NO: Path B (New Project)
        → Read references/new-project.md for Phase 0 (Idea Capture) ONLY
          → Phase 0: Idea Capture (braindump file / inline description / fast-track)
            → After Phase 0: invoke /discover
              → [Lean profile or --quick?] → /discover --quick
              → [Otherwise] → /discover (auto-detects mode from scale)
              → /discover handles: classification, elicitation, research, vision, backlog, README
            → After /discover: continue with scaffold generation + summary → DONE
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

## 0.5. README Management

Detect and handle the framework's own README before proceeding:

```bash
# Check if README.md is the framework's own README (not a project README)
grep -q "JD-LLM Development Framework" README.md 2>/dev/null && \
grep -q "drop-in development framework" README.md 2>/dev/null
```

**If framework README detected:** Rename to preserve it as a reference:
```bash
mv README.md FRAMEWORK_README.md
```
Report: "Renamed framework README to FRAMEWORK_README.md — reference it anytime for framework documentation."

**If README.md is a scaffold template** (contains `[Project Name]` and `[Brief description`): Leave it — it will be populated in step A4.2 (Path A) or Phase 7D (Path B).

**If README.md is a real project README** (neither framework nor scaffold template): Preserve it unchanged. It will be reviewed for completeness in A4.2.

**If no README.md exists:** One will be generated in step A4.2 (Path A) or Phase 7D (Path B).

---

## 1. Detect Project State

This is a **deterministic routing step**, not a judgment call. Run the command, count the result, route. **Do NOT ask the user to confirm the project state** — the command output is the answer.

```bash
# Count non-framework source files. Exclude every path install.sh creates.
find . -type f \
  -not -path './.git/*' \
  -not -path './.claude/*' \
  -not -path './vision/*' \
  -not -path './docs/*' \
  -not -path './scripts/*' \
  -not -path './scaffold/*' \
  -not -path './core/*' \
  -not -path './.github/*' \
  -not -path './.claude-plugin/*' \
  -not -path './CLAUDE.md' \
  -not -path './CLAUDE.local.md*' \
  -not -path './README.md' \
  -not -path './FRAMEWORK_README.md' \
  -not -path './CONTRIBUTING.md' \
  -not -path './CHANGELOG.md' \
  -not -path './AGENTS.md' \
  -not -path './llms.txt' \
  -not -path './install.sh' \
  -not -path './.gitignore' \
  -not -path './.gitkeep' \
  -not -name '.DS_Store' | head -20
```

**Routing rule:**

- **Output empty (0 source files):** → Path B (New Project). This is the expected, normal state immediately after `./install.sh` on a fresh project. The presence of `.claude/`, `docs/`, `vision/`, `scripts/`, `scaffold/`, README scaffold templates, populated `docs/brain/` templates, etc. is **not unusual** — it's exactly what `install.sh` creates. Proceed directly to Path B without asking the user to confirm or pick between routes.
- **Output non-empty (any source files found):** → Path A (Existing Repository).

For Path B: Read `references/new-project.md` for Phase 0 (Idea Capture), then invoke `/discover` for deep guided elicitation.

**Never present a "what is this project?" multiple-choice question.** If genuinely ambiguous (e.g. the find command returns files but they look like framework debris), pick the route the command output indicates and surface a one-line note in the summary instead of blocking on a confirmation prompt.

---

## Path A: Existing Repository

```
---
**Bootstrap** | Step 1 of 8: Stack Detection
[=>..................] 1 of 8 steps
Coming up: Detecting your technology stack, tools, and codebase metrics
---

Analyzing your project to detect the tech stack, available tools, and
codebase structure. This is automatic — no input needed yet.
```

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

```
---
**Bootstrap** | Step 3 of 8: Quality Tooling
[=====>..............] 3 of 8 steps
Coming up: Installing recommended development tools
---
```

Read `references/quality-tooling.md` for the complete flow. After detecting the stack and its available tools (including type checker from A2.8), present missing-but-recommended quality tools via **AskUserQuestion** with `multiSelect`:

```
header: "Dev tools"
question: "These tools are recommended for your [language] project but aren't
           installed yet. Select which to install now. Skipped tools become
           backlog stories you can tackle later."
multiSelect: true
options:
  - label: "[tool] ([category]) (Recommended)"
    description: "[what it does]. Install: `[command]`. Used by quality gates
                  during development."
  - label: "[tool] ([category]) (Recommended)"
    description: "[what it does]. Install: `[command]`."
  - label: "[tool] ([category])"
    description: "[what it does]. Install: `[command]`. Optional but improves
                  code reliability."
```

If all tools are already available, skip this step with a note: "All recommended tools detected."

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

**Seed `docs/brain/error-patterns.md`:** For files with 3+ stale markers (TODO/FIXME/HACK) or detected unsafe patterns, add an entry to error-patterns.md noting the affected area and common failure patterns for that module. This gives debug-session and context-prime useful context from day one. Format follows the template in error-patterns.md (Brief description, Affected area, Prevention note). Only seed 3-5 entries maximum from the most problematic areas — this file grows organically via record-failure during normal development.

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

### A3.55. Seed the Repo Brain

Populate `docs/brain/` (the LLM-maintained source of truth — see `docs/brain/CLAUDE.md` for the operating model). Every technical claim MUST cite `file:line` or a commit hash. Uncited claims are flagged `[Assumed]` and pending re-verification.

Apply accuracy safeguards from `references/accuracy-safeguards.md`.

**Stable pages** (analyzed once at bootstrap, refined by `/brain-update` later):

- `project-overview.md` — What the project does, who it's for, core workflows
- `tech-context.md` — Stack, key libraries, API contracts, data layer (cite `package.json:N`, `Cargo.toml:N`, etc.)
- `system-patterns.md` — Populate each section with codebase evidence:
  - **Implementation Patterns:** Grep for structural patterns (Controller/Service/Repository classes, middleware chains, factory functions, event handlers). For each, cite a reference file:line.
  - **Architectural Conventions:** Extract naming conventions from file/class/function names across 10+ files. Note import direction rules from the A3.5 dependency graph.
  - **Error Handling Strategy:** Grep for try/catch, error middleware, custom error classes, logging calls. Trace error propagation from data layer to user-facing response.
  - **Testing Conventions:** Analyze test file naming, co-location vs separate dir, assertion library, mock/stub patterns, fixture setup.
  - **Implementation Recipes:** Identify the most common entity type (API endpoint, service, component) and document the step-by-step to add a new one. Reference exemplar file:line.
- `project-structure.md` — Directory layout, module responsibilities, data flow
- `product-context.md` — Domain terminology, feature areas, constraints
- `personas.md` — User personas (see below)

**Volatile pages** (re-derived by `/brain-update` going forward — seed once here):

- `index.md` — Catalog. Populate the Pages tables with last-updated dates set to today. Populate Coverage with the areas the stable pages cover. Leave Gaps empty (will surface from `/ideate`).
- `log.md` — Append the first entry: `## [YYYY-MM-DD HH:MM] bootstrap seed | initial repo brain seeded from codebase analysis` with the list of pages written.
- `current-state.md` — Populate "What Works Now" from existing tests passing + obvious user-facing features. Leave "What's In Progress" and "What Changed Recently" empty (no sprint history yet). Populate "Architectural Constraints" by mirroring the load-bearing patterns from system-patterns.md.

**Append-only pages:** `error-patterns.md` (seeded in A3.2 — see above).

Each stable file: ≤200 lines, evidence-based claims only. Update YAML frontmatter timestamps.

**Persona Generation (Path A):** For projects with user-facing features (web apps, APIs with end users, CLIs with distinct user types), generate `docs/brain/personas.md`:

1. **Infer personas** from codebase signals: role-based directories (admin/, user/), auth roles in code, distinct UI sections, README user descriptions, existing persona docs
2. **Ask the user** via AskUserQuestion:
   ```
   header: "User personas"
   question: "I've identified these user types from your codebase. Are they correct?
              Uncheck any that don't exist, or select 'Other' to add missing ones."
   multiSelect: true
   options: [one per inferred persona with description]
   ```
3. **Generate lean persona cards** (6-field format) for confirmed user types
4. **Ask for primary persona** if more than one confirmed
5. **Save** to `docs/brain/personas.md`

**Skip when:** Project is a library, internal tool with a single user type, or the user says "no personas needed." In these cases, leave `personas.md` as the template with a note: "Single user type — personas not applicable."

### A3.5b. Establish Project Ground Rules

```
---
**Bootstrap** | Step 5 of 8: Ground Rules
[========>...........] 5 of 8 steps
Coming up: Defining architectural rules that protect your codebase
---

Ground rules are non-negotiable architectural principles — they prevent
AI and developers from making choices that break your system. These get
checked automatically during every sprint.
```

Prompt the user for 3-7 non-negotiable architectural principles. Populate `docs/reference/GROUND_RULES.md`:

- Fill the **Architecture Summary** with 2-3 sentences describing the pattern and key technology choices
- **Select categories** — use **AskUserQuestion** with `multiSelect` to let the user pick which categories matter:

```
header: "Categories"
question: "Which ground rule categories matter for your project?
           The first 3 are recommended for all projects."
multiSelect: true
options:
  - label: "Dependencies + Boundaries + Data-flow (Recommended)"
    description: "Essential for all projects. Controls what imports what,
                  where logic lives, and how data moves."
  - label: "Security"
    description: "For apps handling auth, payments, or personal data.
                  Locks down credential handling and data access patterns."
  - label: "Technology"
    description: "Locks tech choices to prevent AI from introducing unapproved
                  libraries. Recommended for AI-assisted development."
  - label: "API design / Operational"
    description: "For APIs, microservices, or production systems with SLOs.
                  Enforces contract-first design and operational standards."
```

- Ask conversationally: "What architectural rules should NEVER be broken in this project?" Give examples from the BOOTSTRAP DEFAULTS comment in GROUND_RULES.md, selecting the section matching the detected architecture
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

Also update `docs/reference/GIT_WORKFLOW.md`: replace generic `main` references in the Branching Model section with the detected default branch name (e.g., if the project uses `develop` as its default branch, update accordingly). This ensures sprint-end and framework-upgrade read the correct branch name from this reference file.

### A3.8. Profile Detection

```
---
**Bootstrap** | Step 4 of 8: Development Profile
[======>.............] 4 of 8 steps
Coming up: Choosing how much ceremony the framework applies
---
```

Analyze project characteristics to recommend a complexity profile. This determines the ceremony level for all framework skills.

**Strict indicators** (2+ present = recommend Strict):
- Compliance/regulatory references: grep for HIPAA, SOC2, PCI-DSS, GDPR, FDA, FedRAMP in any file
- Domain markers: fintech, healthcare, insurance, payments, banking in README or package description
- Multi-service architecture: docker-compose.yml with 3+ services, kubernetes/ or k8s/ directory, terraform/ directory
- Production infrastructure: k8s manifests, terraform configs, multiple deployment environment configs
- Strict CI: branch protection rules, required reviewers, mandatory status checks

**Standard indicators** (default when not clearly Lean or Strict):
- CI/CD configured (.github/workflows/, .gitlab-ci.yml, Jenkinsfile, etc.)
- Test framework detected (from A2)
- Established codebase (>5K LOC from A3 metrics)
- Production deployment target (Dockerfile, deployment configs, CDN configs)

**Lean indicators** (ALL must be true to recommend Lean):
- No CI/CD configuration detected
- No test framework detected OR zero test files
- Small codebase (<2K LOC from A3 metrics)
- No deployment configuration (no Dockerfile, no hosting configs)

Present the recommendation with matched indicators, then use **AskUserQuestion**:

```
header: "Profile"
question: "Based on your project ([list matched indicators]), I recommend
           [profile]. This controls how much ceremony the framework applies.
           You can change this anytime in CLAUDE.md."
options:
  - label: "[Recommended profile] (Recommended)"
    description: "[Full description]. [Why this fits based on matched indicators]."
  - label: "Lean"
    description: "Minimal ceremony. Fast iteration. Best for prototypes, MVPs,
                  internal tools. Fewer quality gates, less documentation."
  - label: "Standard"
    description: "Balanced quality gates + documentation. Best for production apps
                  and APIs. TDD enforced, PR reviews, sprint workflow."
  - label: "Strict"
    description: "Maximum rigor with audit trail. Best for regulated, high-stakes,
                  or compliance-sensitive projects. All gates mandatory, ADRs required."
```

Note: Show the recommended profile first with `(Recommended)`. The remaining 2 options are the other profiles (don't repeat the recommended one).

Store the chosen profile: write `**Profile:** <choice>` to CLAUDE.md in step A4.

<IF condition="Profile is lean (chosen or detected)">
**Lean mode bootstrap:** After profile selection, skip these steps:
- A2.5-A2.9 (documentation assessment, architecture assessment, best practices research)
- A3.1-A3.2 (LLM-readiness assessment, technical debt assessment)
- A3.5-A3.5c (architecture overview, context knowledge base, ground rules, team detection)
- A5-A5.9 (skill-create, hook/rule configuration, CI/CD setup, readiness report, foundation backlog)

Generate only:
- CLAUDE.md with commands section populated (test, lint, format, build, typecheck from A2)
- README.md (project README from detected info — A4.2 still runs in lean mode)
- docs/progress.md (minimal template)
- .gitignore with stack-specific patterns

Still perform: A1 (stack detection), A2 (command detection), A2.85 (quality tooling offer), A3.7 (default branch), A4 (CLAUDE.md configuration — lean subset), A4.2 (README generation).
</IF>

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

### A4.2. Generate or Update Project README

Ensure the project has a proper `README.md` using information gathered in A1-A3.

**If no README.md exists (or only the scaffold template with `[Project Name]` placeholders):**
Generate a complete README with these sections (cognitive funnel — broadest first):

1. **Title:** Project name from `package.json` name, `pyproject.toml` [project] name, `go.mod` module, `Cargo.toml` [package] name, or git remote / directory name as fallback
2. **Description:** From `package.json` description, `pyproject.toml` description, `Cargo.toml` description, or `go.doc` comment. If none found, write a one-liner from the Project Overview in CLAUDE.md
3. **Prerequisites:** Detected runtime + version from A1 (e.g., "Python 3.11+", "Node 20+"). Include required system tools
4. **Getting Started:** Clone URL (from `git remote get-url origin`), install command, and dev/run command from A2
5. **Development:** Table of commands from A2 — test, lint, format, build, typecheck. Only include commands that were actually detected
6. **Project Structure:** Top-level directory overview from A2.7 architecture assessment. List each top-level source directory with a one-line description of its responsibility. In lean mode (A2.7 skipped), use a basic `ls` of top-level directories instead
7. **Contributing:** Link to `CONTRIBUTING.md` if it exists. Otherwise: "See `docs/reference/CODING_STANDARDS.md` for conventions and `docs/reference/GIT_WORKFLOW.md` for branch/commit rules."
8. **License:** Detect from `LICENSE`, `LICENSE.md`, or `LICENSE.txt`. Show the license type (MIT, Apache-2.0, etc.). If no license file found, leave as a placeholder

**If project has an existing README.md (real content, not scaffold template):**
Do NOT overwrite. Check for these standard sections and note missing ones in the A7 summary:
- Prerequisites / Installation / Getting Started
- Development commands (test, lint, build)
- Project structure
- Contributing
- License

Report: "Existing README preserved. Consider adding: [list of missing sections]."

### A4.4. Update llms.txt

Update `llms.txt` with project-specific information from bootstrap results. Replace the generic framework description with: project name, one-line purpose (from CLAUDE.md Project Overview), detected tech stack, and key documentation paths. This file is consumed by `/framework-upgrade` for version comparisons and serves as an external LLM context entry point.

### A4.5. Detect MCP Servers (Optional)

Check if any MCP servers are available in the Claude Code environment. If detected, note them in `CLAUDE.md` under a `## MCP Servers` section so skills can conditionally leverage them. See `docs/reference/MCP_INTEGRATION.md` for server categories and integration guidance.

If no MCP servers are detected, skip this step — all skills function without them.

### A5. Run /skill-create

```
---
**Bootstrap** | Step 6 of 8: Configuration
[===========>........] 6 of 8 steps
Coming up: Generating skills, configuring hooks, and setting up CI/CD
---
```

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

5. **Populate SECRETS_INVENTORY.md** (if .env usage detected): Create `docs/reference/SECRETS_INVENTORY.md` from the scaffold template. For each detected environment variable, add a row with: variable name, inferred type (api_key, database_credential, jwt_signing, config — based on naming patterns), environment (all), storage (env_file), classification (critical if name contains SECRET/KEY/TOKEN/PASSWORD, standard otherwise). Leave Last Rotated, Next Due, and Rotation Method as "—" for the user to fill. This enables weekly-maintenance's secret rotation checking from day one.

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
- **If not found:** Offer to set up Lefthook via **AskUserQuestion**:

```
header: "Git hooks"
question: "No pre-commit hooks detected. Lefthook can enforce conventional
           commits and block direct pushes to main — protecting manual
           commits (the framework already protects AI sessions via its own hooks)."
options:
  - label: "Yes, set up Lefthook (Recommended)"
    description: "Installs Lefthook with conventional commit validation and
                  branch protection. Takes ~1 minute."
  - label: "Skip for now"
    description: "No pre-commit hooks. A low-priority backlog story will be
                  created. The framework's own hooks still protect AI sessions."
  - label: "I use a different tool"
    description: "Tell me which tool (Husky, pre-commit, etc.) and I'll
                  configure it instead."
```

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
- **If no CI/CD found:** Use **AskUserQuestion**:

```
header: "CI/CD"
question: "No CI/CD pipeline detected. The framework includes a GitHub Actions
           workflow for automated PR review — it checks code quality on every
           pull request."
options:
  - label: "Install GitHub Actions (Recommended)"
    description: "Adds claude-pr-review.yml to .github/workflows/. Runs
                  quality checks on every PR automatically."
  - label: "Skip for now"
    description: "No CI/CD. A backlog story will be created. Quality checks
                  will only run locally during AI sessions."
  - label: "I use a different CI"
    description: "Tell me your CI provider (GitLab CI, CircleCI, etc.)
                  and I'll note it for manual setup."
```

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

```
---
**Bootstrap** | Step 7 of 8: Readiness Assessment
[===============>....] 7 of 8 steps
Coming up: Assessing how ready your project is for framework-powered development
---
```

Read `references/readiness-report.md` for the complete check definitions and classification rules.

Using data collected in earlier steps (A1-A3, A2.6, A2.8, A2.9, A3.1, A3.2, A3.5b, A3.7, A4, A5.5, A5.65, A5.7), assess each framework principle against the project's actual state. For each principle, classify as `✓ Ready`, `⚠️ Risk`, or `✗ Missing` with a brief explanation.

**Output:**
1. Display the readiness report table in the A7 summary
2. Save to `docs/reference/READINESS_REPORT.md`
3. Pass Risk and Missing items to A5.9 for foundation story generation

### A5.9. Generate Foundation Backlog & Initialize BACKLOG_INDEX.md

```
---
**Bootstrap** | Step 7 of 8: Foundation Backlog
[=================>..] 7 of 8 steps
Coming up: Generating stories for gaps found in the readiness report
---
```

Read `references/foundation-backlog.md` for story generation templates.

Based on the Readiness Report (A5.8), auto-generate **dependency-ordered** foundation stories for Risk and Missing items. Stories are organized into four dependency levels:

- **Level 0:** Install missing tools (test framework, formatter, linter, coverage, type checker)
- **Level 1:** Configure commands and fix baselines (CLAUDE.md commands, failing tests, type checker config)
- **Level 2:** Measurable improvements (coverage ≥60%, lint warnings→0, type errors→0, ground rules, pre-commit)
- **Level 3:** Structural improvements (split oversized files, break circular deps, CI pipeline) — optional for starting features

Stories at Level N require all Level N-1 stories to be complete. Level 2+ stories with measurable targets include an `/optimize` execution method with metric command, target, and direction from the Readiness Report's Optimization Metrics section. A **Framework Ready Gate** is inserted between Levels 2 and 3, defining minimum thresholds for starting feature development.

Each story has a type, priority, level, description, execution method, and acceptance criteria. Present stories to the user and use **AskUserQuestion** for approval:

```
header: "Foundation"
question: "I've generated [N] foundation stories across [L] levels based on
           the readiness gaps. Review the stories above. Ready to finalize?"
options:
  - label: "Accept all (Recommended)"
    description: "Write all stories to the foundation backlog. You can
                  modify individual stories later during sprint planning."
  - label: "I want to remove some"
    description: "Tell me which stories to drop — I'll adjust dependencies."
  - label: "Skip foundation backlog"
    description: "No foundation stories. Go straight to feature work.
                  Note: some framework features won't work without foundation."
```

Write accepted stories to `docs/reference/backlog/E00-foundation.md`.

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

Also create `docs/reviews/` with a `.gitkeep` file. This directory stores phase review findings from `/phase-review` sessions (walkthrough results, direction decisions). Required by Phase Transition Stories.

### A6. Clean Up

- Delete `vision/` directory (not needed for existing repos)
- Delete `scaffold/` directory if present (template-mode artifact, contents already installed)
- Remove template placeholder comments from populated docs
- Delete any empty template sections that weren't filled

### A7. Present Summary

```
---
**Bootstrap** | Step 8 of 8: Complete!
[====================] 8 of 8 steps
---
```

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
- README.md (project README — generated or existing preserved)
- FRAMEWORK_README.md (framework documentation — renamed from original README.md, if applicable)
- CLAUDE.md (project overview, commands, architecture, profile, default branch)
- docs/reference/CODING_STANDARDS.md (language standards)
- docs/architecture/ARCHITECTURE.md (module overview)
- docs/brain/* (repo brain — 7 stable pages + index.md + log.md + current-state.md)
- docs/reference/GROUND_RULES.md (architectural principles)
- docs/reference/TESTING_STRATEGY.md (test infrastructure)
- docs/reference/READINESS_REPORT.md (principle assessment)
- docs/reference/GIT_WORKFLOW.md (personalized with default branch)
- docs/reference/SECRETS_INVENTORY.md (if .env usage detected)
- docs/reference/backlog/E00-foundation.md (if gaps found)
- docs/reference/BACKLOG_INDEX.md (initialized)
- docs/progress.md (baseline metrics)
- docs/technical-debt.md (detected debt items)
- docs/brain/error-patterns.md (seeded from debt scan)
- llms.txt (project-specific summary)

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
