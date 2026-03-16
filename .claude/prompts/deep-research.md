Deep online research methodology. Compose this snippet when a skill needs web research beyond a single search. The invoking skill specifies the depth level and query — this snippet provides the methodology.

## Depth Levels

| Parameter | Quick | Standard | Deep |
|-----------|-------|----------|------|
| Sub-questions | 1–2 | 3–4 | 4–6 |
| Searches per sub-Q | 2–3 | 5–8 | 10–15 |
| WebFetch per sub-Q | 1–2 | 3–5 | 5–10 |
| Iteration rounds | 0 | 1 | 2–3 |
| Confidence threshold | — | 70 | 80 |
| Subagent tool budget | 5 | 12 | 20 |
| Subagent dispatch | No (inline) | Yes (parallel) | Yes (parallel) |
| Agent model | haiku | haiku | default (inherits) |
| Default output format | evidence-check | decision-input | research-report |
| Persistence | Inline in caller | `docs/solutions/` or inline | `docs/research/` |
| Output length | 1–2 paragraphs | 1–2 pages | 3–5 pages |

The invoking skill selects the depth. If not specified, classify automatically:
- **Quick** — single factual question, verification check, "does X support Y?"
- **Standard** — comparison, multi-faceted analysis, implementation approach
- **Deep** — domain exploration, strategic decision, comprehensive investigation

## Phase 1: Decompose

Break the research query into independent sub-questions.

1. Identify the core question and its facets
2. Generate N sub-questions (N from depth table) that together cover the query
3. **Standard/Deep only:** For each sub-question, classify as: **web-only**, **code-only**, or **hybrid** (both). Skip classification at QUICK depth — it's overhead for simple queries.
4. Prioritize sub-questions by importance to the original query
5. If the query is already narrow enough for a single sub-question, skip decomposition

Output a numbered sub-question list (with classification and priority for Standard/Deep).

## Phase 2: Dispatch

**Quick depth:** Execute inline — no subagent dispatch. Run searches directly in the current context (parallel WebSearch calls are fine). Use the same reflection format as subagents to structure findings, but write it inline rather than dispatching an agent. **Stop early:** If the first search + WebFetch gives a definitive answer from an authoritative source (e.g., official docs), stop searching — don't fill the budget for the sake of it.

**Standard and Deep depth:** Dispatch parallel subagents using the Agent tool:

For EACH sub-question, launch an Agent with:
```
Subagent type: general-purpose
Model: haiku (quick/standard) or default (deep)
Prompt: |
  Research this specific question: "[sub-question]"

  Search strategy:
  - Start with SHORT, BROAD queries (under 5 words)
  - If few results, broaden slightly — do NOT add more words
  - Use WebSearch for discovery, then WebFetch for the 2-3 most promising results (2-3 total, not per search)
  - If WebFetch fails (SSL error, timeout, 403): fall back to search result snippets for that source, note reduced confidence
  - Budget: [N] total tool calls maximum

  Source evaluation — watch for and downgrade:
  - Speculation: "could", "may", "might", "possibly" without evidence
  - Marketing language: "revolutionary", "game-changing", "best-in-class"
  - Unnamed sources: "experts say", "studies show" without citation
  - SEO content farms: thin content, listicle format, no depth
  - Outdated content: check publication date vs topic's rate of change

  Source evaluation — prioritize:
  - Official documentation and API references
  - Content with specific version numbers, dates, code examples
  - Well-known publications and authors with verifiable expertise
  - Recent content (within last 2 years for fast-moving topics)

  OUTPUT FORMAT — Return ONLY a reflection, not raw content:
  ```
  ## Reflection: [sub-question]

  **Key findings:**
  - [finding 1 — one sentence, factual]
  - [finding 2]
  - [finding 3]

  **Confidence:** [0-100] — [one-line justification]

  **Sources:**
  - [URL] — [title] — [quality: high/medium/low] — [date if found]

  **Contradictions:** [any conflicting claims between sources, with both positions noted — or "None"]

  **Gaps:** [what couldn't be answered or needs deeper investigation]
  ```

  CRITICAL: Return the reflection only. Do NOT include raw page content.
```

Launch all sub-question agents in a SINGLE message (parallel dispatch). Wait for all to complete.

### Dispatch Rules

- Max 5 parallel agents (context pressure from concurrent results)
- Each agent operates with independent context (this IS the context isolation strategy)
- Only reflections come back — raw web content stays in the subagent's context
- If a subagent fails or times out, note the gap and continue with available results

### Dispatch Fallback

If parallel Agent dispatch is unavailable or impractical (tool limitations, environment constraints):
- Fall back to running searches in parallel batches (multiple WebSearch calls in one message)
- Write inline reflections per sub-question using the same reflection format
- Track total tool calls across all sub-questions (use the sum of per-subagent budgets as total budget)
- The reflection pattern still works — it's about structuring findings, not about the dispatch mechanism

## Phase 3: Synthesize

After all subagent reflections are collected:

1. **Merge findings** — Combine reflections into a coherent answer to the original query
2. **Resolve contradictions** — If sources disagree, note the disagreement explicitly with both positions and their evidence strength
3. **Assess confidence** — Overall confidence = weighted average of sub-question confidences (weighted by priority)
4. **Identify gaps** — Compile all gaps from sub-question reflections
5. **Deduplicate sources** — Merge source lists, keep highest quality rating per URL

## Phase 4: Deepen (Standard and Deep only)

Skip this phase if overall confidence meets the threshold (70 for standard, 80 for deep).

For sub-questions below the confidence threshold:

1. Generate 1–2 targeted follow-up queries based on identified gaps
2. Dispatch a new round of subagents for low-confidence sub-questions only
3. Merge new reflections into the existing synthesis
4. Re-evaluate confidence
5. **Deep only:** Repeat up to 2 more times (max 3 total rounds)

**Stop conditions** (any one triggers stop):
- All sub-questions meet confidence threshold
- New round yielded no novel information (diminishing returns)
- Total tool budget exhausted
- 3 rounds completed (deep) or 1 round completed (standard)

## Phase 5: Output

Format the final output based on what the invoking skill requested:

### Format: `research-report`
Full structured report for standalone `/research` output:
```markdown
# Research: [Topic]

## Executive Summary
[2-3 sentence answer to the original query]

## Findings
### [Sub-question 1]
[Findings with inline citations]

### [Sub-question 2]
[Findings with inline citations]

## Sources
| # | URL | Title | Quality | Date |
|---|-----|-------|---------|------|

## Knowledge Gaps
- [What remains unknown or uncertain]

## Confidence
Overall: [score]/100
[One-paragraph justification with per-sub-question breakdown]
```

### Format: `decision-input`
Compact findings for brainstorm/ideate integration:
```markdown
**Research findings for: [topic]**
- [Key finding 1] ([source])
- [Key finding 2] ([source])
- [Key finding 3] ([source])
**Confidence:** [score]/100 | **Gaps:** [brief gap summary]
```

### Format: `plan-context`
Findings formatted for integration into a plan:
```markdown
**Online research context:**
[2-3 paragraph summary of findings relevant to the plan]
Sources: [URL list]
Confidence: [score]/100
```

### Format: `evidence-check`
Yes/no/maybe answer with supporting evidence:
```markdown
**Question:** [the query]
**Answer:** [Yes / No / Partially / Unclear]
**Evidence:** [1-3 sentences with source citations]
**Confidence:** [score]/100
```

## Anti-Patterns

- **DO NOT** use long, specific search queries — start broad (under 5 words), then narrow
- **DO NOT** accumulate raw web page content in context — always distill to reflections
- **DO NOT** skip source evaluation — quality matters more than quantity
- **DO NOT** research what can be found in the local codebase — use Grep/Read for that
- **DO NOT** exceed the tool budget for the depth level — stop and report gaps instead
- **DO NOT** re-research topics already covered in `docs/research/` or `docs/solutions/` — check first
- **DO NOT** present training-data knowledge as research findings — all claims must come from web sources

## Token Budget Guidance

| Phase | Budget Share |
|-------|-------------|
| Decomposition | 5% |
| Search + Reflection (subagents) | 70% |
| Synthesis + Deepening | 15% |
| Output formatting | 10% |

The reflection pattern keeps token growth linear: each subagent returns ~200-400 tokens of reflection regardless of how many pages it read. This is the key efficiency mechanism.
