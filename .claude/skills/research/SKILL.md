---
name: research
version: 1.0.0
description: Deep online research on any topic. Produces structured reports with citations and confidence scores. Three depth modes — quick scan, standard investigation, or deep dive.
trigger: manual
depends-on: []
references: [research-report-template.md, depth-profiles.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Write, Glob, Grep, Bash, Agent, WebSearch, WebFetch
argument-hint: "<topic-or-question>"
---
______________________________________________________________________

## research

Researching: **$ARGUMENTS**

## Phase 1: Clarification Gate

Before starting research, assess whether the query is specific enough:

**If the query is vague** (single word, no clear question, ambiguous scope):
- Ask 1–2 focused clarifying questions using AskUserQuestion
- Ask about scope: "What specific aspect of [topic] are you interested in?"
- Ask about context: "Is this for a specific project/technology, or a general investigation?"

**If the query is specific enough** — proceed directly.

**Ask about depth** if not obvious from the query:
- Use AskUserQuestion with options: "Quick scan (2-3 searches, fast answer)", "Standard (parallel research, 2-3 min)", "Deep dive (comprehensive, 5-10 min)"
- If the query clearly implies depth (e.g., "comprehensive analysis of..." → deep), skip asking

## Phase 2: Check Prior Research

Before doing new research, check if this topic has been investigated before:

1. Search `docs/research/` for matching topics (Grep on title/tags in frontmatter)
2. Search `docs/solutions/` for related findings
3. Search `docs/brainstorms/` for related design explorations

If prior research exists:
- Load it and assess: is it still current? Does it answer the query?
- If it's recent and relevant: present it to the user, ask if they want fresh research or if prior findings suffice
- If it's outdated or partially relevant: note it as context for the new research

## Phase 3: Plan Research

Compose the **deep-research** methodology (`.claude/prompts/deep-research.md`):

1. **Classify depth** — Auto-classify using depth profile heuristics, or use the user's explicit choice
2. **Decompose query** — Break into sub-questions per Phase 1 of deep-research methodology
3. **Present plan to user** — Show the sub-questions and depth before executing

Present the research plan:
```
Research plan for: [query]
Depth: [quick/standard/deep]

Sub-questions:
1. [sub-question 1] — [web/code/hybrid]
2. [sub-question 2] — [web/code/hybrid]
3. [sub-question 3] — [web/code/hybrid]

Estimated: [N] searches, [time estimate]
```

<HARD-GATE>
Do NOT dispatch research agents until the user approves the research plan. The user may want to adjust sub-questions, change depth, or add specific areas to investigate.
</HARD-GATE>

## Phase 4: Execute Research

After plan approval, execute using the deep-research methodology:

1. **Quick depth:** Execute inline — search sequentially, no subagent dispatch
2. **Standard/Deep depth:** Dispatch parallel subagents per sub-question using the Agent tool
   - Each subagent is a `research-analyst` (general-purpose agent with the research-analyst prompt)
   - Each receives: sub-question, search strategy, tool budget, output format instructions
   - Launch ALL subagents in a single message for parallel execution

Communicate progress to the user between phases:
- After dispatch: "Researching [N] sub-questions in parallel..."
- After collection: "Collected findings from [N] sub-questions. Synthesizing..."

## Phase 5: Synthesize & Evaluate

Apply Phase 3 (Synthesize) from the deep-research methodology:

1. Merge all subagent reflections into a coherent answer
2. Resolve contradictions explicitly
3. Assess overall confidence (weighted average of sub-question confidences)
4. Compile knowledge gaps

**If confidence is below threshold** (70 for standard, 80 for deep):
- Present initial findings with low-confidence areas highlighted
- Ask user: "These areas have low confidence: [gaps]. Want me to dig deeper on any of them?"
- If yes: apply Phase 4 (Deepen) from deep-research methodology — targeted follow-up research
- If no: proceed with current findings, noting confidence gaps

## Phase 6: Output & Persist

1. **Generate report** using the `research-report` format from `references/research-report-template.md`
2. **Save to** `docs/research/<topic-slug>.md` with full YAML frontmatter
3. **Present key findings** to the user — don't just say "report saved", show the executive summary and top findings inline

### Topic Slug Generation
- Lowercase the topic
- Replace spaces with hyphens
- Remove special characters
- Truncate to 50 characters
- Example: "Modern auth token rotation" → `modern-auth-token-rotation`

## Phase 7: Cross-Reference & Next Steps

After presenting findings:

1. **Check backlog impact** — Search `docs/reference/BACKLOG_INDEX.md` for stories that might be affected by these findings
2. **Check solution overlap** — Search `docs/solutions/` for existing learnings that should be updated
3. **Suggest next steps** based on findings:
   - "These findings suggest a brainstorm: `/brainstorm [topic]`"
   - "This could become stories: `/ideate [idea based on findings]`"
   - "A spike story would help validate: [specific uncertainty]"
   - "Findings are informational only — no action needed"

## Example

```
Input:  /research "Compare SQLAlchemy vs Tortoise ORM for async Python APIs"

Phase 1: Query is specific, implies comparison → auto-depth: Standard
Phase 2: No prior research found
Phase 3: Plan presented —
  Sub-questions:
  1. SQLAlchemy async capabilities and maturity
  2. Tortoise ORM async capabilities and maturity
  3. Performance benchmarks and community adoption
  4. Migration path and ecosystem compatibility

Phase 4: 4 subagents dispatched in parallel
Phase 5: Confidence 82/100 — all sub-questions well-covered
Phase 6: Report saved to docs/research/sqlalchemy-vs-tortoise-orm.md
Phase 7: No backlog impact. Suggested: /brainstorm if choosing ORM for new project
```

## Rules

- NEVER skip the clarification gate for vague queries — bad input produces bad research
- NEVER present training-data knowledge as research findings — all claims must come from web sources
- NEVER dispatch research without user approval of the plan
- ALWAYS save research reports for future reference (they prevent redundant research)
- ALWAYS show the executive summary inline — don't make users open the file to see results
- ALWAYS check for prior research before starting new research
- Keep the research plan visible and the user in control of depth and scope
