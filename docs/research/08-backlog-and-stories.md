# Backlog management and story templates for AI-assisted development

**The single highest-leverage practice for AI-assisted development is machine-verifiable acceptance criteria — stories where "done" is proven by running a command.** Spec-Driven Development (SDD) has emerged as the dominant paradigm for AI coding agents in 2025–2026, replacing traditional user stories with structured specification documents that guide agents through a specify → plan → implement → validate loop. This research synthesizes findings from Anthropic's official best practices, GitHub's Spec Kit, Amazon's Kiro IDE, practitioner blogs, academic papers, and established agile methodology to define the optimal story format, backlog structure, and decomposition strategy for the JD-LLM Development Framework.

The implications are significant: teams that adopt structured, machine-verifiable stories report **40–80% fewer bugs** through test-first workflows, while AI agents operating on well-scoped stories (≤5 files, under 30K tokens of context) succeed far more reliably than those given large, ambiguous tasks. A 5% error rate per agent action means a 10-turn task has only **59.9% probability of success** — making story decomposition the primary determinant of AI implementation reliability.

---

## 1. Story formats that drive quality AI implementation

### User stories vs job stories vs feature specs

Traditional user stories ("As a [user], I want [action], so that [benefit]") remain useful for capturing intent but are **insufficient for AI coding agents**. The persona-action-benefit structure provides motivation but lacks the technical specificity AI needs to generate correct code. Without explicit constraints, examples, and acceptance criteria, LLMs fill gaps with assumptions from training data — often incorrectly.

Job stories ("When [situation], I want to [motivation], so I can [outcome]") perform better because the situational trigger ("When an order is submitted...") gives AI agents grounding about state management, preconditions, and where in the codebase to implement changes. This maps naturally to event-driven code and BDD test structures.

**Feature specs have emerged as the clear winner for AI-assisted development.** GitHub's open-source Spec Kit treats specs as first-class artifacts (`spec.md` → `plan.md` → `tasks.md` → implementation). Amazon's Kiro IDE implements SDD natively with three files: `requirements.md`, `design.md`, and `tasks.md`. Addy Osmani notes that "simply throwing a massive spec at an AI agent doesn't work — the key is to write smart specs: documents that guide the agent clearly, stay within practical context sizes, and evolve with the project."

The optimal approach for AI agents is a **hybrid format**: a one-line user story for the "why," structured feature specs for the "what," and decomposed tasks for the "how." This is the format recommended for the JD-LLM Framework.

### BDD Given/When/Then and EARS notation

BDD's Given/When/Then format is highly effective for AI agents because it maps directly to test setup, execution, and assertion. The `Given` clause establishes state, `When` triggers action, `Then` verifies outcome — a structure AI can implement mechanically into automated tests. Simon Willison's insight captures this well: "Tests give us reliable exit criteria. We force the agent to iterate until the previously failed tests pass."

The **EARS notation** (Easy Approach to Requirements Syntax) is emerging as a complementary format, particularly via Amazon Kiro: `WHEN [condition/event] THE SYSTEM SHALL [expected behavior]`. Originally developed at Rolls-Royce for airworthiness regulations, it provides machine-readable precision for system-level constraints.

For AI agents, **checklist-style AC outperforms pure BDD for most cases** because each item maps to a discrete testable assertion and consumes fewer context window tokens. The recommendation is checklist as the default format with GWT reserved for complex behavioral scenarios involving multiple preconditions.

### Which INVEST criteria matter most for AI

The INVEST criteria require reweighting for AI implementation:

- **Testable** is the single most critical criterion. Without testable acceptance criteria, the AI has no exit condition and no way to self-verify. Tests are guardrails forcing the agent to iterate until correct.
- **Small** is essential for context window management. Stories must fit within a single agent session. Error compounding means smaller tasks succeed far more reliably.
- **Independent** matters because AI agents operate in isolated context windows. Dependencies between stories cause failures since agents cannot share state across sessions.
- **Estimable** helps determine if a story fits within a single context window. If you cannot estimate it, it is probably too ambiguous for AI.
- **Negotiable** is least critical — for AI agents, explicit specifications replace negotiation. The spec is the contract.

