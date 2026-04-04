# Interactive UX Protocol

Shared rules for all skills that interact with users via questions. Referenced by `/bootstrap`, `/discover`, and any skill that asks questions.

## Tool Selection

Use **AskUserQuestion** for 2-4 predefined choices (tech stack, profile, scale, yes/no, approval gates, ratings). Use **conversational text** for open-ended exploration (problem descriptions, feature brainstorms, follow-up clarification). When a question works both ways, use AskUserQuestion but phrase it: _"Select below, or choose 'Other' to describe your specific needs — the more detail you provide, the better the result."_

## AskUserQuestion Format Rules

1. **Recommend first** — Place the recommended option FIRST with `(Recommended)` in the label. Always have a recommendation — if uncertain, recommend the most common/safest choice.
2. **Rich descriptions** — Every option's `description` MUST explain: what it means in plain English, when to choose it, and what trade-off it implies.
3. **Encourage detail** — Add to the question text: _"Select 'Other' to describe your specific needs in detail."_ Make this feel inviting, not like a fallback.
4. **Preview for tech choices** — Use the `preview` field (single-select only) for file structures, config snippets, or architecture diagrams when comparing technical options.
5. **Max 4 options** — When there are more choices, present the 3 best-fit options based on context. "Other" (auto-included) covers the rest. If user picks "Other" wanting more options, show the full list as text, then use a new AskUserQuestion with their top picks.
6. **Multi-select for checklists** — Use `multiSelect: true` for tool installation, compliance checks, feature selection, and any "select all that apply" questions.

## Progress Tracking

Display a phase bar at the START of each new phase and after major steps:

```
---
**[Skill Name]** | Phase [N] of [Total]: [Phase Name]
[========>...........] [X] of ~[Y] decisions
Coming up: [plain-English description of next step]
---
```

Before the first question of each phase, provide a 2-3 sentence summary: what this phase covers, why it matters, and approximately how long it takes. Use plain language — "aspects" not "dimensions", "decided" not "resolved".

## Confirmation Gates

At HARD GATE approval points, use AskUserQuestion:

```
header: "Approve"
question: "[Summary]. Ready to proceed?"
options:
  - label: "Looks good, continue (Recommended)"
    description: "Accept and move to the next phase"
  - label: "I want to change something"
    description: "Go back and revise specific items before continuing"
  - label: "Start over from [phase]"
    description: "Restart from an earlier phase if the direction has drifted"
```

## Phase Transitions

Between phases: (1) summarize decisions from the completed phase as 3-5 bullets, (2) show updated progress bar, (3) preview what's coming next. Keep transitions to 5-8 lines — orient, don't lecture.
