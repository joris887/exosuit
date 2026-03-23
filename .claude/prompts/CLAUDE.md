# Prompts Directory

Reusable prompt snippets that skills embed via `@.claude/prompts/<name>.md` references.

## Purpose
- Shared micro-components that enforce consistency across multiple skills
- Each file is a self-contained instruction block (typically 10-40 lines)
- Skills reference these — prompts do not reference each other

## Key Prompts
- `confidence-gate.md` — 5-dimension confidence scoring (>=85 to proceed)
- `quality-gate-sequence.md` — lint/test/typecheck verification sequence
- `context-budget.md` — context window management instructions
- `context-prime.md` — session startup context loading
- `suggest-tests.md` — TDD test suggestion protocol
- `wave-execution.md` — parallel task execution in waves
- `grep-first-explore.md` — search-before-read exploration pattern

## Conventions
- Keep each prompt under 50 lines — they are embedded into skill context
- Use imperative voice — these are instructions, not documentation
- Never duplicate logic already in rules (rules auto-load, prompts are on-demand)
