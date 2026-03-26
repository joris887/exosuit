# Testing Strategy

Authoritative reference for testing practices in AI-assisted development. Referenced by `/story-cycle`, `/test-validator`, and all quality gates.

## Core Principle

**AI amplifies your testing practice.** Strong testing + AI = faster delivery. Weak testing + AI = 1.7x more defects, 2x more logic errors (CodeRabbit 2025, DORA 2025). When AI writes both test and implementation, it creates a circular validation loop — tests protect bugs instead of catching them. TDD breaks this loop structurally.

---

## TDD Workflow — Role Separation

TDD is mandatory for **feature**, **bug fix**, and **refactoring** stories. The human owns the specification (RED); AI assists with implementation (GREEN) and refactoring.

### The 7-Step AI-Assisted TDD Cycle

1. **Human writes the test name** — behavior-focused name IS the specification
2. **Human writes a seed test** — one complete test establishing conventions, fixtures, assertion style
3. **AI generates remaining test cases** — following seed pattern for additional behaviors
4. **Human validates AI tests** — apply the Quality Checks below; reject tautological/weak tests
5. **AI generates implementation** — with the full test suite as context
6. **Run tests, iterate** — AI debugs using test output as feedback
7. **Human reviews final result** — understand every line before committing

### TDD Rules

- NEVER let AI write both test AND implementation in the same prompt
- NEVER skip the failing test phase — always see RED before GREEN
- NEVER weaken an assertion to make a test pass — fix the implementation
- NEVER delete a failing test — fix the code or understand why the test is wrong
- Run tests after EVERY small change — not in batches

### When NOT to Use TDD

| Story Type | Alternative | Why |
|---|---|---|
| **Spike/Research** | Exploratory, then retroactive tests | Requirements unknown |
| **UI/UX exploration** | Visual feedback + snapshot tests | Behavior is subjective |
| **Infrastructure/Config** | Integration/smoke tests only | Unit tests for wiring are brittle |
| **Simple CRUD** | Schema validation + integration tests | Logic trivial; TDD overhead exceeds value |
| **Documentation** | Manual link/accuracy verification | No executable behavior |

---

## Quality Metrics — Concrete Thresholds

### Primary Metrics (ranked by fault-detection power)

| Metric | Threshold | Why This Number |
|---|---|---|
| **Mutation score (changed code)** | ≥80% | Top-quartile suites show 8-46% better fault detection (Papadakis ICSE 2018); Google uses incremental mutation at scale |
| **Mutation score (critical modules)** | ≥85% | Mutation-adequate testing detects 85% of faults vs 65% for coverage-only (Li et al.) |
| **Assertion density** | ≥3 meaningful per test method | R²=0.94-0.99 correlation with mutation score (Zhang FSE 2015); 26-40/KLOC = lowest defect density (Microsoft Research) |
| **Assertion-free test rate** | 0% (zero tolerance) | Assertion removal creates "substantially larger" oracle gaps |
| **Branch coverage (core logic)** | ≥90% | Significant fault detection improvement above 90% (Hutchins et al.) |
| **Branch coverage (overall)** | ≥75% | Google "commendable" tier; diminishing returns below this |
| **New code coverage** | ≥80% on changed lines | SonarQube recommended gate; CI-enforced with ratcheting |

### Secondary Metrics

| Metric | Threshold | Purpose |
|---|---|---|
| **Mock-to-assertion ratio** | <1:1 | Mocks must not exceed assertions — flags over-mocking |
| **Flaky test rate** | <2% of suite | Fix or remove flaky tests within 14 days |
| **Branch-to-line coverage gap** | <15% | Large gaps indicate happy-path-only testing |
| **PR test execution time** | <15 minutes | Slower pipelines get bypassed |

### Coverage by Risk Tier

| Risk Tier | Branch Coverage | Mutation Score | Test Types Required |
|---|---|---|---|
| Critical business logic | 90%+ | 85%+ | Unit + property-based + integration |
| API/interface layers | 80-90% | 80%+ | Unit + contract + integration |
| Utility/helper code | 70-80% | 75%+ | Unit + parameterized |
| Configuration/infra | Schema validation | N/A | Static analysis + smoke tests |
| Generated/boilerplate | Exclude | N/A | Compilation verification only |

