---
name: bootstrap
version: 2.9.0
description: First-run framework setup. Detects existing project stack or guides new project creation from vision/braindump.
trigger: manual
depends-on: [skill-create]
references: [references/stack-detection.md, references/new-project.md, references/accuracy-safeguards.md, references/coverage-assessment.md, references/quality-tooling.md, references/readiness-report.md, references/foundation-backlog.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## bootstrap

Setting up the JD-LLM Development Framework for this project.

## Process Flow (authoritative — prose below is supporting detail)

```
START → 0. Detect Installation Mode
  → [Plugin mode?]
    → YES: CLAUDE_PLUGIN_ROOT is set, skip .claude/ setup
    → NO: Template mode, .claude/ already in project
  → 1. Detect Project State
    → [Source files exist?]
      → YES: Path A (Existing Repository)
        → A1-A3: Detect stack, commands, assess docs/coverage/architecture, measure codebase
          → A2.8: Offer quality tooling installation
            → A3.5: Generate architecture → A3.6: Establish ground rules
              → A4: Generate config → A5: Run /skill-create → A5.5-A5.6: Configure hooks and rules
                → A5.8: Framework Readiness Report → A5.9: Generate foundation backlog
                  → A6: Clean up → A7: Present summary → DONE
      → NO: Path B (New Project)
        → Read references/new-project.md and follow B1-B4 → DONE
```

## 0. Detect Installation Mode

Determine whether the framework is running as a **plugin** or as a **template**:

```bash
# Plugin mode: CLAUDE_PLUGIN_ROOT is set by Claude Code
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    echo "Plugin mode: core at $CLAUDE_PLUGIN_ROOT"
else
    echo "Template mode: core at .claude/"
fi
```

**Plugin mode** (`CLAUDE_PLUGIN_ROOT` set): Core framework (hooks, skills, agents, rules, prompts) is installed as a Claude Code plugin. Only scaffold files (docs/, vision/, CLAUDE.md) need to be in the project.

**Template mode** (default): Full framework cloned into the project. Both core and scaffold files are in the project directory.

This affects Path A steps A5.5 (hook configuration) and A5.6 (rule configuration) — in plugin mode, hook and rule configuration is managed by the plugin, not project-level settings.json.

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

Run `scripts/detect-stack.sh` — execute directly, do NOT read source first.

Read `references/stack-detection.md` for detailed detection tables and commands. This covers:
- Technology stack detection (A1)
- Command detection (A2)
- Documentation state assessment (A2.5)
- **Test coverage assessment (A2.6)** — Read `references/coverage-assessment.md` for the full flow: detect coverage tool → offer installation if missing → run coverage → record baseline → flag zero-coverage areas. This data feeds into the Readiness Report (A5.8).
- Architecture assessment (A2.7)
- Codebase metrics (A3)

### A2.8. Offer Quality Tooling Installation

Read `references/quality-tooling.md` for the complete flow. After detecting the stack and its available tools, present missing-but-recommended quality tools (formatter, linter, coverage, type checker) with correct install commands for the detected package manager. The user can select which tools to install or decline all. Declined tools are recorded for the Readiness Report and foundation backlog.

**For stacks with built-in tools** (Go, Rust, Dart): note as available, skip the offer for those categories.

### A3.5. Generate Architecture Overview

Auto-populate `docs/architecture/ARCHITECTURE.md` from code structure. Apply accuracy safeguards from `references/accuracy-safeguards.md` — every claim must reference actual files:

- List top-level modules and their responsibilities
- Identify module boundaries and dependencies
- Note entry points and data flow direction
- Keep it brief — a starting point for the developer to refine

### A3.55. Generate Project Context Knowledge Base

Populate `docs/context/` files by analyzing the codebase. Apply accuracy safeguards from `references/accuracy-safeguards.md`:

- `project-overview.md` — What the project does, who it's for, core workflows
- `tech-context.md` — Stack, key libraries, API contracts, data layer
- `system-patterns.md` — Design patterns, conventions, error handling
- `project-structure.md` — Directory layout, module responsibilities, data flow
- `product-context.md` — Domain terminology, user personas, feature areas

Each file: ≤200 lines, evidence-based claims only, update YAML frontmatter timestamps.

### A3.6. Establish Project Ground Rules

Prompt the user for 3-7 non-negotiable architectural principles. Populate `docs/reference/GROUND_RULES.md`:

- Ask: "What architectural rules should NEVER be broken in this project?" Give examples (library-first, no ORM, max N services, composition over inheritance, etc.)
- For each principle, classify as **MUST** (non-negotiable) or **SHOULD** (strong preference, exceptions require justification)
- If the user has no strong preferences, suggest 3-5 principles based on detected stack and architecture
- The ground rules are checked during `/story-cycle` planning (Phase 1e) and `/sprint-end` quality gates

### A3.6. Detect Default Branch

Detect the repository's default branch name and store it in CLAUDE.md so all skills can reference it without guessing:

```bash
# Try remote HEAD first (most reliable for repos with a remote)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

if [ -z "$DEFAULT_BRANCH" ]; then
    # No remote HEAD — check common branch names
    for branch in main master develop; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            DEFAULT_BRANCH="$branch"
            break
        fi
    done
fi

# Final fallback: use current branch
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH=$(git branch --show-current)
fi

echo "Default branch: $DEFAULT_BRANCH"
```

Update CLAUDE.md's Git Workflow section: replace the `<!-- Detected by /bootstrap -->` comment with the detected branch name.

### A4. Generate Configuration

Update these files with detected information:

1. **`CLAUDE.md`** — Fill in Project Overview, Commands, Architecture one-liner, **Default branch** (from A3.6)
2. **`docs/reference/CODING_STANDARDS.md`** — Fill in language-specific sections
3. **`docs/progress.md`** — Initialize with baseline metrics

### A4.5. Detect MCP Servers (Optional)

Check if any MCP servers are available in the Claude Code environment. If detected, note them in `CLAUDE.md` under a `## MCP Servers` section so skills can conditionally leverage them. See `docs/reference/MCP_INTEGRATION.md` for server categories and integration guidance.

If no MCP servers are detected, skip this step — all skills function without them.

### A5. Run /skill-create

Generate technology-specific skills for the detected stack.

### A5.5. Configure Hooks

Based on detected stack, configure hooks:

- **Formatter detected** → uncomment/configure `post-edit-format.sh` for the language
- **Linter + test runner detected** → configure quality rules in `.claude/hooks/rules/quality.yaml`
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

### A5.8. Framework Readiness Report

Read `references/readiness-report.md` for the complete check definitions and classification rules.

Using data collected in earlier steps (A1-A3, A2.6, A2.8, A3.6, A4, A5.5), assess each framework principle against the project's actual state. For each principle, classify as `✓ Ready`, `⚠️ Risk`, or `✗ Missing` with a brief explanation.

**Output:**
1. Display the readiness report table in the A7 summary
2. Save to `docs/reference/READINESS_REPORT.md`
3. Pass Risk and Missing items to A5.9 for foundation story generation

### A5.9. Generate Foundation Backlog & Initialize BACKLOG_INDEX.md

Read `references/foundation-backlog.md` for story generation templates.

Based on the Readiness Report (A5.8), auto-generate foundation stories for Risk and Missing items. Each story has a type, priority, description, and acceptance criteria. Present to the user for review — they can accept, modify, or discard stories. Write accepted stories to `docs/reference/backlog/E00-foundation.md`.

**Initialize BACKLOG_INDEX.md** — remove template comments and populate with actual content:

```markdown
# Backlog Index

**Last Updated:** {date}

## Status Summary

| Epic | Total | Done | In Progress | TODO |
|------|-------|------|-------------|------|
| E00-foundation | {n} | 0 | 0 | {n} |

## Current Focus

Foundation work: infrastructure and tooling gaps identified by the Framework Readiness Report.

## Epic Files

- @docs/reference/backlog/E00-foundation.md — Foundation (infrastructure + tooling)

## Story ID → Epic Mapping

| Story Range | Epic File |
|-------------|-----------|
| E00-S01 — E00-S{nn} | E00-foundation.md |

## Next Steps

- Run `/sprint-start` to begin foundation work
- Run `/ideate` to generate feature stories after foundation is complete
```

If no foundation stories were generated (all principles Ready), still initialize BACKLOG_INDEX.md with an empty status table and point the user to `/ideate`.

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

**Framework Readiness Report:**
| Principle | Status | Detail |
|-----------|--------|--------|
| [principle] | [✓/⚠️/✗] | [explanation] |
| ... | ... | ... |

**Summary:** [N]/10 ready, [N] at risk, [N] missing

**Foundation Backlog:** [N] stories generated in E00-foundation (or "No gaps found — project is ready")

**Files Updated:**
- CLAUDE.md (project overview, commands, architecture)
- docs/reference/CODING_STANDARDS.md (language standards)
- docs/architecture/ARCHITECTURE.md (module overview)
- docs/reference/READINESS_REPORT.md (principle assessment)
- docs/reference/backlog/E00-foundation.md (if gaps found)
- docs/reference/BACKLOG_INDEX.md (initialized)
- docs/progress.md (baseline metrics)

**Hooks Configured:**
- [list of enabled hooks]

**Technology Skills Generated:** [count]

**Next Steps:**
- Foundation work needed? → Run `/sprint-start` to begin with E00-foundation stories
- No foundation work? → Run `/ideate` to plan your next feature, then `/sprint-start`
```

## Graceful Degradation

| Dependency       | If Missing                                              |
|------------------|---------------------------------------------------------|
| Package manager  | Skip dependency analysis, note "manual setup required"  |
| Formatter        | Offer installation (A2.8) → if declined, skip hook config, note in summary and Readiness Report |
| Test runner      | Record "N/A" for test baseline, flag TDD-first as Missing in Readiness Report |
| Coverage tool    | Offer installation → if declined, record "N/A — user declined", flag TDD-first as Risk |

## Rules

- NEVER overwrite files that have user content (check for non-template content first)
- ALWAYS show what will be changed before writing
- ALWAYS present a summary with next steps
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
