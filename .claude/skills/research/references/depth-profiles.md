# Research Depth Profiles

Reference for calibrating research effort to query complexity. Used by the deep-research engine and by skills that compose it.

## Profile Parameters

| Parameter | Quick Scan | Standard | Deep Dive |
|-----------|-----------|----------|-----------|
| **Sub-questions** | 1–2 | 3–4 | 4–6 |
| **Searches per sub-Q** | 2–3 | 5–8 | 10–15 |
| **WebFetch per sub-Q** | 1–2 | 3–5 | 5–10 |
| **Iteration rounds** | 0 | 1 | 2–3 |
| **Confidence threshold** | N/A | 70/100 | 80/100 |
| **Subagent tool budget** | 5 | 12 | 20 |
| **Agent model** | haiku | haiku | default (inherits) |
| **Subagent dispatch** | No (inline) | Yes (parallel) | Yes (parallel) |
| **Expected output** | 1–2 paragraphs | 1–2 pages | 3–5 pages |
| **Default output format** | evidence-check | decision-input | research-report |
| **Persistence** | Inline in calling skill | `docs/solutions/` or inline | `docs/research/` |

## When to Use Each Depth

### Quick Scan
- Single factual question: "Does X support Y?"
- Verification of a specific claim or API capability
- Dependency freshness check (CVEs, deprecations)
- Bug fix error pattern lookup
- Simple "how to" for a well-documented feature
- Story-cycle Phase 1c.5 for standard stories

### Standard
- Comparison queries: "X vs Y for use case Z"
- Implementation approach research with multiple options
- Multi-faceted questions touching several concerns
- Brainstorm alternative evaluation
- Ideate feasibility checks for unfamiliar technology
- Bootstrap domain exploration
- Story-cycle Phase 1c.5 for high-risk stories

### Deep Dive
- Domain exploration for unfamiliar territory
- Strategic technology decisions with long-term impact
- Comprehensive investigation across multiple perspectives
- Spike/Research stories
- Standalone `/research` queries
- Bootstrap vision document research (Path B)
- Complex brainstorms involving architectural decisions

## Auto-Classification Heuristics

When the invoking skill doesn't specify depth, classify based on:

| Signal | Points |
|--------|--------|
| Query is a yes/no question | -2 (toward quick) |
| Query involves comparison (vs, compare, which) | +1 (toward standard) |
| Query involves "how to" or "best practices" | +1 (toward standard) |
| Query involves multiple technologies or domains | +2 (toward deep) |
| Query involves strategic or architectural decisions | +2 (toward deep) |
| Query involves unfamiliar domain or technology | +1 (toward deep) |
| Query word count < 10 | -1 (toward quick) |
| Query word count > 25 | +1 (toward deep) |
| Story is spike/research type | +3 (toward deep) |
| Story has security/payments/auth tag | +1 (toward standard) |

**Scoring:** Sum the signals. ≤0 → Quick. 1–3 → Standard. ≥4 → Deep.

## Depth Override

The user can always override the auto-classification:
- "Quick scan: [query]" → forces Quick
- "Deep dive: [query]" → forces Deep
- If the invoking skill specifies depth, use that depth regardless of auto-classification
