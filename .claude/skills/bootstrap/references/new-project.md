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

```markdown
### New Project Setup

No existing codebase detected. Let's build your project from an idea.

1. **Describe your idea** — I'll ask a few questions to understand it fully
2. **I already wrote a vision** — I'll check the `vision/` folder for your notes
3. **Just build it** — Give me a one-liner and I'll make all the decisions
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

**Output:** `/discover` generates all vision documents, DECISION_LOG.md, ASSUMPTION_REGISTER.md, PRD_SUMMARY.md, BACKLOG_INDEX.md, and epic files.

See `.claude/skills/discover/SKILL.md` for the complete 7-phase flow.

**Legacy dimension references** (`references/dimensions/01-10.md`, `references/phase-1-analysis.md`, `references/discovery-engine.md`) are preserved and reused by /discover's dimension sweep phase.

## Post-Discovery: Scaffold Generation

After `/discover` completes, continue with scaffold generation:

From technology choices (now in `docs/reference/DECISION_LOG.md`), generate:
- `CLAUDE.md` — commands for chosen stack, profile, architecture overview
- `.gitignore` — stack-specific patterns
- `docs/reference/CODING_STANDARDS.md` — for chosen language(s)
- `docs/architecture/ARCHITECTURE.md` — proposed architecture
- `docs/reference/GROUND_RULES.md` — principles + No-Gos from discovery

**Profile-aware generation:**
- Lean: CLAUDE.md with commands only, ~12 core skills in table, minimal docs
- Standard: full documentation suite
- Strict: full docs + compliance structure + audit trail scaffold

Also create `docs/research/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/` with `.gitkeep`.

### Present Summary

```markdown
### Bootstrap Complete (New Project)

**Discovery mode:** [quick | guided | platform | pioneering]
**Archetype:** [primary] (+ [secondary] if hybrid)
**Scale:** [Quick Build | Standard | Platform | Pioneering]

**Generated:**
- [N] epics, [M] stories (including Phase Transition epic)
- Project scaffold: [framework] + [database] + [auth] on [hosting]
- Docs: CLAUDE.md, Architecture, Coding Standards, Ground Rules
- Discovery artifacts: DECISION_LOG.md, ASSUMPTION_REGISTER.md, project-pitch.md

**First sprint:** E01 foundation (project setup, database, auth, CI/CD)

**Next:** Review epics in `docs/reference/backlog/`, then `/sprint-start`
```