### How leading teams structure stories

**Linear** explicitly rejects traditional user stories. Their methodology states: "User stories have become a cargo cult ritual that wastes resources. They're a roundabout way to describe tasks, obscuring the work to be done." Linear advocates short, direct issue titles stating the task, with optional descriptions for context.

**Spotify** has no standardized story format — each autonomous squad chooses their own approach. Their success comes from deep product understanding before coding, not from story templates. Some squads that adopted structured Scrum reduced average completion time from **8.1 to 3.9 days**.

**GitHub Spec Kit** uses markdown specification files with acceptance criteria and implementation tasks. **Amazon Kiro** generates EARS-format acceptance criteria from natural language prompts. Both implement the specify → plan → implement → validate loop that defines SDD.

### Emerging AI-native formats

Several AI-native story formats have emerged. The **"Agent Stories"** framework proposes: "As [AI agent type], given [context/constraints], I will [action], so that [verifiable outcome]." ProdMoh proposes JSON-structured stories with fields for id, title, intent, acceptance criteria (predicate-based), examples, constraints, and NFRs. The **BMAD Method** provides an agile framework where "stories are small and acceptance criteria are explicit, producing predictable increments that are easier to review and revert."

The most significant pattern is the **three-file specification** (requirements → design → tasks) now implemented by both Kiro and Spec Kit — this is the architecture the JD-LLM Framework should adopt.

---

## 2. Story mapping and decomposition for AI-sized units

### Jeff Patton's story mapping applied to AI workflows

Jeff Patton's story mapping solves what he calls the "flat backlog" problem — "a bag of context-free mulch." The methodology creates a 2D representation organized around the user journey: activities left-to-right across the backbone, detailed stories top-to-bottom by priority under each activity, with horizontal release slices defining MVPs.

For AI-assisted development, story maps directly reveal which stories can be independently implemented by an AI agent (self-contained vertical slices), identify natural dependency chains, and guide decomposition so each story fits within a single context window. The map structure ensures the "tree" of product context is preserved rather than lost in a flat list.

### Vertical slicing is non-negotiable for AI agents

**Every story for AI implementation must be a vertical slice** — cutting through all architectural layers (UI → business logic → data) to deliver a thin, complete piece of functionality. Horizontal slicing (one story for the database, another for the API) creates non-independent stories that cannot deliver value alone and cannot be verified in isolation.

AI agents excel at vertical slices because each slice is a self-contained unit with clear inputs, outputs, and testable acceptance criteria — completable and verifiable in a single session. The only exception is foundational horizontal "enabler" stories (database infrastructure, auth framework setup, CI/CD configuration) that must be implemented first.

### SPIDR splitting patterns

Mike Cohn's SPIDR framework provides five splitting patterns ordered by preference:

- **Paths**: Split by alternate user flows. Implement the happy path first, then alternative flows in separate AI sessions. Each path becomes an independent task.
- **Interfaces**: Split by UI complexity. First story delivers functional-but-minimal UI; subsequent stories add progressive enhancement. Reduces cognitive load per session.
- **Data**: Split by data subsets. "Handle positive balances only" → "Add negative balance support." Each data variant is a clean, bounded task.
- **Rules**: Relax or defer business rules. Start with simplified rules, add constraints incrementally. Each rule addition is a focused, testable unit.
- **Spike**: Research activity when other methods cannot work. Frame as: "Investigate X and produce a recommendation document."

The heuristic: try Paths, Interfaces, Data, Rules first. Resort to Spike only when other methods fail.

### The Elephant Carpaccio principle for AI sizing

Alistair Cockburn's Elephant Carpaccio technique — slicing even the largest feature into infinitely thin vertical slices — is the **ideal mental model for AI story sizing**. Each "slice" maps to a single AI session: start with the absolute minimum working implementation, then each subsequent slice adds exactly one thing (one data type, one rule, one UI enhancement). Every slice is testable and demoable.

### Sizing heuristics for single-context-window implementation

