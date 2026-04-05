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
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent, AskUserQuestion
argument-hint: "<idea-description> [--quick|--platform|--pioneer]"
---
______________________________________________________________________

## discover

Deep guided elicitation for: **$ARGUMENTS**

Read `references/question-scaffolding.md` — these 8 rules apply to EVERY question you ask. Read `@.claude/prompts/interactive-ux.md` for the shared interactive UX protocol (AskUserQuestion format, progress tracking, confirmation gates).

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

Show the opening progress bar:

```
---
**Discover** | Phase 1 of 7: Classification
[>....................] 0 of ~22 decisions
Coming up: What kind of project is this, and how big?
---

Let's start by understanding what kind of project this is. I'll ask 4-5 quick
questions to classify your idea — this takes about 2 minutes.
```

### 1A. Archetype Selection (recognition-based — use AskUserQuestion)

Analyze the user's idea description from Phase 0. Identify the top 3 matching archetypes. Present via **AskUserQuestion**:

```
header: "Project type"
question: "Based on your description, your project seems closest to one of these.
           Which fits best? Select 'Other' to see all 11 options or describe
           something different."
options:
  - label: "[Best match] (Recommended)"
    description: "[one-sentence archetype description]. Like [3 examples]."
  - label: "[Second match]"
    description: "[one-sentence description]. Like [3 examples]."
  - label: "[Third match]"
    description: "[one-sentence description]. Like [3 examples]."
```

If user selects "Other": display the full archetype card from `references/scale-guide.md` as text, then use a new AskUserQuestion with their indicated preference.

### 1B. Sub-variant Confirmation via Analogy (use AskUserQuestion)

Load the archetype's reference file for sub-variant examples. Present via **AskUserQuestion**:

```
header: "Sub-type"
question: "You said [archetype]. Is it more like one of these?
           Select 'Other' if none quite fit."
options: [3 sub-variants from archetype file, each with description]
```

### 1C. Hybrid Check (use AskUserQuestion)

Based on the idea, identify the most likely secondary archetype. Present via **AskUserQuestion**:

```
header: "Hybrid?"
question: "Does your project also have a strong [other archetype] element?
           Most real projects span 2 types."
options:
  - label: "Yes, also [archetype]"
    description: "This adds [archetype]-specific questions to make sure we cover
                  both aspects of your project."
  - label: "No, just [primary]"
    description: "We'll focus entirely on the [primary archetype] perspective."
  - label: "Actually, it's more like..."
    description: "Pick this if the secondary archetype I suggested doesn't feel right
                  but there IS a second element."
```

### 1D. Scale Classification (use AskUserQuestion)

Read `references/scale-guide.md` for the full definitions. Infer the most likely scale from the description's timeline, complexity, and scope. Present via **AskUserQuestion**:

```
header: "Scale"
question: "How big and complex is this project? This determines how deep we go
           in planning. Select 'Other' if none of these fit."
options:
  - label: "[Inferred scale] (Recommended)"
    description: "[description]. [why this fits based on what user said]"
  - label: "Quick Build"
    description: "1-3 days. Single feature, one user type. Like a CLI tool or
                  game jam entry. We'll plan fast and start building immediately."
  - label: "Standard"
    description: "1-4 weeks. Frontend + backend + database. A proper MVP for a
                  target audience. Balanced planning and building."
  - label: "Platform"
    description: "1-6 months. Multiple services, user types, or integrations.
                  Thorough planning with architecture decisions and ADRs."
```

Note: If the recommended scale is one of the 3 listed, show it first with `(Recommended)` and replace it in the list with the 4th option (Pioneering: "Unknown timeline. Novel concept where the architecture IS the question. Needs research spikes first.").

### 1E. Quick Context Baseline (5 universal questions)

1. "In one sentence, what is this?" (scaffold: "'It's [X] that [does Y]'")
2. "What existing thing is this most like? 'It's X meets Y.'"
3. "Where and when will people use this?" (scaffold: "Phone on bus? Desktop at work?")
4. "How long is a typical session?" (scaffold: "30 seconds? 5 minutes? An hour?")
5. "Timeline and who's building?" (scaffold: "Weekend? Month? Just you?")

