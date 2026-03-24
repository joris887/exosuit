# 8. Backlog Management & Story Templates

## Research Prompt

```
I need deep research on backlog management and user story documentation for AI-assisted development. The goal is to determine the best possible approach for backlog organization and story templates that produce stories an AI can implement reliably — with clear scope, testable criteria, and no ambiguity.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Stories and backlogs:
- Are created by /ideate (story decomposition from PRD or user ideas)
- Are implemented by /story-cycle (which classifies stories as TRIVIAL/SMALL/STANDARD and adjusts workflow depth)
- Must support 10 story types: Feature, Bug Fix, Refactoring, Spike, Infra, Testing, Docs, Security, Performance, Skill
- Must produce stories implementable in a single AI context window
- Acceptance criteria must be machine-verifiable (the AI runs a command to prove completion)
The template must work for solo developers and teams.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Story Formats That Drive Quality Implementation** — User stories vs job stories vs feature specs. BDD Given/When/Then. Acceptance criteria formats. Optimal story scope for AI implementation. INVEST criteria — which matter most for AI? How Spotify, Atlassian, Linear structure stories.

2. **Story Mapping & Decomposition** — Jeff Patton's story mapping. Vertical vs horizontal slicing. SPIDR splitting patterns. Sizing stories for single-context-window AI implementation. Dependency modeling.

3. **Backlog Organization** — Epic → Story hierarchy. Priority frameworks (RICE, MoSCoW, Kano). Backlog health metrics. Story readiness definitions.

4. **Acceptance Criteria for AI** — Machine-verifiable AC (command-based verification). Optimal specificity level. Non-functional AC. Scope control through explicit non-goals. "Follow existing patterns" without listing every pattern.

5. **Estimation & Forecasting** — Story points vs T-shirt sizing vs #NoEstimates with AI. Cycle time tracking. How AI changes velocity.

6. **Backlog Anti-Patterns** — Too vague for AI. Too prescriptive (specifying implementation). Zombie stories. Blocking dependency chains. Non-user-facing story formats.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended story format** — propose the specific fields, structure, and AC format that produces highest AI implementation success, with justification
4. **Recommended backlog index structure** — how to organize epics and stories
5. **Recommended decomposition heuristics** — how to split work for AI implementation
6. Story quality checklist
7. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on backlog management and story templates. The research findings are saved in docs/research/backlog-stories.md (or I will paste them below).

Your task: Update the framework's backlog index and story templates to produce the highest-quality stories for AI implementation, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations:
  - docs/reference/BACKLOG_INDEX.md (and scaffold/) — epic overview and story status
  - .claude/skills/ideate/references/story-template.md — full story template
  - .claude/skills/ideate/references/story-template-lightweight.md — lightweight template
  - .claude/skills/ideate/assets/story-template.md — copy-paste template
- Must produce stories implementable in a single AI context window
- Must include machine-verifiable acceptance criteria
- Must support all 10 story types (Feature, Bug Fix, Refactoring, Spike, Infra, Testing, Docs, Security, Performance, Skill)
- Must feed into /story-cycle's size classification (TRIVIAL/SMALL/STANDARD)
- Created by /ideate, consumed by /story-cycle

**Instructions:**
1. Read all current templates listed above
2. Read the research findings thoroughly
3. Implement the story format, backlog structure, and AC format the research recommends — trust the research over your own defaults
4. Update scaffold versions to match
5. Verify /ideate skill works with the new story format
6. Verify /story-cycle Phase 0 (intent decomposition) works with the new format

**Outcome criteria (how to evaluate the result):**
- Stories are zero-ambiguity — an AI implements them correctly on the first attempt
- Acceptance criteria are machine-verifiable — the AI can run a command to prove completion
- Story scope matches what fits in a single context window
- The format works equally well for a new feature, a bug fix, and a refactoring
- /story-cycle correctly classifies stories by size from the story's metadata
```
