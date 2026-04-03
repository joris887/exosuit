# Assumption Register

Tracks assumptions that need validation. Populated during `/discover` Phase 4.
Updated during Phase Transition Reviews.

| ID | Category | Assumption | Confidence | Impact | Validation Method | Status | Evidence |
|---|---|---|---|---|---|---|---|
| A001 | Desirability | [assumption] | HIGH/MED/LOW | HIGH/MED/LOW | [method] | PENDING | — |

## Status Values

- **PENDING** — Not yet testable
- **TESTING** — Currently being validated via MVP
- **VALIDATED** — Evidence supports the assumption
- **INVALIDATED** — Evidence contradicts the assumption
- **UNKNOWN** — Tested but inconclusive

## Categories

- **Desirability** — Will people want this?
- **Feasibility** — Can we build this?
- **Viability** — Does the business work?
- **Usability** — Can people figure it out?

## Usage

- `/story-cycle` loads relevant assumptions during Phase 0
- If implementation reveals an assumption is wrong, update status → INVALIDATED with evidence
- Phase Transition Reviews (E0N-002) systematically validate all high-impact assumptions
- Assumptions rated "Unknown" with HIGH impact should become spike stories