### 1F. Mode Selection

Select mode from scale + flags. Save to `vision/classification.md`.

Show transition summary:

```
---
Phase 1 Complete: Classification
---

**Decided so far:**
- Archetype: [primary] (+ [secondary] if hybrid)
- Scale: [name]
- One-liner: "[X meets Y]"
- Context: [device], [session length], [timeline]

**Moving to Phase 2:** Core Identity — we'll explore what makes your project unique.
```

<IF condition="Mode is QUICK">
Jump to Quick Start flow (below).
</IF>
<IF condition="Mode is PIONEERING">
Jump to Pioneering flow (below).
</IF>

## Phase 2: Core Identity (ARCHETYPE-SPECIFIC)

```
---
**Discover** | Phase 2 of 7: Core Identity
[===>................] 4 of ~22 decisions
Coming up: What makes your project unique?
---

Now let's explore the heart of your idea. I'll ask questions specific to your
type of project — this shapes everything that gets built.
Time: ~5 minutes of conversation.
```

Load the primary archetype reference from `references/archetypes/{archetype}.md`. If hybrid: also load secondary for supplementary questions.

Ask Core Identity Questions from the archetype file. RULES:
- ONE question at a time, wait for answer
- Every question includes scaffolding (see `references/question-scaffolding.md`)
- **Questions with clear options** (e.g., "visual style", "monetization model") → use **AskUserQuestion** with the archetype file's options. Add to question text: _"Select 'Other' to describe your own vision — more detail helps me build something closer to what you want."_
- **Open-ended questions** (e.g., "describe the experience", "what problem?") → ask conversationally with scaffolding examples
- Vague answer → drill deeper with follow-up
- "I don't know" → present 2-3 options via **AskUserQuestion** as a fallback
- "You decide" → pick, mark as ASSUMED in DECISION_LOG, move on
- Scale adapts question count: Quick Build: 3-4 | Standard: 5-7 | Platform: 7-10 | Pioneering: 4-5
- Never batch questions. This is a conversation.

<IF condition="Scale is Platform">
Additional questions: stakeholders beyond end users, existing system integrations, compliance/regulatory requirements, non-functional requirements. See scaffolding in archetype file.
</IF>

### Research Checkpoint 1: Context Research

Execute archetype-specific research protocol from `references/research-protocols.md` — section for the primary archetype. Present: "Here's the landscape..."

<HARD-GATE>
Use **AskUserQuestion** to check research impact:

```
header: "Research"
question: "Here's what I found about the landscape. Does this change anything
           about your concept?"
options:
  - label: "No changes, continue (Recommended)"
    description: "The research confirms the direction. Let's keep going."
  - label: "Yes, I want to adjust"
    description: "Something in the research changes how I think about this.
                  I'll describe what I want to change."
  - label: "Tell me more about..."
    description: "I want to dig deeper into a specific finding before deciding."
```
</HARD-GATE>

Save to `vision/core-identity.md`. Log decisions to `docs/reference/DECISION_LOG.md` (copy template from `assets/decision-log.md` if not exists).

## Phase 3: Deep Elicitation (ARCHETYPE-SPECIFIC)

```
---
**Discover** | Phase 3 of 7: Deep Elicitation
[======>..............] 8 of ~22 decisions
Coming up: Detailed features, user journeys, and edge cases
---

We've defined WHAT you're building. Now let's go deep on HOW it works —
features, workflows, and edge cases. This is where your idea becomes a product.
Time: ~10-15 minutes.
```

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

### 3D. Persona Synthesis

After deep elicitation completes, synthesize user personas from ALL Phase 2-3 answers. Personas generated here are richer than the early D02 user notes because they're informed by feature maps, user journeys, and edge cases.

**Generate 2-4 personas** in the lean 6-field format:

```markdown
## P[N]: [Name] — [Role] ([key context])
- **CONTEXT:** [Environment, tech proficiency, device, constraints]
- **GOALS:** [What they're trying to achieve — observable outcomes]
- **FRUSTRATIONS:** [What blocks them today — drives acceptance criteria]
- **BEHAVIORS:** [How they interact with similar products — informs UX]
- **EVALUATES BY:** "[Question 1]?" / "[Question 2]?"
- **FAILURE LOOKS LIKE:** [What goes wrong for this persona — informs testing]
```

**Rules for persona generation:**
- Derive from what the user SAID, not from archetypes or assumptions
- Each persona must have a DISTINCT behavior pattern — if two personas differ only by demographics, merge them
- Mark one as primary (★) — the persona the MVP is built for
- Cap at 4 personas; more usually means overlapping segments
- Scale adapts: Quick Build = 1 persona, Standard = 2-3, Platform = 3-4, Pioneering = 1-2 proto-personas

**Verify with user** via **AskUserQuestion** (`multiSelect`):

```
header: "User personas"
question: "Based on our conversation, I've identified these user types. Uncheck any
           that don't fit, or select 'Other' to add a user type I missed.
           I'll show the full persona cards after you confirm."
multiSelect: true
options:
  - label: "P1: [Name] — [Role] (Recommended as primary)"
    description: "GOALS: [goals]. FRUSTRATIONS: [frustrations].
                  EVALUATES BY: '[key question]?'"
  - label: "P2: [Name] — [Role]"
    description: "GOALS: [goals]. FRUSTRATIONS: [frustrations].
                  EVALUATES BY: '[key question]?'"
  - label: "P3: [Name] — [Role]"
    description: "GOALS: [goals]. FRUSTRATIONS: [frustrations].
                  EVALUATES BY: '[key question]?'"
```

After user confirms persona selection, if more than one persona confirmed, ask primary selection via **AskUserQuestion**:

```
header: "Primary persona"
question: "Which user should we prioritize when features conflict between personas?"
options: [one per confirmed persona, recommended = most frequently referenced in Phase 2-3]
```

For "Other" additions: ask 2-3 follow-up questions (context, goal, frustration), generate card, present for confirmation.

**Save** generated personas to `docs/context/personas.md` using the template format. Log persona decisions to DECISION_LOG with confidence `CONFIRMED` (user-verified) or `ASSUMED` (auto-generated in Quick mode).

**Transition:**

```
---
Phase 3 Complete: Deep Elicitation + Personas
---

**User personas confirmed:**
- ★ P1: [Name] — [Role] (primary)
- P2: [Name] — [Role]

**Moving to Phase 4:** Stress Testing — we'll test assumptions and identify risks.
```

## Phase 4: Assumption Surfacing & Stress Testing

```
---
**Discover** | Phase 4 of 7: Stress Testing
[==========>..........] 12 of ~22 decisions
Coming up: Testing your assumptions and identifying risks
---

Every project has hidden assumptions. Let's surface them now — it's much
cheaper to discover problems in planning than in code.
Time: ~5-10 minutes.
```

### 4A. "What Needs To Be True"

Generate assumptions FROM Phases 2-3 decisions. User RATES them using **AskUserQuestion** — batch up to 4 assumptions per call:

```
questions: [
  {
    header: "Assumption 1"
    question: "\"[assumption text]\". How confident are you?"
    options:
      - label: "Definitely true"
        description: "I have evidence or strong experience that confirms this."
      - label: "Probably true (Recommended)"
        description: "Seems reasonable, but I'm not 100% sure."
      - label: "Unknown"
        description: "I genuinely don't know — this needs validation."
  },
  // ... up to 4 per call
]
```

Present by category: Desirability, Feasibility, Viability, Usability. Then: "Any other assumptions I missed?"

### Research Checkpoint 4: Assumption Validation

For EACH "Unknown" and "Probably" assumption: run targeted web research (2-3 searches). Present findings, update confidence. Flag remaining unknowns as "needs spike."

### 4B. Pre-Mortem

