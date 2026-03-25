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

## A2.55. Detect API Surface

Scan for API specification files and framework-level API indicators:

| File Pattern | Indicates |
|---|---|
| `openapi.yaml`, `openapi.json`, `swagger.yaml`, `swagger.json` | REST API (OpenAPI spec) |
| `asyncapi.yaml`, `asyncapi.json` | Event-driven API (AsyncAPI spec) |
| `schema.graphql`, `*.graphql` (non-test) | GraphQL API |
| `*.proto` | gRPC API (Protocol Buffers) |

Also scan for API framework indicators in detected stack:

| Stack | API Framework Indicators |
|---|---|
| Python | `fastapi`, `flask`, `django.urls`, `django-rest-framework` in dependencies |
| TypeScript/JS | `express`, `fastify`, `nestjs`, `hono`, `next/api` in dependencies |
| Go | `gin`, `echo`, `chi`, `fiber`, `net/http` route definitions |
| Rust | `actix-web`, `axum`, `rocket` in `Cargo.toml` |
| Java/Kotlin | `@RestController`, `@RequestMapping` annotations, Spring WebFlux |
| Ruby | `config/routes.rb`, `grape`, Rails API mode |
| C# | `[ApiController]`, ASP.NET controller directories |
| PHP | Laravel routes, Symfony controllers |

**Record:**
- **API type:** REST, GraphQL, gRPC, Event-Driven, Hybrid, or None
- **Spec files found:** list paths
- **API framework:** detected framework name and version
- **Contract-first status:** spec file exists (contract-first) vs framework-only (code-first)

This data feeds into:
- `docs/context/tech-context.md` → `## API Contracts` section (A4)
- Readiness Report (A5.8) → Contract-first and API-documented checks
- Foundation backlog (A5.9) → contract testing and API documentation stories

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
