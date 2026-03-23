# 10. Progress Tracking & Engineering Metrics

## Research Prompt

```
I need comprehensive deep research on engineering metrics and progress tracking for software development teams using AI assistance. The goal is a metrics framework that measures what actually matters — development velocity, quality, and AI effectiveness — without creating measurement overhead.

Research these specific areas:

1. **DORA Metrics (DevOps Research and Assessment)**
   - The four key metrics: deployment frequency, lead time, change failure rate, MTTR
   - DORA 2024/2025 findings — what's new? How does AI assistance change these metrics?
   - How to measure DORA metrics for solo developers and small teams
   - Correlation between DORA metrics and actual software quality
   - Tools for tracking DORA metrics (LinearB, Sleuth, Jellyfish)

2. **SPACE Framework (Developer Productivity)**
   - Satisfaction, Performance, Activity, Communication, Efficiency dimensions
   - Which SPACE dimensions are measurable in AI-assisted development?
   - Research on developer satisfaction with AI tools
   - How to measure without surveillance (self-reported vs automated)

3. **Code Quality Metrics Over Time**
   - Cyclomatic complexity trends — what constitutes alarming growth?
   - Code duplication tracking — tools, thresholds, trend analysis
   - Test coverage trends — what rate of coverage growth is realistic?
   - Technical debt growth rates — research on sustainable debt levels
   - Churn rate (files changed then quickly changed again) — indicator of rework

4. **AI-Specific Metrics**
   - AI suggestion survival rate — how much AI-generated code survives review?
   - Context reset frequency — how often does the AI lose context?
   - TDD compliance rate — how often is test-first actually followed?
   - Agent effectiveness — which quality agents catch real issues vs false positives?
   - Skill success rates — which skills fail most and why?
   - Edit-to-bash ratio — what ratio indicates productive work vs debugging?

5. **Progress Visualization**
   - Sprint-over-sprint trend formats — what visualization works in markdown?
   - Quality dashboards — what should a developer see at a glance?
   - Burndown in text format — is it useful in a markdown file?
   - Traffic light (green/yellow/red) indicators — when they help vs when they hide

6. **Metrics Anti-Patterns**
   - Goodhart's Law in engineering metrics ("when a measure becomes a target...")
   - Lines of code as a metric — why it's harmful with AI (AI generates more code)
   - Coverage gaming — writing tests to hit numbers without testing behavior
   - Velocity as a performance measure — why it fails
   - Over-measuring — when metrics overhead exceeds their value

For each finding, include research sources, data quality, and specific recommendations for what to track in a markdown-based progress file.

Output a structured research report with: recommended metrics set, tracking format, trend analysis approach, and anti-pattern warnings.
```

## Implementation Prompt

```
I have completed deep research on engineering metrics and progress tracking. The research findings are saved in docs/research/engineering-metrics.md (or I will paste them below).

Your task: Update the framework's progress.md template to track the metrics that actually predict and improve software quality.

**Context:** The template lives at docs/progress.md (and scaffold/docs/progress.md). It's updated by /sprint-end and read by /continue, /retrospective, /weekly-maintenance, and /dashboard. It must:
- Track sprint-over-sprint trends that reveal quality patterns
- Include AI-specific metrics (measured via activity-log.jsonl and skill events)
- Be parseable by scripts (scripts/pm/metrics.sh reads it)
- Stay lean — auto-loaded in CLAUDE.md, consumes context budget
- Support both solo developers and teams

**Instructions:**
1. Read the current docs/progress.md template
2. Read the research findings
3. Redesign the metrics structure:
   - Current Sprint section (what's active)
   - Sprint-over-Sprint Trends table (research-validated metrics)
   - Quality Indicators section (what to track and threshold values)
   - AI-Effectiveness metrics (research-backed, not vanity)
   - Ground Rule Compliance section (existing, verify format)
4. Remove any metrics that research shows are harmful or misleading
5. Add guidance comments explaining what each metric measures and why
6. Update scaffold version to match
7. Verify /sprint-end populates all metrics correctly
8. Verify scripts/pm/metrics.sh can parse the format

Make this the progress file that gives a developer a 30-second understanding of project trajectory and quality health.
```
