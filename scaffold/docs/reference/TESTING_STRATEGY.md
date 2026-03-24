# Testing Strategy

Authoritative reference for testing practices in LLM-assisted development. All skills reference this document.

## Core Principle

**AI amplifies your testing practice.** If testing is strong, AI makes you faster. If it is weak, AI makes you worse (DORA 2025). Tests are not afterthoughts — they are how you communicate intent to the machine.

______________________________________________________________________

## TDD Workflow with LLMs

TDD is mandatory for **feature**, **bug fix**, and **refactoring** stories. The human owns the RED phase (what to test); the AI assists with GREEN (make it pass) and REFACTOR.

### The 7-Step AI-Assisted TDD Cycle

1. **Human writes the test name** — A clear, behavior-focused name IS the specification
2. **Human writes a seed test** — One complete test establishing conventions, patterns, imports, fixtures, assertion style
3. **AI generates remaining test cases** — Following the seed pattern for additional behaviors
4. **Human validates AI-generated tests** — Check for quality (see Test Quality Criteria below)
5. **AI generates implementation** — With the full test suite as context
6. **Run tests, iterate on failures** — AI debugs using test output as context
7. **Human reviews the final result** — Understand every line before committing

### TDD Rules

- NEVER let the AI write both the test AND the implementation in the same prompt
- NEVER skip the failing test phase — always see RED before GREEN
- NEVER weaken an assertion to make a test pass — fix the implementation instead
- NEVER delete a failing test — either fix the code or understand why the test is wrong
- Run tests after EVERY small change — not in batches

______________________________________________________________________

## When NOT to Use TDD

| Story Type                  | Alternative                                     | Why                                            |
| --------------------------- | ----------------------------------------------- | ---------------------------------------------- |
| **Spike/Research**          | Exploratory coding, then retroactive tests      | Requirements unknown; tests would be rewritten |
| **UI/UX exploration**       | Visual feedback, manual testing, then snapshots | Behavior is subjective and visual              |
| **Infrastructure/Config**   | Integration/smoke tests only                    | Unit tests for config wiring are brittle       |
| **Simple CRUD/Boilerplate** | Schema validation + integration tests           | Logic is trivial; TDD overhead exceeds value   |
| **Documentation**           | Verify links and accuracy manually              | No executable behavior to test                 |
| **One-shot scripts**        | Manual verification, then discard               | No long-term maintenance                       |

For these story types, `/story-cycle` automatically selects the appropriate alternative.

______________________________________________________________________

## Test Quality Criteria

AI-written tests frequently increase coverage numbers without catching real bugs. Apply these checks:

### The 6 Quality Tests

| Check                 | Question                                                        | Red Flag                                      |
| --------------------- | --------------------------------------------------------------- | --------------------------------------------- |
| **Revert Test**       | Would this test fail if you reverted to a naive implementation? | Test passes regardless of implementation      |
| **Mutation Test**     | Would changing `>` to `>=` or removing a line make this fail?   | Mutations survive — assertions are too weak   |
| **Independence Test** | Does this test validate behavior from the caller's perspective? | Test mirrors internal implementation details  |
| **Assertion Ratio**   | Does every test have specific, meaningful assertions?           | `assert result is not None` as sole assertion |
| **Name Test**         | Can you read the name and understand what behavior it protects? | `test_function_works` — says nothing          |
| **Edge Case Test**    | Does the suite include boundaries, errors, empty/null inputs?   | Only happy-path tests                         |

### Red Flags in AI-Generated Tests

- Tests that construct a mock, call a method, and assert the mock was called (testing the mock, not behavior)
- Expected values computed using the same logic as the implementation (tautological)
- Tests where removing the implementation would NOT require changing the test
- `assert True`, `assert result is not None`, or zero assertions
- All tests for valid inputs only — no error paths, no boundaries

______________________________________________________________________

## Testing Anti-Patterns to Prevent

