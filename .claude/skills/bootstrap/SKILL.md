______________________________________________________________________

## name: bootstrap description: First-run framework setup. Detects existing project stack or guides new project creation from vision/braindump. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Setting up the JD-LLM Development Framework for this project.

## Process Flow (authoritative — prose below is supporting detail)

```
START → 1. Detect Project State
  → [Source files exist?]
    → YES: Path A (Existing Repository)
      → A1: Detect stack → A2: Detect commands → A2.5: Assess docs
        → A2.6: Assess coverage → A2.7: Assess architecture
          → A3: Measure codebase → A3.5: Generate architecture
            → A4: Generate config → A5: Run /skill-create
              → A5.5: Configure hooks → A5.6: Configure rules
                → A6: Clean up → A7: Present summary → DONE
    → NO: Path B (New Project)
      → B1: Check vision/ content
        → [Vision files exist?]
          → YES: B3: Generate from vision → B4: Present summary → DONE
          → NO: B2: Guide braindump → B2.5: Accept inline braindump
            → B3: Generate from vision → B4: Present summary → DONE
```

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
**If no source files (or only framework files):** → Path B (New Project)

---

## Path A: Existing Repository

### A1. Detect Technology Stack

Scan for project configuration files:

| File                   | Indicates                    |
| ---------------------- | ---------------------------- |
| `package.json`         | Node.js / JavaScript / TS    |
| `pyproject.toml`       | Python (modern)              |
| `setup.py`/`setup.cfg` | Python (legacy)              |
| `Cargo.toml`          | Rust                         |
| `Package.swift`       | Swift                        |
| `go.mod`              | Go                           |
| `pom.xml`/`build.gradle` | Java / Kotlin             |
| `Gemfile`             | Ruby                         |
| `*.csproj`/`*.sln`    | C# / .NET                   |
| `CMakeLists.txt`      | C / C++                      |
| `composer.json`       | PHP                          |
| `pubspec.yaml`        | Dart / Flutter               |

For each detected config file, extract:

- **Languages** and versions
- **Package manager** (npm, yarn, pnpm, bun, pip, uv, cargo, etc.)
- **Build tool** (webpack, vite, just, make, gradle, etc.)
- **Test framework** (jest, pytest, cargo test, swift test, go test, etc.)
- **Linter/formatter** (eslint, ruff, clippy, swiftlint, prettier, etc.)
- **CI/CD** (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc.)

### A2. Detect Commands

Identify the project's key commands:

```bash
# Check for task runners
cat Makefile 2>/dev/null | head -30
cat justfile 2>/dev/null | head -30
cat package.json 2>/dev/null | python3 -c "import sys,json; [print(f'  {k}: {v}') for k,v in json.load(sys.stdin).get('scripts',{}).items()]"
```

Map to standard operations:

| Operation   | Detected Command |
| ----------- | ---------------- |
| Test        | `{test_command}` |
| Lint        | `{lint_command}`  |
| Format      | `{format_command}` |
| Build       | `{build_command}` |
| Type Check  | `{typecheck_command}` |
| Dev Server  | `{dev_command}`  |

### A2.5. Assess Documentation State

Check which docs exist and whether they contain real content or only template placeholders:

- `docs/architecture/ARCHITECTURE.md` — exists? populated?
- `docs/reference/CODING_STANDARDS.md` — exists? populated?
- `docs/reference/TESTING_STRATEGY.md` — exists? populated?
- `docs/progress.md` — has sprint entries?

### A2.6. Assess Test Coverage

Run coverage tool if available to establish a baseline:

```bash
# Detect and run coverage (adapt to detected framework)
# pytest --cov=src --cov-report=term-missing -q
# npx jest --coverage --silent
# go test -cover ./...
# cargo tarpaulin --skip-clean -o stdout
```

Record baseline in progress.md.

### A2.7. Assess Architecture

Scan directory structure to identify:

- Module boundaries (top-level directories, package structure)
- Entry points (main files, index files, app files)
- Configuration layers (env files, config directories)

### A3. Measure Codebase

```bash
# File counts and languages
find . -name '*.py' -not -path './.git/*' | wc -l
find . -name '*.ts' -o -name '*.tsx' -not -path './.git/*' | wc -l
find . -name '*.swift' -not -path './.git/*' | wc -l
find . -name '*.rs' -not -path './.git/*' | wc -l
find . -name '*.go' -not -path './.git/*' | wc -l

# Test count (adapt to detected framework)
# pytest: pytest --collect-only -q | tail -1
# jest: npx jest --listTests | wc -l
# swift test: swift test list 2>/dev/null | wc -l
```

### A3.5. Generate Architecture Overview

Auto-populate `docs/architecture/ARCHITECTURE.md` from code structure:

- List top-level modules and their responsibilities
- Identify module boundaries and dependencies
- Note entry points and data flow direction
- Keep it brief — a starting point for the developer to refine

