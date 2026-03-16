Source quality evaluation criteria. Compose this snippet when assessing web research results, documentation, or any external information source.

## Quality Signals — Positive

| Signal | Why It Matters |
|--------|---------------|
| Official documentation (API docs, library guides) | First-party, maintained, version-specific |
| Specific version numbers, dates, code examples | Verifiable and reproducible |
| Well-known publication or engineering blog | Editorial review, reputation at stake |
| Author with verifiable domain expertise | Accountable, experienced perspective |
| Recent publication (within topic's change rate) | Reflects current state |
| Concrete benchmarks or measurements | Evidence over opinion |
| Links to source code or reproducible examples | Verifiable claims |

## Quality Signals — Negative

| Signal | Pattern to Watch For |
|--------|---------------------|
| Speculation without evidence | "could", "may", "might", "possibly", "potentially" |
| Marketing language | "revolutionary", "game-changing", "best-in-class", "cutting-edge" |
| Unnamed attribution | "experts say", "studies show", "it is widely believed" |
| Passive voice hiding sources | "it has been shown", "it is known that" |
| SEO content farm markers | Thin content, listicle format, keyword stuffing, no depth |
| Outdated content | No date, or date older than topic's change cycle |
| AI-generated filler | Repetitive hedging, generic advice, covers all bases without specifics |
| Circular sourcing | Multiple articles citing each other with no primary source |

## Quality Score (0–10)

| Score | Category | Examples |
|-------|----------|---------|
| 8–10 | **Authoritative** | Official docs, peer-reviewed research, RFC specifications |
| 5–7 | **Useful** | Engineering blogs with code, StackOverflow (high upvotes), tutorials with working examples |
| 3–4 | **Supplementary** | Forum discussions, opinion pieces with some evidence, older but relevant content |
| 0–2 | **Unreliable** | Content farms, unsourced claims, heavily outdated, pure marketing |

## Decision Rules

- **Build findings from** sources scoring 5+ (authoritative + useful)
- **Note as supplementary** sources scoring 3–4 (mention but don't rely on)
- **Discard** sources scoring 0–2 unless they're the only source (flag low confidence)
- **When sources conflict:** prefer higher-quality source; if equal quality, note the disagreement
- **Recency weighting:** for fast-moving topics (frameworks, cloud services, security), weight sources from the last 12 months 2× higher than older sources
