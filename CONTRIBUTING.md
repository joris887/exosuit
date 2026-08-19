# Contributing to Exosuit

Thank you for your interest in contributing! This guide explains how to set up, test, and submit changes.

## Quick Start

```bash
# 1. Clone and enter the repo
git clone https://github.com/joris887/exosuit.git
cd exosuit

# 2. Run the hook test suite
bash .claude/hooks/tests/run-all.sh

# 3. Create a feature branch
git checkout -b feat/your-change
```

## Adding a Flow Contract to a Skill

1. Read `.claude/skills/FLOW_SPEC.md` (grammar, node types, cursor, evidence).
2. Transcribe the skill's INLINE prose 1:1 into `flow.yaml` — every gate and
   branch explicit, judgment calls documented in header comments. Do not
   redesign the flow while transcribing.
3. Anchor every node with `doc:` (exact SKILL.md line) — the validator fails
   CI on drift.
4. `bash .claude/skills/doctor/scripts/validate-flows.sh` until clean, then
   `bash .claude/skills/doctor/scripts/render-flow.sh --write` and commit the
   generated view.
5. Optional: add `graph-state.sh` cursor call-sites and `evidence:` attrs on
   mechanically checkable hard gates (see FLOW_SPEC → Gate Evidence).

## Development Environment

**Requirements:** POSIX shell, git, and a text editor. No language runtimes needed.

**Optional tools:**
- `jq` — hooks use it for JSON parsing (fall back to `sed` if absent)
- `shellcheck` — static analysis for shell scripts

## Project Structure

```
.claude/
  hooks/         Shell scripts that run on Claude Code events
  rules/         Markdown rules auto-loaded by file path matching
  skills/        Slash commands (SKILL.md + references/)
  agents/        Native agent personas (markdown with YAML frontmatter)
  prompts/       Reusable micro-components embedded by skills
  settings.json  Hook registration and framework settings
```

## How to Add a New Hook

1. Create `<hook-id>.sh` in `.claude/hooks/` (POSIX sh — `#!/bin/sh`)
2. Add the guard call near the top: `"$HOOKS_DIR/lib/hook-guard.sh" "<hook-id>" "<min-profile>" || exit 0`
3. Add rule files in `rules/` if needed (@@-delimited pattern format)
4. Register in `.claude/settings.json` and `.claude/hooks/hooks.json` (plugin mode)
5. Document in `.claude/hooks/README.md`
6. Add tests in `.claude/hooks/tests/test-<hook-id>.sh`

**Shell conventions:**
- Use `#!/bin/sh` (POSIX) for hooks, NOT `#!/bin/bash` (exceptions: `post-edit-format.sh` and `status-line.sh` which need bash arrays)
- Read JSON from stdin using `jq` with `sed` fallback — never hard-depend on `jq`
- Exit codes: `0` = allow, `2` = block
- All output on stderr (stdout reserved for JSON responses to Claude Code)

## How to Add a New Skill

1. Create `.claude/skills/<skill-name>/SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: skill-name
   version: 1.0.0
   description: One-line description
   trigger: manual
   depends-on: []
   references: []
   ---
   ```
2. Add reference files in `references/` if the skill needs supporting content
3. Add the skill to `.claude/skills/skills-registry.json`
4. Update `.claude/skills/SKILLS_INVENTORY.md`
5. See `SKILL_TEMPLATE.md` for the full format reference

**Skill conventions:**
- Keep `SKILL.md` under 150 lines (exception: orchestration skills like story-cycle)
- Individual reference files: ≤200 lines each
- Total references per skill: ≤500 lines
- Use `<HARD-GATE>` markers for mandatory checkpoints
- Use `<IF condition="...">` / `<ELSE>` for conditional behavior

## How to Add a New Rule

1. Create `.claude/rules/<name>.md` with optional path-scoping frontmatter:
   ```yaml
   ---
   paths:
     - "**/*.py"
     - "**/*.ts"
   ---
   ```
2. Rules without `paths:` load for all interactions (use sparingly)
3. Keep rules under 100 lines — they load into every matching context
4. Include the rule effectiveness tracking event emitter (see existing rules)
5. Document in `.claude/rules/CLAUDE.md`

## Pattern File Format

Hook patterns use `@@` as a delimiter:

```
# 3-field: id@@regex@@message
# 4-field: id@@regex@@message@@severity
# 5-field: id@@regex@@message@@severity@@explanation

# severity: critical | standard (default) | strict
# explanation: shown when EXOSUIT_EXPLAIN_MODE=verbose
```

## Testing

Run the full test suite:

```bash
bash .claude/hooks/tests/run-all.sh
```

Test files follow the naming convention `test-<hook-id>.sh`. Each test:
- Creates temporary files/state for setup
- Exercises the hook with crafted JSON input
- Asserts expected exit codes and output
- Cleans up all temporary state

## Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore
Scope: hook name, skill name, or component (e.g., hooks, rules, bootstrap)
```

Examples:
- `feat(hooks): add explanation mode to safety patterns`
- `fix(bootstrap): handle missing jq in stack detection`
- `docs(skills): update SKILLS_INVENTORY for v3.9`

## Pull Request Guidelines

- **Size:** ≤400 LOC (target ≤200). Larger changes should be split.
- **Description:** Explain what changed and why. Include the acceptance criteria from the story if applicable.
- **Tests:** Add or update hook tests for any hook changes. Verify all existing tests still pass.
- **Cross-platform:** Hook scripts must work on both macOS (BSD tools) and Linux (GNU tools). Use the portable patterns established in the codebase (`stat -f %m || stat -c %Y`, multiple `-e` flags for grep, etc.).

## Code of Conduct

Be respectful, constructive, and inclusive. We welcome contributions from developers of all experience levels.
