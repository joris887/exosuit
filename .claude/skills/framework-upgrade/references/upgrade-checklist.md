# Upgrade Checklist

Exhaustive list of components to compare during a framework upgrade. Use this to ensure nothing is missed.

## Critical Constraints (read first)

- [ ] **Use Bash `cp`/`printf`/`cat` for ALL `.claude/` writes** — Write/Edit tools always prompt
- [ ] **Use `git rev-parse` in settings.json** — NOT `__PROJECT_ROOT__` (may not be supported)
- [ ] **Avoid safety pattern text in Bash commands** — use Python string concatenation
- [ ] **Update settings.json BEFORE hooks.json** — prevents mid-session hook failures

## .claude/hooks/

- [ ] `pre-tool-use.sh` — Safety pattern matching
- [ ] `post-tool-use.sh` — Activity logging + test tracking
- [ ] `session-start.sh` — Environment checks
- [ ] `stop.sh` — Auto-save + completion evidence
- [ ] `user-prompt.sh` — Intent classification
- [ ] `subagent-stop.sh` — Subagent output validation
- [ ] `worktree.sh` — Worktree init/cleanup
- [ ] `post-edit-format.sh` — Auto-format after edits
- [ ] `worktree-bash-fix.sh` — Worktree directory fix
- [ ] `status-line.sh` — Status bar output
- [ ] `rules/safety.patterns` — Dangerous command patterns (MERGE with project rules)
- [ ] `rules/quality.conf` — Completion evidence rules
- [ ] `rules/intent.patterns` — Destructive request patterns
- [ ] `rules/subagent.patterns` — Subagent quality checks
- [ ] `rules/subagent.conf` — Subagent config
- [ ] `hooks.json` — Plugin distribution definitions (update LAST)
- [ ] `lib/paths.sh` — Bash path resolution
- [ ] `README.md` — Hook architecture docs
- [ ] `.claude-context.md` — Hook module context

## .claude/settings.json

- [ ] Hook commands point to shell scripts (not Python engine)
- [ ] Uses `git rev-parse --show-toplevel` pattern (not `__PROJECT_ROOT__`)
- [ ] New fields adopted (spinnerVerbs, attribution, plansDirectory)
- [ ] `statusMessage` added to hook definitions
- [ ] `once: true` on SessionStart

## .claude/agents/

- [ ] `code-reviewer.md`
- [ ] `security-analyst.md`
- [ ] `architecture-reviewer.md`
- [ ] `codebase-explorer.md`
- [ ] `spec-reviewer.md`
- [ ] `performance-engineer.md`
- [ ] `research-analyst.md`
- [ ] Any new agents in framework
- [ ] Project-specific agents preserved

## .claude/prompts/

- [ ] `README.md` — Prompt categorization
- [ ] `capture-outcome.md` — Story outcome measurement
- [ ] `confidence-gate.md`
- [ ] `context-budget.md`
- [ ] `context-prime.md`
- [ ] `discover-commands.md`
- [ ] `grep-first-explore.md`
- [ ] `quality-gate-sequence.md`
- [ ] `record-failure.md`
- [ ] `verify-clean-git-state.md`
- [ ] `wave-execution.md`
- [ ] `capture-learnings.md`
- [ ] `select-tool.md`
- [ ] `review-security.md`
- [ ] `deep-research.md`
- [ ] `explain-pattern.md`
- [ ] `suggest-tests.md`
- [ ] `source-evaluator.md`
- [ ] Any new prompts in framework

## .claude/rules/

- [ ] `code-slop.md` — Comment quality (YAML frontmatter)
- [ ] `security.md` — Security rules (MERGE: frontmatter + project sections)
- [ ] `verification.md` — Evidence protocol (MERGE: frontmatter + project sections)
- [ ] `testing.md` — Test quality (MERGE: frontmatter + project sections)
- [ ] `dependencies.md` — Dependency management (MERGE: frontmatter + project sections)
- [ ] `documentation.md` — Doc accuracy (MERGE: frontmatter + project sections)
- [ ] `edit-recovery.md` — Edit failure recovery (YAML frontmatter)
- [ ] `git.md` — Git workflow (MERGE: frontmatter + project sections)
- [ ] `research.md` — Research quality (YAML frontmatter)
- [ ] Project-specific rules preserved (e.g., swift-ui-patterns.md)
- [ ] Any new rules in framework

## .claude/skills/ (framework skills)

Core workflow: `story-cycle`, `sprint-start`, `sprint-end`, `continue`, `handoff`
Planning: `ideate`, `brainstorm`, `bootstrap`, `skill-create`
Quality: `code-quality`, `test-validator`, `security-audit`, `architecture-check`
Testing: `manual-test`, `testing-cycle`, `UAT-cycle`, `claude-sense-check`
Maintenance: `weekly-maintenance`, `retrospective`, `backlog-review`, `doctor`, `framework-upgrade`
Optimization: `optimize`, `refine-loop`
Utility: `commit`, `fix-issue`, `pr-status`, `debug-session`, `undo-work`, `parallel-work`, `skill-eval`, `research`

For each: check SKILL.md version + references/ subdirectory.

## .claude/skills/ (support files)

- [ ] `SKILLS_INVENTORY.md` — Merge (framework base + project skills)
- [ ] `SKILL_TEMPLATE.md` — Replace
- [ ] `skills-registry.json` — Merge via Python
- [ ] `SKILLS_ROADMAP.md` — Delete if exists (deprecated)

## .claude/ new directories

- [ ] `output-styles/` — Framework output formatting
- [ ] `scripts/` — Script utilities
- [ ] `keybindings.json.template` — Keyboard shortcut template
- [ ] `settings.local.json.template` — Local settings template

## .claude/commands/

- [ ] `review-pr-ci.md`
- [ ] Any new commands in framework

## Project docs

- [ ] `docs/reference/TESTING_STRATEGY.md`
- [ ] `docs/reference/MCP_INTEGRATION.md`
- [ ] `docs/reference/CODING_STANDARDS.md`
- [ ] `docs/reference/GROUND_RULES.md`
- [ ] `docs/reference/GIT_WORKFLOW.md`
- [ ] `docs/reference/WORKFLOW.md`
- [ ] `docs/context/` — template files (preserve if populated)
- [ ] `docs/plans/` — Ensure directory exists (new)
- [ ] `docs/solutions/` — Ensure directory exists
- [ ] `docs/brainstorms/` — Ensure directory exists
- [ ] `scripts/pm/` — PM scripts

## Root files

- [ ] `CLAUDE.md` — Update version, skills table, docs references
- [ ] `llms.txt` — Update stats
- [ ] `.gitignore` — Ensure new paths included
