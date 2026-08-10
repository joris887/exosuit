# Changelog

All notable changes to the Exosuit framework. Used by `/framework-upgrade` for targeted version upgrades.

## Format

Each version entry lists:
- **Files changed:** Exact paths of CORE files that changed
- **Files added:** New CORE files introduced
- **Files removed:** CORE files removed
- **Project file changes:** Instructions for updating PROJECT files (if needed)
- **Breaking changes:** Changes that require manual intervention

---

## [5.0.1] - 2026-08-10

### Summary
Cross-platform install. Windows gets a first-class one-liner via a new `install.ps1`
wrapper that runs the canonical `install.sh` through Git Bash — no duplicated install
logic. The README install snippet no longer errors when pasted into stock macOS zsh
(the `#` comment line inside the copyable block was executed by zsh, whose
`interactivecomments` option is off by default, producing `zsh: missing end of string`).
Found during open-source flow testing (T06-001, T06-002).

### Fixed
- `status-line.sh` rendered `detached*+` in any directory without a git repo (every
  git call fails outside a repo and each failure was misread as detached/dirty/staged);
  now shows a dim `no git`. A genuinely detached HEAD also now shows `detached` —
  previously the branch segment rendered empty (`--show-current` exits 0 with no
  output on detached HEAD, so the fallback never fired).

### Files added
- `install.ps1` — Windows wrapper: locates Git Bash, fetches and runs `install.sh`
- `.claude/hooks/tests/test-status-line.sh` — git state rendering suite (non-git,
  clean, dirty, staged, detached)

### Files changed
- `install.sh` — usage header only (documents `-fsSL` and the Windows wrapper)
- `README.md` — Quick Start: comment moved out of copyable block, `curl -sL` → `-fsSL`,
  Windows PowerShell one-liner added; "clone and install locally" alternative removed
  (the clone-as-project variant left framework repo files — LICENSE, CHANGELOG, core/,
  assets/ — in user projects; the installer + `/bootstrap` empty-project detection is
  the single supported path for new projects)
- `docs/GETTING_STARTED.md` — same install-block update; clone-for-new-project
  replaced with "run the installer in an empty folder"
- Starting-text pass (README, GETTING_STARTED, quickstart skill, installer banner):
  em-dashes removed from prose (kept only as structural separators in diagrams and
  table placeholders); "Your First Session" now tells users the discovery interview
  is meant to take time (an hour or more for new projects); the `/discover` example
  is a startup idea (driveway-parking marketplace) instead of a tech spec, with
  archetype and questions matched; `/build` examples now use plain product ideas
- `docs/FRAMEWORK_REFERENCE.md` — documents `install.ps1`
- `.claude/skills/uninstall/SKILL.md` — re-install snippet updated

### Breaking changes
None.

---

## [5.0.0] - 2026-08-05

### Summary
The framework is now called **Exosuit**. The JD-LLM Development Framework name is retired
everywhere: repository, plugin, marketplace, environment variables, and all documentation.
No workflow, skill, hook, or rule behavior changes — this release is the rebrand only.
The major version bump reflects the breaking rename of the plugin identifier and the
`JD_*` environment variable prefix.

### Changed
- Repository renamed to `joris887/exosuit` — GitHub redirects the old
  `joris887/JD-LLM-Development_framework` URLs and git remotes automatically
- Plugin name `jd-llm-development-framework` → `exosuit`; marketplace name
  `jd-llm-framework` → `exosuit`
- All `JD_*` environment variables renamed to `EXOSUIT_*`: `EXOSUIT_HOOK_PROFILE`,
  `EXOSUIT_PROJECT_PROFILE`, `EXOSUIT_DISABLED_HOOKS`, `EXOSUIT_STOP_MAX_ITERATIONS`,
  `EXOSUIT_EXPLAIN_MODE`, `EXOSUIT_FRAMEWORK_REPO`
- `/bootstrap` README detection now matches both "Exosuit" and the legacy
  "JD-LLM Development Framework" string, so pre-5.0 installs are still recognized
- All prose, banners, output-style name, and doc references updated to Exosuit

### Project File Changes
- If your shell profile, CI config, or `.claude/settings.json` sets any `JD_*` variable,
  rename it to the `EXOSUIT_*` equivalent — the old names are no longer read
- If installed as a plugin: remove `jd-llm-development-framework`, then install `exosuit`
  from the `exosuit` marketplace
- Git remotes pointing at the old repo URL keep working via GitHub redirect, but update
  them anyway: `git remote set-url <name> https://github.com/joris887/exosuit.git`

### Breaking changes
- `JD_*` environment variables are no longer read — rename to `EXOSUIT_*` (see above)
- Plugin/marketplace identifiers changed — reinstall under the new name

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude-plugin/marketplace.json (CHANGED)
  .claude-plugin/plugin.json (CHANGED)
  .claude/hooks/CLAUDE.md (CHANGED)
  .claude/hooks/README.md (CHANGED)
  .claude/hooks/lib/hook-guard.sh (CHANGED)
  .claude/hooks/pre-tool-use.sh (CHANGED)
  .claude/hooks/rules/quality.conf (CHANGED)
  .claude/hooks/rules/safety.patterns (CHANGED)
  .claude/hooks/stop.sh (CHANGED)
  .claude/hooks/tests/test-hook-guard.sh (CHANGED)
  .claude/hooks/tests/test-pre-tool-use.sh (CHANGED)
  .claude/hooks/tests/test-user-prompt.sh (CHANGED)
  .claude/output-styles/framework.md (CHANGED)
  .claude/settings.local.json.template (CHANGED)
  .claude/skills/SKILLS_INVENTORY.md (CHANGED)
  .claude/skills/bootstrap/SKILL.md (CHANGED)
  .claude/skills/doctor/SKILL.md (CHANGED)
  .claude/skills/framework-upgrade/SKILL.md (CHANGED)
  .claude/skills/quickstart/SKILL.md (CHANGED)
  .claude/skills/skills-registry.json (CHANGED)
  .claude/skills/uninstall/SKILL.md (CHANGED)
  .gitignore.framework (CHANGED)
  CHANGELOG.md (CHANGED)
  CONTRIBUTING.md (CHANGED)
  README.md (CHANGED)
  core/package.sh (CHANGED)
  docs/FRAMEWORK_REFERENCE.md (CHANGED)
  docs/GETTING_STARTED.md (CHANGED)
  docs/reference/TEAM_WORKFLOW.md (CHANGED)
  install.sh (CHANGED)
  llms.txt (CHANGED)
  scaffold/docs/reference/TEAM_WORKFLOW.md (CHANGED)
  scaffold/llms.txt (CHANGED)

CORE_MERGE:
  CLAUDE.md (Skills section header now "Exosuit v5.0"; preserve all
             project-specific sections)
  .claude/settings.json (env var names JD_* → EXOSUIT_* in the env block;
             preserve project-specific hooks and permissions)

PROJECT_UPDATE_INSTRUCTIONS:
  - Rename any JD_* environment variable the project sets (shell profile, CI,
    .claude/settings.json, .claude/settings.local.json) to EXOSUIT_*.
  - Update git remotes to https://github.com/joris887/exosuit.git (old URLs
    redirect, so this is not urgent).
  - If the project README references the framework by its old name, update the
    mention — /bootstrap recognizes both names, so nothing breaks either way.
