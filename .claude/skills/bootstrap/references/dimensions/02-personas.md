# Dimension 2: User Personas & Impact

## Introduction

"Now let's figure out who will actually use this. Understanding your users shapes every decision that follows."

> **Note:** This dimension captures **raw user notes** during early discovery (Phase 2 core identity / dimension sweep). The full lean persona cards with all 6 fields are generated later in **Phase 3D: Persona Synthesis**, after deep elicitation provides enough context for behavioral detail. See `/discover` SKILL.md Phase 3D.

## When This Dimension Is OPEN

Ask:

1. **Primary user:** "Describe your typical user in one sentence. What's their job or situation?"
2. **Frustration:** "What's the single biggest frustration they have with how things work today?"
3. **Technical comfort:** "How comfortable are they with technology?" Offer examples:
   - "Like my grandmother — needs everything explained"
   - "Comfortable with apps — uses them daily but doesn't build them"
   - "Technical — writes code or works in tech"

## Early Persona Notes

From the answers, record raw user notes for Phase 3D synthesis:

```markdown
**[Name/Role]**
- **Goal:** [What they want to accomplish]
- **Frustration:** [Their biggest pain point]
- **Tech comfort:** [Level with brief implication]
- **Key need:** [The one thing that would make them adopt this]
```

Use realistic names and roles. Mark one as the **likely primary** — the person the MVP is built for. These notes are INPUT to Phase 3D, which generates the full persona cards after feature maps and user journeys are defined.

## When User Says "I Don't Know My Users"

Generate archetypal user types from the problem space and competitive research:

"Based on similar products, these are the typical user types. Do any of these match who you're building for?"

Present 2-3 archetypes derived from the competitive landscape (Phase 1 research).

## When This Dimension Is INFERRED

"Based on your description, your main users seem to be **[inferred user type]**. Sound right?"

## Output

Record to `vision/idea-capture.md` or `vision/core-identity.md`:
- **Primary user:** Name/role, goal, frustration, tech comfort
- **Secondary user(s):** Same structure (if applicable)
- **Accessibility notes:** Any specific needs mentioned (mobile-first, low-bandwidth, accessibility requirements)

These raw notes feed into Phase 3D: Persona Synthesis, which generates the full `docs/context/personas.md` file with the 6-field lean format (context, goals, frustrations, behaviors, evaluates-by, failure-looks-like).

## Recommendation Logic

No recommendation — the user knows their audience. Framework role is to structure their knowledge into actionable persona cards that feed feature prioritization, UX decisions, acceptance criteria, and testing.
