______________________________________________________________________

## name: ideate description: Use when the user has an idea or requirement to decompose into backlog stories. argument-hint: <idea-or-requirement> disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Transforming idea into backlog stories: **$ARGUMENTS**

## 1. Gather Input

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

For each story, define:

```markdown
### <Story-ID>: <Title> [<Type>]

**Description:** <What and why>

**Acceptance Criteria:**
- [ ] <Verifiable criterion 1>
- [ ] <Verifiable criterion 2>
- [ ] <Verifiable criterion 3>

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
