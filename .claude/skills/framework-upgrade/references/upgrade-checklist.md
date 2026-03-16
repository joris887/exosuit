# Upgrade Checklist

Exhaustive list of components to compare during a framework upgrade. Use this to ensure nothing is missed.

## .claude/hooks/

- [ ] `pre-tool-use.sh` — Safety pattern matching
- [ ] `post-tool-use.sh` — Activity logging
- [ ] `stop.sh` — Auto-save + completion evidence validation
- [ ] `session-start.sh` — Environment checks
- [ ] `user-prompt.sh` — Intent classification
- [ ] `subagent-stop.sh` — Subagent output validation
- [ ] `worktree.sh` — Worktree init/cleanup
- [ ] `post-edit-format.sh` — Auto-format after edits
- [ ] `worktree-bash-fix.sh` — Worktree directory fix
- [ ] `status-line.sh` — Status bar output
- [ ] `hooks.json` — Plugin distribution definitions
- [ ] `rules/safety.patterns` — Dangerous command patterns
- [ ] `rules/quality.conf` — Completion evidence rules
- [ ] `rules/intent.patterns` — Destructive request patterns
- [ ] `rules/subagent.patterns` — Subagent quality checks
- [ ] `rules/subagent.conf` — Subagent configuration
- [ ] `lib/paths.sh` — Bash path resolution
- [ ] `README.md` — Hook architecture docs
- [ ] `.claude-context.md` — Hook module context

## .claude/agents/

- [ ] `code-reviewer.md`
- [ ] `security-analyst.md`
- [ ] `architecture-reviewer.md`
- [ ] `codebase-explorer.md`
- [ ] `spec-reviewer.md`
- [ ] `performance-engineer.md`
- [ ] Any new agents in framework

## .claude/prompts/

- [ ] `README.md` — Prompt categorization
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
- [ ] `explain-pattern.md`
- [ ] `suggest-tests.md`
- [ ] Any new prompts in framework

## .claude/rules/

- [ ] `code-slop.md` — Comment quality
- [ ] `security.md` — Security rules
- [ ] `verification.md` — Evidence protocol
- [ ] `testing.md` — Test quality
- [ ] `dependencies.md` — Dependency management
- [ ] `documentation.md` — Doc accuracy
- [ ] `edit-recovery.md` — Edit failure recovery
- [ ] `git.md` — Git workflow
- [ ] Any new rules in framework

## .claude/skills/ (framework skills)

Core workflow: `story-cycle`, `sprint-start`, `sprint-end`, `continue`, `handoff`
Planning: `ideate`, `brainstorm`, `bootstrap`, `skill-create`
Quality: `code-quality`, `test-validator`, `security-audit`, `architecture-check`
Testing: `manual-test`, `testing-cycle`, `UAT-cycle`, `claude-sense-check`
Maintenance: `weekly-maintenance`, `retrospective`, `backlog-review`, `doctor`, `framework-upgrade`
Utility: `commit`, `fix-issue`, `pr-status`, `debug-session`, `undo-work`, `parallel-work`, `refine-loop`, `skill-eval`

For each: check SKILL.md version + references/ subdirectory.

## .claude/skills/ (support files)

- [ ] `SKILLS_INVENTORY.md` — Regenerate completely
- [ ] `SKILL_TEMPLATE.md` — Replace
- [ ] `skills-registry.json` — Regenerate

## .claude/commands/

- [ ] `review-pr-ci.md`
- [ ] Any new commands in framework

## .claude/ config

- [ ] `settings.json` — Hook configuration (usually keep project version)
- [ ] `settings.local.json` — Always preserve (gitignored)
- [ ] `keybindings.json` — Preserve if customized

## Project docs

- [ ] `docs/reference/TESTING_STRATEGY.md`
- [ ] `docs/reference/MCP_INTEGRATION.md`
- [ ] `docs/reference/CODING_STANDARDS.md`
- [ ] `docs/reference/GROUND_RULES.md`
- [ ] `docs/reference/GIT_WORKFLOW.md`
- [ ] `docs/reference/WORKFLOW.md`
- [ ] `docs/context/` — template files (preserve if populated)
- [ ] `docs/solutions/` — Ensure directory exists
- [ ] `docs/brainstorms/` — Ensure directory exists
- [ ] `scripts/pm/` — PM scripts

## Root files

- [ ] `CLAUDE.md` — Update version, skills table, docs references
- [ ] `llms.txt` — Update stats
- [ ] `.gitignore` — Ensure new paths included