| Anti-Pattern                 | Description                                                   | Prevention                                              |
| ---------------------------- | ------------------------------------------------------------- | ------------------------------------------------------- |
| **Testing the mock**         | Mock is configured, called, and asserted — no real logic runs | Mock external services only, never internal logic       |
| **Tautological tests**       | Expected output computed with same formula as implementation  | Use hardcoded expected values from domain knowledge     |
| **Happy-path-only**          | 5 tests, all for valid inputs                                 | Require at least 1 error/edge case per behavior         |
| **Implementation mirroring** | Test replicates algorithm step-by-step                        | Test observable outcomes, not internal state            |
| **Hallucinated APIs**        | Test calls methods that don't exist                           | Run every test immediately after writing                |
| **Over-mocking**             | Everything mocked, zero production code runs                  | Measure what production code the test actually executes |
| **Weakened assertions**      | AI "fixes" failing test by removing assertions                | Track assertion count — it must never decrease          |
| **Copy-paste divergence**    | AI copies test structure but changes assertions incorrectly   | Review each test individually, not as a batch           |

______________________________________________________________________

## Testing by Story Type

### Feature Stories

- **Method:** TDD (RED-GREEN-REFACTOR)
- **Test types:** Unit tests for logic, integration tests for component interaction
- **Coverage:** Must cover happy path + at least one error/edge case per behavior
- **Pattern:** Given/When/Then structure

### Bug Fix Stories

- **Method:** Reproduction-first TDD
- **Test types:** Regression test that reproduces the exact bug
- **Coverage:** The reproduction test MUST fail before the fix and pass after
- **Pattern:** Write the failing test → verify it fails for the right reason → fix → verify pass

### Refactoring Stories

- **Method:** Characterization tests → Refactor → Verify
- **Test types:** Golden master / approval tests that capture current behavior
- **Coverage:** Lock ALL observable behavior before changing any code
- **Pattern:** Capture outputs for comprehensive inputs → refactor → assert outputs unchanged

### Spike/Research Stories

- **Method:** No TDD — exploratory
- **Test types:** None during exploration; retroactive tests on any code that survives
- **Coverage:** N/A during spike; code may be discarded
- **Pattern:** Explore → prototype → document findings → discard or test

### Infrastructure Stories

- **Method:** Integration/smoke tests
- **Test types:** Smoke tests ("does it start?"), integration tests ("do components connect?")
- **Coverage:** Verify commands work, scripts execute, configs are valid
- **Pattern:** Implement → smoke test → verify in CI

### Security Stories

- **Method:** TDD + scanning tools
- **Test types:** Security-focused unit tests + automated scanning
- **Coverage:** Every security boundary must have explicit tests
- **Pattern:** Threat model → TDD → scan with security tools → audit

### Performance Stories

- **Method:** Benchmark-driven
- **Test types:** Benchmark tests with baseline comparison
- **Coverage:** Before/after measurements for every optimization
- **Pattern:** Baseline → optimize → benchmark → compare → prevent regression

______________________________________________________________________

## Test Infrastructure

<!-- Filled by /bootstrap with project-specific test commands and patterns -->

```bash
# Example commands (replace with your project's):
# npm test                    # Full suite
# npm test -- --watch         # TDD fast feedback
# npm test -- --coverage      # Coverage report
```

______________________________________________________________________

## E2E Testing Strategy

### The Skeleton Pattern

For multi-story features, build the test skeleton first:

1. **Create disabled E2E tests** that describe all expected behaviors
1. **Implement features** story by story
1. **Enable corresponding E2E tests** as each feature ships
1. **Integration is tested continuously** — not just at the end

______________________________________________________________________

## Contract Conformance Testing

For projects with component boundaries (API ↔ client, backend ↔ frontend, service ↔ service), add contract tests that verify both sides agree on the interface. Skip for single-component projects.

**What to test:** Request/response schemas match on both sides, error codes handled consistently, serialization round-trips correctly.

**Pattern:**
1. Define the contract (OpenAPI spec, JSON schema, Protocol Buffers, or shared type definition)
2. Write tests on BOTH sides that validate against the contract
3. Run contract tests in CI — a schema change that breaks the other side fails the build
4. When modifying a boundary, update contract + both sides' tests in the same PR

**Why this matters with LLMs:** AI-generated code often silently drifts from contracts (wrong field names, mismatched types). Contract tests catch this at build time.

______________________________________________________________________

## Guard Rails

Automated protections that prevent LLMs from degrading test quality:

### Must-Have Guards

