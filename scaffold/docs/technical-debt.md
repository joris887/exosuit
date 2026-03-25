# Technical Debt Register

> Last reviewed: <!-- date --> | Next review: <!-- date -->
> Active items: 0 | Resolved this quarter: 0

<!-- Classification reference:
  Categories: Architecture | Code quality | Test | Dependency | Documentation | Infrastructure | Security
  Severities: Critical (fix this sprint) | High (next 2 sprints) | Medium (next quarter) | Low (opportunistic)
  Origins:    ai-generated | legacy | deliberate-prudent | deliberate-reckless | inadvertent
  Interest:   Growing | Stable | Shrinking
  Effort:     Hours | Days | Weeks
  Priority score = (Impact 1-3 x Reach 1-3) / Effort 1-3 — higher = fix first
-->

## Critical

<!-- Items that block development, pose security risk, or cause data loss. Fix this sprint.

### TD-NNN: [Short descriptive title]
- **Category:** Architecture | Code quality | Test | Dependency | Documentation | Infrastructure | Security
- **Severity:** Critical | **Since:** YYYY-MM-DD
- **Origin:** ai-generated | legacy | deliberate-prudent | deliberate-reckless | inadvertent
- **Location:** `path/to/file.ext:lines`, `path/to/other.ext`

**What:** One-paragraph description of the debt and why it exists.

**Impact:** Quantified cost — e.g., "Adds ~15 min to every deploy. Caused 2 incidents in Q1."

**Interest:** Growing | Stable | Shrinking
**Effort:** Hours | Days | Weeks — brief rationale.
**Priority score:** (Impact x Reach) / Effort = N.N

**Resolution:** Concrete next steps, dependencies, prerequisites.

**Linked:** Story #NNN | Blocks TD-NNN | See ADR-NNN
-->

## High

<!-- Significant velocity impact, affects multiple components, getting worse. Fix in next 2 sprints. -->

## Medium

<!-- Noticeable friction, contained to one area, stable. Address next quarter. -->

## Low

<!-- Minor inconvenience, cosmetic, isolated, rarely touched code. Fix opportunistically. -->

---

## Accepted Debt

<!-- Items consciously accepted as permanent trade-offs. Each must have a review trigger.

### TD-NNN: [Title]
- **Accepted:** YYYY-MM-DD | **Rationale:** Why this is acceptable
- **Review trigger:** Condition that would reopen — e.g., "if we exceed 10k users"
-->

---

## Resolved (Last 90 Days)

<!-- Archive of recently resolved items for pattern analysis. Delete entries older than 90 days.

### ~~TD-NNN: [Title]~~
- **Resolved:** YYYY-MM-DD | **Method:** Refactored | Rewritten | Deleted | Superseded
- **Effort actual:** 3 days (estimated 2 days)
- **Sprint:** Sprint N, Story #NNN
-->

---

## AI Debt Trends

<!-- Updated quarterly by /weekly-maintenance. Tracks whether AI governance is improving.

| Quarter | New items | AI-origin | Resolved | Net change | Top AI pattern |
|---------|-----------|-----------|----------|------------|----------------|
| YYYY-QN | 0         | 0 (0%)    | 0        | 0          | —              |
-->

---

## Remediation Guide

<!-- When tackling debt items as sprint stories, the category determines what the LLM can
handle autonomously vs what requires human judgment:

  SAFE FOR LLM REMEDIATION (proceed via /story-cycle normally):
  - Code quality — mechanical refactoring, dead code removal, naming consistency, function extraction
  - Test — generating tests for untested code, fixing flaky tests, improving shallow assertions
  - Documentation — generating docs for undocumented modules, updating stale API docs
  - Dependency — version updates with automated migration, removing unused dependencies

  REQUIRES HUMAN JUDGMENT (LLM assists research and proposes options, human decides):
  - Architecture — structural changes affect system-wide trade-offs the LLM cannot evaluate
  - Security — risk assessment requires threat modeling and business context
  - Infrastructure — deployment and environment changes have blast radius the LLM cannot predict

  Why: Research shows AI-generated code is "highly functional but systematically lacking in
  architectural judgment." The LLM excels at mechanical fixes but cannot reason about
  system-level trade-offs or business risk. For Architecture/Security/Infrastructure debt,
  use /brainstorm or /research to explore options, then let the developer decide.
-->
