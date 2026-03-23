# 3. Testing Strategy

## Research Prompt

```
I need deep research on testing strategy documentation for AI-assisted software development. The goal is to determine the best possible approach for a testing strategy template that works for ANY project and specifically addresses the unique challenges of AI-generated code quality.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Testing is a core framework principle: TDD is mandatory for feature, bug fix, and refactoring stories. The framework has:
- A /story-cycle skill that enforces test-first workflow (RED → GREEN → REFACTOR)
- A /test-validator quality agent that analyzes test quality
- Hook enforcement that blocks completion claims without test evidence
- Quality gates that check assertion density and test coverage
The template must work for any language and be actionable, not philosophical.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **TDD in AI-Assisted Development** — DORA 2024/2025 findings on TDD + AI. Research on AI-generated test quality. The "who writes the test" problem. Case studies from AI-augmented teams. CodeScene/CodeRabbit research on AI code quality.

2. **Test Quality Metrics That Matter** — Mutation testing, assertion density, coverage types (branch vs line vs path), test effectiveness metrics, property-based testing, characterization testing. Which metrics actually predict defect detection?

3. **Testing Pyramid & Architecture-Aware Testing** — Modern testing pyramid vs testing trophy. Contract testing. Component testing granularity. When to test config/infra.

4. **AI-Specific Testing Anti-Patterns** — Tautological tests, over-mocking, happy-path-only, "test the mock" pattern, hallucinated test APIs, test count inflation without quality. How AI weakens assertions over time.

5. **Test Organization & Naming** — BDD (Given/When/Then) vs alternatives. Co-located vs centralized test files. Naming conventions. Fixture/factory patterns.

6. **Coverage Strategy** — Optimal targets by module type. Coverage ratcheting. Diminishing returns. Risk-based testing.

7. **Continuous Testing** — What to run when (commit → PR → nightly → release). Flaky test management. Parallelization.

Prioritize findings backed by data (studies, metrics, large-scale analyses) over opinion pieces.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended testing strategy structure** — propose the specific workflow, quality criteria, coverage approach, and anti-pattern defenses you believe are optimal, with justification
4. **Recommended metrics and thresholds** — specific numbers with evidence
5. **Anti-pattern catalog** — ranked by frequency and severity in AI-generated code
6. Tool recommendations per language
7. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on testing strategy best practices. The research findings are saved in docs/research/testing-strategy.md (or I will paste them below).

Your task: Update the framework's TESTING_STRATEGY.md template to be the definitive testing strategy for AI-assisted development, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations: docs/reference/TESTING_STRATEGY.md AND scaffold/docs/reference/TESTING_STRATEGY.md
- Budget: ≤250 lines
- Must work for ANY project and language
- Must address AI-specific testing challenges (this is the framework's core value proposition)
- Must support the /story-cycle TDD flow and /test-validator quality analysis
- Must be actionable — specific techniques and criteria, not philosophy

**Instructions:**
1. Read the current TESTING_STRATEGY.md at docs/reference/TESTING_STRATEGY.md
2. Read the research findings thoroughly
3. Implement the testing strategy structure, metrics, thresholds, and anti-pattern defenses the research recommends — trust the research over your own defaults
4. Update scaffold/docs/reference/TESTING_STRATEGY.md to match
5. If research findings suggest updates to .claude/rules/testing.md, note them but verify before changing
6. Verify total stays within 250-line budget

**Outcome criteria (how to evaluate the result):**
- An AI following this strategy produces tests that catch real bugs, not just inflate coverage
- Every known AI testing anti-pattern has a specific, named defense
- Quality criteria are concrete (numbers, thresholds) not vague ("good coverage")
- The document works for a Python API, a React app, a Go CLI, and a Rust library equally
- /story-cycle and /test-validator can reference specific sections for guidance
- Under 250-line budget
```
