______________________________________________________________________

## name: story-cycle description: Deliver a single story using the right methodology for its type. Starts in plan mode, clears context after plan approval, then executes. argument-hint: <story-description-or-id> disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Delivering story: **$ARGUMENTS**

## Phase 1: Story Analysis (Plan Mode)

Enter plan mode to research and design the approach.

### 1a. Identify Story Type

Determine the story type from the description, backlog entry, or user input:

| Type               | Indicators                                         | Approach                                   |
| ------------------ | -------------------------------------------------- | ------------------------------------------ |
| **Feature**        | New user-facing capability, "As a user..."         | TDD: RED-GREEN-REFACTOR                    |
| **Bug Fix**        | Defect, "fix", error report, reproduction steps    | Reproduce → Test → Fix → Verify            |
| **Refactoring**    | "Refactor", "restructure", no behavior change      | Characterization tests → Refactor → Verify |
| **Spike/Research** | "Investigate", "evaluate", "prototype", time-boxed | Explore → Document → Decide                |
| **Infrastructure** | CI/CD, tooling, build, config, environment         | Plan → Implement → Smoke Test              |
| **Testing**        | "Add tests", "coverage", "E2E tests"               | Design strategy → Generate → Validate      |
| **Documentation**  | "Document", "write docs", "update README"          | Gather → Generate → Review                 |
| **Security**       | "Harden", "audit", "vulnerability", "encrypt"      | Threat model → Implement → Audit           |
| **Performance**    | "Optimize", "benchmark", "speed up", "latency"     | Baseline → Optimize → Benchmark            |
| **Skill/Tooling**  | "Create skill", "add tool", "developer experience" | Design → Build → Document                  |

If unclear, ask the user to clarify the story type.

### 1b. Research Codebase

- Explore relevant files, patterns, and existing code
- Identify files to modify and files to create
- Understand existing tests and patterns in the area

### 1c. Define Required Skills

Determine which skills benefit this story. If the story metadata already defines skills, use those. Otherwise select from:

| Skill               | Load When                                             |
| ------------------- | ----------------------------------------------------- |
| `/code-quality`     | Feature, refactoring, infrastructure stories          |
| `/test-validator`   | Feature, bug fix, testing stories                     |
| `/security-audit`   | Security stories, code touching auth/credentials/data |

### 1d. Write the Plan

Write a plan covering:

- **Story type** and methodology to use
- **Files to modify/create** (specific paths)
- **Testing strategy** (what tests, where, what approach)
- **Skills to load** during execution
- **Acceptance criteria** (how to verify completion)
- **Documentation updates** needed (if any)
- **Non-goals** — what is explicitly out of scope

**CRITICAL — Story-Cycle Context Preservation:**

After plan approval, context resets and only the plan survives. The plan MUST start with a "Story-Cycle Context" section so Claude Code knows what workflow it's in and what steps remain. Use this exact format at the TOP of the plan:

```markdown
## Story-Cycle Context

This plan is part of a `/story-cycle` execution. After implementing the plan below, complete these remaining story-cycle steps:

1. **Run tests:** Use the project's test command (from CLAUDE.md Commands section)
2. **Update documentation** if the story's AC requires it
3. **Commit:** Stage relevant files and commit with conventional format: `<type>(<scope>): <description>`
4. **Do NOT merge or create PR** — that's `/sprint-end`'s job
5. **Print completion report** with: story description, type, approach, files modified, test count, and commit hash
```

Present the plan for user approval.

## Phase 2: Context Reset

After plan approval, clear the context and reload only:

1. The approved plan
1. `docs/reference/CODING_STANDARDS.md` (coding standards)
1. Files identified in the plan as relevant
1. Skill-specific context (if skills were defined)

**IMPORTANT:** Do NOT carry over exploration context from Phase 1. Start fresh with only what's needed for execution.

## Phase 3: Execute by Story Type

### Feature Story (TDD)

**RED:**

1. Write a focused failing test for one behavior
1. Use descriptive name: `test_[action]_[condition]_[expected]`
1. Include Given/When/Then structure
1. Verify test fails for the RIGHT reason

**GREEN:**
5\. Write MINIMUM code to make the test pass
6\. No over-engineering, no untested features
7\. Verify test passes + full suite for regressions

**REFACTOR:**
8\. Improve code quality while keeping tests green
9\. Remove duplication, improve naming
10\. Run tests after each change

Repeat RED-GREEN-REFACTOR for each behavior in the acceptance criteria.

### Bug Fix

1. Write a test that reproduces the bug (must fail)
1. Verify it fails for the right reason (matches the reported behavior)
1. Implement the minimal fix
1. Verify the reproduction test passes
1. Run full test suite for regressions

### Refactoring

1. Write characterization tests that capture current behavior (if not already covered)
1. Verify all characterization tests pass
1. Perform the refactoring in small steps
1. Run tests after each step — never break them
1. Verify final behavior matches original (characterization tests green)

### Spike/Research

1. Define the questions to answer (from story or user)
1. Time-box the exploration (ask user for budget if not defined)
1. Explore, prototype, experiment — code may be thrown away
1. Document findings: what was learned, what was decided, what's recommended
1. Output: decision document, ADR, or backlog stories for follow-up work
1. No production code required

### Infrastructure

1. Plan the changes (scripts, config, CI)
1. Implement incrementally
1. Write smoke tests or verification scripts
1. Verify with the project's test command
1. Document any new commands or setup changes

### Testing

1. Design test strategy (what to cover, what patterns to use)
1. Generate test code following existing patterns in the codebase
1. Verify tests pass and provide meaningful coverage
1. Run full suite to ensure no conflicts

### Documentation

1. Gather source material (code, existing docs, architecture)
1. Generate documentation following existing format/style
1. Verify accuracy: links work, code references are correct
1. Keep concise — document what's needed, not everything possible

### Security

1. Define threat model or security requirements
1. Implement security measures
1. Run available security scanning tools
1. Write security-focused tests
1. Run `/security-audit` skill for review

### Performance

1. Establish baseline measurements (before optimization)
1. Implement optimizations
1. Measure after and compare to baseline
1. Write benchmark tests to prevent regression
1. Document before/after metrics

### Skill/Tooling

1. Design the skill/tool interface
1. Build following the skill template (`.claude/skills/SKILL_TEMPLATE.md`)
1. Test the skill manually
1. Document usage and examples
1. Update SKILLS_INVENTORY.md

## Phase 4: Wrap Up

After execution is complete:

1. **Run tests:** Use the project's test command (from CLAUDE.md Commands section)
1. **Update documentation** if the story's AC requires it (but only what's relevant)
1. **Commit:** Stage relevant files and commit with conventional format:
   ```
   <type>(<scope>): <description>
   ```
1. **Do NOT merge or create PR** — that's `/sprint-end`'s job

### Completion Report

```markdown
### Story Complete

**Story:** [description]
**Type:** [story type]
**Approach:** [methodology used]
**Files modified:** [list]
**Tests:** [count] passing, [new tests added]
**Commit:** [hash and message]

**Ready for next story or sprint-end.**
```

## Rules

- NEVER skip the plan phase — always enter plan mode first
- NEVER carry exploration context into execution — clear and reload
- NEVER merge to main or create a PR — that's sprint-end
- NEVER add features not in the acceptance criteria
- NEVER weaken or delete existing tests
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
- Follow testing strategy in `docs/reference/TESTING_STRATEGY.md`
- Follow architecture constraints in `docs/architecture/ARCHITECTURE.md`
