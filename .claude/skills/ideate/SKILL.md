---
name: ideate
version: 2.10.0
description: Use when the user has an idea or requirement to decompose into backlog stories.
trigger: manual
depends-on: []
references: [references/story-template.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent
argument-hint: "<idea-or-requirement>"
---
______________________________________________________________________

## ideate

Transforming idea into backlog stories: **$ARGUMENTS**

## Phase 0: Validate Prerequisites

Before starting, verify:
- `docs/reference/backlog/` directory exists (create if missing)
- `docs/reference/BACKLOG_INDEX.md` is readable
- No conflicting ideation in progress (check for uncommitted backlog changes)

If prerequisites fail, inform the user and stop — don't consume context on doomed work.

## 1. Gather Input

**Check for prior brainstorm artifacts:** Search `docs/brainstorms/` for existing design documents matching the topic. If a brainstorm doc exists with `status: decided`, load it as context — the design exploration and key decisions have already been made.

Understand the idea or requirement from `$ARGUMENTS` and any additional context the user provides.

Ask clarifying questions if the idea is too vague:

- What problem does this solve?
- Who benefits from this?
- What does "done" look like?
- Are there constraints or preferences?

## 2. Research Context

Explore the codebase to understand:

- Related existing code and patterns
- Architectural constraints (read `docs/architecture/ARCHITECTURE.md`)
- What already exists vs what needs to be built
- Testing patterns in the relevant area
- Dependencies on existing code

## 2.5. Feasibility Research (Conditional)

If the idea involves external dependencies, unfamiliar technology, or integration with third-party services, perform a quick feasibility check before decomposition.

Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **QUICK** depth:

- **Query:** Generated from the idea's key technical requirements
- **Sub-questions** (1-2, focused on feasibility):
  1. "Does [key library/API] support [required capability]?"
  2. "Are there breaking changes or deprecations in [dependency] for [use case]?"
- **Output format:** `evidence-check` (yes/no/maybe with evidence)

**If feasibility is uncertain:** Add a Spike/Research story to the decomposition to resolve the uncertainty before implementation stories begin.

**Skip when:** The idea uses only well-understood, established technologies already present in the codebase, or when a prior brainstorm/research doc already covers feasibility.

## 3. Decompose into Stories

Break the idea into properly typed stories. For each story, determine the best type:

| Story Type         | Template                                                                      | Output                        |
| ------------------ | ----------------------------------------------------------------------------- | ----------------------------- |
| **Feature**        | "As a \[user\], I want \[capability\], so that \[benefit\]."                  | Working code + tests          |
| **Bug Fix**        | "Fix: \[defect description\]. Expected: \[behavior\]. Actual: \[behavior\]."  | Fix + regression test         |
| **Refactoring**    | "Refactor \[component\] to \[improvement\] without changing behavior."        | Restructured code             |
| **Spike/Research** | "Investigate \[question\]. Time-box: \[hours\]. Decision criteria: \[list\]." | Decision document or ADR      |
| **Infrastructure** | "Set up \[tooling/config\] to enable \[capability\]."                         | Scripts/config + verification |
| **Testing**        | "Add \[test type\] coverage for \[component/feature\]."                       | Test code + coverage          |
| **Documentation**  | "Document \[topic\] for \[audience\]."                                        | Updated docs                  |
| **Security**       | "Harden \[component\] against \[threat\]. Verify with \[method\]."            | Hardened code + audit         |
| **Performance**    | "Optimize \[operation\] to meet \[target\]. Baseline: \[current\]."           | Optimized code + benchmarks   |
| **Skill/Tooling**  | "Create \[skill/tool\] to automate \[workflow\]."                             | New skill + docs              |

### Story Sizing Constraint

**Each story must fit within a single Claude Code context window.** This means:

- 1-3 hours of focused work maximum
- Touches no more than 5-8 files
- Has a clear, atomic deliverable
- Can be fully tested within the story

If a story feels too large, split it further. Prefer many small stories over few large ones.

### Story Structure

Follow the story template in `${CLAUDE_SKILL_DIR}/references/story-template.md`. For each story, define:

```markdown
### <Story-ID>: <Brief user-facing title — NO technical terms> [<Type>]

**As a** [user role], **I want** [capability], **so that** [value].

**Acceptance Criteria:**
1. **Given** [state], **When** [action], **Then** [outcome]
2. **Given** [state], **When** [action], **Then** [outcome]

**Independent Test:** [How to verify this story works without other stories]

**Priority:** P1/P2/P3
**Why this priority:** [Value justification]

**Skills:** <skills to load in story-cycle, e.g., `/code-quality`, `/test-validator`>

**Testing Approach:** <TDD | Characterization | Smoke | Benchmark | Manual review>

**Verification:** <Command to prove it works>

**File Hints:** <Key files to read/modify>

**Non-Goals:** <What is explicitly out of scope>

**Depends On:** <Other story IDs>
```

## 4. Identify Missing Skills

For each story, check if the required skills exist:

- Review `.claude/skills/SKILLS_INVENTORY.md`
- If a story needs a skill that doesn't exist, add a **Skill/Tooling** story to create it
- Skill creation stories should come before stories that depend on them

## 5. Order for Testability

Organize stories in a logical order that enables incremental testing:

1. **Testing infrastructure first** — E2E test skeletons, fixtures, mocks
1. **Foundation stories** — core functionality that other stories depend on
1. **Feature stories** — build on the foundation, enable E2E tests incrementally
1. **Quality stories** — refactoring, performance, security hardening
1. **Documentation stories** — document what was built

**Key principle:** Each story should be independently verifiable. Tests from earlier stories should keep passing as later stories are delivered.

### E2E Test Strategy

If the idea involves multiple stories:

1. Create a testing story first that sets up E2E test skeleton (disabled tests)
1. As feature stories are delivered, enable corresponding E2E tests
1. This ensures integration is tested continuously, not just at the end

## 6. Output

Present the decomposed stories to the user:

```markdown
### Backlog: <Idea Title>

**Stories:** [count]
**Estimated scope:** [small/medium/large]

#### Story Order (dependency-resolved):
1. [Story-ID]: [Title] [Type] — [one-line summary]
2. [Story-ID]: [Title] [Type] — [one-line summary]
...

#### Detailed Stories:
[Full story definitions as structured above]

#### Dependency Graph:
[Simple ASCII or description of dependencies]
```

### Document Quality Check

Before presenting for approval, dispatch a fresh sub-agent to test the story decomposition from a reader's perspective:

- **Agent type:** Explore (read-only, forked context)
- **Input:** ONLY the story decomposition output — no conversation history
- **Instructions:** "You are a developer who will implement these stories. For each story: (1) Is the description clear enough to start work? (2) Are acceptance criteria testable and unambiguous? (3) Are file hints specific enough? (4) Are non-goals clear? Flag any story that you'd need to ask questions about before starting."

Review findings. Fix genuine gaps in the stories before presenting to user.

Ask user for approval before writing to backlog files.

<HARD-GATE>
Do NOT write any stories to backlog files, create epic files, or update BACKLOG_INDEX.md until the user has explicitly approved the decomposition. Present the stories, wait for approval.
</HARD-GATE>

## 7. Write to Backlog

After user approval:

- Add stories to the appropriate epic file in `docs/reference/backlog/`
- Or create a new epic file if this is a new epic
- Update `docs/reference/BACKLOG_INDEX.md` with new story counts
- Update CLAUDE.md if the current focus changes

## Example

```
Input:  /ideate "user authentication with email/password"
Output: 5 stories decomposed:
        S01: Testing infrastructure (fixtures, test helpers) [Testing]
        S02: User model + migration [Feature]
        S03: Registration endpoint with validation [Feature]
        S04: Login endpoint with JWT tokens [Feature]
        S05: Auth middleware for protected routes [Feature]
        Dependency graph: S01 → S02 → S03/S04 → S05

Next Steps:
→ /sprint-start — create a sprint branch to start implementing
→ /story-cycle "S01: Testing infrastructure" — deliver the first story
```

## Rules

- Each story must be scoped for 1-3 hours of focused work (single context window)
- Each story should touch no more than 5-8 files
- Acceptance criteria must be machine-verifiable where possible
- Non-goals must be explicit to prevent scope creep
- Skills-to-load must be defined for every story
- Spike stories must have a time-box and decision criteria
- Testing stories come before feature stories in the order
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
- Follow testing strategy in `docs/reference/TESTING_STRATEGY.md`
- Follow architecture constraints in `docs/architecture/ARCHITECTURE.md`
