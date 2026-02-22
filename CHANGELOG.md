# Changelog

## [2.9.0] - 2026-02-22

### Resilience & Context Protection (OPT-78, OPT-79)

#### OPT-78: Pre-Compaction State Persistence
- **Modified:** `.claude/rules/verification.md` (new "Pre-Compaction State Persistence" section)
- **What:** Added a rule instructing Claude to persist session state to `docs/sessions/.auto-save.md` when context is approaching compaction (15+ turns, multiple large tool outputs, or system compaction trigger). After compaction, Claude verifies critical state survived and reloads from auto-save if needed.
- **Why:** The existing auto-save in `pre-stop-quality.sh` only triggers at session end. Mid-session compaction can lose HIGH-priority state (branch, phase, decisions) if the compaction directive isn't followed perfectly. Persisting before compaction creates a safety net that survives even aggressive compaction.
- **To test:** During a long story-cycle session (15+ turns), verify Claude saves state to `.auto-save.md` before compaction triggers. After compaction, verify critical fields (goal, commands, active_plan) are still present.
- **To revert:** Remove the "## Pre-Compaction State Persistence" section (4 numbered steps + explanation paragraph) from verification.md.

#### OPT-79: Reference File Token Budgets
- **Modified:** `.claude/rules/documentation.md` (new "Reference File Size Budgets" section), `.claude/skills/SKILL_TEMPLATE.md` (new "Reference File Budgets" subsection)
- **What:** Added explicit line budgets for on-demand reference files: individual references ≤200 lines, total per skill ≤500 lines, and specific budgets for key project docs (CODING_STANDARDS ≤200, TESTING_STRATEGY ≤250, CONSTITUTION ≤100, ARCHITECTURE ≤200). Added guidance to load only relevant sections via grep hints.
- **Why:** Progressive disclosure prevents bulk loading, but there's no cap on how large a reference file can grow. As projects mature, CODING_STANDARDS.md or TESTING_STRATEGY.md can expand to 400+ lines, silently consuming context budget every time they're loaded. Budgets prevent this creep.
- **To test:** Read documentation.md and verify the budget table is present. Read SKILL_TEMPLATE.md and verify the "Reference File Budgets" subsection exists after "Skill Size & Resource Types."
- **To revert:** Remove the "## Reference File Size Budgets" section from documentation.md. Remove the "### Reference File Budgets" subsection from SKILL_TEMPLATE.md.

### Security (OPT-80)

#### OPT-80: Automated Secrets Detection in Post-Edit Hook
- **Modified:** `.claude/hooks/post-edit-format.sh` (new secrets detection section after lint)
- **What:** Added a lightweight secrets scan that runs after every file edit. Checks for: AWS access keys (AKIA...), OpenAI/Stripe-style keys (sk-...), GitHub personal access tokens (ghp_...), private keys (BEGIN PRIVATE KEY), and generic hardcoded credentials. Uses per-file session state to avoid duplicate warnings. Skips non-text files (images, lock files, markdown). Reports findings but does NOT block edits.
- **Why:** The `security.md` rule and `/security-audit` skill catch secrets during code review, but both are advisory. A hook-based scan catches secrets deterministically — regardless of which skill is running, any file containing a credential pattern gets flagged immediately.
- **To test:** Create a test file with `AKIA1234567890ABCDEF` in it. Verify the hook outputs a warning. Edit the same file again — verify the warning does NOT repeat (per-session state tracking).
- **To revert:** Remove everything from the `# Secrets detection` comment to the closing `fi` (before `exit 0`) in post-edit-format.sh.

### Skill Architecture (OPT-81, OPT-82, OPT-83)

#### OPT-81: Skill Prerequisites Declaration
- **Modified:** `.claude/skills/SKILL_TEMPLATE.md` (new "Skill Prerequisites (requires)" section)
- **What:** Added a `requires` field to the YAML frontmatter specification with three sub-fields: `binaries` (CLI tools), `commands` (CLAUDE.md Commands entries), and `files` (project files). Skills with `requires` validate prerequisites at startup and HALT with actionable error messages if anything is missing. Skills with documented fallbacks in their Graceful Degradation table can skip prerequisite checks for those items.
- **Why:** Skills currently fail at runtime when prerequisites aren't met (e.g., `gh` not installed for `/sprint-end`). Some skills handle this with `<IF>` blocks, but many don't. Declaring prerequisites upfront enables: early failure with actionable errors, `/doctor` validation, and `/bootstrap` compatibility checking.
- **To test:** Read SKILL_TEMPLATE.md and verify the "Skill Prerequisites (requires)" section is present after YAML Frontmatter. Verify it includes the `binaries`, `commands`, `files` field table and the HALT example.
- **To revert:** Remove the "## Skill Prerequisites (requires)" section from SKILL_TEMPLATE.md.

#### OPT-82: Subagent Context Protocol
- **Modified:** `.claude/skills/SKILL_TEMPLATE.md` (new "Subagent Context Protocol" section)
- **What:** Formalized two context modes for forked subagents: Full Mode (full conversation context, used by workflow skills) and Minimal Mode (CLAUDE.md Commands + coding standards only, used by analysis agents like code-quality, test-validator, security-audit). Added a template for specifying context requirements in skill frontmatter or dispatch templates. Subagent templates in `.claude/prompts/agents/` should specify their context requirements.
- **Why:** Forked subagents currently inherit whatever context is available, which can include irrelevant framework state that wastes tokens and potentially confuses analysis. Formalizing what each subagent receives ensures efficient token usage and accurate analysis.
- **To test:** Read SKILL_TEMPLATE.md and verify the "Subagent Context Protocol" section is present after Agent Types. Verify it documents Full Mode and Minimal Mode with use-case guidance.
- **To revert:** Remove the "## Subagent Context Protocol" section from SKILL_TEMPLATE.md.

#### OPT-83: Hook Self-Validation with Requirements Metadata
- **Modified:** `.claude/hooks/post-edit-format.sh` (requirements header + `report_missing()` helper), `.claude/hooks/pre-tool-safety.sh` (requirements header), `.claude/hooks/pre-stop-quality.sh` (requirements header), `.claude/hooks/README.md` (new "Requirements" section)
- **What:** Added standardized requirements headers to all three hook scripts declaring what tools they need and their behavior. Added a `report_missing()` helper to `post-edit-format.sh` that reports missing tools once per session using `$TMPDIR` state files. Updated hooks README to document the requirements header convention.
- **Why:** Hooks currently degrade silently when tools aren't installed. Users don't know their quality gates aren't firing. A hook that reports "post-edit-format: 'prettier' not found — skipping formatting" once per session is more informative than silent fallback.
- **To test:** Run a Claude Code session in a project without prettier. Verify `post-edit-format.sh` reports the missing tool once (not per edit). Verify hook README documents the requirements convention.
- **To revert:** Restore the original comment headers in all three hook scripts from git history. Remove `report_missing()` and `HOOK_STATE_DIR` from post-edit-format.sh. Remove the "## Requirements" section from hooks README.md.

### Observability & Diagnostics (OPT-84, OPT-85)

#### OPT-84: Context Budget Visibility
- **New file:** `.claude/prompts/context-budget.md`
- **Modified:** `.claude/prompts/README.md` (new row in Micro-Components table)
- **What:** Created a micro-component that estimates current context window usage and reports: framework base load, loaded references, conversation depth, compaction proximity (LOW/MEDIUM/HIGH/CRITICAL), and recommendations for pruning. References the context relevance scoring categories from verification.md.
- **Why:** The framework meticulously manages context (progressive disclosure, relevance scoring, compaction directives) but provides no visibility into usage. Users can't tell if they're at 40% or 90% capacity, and can't make informed decisions about when to handoff vs. push through.
- **To test:** Use the `context-budget` micro-component during a session. Verify it produces a structured breakdown with compaction proximity estimate and actionable recommendations.
- **To revert:** Delete `.claude/prompts/context-budget.md`. Remove the `context-budget.md` row from the Micro-Components table in `.claude/prompts/README.md`.

#### OPT-85: Framework Health Check Skill (/doctor)
- **New file:** `.claude/skills/doctor/SKILL.md`
- **Modified:** `.claude/skills/SKILLS_INVENTORY.md` (new row in Maintenance table)
- **What:** Created a `/doctor` diagnostic skill that validates: (1) CLAUDE.md commands execute successfully, (2) hook scripts exist and their dependencies are installed, (3) rule path patterns match actual project files, (4) skill dependencies resolve, (5) documentation is current, (6) git state follows conventions. Outputs a structured health report with PASS/WARN/FAIL per check and an overall health score.
- **Why:** `/bootstrap` handles initial setup and `/weekly-maintenance` handles code health, but nothing checks the framework itself. Hooks silently degrade when formatters aren't installed. Rules with stale path patterns never trigger. A health check surfaces these issues before they silently erode quality.
- **To test:** Run `/doctor` in a project. Verify it checks all 6 categories and produces a structured report. Verify it correctly identifies missing tools (WARN) and unconfigured commands (NOT CONFIGURED).
- **To revert:** Delete `.claude/skills/doctor/` directory. Remove the `/doctor` row from SKILLS_INVENTORY.md Maintenance table.

### Quality Tooling (OPT-86)

#### OPT-86: Dead Code Detection in Quality Toolkit
- **Modified:** `.claude/skills/code-quality/SKILL.md` (new step 6 in Analysis Process, new "Dead Code Detection" subsection, new "Dead Code" output section), `.claude/skills/weekly-maintenance/SKILL.md` (dead code check in step 1)
- **What:** Added dead code detection as a standard check in code-quality analysis: unused exports, orphaned functions, unreferenced modules. Uses language-specific tools when available (knip/ts-prune for JS/TS, vulture for Python) with manual grep-based fallback. Added to weekly-maintenance as a periodic check. Findings use the existing confidence scoring (≥80 actionable, 50-79 notes).
- **Why:** AI-assisted development generates more code than manual development — features get refactored, old code isn't always cleaned up. Dead code wastes context when the LLM reads files with unused exports, and represents technical debt. The existing code-quality skill checks complexity, duplication, and patterns, but not dead code.
- **To test:** Run `/code-quality` on a project with known unused exports. Verify the report includes a "Dead Code" section with file:line references and confidence scores.
- **To revert:** Remove step 6 ("Dead code detection") from the Analysis Process list. Remove the "### Dead Code Detection" subsection. Remove the "### Dead Code" section from the output format. Remove the dead code bullet from weekly-maintenance step 1.

### Version Updates

