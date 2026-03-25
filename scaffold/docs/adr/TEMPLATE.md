---
# ADR Metadata (machine-parseable — used by /architecture-check and /story-cycle)
status: proposed  # proposed | accepted | rejected | deprecated | superseded
date: YYYY-MM-DD
decision-makers: []
tags: []  # e.g., [database, api, security, infrastructure]
rejected-options: []  # e.g., [mongodb, graphql] — AI checks this before proposing approaches
supersedes: null  # ADR-NNNN if replacing an earlier decision
superseded-by: null
linked-ground-rules: []  # e.g., [GR-003] if promoted to a ground rule
confidence: high  # high | medium | low — low-confidence decisions get reviewed sooner
---

# ADR-NNNN: {Decision title as imperative phrase}

## Context

{What situation are we in? What forces are at play — technical, business,
team, timeline? Write as value-neutral facts. 2-4 sentences.}

## Decision

**We will {decision in active voice}.**

{1-2 sentences expanding on the decision if needed.}

## Alternatives Considered

### ✅ {Chosen option} (Selected)
- **Why chosen:** {core rationale, 1-2 sentences}

### ❌ {Rejected option 1}
- **Why rejected:** {specific reason, 1-2 sentences}
- **Reconsider when:** {conditions that would reopen this}

### ❌ {Rejected option 2}
- **Why rejected:** {specific reason, 1-2 sentences}
- **Reconsider when:** {conditions that would reopen this}

## Consequences

- **Positive:** {what gets better}
- **Negative:** {what gets worse or becomes harder}
- **Operational:** {what the team must now do differently}

## Compliance

{How will we verify this decision is followed? Reference fitness functions,
code review checks, ground rules, or architectural tests. Optional for
low-impact decisions.}
