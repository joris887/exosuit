# 4. Architectural Ground Rules

## Research Prompt

```
I need deep research on architectural governance — how to define, document, and enforce non-negotiable architectural principles in software projects. The goal is to determine the best possible approach for a ground rules template that captures a project's architectural DNA in a way both humans and AI can enforce.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Ground rules are:
- Populated by /bootstrap through user conversation (step A3.5b)
- Checked by AI during /story-cycle planning (Phase 1e) and /sprint-end quality gates
- Tracked for compliance in progress.md
- Typically 3-7 principles that define what CANNOT be violated
The template must work for any architecture and stay under 100 lines.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Architectural Fitness Functions** — Neal Ford's "Building Evolutionary Architectures", ArchUnit, NetArchTest, dependency-cruiser. How to express rules as testable assertions. Which properties can be auto-verified vs require judgment?

2. **Governance Models** — How Google, Netflix, Spotify enforce architectural standards. RFC 2119 MUST/SHOULD/MAY. How specificity affects compliance.

3. **Ground Rule Categories That Matter** — Dependency direction, technology selection, data flow, API design, security, performance, operational rules. Which categories are universal vs project-specific?

4. **Documentation Format** — How to write rules precise enough to enforce but flexible enough to evolve. Exception handling. Compliance tracking. Writing rules an AI can check during code changes.

5. **Evolving Ground Rules** — When should rules change? ADR integration. Rule lifecycle. Preventing rule accumulation.

6. **AI-Specific Governance** — Expressing boundaries that prevent AI drift. Rules that prevent "helpful" violations. The right granularity for AI enforcement.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended rule format** — propose the specific format for individual rules (structure, fields, classification scheme) with justification
4. **Recommended categories** — which rule areas are essential, which are optional, with justification
5. **Recommended template structure** — the overall document organization
6. Examples of effective rules for common architectures
7. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on architectural ground rules best practices. The research findings are saved in docs/research/ground-rules.md (or I will paste them below).

Your task: Update the framework's GROUND_RULES.md template to be the best possible architectural governance format, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations: docs/reference/GROUND_RULES.md AND scaffold/docs/reference/GROUND_RULES.md
- Budget: ≤100 lines
- Must capture 3-7 principles that define a project's architectural DNA
- Must be checkable by AI during /story-cycle planning (Phase 1e) and /sprint-end quality gates
- Must work for any architecture (monolith, microservices, serverless, mobile)
- Bootstrap (step A3.5b) must be able to populate it from user conversation
- Must support compliance tracking in progress.md

**Instructions:**
1. Read the current GROUND_RULES.md at docs/reference/GROUND_RULES.md
2. Read the research findings thoroughly
3. Implement the rule format, categories, and template structure the research recommends — trust the research over your own defaults
4. Include suggested defaults for common architectures that bootstrap can offer
5. Update scaffold/docs/reference/GROUND_RULES.md to match
6. Verify bootstrap (A3.5b) prompts still work with the new format
7. Verify sprint-end ground rules check still works with the new format

**Outcome criteria (how to evaluate the result):**
- A developer reading this knows exactly what they cannot violate
- An AI reading this can verify compliance during code changes
- Rules are precise enough to enforce but flexible enough to evolve
- Bootstrap can generate sensible defaults for common architectures (REST API, React SPA, CLI tool, library)
- Under 100-line budget
```