- Updated CLAUDE.md version reference to v2.9
- Updated SKILL_TEMPLATE.md with prerequisites, subagent protocol, and reference budgets
- Updated SKILLS_INVENTORY.md version to 2.9 and added /doctor skill
- Created new skill: `.claude/skills/doctor/SKILL.md`
- Created new micro-component: `.claude/prompts/context-budget.md`

## [2.8.0] - 2026-02-22

### Specification Quality & Planning (OPT-71, OPT-72, OPT-73)

#### OPT-71: Forced Clarification Markers in Story Planning
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 1e), `.claude/skills/story-cycle/references/reasoning-tools.md` (scope_analysis tool)
- **What:** Added `[NEEDS CLARIFICATION: specific question]` convention to story-cycle planning. When the user's intent is ambiguous or multiple valid interpretations exist, the plan must mark uncertainties explicitly instead of making assumptions. Maximum 3 markers before triggering a hard gate for user input. The `scope_analysis` reasoning tool now includes a step 6 that checks each deliverable for ambiguity.
- **Why:** LLMs naturally fill gaps with plausible-sounding assumptions. This convention makes uncertainty visible at planning time, preventing rework from incorrect assumptions. It's the specification equivalent of the `<HARD-GATE>` pattern — but for knowledge gaps.
- **To test:** Run `/story-cycle` with an ambiguous request (e.g., "add user auth"). Verify the plan contains `[NEEDS CLARIFICATION]` markers for decisions like auth method, storage, session handling. Verify markers are presented to user before plan approval.
- **To revert:** Remove `[NEEDS CLARIFICATION]` instruction from story-cycle Phase 1e. Remove step 6 and output format change from `scope_analysis` tool in reasoning-tools.md.

#### OPT-72: Structured Clarification Sub-Phase with Ambiguity Scanning
- **New reasoning tool:** `ambiguity_scan` in `.claude/skills/story-cycle/references/reasoning-tools.md`
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (new Phase 1f between plan draft and approval gate, process flow updated)
- **What:** Added a dedicated clarification check (Phase 1f) that scans the plan for assumptions across seven categories: scope & behavior, data model, UX flow, non-functional requirements, integration dependencies, edge cases, and constraints. Uses a new `ambiguity_scan` reasoning tool that ranks questions by impact (scope > security > UX > technical) and presents top 3-5 to user. Answers integrate directly into the plan before approval.
- **Why:** The `scope_analysis` tool (OPT-71) catches ambiguity in deliverables; this catches ambiguity in the plan itself. Together they form a two-layer defense against incorrect assumptions — at decomposition and at planning.
- **To test:** Run `/story-cycle` with a request that has UX implications (e.g., "add a search feature"). Verify Phase 1f fires after the plan draft and asks focused questions about search behavior, result display, pagination, etc.
- **To revert:** Remove the `## Tool: ambiguity_scan` section from reasoning-tools.md. Remove Phase 1f section and its references from story-cycle SKILL.md. Restore the original process flow (remove Phase 1f and 1g lines).

#### OPT-73: WHAT/WHY vs HOW Separation in Plans with Output Templates
- **New files:** `.claude/skills/story-cycle/references/plan-template.md`, `.claude/skills/ideate/references/story-template.md`
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 1e plan format, YAML frontmatter references), `.claude/skills/ideate/SKILL.md` (story structure, version, YAML frontmatter references), `.claude/skills/story-cycle/references/reasoning-tools.md` (plan_completeness tool — added steps 7-8)
- **What:** Plans now require two distinct sections: Specification (WHAT/WHY — user-visible behavior, acceptance criteria in Given/When/Then, no file paths or technical terms) and Implementation Approach (HOW — files, patterns, technical strategy). Created `plan-template.md` reference with the full structure including anti-patterns. Created `story-template.md` for ideate with user-centric framing (As a/I want/So that), independent testability requirement, and priority justification. Updated `plan_completeness` reasoning tool (now Phase 1g) to verify spec contains zero implementation details and implementation traces to every acceptance criterion.
- **Why:** Mixing specification and implementation in plans leads to premature technical decisions that constrain the solution space. Templates-as-meta-prompts shape LLM behavior through structure (showing the right format) rather than instruction (saying "don't do X"), which is more reliable.
- **To test:** Run `/story-cycle` and verify the plan output has separate Specification and Implementation Approach sections. Verify Specification section has Given/When/Then criteria and no file paths. Read the new template files and verify they include anti-pattern guidance.
- **To revert:** Delete `references/plan-template.md` from story-cycle and `references/story-template.md` from ideate. Remove `references/plan-template.md` from story-cycle YAML frontmatter. Remove `references/story-template.md` from ideate YAML frontmatter. Restore original Phase 1e plan section (single flat list: story type, files, testing, skills, AC, non-goals). Restore original ideate story structure (Description instead of As a/I want). Revert plan_completeness tool to remove steps 7-8 and rename back to Phase 1e.

### Architectural Governance (OPT-74, OPT-75)

#### OPT-74: Project Constitution Pattern
- **New file:** `docs/reference/CONSTITUTION.md`
- **Modified:** `.claude/skills/bootstrap/SKILL.md` (new step A3.6, process flow updated, version bumped), `.claude/skills/story-cycle/SKILL.md` (Phase 1e constitution check, Rules section), `.claude/skills/sprint-end/SKILL.md` (Step 2 constitution compliance gate)
- **What:** Added a "project constitution" concept — a set of non-negotiable architectural principles per project (MUST/SHOULD classification). Created during `/bootstrap` (step A3.6) by prompting user for 3-7 principles. Checked during `/story-cycle` Phase 1e (MUST violation = HALT, SHOULD violation = document justification). Checked during `/sprint-end` quality gates (verify no untracked violations). The constitution template includes sections for principles, amendment history, and tracked violations.
- **Why:** Architectural decisions made in sprint 1 erode by sprint 5 because they exist only in ARCHITECTURE.md prose. A constitution creates checkable constraints validated at planning time and shipping time, catching architectural drift before code is written.
- **To test:** Run `/bootstrap` on a project and verify it prompts for architectural principles and populates CONSTITUTION.md. Run `/story-cycle` with a plan that violates a MUST principle and verify HALT. Run `/sprint-end` and verify constitution compliance is checked.
- **To revert:** Delete `docs/reference/CONSTITUTION.md`. Remove step A3.6 and its process flow line from bootstrap SKILL.md. Remove the `<IF condition="docs/reference/CONSTITUTION.md exists">` block from story-cycle Phase 1e. Remove the constitution compliance `<IF>` block from sprint-end Step 2. Remove the constitution reference from story-cycle Rules section.

#### OPT-75: Violation Tracking with Justification
- **Modified:** `.claude/skills/story-cycle/references/plan-template.md` (Architectural Violations table section)
- **What:** When a story plan violates a constitutional principle, the plan template now requires an explicit table: Principle Violated | Why Needed | Rejected Alternative. These violations are tracked in the constitution's Tracked Violations section and cross-referenced with `docs/technical-debt.md`.
- **Why:** Creates accountability for technical debt at creation time, not retroactively. Forces justification and documentation of what simpler alternative was rejected.
- **To test:** Run `/story-cycle` with a plan that violates a SHOULD principle. Verify the Architectural Violations table appears in the plan with justification.
- **To revert:** Remove the "## Architectural Violations (if any)" section from plan-template.md. Remove the Tracked Violations section from CONSTITUTION.md.

### Workflow Polish (OPT-76, OPT-77)

#### OPT-76: Consistent Handoff Suggestions with Pre-Filled Commands
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (completion report), `.claude/skills/sprint-end/SKILL.md` (sprint complete summary), `.claude/skills/ideate/SKILL.md` (example output), `.claude/skills/brainstorm/SKILL.md` (example output), `.claude/skills/debug-session/SKILL.md` (example output)
- **What:** Every workflow skill's completion output now includes a "Next Steps" section with 1-3 contextual, ready-to-use slash commands. Story-cycle suggests next story/sprint-end/handoff. Sprint-end suggests sprint-start/retrospective/handoff. Ideate suggests sprint-start/story-cycle. Brainstorm suggests ideate/handoff. Debug-session suggests story-cycle/sprint-end/handoff.
- **Why:** Reduces friction between workflow steps. Users can proceed without remembering the workflow sequence or typing commands from memory. The suggestions are contextual — they reference actual workflow state.
- **To test:** Run any workflow skill to completion. Verify the output includes a "Next Steps" section with valid slash commands.
- **To revert:** Remove the "Next Steps" sections from: story-cycle completion report, sprint-end step 7 summary, ideate example, brainstorm example, debug-session example.

#### OPT-77: Per-Phase Context Loading Manifests
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 2 Context Transition)
- **What:** Phase 2 now includes a prescriptive "RELOAD for Phase 3" manifest listing exactly which files to load (CODING_STANDARDS.md, TESTING_STRATEGY.md, plan target files, skill-specific context) and a "SKIP until Phase 4" list (progress.md, ARCHITECTURE.md, backlog files, CONSTITUTION.md). This replaces the previous generic "reload coding standards and relevant files."
- **Why:** The framework's progressive disclosure and context relevance scoring are reactive (classify after loading). Per-phase manifests are prescriptive (define before loading), preventing unnecessary file reads in the first place.
- **To test:** Run `/story-cycle` through Phase 2. Verify Claude loads only the files listed in the RELOAD manifest and does not load files in the SKIP list.
- **To revert:** Restore the original Phase 2 "THEN RELOAD fresh" section (3 generic items) and remove the "RELOAD for Phase 3" and "SKIP until Phase 4" sections.

### Version Updates

- Updated CLAUDE.md version reference to v2.8
- Updated story-cycle, sprint-end, bootstrap, ideate skill versions to 2.8.0
- Added `references/plan-template.md` to story-cycle YAML frontmatter
- Added `references/story-template.md` to ideate YAML frontmatter

## [2.7.0] - 2026-02-22

### Prompt Engineering & Reasoning Quality (OPT-65, OPT-66)