```

---

## [4.2.0] - 2026-07-26

### Summary
Story sizing now follows **conceptual cohesion, not file count**. The previous ceiling — "more than
5 files, must split" — was a proxy for context-window limits that no longer bind at current model
context sizes, and it forced coherent mechanisms to be split into pieces that produced broken
intermediate states. Adds `LARGE` and `XL` sizes, replaces the file-count threshold with a cohesion
test, and introduces `docs/reference/STORY_SIZING.md` as a project-level deviation point.

### Added
- `scaffold/docs/reference/STORY_SIZING.md` — project sizing policy. Deliberately thin: it states
  the principle and points at the canonical table rather than restating it, so the two cannot drift.
- `LARGE` and `XL` sizes across the size enum, workflow-depth table, and risk matrix

### Changed
- `.claude/skills/ideate/references/story-template.md` — Size Classification rewritten around a
  cohesion test with worked examples; `Too large | >5 files` row replaced by a `Bundle` row
  (unrelated topics, split by topic); AC guidance now scales with size; affected-files cap removed;
  DoR gains a cohesion check
- `.claude/skills/story-cycle/SKILL.md` — size→workflow table and size×risk matrix extended with
  LARGE and XL rows; explicit instruction not to split on file count
- `.claude/skills/ideate/SKILL.md` — size enum, DoR checklist, affected-files guidance
- `.claude/skills/backlog-review/SKILL.md` — DoR splitting criterion now topic-based, not file-count;
  cycle-time metrics cover all five sizes
- `.claude/agents/spec-reviewer.md` — size enum in the DoR check
- `CLAUDE.md`, `scaffold/docs/reference/CLAUDE.md` — reference the new sizing file

### Project File Changes
- Existing projects: `docs/reference/STORY_SIZING.md` is new and optional. Without it, the framework
  default applies. Existing stories keep their sizes — `LARGE` and `XL` are additive.
- Stories previously split to satisfy the 5-file rule may now be worth recombining, but nothing
  requires it.

### Breaking changes
None. The enum is extended, not redefined; TRIVIAL, SMALL, and STANDARD keep their meaning.

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/ideate/references/story-template.md (CHANGED)
  .claude/skills/ideate/SKILL.md (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/backlog-review/SKILL.md (CHANGED)
  .claude/agents/spec-reviewer.md (CHANGED)
  scaffold/docs/reference/STORY_SIZING.md (NEW)
  scaffold/docs/reference/CLAUDE.md (CHANGED)
  docs/FRAMEWORK_REFERENCE.md (CHANGED)
  CHANGELOG.md (CHANGED)

CORE_MERGE:
  CLAUDE.md (Important Files section — add the STORY_SIZING.md line; preserve
             all project-specific sections: Project Overview, Tech Stack,
             Critical Rules, Commands, Architecture, Current Focus)

PROJECT_UPDATE_INSTRUCTIONS:
  - Copy scaffold/docs/reference/STORY_SIZING.md to docs/reference/STORY_SIZING.md.
    It is optional — without it the framework default applies. Leave the
    "Project Deviations" section empty unless the project genuinely differs.
  - If the project ALREADY has a docs/reference/STORY_SIZING.md that restates a
    full size table (written to override the pre-4.2.0 file-count rule), replace it
    with the scaffold version. That override is now redundant, and keeping a second
    copy of the table is how the two silently drift apart. Carry over only genuine
    project deviations into the "Project Deviations" section.
  - Add to the CLAUDE.md Important Files list:
    - `docs/reference/STORY_SIZING.md` — Project sizing policy (sizing is by cohesion, not file count)
  - Existing stories need no change. LARGE and XL are additive; TRIVIAL, SMALL,
    and STANDARD keep their exact meaning.
  - Stories previously split only to satisfy the 5-file rule may now be worth
    recombining. This is optional and should be judged per story against the
    cohesion test, not applied in bulk.
```

---

## [4.1.1] - 2026-07-26

### Summary
Stop-hook noise reduction. The completion-evidence gate and debug audit fired constantly on sessions
they had no business inspecting — documentation work, planning sessions, and repositories with no
test runner at all. Both checks are now gated on actual source-file changes, the completion regex
requires a subject instead of matching bare prose, and the TODO/FIXME pattern is opt-in. Also fixes
`.gitignore.framework` missing OS-junk patterns, which made `test-install.sh` fail in every
installed project while passing in the framework repo.

### Changed
- `.claude/hooks/stop.sh` — added `changed_source_files()` and `has_test_suite()` guards; both the
  debug audit and the evidence gate now exit early unless the session changed a source file; the
  debug audit scans only source files instead of the entire diff
- `.claude/hooks/rules/quality.conf` — `completion_regex` now requires a subject
  ("implementation is complete") rather than matching the bare word "complete" anywhere in prose;
  added `source_extensions` key; `max_iterations` 5 → 3
- `.claude/hooks/rules/debug.patterns` — `todo-fixme-hack` commented out by default (noisiest
  pattern in the set; TODO markers in real code are usually deliberate)
- `.claude/hooks/pre-read-check.sh` — minimum profile raised `standard` → `strict`; it fired on
  every Read to match a path regex and never blocked anything
- `.claude/hooks/tests/test-stop.sh` — rewritten to run against isolated temp git repos instead of
  the live working tree; 4 original cases retained, 5 regression cases added
- `.claude/hooks/README.md` — documented the noise-control guards and the profile change
- `.gitignore.framework` — added `.DS_Store` and `Thumbs.db`

### Project File Changes
- Existing projects: re-run `install.sh` or copy the four changed hook files into `.claude/hooks/`.
  No configuration changes required — the new guards are self-activating.
- Projects that *want* TODO/FIXME flagged can uncomment `todo-fixme-hack` in `rules/debug.patterns`.
- Projects on the `strict` profile keep `pre-read-check` behaviour unchanged.

### Breaking changes
None. All changes reduce hook firing; no previously-passing session will newly fail.

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/hooks/stop.sh (CHANGED)
  .claude/hooks/pre-read-check.sh (CHANGED)
  .claude/hooks/rules/quality.conf (CHANGED)
  .claude/hooks/rules/debug.patterns (CHANGED)
  .claude/hooks/tests/test-stop.sh (CHANGED)
  .claude/hooks/README.md (CHANGED)
  .gitignore.framework (CHANGED)
  CHANGELOG.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - No action required. The new stop-hook guards are self-activating: both the debug audit
    and the completion-evidence gate now skip sessions that changed no source files.
  - Projects that want TODO/FIXME flagged as ship-blockers should uncomment `todo-fixme-hack`
    in `.claude/hooks/rules/debug.patterns` after upgrading.
  - Projects relying on sensitive-file read warnings must set EXOSUIT_HOOK_PROFILE=strict, or set
    the project profile to strict — `pre-read-check` no longer runs at the standard profile.
  - Append `.DS_Store` and `Thumbs.db` to the project `.gitignore` if not already present;
    re-running install.sh does this automatically.
