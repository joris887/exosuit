# Coverage Assessment Reference

Reference loaded by `/bootstrap` Path A step A2.6. Assesses test coverage readiness for the TDD-first principle.

## Coverage Tool Detection

Detect whether a coverage tool is available for the detected stack:

| Stack | Coverage Tool | Detect Command | Install Command | Run Command |
|-------|--------------|----------------|-----------------|-------------|
| Python (pytest) | pytest-cov | `python -c "import pytest_cov"` | `{pkg_mgr} install pytest-cov` | `pytest --cov={package} --cov-report=term-missing -q` |
| Python (unittest) | coverage | `python -c "import coverage"` | `{pkg_mgr} install coverage` | `coverage run -m unittest discover && coverage report` |
| TypeScript/JS (Jest) | Built-in | N/A (always available) | — | `npx jest --coverage --silent` |
| TypeScript/JS (Vitest) | Built-in (v8) | N/A (always available) | — | `npx vitest run --coverage` |
| Go | Built-in | N/A (always available) | — | `go test -cover ./...` |
| Rust | cargo-tarpaulin | `cargo tarpaulin --version` | `cargo install cargo-tarpaulin` | `cargo tarpaulin --skip-clean -o stdout` |
| Ruby (RSpec) | simplecov | `ruby -e "require 'simplecov'"` | `gem install simplecov` | Check after `bundle exec rspec` |
| Java (Maven) | jacoco | Check `pom.xml` for jacoco plugin | Add to pom.xml | `mvn test jacoco:report` |
| C# (.NET) | coverlet | `dotnet tool list` | `dotnet tool install coverlet.console` | `dotnet test --collect:"XPlat Code Coverage"` |

`{pkg_mgr}` resolves to the detected package manager: `uv pip`, `pip`, `poetry add --group dev`, `pdm add -dG test`, etc.

## Assessment Flow

### Step 1: Check if coverage tool is available

For stacks with built-in coverage (Go, Jest, Vitest): skip to Step 3.

For stacks requiring a separate tool: run the detect command from the table above.

### Step 2: Offer installation if missing

If the coverage tool is NOT detected:

```
Coverage tool not found for your {stack} project.

The TDD-first principle requires coverage tracking to:
- Identify untested code before refactoring
- Measure test health across sprints
- Flag modules unsafe for TDD refactoring (zero coverage)

Install {tool}? ({install_command})
[Install / Skip]
```

- If **Install**: run the install command, verify it works
- If **Skip**: record `coverage: "N/A — user declined {tool} installation"` in progress.md and move on

### Step 3: Run coverage report

Run the coverage command from the table. Before running, verify flags with `[tool] --help` — do NOT guess flags.

Parse the output to extract:
- **Overall coverage percentage**
- **Per-module/file breakdown** (if available)
- **Files with zero coverage**

### Step 4: Record baseline in progress.md

Update `docs/progress.md` → `## Current Sprint` → **Notes** field with baseline test metrics:

```markdown
**Notes:** Bootstrap baseline — {count} tests ({overall_pct}% coverage), tool: {tool_name}. Zero-coverage: {list or "none"}.
```

### Step 5: Flag zero-coverage areas

Files or modules with 0% coverage are flagged as **unsafe for TDD refactoring**. These need characterization tests before any refactoring work.

Store this data for the Readiness Report (E8-S01):

```
coverage_assessment:
  tool: {tool_name}
  overall_pct: {number}
  zero_coverage_files: [{list}]
  status: ready | risk | missing
  detail: "{explanation}"
```

Classification:
- `ready`: Coverage tool available AND overall > 60%
- `risk`: Coverage tool available BUT overall < 60% OR significant zero-coverage areas
- `missing`: No coverage tool, user declined installation

## Mutation Testing Tool Detection

Mutation testing is the strongest predictor of test suite fault detection (R²=0.94-0.99 correlation with real fault detection). Detect whether a mutation testing tool is available:

| Stack | Mutation Tool | Detect Command | Install Command | Run Command |
|-------|--------------|----------------|-----------------|-------------|
| Python | mutmut | `python -c "import mutmut"` | `{pkg_mgr} install mutmut` | `mutmut run --paths-to-mutate={package}` |
| TypeScript/JS | Stryker | `npx stryker --version` | `npm install --save-dev @stryker-mutator/core` | `npx stryker run` |
| Java (Maven) | PIT (Pitest) | Check `pom.xml` for pitest plugin | Add to pom.xml | `mvn org.pitest:pitest-maven:mutationCoverage` |
| Go | go-mutesting | `command -v go-mutesting` | `go install github.com/zimmski/go-mutesting/...@latest` | `go-mutesting ./...` |
| Rust | cargo-mutants | `cargo mutants --version` | `cargo install cargo-mutants` | `cargo mutants` |
| C# (.NET) | Stryker.NET | `dotnet stryker --version` | `dotnet tool install dotnet-stryker` | `dotnet stryker` |

### Assessment

- If mutation tool is available: record in progress.md, note as ready for nightly/pre-release CI
- If missing: note in Readiness Report, generate foundation story (Level 2, P2) for installation
- Mutation testing runs in post-merge/nightly CI, NOT in pre-commit — it's too slow for fast feedback

Record mutation testing status:

```
mutation_testing:
  tool: {tool_name}
  status: ready | missing
  detail: "{explanation}"
```

## Architecture → Testing Shape Mapping

The recommended testing shape depends on the project's architecture. After architecture detection (A3), map to a testing recommendation:

| Architecture | Testing Shape | Primary Test Level | Ratio Guidance |
|---|---|---|---|
| Monolith | Pyramid | Unit tests for business logic | 70% unit / 20% integration / 10% E2E |
| Frontend SPA | Trophy | Integration tests + static analysis | 20% unit / 50% integration / 20% E2E / 10% static |
| Microservices | Honeycomb | Service-boundary integration + contract | 30% unit / 50% integration + contract / 20% E2E |
| Serverless | Hybrid | Per-function unit + contract | 50% unit + contract / 30% integration / 20% E2E |
| CLI tool | Pyramid | Unit + integration (command tests) | 60% unit / 30% integration / 10% E2E |
| Library/SDK | Pyramid | Unit + property-based | 70% unit + PBT / 20% integration / 10% examples |

Populate the testing shape recommendation in TESTING_STRATEGY.md's `## Test Infrastructure` section during step A4.

## Graceful Degradation

| Situation | Action |
|-----------|--------|
| Coverage tool not installed, user declines | Record N/A, create foundation story suggestion |
| Coverage command fails | Record error, note in summary, do not block bootstrap |
| Coverage output can't be parsed | Record raw output, estimate manually, note uncertainty |
| No test framework detected at all | Skip coverage entirely, flag TDD-first as `✗ Missing` |
