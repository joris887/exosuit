# Story Type Execution Details

Reference loaded by `/story-cycle` Phase 3. Execute based on identified story type.

## Feature Story (TDD)

Write tests without implementation knowledge when possible. This prevents the "testing the mock" anti-pattern.

**TDD ordering is enforced by a hard gate in Phase 3.** You MUST complete RED (write and run a failing test, show failure output) before starting GREEN (writing implementation). This is not advisory — the story-cycle SKILL.md contains a HARD-GATE that requires test files to be written and executed before source files are edited.

**RED:**

1. Write a focused failing test for one behavior
1. Use descriptive name: `test_[action]_[condition]_[expected]`
1. Include Given/When/Then structure
1. Verify test fails for the RIGHT reason

**GREEN:**
5. Write MINIMUM code to make the test pass
6. No over-engineering, no untested features
7. Verify test passes + full suite for regressions

**REFACTOR:**
8. Improve code quality while keeping tests green
9. Remove duplication, improve naming
10. Run tests after each change

Repeat RED-GREEN-REFACTOR for each behavior in the acceptance criteria.

## Bug Fix

1. **Web research the error pattern (before coding):** Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **QUICK** depth. Use the error message, stack trace, or reported behavior as the query. Sub-questions: (a) "What causes [error message] in [library/framework]?" (b) "Known fixes for [error pattern]". Output format: `evidence-check`. This often reveals the root cause faster than code archaeology. Skip only if the bug is clearly internal logic (e.g., wrong variable name).

**Reproduction test ordering is enforced by a hard gate in Phase 3.** You MUST write and run the reproduction test (must fail) before implementing the fix.

1. Write a test that reproduces the bug (must fail)
1. Verify it fails for the right reason (matches the reported behavior)
1. Implement the minimal fix (informed by web research findings if applicable)
1. Verify the reproduction test passes
1. Run full test suite for regressions

## Refactoring

1. Write characterization tests that capture current behavior (if not already covered)

**Characterization test ordering is enforced by a hard gate in Phase 3.** You MUST write and run characterization tests (must pass) before performing any refactoring.

1. Verify all characterization tests pass
1. Perform the refactoring in small steps
1. Run tests after each step — never break them
1. Verify final behavior matches original (characterization tests green)

## Spike/Research

1. Define the questions to answer (from story or user)
1. Time-box the exploration (ask user for budget if not defined)
1. **Deep web research (mandatory):** Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **DEEP** depth. Generate sub-questions from the spike's questions. Research current state of reference technologies, recent publications, competitor products, and relevant UX/architecture patterns. The research engine handles parallel subagent dispatch, source quality evaluation, reflection-based compression, and iterative deepening. Output format: `research-report`. Training data is insufficient — spikes require verified, current information with source URLs.
1. Explore, prototype, experiment — code may be thrown away
1. Document findings: what was learned, what was decided, what's recommended. All claims must cite sources with URLs. Save the research report to `docs/research/<topic-slug>.md`.
1. **Output as ADR when a decision was made:** If the spike resulted in a technology choice, architecture decision, or approach selection, create an ADR using `docs/adr/TEMPLATE.md` with `status: proposed`. Map each explored option to the Alternatives Considered section (chosen → ✅, rejected → ❌ with specific rationale and reconsider-when conditions). Fill `rejected-options` in YAML frontmatter for AI filtering. If no decision was made, output backlog stories for follow-up work instead.
1. **Backlog review (mandatory):** Before completing, review all stories that depend on or are informed by this spike's findings. For each: (a) check if acceptance criteria need updating based on research, (b) check if new stories are needed to cover gaps the research revealed, (c) check if any stories should be split, merged, or removed. Present proposed backlog changes to the user for approval.
1. No production code required

## Infrastructure

1. Plan the changes (scripts, config, CI)
1. Implement incrementally
1. Write smoke tests or verification scripts
1. Verify with the project's test command
1. Document any new commands or setup changes

## Testing

1. Design test strategy (what to cover, what patterns to use)
1. Generate test code following existing patterns in the codebase
1. Verify tests pass and provide meaningful coverage
1. Run full suite to ensure no conflicts

## Documentation

1. Gather source material (code, existing docs, architecture)
1. Generate documentation following existing format/style
1. Verify accuracy: links work, code references are correct
1. Keep concise — document what's needed, not everything possible
1. **Document quality check:** Dispatch a fresh sub-agent (Explore, forked) with ONLY the generated document — no conversation history. Ask it to identify gaps, ambiguities, and assumed context. Fix genuine issues before marking complete.

**If sub-agents are NOT available:** Perform the quality check manually — re-read the generated document from scratch, pretending you have no prior context. Identify gaps, ambiguities, and assumed context. Fix genuine issues before marking complete.

## Security

1. Define threat model or security requirements
1. Implement security measures
1. Run available security scanning tools
1. Write security-focused tests
1. Run `/security-audit` skill for review

## Performance

1. Establish baseline measurements (before optimization)
1. Implement optimizations
1. Measure after and compare to baseline
1. Write benchmark tests to prevent regression
1. Document before/after metrics

## Skill/Tooling

1. Design the skill/tool interface
1. Build following the skill template (`.claude/skills/SKILL_TEMPLATE.md`)
1. Test the skill manually
1. Document usage and examples
1. Update SKILLS_INVENTORY.md
