# 4. Architectural Ground Rules

## Research Prompt

```
I need comprehensive deep research on architectural governance — how to define, document, and enforce non-negotiable architectural principles in software projects. The goal is to create the best possible ground rules template that captures a project's architectural DNA in a way both humans and AI can enforce.

Research these specific areas:

1. **Architectural Fitness Functions**
   - Neal Ford / "Building Evolutionary Architectures" — fitness function concept and catalog
   - ArchUnit (Java), NetArchTest (.NET), dependency-cruiser (JS) — automated architecture testing
   - How to express architectural rules as testable assertions
   - Which architectural properties can be automatically verified vs require human judgment?
   - Real-world examples of fitness functions from major companies

2. **Governance Models**
   - How Google enforces architectural standards across thousands of repos
   - Netflix's architecture governance (freedom and responsibility)
   - Spotify's autonomous squads — how they maintain coherence without top-down rules
   - ThoughtWorks Technology Radar approach to technology governance
   - MUST vs SHOULD vs MAY (RFC 2119) — how specificity affects compliance

3. **Ground Rule Categories That Matter**
   - Dependency direction rules (layers, hexagonal, clean architecture)
   - Technology selection rules (approved libraries, no-go list, evaluation criteria)
   - Data flow rules (where data can live, how it moves between boundaries)
   - API design rules (versioning, backwards compatibility, contract policies)
   - Security rules (authentication patterns, data classification, encryption policies)
   - Performance rules (latency budgets, resource limits, scaling policies)
   - Operational rules (logging standards, monitoring requirements, deployment constraints)

4. **Documentation Format for Architectural Rules**
   - How to write rules that are precise enough to enforce but flexible enough to evolve
   - MUST/SHOULD classification — how to balance rigidity with pragmatism
   - Exception handling — how to document approved exceptions to rules
   - Compliance tracking — how to measure and report rule adherence over time
   - How to write rules that an AI can check during code planning and review

5. **Evolving Ground Rules**
   - When should rules change? What signals indicate a rule is outdated?
   - ADR integration — linking ground rules to architectural decisions
   - Rule lifecycle: proposal → discussion → adoption → enforcement → retirement
   - How to prevent rule accumulation (too many rules = no rules)

6. **AI-Specific Governance**
   - How to express boundaries that prevent AI architectural drift
   - Rules that prevent AI from "helpful" violations (adding convenience that breaks architecture)
   - The right granularity — rules specific enough for AI to follow, general enough to be useful
   - How ground rules should interact with confidence gates and quality agents

For each finding, include sources, real-world examples, and assessment of whether it applies to solo developers, small teams, or enterprise scale.

Output a structured research report with: recommended ground rules categories, template structure, enforcement approaches, and examples of effective rules.
```

## Implementation Prompt

```
I have completed deep research on architectural ground rules best practices. The research findings are saved in docs/research/ground-rules.md (or I will paste them below).

Your task: Update the framework's GROUND_RULES.md template to be the best possible architectural governance format.

**Context:** This template lives at docs/reference/GROUND_RULES.md (and scaffold/docs/reference/GROUND_RULES.md). It's populated by /bootstrap (step A3.5b) through user conversation. It must:
- Work for ANY project architecture (monolith, microservices, serverless, mobile)
- Capture 3-7 principles that define the project's architectural DNA
- Use MUST/SHOULD classification for enforcement levels
- Be checkable by AI during /story-cycle planning (Phase 1e) and /sprint-end quality gates
- Support compliance tracking in progress.md
- Stay under 100 lines (the framework's documentation rule budget)
- Include suggested rules for common architectures when user has no preference

**Instructions:**
1. Read the current GROUND_RULES.md at docs/reference/GROUND_RULES.md
2. Read the research findings
3. Redesign the template:
   - Categories section (suggested rule areas: dependency, technology, data, API, security, performance, operational)
   - Rule format (MUST/SHOULD + rationale + verification method + exception process)
   - Suggested defaults section (bootstrap can offer these based on detected architecture)
   - Compliance section format (for tracking in progress.md)
   - Evolution section (when to update rules, linked to ADRs)
4. Include examples of effective rules for common architectures (REST API, React SPA, CLI tool, library)
5. Update scaffold version to match
6. Update bootstrap (A3.5b) if the rule format changed — check if the prompts still work
7. Update sprint-end ground rules check if the format changed

Make this the document that captures a project's architectural non-negotiables in a way that both human reviewers and AI assistants enforce consistently.
```
