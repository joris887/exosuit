# 8. Backlog Management & Story Templates

## Research Prompt

```
I need comprehensive deep research on backlog management and user story documentation for AI-assisted development. The goal is to create the best possible backlog index and story template that produce stories an AI can implement reliably — with clear scope, testable criteria, and no ambiguity.

Research these specific areas:

1. **Story Formats That Drive Quality Implementation**
   - User stories vs job stories vs feature specs — which produces better AI implementations?
   - BDD Given/When/Then — research on whether this format improves test-first implementation
   - Acceptance criteria formats: scenario-based vs checklist vs contract-based
   - Story sizing research — what's the optimal scope for AI implementation (LOC, files, time)?
   - INVEST criteria (Independent, Negotiable, Valuable, Estimable, Small, Testable) — which matter most for AI?
   - How Spotify, Atlassian, and Linear structure their story formats

2. **Story Mapping & Decomposition**
   - Jeff Patton's story mapping — does it produce better decompositions?
   - Vertical slicing vs horizontal slicing — research on which reduces integration risk
   - Story splitting patterns (SPIDR: Spike, Path, Interface, Data, Rules)
   - How to size stories for single-context-window AI implementation
   - Dependency modeling between stories — what format works?

3. **Backlog Organization**
   - Epic → Story hierarchy — when it helps, when it's overhead
   - Theme-based vs user-journey-based organization
   - Priority frameworks: RICE, MoSCoW, Kano — which produces best ordering for AI delivery?
   - Backlog health metrics — how to measure if a backlog is well-maintained
   - Story readiness definitions — what must be true before starting implementation?

4. **Acceptance Criteria for AI**
   - How to write AC that is machine-verifiable (command-based verification)
   - AC specificity — research on optimal detail level for AI implementation
   - Non-functional AC (performance, security, accessibility) — how to make them testable
   - AC that prevents scope creep — explicit non-goals format
   - How to specify "follows existing patterns" without listing every pattern

5. **Estimation & Forecasting**
   - Story point estimation — does it add value for AI-assisted development?
   - T-shirt sizing vs story points vs #NoEstimates — what works with AI?
   - Cycle time tracking — research on predictability with AI assistance
   - Sprint velocity with AI — how does velocity change with AI assistance?

6. **Backlog Anti-Patterns**
   - Stories that are too vague for AI to implement (common patterns)
   - Stories that are too prescriptive (specifying implementation instead of outcome)
   - Zombie stories (sitting in backlog forever) — detection and cleanup
   - Story dependencies that create blocking chains
   - "As a developer, I want to refactor..." — non-user-facing stories format

For each finding, include sources, template examples, and assessment of applicability to solo developers vs teams.

Output a structured research report with: recommended story format, backlog index structure, decomposition heuristics, and story quality checklist.
```

## Implementation Prompt

```
I have completed deep research on backlog management and story templates. The research findings are saved in docs/research/backlog-stories.md (or I will paste them below).

Your task: Update the framework's backlog index and story templates to produce the highest-quality stories for AI implementation.

**Context:** Templates live at:
- docs/reference/BACKLOG_INDEX.md (and scaffold/) — epic overview and story status
- .claude/skills/ideate/references/story-template.md — full story template
- .claude/skills/ideate/references/story-template-lightweight.md — lightweight template for small stories
- .claude/skills/ideate/assets/story-template.md — copy-paste template

They're used by /ideate for story decomposition and /story-cycle for implementation. They must:
- Produce stories that AI can implement in a single context window
- Include machine-verifiable acceptance criteria
- Support all 10 story types (Feature, Bug Fix, Refactoring, Spike, Infra, Testing, Docs, Security, Performance, Skill)
- Feed into /story-cycle's size classification (TRIVIAL/SMALL/STANDARD)

**Instructions:**
1. Read all current templates
2. Read the research findings
3. Update story template(s):
   - Story format (user story or alternative if research shows better option)
   - AC format (BDD or alternative — must be verifiable)
   - Size/complexity indicators that help /story-cycle classify correctly
   - Non-goals section (scope control)
   - Verification command (machine-executable proof of completion)
   - File hints and dependency information
4. Update BACKLOG_INDEX.md structure if research suggests improvements
5. Update /ideate skill if the story format changed
6. Update scaffold versions
7. Verify /story-cycle Phase 0 (intent decomposition) works with the new format

Make these the story templates that produce zero-ambiguity stories an AI implements correctly on the first attempt.
```