#### OPT-65: Cognitive Reasoning Scaffolds at Critical Decision Points
- **New file:** `.claude/skills/story-cycle/references/reasoning-tools.md`
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 0, Phase 1e, Phase 3), `.claude/skills/debug-session/SKILL.md` (Phase 1d), `.claude/skills/architecture-check/SKILL.md` (Step 2)
- **What:** Created a shared library of 5 named reasoning tools (`scope_analysis`, `test_strategy_selection`, `failure_diagnosis`, `architectural_impact`, `plan_completeness`) — compact step-by-step scaffolds for critical decision points. Skills now reference these tools at their key junctures: story-cycle uses `scope_analysis` in Phase 0, `test_strategy_selection` and `plan_completeness` in Phase 1/3; debug-session uses `failure_diagnosis` in Phase 1d; architecture-check uses `architectural_impact` in Step 2.
- **Why:** Research shows structured reasoning scaffolds improve LLM task performance by 40-60% on complex reasoning (IBM Zurich, June 2025). Skills previously guided *what* to do but not *how to think* at decision points. Named reasoning tools scaffold the thinking process itself, making it more reliable than prose instructions.
- **To test:** Run `/story-cycle` with a compound request. Verify Phase 0 follows the `scope_analysis` steps (numbered list of deliverables with types and complexity ratings). Run `/debug-session` and verify Phase 1d follows the `failure_diagnosis` backward trace steps.
- **To revert:** Delete `.claude/skills/story-cycle/references/reasoning-tools.md`. Remove all "Apply the `*` reasoning tool" references from story-cycle (3 locations), debug-session (1 location), architecture-check (1 location). Remove `references/reasoning-tools.md` from story-cycle YAML frontmatter.

#### OPT-66: Symbolic State Encoding for Compaction
- **Files:** `CLAUDE.md` (Compaction Directive section), `.claude/skills/story-cycle/SKILL.md` (Story-Cycle Context header)
- **What:** Replaced prose-based compaction format with structured key-value (YAML-like) encoding. CRITICAL section now uses `goal:`, `commands:`, `active_plan:` fields. HIGH section uses `branch:`, `sprint:`, `phase:`, `decisions:` fields. Story-Cycle Context header similarly restructured from prose steps to `workflow:`, `phase:`, `remaining_steps:`, `error_recovery:` fields.
- **Why:** LLMs process structured symbolic formats (YAML, key-value pairs) more reliably than natural language prose during context preservation. Each field is atomic and unambiguous, surviving compaction with higher fidelity than paragraph-form descriptions.
- **To test:** Trigger context compaction during a long session. Verify the compacted summary uses key-value format (e.g., `goal: "..."`, `branch: "..."`) rather than prose paragraphs.
- **To revert:** Replace the Compaction Directive in CLAUDE.md with the original markdown-header format from v2.6. Replace the Story-Cycle Context header in story-cycle/SKILL.md with the original numbered prose steps from v2.6.

### Workflow Reliability (OPT-67, OPT-68)

#### OPT-67: Explicit Control Flow Markers (IF/ELSE/LOOP/HALT)
- **Files:** `.claude/skills/SKILL_TEMPLATE.md` (new "Control Flow Markers" section replacing "Hard Gate Pattern"), `.claude/skills/story-cycle/SKILL.md` (Phase 4, Phase 4.5), `.claude/skills/sprint-end/SKILL.md` (Step 5, Project State Adaptation), `.claude/skills/debug-session/SKILL.md` (Phase 3)
- **What:** Extended the `<HARD-GATE>` vocabulary with three new structured control flow markers: `<IF>/<ELSE>` for conditional execution, `<LOOP max="N" until="condition">` for bounded retry loops, and `<HALT reason="...">` for explicit stopping. Added documentation and examples to SKILL_TEMPLATE.md. Replaced prose conditionals in story-cycle (test command check in Phase 4, verification loop in Phase 4.5), sprint-end (CI check in Step 5, command checks in Project State Adaptation), and debug-session (halt after 3 failed fixes).
- **Why:** The `<HARD-GATE>` pattern is one of the framework's strongest innovations. Extending it to conditions and loops makes *all* control flow equally explicit and machine-parseable, reducing Claude's tendency to skip conditional branches or interpret them loosely.
- **To test:** Run `/story-cycle` in a project without a test command. Verify Claude follows the `<ELSE>` branch (skips with note) rather than failing. Run `/sprint-end` and verify CI check uses the `<IF>` conditional. Run `/debug-session` with a hard bug — verify the `<HALT>` triggers after 3 failed fixes.
- **To revert:** In SKILL_TEMPLATE.md, replace the "Control Flow Markers" section with the original "Hard Gate Pattern" section. In story-cycle Phase 4, restore the original numbered list. In story-cycle Phase 4.5, restore the original numbered steps without LOOP/HALT. In sprint-end Step 5, restore the original "If CI is configured... If no CI detected..." prose. In sprint-end Project State Adaptation, restore the original bullet-point format. In debug-session Phase 3, remove the `<HALT>` block.

#### OPT-68: Phase-Specific Error Recovery Tables
- **New files:** `.claude/skills/story-cycle/references/error-recovery.md`, `.claude/skills/debug-session/references/error-recovery.md`, `.claude/skills/sprint-end/references/error-recovery.md`
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Recovery section, Phase 3 reference), `.claude/skills/debug-session/SKILL.md` (Recovery section), `.claude/skills/sprint-end/SKILL.md` (Step 2 reference), `.claude/skills/SKILL_TEMPLATE.md` (Recovery Guidance section)
- **What:** Created phase-specific error/cause/recovery decision tables for all three complex skills. Story-cycle covers 7 phases (19 error patterns). Debug-session covers 5 phases (15 error patterns). Sprint-end covers 6 steps (18 error patterns). Each error has a specific cause and exact recovery action. Skills now reference their error-recovery file in Recovery sections and at high-risk phases. SKILL_TEMPLATE.md updated to recommend this pattern for complex skills.
- **Why:** The `edit-recovery.md` rule demonstrated that structured decision trees improve error handling. This extends the pattern to all major workflow failure modes — preventing Claude from retrying blindly, weakening tests to pass, or making poor recovery choices.
- **To test:** During `/story-cycle`, introduce a deliberate test failure in Phase 3. Verify Claude consults the error-recovery table (reads the Phase 3 section) before attempting a fix. During `/sprint-end`, verify quality gate failures reference the Step 2 recovery table.
- **To revert:** Delete the three `references/error-recovery.md` files. Remove "references/error-recovery.md" from YAML frontmatter in story-cycle and sprint-end. Remove all "consult `references/error-recovery.md`" references from story-cycle (2 locations), debug-session (1 location), sprint-end (1 location). Restore original Recovery Guidance in SKILL_TEMPLATE.md.

### Context Efficiency (OPT-69, OPT-70)

#### OPT-69: Formalized Context Relevance Scoring
- **File:** `.claude/rules/verification.md`
- **What:** Added "Context Relevance Scoring" section with a 5-level classification system (ACTIVE, ANCHORED, REFERENCE, STALE, DUPLICATE) and specific actions for each level. Includes: application triggers (phase transitions, after 5+ file reads, before compaction), and 4 "signs of context rot" detection heuristics.
- **Why:** The existing context budget awareness heuristics are threshold-based triggers. A continuous classification system — applied at phase transitions — ensures stale context is identified and pruned before it degrades reasoning quality. The concept of "context rot" (performance degradation from irrelevant accumulated context) is well-documented in LLM research.
- **To test:** During a long story-cycle session with extensive Phase 1 exploration, verify Claude classifies and prunes context at the Phase 2 transition using the ACTIVE/STALE/DUPLICATE categories. Check that it doesn't re-read files classified as STALE.
- **To revert:** Remove the "## Context Relevance Scoring" section (classification table + application triggers + context rot signs) from verification.md.

#### OPT-70: Reusable Micro-Components for Cross-Skill Operations
- **New files:** `.claude/prompts/discover-commands.md`, `.claude/prompts/quality-gate-sequence.md`, `.claude/prompts/verify-clean-git-state.md`
- **Modified:** `.claude/prompts/README.md` (new "Micro-Components" section), `.claude/skills/sprint-end/SKILL.md` (Project State Adaptation references discover-commands)
- **What:** Extracted 3 commonly duplicated operations into reusable micro-component snippets: `discover-commands` (extract configured commands from CLAUDE.md), `quality-gate-sequence` (run lint → typecheck → test with graceful skipping), `verify-clean-git-state` (check working tree cleanliness). Updated prompts README with a Micro-Components section documenting each component and which skills use it. Sprint-end now references discover-commands in its Project State Adaptation section.
- **Why:** Multiple skills independently implement the same operations (discovering commands, running quality gates, checking git state). Each duplicate costs tokens when loaded and creates maintenance burden. Micro-components reduce duplication while staying lightweight (5-15 lines each).
- **To test:** Read `.claude/prompts/discover-commands.md` and verify it provides clear extraction instructions for CLAUDE.md Commands. Verify `.claude/prompts/README.md` lists all three micro-components in the new section.
- **To revert:** Delete the three `.claude/prompts/*.md` micro-component files (discover-commands, quality-gate-sequence, verify-clean-git-state). Remove the "Micro-Components" section from `.claude/prompts/README.md`. Remove the discover-commands reference from sprint-end Project State Adaptation.

### Version Updates

- Updated CLAUDE.md version reference to v2.7
- Updated story-cycle, debug-session, sprint-end, architecture-check skill versions to 2.7.0
- Added `references/reasoning-tools.md` and `references/error-recovery.md` to skill YAML frontmatter

## [2.6.0] - 2026-02-22

### Code Quality Enforcement (OPT-50, OPT-51)

#### OPT-50: AI Slop Detection Rule
- **New file:** `.claude/rules/code-slop.md`
- **What:** Created a path-scoped rule (all source files) that detects and prevents common AI-generated filler patterns in comments and code. Includes: 15 banned comment patterns (with explanations), obvious comment detection with good/bad examples, code prose anti-patterns, and guidance on when comments ARE required.
- **Why:** AI coding assistants produce predictable slop: obvious comments, filler phrases, and over-explanatory boilerplate. This catches it at the rule level before it accumulates.
- **To test:** Edit a source file and verify Claude avoids patterns like "This function does..." or "Please note that..." in comments.
- **To revert:** Delete `.claude/rules/code-slop.md`.

#### OPT-51: Comment Quality Standards in Coding Standards
- **File:** `docs/reference/CODING_STANDARDS.md`
- **What:** Added "Comment Quality" section between Security and Documentation sections. Documents when comments are required (edge cases, business logic, workarounds) vs prohibited (restating code, explaining types).
- **Why:** Coding standards lacked explicit comment quality guidance. Works in conjunction with OPT-50 rule.
- **To test:** Read CODING_STANDARDS.md and verify the Comment Quality section is present with required/prohibited categories.
- **To revert:** Remove the "### Comment Quality" section (3 bullet points + reference) from CODING_STANDARDS.md.

### Resilience & Error Recovery (OPT-52, OPT-53)