### A4. Generate Configuration

Update these files with detected information:

1. **`CLAUDE.md`** — Fill in Project Overview, Commands, Architecture one-liner
2. **`docs/reference/CODING_STANDARDS.md`** — Fill in language-specific sections
3. **`docs/progress.md`** — Initialize with baseline metrics

### A5. Run /skill-create

Generate technology-specific skills for the detected stack.

### A5.5. Configure Hooks

Based on detected stack, configure hooks:

- **Formatter detected** → uncomment/configure `post-edit-format.sh` for the language
- **Linter + test runner detected** → uncomment/configure `pre-stop-quality.sh`
- **Safety hooks** → always enabled (already in settings.json)

Update `.claude/settings.json` if adding PostToolUse or Stop hooks.

### A5.6. Configure Rules

Generate path-scoped rules for detected file types:

- If detected language has specific patterns, add to existing rules or create new ones
- Ensure `.claude/rules/testing.md` paths match the project's test file patterns
- Ensure `.claude/rules/dependencies.md` paths match the project's dependency files

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
- CI/CD: [provider]

**Commands Configured:**
| Operation | Command |
|-----------|---------|
| Test      | [cmd]   |
| Lint      | [cmd]   |
| Format    | [cmd]   |
| Build     | [cmd]   |

**Files Updated:**
- CLAUDE.md (project overview, commands, architecture)
- docs/reference/CODING_STANDARDS.md (language standards)
- docs/architecture/ARCHITECTURE.md (module overview)
- docs/progress.md (baseline metrics)

**Hooks Configured:**
- [list of enabled hooks]

**Technology Skills Generated:** [count]

**Next Steps:**
- Run `/ideate` to plan your next feature
- Run `/sprint-start` to begin a sprint
```

---

## Path B: New Project

### B1. Check for Vision Content

```bash
ls vision/ 2>/dev/null
```

**If `vision/` has content (beyond README and BRAINDUMP_PROMPT.md):** → B3 (Generate from vision)
**If empty:** → B2 (Guide braindump)

### B2. Guide Braindump

Present the braindump flow:

```markdown
### New Project Setup

No existing codebase detected. Let's build your project from an idea.

**Option 1 — Deep Research (recommended for complex projects):**

1. Open `vision/BRAINDUMP_PROMPT.md` — it contains a structured research prompt
2. Copy the research prompt into a Claude Project (or ChatGPT, Perplexity, etc.)
3. Fill in the `[YOUR IDEA HERE]` section with your raw idea
4. Have a research conversation — explore the problem space deeply
5. Save the structured output back to `vision/` (as .md files)
6. Run `/bootstrap` again to generate your project structure

**Option 2 — Quick Start:**

Describe your idea now and I'll ask clarifying questions to build a complete picture.
```

### B2.5. Accept Inline Braindump

If the user types their idea directly, transition to iterative questioning mode:

1. Acknowledge the idea
2. Ask 5-10 clarifying questions covering:
   - Problem statement and target users
   - Technical constraints and preferences
   - Similar products or prior art
   - Non-negotiable requirements
   - Scale and performance needs
   - Security and compliance requirements
3. After gathering answers, synthesize into a vision document
4. Save to `vision/braindump-output.md`
5. Continue to B3

### B3. Generate from Vision

Read all files in `vision/` and generate:

1. **`docs/reference/PRD_SUMMARY.md`** — Extract requirements, goals, users, use cases
2. **`docs/architecture/ARCHITECTURE.md`** — Extract or propose architecture
3. **`docs/reference/BACKLOG_INDEX.md`** — Create epic structure
4. **`docs/reference/backlog/E01-*.md` through `E0N-*.md`** — Epic files with typed stories
5. **`CLAUDE.md`** — Fill in overview, architecture one-liner, current focus
6. **`docs/reference/CODING_STANDARDS.md`** — Fill if stack is specified in vision
7. **`.claude/rules/`** — Generate rules tailored to proposed stack
8. **`.gitignore`** — Add language-specific patterns for proposed stack

Stories should be typed (feature, infrastructure, spike, etc.) and ordered for testability.

### B4. Present Summary

```markdown
### Bootstrap Complete (New Project)

**Generated from vision:**
- PRD Summary: docs/reference/PRD_SUMMARY.md
- Architecture: docs/architecture/ARCHITECTURE.md
- Backlog: [N] epics, [M] stories

**Epic Structure:**
| Epic | Stories | Description |
|------|---------|-------------|
| E01  | [count] | [name]      |
| ...  | ...     | ...         |

**Next Steps:**
- Review generated epics in `docs/reference/backlog/`
- Run `/sprint-start` to begin your first sprint
- First sprint should be E01 (foundation/infrastructure)
```

---

## Rules

- NEVER overwrite files that have user content (check for non-template content first)
- ALWAYS show what will be changed before writing
- ALWAYS present a summary with next steps
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
