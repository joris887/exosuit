______________________________________________________________________

## name: story-cycle description: Use when the user wants to implement a single story or deliver a backlog item. argument-hint: <story-description-or-id> disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Delivering story: **$ARGUMENTS**

## Process Flow (authoritative — prose below is supporting detail)

```
START → Phase 1: Plan Mode (research, identify type, write plan)
  → [User approved?]
    → NO: Revise plan → back to approval
    → YES: Phase 2: Context Transition (keep insights, discard bulk)
      → Phase 3: Execute by Story Type (TDD/reproduce/characterize/etc.)
        → Phase 3.5: Self-Review (completeness, quality, testing, discipline)
          → [Review passes?]
            → NO: Fix issues → back to Phase 3
            → YES: Phase 4: Wrap Up (tests, docs, commit, report)
              → DONE
```

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

Keep the plan concise — **under 50 lines**. Save complex plans to `docs/plans/` for persistence across compaction. Reference files by path rather than inlining content.

Write a plan covering:

- **Story type** and methodology to use
- **Files to modify/create** (specific paths)
- **Testing strategy** (what tests, where, what approach)
- **Skills to load** during execution
- **Acceptance criteria** (how to verify completion)
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

### File Context (accumulates across compactions)
<files-read>
[List all files read during planning — one path per line]
</files-read>
<files-modified>
[Update as files are modified during execution — one path per line]
</files-modified>

When context compacts, MERGE new file paths into these lists — never discard previous entries.
```

For complex stories, use `ultrathink` to reason through architectural decisions before writing the plan.

Present the plan for user approval.

<HARD-GATE>
Do NOT write any implementation code, edit source files, or take any implementation action until the plan has been presented and the user has explicitly approved it. "I already know what to do" is NOT approval. Wait for the user.
</HARD-GATE>

## Phase 2: Context Transition

After plan approval, selectively prune the context — keep discovery metadata, discard bulk content.

**KEEP (low token cost, high value):**
1. The approved plan (with Story-Cycle Context header and file tracking tags)
2. File paths discovered during research (as a list, not full file contents)
3. Edge cases or gotchas noted during exploration
4. Pattern examples found in existing code (brief snippets only, not full files)

**DISCARD (high token cost, low ongoing value):**
- Full file contents from exploration reads
- Dead-end investigation paths
- Irrelevant code discovered during broad searches
- Search results that didn't lead anywhere

**THEN RELOAD fresh:**
1. `docs/reference/CODING_STANDARDS.md` (coding standards)
2. Files identified in the plan as relevant (re-read for fresh content)
3. Skill-specific context (if skills were defined)

The goal: preserve the *insights* from Phase 1 without the *bulk*. A list of 20 file paths costs ~200 tokens; the contents of those 20 files costs ~20,000.

## Phase 3: Execute by Story Type

### Feature Story (TDD)

For Feature stories, write tests without implementation knowledge when possible. This prevents the "testing the mock" anti-pattern.

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

## Phase 3.5: Self-Review Before Wrap-Up

Before proceeding to Phase 4, complete this checklist honestly. Do NOT skip items.

### Completeness
- [ ] Every acceptance criterion has been implemented
- [ ] Every acceptance criterion has a corresponding test
- [ ] No "TODO" or "FIXME" left in new code (unless explicitly deferred)

### Quality
- [ ] New code follows patterns found in existing codebase
- [ ] No unnecessary features added beyond acceptance criteria (YAGNI)
- [ ] Error handling covers realistic failure modes

### Testing
- [ ] All tests pass — run the test command and show output (not from memory)
- [ ] Tests are meaningful — would fail if implementation was naive
- [ ] Edge cases from planning phase are covered

### Discipline
- [ ] Did not weaken or delete any existing tests
- [ ] Did not add dependencies without noting them
- [ ] Implementation matches the approved plan

### Spec Compliance (for stories with 4+ acceptance criteria)

For each acceptance criterion:
1. Re-read the criterion text from the plan
2. Find the code that implements it (cite file:line)
3. Find the test that verifies it (cite file:line)
4. Confirm they match — do NOT rely on memory, re-read the plan and the code

### Red Flags — Stop If You're Thinking:

| Rationalization | Why It's Wrong | Correct Action |
|----------------|----------------|----------------|
| "The tests probably pass, I'll commit" | "Probably" is not evidence | Run the test command, show output |
| "This is a small change, no need for TDD" | Small changes cause big regressions | Write the test first |
| "I already verified this earlier" | Earlier is not fresh evidence | Re-run verification now |
| "The user wants this done fast, skip review" | Fast now = rework later | Complete the self-review |
| "Close enough to the acceptance criteria" | Close is not done | Implement exactly what was specified |

If any checklist item fails, go back to Phase 3 and fix the issue before proceeding.

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

## Recovery

When a step fails during execution:

- **Test failure (new code):** Read the error, fix the implementation, re-run. Do not weaken the test.
- **Test failure (pre-existing):** Inform user. Do not mask it. Log to `docs/technical-debt.md` if out of scope.
- **Context exhaustion:** Save current progress to `docs/plans/`, commit work-in-progress, inform user to start a new session with `/continue`.
- **Git conflict:** Show conflict to user. Do NOT auto-resolve without approval.
- **Skill not found:** If a required skill (e.g., `/code-quality`) is not available, skip it and note in the completion report.

## Rules

- NEVER skip the plan phase — always enter plan mode first
- NEVER carry exploration context into execution — clear and reload
- NEVER merge to main or create a PR — that's sprint-end
- NEVER add features not in the acceptance criteria
- NEVER weaken or delete existing tests
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
- Follow testing strategy in `docs/reference/TESTING_STRATEGY.md`
- Follow architecture constraints in `docs/architecture/ARCHITECTURE.md`