| Guard                        | What It Prevents                    | Implementation                                             |
| ---------------------------- | ----------------------------------- | ---------------------------------------------------------- |
| **Test count gate**          | AI deleting tests to "fix" failures | CI: count tests on branch vs main; fail if decreased       |
| **Coverage delta gate**      | AI-generated code without tests     | CI: reject PRs that decrease coverage for touched files    |
| **Assertion tracking**       | AI weakening assertions             | CI: track assertion count per test file; alert on decrease |
| **Pre-commit test run**      | Broken code reaching remote         | Pre-commit hook runs tests on changed modules              |
| **Type checking**            | Hallucinated types and APIs         | Strict type checking catches before runtime                |
| **Critical file protection** | AI modifying test infrastructure    | Require human review for conftest.py, fixtures, mocks      |

### Periodic Checks

- **Reverse test:** Comment out key implementation lines; if all tests pass, tests need strengthening
- **Mutation testing:** Run mutation testing tools; if mutations survive, assertions are too weak
- **Coverage trend:** Track per-module coverage over sprints; flag persistent low-coverage modules

______________________________________________________________________

## Coverage Strategy

### Targets

- **Overall:** Must not decrease sprint-over-sprint; CI warns if below 70%
- **New code:** ≥80% line coverage (CI-enforced on touched files)
- **Critical business logic:** ≥90% branch coverage

### What Coverage Means and Doesn't Mean

- **Coverage = "this line was executed during tests"** — nothing more
- **Coverage ≠ "this line is correctly tested"** — assertions matter, not execution
- **Branch coverage > line coverage** — catches untested if/else paths
- **Mutation testing > all coverage metrics** — answers "would a bug here be caught?"

### Rules

- Coverage is a **floor**, not a goal — do not chase 100%
- Focus on **critical paths**, error handling, and security-sensitive code
- Never increase coverage with tautological or assertion-free tests
- Track **per-module** coverage to prevent high-coverage utilities from masking low-coverage logic

______________________________________________________________________

## Coverage Tool Quick Reference

Bootstrap configures the appropriate tools for your detected stack. Common coverage commands:

| Language | Tool | Command | Report Flag |
|----------|------|---------|-------------|
| Python | pytest-cov | `pytest --cov=src` | `--cov-report=term-missing` |
| TypeScript/JS | c8/istanbul | `npx jest --coverage` | Built-in HTML report |
| Go | built-in | `go test -cover ./...` | `-coverprofile=cover.out` |
| Rust | tarpaulin | `cargo tarpaulin` | `--out Html` |
| Ruby | simplecov | `bundle exec rspec` | Auto-generates HTML |
| Java | JaCoCo | `mvn test` | Built-in with Maven |
| Swift | built-in | `swift test --enable-code-coverage` | `llvm-cov` |
| C# | coverlet | `dotnet test --collect:"XPlat Code Coverage"` | ReportGenerator |
| PHP | phpunit | `phpunit --coverage-text` | `--coverage-html` |
| Dart | built-in | `dart test --coverage` | `lcov` |
| Kotlin | Kover | `gradle koverReport` | HTML report |
| C/C++ | gcov/lcov | `make test && gcov *.c` | `lcov` |

**Note:** This table is a starting reference. Bootstrap detects your specific project's tools and configures CLAUDE.md Commands accordingly. The project-specific test command is always authoritative.

______________________________________________________________________

## Characterization Tests

For locking behavior before refactoring (especially important with LLMs):

1. Run existing code with comprehensive inputs and capture all outputs
1. Write tests asserting `current_output == captured_output` for every input
1. These tests do NOT judge correctness — they lock CURRENT behavior
1. Let the AI refactor with characterization tests as the safety net
1. Any behavioral change is immediately caught
1. After refactoring: keep useful tests as regression tests, replace others with behavior tests

**When to use:** Before refactoring any module, before upgrading dependencies, before the AI restructures existing code.

______________________________________________________________________

## References

- DORA 2025: TDD amplifies AI-assisted development quality
- 8th Light: TDD as the missing protocol for effective AI collaboration
- Tweag: Agentic Coding Handbook — TDD workflow and auto-validations
- CodeRabbit: AI-generated code produces 1.7x more issues than human-written code
- CodeScene: Three pillars of AI code guardrails — quality, familiarity, coverage
- Addy Osmani: Ultra-granular version control for AI-generated code
- Simon Willison: "Your job is to deliver code you have proven to work"
