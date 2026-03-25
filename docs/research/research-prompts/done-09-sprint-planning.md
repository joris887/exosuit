# 9. Sprint Planning & Tracking

## Research Prompt

```
I need deep research on sprint planning documentation for AI-assisted development. The goal is to determine the best possible approach for a sprint specification template that captures everything needed to execute a sprint effectively — with both human developers and AI assistants — while minimizing documentation overhead.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Sprints:
- Are created by /sprint-start, completed by /sprint-end, reviewed by /retrospective
- Represent bounded units of work (typically 3-8 stories)
- Span multiple AI sessions (each session = one or more stories, with /continue for session continuity)
- Context window is a real capacity constraint — sessions can't hold unlimited context
- progress.md is loaded every session (must be lean)
The template must work for solo developers and teams.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Sprint Planning Approaches** — Scrum sprint planning, Kanban continuous flow, Shape Up cycles. Sprint goals — do they improve outcomes? How AI changes capacity calculations.

2. **Sprint Documentation That Works** — Minimum viable sprint spec. Sprint board vs document. Scope documentation. Sprint notes. Retrospective data worth capturing.

3. **Metrics for Sprint Tracking** — Velocity with AI. Burndown/burnup charts. Cycle time per story type. Quality metrics (test delta, coverage delta, complexity delta). Which metrics drive improvement vs vanity?

4. **Sprint Boundaries & Decisions** — Carry-over patterns. Mid-sprint scope protection. When to end early. Planned vs unplanned work.

5. **AI-Specific Sprint Considerations** — Context window as capacity constraint. Session-to-sprint mapping. Handoff patterns between sessions. How AI changes what "sprint-sized" means.

Focus on what's PROVEN to work over what's theoretically ideal.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended sprint spec format** — propose the specific sections and level of detail, with justification
4. **Recommended metrics** — which to track and which to avoid, with evidence
5. **Recommended AI-specific sprint patterns** — session management, capacity, continuity
6. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on sprint planning documentation. The research findings are saved in docs/research/sprint-planning.md (or I will paste them below).

Your task: Update the framework's sprint template and progress tracking to be the most effective sprint management format, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations:
  - docs/sprints/_TEMPLATE.md (and scaffold/) — per-sprint specification
  - docs/progress.md (and scaffold/) — sprint history and metrics
- Used by /sprint-start (creates), /sprint-end (completes), /retrospective (reviews)
- Must capture sprint scope, goals, and outcomes efficiently
- Must track metrics that enable useful retrospectives
- Must support session continuity (/continue reads progress.md)
- progress.md is auto-loaded every session — must be lean
- Must be maintainable with minimal overhead during active development

**Instructions:**
1. Read current docs/sprints/_TEMPLATE.md and docs/progress.md
2. Read the research findings thoroughly
3. Implement the sprint format, metrics, and AI-specific patterns the research recommends — trust the research over your own defaults
4. Update scaffold versions to match
5. Verify /sprint-end populates the templates correctly
6. Verify /retrospective can read the metrics it needs

**Outcome criteria (how to evaluate the result):**
- Sprint documents capture exactly what matters — nothing more, nothing less
- Metrics enable useful retrospectives and predict future sprint capacity
- progress.md gives a 30-second understanding of project trajectory
- Session continuity works — /continue can resume from progress.md state
- Zero documentation overhead during active development (metrics auto-populated by /sprint-end)
```