```

---

## [4.1.0] - 2026-04-03

### Summary
Deep guided elicitation system: `/discover` skill with archetype-aware, multi-phase, research-backed discovery. 11 project archetypes with tailored question banks. 4 discovery modes (Quick/Guided/Platform/Pioneering). Assumption tracking with DECISION_LOG and ASSUMPTION_REGISTER. Phase Transition Stories for infinite build→review→discover→build cycle. `/phase-review` skill for structured post-phase evaluation.

### Added
- `.claude/skills/discover/SKILL.md` — 7-phase discovery skill with 4 mode branches
- `.claude/skills/discover/references/scale-guide.md` — scale classification + archetype cards
- `.claude/skills/discover/references/question-scaffolding.md` — 6 scaffolding rules for questions
- `.claude/skills/discover/references/dimension-sweep.md` — D04-D10 sweep with archetype overlays
- `.claude/skills/discover/references/research-protocols.md` — per-archetype research queries
- `.claude/skills/discover/references/engineering-by-archetype.md` — testing + AC strategies per archetype
- `.claude/skills/discover/references/phase-transition-template.md` — E0N-REVIEW story templates
- `.claude/skills/discover/references/archetypes/*.md` — 11 archetype question bank files
- `.claude/skills/discover/assets/decision-log.md` — DECISION_LOG template
- `.claude/skills/discover/assets/assumption-register.md` — ASSUMPTION_REGISTER template
- `.claude/skills/discover/assets/phase-walkthrough.md` — phase walkthrough review template
- `.claude/skills/phase-review/SKILL.md` — phase transition review skill
- "Review" story type in story-cycle for Phase Transition Stories

### Changed
- `.claude/skills/bootstrap/SKILL.md` — Path B now invokes /discover instead of legacy Phases 1-4
- `.claude/skills/bootstrap/references/new-project.md` — delegates Phases 1-4 to /discover
- `.claude/skills/ideate/SKILL.md` — added discovery-state pre-flight (Step 0)
- `.claude/skills/story-cycle/SKILL.md` — added discovery context loading (Phase 0b.5) + Review story type
- `.claude/skills/build/SKILL.md` — added retroactive discovery capture
- `.claude/skills/ideate/references/story-template.md` — added Relevant Decisions, Assumptions, No-Gos fields
- `.claude/skills/ideate/references/story-template-lightweight.md` — added Relevant Decisions, No-Gos fields
- `.claude/skills/skills-registry.json` — added discover + phase-review entries
- `.claude/skills/SKILLS_INVENTORY.md` — added discover + phase-review to inventory, updated workflow, added Review type
- `CLAUDE.md` — added /discover and /phase-review to skill table, version bump to 4.1

### Project File Changes
- New projects using Path B will now go through /discover instead of the legacy dimension discovery
- Existing projects: no changes required. /discover is opt-in via manual invocation.
- Story templates now include optional Decisions/Assumptions/No-Gos sections (omit if no discovery was run)

---

## [4.0.0] - 2026-03-30

### Summary
Open source readiness: critical bug fixes (macOS md5sum, BSD grep Unicode, plugin mode security, registry gaps), consistency fixes (version sync, gitignore, dead code removal), objective readiness gate (replaces subjective confidence scoring), explanation mode for hooks (WHY/INSTEAD for beginners), configurable stop iteration limit, quickstart as default entry point, CONTRIBUTING.md, CHANGELOG audit.

### Added
- `CONTRIBUTING.md` -- open source contribution guide
- Explanation mode (`EXOSUIT_EXPLAIN_MODE=off|brief|verbose`) for hook messages with WHY/INSTEAD explanations
- `EXOSUIT_STOP_MAX_ITERATIONS` env var to override stop hook safety valve
- First-run detection in session-start.sh (suggests `/quickstart`)

### Changed
- `install.sh` -- post-install message now directs to `/quickstart` instead of `/bootstrap`
- `.claude/prompts/confidence-gate.md` -- replaced subjective 5-dimension scoring (0-100) with 5 objective pre-condition checks (PASS/FAIL)
- `.claude/skills/story-cycle/SKILL.md` -- updated Phase 2b to use objective readiness gate
- `.claude/hooks/stop.sh` -- configurable iteration limit via env var, explanation mode support
- `.claude/hooks/pre-tool-use.sh` -- explanation mode support, 5-field pattern parsing
- `.claude/hooks/rules/safety.patterns` -- added WHY/INSTEAD explanations to all entries
- `.claude/hooks/README.md` -- documented explanation mode and configurable stop limit
- `.claude/hooks/CLAUDE.md` -- documented new environment variables
- `.claude/settings.local.json.template` -- documented all framework env vars
- `llms.txt` -- updated entry point to /quickstart, fixed stale references

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  CONTRIBUTING.md (NEW)
  .claude/prompts/confidence-gate.md (CHANGED)
  .claude/hooks/stop.sh (CHANGED)
  .claude/hooks/pre-tool-use.sh (CHANGED)
  .claude/hooks/rules/safety.patterns (CHANGED)
  .claude/hooks/session-start.sh (CHANGED)
  .claude/hooks/README.md (CHANGED)
  .claude/hooks/CLAUDE.md (CHANGED)
  .claude/settings.local.json.template (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  install.sh (CHANGED)
  llms.txt (CHANGED)
  CHANGELOG.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - Set EXOSUIT_EXPLAIN_MODE=verbose in your shell profile if you want beginner-friendly hook explanations
  - The confidence gate in story-cycle now uses objective checks instead of self-assessed scoring
```

---

## [3.8.0] - 2026-03-23

### Added
- `/quickstart` skill -- guided interactive tour for new users
- `/help-me` skill -- natural language skill discovery
- `/dashboard` skill -- sprint status overview
- `/custom-hooks` skill -- create project-specific hooks
- `/uninstall` skill -- clean framework removal
- `/performance-check` skill -- performance analysis quality agent
- `.claude/prompts/error-recovery-central.md` -- centralized error recovery
- `.claude/prompts/validate-arguments.md` -- argument validation pattern
- `.claude/prompts/capture-outcome.md` -- structured story outcome tracking
- `.claude/hooks/tests/` -- framework test suite for hooks
- `.claude/hooks/status-line.sh` -- status bar output for plugin mode
- `docs/reference/TEAM_WORKFLOW.md` scaffold -- team collaboration guide template
- `docs/reference/API_DOCUMENTATION.md` scaffold -- API documentation template
- `docs/reference/SECRETS_INVENTORY.md` scaffold -- secret rotation tracking template
- `core/MANIFEST.md` -- file classification for upgrades
- `.claude-context.md` files for all major directories

### Changed
- `CHANGELOG.md` -- restructured for machine-parseable upgrade instructions
- `README.md` -- removed Python prerequisite, fixed skill counts and paths
- `.claude-plugin/plugin.json` -- version 3.4.0 -> 3.8.0
- `.claude/skills/skills-registry.json` -- synced all versions with SKILL.md files
- `.claude/skills/commit/SKILL.md` -- fixed co-author placeholder
- `.claude/skills/fix-issue/SKILL.md` -- dynamic default branch detection
- `scripts/pm/metrics.sh` -- fixed stale engine.py reference
- `.claude/hooks/stop.sh` -- optimized auto-save (only when uncommitted changes exist)
- `.claude/hooks/status-line.sh` -- added active skill indicator
- `.claude/rules/security.md` -- added SBOM and secret rotation sections
- `.claude/skills/security-audit/SKILL.md` -- added SBOM generation
- `.claude/skills/sprint-end/SKILL.md` -- added human review handling
- `.github/CODEOWNERS` -- expanded with team patterns
- `install.sh` -- added .github/ copy, additional directory creation
- Multiple skills -- added lifecycle event emission for metrics

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/quickstart/SKILL.md (NEW)
  .claude/skills/help-me/SKILL.md (NEW)
  .claude/skills/dashboard/SKILL.md (NEW)
  .claude/skills/custom-hooks/SKILL.md (NEW)
  .claude/skills/uninstall/SKILL.md (NEW)
  .claude/skills/performance-check/SKILL.md (NEW)
  .claude/prompts/error-recovery-central.md (NEW)
  .claude/prompts/validate-arguments.md (NEW)
  .claude/prompts/capture-outcome.md (NEW)
  .claude/hooks/tests/ (NEW directory)
  .claude/hooks/status-line.sh (NEW)
  core/MANIFEST.md (NEW)
  .claude/skills/commit/SKILL.md (CHANGED)
  .claude/skills/fix-issue/SKILL.md (CHANGED)
  .claude/hooks/stop.sh (CHANGED)
  scripts/pm/metrics.sh (CHANGED)
  README.md (CHANGED)
  install.sh (CHANGED)
  CHANGELOG.md (CHANGED)
  .claude-plugin/plugin.json (CHANGED)
  .claude/skills/skills-registry.json (CHANGED)
  .claude/skills/SKILLS_INVENTORY.md (CHANGED)
  .claude/rules/security.md (CHANGED)
  .claude/skills/security-audit/SKILL.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)

CORE_MERGE:
  .github/CODEOWNERS (merge team members)

PROJECT_UPDATE_INSTRUCTIONS:
  - If docs/reference/CODING_STANDARDS.md exists: consider adding "Universal Conventions" section from scaffold template
  - If docs/reference/TESTING_STRATEGY.md exists: consider adding "Coverage Tool Quick Reference" section
  - Copy new scaffold templates to docs/reference/ if missing: TEAM_WORKFLOW.md, API_DOCUMENTATION.md, SECRETS_INVENTORY.md
```

---

## [3.7.0] - 2026-03-20

### Summary
Metric-driven optimization: `/optimize` skill with git checkpointing and automatic rollback, story-cycle git checkpoint + auto-rollback on verification failure, story-scoped file boundaries, simplicity assessment in `/code-quality`, `capture-outcome` micro-component for structured story outcome tracking, `/refine-loop` autonomous mode with TSV logging and diminishing-returns detection.

### Added
- `.claude/skills/optimize/SKILL.md` -- autonomous metric-driven optimization with git checkpointing
- `.claude/prompts/capture-outcome.md` -- structured story outcome tracking

### Changed
- `.claude/skills/story-cycle/SKILL.md` -- git checkpoint + auto-rollback on verification failure, story-scoped file boundaries
- `.claude/skills/code-quality/SKILL.md` -- simplicity assessment added
- `.claude/skills/refine-loop/SKILL.md` -- autonomous mode with TSV logging and diminishing-returns detection

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/optimize/SKILL.md (NEW)
  .claude/prompts/capture-outcome.md (NEW)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/code-quality/SKILL.md (CHANGED)
  .claude/skills/refine-loop/SKILL.md (CHANGED)
  .claude/skills/SKILLS_INVENTORY.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  (none)
```

---

## [3.6.0] - 2026-03-16

### Summary
Deep research capability: `/research` skill, `deep-research` engine snippet, `source-evaluator` snippet, `research-analyst` agent, research rule, depth-calibrated research in bootstrap/brainstorm/ideate/story-cycle, reflection-based context compression, parallel subagent dispatch for research, prior research caching.

### Added
- `.claude/skills/research/SKILL.md` -- deep online research skill
- `.claude/prompts/deep-research.md` -- research engine snippet
- `.claude/prompts/source-evaluator.md` -- source quality scoring
- `.claude/agents/research-analyst.md` -- research-focused agent
- `.claude/rules/research.md` -- research output quality standards

### Changed
- `.claude/skills/bootstrap/SKILL.md` -- depth-calibrated research integration
- `.claude/skills/brainstorm/SKILL.md` -- research integration
- `.claude/skills/ideate/SKILL.md` -- research integration
- `.claude/skills/story-cycle/SKILL.md` -- research integration, prior research caching
- `.claude/skills/SKILLS_INVENTORY.md` -- added research skill, version 3.6

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/research/SKILL.md (NEW)
  .claude/skills/research/references/ (NEW directory)
  .claude/prompts/deep-research.md (NEW)
  .claude/prompts/source-evaluator.md (NEW)
  .claude/agents/research-analyst.md (NEW)
  .claude/rules/research.md (NEW)
  .claude/skills/bootstrap/SKILL.md (CHANGED)
  .claude/skills/brainstorm/SKILL.md (CHANGED)
  .claude/skills/ideate/SKILL.md (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/SKILLS_INVENTORY.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - Bootstrap will scaffold docs/research/ on next run
```

---

## [3.5.0] - 2026-03-14

### Summary
Context efficiency and knowledge reuse: grep-first codebase exploration, solutions database, research decision gate, hook error isolation, depth-controlled exploration, brainstorm document artifacts, skill cross-reference registry, agent temperature hints.

### Added
- `.claude/prompts/grep-first-explore.md` -- pre-filter files via targeted Grep (OPT-125)
- `.claude/prompts/capture-learnings.md` -- persist learnings from completed stories (OPT-126)
- `docs/solutions/` directory -- searchable solutions database (OPT-126)
- `docs/brainstorms/` directory -- persisted design documents (OPT-130)

### Changed
- `.claude/skills/story-cycle/SKILL.md` -- grep-first exploration (OPT-125), learnings capture (OPT-126), research decision gate (OPT-127), depth-controlled exploration (OPT-129)
- `.claude/skills/bootstrap/SKILL.md` -- scaffold docs/solutions/ and docs/brainstorms/ (OPT-126)
- `.claude/skills/brainstorm/SKILL.md` -- persist design documents (OPT-130)
- `.claude/skills/ideate/SKILL.md` -- check prior brainstorm artifacts (OPT-130)
- `.claude/skills/skills-registry.json` -- added `calls` field for cross-references (OPT-131)
- `.claude/skills/doctor/SKILL.md` -- skill cross-reference validation (OPT-131)
- `.claude/agents/code-reviewer.md` -- temperature 0.1, model: inherit (OPT-132)
- `.claude/agents/spec-reviewer.md` -- temperature 0.1 (OPT-132)
- `.claude/agents/security-analyst.md` -- temperature 0.1, model: inherit (OPT-132)
- `.claude/agents/architecture-reviewer.md` -- temperature 0.1, model: inherit (OPT-132)
- `.claude/agents/performance-engineer.md` -- temperature 0.2, model: inherit (OPT-132)
- `.claude/agents/codebase-explorer.md` -- temperature 0.3 (OPT-132)
- `.claude/hooks/engine.py` -- error isolation in handler dispatch (OPT-128)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/prompts/grep-first-explore.md (NEW)
  .claude/prompts/capture-learnings.md (NEW)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/bootstrap/SKILL.md (CHANGED)
  .claude/skills/brainstorm/SKILL.md (CHANGED)
  .claude/skills/ideate/SKILL.md (CHANGED)
  .claude/skills/skills-registry.json (CHANGED)
  .claude/skills/doctor/SKILL.md (CHANGED)
  .claude/agents/code-reviewer.md (CHANGED)
  .claude/agents/spec-reviewer.md (CHANGED)
  .claude/agents/security-analyst.md (CHANGED)
  .claude/agents/architecture-reviewer.md (CHANGED)
  .claude/agents/performance-engineer.md (CHANGED)
  .claude/agents/codebase-explorer.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - Bootstrap will scaffold docs/solutions/ and docs/brainstorms/ on next run
```

---

## [3.4.0] - 2026-02-23

### Summary
Confidence gate, four-question evidence protocol, cross-session error learning, wave execution pattern, MCP integration guide, domain-specific agent personas, completion evidence protocol.

### Added
- `.claude/prompts/confidence-gate.md` -- pre-implementation confidence assessment (OPT-119)
- `.claude/prompts/record-failure.md` -- record failure patterns (OPT-121)
- `docs/context/error-patterns.md` -- persistent error knowledge base (OPT-121)
- `.claude/prompts/wave-execution.md` -- parallel execution pattern (OPT-122)
- `docs/reference/MCP_INTEGRATION.md` -- MCP server integration guide (OPT-123)
- `.claude/prompts/select-tool.md` -- MCP vs built-in tool selection (OPT-123)
- `.claude/prompts/agents/security-analyst.md` -- attacker-mindset persona (OPT-124)
- `.claude/prompts/agents/performance-engineer.md` -- systems profiling persona (OPT-124)
- `.claude/prompts/agents/architecture-reviewer.md` -- boundary-enforcement persona (OPT-124)

### Changed
- `.claude/skills/story-cycle/SKILL.md` -- Phase 2.5 confidence gate (OPT-119), error learning (OPT-121), wave execution (OPT-122)
- `.claude/rules/verification.md` -- four-question completion evidence protocol (OPT-120)
- `.claude/skills/debug-session/SKILL.md` -- Phase 4.5 error learning (OPT-121)
- `.claude/prompts/context-prime.md` -- error-patterns.md loading (OPT-121)
- `.claude/skills/bootstrap/SKILL.md` -- MCP server detection step A4.5 (OPT-123)
- `CLAUDE.md` -- added MCP_INTEGRATION.md to Important Files (OPT-123)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/prompts/confidence-gate.md (NEW)
  .claude/prompts/record-failure.md (NEW)
  .claude/prompts/wave-execution.md (NEW)
  .claude/prompts/select-tool.md (NEW)
  .claude/prompts/agents/security-analyst.md (NEW)
  .claude/prompts/agents/performance-engineer.md (NEW)
  .claude/prompts/agents/architecture-reviewer.md (NEW)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/rules/verification.md (CHANGED)
  .claude/skills/debug-session/SKILL.md (CHANGED)
  .claude/prompts/context-prime.md (CHANGED)
  .claude/skills/bootstrap/SKILL.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - If docs/reference/ exists: copy MCP_INTEGRATION.md from scaffold
  - Add MCP_INTEGRATION.md to CLAUDE.md Important Files section
  - Bootstrap will scaffold docs/context/error-patterns.md on next run
```

---

## [3.3.0] - 2026-02-23

### Summary
Context intelligence (intent-aware context priming, intent-based rule activation), failure resilience (structured failure state persistence, cross-skill error awareness), observability (skill-level execution metrics, ground rule compliance ledger, rule effectiveness tracking), prompt engineering (adaptive depth calibration, dynamic micro-component composition), skill version regression detection.

### Added
- `scripts/pm/metrics.sh` -- skill execution metrics query script (OPT-113)
- `.claude/skills/skill-eval/baselines/` -- baseline captures directory (OPT-118)

### Changed
- `.claude/prompts/context-prime.md` -- intent classification table and dynamic loading (OPT-109)
- `.claude/rules/security.md` -- expanded path scope for security-sensitive files (OPT-110)
- `.claude/skills/story-cycle/SKILL.md` -- failure state persistence, cross-skill status, intent-based security, adaptive calibration, lifecycle events, micro-components frontmatter (OPT-110, OPT-111, OPT-112, OPT-113, OPT-116, OPT-117)
- `.claude/skills/debug-session/SKILL.md` -- failure state persistence (OPT-111)
- `.claude/skills/continue/SKILL.md` -- failure state detection Step 0.5 (OPT-111)
- `.claude/skills/sprint-end/SKILL.md` -- story completion status check, compliance ledger, micro-components frontmatter (OPT-112, OPT-114, OPT-117)
- `.claude/skills/retrospective/SKILL.md` -- skill execution metrics section (OPT-113)
- `docs/progress.md` -- ground rule compliance table section (OPT-114)
- `.claude/rules/verification.md` -- rule effectiveness tracking protocol (OPT-115)
- `.claude/skills/weekly-maintenance/SKILL.md` -- rule health review Step 5 (OPT-115)
- `.claude/skills/SKILL_TEMPLATE.md` -- micro-components field documentation (OPT-117)
- `.claude/skills/skill-eval/SKILL.md` -- baseline and regression modes (OPT-118)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  scripts/pm/metrics.sh (NEW)
  .claude/skills/skill-eval/baselines/ (NEW directory)
  .claude/prompts/context-prime.md (CHANGED)
  .claude/rules/security.md (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/debug-session/SKILL.md (CHANGED)
  .claude/skills/continue/SKILL.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/skills/retrospective/SKILL.md (CHANGED)
  .claude/rules/verification.md (CHANGED)
  .claude/skills/weekly-maintenance/SKILL.md (CHANGED)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)
  .claude/skills/skill-eval/SKILL.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - Add "Ground Rule Compliance" table section to docs/progress.md if not present
```

---

## [3.2.0] - 2026-02-23

### Summary
Worktree-aware bash hook, parallel stream decomposition, project context knowledge base, script delegation, documentation accuracy safeguards, template repo safety check.

### Added
- `.claude/hooks/worktree-bash-fix.sh` -- worktree directory fix (OPT-103)
- `.claude/skills/story-cycle/references/parallel-streams.md` -- parallel stream reference (OPT-104)
- `docs/context/project-overview.md`, `docs/context/tech-context.md`, `docs/context/system-patterns.md`, `docs/context/project-structure.md`, `docs/context/product-context.md` -- project context knowledge base (OPT-105)
- `.claude/prompts/context-prime.md` -- priority-ordered context loading (OPT-105)
- `scripts/pm/status.sh`, `scripts/pm/next-story.sh`, `scripts/pm/standup.sh` -- PM scripts (OPT-106)
- `.claude/skills/bootstrap/references/accuracy-safeguards.md` -- anti-hallucination protocol (OPT-107)

### Changed
- `.claude/settings.json` -- added worktree-bash-fix hook entry (OPT-103)
- `.claude/skills/story-cycle/SKILL.md` -- Phase 3a parallel streams (OPT-104), context loading (OPT-105)
- `.claude/skills/continue/SKILL.md` -- Step 1.5 load project context (OPT-105)
- `.claude/skills/bootstrap/SKILL.md` -- generate context knowledge base (OPT-105), accuracy safeguards (OPT-107)
- `.claude/skills/sprint-end/SKILL.md` -- incremental context update (OPT-105)
- `.claude/rules/documentation.md` -- documentation accuracy section (OPT-107)
- `.claude/hooks/pre-tool-use.sh` -- template repo safety check (OPT-108)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/hooks/worktree-bash-fix.sh (NEW)
  .claude/skills/story-cycle/references/parallel-streams.md (NEW)
  .claude/prompts/context-prime.md (NEW)
  scripts/pm/status.sh (NEW)
  scripts/pm/next-story.sh (NEW)
  scripts/pm/standup.sh (NEW)
  .claude/skills/bootstrap/references/accuracy-safeguards.md (NEW)
  .claude/settings.json (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/continue/SKILL.md (CHANGED)
  .claude/skills/bootstrap/SKILL.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/rules/documentation.md (CHANGED)
  .claude/hooks/pre-tool-use.sh (CHANGED)

CORE_MERGE:
  .claude/settings.json (new hook entry for worktree-bash-fix)

PROJECT_UPDATE_INSTRUCTIONS:
  - Bootstrap will scaffold docs/context/ directory with 5 knowledge base files on next run
  - Copy scripts/pm/ scripts to project if not present
```

---

## [3.1.0] - 2026-02-23

### Summary
Adversarial disaster prevention, token-efficiency guidelines, per-workflow state persistence, integrated depth exploration, complexity-calibrated workflow depth, artifact-aware project navigator, output templates, elicitation techniques library, facilitator reinforcement, skill-specific sidecar memory.

### Added
- `.claude/skills/story-cycle/references/disaster-prevention.md` -- adversarial checklist (OPT-93)
- `.claude/skills/story-cycle/references/elicitation-techniques.md` -- 5 named techniques (OPT-100)
- `.claude/skills/debug-session/assets/debug-report.md` -- output template (OPT-99)
- `.claude/skills/brainstorm/assets/brainstorm-output.md` -- output template (OPT-99)
- `.claude/skills/manual-test/assets/test-plan.md` -- output template (OPT-99)
- `.claude/skills/ideate/assets/story-template.md` -- output template (OPT-99)

### Changed
- `.claude/skills/story-cycle/references/self-review.md` -- disaster prevention reference (OPT-93)
- `.claude/skills/story-cycle/SKILL.md` -- disaster prevention, state persistence, depth check, risk classification, discovery gate (OPT-93, OPT-95, OPT-96, OPT-97, OPT-101)
- `.claude/skills/story-cycle/references/reasoning-tools.md` -- risk_classification, depth_exploration tools (OPT-96, OPT-97)
- `.claude/skills/story-cycle/references/plan-template.md` -- workflow state frontmatter, architectural violations (OPT-95, OPT-75)
- `.claude/rules/documentation.md` -- cross-skill output optimization, reference file budgets (OPT-94, OPT-79)
- `.claude/skills/continue/SKILL.md` -- project health scan Step 0 (OPT-98)
- `.claude/skills/SKILL_TEMPLATE.md` -- sidecar memory convention (OPT-102)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/story-cycle/references/disaster-prevention.md (NEW)
  .claude/skills/story-cycle/references/elicitation-techniques.md (NEW)
  .claude/skills/debug-session/assets/debug-report.md (NEW)
  .claude/skills/brainstorm/assets/brainstorm-output.md (NEW)
  .claude/skills/manual-test/assets/test-plan.md (NEW)
  .claude/skills/ideate/assets/story-template.md (NEW)
  .claude/skills/story-cycle/references/self-review.md (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/story-cycle/references/reasoning-tools.md (CHANGED)
  .claude/skills/story-cycle/references/plan-template.md (CHANGED)
  .claude/rules/documentation.md (CHANGED)
  .claude/skills/continue/SKILL.md (CHANGED)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  (none)
```

---

## [3.0.0] - 2026-02-22

### Summary
CI PR review, PR template, session-start hook, activity logging, skill conformance validator, registry schema, story-cycle fast-track, dynamic quality scaling, agent tool restrictions, GitHub issue templates, framework health check, dead code detection, context budget visibility, secrets detection, skill prerequisites, subagent context protocol, hook self-validation, pre-compaction state persistence, reference file budgets.

### Added
- `.github/workflows/claude-pr-review.yml` -- CI PR review workflow (OPT-83)
- `.github/pull_request_template.md` -- PR template (OPT-84)
- `.github/ISSUE_TEMPLATE/bug_report.yml` -- bug report template (OPT-92)
- `.github/ISSUE_TEMPLATE/feature_request.yml` -- feature request template (OPT-92)
- `.claude/hooks/session-start.sh` -- environment checks (OPT-85)
- `.claude/hooks/post-tool-use.sh` -- activity logging (OPT-86)
- `.claude/commands/review-pr-ci.md` -- CI review command (OPT-83)
- `.claude/skills/doctor/SKILL.md` -- framework health check (OPT-85)
- `.claude/skills/doctor/scripts/validate-skills.sh` -- skill conformance validator (OPT-87)
- `.claude/skills/skills-registry.schema.json` -- registry schema (OPT-88)
- `.claude/prompts/context-budget.md` -- context budget visibility (OPT-84)

### Changed
- `.claude/settings.json` -- SessionStart + PostToolUse hook entries (OPT-85, OPT-86)
- `.claude/hooks/README.md` -- session-start and activity-logger documentation (OPT-85, OPT-86)
- `.claude/skills/sprint-end/SKILL.md` -- CI reference, PR template, quality scaling (OPT-83, OPT-84, OPT-90)
- `.claude/skills/sprint-end/references/quality-gates.md` -- dynamic quality agent scaling (OPT-90)
- `.claude/skills/story-cycle/SKILL.md` -- fast-track mode, lifecycle events (OPT-89, OPT-113)
- `.claude/skills/retrospective/SKILL.md` -- activity log metrics (OPT-86)
- `.claude/skills/handoff/SKILL.md` -- activity summary (OPT-86)
- `.claude/skills/code-quality/SKILL.md` -- tool restrictions, dead code detection (OPT-91, OPT-86)
- `.claude/skills/security-audit/SKILL.md` -- tool restrictions (OPT-91)
- `.claude/skills/test-validator/SKILL.md` -- tool restrictions (OPT-91)
- `.claude/skills/SKILL_TEMPLATE.md` -- tool restrictions, prerequisites, subagent protocol, reference budgets (OPT-91, OPT-81, OPT-82, OPT-79)
- `.claude/skills/skill-create/scripts/update-registry.sh` -- schema validation (OPT-88)
- `.claude/skills/weekly-maintenance/SKILL.md` -- dead code check (OPT-86)
- `.claude/hooks/post-edit-format.sh` -- secrets detection, requirements header (OPT-80, OPT-83)
- `.claude/hooks/pre-tool-use.sh` -- requirements header (OPT-83)
- `.claude/rules/verification.md` -- pre-compaction state persistence (OPT-78)
- `.claude/rules/documentation.md` -- reference file budgets (OPT-79)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .github/workflows/claude-pr-review.yml (NEW)
  .github/pull_request_template.md (NEW)
  .github/ISSUE_TEMPLATE/bug_report.yml (NEW)
  .github/ISSUE_TEMPLATE/feature_request.yml (NEW)
  .claude/hooks/session-start.sh (NEW)
  .claude/hooks/post-tool-use.sh (NEW)
  .claude/commands/review-pr-ci.md (NEW)
  .claude/skills/doctor/SKILL.md (NEW)
  .claude/skills/doctor/scripts/validate-skills.sh (NEW)
  .claude/skills/skills-registry.schema.json (NEW)
  .claude/prompts/context-budget.md (NEW)
  .claude/settings.json (CHANGED)
  .claude/hooks/README.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/skills/sprint-end/references/quality-gates.md (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/retrospective/SKILL.md (CHANGED)
  .claude/skills/handoff/SKILL.md (CHANGED)
  .claude/skills/code-quality/SKILL.md (CHANGED)
  .claude/skills/security-audit/SKILL.md (CHANGED)
  .claude/skills/test-validator/SKILL.md (CHANGED)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)
  .claude/skills/skill-create/scripts/update-registry.sh (CHANGED)
  .claude/skills/weekly-maintenance/SKILL.md (CHANGED)
  .claude/hooks/post-edit-format.sh (CHANGED)
  .claude/hooks/pre-tool-use.sh (CHANGED)
  .claude/rules/verification.md (CHANGED)
  .claude/rules/documentation.md (CHANGED)

CORE_MERGE:
  .claude/settings.json (new hook entries for SessionStart and PostToolUse)

PROJECT_UPDATE_INSTRUCTIONS:
  - Copy .github/ directory to project if not present
  - Add /doctor to SKILLS_INVENTORY.md Maintenance table
```

---

## [2.8.0] - 2026-02-22

### Summary
Forced clarification markers, structured clarification sub-phase with ambiguity scanning, WHAT/WHY vs HOW separation in plans, project ground rules pattern, violation tracking, consistent handoff suggestions, per-phase context loading manifests.

### Added
- `.claude/skills/story-cycle/references/plan-template.md` -- plan structure template (OPT-73)
- `.claude/skills/ideate/references/story-template.md` -- story structure template (OPT-73)
- `docs/reference/GROUND_RULES.md` -- project ground rules (OPT-74)

### Changed
- `.claude/skills/story-cycle/SKILL.md` -- clarification markers (OPT-71), Phase 1f ambiguity scan (OPT-72), plan format (OPT-73), ground rules check (OPT-74), handoff suggestions (OPT-76), per-phase context manifests (OPT-77)
- `.claude/skills/story-cycle/references/reasoning-tools.md` -- scope_analysis step 6, ambiguity_scan tool, plan_completeness steps 7-8 (OPT-71, OPT-72, OPT-73)
- `.claude/skills/sprint-end/SKILL.md` -- ground rules compliance gate, handoff suggestions (OPT-74, OPT-76)
- `.claude/skills/bootstrap/SKILL.md` -- step A3.6 ground rules (OPT-74)
- `.claude/skills/ideate/SKILL.md` -- story structure, handoff suggestions (OPT-73, OPT-76)
- `.claude/skills/brainstorm/SKILL.md` -- handoff suggestions (OPT-76)
- `.claude/skills/debug-session/SKILL.md` -- handoff suggestions (OPT-76)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/story-cycle/references/plan-template.md (NEW)
  .claude/skills/ideate/references/story-template.md (NEW)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/story-cycle/references/reasoning-tools.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/skills/bootstrap/SKILL.md (CHANGED)
  .claude/skills/ideate/SKILL.md (CHANGED)
  .claude/skills/brainstorm/SKILL.md (CHANGED)
  .claude/skills/debug-session/SKILL.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - Bootstrap will scaffold docs/reference/GROUND_RULES.md on next run
```

---

## [2.7.0] - 2026-02-22

### Summary
Cognitive reasoning scaffolds, symbolic state encoding, control flow markers (IF/ELSE/LOOP/HALT), phase-specific error recovery tables, context relevance scoring, reusable micro-components.

### Added
- `.claude/skills/story-cycle/references/reasoning-tools.md` -- 5 named reasoning tools (OPT-65)
- `.claude/skills/story-cycle/references/error-recovery.md` -- 19 error patterns (OPT-68)
- `.claude/skills/debug-session/references/error-recovery.md` -- 15 error patterns (OPT-68)
- `.claude/skills/sprint-end/references/error-recovery.md` -- 18 error patterns (OPT-68)
- `.claude/prompts/discover-commands.md` -- extract CLAUDE.md commands (OPT-70)
- `.claude/prompts/quality-gate-sequence.md` -- lint/typecheck/test sequence (OPT-70)
- `.claude/prompts/verify-clean-git-state.md` -- working tree check (OPT-70)

### Changed
- `.claude/skills/story-cycle/SKILL.md` -- reasoning tools, symbolic state, control flow markers, error recovery (OPT-65, OPT-66, OPT-67, OPT-68)
- `.claude/skills/debug-session/SKILL.md` -- reasoning tools, control flow markers, error recovery (OPT-65, OPT-67, OPT-68)
- `.claude/skills/sprint-end/SKILL.md` -- control flow markers, error recovery (OPT-67, OPT-68)
- `.claude/skills/architecture-check/SKILL.md` -- architectural_impact reasoning tool (OPT-65)
- `.claude/skills/SKILL_TEMPLATE.md` -- control flow markers, recovery guidance (OPT-67, OPT-68)
- `CLAUDE.md` -- symbolic state encoding in compaction directive (OPT-66)
- `.claude/rules/verification.md` -- context relevance scoring (OPT-69)
- `.claude/prompts/README.md` -- micro-components section (OPT-70)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/story-cycle/references/reasoning-tools.md (NEW)
  .claude/skills/story-cycle/references/error-recovery.md (NEW)
  .claude/skills/debug-session/references/error-recovery.md (NEW)
  .claude/skills/sprint-end/references/error-recovery.md (NEW)
  .claude/prompts/discover-commands.md (NEW)
  .claude/prompts/quality-gate-sequence.md (NEW)
  .claude/prompts/verify-clean-git-state.md (NEW)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/debug-session/SKILL.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/skills/architecture-check/SKILL.md (CHANGED)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)
  .claude/rules/verification.md (CHANGED)
  .claude/prompts/README.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - Update CLAUDE.md Compaction Directive to use structured key-value format (see scaffold/CLAUDE.md)
```

---

## [2.6.0] - 2026-02-22

### Summary
AI slop detection rule, edit recovery protocol, automated session state preservation, priority-based compaction, intent decomposition, completion verification, parallel research, context budget awareness, expanded anti-patterns, graceful degradation expansion.

### Added
- `.claude/rules/code-slop.md` -- AI filler pattern detection (OPT-50)
- `.claude/rules/edit-recovery.md` -- edit failure recovery protocol (OPT-52)

### Changed
- `docs/reference/CODING_STANDARDS.md` -- comment quality section (OPT-51)
- `.claude/hooks/stop.sh` -- auto-save session state (OPT-53)
- `CLAUDE.md` -- priority-based compaction, directory-level context convention (OPT-54, OPT-55)
- `.claude/rules/verification.md` -- context budget awareness, task completion enforcement (OPT-56, OPT-57)
- `.claude/skills/story-cycle/SKILL.md` -- intent decomposition Phase 0, completion verification Phase 4.5, parallel research, context convention, dynamic skill content (OPT-55, OPT-58, OPT-59, OPT-60, OPT-61)
- `.claude/skills/sprint-start/SKILL.md` -- dynamic project state adaptation (OPT-61)
- `.claude/skills/sprint-end/SKILL.md` -- expanded graceful degradation (OPT-62)
- `.claude/rules/testing.md` -- AI-specific anti-patterns (OPT-63)
- `.claude/rules/security.md` -- AI-specific security anti-patterns (OPT-64)
- `.claude/rules/documentation.md` -- directory-level context acknowledgement (OPT-55)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/rules/code-slop.md (NEW)
  .claude/rules/edit-recovery.md (NEW)
  .claude/hooks/stop.sh (CHANGED)
  .claude/rules/verification.md (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/sprint-start/SKILL.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/rules/testing.md (CHANGED)
  .claude/rules/security.md (CHANGED)
  .claude/rules/documentation.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - Add "Comment Quality" section to docs/reference/CODING_STANDARDS.md if not present
  - Update CLAUDE.md Compaction Directive to priority-based format (see scaffold/CLAUDE.md)
```

---

## [2.5.0] - 2026-02-22

### Summary
Script black-boxing, grep navigation hints, resource types, skill scaffolding, I/O examples, DO/DON'T pairs, graceful degradation, pre-execution validation, skills registry.

### Added
- `.claude/skills/skill-create/scripts/init-skill.sh` -- skill scaffolding script (OPT-43)
- `.claude/skills/skill-create/scripts/update-registry.sh` -- registry generator (OPT-49)
- `.claude/skills/skills-registry.json` -- machine-readable skill registry (OPT-49)

### Changed
- `.claude/skills/SKILL_TEMPLATE.md` -- script execution policy, reference navigation, resource types, context principle (OPT-40, OPT-41, OPT-42, OPT-28)
- `.claude/skills/bootstrap/SKILL.md` -- black-box script directives (OPT-40)
- `.claude/skills/sprint-end/references/quality-gates.md` -- black-box script directives (OPT-40)
- `.claude/skills/parallel-work/SKILL.md` -- black-box script directives (OPT-40)
- `.claude/skills/story-cycle/SKILL.md` -- grep navigation, DO/DON'T pairs, graceful degradation (OPT-41, OPT-46, OPT-47, OPT-30)
- `.claude/skills/debug-session/SKILL.md` -- grep navigation, I/O examples, imperative language, DO/DON'T pairs (OPT-41, OPT-44, OPT-45, OPT-46)
- `.claude/skills/brainstorm/SKILL.md` -- I/O examples (OPT-44)
- `.claude/skills/ideate/SKILL.md` -- I/O examples, pre-execution validation (OPT-44, OPT-48)
- `.claude/skills/handoff/SKILL.md` -- pre-execution validation (OPT-48)
- `.claude/skills/sprint-end/SKILL.md` -- graceful degradation table (OPT-47)
- `.claude/skills/bootstrap/SKILL.md` -- graceful degradation table (OPT-47)
- `.claude/skills/code-quality/SKILL.md` -- graceful degradation table (OPT-47)
- `.claude/skills/skill-create/SKILL.md` -- co-located references (OPT-29)
- `.claude/hooks/pre-tool-use.sh` -- per-session state tracking (OPT-38)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/skill-create/scripts/init-skill.sh (NEW)
  .claude/skills/skill-create/scripts/update-registry.sh (NEW)
  .claude/skills/skills-registry.json (NEW)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)
  .claude/skills/bootstrap/SKILL.md (CHANGED)
  .claude/skills/sprint-end/references/quality-gates.md (CHANGED)
  .claude/skills/parallel-work/SKILL.md (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/debug-session/SKILL.md (CHANGED)
  .claude/skills/brainstorm/SKILL.md (CHANGED)
  .claude/skills/ideate/SKILL.md (CHANGED)
  .claude/skills/handoff/SKILL.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/skills/code-quality/SKILL.md (CHANGED)
  .claude/skills/skill-create/SKILL.md (CHANGED)
  .claude/hooks/pre-tool-use.sh (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  (none)
```

---

## [2.4.0] - 2026-02-22

### Summary
Confidence scoring, parallel quality gates, multi-perspective review, skill-eval, refine-loop, agent-first file discovery, example block triggers, session hook state, YAML frontmatter.

### Added
- `.claude/skills/skill-eval/SKILL.md` -- skill evaluation framework (OPT-34)
- `.claude/skills/refine-loop/SKILL.md` -- iterative refinement loop (OPT-35)

### Changed
- `.claude/skills/code-quality/SKILL.md` -- confidence scoring, example block triggers (OPT-31, OPT-37)
- `.claude/skills/test-validator/SKILL.md` -- confidence scoring, example block triggers (OPT-31, OPT-37)
- `.claude/skills/security-audit/SKILL.md` -- confidence scoring, example block triggers (OPT-31, OPT-37)
- `.claude/skills/sprint-end/references/quality-gates.md` -- parallel dispatch, multi-perspective review (OPT-32, OPT-33)
- `.claude/prompts/agents/code-reviewer.md` -- lens parameter, confidence scoring (OPT-33)
- `.claude/skills/story-cycle/SKILL.md` -- agent-first file discovery Phase 1b (OPT-36)
- `.claude/skills/SKILL_TEMPLATE.md` -- evaluation criteria, example block triggers (OPT-34, OPT-37)
- All 26 `.claude/skills/*/SKILL.md` -- YAML frontmatter (OPT-39)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/skill-eval/SKILL.md (NEW)
  .claude/skills/refine-loop/SKILL.md (NEW)
  .claude/skills/code-quality/SKILL.md (CHANGED)
  .claude/skills/test-validator/SKILL.md (CHANGED)
  .claude/skills/security-audit/SKILL.md (CHANGED)
  .claude/skills/sprint-end/references/quality-gates.md (CHANGED)
  .claude/prompts/agents/code-reviewer.md (CHANGED)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)
  All .claude/skills/*/SKILL.md (CHANGED — YAML frontmatter added)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  (none)
```