Load archetype-specific failure scenarios from the archetype reference file. Rate each using **AskUserQuestion** — batch up to 4 scenarios per call:

```
questions: [
  {
    header: "Risk [N]"
    question: "\"[failure scenario]\". How likely is this for your project?"
    options:
      - label: "Likely"
        description: "This is a real risk I'm worried about. Let's plan a mitigation."
      - label: "Possible"
        description: "Could happen, but not my top concern. Worth noting."
      - label: "Unlikely (Recommended)"
        description: "Doesn't apply to my situation or I have this covered."
  }
]
```

For each "Likely" or "Possible": ask mitigation strategy conversationally, log in assumption register.

### 4C. No-Gos Declaration

Auto-generate No-Gos from: features classified as CUT, scope boundaries from timeline, architectural constraints from research, user's "not what I want" moments. Present for user approval via **AskUserQuestion** with `multiSelect`:

```
header: "No-Gos"
question: "These are the things we're explicitly NOT building. Uncheck any
           you disagree with. Select 'Other' to add more."
multiSelect: true
options:
  - label: "[No-go 1]"
    description: "[Why this is excluded and what happens if it creeps in]"
  - label: "[No-go 2]"
    description: "[Why excluded]"
  - label: "[No-go 3]"
    description: "[Why excluded]"
```

<HARD-GATE>
Use **AskUserQuestion** confirmation gate (see `interactive-ux.md` format).
User approves No-Gos before proceeding.
</HARD-GATE>

Save to `docs/reference/ASSUMPTION_REGISTER.md` (copy template from `assets/assumption-register.md` if not exists) + `vision/stress-test.md`.

## Phase 5: Dimension Completeness Sweep

```
---
**Discover** | Phase 5 of 7: Technical Decisions
[============>........] 14 of ~22 decisions
Coming up: Frontend, backend, database, auth, hosting, and design choices
---

We've defined WHAT you're building. Now let's decide HOW to build it.
I'll present options for each technology layer with my recommendation.
For each choice, I'll research what's current. This takes ~5-15 minutes
depending on how many decisions are still open.
```

Read `references/dimension-sweep.md` for the full protocol. Load DECISION_LOG to identify what's already decided. Run through dimensions D04-D10, skipping items already covered by Phases 2-4. Scale determines depth per dimension. **Use AskUserQuestion for every dimension** (each has 2-4 options — perfect fit). Log ALL decisions to DECISION_LOG.

### Research Checkpoint 5: Stack & Architecture

Search stack project structure, architecture patterns, testing strategy for the complete selected stack.

Cross-dimension constraint check: detect contradictions (serverless + WebSocket, static + SSR, etc.). Present conflicts → resolve with user.

## Phase 6: Vision Synthesis

```
---
**Discover** | Phase 6 of 7: Vision Synthesis
[=================>...] 20 of ~22 decisions
Coming up: Reviewing the complete project vision
---

Almost there! I'm synthesizing everything into a project pitch.
You'll review it and approve before we generate the build plan.
```

Generate Shape Up pitch: PROBLEM/CONCEPT, APPETITE, SOLUTION, RABBIT HOLES, NO-GOS. Generate `vision/project-pitch.md`. Highlight every ASSUMED and SPECULATIVE decision — user confirms or changes each.

<HARD-GATE>
Use **AskUserQuestion** for vision approval:

```
header: "Vision"
question: "Here's your complete project vision. I've highlighted all assumptions
           and speculative decisions above. Ready to proceed to backlog generation?"
options:
  - label: "Approved, generate backlog (Recommended)"
    description: "The vision captures what I want to build. Let's create the
                  build plan."
  - label: "I want to change specific items"
    description: "The direction is right but some details need adjusting.
                  I'll tell you what to change."
  - label: "Major rethink needed"
    description: "The vision has drifted from what I intended.
                  Let's go back to an earlier phase."
```
</HARD-GATE>

## Phase 7: MVP Scoping & Backlog Generation