**Ratcheting:** Current coverage is the baseline. CI blocks PRs that reduce it. Threshold rises automatically. Apply per-module with 2% tolerance buffer.

---

## AI Anti-Patterns — Named Defenses

### Tier 1: Critical (detect in every review)

| Anti-Pattern | Frequency | Detection | Defense |
|---|---|---|---|
| **Tautological tests** | ~30% of AI suites | Mutation kill rate near zero; expected values computed from production logic | Require hardcoded expected values from specifications, never formulas |
| **Over-mocking** | 40-70% of AI repos | >3 mocks per test; assertions only verify mock-configured returns | Mock external services only; require ≥1 integration test per feature without mocks |
| **Happy-path-only** | Near universal | Branch coverage >15% below line coverage; functions with >3 branches at <60% branch coverage | Require negative tests proportional to positive; property-based testing for complex inputs |

### Tier 2: High (detect in CI)

| Anti-Pattern | Frequency | Detection | Defense |
|---|---|---|---|
| **Hallucinated APIs** | >20% of AI packages | Type-check/compile failures | Strict type checking; always compile before commit |
| **Coverage theater** | 40-70% of AI repos | Line coverage 85%+ but mutation score <50% | Mutation score as quality gate alongside coverage |
| **Implementation coupling** | Common | Assertions on method call counts/order, not return values | Test observable behavior through public APIs only |

### Tier 3: Moderate (detect in review)

| Anti-Pattern | Detection | Defense |
|---|---|---|
| **Assertion weakening** | Assertions became less specific in diff without code changes | Investigate code bugs before any test modification |
| **Copy-paste duplication** | >80% AST similarity between test methods | Use parameterized/table-driven tests |
| **Snapshot overuse** | Snapshots include timestamps, IDs, formatting | Targeted assertions for dynamic content |

---

## Quality Checks — /test-validator Reference

Apply these 6 checks to every AI-generated test:

| # | Check | Question | Red Flag |
|---|---|---|---|
| 1 | **Revert** | Would this fail with a naive implementation? | Passes regardless of implementation |
| 2 | **Mutation** | Would changing `>` to `>=` or removing a line cause failure? | Mutations survive |
| 3 | **Independence** | Does this validate behavior from the caller's perspective? | Mirrors internal details |
| 4 | **Assertion density** | ≥3 meaningful assertions per test method? | `assert result is not None` as sole assertion |
| 5 | **Naming** | Does the name explain what behavior it protects? | `test_function_works` |
| 6 | **Edge coverage** | Does the suite include boundaries, errors, null/empty? | Only happy-path tests |

### /test-validator Automated Checks

1. **Tautological assertion scan** — flag tests recalculating expected values with production logic
2. **Mock density** — flag tests with >3 mocks or assertions only on mock-configured values
3. **Happy-path ratio** — flag branch-to-line coverage gap >15%; flag functions with >3 branches at <60% branch coverage
4. **Assertion quality** — reject assertion-free tests, `expect(true).toBe(true)`, overly broad assertions (`> 0` where exact values are knowable)
5. **Test similarity** — flag methods with >80% structural similarity (copy-paste, not parameterized)
6. **Assertion weakening** — in test-modifying PRs, flag assertions that became less specific

---

## Testing by Story Type

| Story Type | Method | Test Types | Key Rule |
|---|---|---|---|
| **Feature** | TDD (RED→GREEN→REFACTOR) | Unit + integration | Happy path + ≥1 error/edge case per behavior |
| **Bug fix** | Reproduction-first TDD | Regression test | MUST fail before fix, pass after |
| **Refactoring** | Characterization → refactor → verify | Golden master/approval | Lock ALL observable behavior before changing code |
| **Security** | TDD + scanning tools | Security-focused unit + SAST/DAST | Every security boundary gets explicit tests |
| **Performance** | Benchmark-driven | Baseline comparison | Before/after measurements for every optimization |
| **Spike** | No TDD — exploratory | Retroactive on surviving code | Discard or test — no untested code merges |
| **Infrastructure** | Smoke + integration | "Does it start?" + "Do parts connect?" | Verify commands, scripts, configs in CI |

---

## CI Pipeline