---

## [2.3.0] - 2026-02-22

### Summary
Skill reference splitting, helper scripts, QA framing, Don'ts lists, CLI discovery pattern, doc quality sub-agents, co-located tech skill references, context budget principle, environment adaptation.

### Added
- `.claude/skills/story-cycle/references/story-types.md` -- story type execution details (OPT-22)
- `.claude/skills/story-cycle/references/self-review.md` -- self-review checklist (OPT-22)
- `.claude/skills/sprint-end/references/quality-gates.md` -- quality gate specifics (OPT-22)
- `.claude/skills/bootstrap/references/stack-detection.md` -- stack detection tables (OPT-22)
- `.claude/skills/bootstrap/references/new-project.md` -- new project workflow (OPT-22)
- `.claude/skills/sprint-end/scripts/test-count-delta.sh` -- test count delta script (OPT-23)
- `.claude/skills/bootstrap/scripts/detect-stack.sh` -- stack detection script (OPT-23)
- `.claude/skills/parallel-work/scripts/worktree-status.sh` -- worktree status script (OPT-23)

### Changed
- `.claude/skills/story-cycle/SKILL.md` -- split to <150 lines (OPT-22)
- `.claude/skills/sprint-end/SKILL.md` -- split to <150 lines, QA framing, environment adaptation (OPT-22, OPT-24, OPT-30)
- `.claude/skills/bootstrap/SKILL.md` -- split to <150 lines, doc quality agents (OPT-22, OPT-27)
- `.claude/skills/debug-session/SKILL.md` -- references moved to references/ (OPT-22)
- `.claude/skills/code-quality/SKILL.md` -- QA framing, Don'ts, CLI discovery (OPT-24, OPT-25, OPT-26)
- `.claude/skills/test-validator/SKILL.md` -- QA framing, Don'ts, CLI discovery (OPT-24, OPT-25, OPT-26)
- `.claude/skills/skill-create/SKILL.md` -- Don'ts, co-located references (OPT-25, OPT-29)
- `.claude/skills/ideate/SKILL.md` -- doc quality agents (OPT-27)
- `.claude/skills/handoff/SKILL.md` -- doc quality agents (OPT-27)
- `.claude/skills/SKILL_TEMPLATE.md` -- context principle (OPT-28)
- `.claude/rules/verification.md` -- CLI discovery pattern (OPT-26)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/story-cycle/references/story-types.md (NEW)
  .claude/skills/story-cycle/references/self-review.md (NEW)
  .claude/skills/sprint-end/references/quality-gates.md (NEW)
  .claude/skills/bootstrap/references/stack-detection.md (NEW)
  .claude/skills/bootstrap/references/new-project.md (NEW)
  .claude/skills/sprint-end/scripts/test-count-delta.sh (NEW)
  .claude/skills/bootstrap/scripts/detect-stack.sh (NEW)
  .claude/skills/parallel-work/scripts/worktree-status.sh (NEW)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/skills/bootstrap/SKILL.md (CHANGED)
  .claude/skills/debug-session/SKILL.md (CHANGED)
  .claude/skills/code-quality/SKILL.md (CHANGED)
  .claude/skills/test-validator/SKILL.md (CHANGED)
  .claude/skills/skill-create/SKILL.md (CHANGED)
  .claude/skills/ideate/SKILL.md (CHANGED)
  .claude/skills/handoff/SKILL.md (CHANGED)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)
  .claude/rules/verification.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  (none)