#### OPT-52: Edit Failure Recovery Protocol
- **New file:** `.claude/rules/edit-recovery.md`
- **What:** Created a path-scoped rule (`**`) with a structured recovery decision tree for edit failures. Covers: old_string not found, old_string not unique, file modified externally, and multiple failures on same file. Includes 6 recovery rules.
- **Why:** Edit failures are common in AI-assisted development. Without guidance, Claude retries blindly with stale content or gives up prematurely. The decision tree provides systematic recovery.
- **To test:** Trigger an edit failure (e.g., edit a file that was modified by a hook). Verify Claude re-reads the file before retrying.
- **To revert:** Delete `.claude/rules/edit-recovery.md`.

#### OPT-53: Automated Session State Preservation
- **File:** `.claude/hooks/pre-stop-quality.sh`
- **What:** Added auto-save section at the top of the pre-stop hook that writes minimal session state (branch, recent commits, uncommitted/staged changes) to `docs/sessions/.auto-save.md` before running quality checks. Creates the sessions directory if needed.
- **Why:** `/handoff` is manual. If the user forgets to run it or the session ends unexpectedly, work context is lost. Auto-save is a safety net that `/continue` can fall back to.
- **To test:** Let Claude complete a task. Verify `docs/sessions/.auto-save.md` exists with current branch and recent commits.
- **To revert:** Remove the "Auto-save minimal session state" block (from `SESSIONS_DIR=` to the closing `fi`) from pre-stop-quality.sh.

### Context Management (OPT-54, OPT-55, OPT-56)

#### OPT-54: Priority-Based Context Preservation in Compaction
- **File:** `CLAUDE.md` (Compaction Directive section)
- **What:** Restructured compaction format with four priority levels: CRITICAL (Goal, Commands, Active Plan — never drop), HIGH (Sprint State, Key Decisions, In-Progress Work — preserve if possible), NORMAL (Progress, Blockers — summarize if needed), LOW (File Context — drop first, recoverable). Added multi-compaction rules for priority-based trimming.
- **Why:** Previously all context was treated equally during compaction. Critical items (active plan, commands) sometimes got trimmed while verbose low-value data persisted. Priority tags make the system self-documenting.
- **To test:** Trigger context compaction during a long session. Verify the compacted summary uses the priority-tagged format and that the Active Plan survives.
- **To revert:** Replace the Compaction Directive section in CLAUDE.md with the original flat format from v2.5.

#### OPT-55: Directory-Level Context Files Convention
- **Files:** `.claude/skills/story-cycle/SKILL.md` (Phase 1c), `.claude/rules/documentation.md`
- **What:** Added `.claude-context.md` convention: directories can contain context files with module-specific patterns and conventions. Story-cycle Phase 1c now checks for nearest context file. Documentation rule updated to acknowledge but not proactively create them.
- **Why:** Module-specific context (API conventions, data model patterns, gotchas) doesn't belong in global CLAUDE.md but is valuable during story work. Directory-level files provide targeted context without global bloat.
- **To test:** Create a `.claude-context.md` in a project subdirectory. Run `/story-cycle` targeting that directory. Verify Claude reads the context file during Phase 1c.
- **To revert:** Remove the `.claude-context.md` line from story-cycle Phase 1c and documentation.md.

#### OPT-56: Proactive Context Budget Awareness
- **File:** `.claude/rules/verification.md`
- **What:** Added "Context Budget Awareness" section with 5 heuristics: summarize after 10+ file reads, discard bulk after exploration phases, prefer targeted grep, summarize verbose outputs, and proactively move on from heavy context.
- **Why:** Previously relied on compaction trigger (system-initiated, reactive). Proactive heuristics help the agent self-manage context budget before hitting limits.
- **To test:** During a story-cycle with extensive exploration, verify Claude summarizes findings rather than re-reading files.
- **To revert:** Remove the "## Context Budget Awareness" section (5 bullet points) from verification.md.

### Task Completion & Verification (OPT-57, OPT-58)

#### OPT-57: Task Completion Enforcement
- **File:** `.claude/rules/verification.md`
- **What:** Added "Task Completion Enforcement" section with 4 rules: check task list before reporting done, resolve all pending items, "almost done" is not done, and every created task must be resolved.
- **Why:** The agent sometimes claims completion with outstanding task list items. This closes the gap between stated work plan and actual completion.
- **To test:** During a session where Claude creates a task list, verify it checks all items before claiming done.
- **To revert:** Remove the "## Task Completion Enforcement" section (4 bullet points) from verification.md.

#### OPT-58: Intent Decomposition Gate in Story Cycle
- **File:** `.claude/skills/story-cycle/SKILL.md`
- **What:** Added Phase 0 "Intent Decomposition" before Phase 1. Decomposes the user's request into all distinct deliverables, identifies dependencies, suggests splitting compound requests, and confirms full scope. Updated process flow diagram to include Phase 0.
- **Why:** Complex requests may contain multiple intents ("refactor auth AND add rate limiting AND create a PR"). Without explicit decomposition, later parts get missed after deep exploration fills context.
- **To test:** Run `/story-cycle "refactor auth module and add rate limiting"`. Verify Claude lists both deliverables and confirms scope before exploring.
- **To revert:** Remove the "## Phase 0: Intent Decomposition" section and restore the original process flow diagram without Phase 0.

### Workflow Optimization (OPT-59, OPT-60, OPT-61, OPT-62)

#### OPT-59: Parallel Research Dispatch in Story Planning
- **File:** `.claude/skills/story-cycle/SKILL.md` (Phase 1b)
- **What:** Added "Parallel Research Optimization" note after the sub-agent dispatch section. When a story touches multiple modules, dispatch 2-3 explore agents in parallel with independent questions.
- **Why:** Sequential exploration wastes time when researching different aspects of the codebase. Parallel dispatch saves wall-clock time with no quality trade-off.
- **To test:** Run `/story-cycle` for a cross-module story. Verify multiple explore agents are dispatched simultaneously.
- **To revert:** Remove the "Parallel Research Optimization" paragraph from Phase 1b.

#### OPT-60: Self-Referential Completion Verification Loop
- **File:** `.claude/skills/story-cycle/SKILL.md`
- **What:** Added Phase 4.5 "Completion Verification" between Phase 4 (Wrap Up) and the completion report. Re-checks ALL acceptance criteria with evidence (test output, code references). If gaps found, loops back to Phase 3 (max 2 extra passes). Includes a HARD-GATE requiring evidence before printing the completion report. Updated process flow diagram.
- **Why:** Complex stories often need multiple passes. The agent may complete a first iteration but miss edge cases or secondary requirements. Looping back with evidence checking catches gaps.
- **To test:** Run `/story-cycle` for a story with 3+ acceptance criteria. Verify Claude checks each criterion with evidence before reporting complete.
- **To revert:** Remove the "## Phase 4.5: Completion Verification" section and its HARD-GATE. Restore original process flow without Phase 4.5.

#### OPT-61: Dynamic Skill Content Based on Project State
- **Files:** `.claude/skills/sprint-start/SKILL.md` (Step 1d), `.claude/skills/sprint-end/SKILL.md` (new "Project State Adaptation" section)
- **What:** Sprint-start Step 1d now checks if a test command exists before running tests (skip with note if not configured). Sprint-end adds "Project State Adaptation" section that reads CLAUDE.md Commands before quality gates and adapts based on available tools.
- **Why:** Static skills gave the same instructions regardless of project maturity. A new project without tests shouldn't fail at "verify tests pass" — it should skip with a note.
- **To test:** Run `/sprint-start` in a project with no test command configured. Verify it skips the test step with a note. Run `/sprint-end` in same project — verify quality gates adapt.
- **To revert:** Restore original Step 1d in sprint-start (unconditional test run). Remove "## Project State Adaptation" section from sprint-end.

#### OPT-62: Expanded Graceful Degradation in Sprint-End
- **File:** `.claude/skills/sprint-end/SKILL.md`
- **What:** Added three new rows to the Graceful Degradation table: Linter (skip lint, note in PR), Type checker (skip typecheck, note in PR), `gh` CLI (push manually, create PR via web).
- **Why:** The existing table covered sub-agents, CI, and test runner but missed other common dependencies. Complete coverage prevents stalling on missing tools.
- **To test:** Run `/sprint-end` in a project without a linter. Verify it proceeds and notes the skip in the PR body.
- **To revert:** Remove the three new rows (Linter, Type checker, `gh` CLI) from the Graceful Degradation table.

### Anti-Pattern Libraries (OPT-63, OPT-64)

#### OPT-63: AI-Specific Testing Anti-Patterns
- **File:** `.claude/rules/testing.md`
- **What:** Added "AI-Specific Anti-Patterns" table with 5 entries: hallucinated test APIs, copy-paste assertion drift, weakened assertions to pass, over-specific snapshot tests, and testing framework internals. Each with detection signal and correct action.
- **Why:** The existing red flags list covered general testing anti-patterns but missed AI-specific failure modes. These are predictable mistakes that can be pre-emptively blocked.
- **To test:** Read testing.md and verify the AI-Specific Anti-Patterns table is present after the Red Flags section.
- **To revert:** Remove the "## AI-Specific Anti-Patterns" section (table with 5 rows) from testing.md.

#### OPT-64: AI-Specific Security Anti-Patterns
- **File:** `.claude/rules/security.md`
- **What:** Added "AI-Specific Security Anti-Patterns" table with 5 entries: phantom package imports, typosquatted dependencies, overly permissive CORS, logging sensitive data, and disabled SSL verification.
- **Why:** Extends the CWE checklist with AI-specific security patterns that the general list doesn't cover.
- **To test:** Read security.md and verify the AI-Specific Security Anti-Patterns table is present after the Fix Safety Issues section.
- **To revert:** Remove the "## AI-Specific Security Anti-Patterns" section (table with 5 rows) from security.md.

### Version Updates

- Updated CLAUDE.md version reference to v2.6
- Updated story-cycle, sprint-start, sprint-end skill versions to 2.6.0

## [2.5.0] - 2026-02-22

### Context Efficiency (OPT-40, OPT-41, OPT-42)

#### OPT-40: Script Execution Policy (Black-Box Directives)
- **Files:** `.claude/skills/SKILL_TEMPLATE.md`, `.claude/skills/bootstrap/SKILL.md`, `.claude/skills/sprint-end/references/quality-gates.md`, `.claude/skills/parallel-work/SKILL.md`
- **What:** Added "Script Execution Policy" section to SKILL_TEMPLATE.md and inline black-box directives ("execute directly, do NOT read source first") to skills that reference scripts. Scripts in `scripts/` are treated as black boxes — run them, don't read their source code.
- **Why:** A 50-line script produces 5-10 lines of output. Reading the source before running wastes ~500 tokens of context with zero benefit during normal execution.
- **To test:** Invoke `/sprint-end` and verify Claude runs `test-count-delta.sh` without reading its source first. Invoke `/bootstrap` and verify the same for `detect-stack.sh`.
- **To revert:** Remove the "Script Execution Policy" section from SKILL_TEMPLATE.md. Remove the "execute directly, do NOT read source first" lines from the three skill files.