| Stage | Tests Run | Time Budget | Gate |
|---|---|---|---|
| **Pre-commit** | Lint + type check + affected unit tests | <3 min | Advisory |
| **PR/pre-merge** | Full unit + integration smoke + coverage + assertion density | <15 min | Blocking |
| **Post-merge/nightly** | Full E2E + mutation testing + performance baselines | <2 hours | Creates issues |
| **Pre-release** | Full regression + DAST + contract verification | Variable | Blocking |

---

## Guard Rails

| Guard | What It Prevents | Implementation |
|---|---|---|
| **Test count gate** | AI deleting tests to "fix" failures | CI: count tests branch vs main; fail if decreased |
| **Coverage ratchet** | AI code without tests | CI: reject PRs that decrease coverage for touched files |
| **Assertion tracking** | AI weakening assertions | CI: track count per file; alert on decrease |
| **Type checking** | Hallucinated APIs/types | Strict mode catches before runtime |
| **Critical file protection** | AI modifying test infra | Human review for conftest.py, fixtures, shared mocks |
| **Mutation gate** | Coverage theater | Mutation score ≥80% on changed code in nightly/pre-release |

---

## Contract Testing

For projects with component boundaries (API↔client, backend↔frontend, service↔service):

1. Define the contract (OpenAPI, JSON Schema, Protocol Buffers, shared types)
2. Write tests on BOTH sides validating against the contract
3. Run in CI — schema changes that break the other side fail the build
4. Update contract + both sides' tests in the same PR

**AI-specific:** AI-generated code silently drifts from contracts (wrong field names, mismatched types). Contract tests catch this at build time. Skip for single-component projects.

### Recommended Tools by Protocol

| Protocol | Linting | Contract Testing | Breaking Change Detection |
|---|---|---|---|
| REST (OpenAPI) | Redocly CLI or Spectral | Dredd (spec→impl) + Schemathesis (fuzzing) | oasdiff |
| GraphQL | graphql-inspector | graphql-inspector (schema diff) | graphql-inspector breaking |
| gRPC (Protobuf) | Buf lint | Buf breaking | Buf breaking |
| Consumer-driven (any) | — | Pact (10+ languages) | Pact compatibility checks |

### Contract Testing CI Pipeline

```yaml
# Triggered on PRs modifying API-related files (routes, controllers, specs, schemas)
lint:     redocly lint openapi.yaml        # or: buf lint, graphql-inspector
breaking: oasdiff breaking base head       # detect breaking changes before merge
contract: dredd openapi.yaml $BASE_URL     # validate implementation matches spec
```

Bootstrap detects API spec files (A2.55) and generates foundation stories for contract testing setup if missing. See `docs/reference/API_DOCUMENTATION.md` for the contract source definition.

---

## Test Infrastructure

<!-- Filled by /bootstrap with project-specific test commands and patterns -->

```bash
# Example commands (replace with your project's):
# npm test                    # Full suite
# npm test -- --watch         # TDD fast feedback
# npm test -- --coverage      # Coverage report
```

**Bootstrap** detects your stack and configures coverage tools, mutation testing, and property-based testing recommendations. The project-specific commands in CLAUDE.md are always authoritative.

---

## Test Structure Conventions

- **Internal structure:** Arrange-Act-Assert (AAA), separated by blank lines
- **Naming:** Behavior-focused: `should_reject_expired_tokens`, `returns_empty_when_no_matches`
- **File organization:** Co-locate unit tests with source; centralize integration/E2E tests
- **Test data:** Factory methods with builder pattern — convenient defaults, per-test overrides
- **Parameterized tests:** Prefer table-driven tests over copy-paste for similar scenarios

---

## UAT Testing

Automated tests verify code correctness; UAT verifies the product works for users. Both are required.

- **Tracking:** `docs/testing/UAT_COVERAGE.md` — single-file registry of all UAT test cases with Given/When/Then format, pass/fail status, and execution history
- **Create:** `/story-cycle` Phase 4c generates test cases for feature/bug-fix stories automatically
- **AI verify:** `/claude-sense-check` traces test case logic against source code in prioritized batches (critical first)
- **Execute:** `/UAT-cycle <UAT-###>` guides manual test execution and records results
- **Plan:** `/manual-test` identifies coverage gaps and creates test plans
- **Exit criteria:** All critical cases pass; all high cases pass or have linked backlog stories; all sense-check boxes checked. See UAT_COVERAGE.md Reference section for full criteria.

UAT is advisory — `/sprint-end` reports coverage but does not block merge.