```

---

## [2.2.0] - 2026-02-22

### Summary
Hard gates, trigger-only descriptions, verification rule, red flag tables, inline self-review, deepened debug-session, brainstorm skill, process flowcharts, subagent templates, TDD for skills, fix-immediately pattern.

### Added
- `.claude/rules/verification.md` -- verification-before-completion rule (OPT-12)
- `.claude/skills/brainstorm/SKILL.md` -- design exploration skill (OPT-17)
- `.claude/skills/debug-session/root-cause-tracing.md` -- root cause reference (OPT-16)
- `.claude/skills/debug-session/condition-based-waiting.md` -- waiting reference (OPT-16)
- `.claude/prompts/agents/code-reviewer.md` -- code review template (OPT-19)
- `.claude/prompts/agents/spec-reviewer.md` -- spec review template (OPT-19)

### Changed
- `.claude/skills/story-cycle/SKILL.md` -- hard gates, trigger-only description, red flags, inline self-review, spec compliance, process flowchart (OPT-10, OPT-11, OPT-13, OPT-14, OPT-15, OPT-18)
- `.claude/skills/sprint-end/SKILL.md` -- hard gates, trigger-only description, red flags, process flowchart (OPT-10, OPT-11, OPT-13, OPT-18)
- `.claude/skills/ideate/SKILL.md` -- hard gates, trigger-only description (OPT-10, OPT-11)
- `.claude/skills/brainstorm/SKILL.md` -- hard gates (OPT-10)
- `.claude/skills/debug-session/SKILL.md` -- rewritten as 5-phase process (OPT-16)
- `.claude/skills/bootstrap/SKILL.md` -- process flowchart (OPT-18)
- `.claude/skills/SKILL_TEMPLATE.md` -- hard gate, red flag, description trap documentation (OPT-10, OPT-13, OPT-20)
- `.claude/rules/security.md` -- fix-immediately pattern (OPT-21)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/rules/verification.md (NEW)
  .claude/skills/brainstorm/SKILL.md (NEW)
  .claude/skills/debug-session/root-cause-tracing.md (NEW)
  .claude/skills/debug-session/condition-based-waiting.md (NEW)
  .claude/prompts/agents/code-reviewer.md (NEW)
  .claude/prompts/agents/spec-reviewer.md (NEW)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/skills/ideate/SKILL.md (CHANGED)
  .claude/skills/debug-session/SKILL.md (CHANGED)
  .claude/skills/bootstrap/SKILL.md (CHANGED)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)
  .claude/rules/security.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  (none)
```

