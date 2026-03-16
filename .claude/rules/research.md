# Research Output Rules

## Rule Effectiveness Tracking

When a rule influences your behavior (causes you to change an approach, block an action, or apply a check you wouldn't otherwise do), emit a tracking event:

```bash
echo "{\"type\":\"rule\",\"rule\":\"research\",\"action\":\"<what-it-caused>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

## Path Scope

These rules apply when creating or editing files in:
- `docs/research/**`
- `docs/solutions/**` (when adding `research_sources` fields)

## Research Quality Standards

- Every factual claim in a research report MUST cite a web source with URL — "according to training data" is never acceptable
- Confidence scores MUST include a justification (not just a number) — explain what drives the score up or down
- Contradictions between sources MUST be explicitly noted — do not silently pick one side
- Outdated sources MUST be flagged: >12 months for fast-moving topics (frameworks, cloud services, security), >3 years for stable topics (algorithms, protocols, standards)
- Sources scoring below 3/10 on the quality scale (see `.claude/prompts/source-evaluator.md`) MUST NOT appear in the final report
- All URLs in source tables MUST be from actual WebFetch calls in this session — never fabricate or guess URLs

## Research Report Structure

Research reports saved to `docs/research/` MUST include:
- YAML frontmatter with: title, date, depth, query, confidence, sources_count, tags
- Executive Summary section
- Per-sub-question Findings sections
- Sources table with quality ratings
- Knowledge Gaps section
- Confidence Assessment with per-sub-question breakdown

## Anti-Patterns

- DO NOT present opinions as findings — label analysis and interpretation explicitly
- DO NOT omit negative findings — if research reveals a technology's weaknesses, include them
- DO NOT mix codebase findings with web findings without clear attribution
- DO NOT copy-paste large blocks from web sources — distill into reflections with citations