#### OPT-41: Reference Navigation Pattern (Grep Hints)
- **Files:** `.claude/skills/SKILL_TEMPLATE.md`, `.claude/skills/story-cycle/SKILL.md`, `.claude/skills/debug-session/SKILL.md`
- **What:** Added "Reference Navigation Pattern" to SKILL_TEMPLATE.md. Changed reference pointers in story-cycle and debug-session from "Read file X" to "In file X, search for `## Section` — load only that section." This applies grep-level navigation to reference files.
- **Why:** Reference files can be 100+ lines. Loading the whole file when only one section is needed wastes context. Section-level hints let Claude load just the relevant portion.
- **To test:** Run `/story-cycle` for a Feature story. Verify Claude searches for the Feature section in story-types.md rather than loading the entire file.
- **To revert:** Restore the original "Read `references/story-types.md`" line in story-cycle. Restore the two original "See `references/...`" lines in debug-session. Remove the "Reference Navigation Pattern" section from SKILL_TEMPLATE.md.

#### OPT-42: Resource Types Table (Skill Size & Resource Types)
- **File:** `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Replaced the "Skill Size Guidelines" section with an expanded "Skill Size & Resource Types" section. Includes a table documenting three resource types (`scripts/`, `references/`, `assets/`) with their purpose and context impact. Added `assets/` as a new resource type for output templates (copy, don't read).
- **Why:** Skill authors needed guidance on where to put supporting files and what context impact each location has. The resource types table makes the cost model explicit.
- **To test:** Read SKILL_TEMPLATE.md and verify the resource types table is present with scripts/, references/, and assets/ entries.
- **To revert:** Replace the "Skill Size & Resource Types" section with the original "Skill Size Guidelines" three-line section.

### Skill Development Experience (OPT-43, OPT-44)

#### OPT-43: Skill Scaffolding Script (init-skill.sh)
- **New file:** `.claude/skills/skill-create/scripts/init-skill.sh`
- **Modified:** `.claude/skills/skill-create/SKILL.md`
- **What:** Created a bash script that scaffolds a new skill directory with SKILL.md template (including YAML frontmatter), `references/`, `scripts/`, and `assets/` subdirectories. Updated skill-create Step 3 to reference the script.
- **Why:** Manual skill scaffolding is error-prone — forgetting frontmatter fields, wrong directory structure, missing subdirectories. The script ensures consistent scaffolding.
- **To test:** Run `bash .claude/skills/skill-create/scripts/init-skill.sh test-skill`. Verify it creates `.claude/skills/test-skill/` with SKILL.md, references/, scripts/, assets/. Clean up after: `rm -rf .claude/skills/test-skill`.
- **To revert:** Delete `.claude/skills/skill-create/scripts/init-skill.sh`. Remove the `scripts/init-skill.sh` reference from skill-create/SKILL.md.

#### OPT-44: Input/Output Examples in Skills
- **Files:** `.claude/skills/debug-session/SKILL.md`, `.claude/skills/brainstorm/SKILL.md`, `.claude/skills/ideate/SKILL.md`
- **What:** Added concise Example sections showing a realistic input and the expected output structure for each skill.
- **Why:** Examples are the most context-efficient way to communicate expected behavior. A 6-line example communicates what 20 lines of prose cannot.
- **To test:** Read each skill file and verify the Example section is present with realistic input/output.
- **To revert:** Remove the `## Example` sections from the three skill files.

### Prompt Engineering (OPT-45, OPT-46)

#### OPT-45: Imperative Language Cleanup
- **File:** `.claude/skills/debug-session/SKILL.md`
- **What:** Changed "You must show" to "Show" inside the HARD-GATE block. Minor wording fix for consistency with imperative style used throughout the framework.
- **Why:** Imperative instructions ("Show X") are more direct and context-efficient than second-person ("You must show X"). The framework is 99% compliant; this fixes the last instance.
- **To test:** Read the HARD-GATE in debug-session Phase 1 and verify it uses imperative form.
- **To revert:** Change "Show:" back to "You must show:" in the HARD-GATE block.

#### OPT-46: DO/DON'T Anti-Pattern Pairs
- **Files:** `.claude/skills/story-cycle/SKILL.md`, `.claude/skills/debug-session/SKILL.md`, `.claude/skills/sprint-end/references/quality-gates.md`
- **What:** Added DO/DON'T pairs at critical transition points: story-cycle Phase 2 (context transition), debug-session Phase 1 (investigation before fix), quality-gates (gate completion).
- **Why:** DO/DON'T pairs are high-signal, low-token behavioral anchors. They address the exact moment where Claude is most likely to shortcut (e.g., carrying over stale context, jumping to a fix, skipping agents).
- **To test:** Read each file and verify DO/DON'T pairs are present at the specified locations.
- **To revert:** Remove the "DO / DON'T" blocks from the three files.

### Resilience & Error Handling (OPT-47, OPT-48)

#### OPT-47: Graceful Degradation Pattern
- **Files:** `.claude/skills/SKILL_TEMPLATE.md`, `.claude/skills/sprint-end/SKILL.md`, `.claude/skills/bootstrap/SKILL.md`, `.claude/skills/code-quality/SKILL.md`
- **What:** Added "Graceful Degradation" pattern to SKILL_TEMPLATE.md with a dependency/fallback table. Added skill-specific degradation tables to sprint-end (sub-agents, CI, test runner), bootstrap (package manager, formatter, test runner), and code-quality (linting tools).
- **Why:** Skills previously assumed all dependencies existed. Missing tools (no CI, no linter, no test runner) caused confusion or stalling. Explicit fallbacks make behavior predictable.
- **To test:** Run `/sprint-end` in a project without CI configured. Verify it proceeds with local quality gates instead of stalling.
- **To revert:** Remove the "Graceful Degradation" sections from SKILL_TEMPLATE.md and the three skill files.

#### OPT-48: Pre-Execution Validation Pattern
- **Files:** `.claude/skills/SKILL_TEMPLATE.md`, `.claude/skills/ideate/SKILL.md`, `.claude/skills/handoff/SKILL.md`
- **What:** Added "Pre-Execution Validation" pattern to SKILL_TEMPLATE.md. Added Phase 0 validation to ideate (checks backlog dir and BACKLOG_INDEX.md exist) and handoff (checks docs/sessions/ dir exists).
- **Why:** Skills that produce structured output files can fail halfway through if directories don't exist or input files are missing. Validating prerequisites first prevents wasting context on doomed operations.
- **To test:** Run `/ideate` in a project without `docs/reference/backlog/` directory. Verify it creates the directory or reports the issue before starting decomposition.
- **To revert:** Remove the "Pre-Execution Validation" section from SKILL_TEMPLATE.md. Remove the "Phase 0" sections from ideate/SKILL.md and handoff/SKILL.md.

### Tooling & Automation (OPT-49)

#### OPT-49: Skills Registry Generator (update-registry.sh)
- **New files:** `.claude/skills/skill-create/scripts/update-registry.sh`, `.claude/skills/skills-registry.json`
- **Modified:** `.claude/skills/skill-create/SKILL.md`
- **What:** Created a bash script that walks all `.claude/skills/*/SKILL.md` files, extracts YAML frontmatter, and generates a JSON registry at `.claude/skills/skills-registry.json`. Updated skill-create Step 7 to run the script after creating skills.
- **Why:** The YAML frontmatter added in v2.4 is machine-readable but there's no machine-readable index. The registry enables tooling: automated inventory, dependency graph generation, version checking.
- **To test:** Run `bash .claude/skills/skill-create/scripts/update-registry.sh`. Verify `skills-registry.json` is created with entries for all skills.
- **To revert:** Delete `scripts/update-registry.sh` and `skills-registry.json`. Remove the registry reference from skill-create/SKILL.md Step 7.

## [2.4.0] - 2026-02-22

### Quality & Review Architecture

#### OPT-31: Confidence-Based Scoring for Quality Agents
- **Files:** `.claude/skills/code-quality/SKILL.md`, `.claude/skills/test-validator/SKILL.md`, `.claude/skills/security-audit/SKILL.md`
- **What:** Added 0–100 confidence scoring rubric to all three quality agents. Only findings scoring ≥80 are reported as actionable. Findings 50–79 go in a non-blocking "Notes" section. Below 50: omitted entirely. Output format tables updated with Confidence column.
- **Why:** Quality agents previously reported all findings with equal weight. This created noise — stylistic nitpicks alongside genuine vulnerabilities. Confidence scoring surfaces only actionable issues, reducing sprint-end friction.
- **To test:** Run `/code-quality` or `/test-validator`. Verify output includes confidence scores and separates actionable findings (≥80) from notes (50–79).
- **To revert:** Remove the "## Confidence Scoring" sections and the `Confidence` columns from output format tables in all three quality skill files.

#### OPT-32: Parallel Quality Gate Execution
- **File:** `.claude/skills/sprint-end/references/quality-gates.md`
- **What:** Changed quality agent dispatch from sequential to parallel. All applicable agents (code-quality, test-validator, and conditionally security-audit) now run simultaneously as parallel Task agents.
- **Why:** Sequential execution wasted time and risked one agent's findings biasing another. Parallel dispatch saves ~60% wall-clock time and gives each agent a truly independent perspective.
- **To test:** Run `/sprint-end`. Verify quality agents are dispatched simultaneously (not waiting for one to finish before starting the next).
- **To revert:** In `quality-gates.md`, replace "Dispatch ALL applicable quality agents **simultaneously**" section with the original sequential "Run the following quality agents" text. Remove "Parallel Dispatch" from the heading.

#### OPT-33: Multi-Perspective Independent Code Review
- **Files:** `.claude/prompts/agents/code-reviewer.md`, `.claude/skills/sprint-end/references/quality-gates.md`
- **What:** Added `$3` lens parameter to the code-reviewer template supporting three focused review perspectives: `correctness`, `conventions`, `security`. Each lens reviewer focuses exclusively on its area. Added optional multi-perspective section to quality gates for significant sprints (10+ files). Issues flagged by 2+ independent reviewers are auto-elevated to Critical.
- **Why:** A single reviewer tends to focus on its strongest area and miss others. Multiple independent reviewers with distinct mandates produce more comprehensive coverage and reduce single-perspective blindness.
- **To test:** During sprint-end with significant changes, verify 2–3 code-reviewer agents are dispatched with different `$3` lens values. Verify findings are aggregated with cross-reviewer elevation.
- **To revert:** In `code-reviewer.md`, remove the "## Review Lens: $3" section and the "## Confidence Scoring" section. In `quality-gates.md`, remove the "### Multi-Perspective Code Review" subsection.

