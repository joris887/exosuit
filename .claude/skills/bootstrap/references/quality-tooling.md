# Quality Tooling Offer Reference

Reference loaded by `/bootstrap` Path A between steps A2.2 (detect commands) and A3 (architecture analysis). Presents missing quality tools for installation.

## Tool Recommendations by Stack

| Stack | Formatter | Linter | Coverage | Type Checker |
|-------|-----------|--------|----------|-------------|
| Python | ruff format | ruff check | pytest-cov | mypy or pyright |
| TypeScript | prettier or biome | eslint or biome | Built-in (jest/vitest) | tsc --noEmit (built-in) |
| JavaScript | prettier or biome | eslint or biome | Built-in (jest/vitest) | — |
| Go | gofmt (built-in) | go vet (built-in) | Built-in (go test -cover) | Built-in |
| Rust | rustfmt (built-in) | clippy (built-in) | cargo-tarpaulin | Built-in |
| Ruby | rubocop | rubocop | simplecov | sorbet or steep |
| Java | google-java-format | checkstyle or spotbugs | jacoco | Built-in (javac) |
| C# | dotnet format (built-in) | dotnet analyzers | coverlet | Built-in |
| Swift | swift-format | swiftlint | — | Built-in |
| PHP | php-cs-fixer | phpstan or psalm | phpunit --coverage | phpstan |
| Dart | dart format (built-in) | dart analyze (built-in) | Built-in | Built-in |

## Detection Logic

For each tool category (formatter, linter, coverage, type checker):

1. **Check if already available** — run `command -v {tool}` or the detect command
2. **Skip built-in tools** — for stacks with built-in tools (Go, Rust, Dart), note as available and skip the offer
3. **Identify the gap** — if not available and not built-in, add to the missing list

## Offer Flow

After detecting the stack (A1) and commands (A2), present missing tools:

```
Quality tooling assessment for your {language} project:

  ✓ {tool} (formatter) — available
  ✗ {tool} (linter) — not installed
  ✗ {tool} (coverage) — not installed
  ✓ {tool} (type checker) — available

Missing tools recommended for framework quality gates:
  ☐ {tool} ({category}) — `{install_command}`
  ☐ {tool} ({category}) — `{install_command}`

Install selected tools now? [Select tools / Skip all]
```

## Install Commands by Package Manager

| Package Manager | Install Pattern |
|----------------|-----------------|
| uv | `uv pip install {package}` or `uv add --dev {package}` |
| pip | `pip install {package}` |
| poetry | `poetry add --group dev {package}` |
| pdm | `pdm add -dG dev {package}` |
| npm | `npm install --save-dev {package}` |
| yarn | `yarn add --dev {package}` |
| pnpm | `pnpm add --save-dev {package}` |
| bun | `bun add --dev {package}` |
| cargo | `cargo install {package}` |
| gem | `gem install {package}` |
| composer | `composer require --dev {package}` |

## After Installation

- **If tools installed:** Verify they work by running `{tool} --version` or `{tool} --help`
- **If user declines:** Record each declined tool for the Readiness Report and foundation backlog:
  ```
  declined_tools:
    - tool: ruff
      category: formatter+linter
      reason: user declined
    - tool: pytest-cov
      category: coverage
      reason: user declined
  ```
- Declined tools become foundation stories in E00 (see E8-S03)

## Architecture Enforcement Tools (Optional)

Architecture enforcement tools make Dependency Rules in ARCHITECTURE.md executable — violations break the build instead of silently accumulating. These are optional but high-value for projects with clear layered architectures.

| Stack | Tool | What It Enforces |
|-------|------|-----------------|
| JavaScript/TypeScript | dependency-cruiser | Import rules, dependency graphs, circular dep detection |
| Python | import-linter | Layer boundaries via declarative config |
| Java | ArchUnit | Layered/onion/hexagonal architecture rules |
| .NET | NetArchTest | Architecture rules as unit tests |
| Go | go-arch-lint | Dependency direction enforcement |
| Rust | Built-in (`pub`, `pub(crate)`) | Module visibility (no additional tool needed) |

**Detection:** Check for existing config files:
```bash
ls .dependency-cruiser.cjs .dependency-cruiser.js .dependency-cruiser.json 2>/dev/null  # JS/TS
ls .importlinter 2>/dev/null; grep -l 'import.linter' pyproject.toml setup.cfg 2>/dev/null  # Python
grep -rl 'ArchUnit\|archunit' --include='*.java' src/ test/ 2>/dev/null | head -1  # Java
grep -rl 'NetArchTest' --include='*.cs' 2>/dev/null | head -1  # .NET
ls .go-arch-lint.yml 2>/dev/null  # Go
```

**Offer flow:** Same pattern as formatter/linter/coverage tools. If the project has Dependency Rules in ARCHITECTURE.md but no enforcement tool, mention it as a recommendation in the Readiness Report (informational, not blocking).

**Do NOT auto-install** — these tools require configuration specific to the project's architecture. Instead, note the recommendation and generate a low-priority Level 3 foundation story if the user is interested.

## Integration Points

- **Post-edit hook** (`post-edit-format.sh`): uses formatter + linter — quality depends on these being installed
- **Quality gates** (`/sprint-end`): uses linter + type checker + test runner — gates can't function without them
- **Readiness Report** (A5.8): uses tool availability data for the "Quality gates" principle check
- **Coverage assessment** (`references/coverage-assessment.md`): coverage tool offer is part of this same pattern
- **Architecture enforcement** (optional): architecture enforcement tools make ARCHITECTURE.md Dependency Rules executable in CI

## Optional: CI Slop Detection

For JavaScript/TypeScript projects, `deslop` (npm) can detect AI-generated comment slop in CI:
```bash
npx deslop --check src/
```

For other stacks, the framework's `code-slop.md` rule provides advisory enforcement during development. CI-level slop detection is a lower-priority enhancement — the rule + code review catches most issues. If a project wants CI enforcement, add a lint step that greps for banned comment patterns from `.claude/rules/code-slop.md`.
