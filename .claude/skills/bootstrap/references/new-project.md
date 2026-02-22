# New Project Setup (Path B)

Reference loaded by `/bootstrap` when no existing source files are detected.

## B1. Check for Vision Content

```bash
ls vision/ 2>/dev/null
```

**If `vision/` has content (beyond README and BRAINDUMP_PROMPT.md):** → B3 (Generate from vision)
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
5. Continue to B3

## B3. Generate from Vision

Read all files in `vision/` and generate:

1. **`docs/reference/PRD_SUMMARY.md`** — Extract requirements, goals, users, use cases
2. **`docs/architecture/ARCHITECTURE.md`** — Extract or propose architecture
3. **`docs/reference/BACKLOG_INDEX.md`** — Create epic structure
4. **`docs/reference/backlog/E01-*.md` through `E0N-*.md`** — Epic files with typed stories
5. **`CLAUDE.md`** — Fill in overview, architecture one-liner, current focus
6. **`docs/reference/CODING_STANDARDS.md`** — Fill if stack is specified in vision
7. **`.claude/rules/`** — Generate rules tailored to proposed stack
8. **`.gitignore`** — Add language-specific patterns for proposed stack

Stories should be typed (feature, infrastructure, spike, etc.) and ordered for testability.

## B4. Present Summary

```markdown
### Bootstrap Complete (New Project)

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
