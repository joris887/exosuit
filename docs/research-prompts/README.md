# Documentation Research & Implementation Prompts

This directory contains paired prompts for each documentation template in the framework:

- **Research Prompt** (`research-*.md`) — Send to a deep research session (Claude Project, Claude Code with `/research`, or any AI research tool). Produces structured findings optimized for framework integration.
- **Implementation Prompt** (`implement-*.md`) — Send to a Claude Code session after research is complete. Takes research findings and updates the framework's template to world-class quality.

## Workflow

```
1. Copy the research prompt → paste into a deep research session
2. Save the research output to docs/research/<topic>.md
3. Copy the implementation prompt → paste into a Claude Code session
4. Point it to the research file → it updates the framework template
```

## Documents Covered

| # | Document | Research Focus | Template File |
|---|----------|---------------|---------------|
| 1 | Architecture Documentation | C4 model, arc42, diagrams-as-code, living docs | `docs/architecture/ARCHITECTURE.md` |
| 2 | Coding Standards | Google/Airbnb/MS style guides, AI-enforceable standards | `docs/reference/CODING_STANDARDS.md` |
| 3 | Testing Strategy | TDD + AI (DORA), mutation testing, test quality metrics | `docs/reference/TESTING_STRATEGY.md` |
| 4 | Ground Rules | Fitness functions, ArchUnit, governance patterns | `docs/reference/GROUND_RULES.md` |
| 5 | Product Requirements | Working Backwards, JTBD, outcome-driven specs | `docs/reference/PRD_SUMMARY.md` |
| 6 | API Documentation | OpenAPI, Stripe/Twilio DX, contract-first design | `docs/reference/API_DOCUMENTATION.md` |
| 7 | Architecture Decisions | MADR, Y-statements, decision governance | `docs/adr/TEMPLATE.md` |
| 8 | Backlog & Stories | Story mapping, INVEST, BDD acceptance criteria | `docs/reference/BACKLOG_INDEX.md` + story templates |
| 9 | Sprint Planning | Sprint goals, capacity, forecasting | `docs/sprints/_TEMPLATE.md` |
| 10 | Progress & Metrics | DORA, SPACE, engineering metrics | `docs/progress.md` |
| 11 | Technical Debt | Fowler's quadrant, debt heat maps, remediation | `docs/technical-debt.md` |
| 12 | UAT & Test Tracking | Test case management, traceability, risk-based testing | `docs/testing/UAT_COVERAGE.md` |
| 13 | Team Workflow | InnerSource, trunk-based dev, review culture | `docs/reference/TEAM_WORKFLOW.md` |
| 14 | Security & Secrets | OWASP SAMM, secret management maturity, compliance | `docs/reference/SECRETS_INVENTORY.md` |
| 15 | Git Workflow | GitHub Flow, conventional commits, merge strategies | `docs/reference/GIT_WORKFLOW.md` |
