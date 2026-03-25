# New Project Setup (Path B)

Reference loaded by `/bootstrap` when no existing source files are detected.

## B1. Check for Vision Content

```bash
ls vision/ 2>/dev/null
```

**If `vision/` has content (beyond README and BRAINDUMP_PROMPT.md):** → B2.7 (offer domain research, then B3)
**If empty:** → B2 (Guide braindump)

## B2. Guide Braindump

Present the braindump flow:

```markdown
### New Project Setup

No existing codebase detected. Let's build your project from an idea.

**Option 1 — Deep Research (recommended for complex projects):**

1. Open `vision/BRAINDUMP_PROMPT.md` — it contains a structured research prompt
2. Copy the research prompt into a Claude Project (or ChatGPT, Perplexity, etc.)
3. Fill in the `[YOUR IDEA HERE]` section with your raw idea
4. Have a research conversation — explore the problem space deeply
5. Save the structured output back to `vision/` (as .md files)
6. Run `/bootstrap` again to generate your project structure

**Option 2 — Quick Start:**

Describe your idea now and I'll ask clarifying questions to build a complete picture.
```

## B2.5. Accept Inline Braindump

If the user types their idea directly, transition to iterative questioning mode:

1. Acknowledge the idea
2. Ask 5-10 clarifying questions covering:
   - Problem statement and target users
   - Technical constraints and preferences
   - Similar products or prior art
   - Non-negotiable requirements
   - Scale and performance needs
   - Security and compliance requirements
3. After gathering answers, synthesize into a vision document
4. Save to `vision/braindump-output.md`
5. Continue to B2.7 (domain research)

## B2.7. Domain Research (Optional — Recommended for Complex Projects)

Before generating the project structure from vision, research the domain to inform the vision with current best practices and competitive landscape.

Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **STANDARD** depth:

- **Query:** Generated dynamically from the vision content. Example: "Best practices for building [type of project described in vision]"
- **Sub-questions** (generated from vision content):
  1. "What similar tools/projects exist for [domain]? What do they do well/poorly?"
  2. "What are current best practices for [domain/technology mentioned in vision]?"
  3. "What common pitfalls should be avoided when building [type of project]?"
  4. "What architecture patterns are recommended for [type of project]?"
- **Output format:** `decision-input` (compact, feeds vision generation)

**Present findings to user before generating project structure.** The user may have insights to add, or findings may change the vision direction.

**Skip when:** User explicitly says "skip research" or "I know what I want", or when the project is simple enough that domain research adds no value (e.g., a basic CRUD app with well-known patterns).

**Persistence:** Save research findings to `vision/domain-research.md` so they're available for B3 generation and future reference.

## B3. Generate from Vision

Read all files in `vision/` (including `domain-research.md` if it exists from B2.7) and generate:

1. **`docs/reference/PRD_SUMMARY.md`** — Extract requirements, goals, users, use cases
2. **`docs/architecture/ARCHITECTURE.md`** — Extract or propose architecture
3. **`docs/reference/BACKLOG_INDEX.md`** — Create epic structure
4. **`docs/reference/backlog/E01-*.md` through `E0N-*.md`** — Epic files with typed stories
5. **`CLAUDE.md`** — Fill in overview, architecture one-liner, current focus
6. **`docs/reference/CODING_STANDARDS.md`** — Fill if stack is specified in vision
7. **`.claude/rules/`** — Generate rules tailored to proposed stack
8. **`.gitignore`** — Add language-specific patterns for proposed stack

Stories should be typed (feature, infrastructure, spike, etc.) and ordered for testability.

Also create `docs/research/`, `docs/solutions/`, and `docs/brainstorms/` directories with `.gitkeep` files for future use by `/research`, `/story-cycle`, and `/brainstorm` skills.

## B3.5. PRD Quality Gate

After generating PRD_SUMMARY.md, validate it for common requirement smells:

| Smell | Detection | Action |
|-------|-----------|--------|
| **Vague terms** | "fast", "user-friendly", "intuitive", "robust", "scalable", "high availability" without numbers | Replace with measurable threshold |
| **Missing error handling** | Requirements describe happy path only, no WHEN [error] criteria | Add error and edge case acceptance criteria |
| **Thin acceptance criteria** | Requirement has < 3 acceptance criteria | Expand — aim for 3-7 per requirement |
| **Premature solutioning** | Requirements specify UI elements, specific libraries, or implementation details | Rewrite as outcome-oriented behavior |
| **Empty NFR section** | NFRs omitted despite project type implying them (e.g., web app with no performance/accessibility) | Add applicable NFR categories with measurable defaults |
| **No non-goals** | Section 7 is empty | Add at least 2 explicit non-goals based on what the vision does NOT mention |

Fix any smells found before presenting to the user. Quality requirements prevent wasted implementation cycles — fixing them now is 10x cheaper than fixing wrong implementations later.

## B4. Present Summary

```markdown
### Bootstrap Complete (New Project)

**Domain Research:** [summary of key findings from B2.7, or "Skipped" if not run]

**Generated from vision:**
- PRD Summary: docs/reference/PRD_SUMMARY.md
- Architecture: docs/architecture/ARCHITECTURE.md
- Backlog: [N] epics, [M] stories

**Epic Structure:**
| Epic | Stories | Description |
|------|---------|-------------|
| E01  | [count] | [name]      |
| ...  | ...     | ...         |

**Next Steps:**
- Review generated epics in `docs/reference/backlog/`
- Run `/sprint-start` to begin your first sprint
- First sprint should be E01 (foundation/infrastructure)
```
