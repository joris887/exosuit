---
name: brainstorm
version: 2.4.0
description: Use when the user has a complex idea that needs design exploration before story decomposition.
trigger: manual
depends-on: [ideate]
references: []
---
______________________________________________________________________

## name: brainstorm description: Use when the user has a complex idea that needs design exploration before story decomposition. argument-hint: <idea-or-topic> disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash

Brainstorming: **$ARGUMENTS**

## 1. Explore the Problem Space

Understand the idea deeply before proposing solutions:

- What problem does this solve? Who benefits?
- What are the constraints (technical, business, time)?
- What similar functionality already exists in the codebase?
- What are the non-negotiable requirements vs nice-to-haves?

Ask clarifying questions if the idea is vague. Do NOT proceed with assumptions.

## 2. Research the Codebase

Investigate relevant existing code:

- Existing patterns and conventions that a solution must follow
- Related features that this idea connects to
- Architecture constraints from `docs/architecture/ARCHITECTURE.md`
- Technology limitations or capabilities

## 3. Propose Alternative Approaches

Present 2-3 distinct approaches with tradeoffs:

```markdown
### Approach A: [Name]
**How:** [Brief description]
**Pros:** [Benefits]
**Cons:** [Drawbacks]
**Complexity:** [Low/Medium/High]
**Files affected:** [Estimated count and key paths]

### Approach B: [Name]
**How:** [Brief description]
**Pros:** [Benefits]
**Cons:** [Drawbacks]
**Complexity:** [Low/Medium/High]
**Files affected:** [Estimated count and key paths]
```

**Recommendation:** State which approach you recommend and why.

## 4. Identify Risks and Open Questions

- What could go wrong with the recommended approach?
- What unknowns remain? (Suggest spikes for unknowns)
- Are there security, performance, or scalability concerns?
- Does this require an ADR (Architecture Decision Record)?

## 5. Present Design for Approval

Summarize the recommended approach in a design brief:

```markdown
### Design: [Idea Title]

**Problem:** [One sentence]
**Approach:** [Recommended approach name]
**Key decisions:** [Bullet list]
**Risks:** [Bullet list]
**Estimated scope:** [Small: 1-2 stories / Medium: 3-5 / Large: 6+]
```

<HARD-GATE>
Do NOT invoke /ideate, write any stories, or begin implementation until the user has approved a design approach. The purpose of brainstorming is exploration, not execution.
</HARD-GATE>

## 6. Next Steps

After user approves the design:

- **For immediate implementation:** Invoke `/ideate` with the approved approach to decompose into stories
- **For complex designs:** Save the design to `docs/plans/` for reference during implementation
- **For unknowns:** Create spike stories to resolve open questions first

## Rules

- NEVER jump to a solution without exploring alternatives
- NEVER start implementation during brainstorming
- ALWAYS present at least 2 approaches with tradeoffs
- ALWAYS identify risks before recommending an approach
- Keep the design brief concise — save detail for story-level planning