---

## [2.1.0] - 2026-02-22

### Summary
Structured compaction, cumulative file tracking, graduated context reset, enriched handoffs, expanded safety hooks, incremental linting, error recovery, health dashboard, prompt snippets.

### Added
- `.claude/prompts/README.md` -- prompt directory documentation (OPT-9)
- `.claude/prompts/review-security.md` -- security review snippet (OPT-9)
- `.claude/prompts/explain-pattern.md` -- pattern explanation snippet (OPT-9)
- `.claude/prompts/suggest-tests.md` -- test suggestion snippet (OPT-9)

### Changed
- `CLAUDE.md` -- structured compaction directive (OPT-1)
- `.claude/skills/story-cycle/SKILL.md` -- cumulative file tracking, graduated context reset, error recovery (OPT-5, OPT-7, OPT-4)
- `.claude/skills/handoff/SKILL.md` -- enriched file access history (OPT-2)
- `.claude/skills/continue/SKILL.md` -- selective context reload, health dashboard (OPT-2, OPT-8)
- `.claude/hooks/pre-tool-use.sh` -- expanded safety patterns (OPT-3)
- `.claude/hooks/post-edit-format.sh` -- incremental linting (OPT-6)
- `.claude/skills/sprint-end/SKILL.md` -- error recovery (OPT-4)
- `.claude/skills/SKILL_TEMPLATE.md` -- error recovery guidance (OPT-4)
- `.claude/skills/SKILLS_INVENTORY.md` -- prompt snippets section (OPT-9)

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/prompts/README.md (NEW)
  .claude/prompts/review-security.md (NEW)
  .claude/prompts/explain-pattern.md (NEW)
  .claude/prompts/suggest-tests.md (NEW)
  CLAUDE.md (CHANGED — scaffold template only, not project CLAUDE.md)
  .claude/skills/story-cycle/SKILL.md (CHANGED)
  .claude/skills/handoff/SKILL.md (CHANGED)
  .claude/skills/continue/SKILL.md (CHANGED)
  .claude/hooks/pre-tool-use.sh (CHANGED)
  .claude/hooks/post-edit-format.sh (CHANGED)
  .claude/skills/sprint-end/SKILL.md (CHANGED)
  .claude/skills/SKILL_TEMPLATE.md (CHANGED)
  .claude/skills/SKILLS_INVENTORY.md (CHANGED)

