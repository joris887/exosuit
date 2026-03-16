# Research Output Templates

Templates for research output documents. The invoking skill or the deep-research engine selects the appropriate format.

## Full Research Report

Saved to `docs/research/<topic-slug>.md`. Used by `/research` standalone and spike stories at DEEP depth.

```markdown
---
title: "<Research Topic>"
date: <YYYY-MM-DD>
depth: quick | standard | deep
query: "<Original research query>"
confidence: <0-100>
sources_count: <N>
sub_questions: <N>
iteration_rounds: <N>
tags: [<topic1>, <topic2>]
---

# Research: <Topic>

## Executive Summary

[2-3 sentence answer to the original query. State the headline finding and confidence level.]

## Findings

### <Sub-question 1>

[Findings with inline citations. Each factual claim references a source by number, e.g., [1].]

### <Sub-question 2>

[Findings with inline citations.]

[Repeat for each sub-question]

## Sources

| # | URL | Title | Quality | Date |
|---|-----|-------|---------|------|
| 1 | [url] | [title] | high/medium/low | [date] |
| 2 | [url] | [title] | high/medium/low | [date] |

## Knowledge Gaps

- [What remains unknown or uncertain]
- [Areas where sources conflicted without resolution]
- [Topics that need dedicated follow-up research]

## Confidence Assessment

**Overall: [score]/100**

| Sub-question | Confidence | Justification |
|-------------|-----------|---------------|
| [sub-Q 1] | [score] | [one-line reason] |
| [sub-Q 2] | [score] | [one-line reason] |

## Recommendations

- [Actionable next step based on findings]
- [Whether further research is needed and on what]
- [How findings should influence current work]
```

## Solution Document Enrichment

When research findings relate to a specific implementation pattern, enrich the existing `docs/solutions/<slug>.md` format:

```yaml
---
title: "<Solution Title>"
tags: [<tag1>, <tag2>]
module: "<module>"
component: "<component>"
research_sources:
  - url: "<URL>"
    title: "<title>"
    quality: "high | medium | low"
    date: "<date>"
---
```

Add a `## Research Context` section to the solution document body with the relevant findings and source citations.

## Citation Format

All research outputs use numbered inline citations:

- **Inline:** `[1]`, `[2]`, `[1,3]` — reference the source table
- **Source table:** numbered rows with URL, title, quality rating, and date
- **Quality ratings:** `high` (8-10 score), `medium` (5-7), `low` (3-4)
- Sources scoring 0-2 should not appear (discarded during research)

## Directory Structure

```
docs/
├── research/          ← Full research reports (deep-research output)
│   ├── auth-token-rotation.md
│   └── sqlalchemy-vs-tortoise.md
├── solutions/         ← Implementation-focused learnings (may include research_sources)
│   └── async-db-connection-pool.md
└── brainstorms/       ← Design explorations (may reference research)
    └── notification-system.md
```
