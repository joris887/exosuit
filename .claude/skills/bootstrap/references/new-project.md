# New Project Setup (Path B)

Reference loaded by `/bootstrap` when no existing source files are detected.

## Flow Overview

```
Phase 0: CAPTURE → Phase 1: ANALYZE → Phase 2: DISCOVER → Phase 3: SYNTHESIZE → Phase 4: GENERATE
```

- **Fast-track:** description + "just build it" → skip to Phase 4, LLM makes all decisions
- **Guided:** full discovery with questions at each dimension → all phases
- **Braindump:** user pre-wrote vision files → skip Phase 0 questions, start Phase 1

## Phase 0: Idea Capture

### Check for Existing Vision Content

```bash
ls vision/ 2>/dev/null
```

**If `vision/` has content beyond templates** (README.md, BRAINDUMP_PROMPT.md, CLAUDE.md): Parse existing `.md` files and extract problem, users, features, technical preferences, constraints → Phase 1.

**If empty or templates only:** Present entry options.

### Entry Options

Present via **AskUserQuestion**:

```
header: "New project"
question: "No existing codebase detected. Let's build your project from an idea.
           How would you like to start?"
options:
  - label: "Describe my idea (Recommended)"
    description: "Tell me about your project in your own words. I'll ask a few
                  focused questions to understand it fully — the more detail you
                  give, the better the result."
  - label: "I already wrote a vision"
    description: "I'll check the vision/ folder for your notes and build from there.
                  Great if you've already thought things through."
  - label: "Just build it"
    description: "Give me a one-liner and I'll make all the technical decisions.
                  Fastest path to code. You'll review my choices before I start."
```

### Inline Description (Option 1)

1. Accept the user's description (any length, any format)
2. Assess which of these are addressed: problem/purpose, target users, key features, technical preferences, scale/timeline
3. Ask up to **5 focused questions** for the top gaps — adapt to what's missing:
   - Problem unclear → "What problem does this solve? Describe it as if telling a friend."
   - Users unclear → "Who will use this? Describe your typical user in one sentence."
   - Features unclear → "What are the 3 most important things it needs to do?"
   - No tech preferences → "Do you have any technology preferences, or should I choose?"
   - Scale unknown → "How many users do you expect in the first 3 months?"
4. **Stop after 5 questions maximum.** Users abandon after 5.

### Braindump File (Option 2)

Parse all `.md` files in `vision/` and extract: problem statement, target users, proposed features, technical preferences, constraints. Treat as inline description with pre-filled answers.

### Fast-Track (Option 3)

Triggered by: user says "just build it" / "fast-track" / "quick" / "skip questions", OR `$ARGUMENTS` includes `--fast`.

1. Record the raw idea
2. Mark all dimensions as "auto-decide"
3. Jump directly to Phase 4 — LLM makes all decisions with documented assumptions
4. Present summary of auto-decided choices for quick approval before generating

### Completeness Assessment

After capture, classify the idea:
- **Complete** (problem + users + features + 4 more aspects addressed) → Phase 1
- **Partial** (problem + 2-5 other aspects) → ask focused questions for top gaps → Phase 1
- **Minimal** (just a sentence or two) → ask more questions OR offer fast-track

### Output

Save to `vision/idea-capture.md`:
```yaml
---
captured: YYYY-MM-DD
mode: inline | braindump | fast-track
completeness: complete | partial | minimal
---
```
Followed by: raw input, Q&A transcript, and extracted dimension status (KNOWN/INFERRED/OPEN per dimension).

**All user-facing text must be jargon-free.** No "dimensions", "phases", "sprint", "TDD", "PR", "ORM".

## Phases 1-4: Deep Guided Elicitation (via /discover)

**After Phase 0 completes, invoke `/discover`** which replaces the legacy Phase 1-4 flow with a deeply guided, archetype-aware, research-backed elicitation system.

```
After Phase 0 (Idea Capture):
  → invoke /discover with the captured idea
  ├── If lean profile or fast-track mode: /discover --quick
  ├── Otherwise: /discover (auto-detects mode from scale classification)
  └── /discover handles:
      - Archetype + scale classification
      - Core identity elicitation (archetype-specific questions)
      - Deep dive with research checkpoints
      - Assumption surfacing and stress testing
      - Dimension completeness sweep (D04-D10)
      - Vision synthesis with user approval
      - MVP scoping + backlog generation with Phase Transition Stories
```

**Output:** `/discover` generates all vision documents, DECISION_LOG.md, ASSUMPTION_REGISTER.md, PRD_SUMMARY.md, BACKLOG_INDEX.md, epic files, AND populates all project documentation (ARCHITECTURE.md, CODING_STANDARDS.md, GROUND_RULES.md, TESTING_STRATEGY.md, docs/brain/*, CLAUDE.md) from discovery decisions in its Phase 7D step.

See `.claude/skills/discover/SKILL.md` for the complete 7-phase flow.

**Legacy dimension references** (`references/dimensions/01-10.md`, `references/phase-1-analysis.md`, `references/discovery-engine.md`) are preserved and reused by /discover's dimension sweep phase.

## Post-Discovery: Remaining Scaffold

`/discover` Phase 7D already populates all project documentation (ARCHITECTURE.md, CODING_STANDARDS.md, GROUND_RULES.md, TESTING_STRATEGY.md, docs/brain/*, CLAUDE.md, README.md) from discovery decisions. After `/discover` completes, only these remaining scaffold steps are needed:

- `.gitignore` — stack-specific patterns (from DECISION_LOG tech choices)
- Create empty directories: `docs/research/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`, `docs/plans/` with `.gitkeep`
- If strict profile: create `docs/adr/` with initial ADRs from Platform-scale discovery decisions
- Delete `scaffold/` directory if present (template-mode artifact, contents already installed or generated)

**Verify Phase 7D ran:** Check that `docs/brain/project-overview.md`, `docs/brain/tech-context.md`, `docs/architecture/ARCHITECTURE.md`, and `README.md` contain project-specific content (not template placeholders). If they're still templates, Phase 7D was skipped — re-read the `/discover` SKILL.md Phase 7D instructions and execute them now.

### Present Summary

```markdown
### Bootstrap Complete (New Project)

**Discovery mode:** [quick | guided | platform | pioneering]
**Archetype:** [primary] (+ [secondary] if hybrid)
**Scale:** [Quick Build | Standard | Platform | Pioneering]

**Generated:**
- [N] epics, [M] stories (including Phase Transition epic)
- Project scaffold: [framework] + [database] + [auth] on [hosting]
- Docs: README.md, CLAUDE.md, Architecture, Coding Standards, Ground Rules
- Discovery artifacts: DECISION_LOG.md, ASSUMPTION_REGISTER.md, project-pitch.md

**First sprint:** E01 foundation (project setup, database, auth, CI/CD)

**Next:** Review epics in `docs/reference/backlog/`, then `/sprint-start`
```
