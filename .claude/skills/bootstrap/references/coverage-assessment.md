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

Update the `## Current Metrics` section:

```markdown
## Current Metrics

- **Tests**: {count} tests ({overall_pct}% coverage)
- **Zero-coverage files**: {list or "none"}
- **Coverage tool**: {tool_name}
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

## Graceful Degradation

| Situation | Action |
|-----------|--------|
| Coverage tool not installed, user declines | Record N/A, create foundation story suggestion |
| Coverage command fails | Record error, note in summary, do not block bootstrap |
| Coverage output can't be parsed | Record raw output, estimate manually, note uncertainty |
| No test framework detected at all | Skip coverage entirely, flag TDD-first as `✗ Missing` |
