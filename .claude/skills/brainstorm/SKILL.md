---
name: brainstorm
version: 2.8.0
description: Use when the user has a complex idea that needs design exploration before story decomposition.
trigger: manual
depends-on: [ideate, brain-update]
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

**Product requirements context:** Read `docs/reference/PRD_SUMMARY.md` if it exists. Use Section 3 (success criteria) as evaluation criteria for approaches in Phase 3. Use Section 7 (scope boundaries) to ensure no approach violates stated non-goals or implementation boundaries. Use Section 6 (NFRs) as constraints — e.g., an approach that can't meet the performance or accessibility thresholds is disqualified.

**Persona context:** Read `docs/brain/personas.md` if it exists. Note each persona's goals, evaluation criteria, and failure scenarios — these inform approach scoring in Phase 3.

Ask clarifying questions if the idea is vague. Do NOT proceed with assumptions.

## 2. Research the Codebase

Investigate relevant existing code:

- Existing patterns and conventions that a solution must follow
- If `docs/brain/system-patterns.md` exists and is populated, load it. In Phase 3, score each approach's **Pattern Fit**: does it follow or diverge from established implementation patterns, error handling strategy, and testing conventions? Approaches that align are lower-risk. Approaches introducing new patterns must justify the divergence and note which sections of system-patterns.md would need updating.
- Related features that this idea connects to
- Architecture constraints from `docs/architecture/ARCHITECTURE.md`
- Ground rules from `docs/reference/GROUND_RULES.md` (if exists) — MUST rules are hard constraints on any proposed approach
- Technology limitations or capabilities

## 2.5. Check Existing Architecture Decisions

<IF condition="docs/adr/ contains accepted ADR files">
Before generating alternatives, scan `docs/adr/` YAML frontmatter for `status: accepted` records with tags relevant to this idea's domain. Treat accepted ADRs as constraints on the design space:
- **Exclude** any approach that matches a `rejected-options` value in an accepted ADR — note the ADR reference and why it was rejected
- **Respect** accepted decisions as fixed constraints — don't propose alternatives that contradict them
- **Check `Reconsider when`** conditions — only if circumstances have materially changed since the ADR was accepted, note this and present the reopened option alongside its history
- Present any relevant ADRs in Phase 3 as context: "Constrained by ADR-NNNN: [title]"
</IF>

## 2.6. Research Alternatives (Optional — Recommended)

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

## 3. Propose Alternative Approaches (ADR-Informed)

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
  **PRD Fit:** [How well this approach meets PRD success criteria and NFRs]
  **Pattern Fit:** [Aligns with / Extends / Diverges from established patterns]
  ```

**If PRD was loaded:** Score each approach against PRD success criteria (Section 3) and NFRs (Section 6). An approach that can't meet a stated NFR (e.g., performance target, accessibility requirement) should be flagged as non-viable.

**If system-patterns were loaded:** Add a **Pattern Fit** line to each approach. Score: **Aligns** (follows all documented patterns), **Extends** (adds a new pattern consistent with existing ones), or **Diverges** (contradicts a documented pattern — must justify). Approaches that Diverge carry higher implementation risk and require updating system-patterns.md.

**If personas were loaded:** Add a **Persona Fit** line to each approach's preview, evaluating how well the approach serves each persona:
- Apply each persona's **EVALUATES BY** questions to the approach
- Flag approaches that would trigger a persona's **FRUSTRATIONS** (e.g., an approach requiring complex configuration when the primary persona is non-technical)
- Note when approaches differ by persona fit: "Option A serves P1 better (speed); Option B serves P2 better (simplicity)"
- The primary persona (★) has tiebreaker weight when approaches trade off between personas

State which approach you recommend and why. The user selects their preferred approach.

## 4. Identify Risks and Open Questions

- What could go wrong with the recommended approach?
- What unknowns remain? (Suggest spikes for unknowns)
- Are there security, performance, or scalability concerns?
- Does this require an ADR (Architecture Decision Record)?
- Do any proposed approaches violate ground rules? A MUST violation disqualifies an approach; a SHOULD violation is a risk to flag.

### STRIDE-Light Threat Analysis (for designs with trust boundaries)

If the design involves API endpoints, authentication flows, data storage, service-to-service communication, or user input processing, run a quick STRIDE pass on each component in the data flow:

| Threat | Question | Example |
|--------|----------|---------|
| **S**poofing | Can an attacker impersonate a legitimate user or service? | Missing auth tokens, weak session management |
| **T**ampering | Can data be modified in transit or at rest? | Unsigned API payloads, unvalidated webhooks |
| **R**epudiation | Can an action be denied without evidence? | Missing audit logs for sensitive operations |
| **I**nformation Disclosure | Can sensitive data leak? | Verbose errors, PII in logs, secrets in config |
| **D**enial of Service | Can the system be overwhelmed? | Missing rate limiting, unbounded queries |
| **E**levation of Privilege | Can a user gain unauthorized access? | IDOR, missing role checks, privilege escalation |

This is not full threat modeling — it's a 2-minute structured checklist. Include findings in the "Risks" section of the design brief. Any STRIDE finding should become a security acceptance criterion when the design is decomposed into stories by `/ideate`.

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

**If the decision is architecturally significant** (from Phase 4 assessment): also create an ADR using `docs/adr/TEMPLATE.md`. The brainstorm document captures the exploration; the ADR captures the decision in machine-parseable format with rejected alternatives and compliance checks. Map the brainstorm's approaches to the ADR's Alternatives Considered section (chosen → ✅, rejected → ❌ with rationale and reconsider-when conditions).

**Update the repo brain:** When the status is `decided`, invoke `/brain-update brainstorm decided <topic-slug>`. This records the design decision (chosen approach, rejected alternatives with reasons) in `docs/brain/system-patterns.md` and appends a log entry. Skip if `docs/brain/` doesn't exist.

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