```
---
**Discover** | Phase 7 of 7: Build Plan
[===================>] 21 of ~22 decisions
Coming up: Selecting MVP features and generating your build plan
---

Final phase! We'll select what goes in the MVP, define success criteria,
and generate your backlog of stories. After this, you're ready to build.
```

Read `references/engineering-by-archetype.md` for testing strategy and success criteria per archetype.

### 7A. MVP Feature Selection

Start with assumption register. Present feature list via **AskUserQuestion** with `multiSelect` — all must-haves pre-selected, nice-to-haves as options:

```
header: "MVP scope"
question: "Which features go in the MVP? Must-haves are listed first.
           Uncheck anything you want to cut. Select 'Other' to add features."
multiSelect: true
options:
  - label: "[Must-have feature 1] (Recommended)"
    description: "Core to the value proposition. Cutting this weakens the MVP."
  - label: "[Must-have feature 2] (Recommended)"
    description: "[why it's essential]"
  - label: "[Important feature]"
    description: "Validates [assumption]. Not strictly required but de-risks."
  - label: "[Nice-to-have feature]"
    description: "Can ship without this. Adds polish but not core value."
```

For each: "Ship without this? Still validate core?" Yes → cut.

<HARD-GATE>
Use **AskUserQuestion** confirmation gate for feature list approval (see `interactive-ux.md`).
</HARD-GATE>

### 7B. Success Criteria (archetype-specific)

Define SUCCESS and FAIL thresholds + circuit breaker date per the archetype success criteria templates in `references/engineering-by-archetype.md`.

### 7C. Epic & Story Generation

Read `references/scale-guide.md` for scale-adapted epic structures. Read `references/phase-transition-template.md` for the Phase Transition epic. Generate epics with Phase Transition as the LAST epic. For each story include: standard AC + archetype-specific AC layers, relevant decisions from DECISION_LOG, relevant assumptions from ASSUMPTION_REGISTER, No-Gos from project-pitch.md.

<HARD-GATE>
Use **AskUserQuestion** for story approval:

```
header: "Backlog"
question: "I've generated [N] stories across [M] epics. Here's the summary above.
           Ready to finalize?"
options:
  - label: "Approved, generate files (Recommended)"
    description: "Create all backlog files. You can still adjust individual
                  stories later."
  - label: "Adjust specific stories"
    description: "The structure is right but some stories need changes.
                  I'll describe what to adjust."
  - label: "Rethink the epic structure"
    description: "The stories are fine but the epic grouping needs work."
```
</HARD-GATE>

Generate outputs: PRD_SUMMARY.md, BACKLOG_INDEX.md, DECISION_LOG.md, ASSUMPTION_REGISTER.md, backlog/E*.md.

### 7D. Populate Project Documentation from Discovery

<HARD-GATE>
This step is MANDATORY. Do NOT skip it. Every file below must be populated with real content from discovery — not left as a template.
</HARD-GATE>

Using all decisions, research findings, and user answers from Phases 1-6, populate these files. Each file must contain project-specific content, not placeholder comments.

**From Phase 3D persona synthesis (already generated — verify exists):**
- `docs/context/personas.md` — Should already exist from Phase 3D. Verify it contains project-specific personas, not template placeholders. If missing (e.g., Phase 3D was skipped), generate now from Phase 2-3 user notes.

**From vision/classification.md + vision/core-identity.md:**
- `docs/context/project-overview.md` — What this project is, who it's for, what problem it solves, archetype + scale classification
- `docs/context/product-context.md` — Feature priorities, user journeys from Phase 3, validation plan from ASSUMPTION_REGISTER. Reference `docs/context/personas.md` for persona details (do not duplicate persona cards here).

**From vision/deep-elicitation.md + DECISION_LOG.md (technical decisions):**
- `docs/context/system-patterns.md` — Populate each section:
  - **Implementation Patterns:** Architecture pattern from Phase 5 dimension sweep (e.g., MVC, hexagonal, event-driven). Reference the proposed module structure.
  - **Architectural Conventions:** Naming and organization conventions from CODING_STANDARDS.md decisions. Import direction rules from the proposed module map.
  - **Error Handling Strategy:** From Phase 3B edge case exploration (error dimension) + Phase 5 error handling decisions.
  - **Testing Conventions:** From DECISION_LOG testing framework decisions + TESTING_STRATEGY.md choices.
  - **Implementation Recipes:** From the proposed architecture, document how to add the project's primary entity (e.g., "To add a new API endpoint: 1. Create handler in... 2. Add route in...").