### Skill Lifecycle & Measurement

#### OPT-34: Skill Evaluation Framework
- **New files:** `.claude/skills/skill-eval/SKILL.md`
- **Modified:** `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Created `/skill-eval` skill with three modes: `eval` (test a skill against a scenario and grade against criteria), `compare` (blind A/B test two skill versions), and `metrics` (analyze a skill's evaluation readiness). Added `## Evaluation Criteria` section guidance to SKILL_TEMPLATE.md.
- **Why:** Previously, skill iterations (v2.0→v2.3) were based on qualitative observation with no systematic way to verify improvements or catch regressions. This enables data-driven skill development.
- **To test:** Run `/skill-eval metrics story-cycle`. Verify it analyzes the skill's hard gates, red flags, and suggests pressure scenarios. Run `/skill-eval eval story-cycle --scenario "just fix this test quickly"` and verify it grades against evaluation criteria.
- **To revert:** Delete `.claude/skills/skill-eval/` directory. Remove the "## Evaluation Criteria" section from SKILL_TEMPLATE.md.

#### OPT-35: Iterative Refinement Loop
- **New file:** `.claude/skills/refine-loop/SKILL.md`
- **What:** Created `/refine-loop` skill for iterative self-improvement on deliverables. Accepts a task, completion criteria (`--until`), and max iterations (`--max`, default 5). Each iteration must identify SPECIFIC improvements (hard gate prevents vague "make it better"). Produces a completion report with iteration log.
- **Why:** Some tasks benefit from multiple passes (architecture docs, complex designs, prompt refinement). Previously each iteration required manual prompting. This formalizes the loop with safety controls.
- **To test:** Run `/refine-loop "write architecture overview" --until "covers all modules, no TODOs" --max 3`. Verify it iterates with specific improvements and stops when criteria are met or max is reached.
- **To revert:** Delete `.claude/skills/refine-loop/` directory.

### Prompt Engineering & Context Efficiency

#### OPT-36: Agent-First File Discovery Pattern
- **File:** `.claude/skills/story-cycle/SKILL.md`
- **What:** Added Step 1b "File Discovery" to Phase 1, before deep code reading. Dispatches a lightweight Explore agent to identify the 5–10 most relevant files for the story, returning only paths (not contents). Main context then reads only those files. Includes fallback for when sub-agents are unavailable.
- **Why:** During planning, it's common to read 15–20 files. Many turn out irrelevant, wasting context tokens. Agent-first discovery narrows the scope before committing context budget. Subsequent steps renumbered (1c→Research, 1d→Skills, 1e→Plan).
- **To test:** Run `/story-cycle` and observe whether an Explore agent is dispatched early in Phase 1 to identify relevant files before deep reading begins.
- **To revert:** Remove the "### 1b. File Discovery" section from story-cycle/SKILL.md. Renumber 1c/1d/1e back to 1b/1c/1d.

