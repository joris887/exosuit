# Documentation Research & Implementation Prompts

This directory contains paired prompts for each documentation template in the framework:

- **Research Prompt** — Send to a deep research session (Claude Project, Claude Code with `/research`, or any AI research tool). Produces structured findings with **explicit recommendations** for the optimal approach.
- **Implementation Prompt** — Send to a Claude Code session after research is complete. Takes the research's recommendations and implements them, guided by hard constraints and outcome criteria.

## Design Philosophy

The prompts are designed so that **research determines the approach, implementation executes it**:

- **Research prompts** provide starting points and areas to investigate, but explicitly ask the researcher to recommend the best approach — including approaches not listed in the prompt
- **Implementation prompts** define hard constraints (file locations, budgets, integration points) and outcome criteria, but do NOT prescribe the template structure or content — that comes from the research findings
- The research output is the **bridge** between the two prompts — it must contain actionable recommendations that the implementation prompt can follow

## Workflow

```
1. Copy the research prompt → paste into a deep research session
2. Save the research output to docs/research/<topic>.md
3. Copy the implementation prompt → paste into a Claude Code session
4. Point it to the research file → it implements the research's recommendations
```

## Documents Covered

| # | Document | Research Focus | Template File |
|---|----------|---------------|---------------|
| 1 | Architecture Documentation | Documentation models, diagrams-as-code, AI consumption | `docs/architecture/ARCHITECTURE.md` |
| 2 | Coding Standards | Style guides, AI-enforceable standards, enforcement | `docs/reference/CODING_STANDARDS.md` |
| 3 | Testing Strategy | TDD + AI, test quality metrics, anti-patterns | `docs/reference/TESTING_STRATEGY.md` |
| 4 | Ground Rules | Fitness functions, governance, AI-checkable rules | `docs/reference/GROUND_RULES.md` |
| 5 | Product Requirements | Modern PRDs, AI-implementable requirements | `docs/reference/PRD_SUMMARY.md` |
| 6 | API Documentation | API formats, AI-correct integration, contracts | `docs/reference/API_DOCUMENTATION.md` |
| 7 | Architecture Decisions | ADR formats, governance, AI decision discovery | `docs/adr/TEMPLATE.md` |
| 8 | Backlog & Stories | Story formats, decomposition, machine-verifiable AC | `docs/reference/BACKLOG_INDEX.md` + story templates |
| 9 | Sprint Planning | Sprint specs, metrics, AI session management | `docs/sprints/_TEMPLATE.md` |
| 10 | Progress & Metrics | DORA, SPACE, AI-specific metrics | `docs/progress.md` |
| 11 | Technical Debt | Classification, prioritization, AI-generated debt | `docs/technical-debt.md` |
| 12 | UAT & Test Tracking | Test cases, traceability, AI verification | `docs/testing/UAT_COVERAGE.md` |
| 13 | Team Workflow | Coordination, review, knowledge sharing with AI | `docs/reference/TEAM_WORKFLOW.md` |
| 14 | Security & Secrets | OWASP, AI security risks, secrets lifecycle | `docs/reference/SECRETS_INVENTORY.md` |
| 15 | Git Workflow | Branching, commits, merging, AI safety | `docs/reference/GIT_WORKFLOW.md` |