Research converges on these practical sizing constraints for AI-implementable stories:

- **Each story should touch ≤5 files** — keeps context manageable and focused
- **Story spec + relevant code context should stay under 30K tokens** — even with 200K+ token windows, focused context produces dramatically better results
- **Each story should be describable in one sentence with one measurable outcome** — if not, split it
- **Target completability in a single AI session** without context overflow or compaction
- **Each subtask should use less than half the available context window**

Addy Osmani warns: "If you ask for too much in one go, it's likely to get confused or produce a 'jumbled mess' that's hard to untangle — like 10 devs worked on it without talking to each other."

### Decomposing a PRD into AI-implementable units

The recommended five-step decomposition process:

1. **PRD → Epics**: Identify 3–7 major capability areas. Each epic represents a major user journey or feature area.
2. **Epics → Stories** (using story mapping): Map user journeys, break activities into steps, each step becomes a candidate story. Apply INVEST criteria.
3. **Stories → AI units** (using SPIDR + vertical slicing): Ask "Can this be implemented in a single AI session with clear AC?" If not, split by Paths, Interfaces, Data, or Rules.
4. **Sequence by dependencies**: Infrastructure → Data models → Core features → Enhancements → Polish. Document explicit dependency chains.
5. **Write AI-optimized specs**: Title, context, acceptance criteria, affected files, dependencies, out-of-scope statements.

---

## 3. Backlog organization for markdown-based AI workflows

### Hierarchy depth and structure

The consensus across Atlassian, Linear, and practitioner research is that **two levels are sufficient for AI workflows**: Epic (grouping) → Story (individual work items). Deeper hierarchies add overhead without improving AI implementation quality. Stories can optionally contain subtasks for complex multi-step implementations, but this should be the exception.

The QuantumBlack/McKinsey research on agentic workflows recommends a **folder-based hierarchy** with deterministic workflow:

```
.sdlc/
  context/          # Persistent project context
    project-overview.md
    architecture.md
    conventions.md
  specs/            # Per-feature specifications
    REQ-001-feature/
      requirement.md
      tasks/
        TASK-001.md
        TASK-002.md
```

This pattern aligns well with markdown-based backlog management tools like **Backlog.md**, the leading open-source solution for git-native, AI-assisted task management.

### Priority frameworks compared

