______________________________________________________________________

## name: bootstrap description: First-run framework setup. Detects existing project stack or guides new project creation from vision/braindump. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Setting up the JD-LLM Development Framework for this project.

## Process Flow (authoritative — prose below is supporting detail)

```
START → 1. Detect Project State
  → [Source files exist?]
    → YES: Path A (Existing Repository)
      → A1-A3: Detect stack, commands, assess docs/coverage/architecture, measure codebase
        → A3.5: Generate architecture → A4: Generate config
          → A5: Run /skill-create → A5.5-A5.6: Configure hooks and rules
            → A6: Clean up → A7: Present summary → DONE
    → NO: Path B (New Project)
      → Read references/new-project.md and follow B1-B4 → DONE
```

## 1. Detect Project State

Determine which path to follow:

```bash
# Count non-framework source files
find . -type f \
  -not -path './.git/*' \
  -not -path './.claude/*' \
  -not -path './vision/*' \
  -not -path './docs/*' \
  -not -path './scripts/*' \
  -not -path './CLAUDE.md' \
  -not -path './CLAUDE.local.md*' \
  -not -path './README.md' \
  -not -path './AGENTS.md' \
  -not -path './llms.txt' \
  -not -path './install.sh' \
  -not -path './.gitignore' \
  -not -path './.gitkeep' \
  -not -name '.DS_Store' | head -20
```

**If source files exist:** → Path A (Existing Repository)
**If no source files (or only framework files):** → Path B — Read `references/new-project.md` and follow its steps.

---

## Path A: Existing Repository

### A1-A3. Detect Stack, Commands, and Measure Codebase

Read `references/stack-detection.md` for detailed detection tables and commands. This covers:
- Technology stack detection (A1)
- Command detection (A2)
- Documentation state assessment (A2.5)
- Test coverage baseline (A2.6)
- Architecture assessment (A2.7)
- Codebase metrics (A3)

### A3.5. Generate Architecture Overview

Auto-populate `docs/architecture/ARCHITECTURE.md` from code structure:

- List top-level modules and their responsibilities
- Identify module boundaries and dependencies
- Note entry points and data flow direction
- Keep it brief — a starting point for the developer to refine

### A4. Generate Configuration

Update these files with detected information:

1. **`CLAUDE.md`** — Fill in Project Overview, Commands, Architecture one-liner
2. **`docs/reference/CODING_STANDARDS.md`** — Fill in language-specific sections
3. **`docs/progress.md`** — Initialize with baseline metrics

### A5. Run /skill-create

Generate technology-specific skills for the detected stack.

### A5.5. Configure Hooks

Based on detected stack, configure hooks:

- **Formatter detected** → uncomment/configure `post-edit-format.sh` for the language
- **Linter + test runner detected** → uncomment/configure `pre-stop-quality.sh`
- **Safety hooks** → always enabled (already in settings.json)

Update `.claude/settings.json` if adding PostToolUse or Stop hooks.

### A5.6. Configure Rules

Generate path-scoped rules for detected file types:

- If detected language has specific patterns, add to existing rules or create new ones
- Ensure `.claude/rules/testing.md` paths match the project's test file patterns
- Ensure `.claude/rules/dependencies.md` paths match the project's dependency files

### A5.7. Document Quality Check

After generating ARCHITECTURE.md, dispatch a fresh sub-agent to test the document from a reader's perspective:

- **Agent type:** Explore (read-only, forked context)
- **Input:** ONLY the generated `docs/architecture/ARCHITECTURE.md` — no conversation history
- **Instructions:** "You are a new developer reading this architecture document for the first time. List: (1) What questions would you have? (2) What's ambiguous or unclear? (3) What context does this assume the reader already has? (4) What's missing that a developer would need?"

Review findings. Fix genuine gaps before presenting the summary to the user.

### A6. Clean Up

- Delete `vision/` directory (not needed for existing repos)
- Remove template placeholder comments from populated docs
- Delete any empty template sections that weren't filled

### A7. Present Summary

```markdown
### Bootstrap Complete (Existing Repository)

**Detected Stack:**
- Languages: [list]
- Package Manager: [name]
- Test Framework: [name] ([count] tests, [coverage]% coverage)
- Linter: [name]
- Formatter: [name]
- CI/CD: [provider]

**Commands Configured:**
| Operation | Command |
|-----------|---------|
| Test      | [cmd]   |
| Lint      | [cmd]   |
| Format    | [cmd]   |
| Build     | [cmd]   |

**Files Updated:**
- CLAUDE.md (project overview, commands, architecture)
- docs/reference/CODING_STANDARDS.md (language standards)
- docs/architecture/ARCHITECTURE.md (module overview)
- docs/progress.md (baseline metrics)

**Hooks Configured:**
- [list of enabled hooks]

**Technology Skills Generated:** [count]

**Next Steps:**
- Run `/ideate` to plan your next feature
- Run `/sprint-start` to begin a sprint
```

## Rules

- NEVER overwrite files that have user content (check for non-template content first)
- ALWAYS show what will be changed before writing
- ALWAYS present a summary with next steps
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
