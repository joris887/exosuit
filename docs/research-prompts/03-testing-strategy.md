# 3. Testing Strategy

## Research Prompt

```
I need comprehensive deep research on testing strategy documentation for AI-assisted software development. The goal is to create the ultimate testing strategy template that works for ANY project and specifically addresses the unique challenges of AI-generated code quality.

Research these specific areas:

1. **TDD in AI-Assisted Development**
   - DORA 2024/2025 findings on TDD + AI — what data exists on effectiveness?
   - Research papers or engineering blogs on AI-generated test quality
   - The "who writes the test" problem — human-owned RED phase vs AI-assisted
   - How do leading AI-augmented teams actually practice TDD? (case studies)
   - CodeScene, CodeRabbit, or similar tool research on AI code quality metrics

2. **Test Quality Metrics That Matter**
   - Mutation testing — tools, adoption rates, how to make it practical
   - Assertion density as a quality signal — research on optimal ratios
   - Branch coverage vs line coverage vs path coverage — which actually predicts defects?
   - Test effectiveness metrics — how to measure if tests catch real bugs
   - Property-based testing — when it adds value vs. example-based testing
   - Characterization testing for legacy code — approaches and tools

3. **Testing Pyramid & Architecture-Aware Testing**
   - The modern testing pyramid (unit → integration → E2E) — is it still relevant?
   - Testing trophy (Kent C. Dodds) vs pyramid — research on which produces better outcomes
   - Contract testing for microservices — Pact, Spring Cloud Contract, Protovalidate
   - Component testing — what's the right granularity?
   - Testing infrastructure code — Terratest, Testcontainers, when to test config

4. **AI-Specific Testing Anti-Patterns**
   - Research on common defects in AI-generated tests (tautological, over-mocking, happy-path-only)
   - How AI weakens assertion quality over time — documented patterns
   - The "test the mock" pattern — detection and prevention
   - Hallucinated test APIs — frequency and prevention strategies
   - Test count inflation without quality — how to detect

5. **Test Organization & Naming**
   - BDD (Given/When/Then) — research on readability and maintainability impact
   - Test file organization patterns (co-located vs centralized) — which scales better?
   - Test naming conventions that communicate intent — research on readability
   - Fixture and factory patterns — what reduces test maintenance?

6. **Coverage Strategy**
   - Optimal coverage targets by module type (critical path vs. utility vs. config)
   - Coverage ratcheting — tools and approaches for never-decrease policies
   - When 100% coverage is harmful — diminishing returns research
   - Risk-based testing — how to focus testing effort on what matters

7. **Continuous Testing**
   - Test-in-CI strategies — what to run when (commit → PR → nightly → release)
   - Flaky test management — detection, quarantine, root-cause approaches
   - Test parallelization — strategies for fast feedback loops
   - Visual regression testing — when and how to implement

For each finding, include source URLs, data quality assessment, and practical applicability. Prioritize findings backed by data (studies, metrics, large-scale analyses) over opinion pieces.

Output a structured research report with: key findings, recommended testing strategy structure, anti-pattern catalog, and tool recommendations per language.
```

## Implementation Prompt

```
I have completed deep research on testing strategy best practices. The research findings are saved in docs/research/testing-strategy.md (or I will paste them below).

Your task: Update the framework's TESTING_STRATEGY.md template to be the definitive testing strategy for AI-assisted development.

**Context:** This template lives at docs/reference/TESTING_STRATEGY.md (and scaffold/docs/reference/TESTING_STRATEGY.md). It's the authoritative reference for ALL testing practices. It must:
- Work for ANY project and language
- Address AI-specific testing challenges (the core problem the framework solves)
- Be actionable — not just philosophy, but specific techniques and criteria
- Stay under 250 lines (the framework's documentation rule budget)
- Support both the /story-cycle TDD flow and /test-validator quality analysis
- Include guard rails that prevent AI from degrading test quality

**Instructions:**
1. Read the current TESTING_STRATEGY.md at docs/reference/TESTING_STRATEGY.md
2. Read the research findings
3. Update the template incorporating proven practices:
   - TDD workflow section (strengthened with research data)
   - Test quality criteria (mutation testing, assertion density — with concrete thresholds)
   - Testing by story type (feature, bug fix, refactoring, etc.)
   - AI-specific anti-patterns (expanded with research findings)
   - Coverage strategy (risk-based, ratcheting, per-module targets)
   - Coverage tool reference table (verify per-language accuracy)
   - Guard rails section (automated protections — with research-backed justifications)
   - Contract testing section (for multi-component projects)
   - Test organization conventions
4. Update scaffold version to match
5. If any rules (.claude/rules/testing.md) should be updated based on findings, do so
6. Verify total stays within 250-line budget

Make this the testing document that prevents every known AI testing anti-pattern while enabling fast, high-quality test-driven development.
```
