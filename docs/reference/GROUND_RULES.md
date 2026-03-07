# Project Ground Rules

Non-negotiable architectural principles for this project. Created during `/bootstrap`, checked during `/story-cycle` planning and `/sprint-end` quality gates.

## Principles

<!-- Filled by /bootstrap. Define 3-7 principles using MUST (non-negotiable) or SHOULD (strong preference, exceptions require justification). -->

<!-- Pick from these common patterns by category, or define your own:

### Architecture
- **Library-First** — Every feature MUST start as a standalone, importable module. No business logic in route handlers.
- **Max N Services** — The system SHOULD NOT exceed N deployable services. Adding more requires documented justification.
- **Composition Over Inheritance** — Code MUST prefer composition. Class inheritance SHOULD NOT exceed 2 levels.
- **Explicit Over Implicit** — Configuration MUST be explicit (no convention-based magic). SHOULD fail loudly on misconfiguration.

### Data & Storage
- **No ORM** — Database access MUST use raw SQL with parameterized queries. SHOULD use a query builder for complex queries.
- **Schema-First** — Data schemas MUST be defined before implementation. All APIs MUST validate against schemas.
- **Immutable Records** — Data records SHOULD be append-only. Updates MUST create new versions, not overwrite.

### Security
- **No Hardcoded Secrets** — Credentials MUST come from environment variables or a secrets manager. Never in source code.
- **Encryption at Rest** — Sensitive data MUST be encrypted in storage. Keys MUST be managed externally.
- **Least Privilege** — Every component MUST request only the permissions it needs. No wildcard access.

### Quality
- **Coverage Floor** — Test coverage MUST NOT decrease sprint-over-sprint. New code MUST be covered.
- **Complexity Ceiling** — Cyclomatic complexity MUST stay below N per function. Functions above SHOULD be split.
- **No Silent Failures** — Errors MUST be logged or surfaced. SHOULD NOT be caught and ignored.

### Performance
- **Memory Budget** — Application MUST stay within N MB baseline. Exceeding requires documented justification.
- **Response Time** — API endpoints MUST respond within N ms at p95. Performance regression MUST be investigated.
- **No N+1 Queries** — Database access MUST NOT produce N+1 query patterns. Use batch/join queries.

### Process
- **TDD for Features** — Feature and bug fix stories MUST follow TDD (test before implementation).
- **Conventional Commits** — All commits MUST use conventional commit format.
- **Contract Tests** — Cross-component boundaries MUST have contract tests on both sides.
-->

## Amendment History

<!-- Track changes to principles with rationale:
| Date | Principle | Change | Rationale |
|------|-----------|--------|-----------|
-->

## Tracked Violations

<!-- Auto-populated from story-cycle plans that include Architectural Violations tables.
| Sprint | Story | Principle Violated | Justification | Status |
|--------|-------|--------------------|---------------|--------|
-->
