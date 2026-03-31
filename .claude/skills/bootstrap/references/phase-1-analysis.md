# Phase 1: Idea Analysis

Reference loaded by Path B Phase 1. Takes the captured idea from `vision/idea-capture.md` and enriches it with project classification, competitive intelligence, and dimension decomposition.

## Step 1: Project Type Detection

Classify the idea into one project archetype. Look for signals in the captured idea:

| Archetype | Signals | Applicable Dimensions |
|-----------|---------|----------------------|
| Full-stack web app | "website", "app", "dashboard", "platform", "marketplace", UI + data | All 10 |
| API/backend service | "API", "service", "backend", "webhook", "integration", no UI mentions | 1, 2, 3, 6, 7, 8, 9, 10 |
| CLI tool | "command line", "CLI", "terminal", "script", automation language | 1, 2, 3, 6, 7, 10 |
| Library/package | "library", "SDK", "package", "module", consumed by other code | 1, 3, 6, 7, 10 |
| Mobile app | "iOS", "Android", "mobile", "phone", "tablet" | All 10 |
| Desktop app | "desktop", "Electron", "Tauri", "native app", "Windows/Mac" | All 10 |
| Data pipeline | "ETL", "pipeline", "data processing", "batch", "ingestion" | 1, 2, 3, 6, 7, 9, 10 |

If ambiguous, ask: "Is this mainly for people to use directly (an app), for other software to use (a library/API), or for processing data (a pipeline)?"

## Step 2: Competitive Landscape Research

Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **QUICK** depth:

- **Query:** "Top 3-5 existing products similar to [idea summary]"
- **Sub-questions:**
  1. "What do users praise about [top competitor]?"
  2. "What do users criticize about [top competitor]?"
- **Output format:** `decision-input` (compact)

Present findings in plain English:

```markdown
### What Already Exists

There are [N] similar tools out there. The most popular is **[X]**:
- People love it for: [Y]
- People complain about: [Z]

**Your opportunity:** [gap or differentiator from the user's idea]
```

**Skip when:** User said "skip research", project is purely internal/personal, or idea is too novel for meaningful comparison.

**Save to:** `vision/competitive-research.md`

## Step 3: Dimension Decomposition

Parse the captured idea against each applicable dimension. For each, determine status:

| Status | Meaning | Example |
|--------|---------|---------|
| **KNOWN** | User explicitly specified | "I want React" → frontend is KNOWN |
| **INFERRED** | Derivable from context | "task management" → needs auth, needs database |
| **OPEN** | Needs user decision | No preference stated for hosting platform |

**Inference rules:**
- Mentions users/accounts → auth dimension INFERRED (needs auth)
- Mentions data/content → database dimension INFERRED (needs storage)
- Mentions "mobile" → responsive/mobile-first INFERRED
- Mentions payments/commerce → security dimension INFERRED (PCI considerations)
- Mentions "team" or "collaboration" → real-time features INFERRED

## Step 4: Present Analysis

```markdown
### Project Analysis

**Type:** [archetype]
**Similar to:** [competitors from research]
**Your edge:** [unique differentiator from captured idea]

**Competition insight:** [1-2 key findings]

**I'll help you decide on these aspects:**
- [x] [Dimension name] — I need your input
- [x] [Dimension name] — I need your input
- [ ] [Dimension name] — you already told me (KNOWN)
- [ ] [Dimension name] — I can figure this out from your description (INFERRED)

Ready to start? Or want to dive deeper into the competition first?
```

Use checkboxes to show which dimensions need user input (OPEN) vs. which are already addressed.

If user wants deeper research: compose `deep-research` at STANDARD depth for the competitive landscape before proceeding.

## Output

Save to `vision/analysis.md`:

```yaml
---
analyzed: YYYY-MM-DD
project_type: [archetype]
competitors: [list]
dimensions_total: [N applicable]
dimensions_known: [count]
dimensions_inferred: [count]
dimensions_open: [count]
---
```

Followed by: project type rationale, competitive findings, and per-dimension status table:

```markdown
## Dimension Status

| # | Dimension | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Core Problem & Vision | KNOWN | "User described problem clearly" |
| 2 | User Personas | OPEN | "No specific users mentioned" |
| 3 | Features & MVP | KNOWN | "Listed 5 features" |
| 5 | Frontend | OPEN | "No preference stated" |
| 6 | Backend | INFERRED | "React mentioned → Node.js likely" |
| 7 | Data & Storage | INFERRED | "User accounts → needs database" |
| 8 | Auth & Security | INFERRED | "User accounts → needs auth" |
| 9 | Deployment | OPEN | "No preference stated" |
```

Proceed to Phase 2 (Dimension Discovery) for all OPEN and INFERRED dimensions.