CORE_MERGE:
  (none)

PROJECT_UPDATE_INSTRUCTIONS:
  - Update CLAUDE.md Compaction Directive section to structured format (see scaffold/CLAUDE.md)
```

---

## [2.0.0] - 2026-02-21

### Summary
Hooks, rules, worktrees, test protection, CWE checks, metrics, architecture-check, parallel-work, session persistence, context management.

### Added
- `.claude/hooks/pre-tool-use.sh` -- safety command blocking
- `.claude/hooks/post-edit-format.sh` -- auto-format after edits
- `.claude/hooks/stop.sh` -- completion evidence validation
- `.claude/hooks/worktree.sh` -- worktree lifecycle
- `.claude/hooks/subagent-stop.sh` -- subagent output validation
- `.claude/hooks/user-prompt.sh` -- intent classification
- `.claude/hooks/lib/paths.sh` -- path resolution
- `.claude/hooks/hooks.json` -- plugin mode hook declarations
- `.claude/hooks/rules/safety.patterns` -- blocked patterns
- `.claude/hooks/rules/quality.conf` -- quality gate rules
- `.claude/hooks/rules/intent.patterns` -- intent patterns
- `.claude/hooks/rules/subagent.patterns` -- subagent patterns
- `.claude/hooks/rules/subagent.conf` -- subagent config
- `.claude/hooks/README.md` -- hook documentation
- `.claude/rules/testing.md` -- TDD enforcement
- `.claude/rules/documentation.md` -- doc constraints
- `.claude/rules/security.md` -- CWE checklist
- `.claude/rules/git.md` -- git workflow
- `.claude/rules/dependencies.md` -- dependency governance
- `.claude/skills/architecture-check/SKILL.md` -- architecture validation
- `.claude/skills/parallel-work/SKILL.md` -- worktree management
- `.claude/agents/code-reviewer.md` -- code review agent
- `.claude/agents/spec-reviewer.md` -- spec review agent
- `.claude/agents/security-analyst.md` -- security agent
- `.claude/agents/performance-engineer.md` -- performance agent
- `.claude/agents/architecture-reviewer.md` -- architecture agent
- `.claude/agents/codebase-explorer.md` -- codebase explorer agent

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  (all files listed above are NEW in this version)

CORE_MERGE:
  .claude/settings.json (hook entries added)

PROJECT_UPDATE_INSTRUCTIONS:
  - Run install.sh to set up hooks and rules
  - Run /bootstrap to configure project
```

