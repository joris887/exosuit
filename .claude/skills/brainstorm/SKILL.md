---
name: brainstorm
version: 2.7.0
description: Use when the user has a complex idea that needs design exploration before story decomposition.
trigger: manual
depends-on: [ideate]
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, WebSearch, WebFetch, Agent
argument-hint: "<idea-or-topic>"
---
______________________________________________________________________

## brainstorm

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"brainstorm\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

Brainstorming: **$ARGUMENTS**

## Plan Mode (Optional)

For complex or high-stakes brainstorms, consider using Plan Mode for Phases 1-4. This adds an extra layer of safety by preventing premature implementation during design exploration.

**When to use:** The idea is architecturally significant, affects multiple systems, or the user explicitly requests a careful exploration.

**How:** Enter Plan Mode before Phase 1. Remain in Plan Mode through Phase 4 (risk identification). Exit Plan Mode before Phase 5 (design presentation) so you can interact with the user for approval.

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

## 2.5. Research Alternatives (Optional — Recommended)

Before proposing alternatives, research them with web evidence. This step makes alternatives evidence-backed rather than relying solely on training data.

Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **STANDARD** depth:

- **Query:** Generated from the 2-3 potential approaches identified during problem exploration
- **Sub-questions** (one per approach):
  1. "Real-world implementations of [approach 1] for [problem domain]"
  2. "Tradeoffs and pitfalls of [approach 2] in production"
  3. "Libraries/tools commonly used for [approach 3] in [detected stack]"
- **Output format:** `decision-input` (compact, one per approach)

Research is dispatched in parallel — one subagent per approach.

Integrate findings into Phase 3 alternatives: each approach's pros/cons now include real-world evidence and citations where applicable.

**Skip when:** User says "no research" or "I know the approaches", or the brainstorm is about internal refactoring with no external technology choices.

## 3. Propose Alternative Approaches

Present 2-3 distinct approaches using AskUserQuestion with `markdown` previews for visual comparison.

For each approach, create an option with:
- **label:** Short approach name (e.g., "Event-Driven", "REST API", "Monolith-First")
- **description:** One-line tradeoff summary (e.g., "Flexible but adds message broker dependency")
- **markdown:** Rich preview containing:
  ```
  ## [Approach Name]

  **How:** [2-3 sentence description]

  **Architecture:**
  [ASCII diagram or file structure tree]

  **Pros:**
  - [benefit 1]
  - [benefit 2]

  **Cons:**
  - [tradeoff 1]
  - [tradeoff 2]

  **Complexity:** [Low/Medium/High] — [N files, N new deps]
  ```

State which approach you recommend and why. The user selects their preferred approach.

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

## 6. Persist Design Document

After user approves the design, save the exploration to `docs/brainstorms/<topic-slug>.md` with frontmatter:

```yaml
---
title: "<Idea Title>"
date: <YYYY-MM-DD>
status: decided  # explored | decided | abandoned
decision: "<Chosen approach name>"
---
```

Include the design brief (from Phase 5), the approaches explored (from Phase 3), and the risks identified (from Phase 4). This document is referenced by `/ideate` and `/story-cycle` when the idea becomes a story.

## 7. Next Steps

After user approves the design:

- **For immediate implementation:** Invoke `/ideate` with the approved approach to decompose into stories
- **For complex designs:** The design doc in `docs/brainstorms/` serves as reference during implementation
- **For unknowns:** Create spike stories to resolve open questions first

## Example

```
Input:  /brainstorm "real-time notifications"
Output: 3 approaches explored (WebSockets, SSE, polling)
        Recommended: SSE — simpler, sufficient for one-way notifications
        Risks: browser support for SSE reconnection, scaling beyond 1000 connections

Next Steps:
→ /ideate "real-time notifications using SSE" — decompose into stories
→ /handoff — if ending the session
```

## Rules

- NEVER jump to a solution without exploring alternatives
- NEVER start implementation during brainstorming
- ALWAYS present at least 2 approaches with tradeoffs
- ALWAYS identify risks before recommending an approach
- Keep the design brief concise — save detail for story-level planning
