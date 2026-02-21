______________________________________________________________________

## name: bootstrap description: First-run framework setup. Detects existing project stack or guides new project creation from vision/braindump. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Setting up the JD-LLM Development Framework for this project.

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
- **Linter/formatter** (eslint, ruff, clippy, swiftlint, etc.)
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

### A4. Generate Configuration

Update these files with detected information:

1. **`CLAUDE.md`** — Fill in Project Overview, Commands, Architecture, Code Conventions
2. **`docs/reference/CODING_STANDARDS.md`** — Fill in language-specific sections
3. **`docs/progress.md`** — Initialize with baseline metrics
4. **`.claude/rules/`** — Generate path-scoped rules for detected file types

### A5. Run /skill-create

Generate technology-specific skills for the detected stack.

### A6. Clean Up Templates

Remove files not relevant to an existing project:

- Delete `vision/` directory (not needed for existing repos)
- Remove template placeholders from docs (replace with detected content)

### A7. Present Summary

```markdown
### Bootstrap Complete (Existing Repository)

**Detected Stack:**
- Languages: [list]
- Package Manager: [name]
- Test Framework: [name] ([count] tests)
- Linter: [name]
- CI/CD: [provider]

**Commands Configured:**
| Operation | Command |
|-----------|---------|
| Test      | [cmd]   |
| Lint      | [cmd]   |
| Build     | [cmd]   |

**Files Updated:**
- CLAUDE.md (project overview, commands, conventions)
- docs/reference/CODING_STANDARDS.md (language standards)
- docs/progress.md (baseline metrics)

**Technology Skills Generated:** [count]

**Next Steps:**
- Run `/ideate` to plan your next feature
- Run `/sprint-start` to begin a sprint
- Run `/skill-create` if you need additional technology skills
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

**Step 1:** Open `vision/BRAINDUMP_PROMPT.md` — it contains a research prompt template
**Step 2:** Copy the research prompt into a Claude Project (or ChatGPT, Perplexity, etc.)
**Step 3:** Fill in the `[YOUR IDEA HERE]` section with your raw idea
**Step 4:** Have a research conversation — explore the problem space deeply
**Step 5:** Save the structured output back to `vision/` (as .md files)
**Step 6:** Run `/bootstrap` again to generate your project structure

Alternatively, describe your idea now and I'll help you structure it directly.
```

If the user provides an idea directly, transition to `/ideate` with the idea as input.

### B3. Generate from Vision

Read all files in `vision/` and generate:

1. **`docs/reference/PRD_SUMMARY.md`** — Extract requirements, goals, users, use cases
2. **`docs/architecture/ARCHITECTURE.md`** — Extract or propose architecture
3. **`docs/reference/BACKLOG_INDEX.md`** — Create epic structure
4. **`docs/reference/backlog/E01-*.md` through `E0N-*.md`** — Epic files with typed stories
5. **`CLAUDE.md`** — Fill in overview, architecture, current focus
6. **`docs/reference/CODING_STANDARDS.md`** — Fill if stack is specified in vision

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
