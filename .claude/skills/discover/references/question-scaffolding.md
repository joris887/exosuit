# Question Scaffolding Rules

These rules apply to EVERY question the framework asks during /discover. They are non-negotiable.

## Rule 1: Recognition Before Recall

Never ask open-ended without first offering options.

```
BAD:  "What visual style?"
GOOD: "Which style is closest?
       (a) Clean and minimal (Apple)
       (b) Playful and colorful (Duolingo)
       (c) Dark and atmospheric (game)
       (d) Data-rich and dense (dashboard)
       (e) Something else — describe it"
```

## Rule 2: Example Before Abstraction

Every abstract concept gets a concrete example first.

```
BAD:  "What needs to be true for this to work?"
GOOD: "Let's check assumptions. Your project assumes 'people will
       enter consumption data willingly.' Rate each: True/Probably/Unknown."
```

## Rule 3: One Question at a Time

Never batch. Ask one, wait for the answer, ask the next based on the answer. This is a conversation, not a form.

## Rule 4: Scaffolding Format

Every question follows this structure:
```
[Question]
[Scaffold: context/examples/options — visually distinct from the question]
```

The scaffold provides anchoring without constraining. Options are starting points, not limits.

## Rule 5: Escape Hatches

Every question has at least one of:
- **"I don't know"** → offer 2-3 concrete options to choose from
- **"You decide"** → pick the best option, mark as ASSUMED in DECISION_LOG, move on
- **"Tell me more"** → explain tradeoffs before re-asking
- **"Skip"** → mark OPEN in DECISION_LOG, revisit later

Never trap the user in a question they can't answer. The goal is progress, not perfection.

## Rule 6: Adaptive Depth

Match the user's energy and confidence level:
- **Confident, detailed answers** → fewer follow-ups, move faster
- **Vague or uncertain answers** → drill deeper with more scaffolding
- **Enthusiastic about a topic** → explore it, even if tangential
- **Impatient or rushed** → compress, offer to auto-decide remaining items

Read the room. A weekend hobbyist and an enterprise architect need different pacing.

## Rule 7: Use AskUserQuestion for Closed Choices

When presenting 2-4 predefined options, use the **AskUserQuestion tool** — don't just list options as text. This gives the user a proper selection UI instead of typing.

Follow the format rules in `@.claude/prompts/interactive-ux.md`:
- Recommended option FIRST with `(Recommended)` in the label
- Rich `description` on every option (what it means, when to choose it, trade-off)
- Phrase the question to encourage the user to select "Other" for detailed custom input
- Use `preview` field for technical comparisons (file structures, config snippets)
- Use `multiSelect: true` for "select all that apply" questions

**When NOT to use AskUserQuestion:**
- Open-ended exploration ("describe your idea", "what problem does this solve")
- Follow-up clarification where the answer depends on prior conversation context
- Questions with >4 genuine options where narrowing would lose important nuance

**Hybrid pattern:** For questions that could go either way, present AskUserQuestion options but make the question text say: _"Select below, or choose 'Other' to tell me in your own words — detailed answers help me build something closer to what you want."_

## Rule 8: Progress Tracking

Users need to know where they are in the process. Display a progress bar at the start of each new phase:

```
---
**Discover** | Phase [N] of 7: [Phase Name]
[========>...........] [X] of ~[Y] decisions
Coming up: [plain-English next step]
---
```

Before each phase's first question, give a 2-3 sentence preview: what this phase covers, why it matters, how long it takes. Between phases, summarize what was decided (3-5 bullets) before showing the next progress bar.
