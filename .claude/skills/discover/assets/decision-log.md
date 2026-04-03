# Decision Log

Tracks all product and technical decisions with rationale and confidence.
Populated during `/discover` and updated throughout development.

| ID | Phase | Question | Decision | Confidence | Rationale | Revisit Trigger |
|---|---|---|---|---|---|---|
| D001 | 1 | Project archetype | [type] | CONFIRMED | User selected | — |
| D002 | 1 | Project scale | [scale] | CONFIRMED | User selected | — |

## Confidence Levels

- **CONFIRMED** — Explicitly stated and validated by user
- **ASSUMED** — Inferred or defaulted by LLM, acknowledged by user
- **SPECULATIVE** — Neither stated nor inferable, flagged for validation

## Usage

- `/story-cycle` loads relevant decisions during Phase 0 — do NOT re-decide settled questions
- `/sprint-end` checks for decisions that need revisiting based on triggers
- Phase Transition Reviews (E0N-REVIEW) systematically review all decisions
- When a decision is revisited, add a new row with the updated decision and reference the original ID
