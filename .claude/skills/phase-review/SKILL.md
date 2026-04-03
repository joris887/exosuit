---
name: phase-review
version: 1.0.0
description: Phase transition review — walkthrough built features, validate assumptions, refresh research, decide direction, and plan next phase.
trigger: manual
depends-on: [discover]
calls: [ideate]
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent
argument-hint: "[phase-number]"
---
______________________________________________________________________

## phase-review

Running Phase Transition Review for phase: **$ARGUMENTS**

## Process Flow

```
START → Load context (ASSUMPTION_REGISTER, DECISION_LOG, BACKLOG_INDEX, progress.md)
  → Identify completed epics
  → Walk through Phase Transition Stories (E0N-001 → E0N-006) interactively
  → Generate outputs to docs/reviews/ and vision/
  → If user approves next phase: invoke /ideate with new vision
  → DONE
```

## 1. Load Context

Read these files (skip any that don't exist with a warning):
- `docs/reference/ASSUMPTION_REGISTER.md` — assumptions to validate
- `docs/reference/DECISION_LOG.md` — decisions to review
- `docs/reference/BACKLOG_INDEX.md` — epic completion status
- `docs/progress.md` — sprint history and metrics
- `vision/project-pitch.md` — original vision and No-Gos
- `vision/classification.md` — archetype and scale

Determine which phase we're reviewing from `$ARGUMENTS` or by counting completed review epics.

## 2. Identify Completed Work

Read epic files from `docs/reference/backlog/` to determine:
- Which epics are complete (all stories done)?
- Which stories were carried over?
- What was the overall delivery rate?

## 3. Execute Phase Transition Stories

Walk through each story interactively. Read `.claude/skills/discover/references/phase-transition-template.md` for the full story definitions.

### 3A. Feature Walkthrough (E0N-001)
Walk through every built feature with the user. Copy template from `.claude/skills/discover/assets/phase-walkthrough.md` to `docs/reviews/phase-N-walkthrough.md` and fill it in.

### 3B. Assumption Validation (E0N-002)
Go through ASSUMPTION_REGISTER.md. For each HIGH-impact assumption: VALIDATED, INVALIDATED, or STILL UNKNOWN? Update the register.

### 3C. Research Refresh (E0N-003)
Load archetype from `vision/classification.md`. Run archetype-specific research from `.claude/skills/discover/references/research-protocols.md` (RC6 checkpoint). Save to `docs/research/phase-N-refresh.md`.

### 3D. Pivot or Persevere (E0N-004)
Load success criteria from `.claude/skills/discover/references/engineering-by-archetype.md`. Present current status vs targets. Apply decision framework (SCALE / PERSEVERE / PIVOT / KILL). Save to `docs/reviews/phase-N-direction.md`.

### 3E. Next Phase Elicitation (E0N-005)
Based on direction from 3D:
- **SCALE:** Elicit growth features and optimization targets
- **PERSEVERE:** Identify validation experiments for remaining unknowns
- **PIVOT:** Run /discover Phases 1-3 with new direction
Save to `vision/phase-N+1-discovery.md`.

### 3F. Next Phase Backlog (E0N-006)
Generate next batch of epics from the phase N+1 discovery. The last epic is AGAIN a Phase Transition epic — maintaining the infinite cycle.

<HARD-GATE>
User approves the next-phase backlog before writing to files.
</HARD-GATE>

## 4. Generate Outputs

After user approval:
- Update `docs/reference/BACKLOG_INDEX.md` with new epics
- Create new epic files in `docs/reference/backlog/`
- Update `docs/progress.md` with phase review outcomes
- Update `docs/reference/DECISION_LOG.md` with any revised decisions

## Graceful Degradation

| Dependency | If Missing |
|---|---|
| ASSUMPTION_REGISTER.md | Skip assumption validation (E0N-002), note gap |
| DECISION_LOG.md | Skip decision review, note gap |
| vision/classification.md | Ask user for archetype during research refresh |
| WebSearch | Skip research refresh (E0N-003), note "no internet" |
| progress.md | Skip metrics comparison in pivot-or-persevere |

## Scale Adaptations

Read scale from `vision/classification.md`:
- **Quick Build:** Run only E0N-001 + E0N-004 + E0N-006 (3 stories)
- **Standard:** Run all 6 stories
- **Platform:** Run all 6 + Architecture Review (E0N-007)
- **Pioneering (post-spike):** Run E0N-001 + E0N-004 + full /discover re-entry

## Rules

- NEVER skip the user walkthrough (E0N-001) — this is the core value of phase review
- NEVER auto-decide PIVOT vs PERSEVERE — this is always a user decision
- ALWAYS include Phase Transition stories in the next phase backlog
- ALWAYS update ASSUMPTION_REGISTER and DECISION_LOG with review outcomes