---

## [1.1.0] - 2026-02-21

### Summary
Added testing workflow: UAT-cycle, testing-cycle, manual-test.

### Added
- `.claude/skills/UAT-cycle/SKILL.md`
- `.claude/skills/testing-cycle/SKILL.md`
- `.claude/skills/manual-test/SKILL.md`

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  .claude/skills/UAT-cycle/SKILL.md (NEW)
  .claude/skills/testing-cycle/SKILL.md (NEW)
  .claude/skills/manual-test/SKILL.md (NEW)
```

---

## [1.0.0] - 2026-02-21

### Summary
Initial framework release: 18 skills, bootstrap flow.

### Added
- `.claude/skills/bootstrap/SKILL.md`
- `.claude/skills/sprint-start/SKILL.md`
- `.claude/skills/story-cycle/SKILL.md`
- `.claude/skills/sprint-end/SKILL.md`
- `.claude/skills/continue/SKILL.md`
- `.claude/skills/handoff/SKILL.md`
- `.claude/skills/ideate/SKILL.md`
- `.claude/skills/skill-create/SKILL.md`
- `.claude/skills/code-quality/SKILL.md`
- `.claude/skills/test-validator/SKILL.md`
- `.claude/skills/security-audit/SKILL.md`
- `.claude/skills/weekly-maintenance/SKILL.md`
- `.claude/skills/retrospective/SKILL.md`
- `.claude/skills/backlog-review/SKILL.md`
- `.claude/skills/commit/SKILL.md`
- `.claude/skills/fix-issue/SKILL.md`
- `.claude/skills/pr-status/SKILL.md`
- `.claude/skills/undo-work/SKILL.md`
- `.claude/skills/SKILLS_INVENTORY.md`
- `.claude/skills/SKILL_TEMPLATE.md`
- `CLAUDE.md` (scaffold template)
- `install.sh`
- `README.md`

### Files Changed (for framework-upgrade)

```
CORE_REPLACE:
  (all files are NEW — initial release)
```
