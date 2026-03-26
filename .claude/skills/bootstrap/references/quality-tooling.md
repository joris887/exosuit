# Quality Tooling Offer Reference

Reference loaded by `/bootstrap` Path A between steps A2.2 (detect commands) and A3 (architecture analysis). Presents missing quality tools for installation.

## Tool Recommendations by Stack

| Stack | Formatter | Linter | Coverage | Type Checker | Mutation | Property-Based |
|-------|-----------|--------|----------|-------------|----------|----------------|
| Python | ruff format | ruff check | pytest-cov | mypy or pyright | mutmut | Hypothesis |
| TypeScript | prettier or biome | eslint or biome | Built-in (jest/vitest) | tsc --noEmit (built-in) | Stryker | fast-check |
| JavaScript | prettier or biome | eslint or biome | Built-in (jest/vitest) | — | Stryker | fast-check |
| Go | gofmt (built-in) | go vet (built-in) | Built-in (go test -cover) | Built-in | go-mutesting | gopter |
| Rust | rustfmt (built-in) | clippy (built-in) | cargo-tarpaulin | Built-in | cargo-mutants | proptest |
| Ruby | rubocop | rubocop | simplecov | sorbet or steep | mutant | rantly |
| Java | google-java-format | checkstyle or spotbugs | jacoco | Built-in (javac) | PIT (Pitest) | jqwik |
| C# | dotnet format (built-in) | dotnet analyzers | coverlet | Built-in | Stryker.NET | FsCheck |
| Swift | swift-format | swiftlint | — | Built-in | — | SwiftCheck |
| PHP | php-cs-fixer | phpstan or psalm | phpunit --coverage | phpstan | Infection | — |
| Dart | dart format (built-in) | dart analyze (built-in) | Built-in | Built-in | — | — |

## Detection Logic

For each tool category (formatter, linter, coverage, type checker, mutation, property-based):

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

## Security Scanning Tools

Security scanning tools catch vulnerabilities that formatters and linters miss. AI-generated code contains vulnerabilities 40-45% of the time — automated scanning is essential.

| Stack | Secret Scanner | SAST | Dependency Audit |
|-------|---------------|------|-----------------|
| All | Gitleaks | Semgrep | — |
| Python | — | Bandit | pip-audit |
| TypeScript/JavaScript | — | — | npm audit, Socket |
| Go | — | gosec | govulncheck |
| Rust | — | — | cargo audit |
| Ruby | — | Brakeman | bundler-audit |
| Java | — | SpotBugs + Find Security Bugs | OWASP Dependency-Check |
| PHP | — | — | composer audit |
| Swift | — | MobSF/mobsfscan | — |

### Detection Logic

Follow the same pattern as formatter/linter detection:

1. **Check if available:** `command -v gitleaks`, `command -v semgrep`, `command -v bandit`, etc.
2. **Check for pre-commit integration:** Look for `gitleaks` in `.pre-commit-config.yaml`
3. **Check for CI integration:** Look for secret/SAST scanning steps in CI config files

### Offer Flow

Present after formatter/linter/coverage tools in the same format:

```
Security scanning assessment:

  ✗ gitleaks (secret scanner) — not installed
  ✗ {tool} (SAST) — not installed
  ✓ npm audit (dependency audit) — available

Missing tools recommended for security gates:
  ☐ gitleaks (secret scanner) — `brew install gitleaks` / `go install github.com/gitleaks/gitleaks/v8@latest`
  ☐ {tool} (SAST) — `{install_command}`

Install selected tools now? [Select tools / Skip all]
```

### Integration Points

- **Pre-commit hook:** Gitleaks can be added to pre-commit config for automatic secret scanning
- **Post-edit hook** (`post-edit-format.sh`): Framework's built-in secret patterns provide baseline detection without external tools
- **Quality gates** (`/sprint-end`): `/security-audit` skill can invoke installed scanning tools
- **Readiness Report** (A5.8): Security scanning tool availability feeds the "Secrets-aware" principle check
- **CI pipeline:** Both Gitleaks and Semgrep offer GitHub Actions for PR-level scanning

### If User Declines

Record declined security tools for the Readiness Report:
```
declined_tools:
  - tool: gitleaks
    category: secret-scanner
    reason: user declined
  - tool: semgrep
    category: sast
    reason: user declined
```

Declined tools become foundation stories. Security tooling gaps are flagged as "Risk" (not "Missing") in the Readiness Report — the framework's built-in hook patterns provide baseline coverage.

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
- **Coverage assessment** (`references/coverage-assessment.md`): coverage + mutation tool offer is part of this same pattern
- **Mutation testing** (nightly/pre-release): mutation tools enable the ≥80% mutation score gate from TESTING_STRATEGY.md
- **Property-based testing**: PBT frameworks enable TESTING_STRATEGY.md's "critical business logic" tier (unit + PBT + integration)
- **Architecture enforcement** (optional): architecture enforcement tools make ARCHITECTURE.md Dependency Rules executable in CI

## Optional: CI Slop Detection

For JavaScript/TypeScript projects, `deslop` (npm) can detect AI-generated comment slop in CI:
```bash
npx deslop --check src/
```

For other stacks, the framework's `code-slop.md` rule provides advisory enforcement during development. CI-level slop detection is a lower-priority enhancement — the rule + code review catches most issues. If a project wants CI enforcement, add a lint step that greps for banned comment patterns from `.claude/rules/code-slop.md`.
