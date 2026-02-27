# Stack Detection Reference

Reference loaded by `/bootstrap` Path A. Detect technologies, commands, and codebase metrics.

## A1. Detect Technology Stack

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

## A2. Detect Commands

Identify the project's key commands:

```bash
# Check for task runners
cat Makefile 2>/dev/null | head -30
cat justfile 2>/dev/null | head -30
cat package.json 2>/dev/null | python3 -c "import sys,json; [print(f'  {k}: {v}') for k,v in json.load(sys.stdin).get('scripts',{}).items()]"
```

Before invoking any detected tool with flags, run `[tool] --help` first to discover available options. Do NOT guess flags from memory — tool versions change.

Map to standard operations:

| Operation   | Detected Command |
| ----------- | ---------------- |
| Test        | `{test_command}` |
| Lint        | `{lint_command}`  |
| Format      | `{format_command}` |
| Build       | `{build_command}` |
| Type Check  | `{typecheck_command}` |
| Dev Server  | `{dev_command}`  |

## A2.5. Assess Documentation State

Check which docs exist and whether they contain real content or only template placeholders:

- `docs/architecture/ARCHITECTURE.md` — exists? populated?
- `docs/reference/CODING_STANDARDS.md` — exists? populated?
- `docs/reference/TESTING_STRATEGY.md` — exists? populated?
- `docs/progress.md` — has sprint entries?

## A2.6. Assess Test Coverage

**Read `references/coverage-assessment.md`** for the complete coverage assessment flow.

Summary: detect coverage tool for the stack → offer installation if missing (with user approval) → run coverage report → record baseline in progress.md → flag zero-coverage areas as unsafe for TDD refactoring. This data feeds into the Framework Readiness Report (A5.8).

## A2.7. Assess Architecture

Scan directory structure to identify:

- Module boundaries (top-level directories, package structure)
- Entry points (main files, index files, app files)
- Configuration layers (env files, config directories)

## A3. Measure Codebase

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

After measuring file counts, proceed to:
- **A3.1** — LLM-readiness assessment (read `references/llm-readiness.md`): file size analysis, fan-out, circular dependency detection
- **A3.2** — Technical debt assessment (read `references/technical-debt-assessment.md`): stale markers, missing types, unsafe patterns
