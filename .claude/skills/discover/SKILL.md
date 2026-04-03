---
name: discover
version: 1.0.0
description: Deep guided elicitation for new projects. Archetype-aware, research-backed, multi-phase discovery with assumption tracking and Phase Transition Stories.
trigger: manual
depends-on: []
calls: [ideate]
references: [references/scale-guide.md, references/question-scaffolding.md, references/dimension-sweep.md, references/phase-transition-template.md, references/engineering-by-archetype.md, references/research-protocols.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent
argument-hint: "<idea-description> [--quick|--platform|--pioneer]"
---
______________________________________________________________________

## discover

Deep guided elicitation for: **$ARGUMENTS**

Read `references/question-scaffolding.md` — these 6 rules apply to EVERY question you ask.

## Process Flow (authoritative)

```
START → Phase 1: Classification (archetype + scale + 5 universal questions)
  → Mode Selection:
    → [QUICK: --quick flag OR Quick Build scale]
      → 3-5 essential questions → 1 research → auto-pick tech → minimal backlog → DONE
    → [GUIDED: Standard scale — DEFAULT]
      → Phase 2 → 3 → 4 → 5 → 6 → 7 → DONE
    → [PLATFORM: --platform flag OR Platform scale]
      → All GUIDED phases + stakeholder/compliance/multi-user/ADRs → DONE
    → [PIONEERING: --pioneer flag OR Pioneering scale]
      → Core identity → deep research → spike planning → spike backlog → DONE
```

## Phase 1: Classification

### 1A. Archetype Selection (recognition-based — present ALL, user picks)

Present the 10 archetypes + Uncategorized with one-sentence descriptions and 3 examples each. See the full presentation card in `references/scale-guide.md`. User picks closest, or "none of these" → free-text → classify or route to Uncategorized.

### 1B. Sub-variant Confirmation via Analogy

"You said [archetype]. Is it more like [A], [B], or [C]?" — 3 sub-variants within the archetype. Load the archetype's reference file for sub-variant examples.

### 1C. Hybrid Check

"Does it also have a strong [other archetype] element?" If yes: set primary + secondary archetype. Most real projects span 2 archetypes.

### 1D. Scale Classification

Present 4 scales with plain-English descriptions. Read `references/scale-guide.md` for the full definitions. If unsure: infer from timeline, complexity, description.

### 1E. Quick Context Baseline (5 universal questions)

1. "In one sentence, what is this?" (scaffold: "'It's [X] that [does Y]'")
2. "What existing thing is this most like? 'It's X meets Y.'"
3. "Where and when will people use this?" (scaffold: "Phone on bus? Desktop at work?")
4. "How long is a typical session?" (scaffold: "30 seconds? 5 minutes? An hour?")
5. "Timeline and who's building?" (scaffold: "Weekend? Month? Just you?")

### 1F. Mode Selection

Select mode from scale + flags. Save to `vision/classification.md`.

<IF condition="Mode is QUICK">
Jump to Quick Start flow (below).
</IF>
<IF condition="Mode is PIONEERING">
Jump to Pioneering flow (below).
</IF>

## Phase 2: Core Identity (ARCHETYPE-SPECIFIC)

Load the primary archetype reference from `references/archetypes/{archetype}.md`. If hybrid: also load secondary for supplementary questions.

Ask Core Identity Questions from the archetype file. RULES:
- ONE question at a time, wait for answer
- Every question includes scaffolding (see `references/question-scaffolding.md`)
- Vague answer → drill deeper with follow-up
- "I don't know" → offer 2-3 options to choose from
- "You decide" → pick, mark as ASSUMED in DECISION_LOG, move on
- Scale adapts question count: Quick Build: 3-4 | Standard: 5-7 | Platform: 7-10 | Pioneering: 4-5
- Never batch questions. This is a conversation.

<IF condition="Scale is Platform">
Additional questions: stakeholders beyond end users, existing system integrations, compliance/regulatory requirements, non-functional requirements. See scaffolding in archetype file.
</IF>

### Research Checkpoint 1: Context Research

Execute archetype-specific research protocol from `references/research-protocols.md` — section for the primary archetype. Present: "Here's the landscape..."

<HARD-GATE>
"Does this change anything about your concept?" — user must respond before proceeding.
</HARD-GATE>

Save to `vision/core-identity.md`. Log decisions to `docs/reference/DECISION_LOG.md` (copy template from `assets/decision-log.md` if not exists).

## Phase 3: Deep Elicitation (ARCHETYPE-SPECIFIC)

### 3A. Archetype Deep Dive

Execute the full Phase 3 question bank from the archetype reference file. Produces: detailed experience/workflow description, feature map extracted from the experience, feature classification (MUST-HAVE / IMPORTANT / NICE / CUT).

### Research Checkpoint 2: Feature-Level Research

For EACH must-have and important feature: search best implementation, common pitfalls, tutorials. Present per feature. User confirms or adjusts.

### 3B. Edge Case Exploration

Probe 6 dimensions (scaffolded per archetype): Boundaries, Errors, Users, States, Scale, Time. See archetype reference file for archetype-specific scaffolding.

### Research Checkpoint 3: UX/Interaction Patterns

Search UX patterns, best practices, inspiration sources. Present pattern options with pros/cons. User selects preferred approaches.

<IF condition="Scale is Platform">
Additional: domain modeling, multi-user-type journeys, API surface design, integration architecture.
</IF>

Save to `vision/deep-elicitation.md`. Log decisions to DECISION_LOG.

## Phase 4: Assumption Surfacing & Stress Testing

### 4A. "What Needs To Be True"

Generate assumptions FROM Phases 2-3 decisions. User only RATES them (Definitely True / Probably True / Unknown). Present by category: Desirability, Feasibility, Viability, Usability. Then: "Any other assumptions I missed?"

### Research Checkpoint 4: Assumption Validation

For EACH "Unknown" and "Probably" assumption: run targeted web research (2-3 searches). Present findings, update confidence. Flag remaining unknowns as "needs spike."

### 4B. Pre-Mortem

Load archetype-specific failure scenarios from the archetype reference file. User rates each: Likely / Possible / Unlikely. For each "Likely" or "Possible": ask mitigation strategy, log in assumption register.

### 4C. No-Gos Declaration

Auto-generate No-Gos from: features classified as CUT, scope boundaries from timeline, architectural constraints from research, user's "not what I want" moments. Present for user approval.

<HARD-GATE>
User approves No-Gos before proceeding.
</HARD-GATE>

Save to `docs/reference/ASSUMPTION_REGISTER.md` (copy template from `assets/assumption-register.md` if not exists) + `vision/stress-test.md`.

## Phase 5: Dimension Completeness Sweep

Read `references/dimension-sweep.md` for the full protocol. Load DECISION_LOG to identify what's already decided. Run through dimensions D04-D10, skipping items already covered by Phases 2-4. Scale determines depth per dimension. Log ALL decisions to DECISION_LOG.

### Research Checkpoint 5: Stack & Architecture

Search stack project structure, architecture patterns, testing strategy for the complete selected stack.

Cross-dimension constraint check: detect contradictions (serverless + WebSocket, static + SSR, etc.). Present conflicts → resolve with user.

## Phase 6: Vision Synthesis

Generate Shape Up pitch: PROBLEM/CONCEPT, APPETITE, SOLUTION, RABBIT HOLES, NO-GOS. Generate `vision/project-pitch.md`. Highlight every ASSUMED and SPECULATIVE decision — user confirms or changes each.

<HARD-GATE>
User approves the full vision before proceeding to backlog generation.
</HARD-GATE>

## Phase 7: MVP Scoping & Backlog Generation

Read `references/engineering-by-archetype.md` for testing strategy and success criteria per archetype.

### 7A. MVP Feature Selection

Start with assumption register. Select features: all must-haves → in, features validating high-impact unknowns → in, nice-to-have → out. For each: "Ship without this? Still validate core?" Yes → cut.

<HARD-GATE>User approves feature list.</HARD-GATE>

### 7B. Success Criteria (archetype-specific)

Define SUCCESS and FAIL thresholds + circuit breaker date per the archetype success criteria templates in `references/engineering-by-archetype.md`.

### 7C. Epic & Story Generation

Read `references/scale-guide.md` for scale-adapted epic structures. Read `references/phase-transition-template.md` for the Phase Transition epic. Generate epics with Phase Transition as the LAST epic. For each story include: standard AC + archetype-specific AC layers, relevant decisions from DECISION_LOG, relevant assumptions from ASSUMPTION_REGISTER, No-Gos from project-pitch.md.

<HARD-GATE>User approves stories.</HARD-GATE>

Generate outputs: PRD_SUMMARY.md, BACKLOG_INDEX.md, DECISION_LOG.md, ASSUMPTION_REGISTER.md, backlog/E*.md, scaffold.

Populate framework documents from discovery outputs per the documentation flow in Phase 6/7 of this skill. Map decisions → docs/context/*, GROUND_RULES.md, ARCHITECTURE.md, CODING_STANDARDS.md, CLAUDE.md.

## Quick Start Mode

For Quick Build scale, or `--quick` flag, or user says "just start" / "skip the questions."

1. Phase 1 classification (3 questions: archetype + scale + "X meets Y")
2. 3-5 essential questions ONLY (archetype core question + who/device + ONE thing to nail)
3. 1 quick research: landscape scan (2-3 searches)
4. Auto-pick all technical decisions (mark as ASSUMED in DECISION_LOG)
5. Generate minimal pitch + minimal backlog: E01 Core Build (3-5 stories) + E02-REVIEW Quick Phase Transition (3 stories)
6. Start building immediately

Key: "Document as you go, not before you start." Phase Transition Stories still trigger a review loop.

## Pioneering Mode

For Pioneering scale, or `--pioneer` flag, or Uncategorized archetype.

1. Core Identity questions + DEEP research (academic, patents, adjacent tech)
2. Spike Planning: identify 2-3 time-boxed experiments
3. Generate spike-first backlog: E01 Spikes (2-3 experiments) + E02-REVIEW Post-Spike Review
4. After spikes: re-enter /discover with real findings → clearer archetype + scale → GUIDED or PLATFORM mode

## Graceful Degradation

| Dependency | If Missing |
|---|---|
| WebSearch/WebFetch | Skip research checkpoints, mark tech decisions as ASSUMED, note in pitch |
| Archetype reference file | Fall back to Uncategorized questions |
| Existing dimension files | Ask questions inline without structured options |
| DECISION_LOG.md | Create fresh from template |
| vision/ directory | Create it |

## Rules

- NEVER batch questions — one at a time, wait for answer
- NEVER skip scaffolding — every question includes options/examples
- NEVER fill gaps silently — mark as ASSUMED in DECISION_LOG if user says "you decide"
- ALWAYS save decisions to DECISION_LOG.md with confidence level
- ALWAYS include Phase Transition Stories as the last epic
- ALWAYS get user approval at HARD GATEs before proceeding
- Follow question scaffolding rules from `references/question-scaffolding.md`
