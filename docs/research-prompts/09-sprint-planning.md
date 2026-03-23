# 9. Sprint Planning & Tracking

## Research Prompt

```
I need comprehensive deep research on sprint planning documentation for AI-assisted development. The goal is a sprint specification template that captures everything needed to execute a sprint effectively — with both human developers and AI assistants — while minimizing documentation overhead.

Research these specific areas:

1. **Sprint Planning Approaches**
   - Scrum sprint planning (two-part) — what survives from formal Scrum in modern practice?
   - Kanban continuous flow vs fixed sprints — research on which works better with AI
   - Shape Up's "6-week cycles with 2-week cooldown" — applicable to AI-assisted work?
   - Sprint goals research — do sprint goals improve outcomes? (SAFe, Scrum.org data)
   - Sprint capacity planning — how AI changes capacity calculations

2. **Sprint Documentation That Works**
   - What information does a sprint spec actually need? (minimalist research)
   - Sprint board vs sprint document — when each is appropriate
   - Sprint scope documentation — how to capture "done" for the sprint
   - Sprint notes — what's worth capturing during a sprint?
   - Sprint retrospective data — what to track for useful retrospectives?

3. **Metrics for Sprint Tracking**
   - Velocity tracking with AI assistance — does it still make sense?
   - Burndown/burnup charts — do they help or hinder with AI?
   - Cycle time per story type — research on predictability patterns
   - Sprint quality metrics: test delta, coverage delta, complexity delta
   - Which metrics drive improvement vs which are vanity metrics?

4. **Sprint Boundaries & Decisions**
   - How to handle stories that span sprints (carry-over patterns)
   - Sprint scope protection — research on mid-sprint scope changes
   - When to end a sprint early (criteria and process)
   - Bug handling during sprints — planned vs unplanned work tracking

5. **AI-Specific Sprint Considerations**
   - Context window as a sprint capacity constraint
   - Session-to-sprint mapping — how many sessions per sprint?
   - Sprint continuity with AI — handoff patterns between sessions
   - How AI changes the definition of "sprint-sized" work

For each finding, include sources and practical recommendations. Focus on what's PROVEN to work over what's theoretically ideal.

Output a structured research report with: recommended sprint spec format, metrics guidance, and AI-specific sprint management patterns.
```

## Implementation Prompt

```
I have completed deep research on sprint planning documentation. The research findings are saved in docs/research/sprint-planning.md (or I will paste them below).

Your task: Update the framework's sprint template and progress tracking to be the most effective sprint management format.

**Context:** Templates live at:
- docs/sprints/_TEMPLATE.md (and scaffold/) — per-sprint specification
- docs/progress.md (and scaffold/) — sprint history and metrics

Used by /sprint-start (creates sprint), /sprint-end (completes sprint), /retrospective (reviews sprint). They must:
- Capture sprint scope, goals, and outcomes efficiently
- Track metrics that enable useful retrospectives
- Support session continuity (/continue reads progress.md)
- Be maintainable with minimal overhead during active development

**Instructions:**
1. Read the current templates (docs/sprints/_TEMPLATE.md and docs/progress.md)
2. Read the research findings
3. Update sprint template:
   - Sprint goal (one-sentence purpose)
   - Story list with status tracking
   - Key decisions made during sprint
   - Metrics (tests, coverage, quality indicators)
   - Sprint outcome summary
4. Update progress.md structure:
   - Sprint-over-sprint trends table (if research suggests improvements)
   - Quality indicators section
   - AI-specific metrics (if research validates their usefulness)
5. Update scaffold versions to match
6. Verify /sprint-end populates the templates correctly
7. Verify /retrospective reads the metrics it needs

Make these the sprint documents that capture exactly what matters — nothing more, nothing less.
```