**From DECISION_LOG.md (technical decisions from Phase 5 dimension sweep):**
- `docs/context/tech-context.md` — Stack choices (frontend, backend, database, auth, hosting), key libraries, API style, data layer decisions
- `docs/architecture/ARCHITECTURE.md` — Proposed architecture: tech stack table, architecture overview (Mermaid diagram from stack decisions), module map, dependency rules, deployment strategy
- `docs/reference/CODING_STANDARDS.md` — Language-specific conventions for the chosen stack, naming conventions, formatting tool, linter, quality gates
- `CLAUDE.md` — Fill in: Project Overview, Tech Stack (versions), Commands (for chosen stack), Architecture one-liner, Profile

**From vision/stress-test.md + vision/project-pitch.md:**
- `docs/reference/GROUND_RULES.md` — No-Gos become MUST-NOT rules, key architectural constraints from dimension decisions become MUST rules, add 3-5 principles from the chosen architecture pattern
- `docs/context/error-patterns.md` — Pre-mortem risks from Phase 4B as potential failure modes to watch for

**From DECISION_LOG.md (if test framework was decided):**
- `docs/reference/TESTING_STRATEGY.md` — Test Infrastructure section filled with chosen test runner, coverage tool, test command, test location. Testing approach from `references/engineering-by-archetype.md` for the project's archetype.

**From vision/classification.md (if project has no source files yet):**
- `docs/context/project-structure.md` — Proposed directory layout based on chosen stack and architecture pattern

**Scale-adapted depth:**
- Quick Build: populate CLAUDE.md (commands, overview) + GROUND_RULES.md (No-Gos only) + minimal tech-context.md. Skip ARCHITECTURE.md, CODING_STANDARDS.md, system-patterns.md (fill during first sprint).
- Standard: populate all files above
- Platform: populate all files above + create initial ADRs in docs/adr/ for major architectural decisions (database, auth, hosting, API style)
- Pioneering: populate CLAUDE.md + tech-context.md (what's known) + project-overview.md. Mark other files as "post-spike" with a note about what spikes will determine.

## Quick Start Mode

For Quick Build scale, or `--quick` flag, or user says "just start" / "skip the questions."

1. Phase 1 classification (3 questions: archetype + scale + "X meets Y")
2. 3-5 essential questions ONLY (archetype core question + who/device + ONE thing to nail)
3. 1 quick research: landscape scan (2-3 searches)
4. Auto-generate 1 persona from answers (mark as ASSUMED). Confirm with user: "Your main user seems to be [X]. Sound right?" Save to `docs/context/personas.md`.
5. Auto-pick all technical decisions (mark as ASSUMED in DECISION_LOG)
6. Generate minimal pitch + minimal backlog: E01 Core Build (3-5 stories) + E02-REVIEW Quick Phase Transition (3 stories)
7. Start building immediately

Key: "Document as you go, not before you start." Phase Transition Stories still trigger a review loop.

## Pioneering Mode

For Pioneering scale, or `--pioneer` flag, or Uncategorized archetype.

1. Core Identity questions + DEEP research (academic, patents, adjacent tech)
2. Generate 1-2 proto-personas from core identity answers, mark as ASSUMED. Save to `docs/context/personas.md` with note: "Proto-personas — refine after spikes."
3. Spike Planning: identify 2-3 time-boxed experiments
4. Generate spike-first backlog: E01 Spikes (2-3 experiments) + E02-REVIEW Post-Spike Review
5. After spikes: re-enter /discover with real findings → clearer archetype + scale → GUIDED or PLATFORM mode → regenerate personas with real data

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