**MoSCoW** (Must/Should/Could/Won't) is the most practical framework for markdown-based backlogs — it is categorical, requires no numerical data, and forces explicit scope decisions. **RICE** (Reach × Impact × Confidence / Effort) provides quantitative rigor for ranking within categories but requires usage data. **Kano** is valuable for understanding customer satisfaction drivers but too complex for story-level prioritization.

The recommended combination: **MoSCoW to scope each cycle** (what's in, what's out), with a simple **P0–P3 numeric priority** for sorting within Must-Have and Should-Have categories. This maps naturally to the JD-LLM Framework's story classification system.

### Status workflow for AI-assisted development

```
draft → ready → in-progress → review → done
                    ↓
                 blocked
```

| Status | Description | AI relevance |
|--------|-------------|-------------|
| **draft** | Idea captured, needs refinement. Missing AC or technical details. | Not ready for AI |
| **ready** | Meets Definition of Ready. AC defined, dependencies resolved. | AI can pick this up |
| **in-progress** | Being implemented by human or AI agent. | One task per session |
| **review** | Implementation complete, awaiting human verification. | Human reviews AI output |
| **done** | Accepted, merged, meets Definition of Done. | Archived |
| **blocked** | Cannot progress. Must document blocking reason and blocker reference. | AI skips to next ready item |

### Labels and metadata taxonomy

Keep labels to **3–5 per item maximum**, organized by category:

- **type**: `feature`, `bugfix`, `refactor`, `spike`, `infra`, `testing`, `docs`, `security`, `performance`, `skill`
- **area**: Module or component tags (e.g., `area:auth`, `area:api`, `area:frontend`)
- **priority**: `P0-critical`, `P1-high`, `P2-medium`, `P3-low`
- **size**: `TRIVIAL`, `SMALL`, `STANDARD` (matching JD-LLM story classification)
- **status**: Tracked via workflow, not labels

### Definition of Ready for AI implementation

A story is "ready" for AI implementation when all of these are true:

- Acceptance criteria are defined, specific, and machine-verifiable
- Verification commands are specified (test, lint, typecheck, build)
- The story is independent — no unresolved blocking dependencies
- Scope boundaries are clear — out-of-scope items listed
- Technical context is provided — affected files, patterns to follow, constraints
- The story fits in a single AI session (≤5 files, <30K tokens of context)
- No unresolved questions or ambiguities remain

---

## 4. Acceptance criteria optimized for AI coding agents

### Machine-verifiable AC are the highest-leverage practice

Anthropic's official Claude Code documentation states: **"This is the single highest-leverage thing you can do. Claude performs dramatically better when it can verify its own work."** Without clear success criteria, the agent might produce something that looks right but does not work.

The principle is simple: a test is a machine-executable statement of a requirement. When it passes, it proves the requirement was met. When it fails, it identifies exactly what was missed. The test suite is the contract between human intent and machine execution.

### The Goldilocks zone of specificity

Too vague ("Make the login work") → AI guesses wrong, handles only the happy path.
Too prescriptive ("On line 15, add a try-catch block using exactly this pattern") → constrains AI from applying better solutions, wastes tokens on implementation details.
Just right: **high specificity for outcomes and edge cases, low specificity for implementation approach.**

| Aspect | Specify (always) | Don't specify (usually) |
|--------|----------|---------------|
| Expected behavior and outcomes | ✅ | |
| Edge cases and error conditions | ✅ | |
| Data formats and validation rules | ✅ | |
| Verification commands | ✅ | |
| Implementation approach | | ❌ |
| Internal architecture choices | | ❌ |
| Specific algorithms | | ❌ |

The sweet spot is **3–7 acceptance criteria per story**. Fewer means insufficient guidance. More than 7 suggests the story needs splitting.

### Scope control through non-goals

AI agents lack the human intuition to self-limit scope. Without explicit boundaries, they will over-implement or gold-plate. Every story should include an **Out of Scope** section listing things that might seem related but are not part of this story, future enhancements tracked elsewhere, and explicit "must not" constraints (e.g., "Must not modify the shared authentication middleware").

### Referencing codebase conventions

Rather than duplicating conventions in every story, use a layered approach:

1. **CLAUDE.md / AGENTS.md** at project root encodes global conventions — build commands, test commands, coding patterns, architectural decisions, and "never do" boundaries
2. **Subdirectory CLAUDE.md files** encode module-specific patterns
3. **Story-level references** point to exemplar files: "Follow the controller pattern in `src/api/users.controller.ts`"

The key principle: **prefer pointers over copies**. Don't put code snippets in documentation (they go stale). Reference file paths of authoritative patterns. The AI will read those files as needed. Research from XDA/ETH Zurich shows AGENTS.md context files now provide approximately **5% improvement** over baseline while overly detailed ones can increase reasoning token use by 20% — include minimum necessary requirements only.

---

## 5. Estimation and forecasting in the AI era

### Traditional estimation is breaking down

Story points become unreliable when AI implements stories — teams using Cursor report that traditional estimates immediately become meaningless as each developer becomes "dramatically more productive." The variance between AI-assisted and unassisted tasks is too large for consistent estimation.

The **#NoEstimates movement aligns naturally with AI-assisted development**. Core principle: make stories so small that estimating becomes pointless. If properly sliced, stories cluster around a small, uniform size, defeating the need to estimate. The shift is from velocity/throughput to **flow metrics: cycle time and lead time**.

### Complexity classification replaces story points

For the JD-LLM Framework, the TRIVIAL/SMALL/STANDARD classification should be based on AI-implementability factors:

- **TRIVIAL** (<15 min): Config changes, text/UI updates, boilerplate CRUD, adding fields to existing forms. AI handles autonomously with minimal review.
- **SMALL** (<1 hour): Single-file features, straightforward API endpoints, unit test generation, simple refactors following established patterns. AI handles with brief human review.
- **STANDARD** (1–4 hours): Multi-file changes touching 3–5 files, new features integrating with existing patterns, moderate business logic. AI needs a plan-then-implement workflow with human review.
- Stories exceeding STANDARD scope **must be split** — they represent unacceptable risk for single-session AI implementation.

Key factors in classification: **number of files touched** (context window pressure), **degree of implicit knowledge required**, **whether established patterns exist**, and **integration surface area**.

### Metrics that matter for AI-assisted throughput

Traditional velocity metrics are becoming "not just limited but harmful" according to DX Research. The recommended metrics for AI-assisted development:

- **Cycle time**: Time from "in-progress" to "done." Still the most reliable metric, though the delay now lives in the human-agent handoff rather than coding.
- **Throughput**: Stories completed per cycle. Flow-based forecasting using historical completion rates.
- **Agent Efficiency Score**: Tasks completed autonomously / (total tasks + human interventions × complexity penalty).
- **Human-Agent Handoff Time**: Time between AI signaling "stuck" and human resuming. This is the new bottleneck.
- **AI Revert Percentage**: Percentage of AI-generated commits that are reverted — a quality signal.

---

## 6. Anti-patterns that cause AI implementation failures

### The vagueness trap

AI agents interpret ambiguous instructions by filling gaps with assumptions from training data. A real-world example: an agent instructed to "remove outdated entries" without defining "outdated" deleted half the vendor records. Every story needs explicit acceptance criteria with measurable outcomes, negative criteria (what should NOT happen), and a context section explicitly stating assumptions.

### The over-prescription trap

The opposite failure: specifying exact implementation details ("use a HashMap to store sessions, iterate with for-each") forces AI into suboptimal paths. Claude Code best practices recommend: "Don't railroad Claude — give goals and constraints, not prescriptive step-by-step instructions." Stories should state **what** and **why**, not **how**.

### Context window overflow

Factory.ai documents that "a typical enterprise monorepo can span thousands of files and several million tokens" while practical context effectiveness degrades well before windows are filled. Databricks found model correctness falls around **32K tokens** for many models. Stories touching more than 5–7 files or requiring extensive context reliably produce degraded output. The solution: split stories to touch fewer files, use the plan → execute → review → ship pattern, and clear context between unrelated tasks.

### Implicit knowledge and missing context

Up to **90% of organizational knowledge is tacit** — existing in team members' heads rather than documentation. AI agents don't know about previous architectural decisions, team coding conventions, or business constraints unless explicitly told. Stories that reference "the ticket" or "the design" without linking to actual content, assume knowledge of the deployment pipeline, or omit framework versions create systematic failures. The solution is **CLAUDE.md files as project memory**, self-contained stories with complete context, and Architecture Decision Records (ADRs) that AI can reference.

### The zombie pattern

Stories surviving more than two cycles must be **split or killed**. In AI-assisted development, zombies often arise from stories requiring tacit knowledge the AI doesn't have, stories that fail AI implementation and sit waiting for human rework, or stories where AI-generated code fails review repeatedly. Track story age as a health metric with automatic flagging at configurable thresholds.

---

## 7. Recommended story format for the JD-LLM Framework

Based on synthesis of all research, this is the recommended story template. Each field is justified by evidence.

```markdown
---
id: [PROJECT]-[NUMBER]
title: [Clear, one-line summary of what changes]
type: feature|bugfix|refactor|spike|infra|testing|docs|security|performance|skill
priority: P0|P1|P2|P3
size: TRIVIAL|SMALL|STANDARD
status: draft|ready|in-progress|review|done|blocked
created: YYYY-MM-DD
---

# [Title]

## Why
[1-2 sentences: What problem does this solve? What user/business value?]
As a [specific persona], I want [concrete action], so that [measurable outcome].

## Context
- **Current state**: [What exists now — behavior, relevant code, prior decisions]
- **Affected files**: [Explicit list of files/modules likely to change]
- **Follow patterns in**: [Reference to exemplar files in the codebase]
- **Dependencies**: [Stories that must be complete first, or "None"]

## Acceptance criteria
- [ ] [Specific, testable outcome — WHAT not HOW]
- [ ] [Edge case or error condition]
- [ ] [Another testable outcome]
- [ ] Given [precondition], when [action], then [verifiable result]

## Verification
```bash
npm test -- --grep "feature-name"   # Targeted tests pass
npm run lint                         # No lint errors
npm run typecheck                    # No type errors
npm run build                        # Build succeeds
```

## Out of scope
- [Thing that might seem related but is NOT part of this story]
- [Future enhancement tracked in PROJ-XXX]
- [Constraint: Must NOT modify X]

## Notes
[Optional: implementation hints, known gotchas, links to designs or docs]
```

### Field justifications

- **YAML frontmatter**: Machine-parseable metadata for filtering, sorting, and automation. Supports the backlog index generation.
- **type field**: Maps to the 10 JD-LLM story types; enables type-specific workflow depth in /story-cycle.
- **size field**: Maps to TRIVIAL/SMALL/STANDARD classification for workflow depth adjustment.
- **Why section**: Provides the "user story" intent without being the entire specification. One-liner context for the AI.
- **Context section with affected files**: Research shows AI performs dramatically better with focused context. Explicit file lists prevent context bloat.
- **"Follow patterns in" reference**: Leverages in-context learning without duplicating conventions. Points to authoritative code the AI can read.
- **Checklist-style AC**: More directly machine-parseable than pure BDD, each item maps to a testable assertion. BDD format used only when preconditions matter.
- **Verification section with exact commands**: The single highest-leverage practice per Anthropic's official guidance. AI can run these commands to self-verify.
- **Out of scope section**: Prevents AI scope creep. Research consistently shows AI agents gold-plate without explicit boundaries.

### Type-specific variations

**Bug Fix** stories replace the "Why" section with:
```markdown
## Bug
- **Current behavior**: [What happens now]
- **Expected behavior**: [What should happen]
- **Steps to reproduce**: [1, 2, 3...]
- **Root cause** (if known): [Description]
```

**Spike** stories replace AC with:
```markdown
## Research questions
1. [Specific question to answer]
2. [Specific question to answer]

## Output
- [ ] Decision document at [path] with recommendation
- [ ] Timebox: [X hours]
```

**Refactoring** stories add:
```markdown
## Constraints
- No changes to external behavior (refactor only)
- All existing tests must pass without modification
```

**Performance** stories add:
```markdown
## Metrics
- **Current**: [Measured baseline, e.g., p95 = 450ms]
- **Target**: [Required outcome, e.g., p95 < 200ms]
- **Benchmark command**: `npm run bench -- --grep "endpoint-name"`
```

---

## 8. Recommended backlog index structure

The backlog should live in a `backlog/` directory at the project root, using markdown files with YAML frontmatter. This structure is compatible with git-native workflows and AI agents that read files.

```
project-root/
├── CLAUDE.md                    # Project conventions, build/test commands
├── backlog/
│   ├── BACKLOG.md               # Master index (auto-generated or maintained)
│   ├── epics/
│   │   ├── EPIC-001-user-auth.md
│   │   ├── EPIC-002-dashboard.md
│   │   └── EPIC-003-api-v2.md
│   ├── stories/
│   │   ├── PROJ-001.md          # Individual story files
│   │   ├── PROJ-002.md
│   │   └── PROJ-003.md
│   ├── completed/               # Done stories (moved here on completion)
│   └── archive/                 # Cancelled or obsolete stories
```

### BACKLOG.md master index format

```markdown
# Project Backlog

> Last updated: YYYY-MM-DD | Ready: X | In Progress: Y | Blocked: Z

## Current cycle: [Cycle Name / Date Range]

### 🔴 P0 — Must have
| ID | Title | Type | Size | Status | Epic |
|----|-------|------|------|--------|------|
| PROJ-001 | User login with email | feature | SMALL | ready | EPIC-001 |
| PROJ-002 | Fix session timeout crash | bugfix | TRIVIAL | in-progress | EPIC-001 |

### 🟡 P1 — Should have
| ID | Title | Type | Size | Status | Epic |
|----|-------|------|------|--------|------|
| PROJ-003 | Password reset flow | feature | STANDARD | ready | EPIC-001 |

### 🟢 P2 — Could have
| ID | Title | Type | Size | Status | Epic |
|----|-------|------|------|--------|------|
| PROJ-004 | OAuth Google integration | feature | STANDARD | draft | EPIC-001 |

### ⚪ P3 — Won't have (this cycle)
| ID | Title | Type | Epic |
|----|-------|------|------|
| PROJ-005 | Biometric login | feature | EPIC-001 |

## Blocked items
| ID | Title | Blocked by | Reason |
|----|-------|-----------|--------|
| PROJ-006 | Dashboard metrics | PROJ-001 | Requires auth system |

## Backlog health
- Stories meeting DoR: X/Y (Z%)
- Average story age: N days
- Zombie stories (>2 cycles): [list or count]
```

### Epic file format

```markdown
---
id: EPIC-001
title: User Authentication
status: in-progress
priority: P0
owner: [name]
target: YYYY-MM-DD
---

# User Authentication

## Objective
[2-3 sentences: what this epic delivers and why it matters]

## Stories
- [x] PROJ-001 — User login with email (done)
- [ ] PROJ-002 — Fix session timeout crash (in-progress)
- [ ] PROJ-003 — Password reset flow (ready)
- [ ] PROJ-004 — OAuth Google integration (draft)

## Dependencies
- External API keys provisioned (resolved)
- Database schema migration (PROJ-000, done)

## Definition of Done
- All stories complete and merged
- E2E auth flow tests pass
- Security review complete
```

This structure supports the JD-LLM Framework's `/ideate` command (which generates stories into `backlog/stories/`) and `/story-cycle` command (which reads stories and classifies them by size).

---

## 9. Recommended decomposition heuristics

These heuristics guide the `/ideate` command's story decomposition from PRD or user ideas.

### The six golden rules

1. **One sentence, one outcome**: If you cannot describe the story in one sentence with one measurable outcome, split it.
2. **Every story is a vertical slice**: Each story touches all necessary layers and delivers independently testable functionality. No "just the database" or "just the UI" stories.
3. **Five-file ceiling**: Target ≤5 files touched per story. More than 5 signals context window pressure and should trigger splitting.
4. **Half-context budget**: Each story's spec plus relevant code context should consume less than half the available context window (~30K tokens).
5. **Start with the thinnest slice**: Apply Elephant Carpaccio — begin with the absolute minimum working implementation, then add one thing per subsequent story.
6. **Commit after every story**: Each completed story maps to one git commit. Git is persistent memory between AI sessions.

### The splitting decision tree

When a story is too large, apply these patterns in order:

1. **Split by Paths** — Can the happy path be separated from alternative flows? Implement the primary flow first, handle edge cases in follow-up stories.
2. **Split by Data** — Can you restrict data scope? Handle one data type first, add others later. "Support CSV export" → "Support JSON export."
3. **Split by Rules** — Can business rules be deferred? Start with simplified validation, add complex rules incrementally.
4. **Split by Interface** — Can the UI be simplified? Deliver functional-but-minimal interface first, enhance in subsequent stories.
5. **Create a Spike** — If the team cannot split because of unknowns, create a timeboxed research story first. The spike produces a recommendation document, not working software.

### Sizing spectrum for AI classification

| Size | Characteristics | AI workflow | Example |
|------|----------------|-------------|---------|
| **TRIVIAL** | Single-file change, <15 min, config/text update | Direct implementation, minimal review | Update error message text |
| **SMALL** | 1–2 files, <1 hour, follows existing patterns | Implement → test → review | Add validation to existing form |
| **STANDARD** | 3–5 files, 1–4 hours, requires plan | Plan → review plan → implement → test → review | New API endpoint with auth, validation, tests |
| **Too large** | >5 files or >4 hours | **Must split** before implementation | Full CRUD feature with UI, API, DB, tests |

### PRD decomposition algorithm

For the `/ideate` command:

1. Extract **user personas** and **user journeys** from the PRD
2. Map each journey into **activities** (top-level groups) → these become epics
3. Break each activity into **steps** → these become candidate stories
4. For each candidate story, apply the **sizing test**: Does it meet the five-file ceiling and half-context budget?
5. If too large, apply the **splitting decision tree** above
6. Sequence stories: **Foundation** (schema, config, scaffolding) → **Core** (primary user flows) → **Enhancement** (secondary flows, edge cases) → **Polish** (performance, UI refinement)
7. Mark dependencies explicitly using `blockedBy` references

---

## 10. Story quality checklist

This checklist validates that a story is ready for AI implementation. It should be used by the `/ideate` command during story generation and by `/story-cycle` before implementation begins.

### Pre-implementation quality gate

- [ ] **Title is clear and specific** — describes the change, not the problem
- [ ] **Type is assigned** — one of the 10 supported types
- [ ] **Size is classified** — TRIVIAL, SMALL, or STANDARD (if too large, split first)
- [ ] **Acceptance criteria exist** — 3–7 specific, testable conditions
- [ ] **Verification commands specified** — exact commands that prove completion
- [ ] **Out of scope is defined** — at least one explicit exclusion
- [ ] **Affected files listed** — AI knows where to focus
- [ ] **Pattern references included** — "Follow patterns in [file]" where applicable
- [ ] **Dependencies resolved or documented** — no unresolved blockers
- [ ] **No ambiguous language** — no "should be fast," "handle errors properly," or "make it work"
- [ ] **Edge cases explicit** — error conditions, empty states, boundary values stated
- [ ] **Self-contained** — story includes or links to all referenced context
- [ ] **Single AI session scope** — implementable without context overflow

### Common rejection reasons

- **Too vague**: "Improve the dashboard" → Rewrite with specific measurable changes
- **Too large**: Touches >5 files or requires >4 hours → Split using SPIDR
- **Missing verification**: No commands to prove completion → Add test/lint/build commands
- **Implicit knowledge**: Assumes understanding not in CLAUDE.md or story context → Make explicit
- **No scope boundary**: Missing out-of-scope section → Add explicit exclusions

---

## 11. Knowledge gaps and emerging areas

Several areas lack mature research or established best practices:

**AI-specific estimation models** remain nascent. No rigorous framework exists for predicting how long an AI agent will take to implement a given story. The TRIVIAL/SMALL/STANDARD classification is based on practitioner heuristics, not empirical data. Teams should track their own cycle times per size category and calibrate over time.

**Multi-agent story coordination** is an open problem. When multiple AI agents work on related stories simultaneously (using git worktrees), coordination patterns for shared state, merge conflict resolution, and integration testing are not well-established. Claude Code's task system supports `blockedBy` dependencies, but cross-agent coordination patterns need further development.

**Long-term context management** across story sessions — how to efficiently transfer knowledge from completed stories to subsequent ones without bloating context — is an active area of research. The CLAUDE.md approach helps but does not fully solve the problem of accumulated project knowledge.

**Quality metrics for AI-generated code** are not standardized. AI Revert Percentage and Hallucination Fix Rate are proposed but not yet widely adopted. The relationship between story quality and AI implementation success rate has not been rigorously measured.

**Story formats for non-code AI tasks** (infrastructure-as-code, DevOps automation, data pipeline configuration) have less practitioner guidance than application development stories. The recommended template may need adaptation for these domains.

**FEATURES.md and AGENTS.md standards** are rapidly evolving. AGENTS.md has reached 60,000+ repos and Linux Foundation stewardship, but the specification continues to change. The JD-LLM Framework should monitor these standards and maintain compatibility as they mature.

The field is moving fast — what constitutes best practice in March 2026 may shift significantly as AI coding agents improve and new tooling emerges. The recommended approach is to adopt the structured template above, measure results rigorously, and iterate based on data.