#### OPT-37: Structured Trigger Descriptions with Example Blocks
- **Files:** `.claude/skills/code-quality/SKILL.md`, `.claude/skills/test-validator/SKILL.md`, `.claude/skills/security-audit/SKILL.md`, `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Added `<example>` blocks to auto-invoked skill descriptions with literal phrases that should trigger the skill (2–3 examples each). Added "Example Block Triggers" guidance section to SKILL_TEMPLATE.md.
- **Why:** Prose trigger descriptions can be ambiguous. Concrete example phrases make auto-invocation more reliable by giving the model exact patterns to match.
- **To test:** Verify that typing phrases like "Review code quality for these changes" triggers `/code-quality` auto-invocation.
- **To revert:** Remove `<example>...</example>` tags from the three quality skill description lines. Remove "## Example Block Triggers" section from SKILL_TEMPLATE.md.

### Hook System & Automation

#### OPT-38: Per-Session Hook State Tracking
- **File:** `.claude/hooks/pre-tool-safety.sh`
- **What:** Added session state tracking to the safety hook. Uses a state file in `$TMPDIR/.claude-hook-state/` to remember which patterns have already been blocked. First occurrence shows full block message; repeated occurrences show "(repeated)" suffix. Stale state files (>24h) are auto-cleaned. Refactored all block checks to use a shared `check_and_block` function.
- **Why:** When a developer legitimately triggers the same blocked pattern multiple times (e.g., during cleanup), the same verbose warning fires every time. Session-aware hooks provide consistent blocking but reduce warning fatigue.
- **To test:** Trigger a blocked command (e.g., `git push --force`) twice in the same session. First should show full message; second should show "(repeated)". Verify a new session (after 24h or state file deletion) shows full message again.
- **To revert:** Restore `pre-tool-safety.sh` from git history (v2.3 version). Remove the `STATE_DIR`, `STATE_FILE`, `check_and_block` function, and `find` cleanup. Restore the original inline `echo` + `exit 1` blocks.

### Skill Metadata & Governance

#### OPT-39: YAML Frontmatter for Skill Metadata
- **Files:** All 26 `.claude/skills/*/SKILL.md` files, `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Added YAML frontmatter block to every SKILL.md with structured metadata: `name`, `version`, `description`, `trigger` (manual/auto/conditional), `depends-on` (list of skills this may invoke), `references` (list of reference files). Added "## YAML Frontmatter" documentation section to SKILL_TEMPLATE.md.
- **Why:** Previously, skill metadata was embedded in prose or in the SKILLS_INVENTORY.md table. Structured metadata enables: automated inventory generation, version tracking, dependency validation, and integration with `/skill-eval`.
- **To test:** Read any SKILL.md and verify the YAML frontmatter is present at the top (before the `______________________________________________________________________` line). Run `/skill-eval metrics <skill-name>` and verify it can parse the frontmatter.
- **To revert:** Remove the `---` YAML frontmatter blocks from all 26 SKILL.md files. Remove the "## YAML Frontmatter" section from SKILL_TEMPLATE.md.

## [2.3.0] - 2026-02-22

### Context Efficiency & Skill Architecture

#### OPT-22: Skill Size Budget Enforcement with Reference Splitting
- **Files:** `.claude/skills/story-cycle/SKILL.md` (317→152 lines), `.claude/skills/sprint-end/SKILL.md` (239→148 lines), `.claude/skills/bootstrap/SKILL.md` (332→142 lines)
- **New files:** `story-cycle/references/story-types.md`, `story-cycle/references/self-review.md`, `sprint-end/references/quality-gates.md`, `bootstrap/references/stack-detection.md`, `bootstrap/references/new-project.md`
- **Also moved:** `debug-session/root-cause-tracing.md` and `debug-session/condition-based-waiting.md` into `debug-session/references/`
- **What:** Split the three largest skills into lean SKILL.md files + `references/` subdirectories, following the <150-line guideline already defined in SKILL_TEMPLATE.md. Kept flowcharts, phase skeletons, and hard gates in SKILL.md. Moved detailed checklists, story-type execution details, quality gate specifics, stack detection tables, and new-project workflow to on-demand reference files.
- **Why:** Large skills consumed unnecessary context on every invocation. Most invocations only need a subset (e.g., one story type out of ten). Reference splitting loads detail on demand.
- **To test:** Invoke `/story-cycle`, `/sprint-end`, `/bootstrap` — verify Claude reads reference files when needed. Check line counts: `wc -l .claude/skills/*/SKILL.md | sort -n`
- **To revert:** Restore SKILL.md files from git history (commit before v2.3). Delete all `references/` directories. Move `debug-session/references/*.md` back to `debug-session/`.

#### OPT-23: Helper Scripts Bundled with Skills
- **New files:** `sprint-end/scripts/test-count-delta.sh`, `bootstrap/scripts/detect-stack.sh`, `parallel-work/scripts/worktree-status.sh`
- **What:** Added executable helper scripts to skills for repetitive multi-step operations. Each script supports `--help`, outputs structured results, and can be invoked as a black box without reading source.
- **Why:** Skills previously instructed Claude to compose complex bash sequences from prose. Scripts are deterministic, testable, and don't consume context tokens explaining what they do.
- **To test:** Run `bash .claude/skills/sprint-end/scripts/test-count-delta.sh --help` — should show usage. Run in a project with tests to see delta output.
- **To revert:** Delete the three `scripts/` directories. Remove the `test-count-delta.sh` reference from `sprint-end/references/quality-gates.md` and restore the inline bash instructions.

#### OPT-28: "Context Window is a Shared Resource" Principle
- **File:** `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Added explicit "Core Principle" section framing the context window as a shared resource. States: "Claude is already very smart — only add context it doesn't already know." Reinforces the 150-line budget and reference-splitting pattern.
- **Why:** Prevents future skill bloat by making the cost model explicit for skill creators.
- **To test:** Read SKILL_TEMPLATE.md and verify the principle is at the top. Create a new skill and verify it follows the budget.
- **To revert:** Remove the "Core Principle: Context Window is a Shared Resource" section from SKILL_TEMPLATE.md.

### Quality & Verification

#### OPT-24: "Assume Problems Exist" QA Framing
- **Files:** `.claude/skills/code-quality/SKILL.md`, `.claude/skills/test-validator/SKILL.md`, `.claude/skills/sprint-end/SKILL.md`
- **What:** Added skeptical QA opening to quality agents and sprint-end quality gates: "Assume there are problems. Your job is to find them. Your first assessment is almost never 'all clear.'"
- **Why:** Starting from "verify it works" creates confirmation bias. Starting from "find the problems" creates thoroughness. Quality agents in forked contexts have no investment in the code being correct.
- **To test:** Run `/code-quality` or `/test-validator` on code. Verify the agent's output is specific and cites file:line, not vague "looks good."
- **To revert:** Remove the "**Mindset:**" paragraph from code-quality/SKILL.md, test-validator/SKILL.md, and sprint-end/SKILL.md step 2.

#### OPT-25: Explicit "Don'ts" Lists in Quality Skills
- **Files:** `.claude/skills/code-quality/SKILL.md`, `.claude/skills/test-validator/SKILL.md`, `.claude/skills/skill-create/SKILL.md`
- **What:** Added "Common Mistakes — NEVER" tables with concrete examples of bad output and what to do instead.
- **Why:** Claude responds more strongly to "NEVER do this: [example]" than to abstract quality guidelines. Concrete anti-patterns make expectations unambiguous.
- **To test:** Run `/code-quality`. Verify the report includes file:line references (not vague summaries) and checks complexity before style.
- **To revert:** Remove the "Common Mistakes — NEVER" tables from the three skill files.

#### OPT-26: "Discover Before Invoking" CLI Pattern
- **Files:** `.claude/rules/verification.md`, `.claude/skills/code-quality/SKILL.md`, `.claude/skills/test-validator/SKILL.md`, `.claude/skills/bootstrap/references/stack-detection.md`
- **What:** Added universal rule: "Before invoking any CLI tool with flags you're unsure about, run `[tool] --help` first." Applied to verification rule (global), quality agents, and bootstrap stack detection.
- **Why:** Claude frequently hallucinates CLI flags — especially for tools that change between versions. Running `--help` first grounds Claude in the actual installed version.
- **To test:** During bootstrap, observe whether Claude runs `--help` on unfamiliar tools before invoking them with flags.
- **To revert:** Remove the `--help` line from verification.md. Remove "Run `[tool] --help` first" instructions from code-quality, test-validator, and stack-detection.md.

### Documentation Quality

#### OPT-27: Fresh-Perspective Sub-Agent Document Testing
- **Files:** `.claude/skills/bootstrap/SKILL.md` (A5.7), `.claude/skills/ideate/SKILL.md`, `.claude/skills/handoff/SKILL.md` (4.5), `.claude/skills/story-cycle/references/story-types.md` (Documentation type)
- **What:** Added document quality check step that dispatches a fresh sub-agent with ONLY the generated document (no authoring context) to identify gaps, ambiguities, and assumed context.
- **Why:** Claude suffers from "context blindness" — things obvious during authoring become confusing to a reader without that context. Documents are the primary communication mechanism in this framework (session handoffs, architecture docs, story specs). Testing them from a reader's perspective catches blind spots.
- **To test:** Run `/handoff` and observe whether a sub-agent reviews the session file. Check if the review catches genuinely missing information.
- **To revert:** Remove step A5.7 from bootstrap/SKILL.md. Remove "Document Quality Check" sections from ideate/SKILL.md and handoff/SKILL.md. Remove step 5 from the Documentation story type in story-types.md.

### Extensibility

#### OPT-29: Co-Located Reference Architecture for Generated Tech Skills
- **File:** `.claude/skills/skill-create/SKILL.md`
- **What:** Changed reference doc location from `docs/reference/tech/<name>.md` to `.claude/skills/<tech-name>/references/` (co-located with the skill). Updated skill file structure template to show lean SKILL.md (<100 lines) + references/ subdirectory. Added "Common Mistakes — NEVER" table.
- **Why:** Co-locating references with skills keeps everything self-contained. SKILL.md can use relative paths (`references/api.md`). Skills become portable and context-efficient: lean SKILL.md auto-loads, detailed references load on demand.
- **To test:** Run `/skill-create` on a project. Verify generated skills have `references/` subdirectories with detailed content, and SKILL.md files are under 100 lines with pointers.
- **To revert:** Restore `docs/reference/tech/` as the reference location. Remove the updated file structure template and restore the old monolithic skill template.

### Workflow Resilience

#### OPT-30: Conditional Environment Adaptation
- **Files:** `.claude/skills/sprint-end/SKILL.md` (step 5), `.claude/skills/story-cycle/SKILL.md` (Phase 3.5), `.claude/skills/bootstrap/references/stack-detection.md` (A2.6)
- **What:** Added fallback instructions for environment-dependent steps. Sprint-end: if no CI, local gates serve as verification. Story-cycle: if no sub-agents, perform self-review manually. Bootstrap: if no coverage tool, record "N/A" instead of failing.
- **Why:** Skills previously assumed capabilities that may not exist in every environment (CI runners, sub-agents, coverage tools). Fallbacks prevent confusion and stalling.
- **To test:** Run `/sprint-end` in a project without CI. Verify it proceeds with local quality gates instead of stalling on `gh pr checks`.
- **To revert:** Remove the conditional blocks ("If CI is configured... If no CI detected...", "If sub-agents are available... If not...", "If no coverage tool detected...") from the three files.

## [2.2.0] - 2026-02-22

### Process Compliance & Enforcement

#### OPT-10: Hard Gate Markers in Skills
- **Files:** `.claude/skills/story-cycle/SKILL.md`, `.claude/skills/sprint-end/SKILL.md`, `.claude/skills/ideate/SKILL.md`, `.claude/skills/brainstorm/SKILL.md`
- **What:** Added `<HARD-GATE>` XML-style markers at critical decision points to prevent Claude from skipping mandatory steps (plan approval before code, quality gates before merge, user approval before backlog writes).
- **Why:** Prose rules ("NEVER skip planning") can be rationalized around. Explicit gate markers create a stronger enforcement barrier within the flow.
- **To test:** Run `/story-cycle` and observe whether Claude waits for plan approval. Run `/sprint-end` and verify it stops if quality gates fail rather than proceeding.
- **To revert:** Remove all `<HARD-GATE>...</HARD-GATE>` blocks from the four skill files.

#### OPT-11: Skill Description Audit (Trigger-Only Pattern)
- **Files:** `.claude/skills/story-cycle/SKILL.md`, `.claude/skills/sprint-end/SKILL.md`, `.claude/skills/ideate/SKILL.md`, `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Rewrote skill descriptions from workflow summaries to trigger-only format ("Use when..."). Added "Description Trap Warning" section to SKILL_TEMPLATE.md documenting the anti-pattern.
- **Why:** When descriptions summarize workflow steps, Claude uses the description as a shortcut instead of reading the full skill content. Trigger-only descriptions force Claude to read the body for workflow details.
- **To test:** Invoke `/story-cycle` and verify Claude follows all 4 phases (not a simplified version). Check that description in skill listings says "Use when..." not a workflow summary.
- **To revert:** Restore original description lines: story-cycle: "Deliver a single story using the right methodology for its type. Starts in plan mode, clears context after plan approval, then executes." sprint-end: "Complete a sprint by discovering work from git, running quality gates, updating docs, creating PR, and merging to main." ideate: "Transform ideas and requirements into properly typed, LLM-optimized backlog stories with testing strategy and skill metadata. Stories are sized for a single context window." Remove "Description Trap Warning" section from SKILL_TEMPLATE.md.

#### OPT-12: Verification-Before-Completion Rule
- **File:** `.claude/rules/verification.md` (NEW)
- **What:** Created a new path-scoped rule (`**` — all files) that requires Claude to show actual command output as evidence before claiming task completion.
- **Why:** Claude frequently says "tests pass" or "should work" without running the verification command. This rule mandates fresh evidence: run the command, show the output.
- **To test:** During a story-cycle, verify Claude runs the test command and shows output before claiming done. Check that it doesn't say "I already ran this" without re-running.
- **To revert:** Delete `.claude/rules/verification.md`.

#### OPT-13: Red Flag Tables in Key Skills
- **Files:** `.claude/skills/story-cycle/SKILL.md`, `.claude/skills/sprint-end/SKILL.md`
- **What:** Added "Red Flags — Stop If You're Thinking" tables listing common rationalizations and their refutations to key workflow skills.
- **Why:** Claude doesn't randomly skip steps — it rationalizes. Pre-empting common rationalizations ("the user wants this fast", "tests probably pass") catches shortcutting before it happens.
- **To test:** During a story-cycle, observe whether Claude completes the self-review rather than jumping to commit. During sprint-end, verify it runs fresh tests rather than relying on prior results.
- **To revert:** Remove the "Red Flags" tables from story-cycle/SKILL.md (in Phase 3.5) and sprint-end/SKILL.md (after Step 2c).

### Quality During Execution

#### OPT-14: Inline Self-Review in Story-Cycle
- **File:** `.claude/skills/story-cycle/SKILL.md`
- **What:** Added Phase 3.5 "Self-Review Before Wrap-Up" between execution and wrap-up. Includes checklists for completeness, quality, testing, discipline, and spec compliance (for 4+ AC stories).
- **Why:** Quality checks previously happened only at sprint-end. This catches issues during story execution while context is fresh and fixes are cheap.
- **To test:** Run a story-cycle for a feature story. Verify Claude completes Phase 3.5 checklist (including running tests and showing output) before Phase 4.
- **To revert:** Remove the entire "Phase 3.5: Self-Review Before Wrap-Up" section from story-cycle/SKILL.md.

#### OPT-15: Spec-Compliance Review for Complex Stories
- **File:** `.claude/skills/story-cycle/SKILL.md` (within Phase 3.5)
- **What:** Added spec compliance sub-section within the self-review: for stories with 4+ acceptance criteria, Claude must re-read each criterion and find the implementing code and test, citing file:line.
- **Why:** Claude's confidence about what it implemented can diverge from actual code, especially in longer sessions. Deliberate re-reading catches this drift.
- **To test:** Run a story-cycle for a story with 4+ acceptance criteria. Verify Claude produces a criterion-by-criterion verification with file:line references.
- **To revert:** Remove the "Spec Compliance" sub-section from Phase 3.5 in story-cycle/SKILL.md.

### Debugging Enhancement

#### OPT-16: Deepened Debug Session Skill
- **Files:** `.claude/skills/debug-session/SKILL.md` (REWRITTEN), `.claude/skills/debug-session/root-cause-tracing.md` (NEW), `.claude/skills/debug-session/condition-based-waiting.md` (NEW)
- **What:** Rewrote debug-session from a 65-line template into a rigorous 5-phase process (Root Cause Investigation → Pattern Analysis → Hypothesis Testing → Fix Implementation → Verify) with hard gates, stopping points, and two supporting reference files.
- **Why:** The original skill was a lightweight template that didn't prevent guess-and-check debugging. The new version mandates root cause identification before any fix attempt, limits changes to one variable at a time, and stops after 3 failed attempts.
- **To test:** Run `/debug-session "TypeError in X"` and verify Claude follows the 5-phase process, starting with root cause investigation and NOT jumping to a fix.
- **To revert:** Replace SKILL.md with the original 65-line version (see git history). Delete root-cause-tracing.md and condition-based-waiting.md.

### Workflow Enhancement

#### OPT-17: Brainstorm Skill (Design Exploration)
- **File:** `.claude/skills/brainstorm/SKILL.md` (NEW)
- **What:** Created a `/brainstorm` skill for structured design exploration before story decomposition. Guides through problem space exploration, codebase research, 2-3 alternative approaches with tradeoffs, risk identification, and design approval.
- **Why:** `/ideate` goes straight to story decomposition. For complex features, exploring the solution space first prevents building the wrong thing. Brainstorm produces a design document that feeds into ideate.
- **To test:** Run `/brainstorm "add payment processing"` and verify Claude explores alternatives, presents tradeoffs, and waits for design approval before suggesting stories.
- **To revert:** Delete `.claude/skills/brainstorm/` directory.

#### OPT-18: Process Flowcharts in Complex Skills
- **Files:** `.claude/skills/story-cycle/SKILL.md`, `.claude/skills/sprint-end/SKILL.md`, `.claude/skills/bootstrap/SKILL.md`
- **What:** Added ASCII process flowcharts at the top of the three most complex skills, marked as "authoritative — prose below is supporting detail."
- **Why:** Claude follows structured process definitions more reliably than numbered prose lists. Flowcharts make decision points, branches, and terminal states explicit. When prose and flowchart disagree, the flowchart wins.
- **To test:** Run each skill and verify Claude follows the flowchart order, including decision points (e.g., "User approved?" in story-cycle).
- **To revert:** Remove the "Process Flow" sections from the top of each skill file.

### Subagent Improvement

#### OPT-19: Subagent Prompt Templates
- **Files:** `.claude/prompts/agents/code-reviewer.md` (NEW), `.claude/prompts/agents/spec-reviewer.md` (NEW)
- **What:** Created reusable prompt templates for dispatching code review and spec compliance subagents. Each includes structured checklists, context slots ($1, $2), and explicit instructions to read actual code (not trust claims).
- **Why:** Quality agents (code-quality, test-validator) receive minimal context when dispatched. Structured templates with self-review checklists and skepticism injection improve subagent output quality.
- **To test:** During sprint-end, use the code-reviewer template when dispatching quality agents. Verify the agent produces file:line references and severity classifications.
- **To revert:** Delete `.claude/prompts/agents/` directory.

### Skill Development Methodology

#### OPT-20: TDD for Skill Creation
- **File:** `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Added "Skill Testing Methodology" section describing how to apply TDD to skill documentation: define pressure scenario (RED) → verify Claude fails without skill → write skill (GREEN) → verify compliance → refine.
- **Why:** Skills are documentation, but they can be tested. A pressure scenario is a realistic prompt that would cause Claude to make a mistake without the skill. Testing against pressure scenarios ensures skills actually change behavior.
- **To test:** Create a new skill using the methodology. Verify the pressure scenario fails without the skill and succeeds with it.
- **To revert:** Remove the "Skill Testing Methodology" section from SKILL_TEMPLATE.md.

### Safety

#### OPT-21: Fix-Immediately Pattern for Safety Issues
- **File:** `.claude/rules/security.md`
- **What:** Added "Fix Safety Issues Immediately" section instructing Claude to fix safety issues discovered during normal work without asking or deferring — exposed secrets, missing .gitignore entries, unsafe permissions, missing input validation.
- **Why:** Safety issues should never be deferred. A discovered exposed secret should be removed immediately, not logged for later. This prevents broken state from propagating.
- **To test:** During development, introduce a scenario where a secret is accidentally in code. Verify Claude removes it immediately and commits the fix.
- **To revert:** Remove the "Fix Safety Issues Immediately" section from security.md.

### Meta

#### Hard Gate and Red Flag Patterns Added to SKILL_TEMPLATE.md
- **File:** `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Added documentation for the Hard Gate pattern, Red Flag Tables pattern, and Description Trap Warning as standard skill design guidelines.

## [2.1.0] - 2026-02-22

### Context Management

#### OPT-1: Structured Compaction Summary Template
- **File:** `CLAUDE.md` (Compaction Directive section)
- **What:** Replaced the flat "preserve these items" directive with a concrete markdown template that tells Claude exactly how to structure compacted summaries (Goal, Sprint State, Progress, Decisions, Commands, Plan, File Context with `<files-read>`/`<files-modified>` tags).
- **Why:** Compaction quality was inconsistent — Claude knew *what* to keep but not *how* to organize it. Structured format produces reliable, machine-parseable summaries.
- **To test:** Start a long story-cycle session, let context compact, verify the summary follows the structured format.
- **To revert:** Restore original one-line directive in CLAUDE.md.

#### OPT-5: Cumulative File Tracking Across Context Boundaries
- **File:** `.claude/skills/story-cycle/SKILL.md` (Story-Cycle Context header)
- **What:** Added `<files-read>` and `<files-modified>` structured tags to the story-cycle context header. These accumulate across compactions so Claude never loses track of explored files.
- **Why:** After compaction, Claude would re-read files it had already explored, wasting context budget.
- **To test:** During a story-cycle, note which files are read. After compaction, verify Claude doesn't re-read them unnecessarily.
- **To revert:** Remove the "File Context" section from the Story-Cycle Context template in story-cycle/SKILL.md.

#### OPT-7: Graduated Context Reset in Story-Cycle
- **File:** `.claude/skills/story-cycle/SKILL.md` (Phase 2)
- **What:** Replaced binary "clear everything" context reset with selective pruning: keep discovery metadata (file paths, edge cases, pattern snippets) while discarding bulk content (full file reads, dead-end searches).
- **Why:** The binary reset discarded valuable insights from the planning phase. The graduated approach preserves insights (~200 tokens) without the bulk (~20,000 tokens).
- **To test:** Run a story-cycle with a complex planning phase. After Phase 2 transition, verify edge cases and patterns from Phase 1 are still referenced.
- **To revert:** Restore Phase 2 to the original "clear and reload" instructions.

### Session Management

#### OPT-2: Enriched Session Handoff with File Access History
- **Files:** `.claude/skills/handoff/SKILL.md`, `.claude/skills/continue/SKILL.md`
- **What:** Expanded handoff session template from a single "Files Modified" section to three categories: Modified (with reasoning), Read (context-relevant), and Investigated (can skip on resume). Added step 1.5 to /continue for selective context reload from file access log.
- **Why:** /continue previously knew what was *changed* but not what was *explored*. This led to re-reading files already investigated.
- **To test:** Run /handoff at end of session. Verify session file has three file categories. Start new session with /continue. Verify it selectively reloads from the log.
- **To revert:** Restore "Files Modified This Session" in handoff/SKILL.md. Remove step 1.5 from continue/SKILL.md.

#### OPT-8: Health Dashboard in /continue
- **File:** `.claude/skills/continue/SKILL.md`
- **What:** Added step 5.5 showing a quick health pulse when resuming: test status, last commit time, open changes count, session file age.
- **Why:** Developers returning to a session want instant confidence: "are things green?"
- **To test:** Run /continue in a project with tests and a session file. Verify the health dashboard appears before the options menu.
- **To revert:** Remove the "5.5. Health Dashboard" section from continue/SKILL.md.

### Enforcement & Safety

#### OPT-3: Expanded Pre-Tool Safety Patterns
- **File:** `.claude/hooks/pre-tool-safety.sh`
- **What:** Added blocks for: package publishing (npm publish, cargo publish, twine upload, gem push, pod trunk push), destructive database operations (DROP TABLE/DATABASE, TRUNCATE TABLE), and mass process killing (kill -9 -1, killall, pkill -9).
- **Why:** The original 6 patterns covered git and rm-rf. These additions prevent other high-impact, hard-to-reverse operations.
- **To test:** Try running `npm publish` or `DROP TABLE users` via Bash — should be blocked. Verify normal operations still work.
- **To revert:** Remove the three new `if` blocks (package publishing, database, process killing) from pre-tool-safety.sh.

#### OPT-6: Incremental Linting in Post-Edit Hook
- **File:** `.claude/hooks/post-edit-format.sh`
- **What:** Added a lint step (auto-fix mode, quiet) after the existing format step. Runs per-file lint for Python (ruff), JavaScript/TypeScript (eslint/biome), and Go (golangci-lint). Skips Rust and Swift which need full project context.
- **Why:** Lint errors previously accumulated silently until sprint-end. Now they're caught and auto-fixed immediately.
- **To test:** Edit a Python or TypeScript file with a lint issue (e.g., unused import). Verify it's auto-fixed after the edit.
- **To revert:** Remove the second `case` block (after the "run linter" comment) from post-edit-format.sh.

### Skill System

#### OPT-4: Skill Error Recovery Guidance
- **Files:** `.claude/skills/SKILL_TEMPLATE.md`, `.claude/skills/sprint-end/SKILL.md`, `.claude/skills/story-cycle/SKILL.md`
- **What:** Added Recovery sections with explicit failure handling: test failures (new vs pre-existing), git conflicts, quality gate failures, context exhaustion, CI failures.
- **Why:** When a step failed mid-skill, Claude's behavior was undefined. Explicit recovery instructions make behavior predictable.
- **To test:** Introduce a deliberate test failure during story-cycle. Verify Claude follows the recovery protocol instead of skipping or masking.
- **To revert:** Remove "Recovery" sections from the three files. In sprint-end, remove the "Recovery: If Quality Gates Fail" block above step 3.

#### OPT-9: Lightweight Prompt Snippets System
- **Files:** `.claude/prompts/README.md`, `.claude/prompts/review-security.md`, `.claude/prompts/explain-pattern.md`, `.claude/prompts/suggest-tests.md`, `.claude/skills/SKILLS_INVENTORY.md`
- **What:** Created a `.claude/prompts/` directory for simple parameterized prompt templates. Includes 3 starter snippets: review-security, explain-pattern, suggest-tests. Uses `$1`/`$2`/`$@` argument syntax.
- **Why:** Gap between ad-hoc prompts and full workflow skills. Common prompts like "review this file for security" shouldn't require 100+ lines of skill scaffolding.
- **To test:** Run `/review-security src/some-file.ts` and verify it produces a structured security review. Run `/suggest-tests src/another-file.py` and verify test suggestions.
- **To revert:** Delete `.claude/prompts/` directory. Remove the "Prompt Snippets" section from SKILLS_INVENTORY.md.

### Meta

#### Version updated
- **File:** `.claude/skills/SKILLS_INVENTORY.md` (Version History table)
- **What:** Added v2.1 entry with date and summary of all changes.

## [2.0.0] - 2026-02-21

Hooks, rules, worktrees, test protection, CWE checks, metrics, architecture-check, parallel-work, session persistence, context management.

## [1.1.0] - 2026-02-21

Added testing workflow: UAT-cycle, testing-cycle, manual-test.

## [1.0.0] - 2026-02-21

Initial framework release: 18 skills, bootstrap flow.
