# 10. Progress Tracking & Engineering Metrics

## Research Prompt

```
I need deep research on engineering metrics and progress tracking for software development teams using AI assistance. The goal is to determine the best possible metrics framework that measures what actually matters — development velocity, quality, and AI effectiveness — without creating measurement overhead.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Progress tracking:
- progress.md is auto-loaded every session via CLAUDE.md (must be lean — every line consumes context)
- Updated by /sprint-end, read by /continue, /retrospective, /weekly-maintenance, /dashboard
- Parsed by scripts/pm/metrics.sh (must be machine-parseable)
- Must support both solo developers and teams
- The framework tracks activity in docs/sessions/.activity-log.jsonl (skill events, rule triggers, hook actions)
The key question: which metrics actually improve outcomes vs which are measurement theater?

**Research areas** (starting points — include anything significant you discover beyond these):

1. **DORA Metrics** — The four key metrics (deployment frequency, lead time, change failure rate, MTTR). DORA 2024/2025 findings on AI. How to measure for solo/small teams. Correlation with actual quality.

2. **SPACE Framework** — Satisfaction, Performance, Activity, Communication, Efficiency. Which dimensions are measurable in AI-assisted development? Measuring without surveillance.

3. **Code Quality Metrics Over Time** — Cyclomatic complexity trends, code duplication, test coverage trends, technical debt growth, churn rate. What constitutes alarming changes?

4. **AI-Specific Metrics** — AI suggestion survival rate, context reset frequency, TDD compliance rate, skill success/failure rates, edit-to-bash ratio. Which of these actually predict productivity?

5. **Progress Visualization** — Sprint-over-sprint trends in markdown. Quality dashboards in text. Traffic light indicators — when they help vs hide problems.

6. **Metrics Anti-Patterns** — Goodhart's Law. LOC with AI. Coverage gaming. Velocity as performance measure. Over-measuring (when overhead exceeds value).

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended metrics set** — the specific metrics to track, with justification for each inclusion and explicit reasoning for what NOT to track
4. **Recommended tracking format** — how to represent metrics in a lean markdown file
5. **Recommended trend analysis approach** — how to detect meaningful changes vs noise
6. Anti-pattern warnings
7. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on engineering metrics and progress tracking. The research findings are saved in docs/research/engineering-metrics.md (or I will paste them below).

Your task: Update the framework's progress.md template to track the metrics that actually predict and improve software quality, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations: docs/progress.md AND scaffold/docs/progress.md
- Auto-loaded every session via CLAUDE.md — must be lean (every line consumes context budget)
- Updated by /sprint-end, read by /continue, /retrospective, /weekly-maintenance, /dashboard
- Parsed by scripts/pm/metrics.sh — must be machine-parseable
- Must support both solo developers and teams
- AI-specific metrics can be derived from docs/sessions/.activity-log.jsonl

**Instructions:**
1. Read the current docs/progress.md template
2. Read the research findings thoroughly
3. Implement the metrics set, tracking format, and trend analysis approach the research recommends — trust the research over your own defaults
4. Remove any metrics the research shows are harmful or misleading
5. Add guidance comments explaining what each metric measures and why
6. Update scaffold/docs/progress.md to match
7. Verify /sprint-end can populate all metrics correctly
8. Verify scripts/pm/metrics.sh can parse the format

**Outcome criteria (how to evaluate the result):**
- A developer gets a 30-second understanding of project trajectory and quality health
- Every tracked metric has a clear purpose — no vanity metrics
- Metrics that the research identifies as harmful are excluded
- The file is lean enough for auto-loading without consuming excessive context
- Machine-parseable by scripts/pm/metrics.sh
- Trend analysis reveals meaningful patterns, not noise
```
