# Changelog

## [3.5.0] - 2026-03-14

### Context Efficiency & Knowledge Reuse (OPT-125 through OPT-132)

#### OPT-125: Grep-First Codebase Exploration
- **New:** `.claude/prompts/grep-first-explore.md` (micro-component for pre-filtering files via targeted Grep before reading)
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 1b replaced parallel agent-only exploration with grep-first pattern, added `grep-first-explore` to phase-1 micro-components, version bumped to 3.6.0)
- **What:** Phase 1b now uses targeted Grep calls to identify relevant files before reading them, dramatically reducing context consumption. Exploration depth scales with story size: TRIVIAL skips exploration, SMALL uses grep-first only, STANDARD adds codebase-explorer agents, STANDARD + High-risk adds security-focused grep.
- **Why:** The previous approach launched 3 parallel codebase-explorer agents that read broadly. For larger codebases, this consumed significant context budget on files that turned out to be irrelevant. Grep-first pre-filters candidates, reducing reads from O(n) to O(relevant).
- **To test:** Run `/story-cycle` on a SMALL story. Verify Phase 1b uses grep-first exploration (parallel Grep calls, file ranking) rather than dispatching 3 agents. For STANDARD stories, verify grep-first runs first followed by 1-2 targeted agents.
- **To revert:** Delete `.claude/prompts/grep-first-explore.md`. In story-cycle SKILL.md: restore the original Phase 1b section (3 parallel codebase-explorer agents), remove `grep-first-explore` from phase-1 micro-components. Revert story-cycle version to 3.5.0.

#### OPT-126: Solutions Database & Learnings Capture
- **New:** `.claude/prompts/capture-learnings.md` (micro-component for persisting learnings from completed stories)
- **New:** `docs/solutions/` directory (searchable solutions database with YAML frontmatter)
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added learnings capture step to Phase 4, added `capture-learnings` to phase-4 micro-components, Phase 1b now checks `docs/solutions/` for prior learnings)
- **Modified:** `.claude/skills/bootstrap/SKILL.md` (added step A5.95 to scaffold `docs/solutions/` and `docs/brainstorms/`, version bumped to 2.11.0)
- **What:** Completed stories can produce structured learnings documents in `docs/solutions/` with searchable YAML frontmatter (title, tags, module, component). During Phase 1b, the grep-first-explore pattern searches these documents for prior learnings on affected modules, preventing rediscovery of known patterns.
- **Why:** Positive learnings (what worked, integration gotchas, architectural decisions) were lost after session handoff notes aged out. Error-patterns captured failures, but successful approaches had no persistence mechanism.
- **To test:** Complete a `/story-cycle` on a story that involves a non-obvious approach. Verify a solution document is created in `docs/solutions/`. Start a new story touching the same module. Verify Phase 1b checks `docs/solutions/` for prior learnings.
- **To revert:** Delete `.claude/prompts/capture-learnings.md` and `docs/solutions/`. In story-cycle SKILL.md: remove the "Capture learnings" step from Phase 4, remove `capture-learnings` from phase-4 micro-components, remove the "Prior learnings check" paragraph from Phase 1b. In bootstrap SKILL.md: remove step A5.95. Revert bootstrap version to 2.10.0.

#### OPT-127: Research Decision Gate
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 1c.5 now has a three-signal decision gate before online verification)
- **What:** Phase 1c.5 (Online Verification) is now conditional. A decision gate evaluates three signals — risk level, local context strength, and uncertainty level — before deciding whether external research is needed. The decision is announced transparently to the user.
- **Why:** Previously, online verification ran for every non-trivial story. For well-understood internal changes with strong local patterns, this wasted context and time. High-risk changes (security, new APIs, unfamiliar libraries) still always get researched.
- **To test:** Run `/story-cycle` on a low-risk internal refactoring with established patterns. Verify the research decision gate skips online verification with a note. Then run on a story touching a new external API — verify it proceeds with research.
- **To revert:** In story-cycle SKILL.md: replace the Phase 1c.5 section with the original (always-on) version that starts with "Before planning, verify that the approach and APIs are current."

#### OPT-128: Hook Error Isolation
- **Modified:** `.claude/hooks/engine.py` (wrapped handler dispatch in try-except with error logging)
- **What:** Individual hook handler failures are now isolated — a crash in one handler (e.g., YAML parsing failure, missing state file) no longer blocks the entire hook event pipeline. Errors are logged to stderr for visibility.
- **Why:** If a handler threw an unexpected error, it crashed the entire hook dispatch, potentially blocking legitimate tool usage or silently disabling enforcement. Each handler should fail independently.
- **To test:** Temporarily introduce a syntax error in one handler module. Verify that other hook events still work and the error is reported on stderr.
- **To revert:** In engine.py: remove the try-except block around `handler.handle()`, restoring the direct `result = handler.handle(...)` call.

#### OPT-129: Depth-Controlled Exploration
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 1b exploration depth now scales with story size classification)
- **What:** The number of exploration streams in Phase 1b scales with story size: TRIVIAL skips entirely, SMALL uses a single grep-first pass, STANDARD uses grep-first plus 1-2 codebase-explorer agents, STANDARD + High-risk adds a security-focused grep stream.
- **Why:** The one-size-fits-all dispatch of 3 parallel agents wasted context on small changes and didn't provide extra security focus for high-risk stories. Better resource allocation follows the existing risk calibration matrix.
- **To test:** Run `/story-cycle` on a TRIVIAL story — verify Phase 1b is skipped. Run on a SMALL story — verify single grep-first pass. Run on a STANDARD story — verify grep-first plus agents.
- **To revert:** This is integrated into the OPT-125 Phase 1b changes. Revert OPT-125 to restore the original 3-agent approach.

#### OPT-130: Brainstorm Document Artifacts
- **New:** `docs/brainstorms/` directory (persisted design exploration documents)
- **Modified:** `.claude/skills/brainstorm/SKILL.md` (added Phase 6 to persist design documents with YAML frontmatter, renumbered Phase 7, version bumped to 2.6.0)
- **Modified:** `.claude/skills/ideate/SKILL.md` (Phase 1 now checks `docs/brainstorms/` for prior design documents, version bumped to 2.9.0)
- **What:** `/brainstorm` now saves approved designs to `docs/brainstorms/<topic-slug>.md` with YAML frontmatter (title, date, status, decision). `/ideate` checks for existing brainstorm artifacts before starting decomposition. `/bootstrap` scaffolds the directory.
- **Why:** Brainstorm output was conversation-only, lost after the session. When a brainstormed idea became a story weeks later, all design exploration had to be redone.
- **To test:** Run `/brainstorm` on an idea, approve a design. Verify a document is saved to `docs/brainstorms/`. Run `/ideate` on the same topic — verify it loads the brainstorm document as context.
- **To revert:** Delete `docs/brainstorms/`. In brainstorm SKILL.md: remove Phase 6, renumber Phase 7 back to Phase 6. In ideate SKILL.md: remove the "Check for prior brainstorm artifacts" paragraph from Phase 1. Revert brainstorm version to 2.5.0, ideate to 2.8.0.

#### OPT-131: Skill Cross-Reference Registry
- **Modified:** `.claude/skills/skills-registry.json` (added `calls` field to each skill entry declaring which other skills it invokes)
- **Modified:** `.claude/skills/doctor/SKILL.md` (added skill cross-reference validation to Section 4, version bumped to 3.0.0)
- **What:** The skills registry now includes a `calls` field for each skill, creating a machine-readable dependency graph. `/doctor` validates that all referenced skills exist and reports broken references or orphaned skills.
- **Why:** Skill dependencies were only discoverable by reading each SKILL.md. A machine-readable graph enables automated validation and impact assessment when modifying skills.
- **To test:** Run `/doctor`. Verify the new "Skill Dependencies & Cross-References" section appears in the health report. Temporarily add a non-existent skill to a `calls` array — verify `/doctor` reports a broken reference.
- **To revert:** Remove the `calls` field from all entries in skills-registry.json. In doctor SKILL.md: remove the "For each skill with `calls:`..." paragraph from Section 4. Revert doctor version to 2.9.0.

#### OPT-132: Agent Temperature & Model Hints
- **Modified:** `.claude/agents/code-reviewer.md` (added `model: inherit`, `temperature: 0.1`)
- **Modified:** `.claude/agents/spec-reviewer.md` (added `temperature: 0.1`)
- **Modified:** `.claude/agents/security-analyst.md` (added `model: inherit`, `temperature: 0.1`)
- **Modified:** `.claude/agents/architecture-reviewer.md` (added `model: inherit`, `temperature: 0.1`)
- **Modified:** `.claude/agents/performance-engineer.md` (added `model: inherit`, `temperature: 0.2`)
- **Modified:** `.claude/agents/codebase-explorer.md` (added `temperature: 0.3`)
- **What:** All 6 native agents now include explicit `temperature` hints in their YAML frontmatter. Conservative agents (code-reviewer, spec-reviewer, security-analyst, architecture-reviewer) use temperature 0.1 for deterministic analysis. Performance-engineer uses 0.2. Codebase-explorer uses 0.3 for flexible search strategies.
- **Why:** Analysis agents benefit from low temperature (deterministic, conservative findings), while exploration agents can use slightly higher temperature for creative search strategies. The `model: inherit` field future-proofs for per-agent model selection.
- **To test:** Read each agent file and verify the temperature and model fields are present in the frontmatter. Temperature values should match: code-reviewer=0.1, security-analyst=0.1, architecture-reviewer=0.1, spec-reviewer=0.1, performance-engineer=0.2, codebase-explorer=0.3.
- **To revert:** Remove the `model:` and `temperature:` lines from each agent file. For spec-reviewer and codebase-explorer (which already had `model: haiku`), only remove the `temperature:` line.

## [3.4.0] - 2026-02-23

### Pre-Implementation Quality Gates (OPT-119, OPT-120)

#### OPT-119: Confidence-Gated Implementation Start
- **New:** `.claude/prompts/confidence-gate.md` (micro-component for pre-implementation confidence assessment)
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added Phase 2.5 between context transition and execution, added `confidence-gate` to micro-components frontmatter, version bumped to 3.1.0)
- **What:** A new Phase 2.5 in story-cycle scores confidence across 5 dimensions (ambiguity, architecture, patterns, test strategy, dependencies) before any implementation code is written. Score ≥85 proceeds, 70-84 flags gaps for clarification, <70 returns to Phase 1 for more research.
- **Why:** The framework verified extensively after implementation (Phase 3.5 self-review, Phase 4.5 completion verification) but had no structured gate asking "Am I confident enough to start?" A wrong-direction implementation caught in Phase 3.5 wastes the entire Phase 3 execution budget.
- **To test:** Run `/story-cycle` on a story. After plan approval and context transition, verify the confidence gate runs and produces a scored assessment before Phase 3 execution begins. Test with an ambiguous story — verify it flags low-scoring dimensions.
- **To revert:** Delete `.claude/prompts/confidence-gate.md`. Remove the "Phase 2.5: Confidence Gate" section from story-cycle SKILL.md. Remove `phase-2.5: [confidence-gate]` from frontmatter micro-components. Remove `→ Phase 2.5: Confidence Gate` line from the process flow. Revert story-cycle version to 3.0.0.

#### OPT-120: Four-Question Completion Evidence Protocol
- **Modified:** `.claude/rules/verification.md` (added "Completion Evidence Protocol" section with 4 mandatory questions and red flags checklist)
- **What:** Before reporting any task as complete, the agent must explicitly answer 4 questions: (1) Are tests passing? (paste output), (2) Are all AC met? (list each with PASS/FAIL), (3) Any unverified assumptions? (list with evidence), (4) Concrete evidence for every claim? (cite outputs/locations). Includes 5 red flag patterns for self-checking.
- **Why:** Existing verification rules used prohibitive language ("NEVER claim...") but the agent could still feel compliant while being vague. A structured checklist forces explicit answers, making it harder to skip verification steps.
- **To test:** Complete a story and verify the completion report addresses all 4 questions with concrete evidence. Check that the red flags are self-checked.
- **To revert:** Remove the "Completion Evidence Protocol" section (from `## Completion Evidence Protocol` through the red flags list) from `.claude/rules/verification.md`.

### Error Learning & Prevention (OPT-121)

#### OPT-121: Cross-Session Error Learning Pattern
- **New:** `.claude/prompts/record-failure.md` (micro-component for recording failure patterns)
- **New:** `docs/context/error-patterns.md` (persistent cross-session error knowledge base)
- **Modified:** `.claude/prompts/context-prime.md` (added `error-patterns.md` to context file loading list)
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added error learning paragraph to Phase 3.5, added `record-failure` to micro-components frontmatter)
- **Modified:** `.claude/skills/debug-session/SKILL.md` (added Phase 4.5 Error Learning section, added `record-failure` to micro-components frontmatter, version bumped to 2.8.0)
- **What:** A reflexion mechanism that records implementation failures, root causes, and prevention strategies in `docs/context/error-patterns.md`. Invoked when self-review catches wrong approaches (story-cycle Phase 3.5) or when debug-session identifies misdiagnosed root causes (new Phase 4.5). The context-prime component loads error-patterns.md during session start so future sessions can check for known pitfalls.
- **Why:** The framework had failure state persistence (tracking where interruption happened) but not failure knowledge persistence (what went wrong and how to prevent it). Sessions could repeat the same architectural mistakes because lessons were lost.
- **To test:** During `/story-cycle`, deliberately make an approach that gets caught in self-review. Verify an entry is appended to `docs/context/error-patterns.md`. Start a new session with `/continue` — verify error-patterns.md is loaded by context-prime. During `/debug-session`, verify Phase 4.5 appears after root cause identification.
- **To revert:** Delete `.claude/prompts/record-failure.md` and `docs/context/error-patterns.md`. Remove `error-patterns.md` line from `.claude/prompts/context-prime.md`. Remove the "Error learning" paragraph from story-cycle Phase 3.5. Remove `phase-3.5: [record-failure]` from story-cycle frontmatter. Remove Phase 4.5 from debug-session SKILL.md. Remove `phase-4: [record-failure]` from debug-session frontmatter. Revert debug-session version to 2.7.0.

### Parallelization Patterns (OPT-122)

#### OPT-122: Formalized Wave Execution Pattern
- **New:** `.claude/prompts/wave-execution.md` (micro-component for Wave → Checkpoint → Wave parallel execution)
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added `wave-execution` to phase-1 micro-components frontmatter)
- **What:** A standardized parallel execution pattern: Wave 1 (independent reads in parallel) → Checkpoint (sequential analysis of combined results) → Wave 2 (independent actions in parallel). Includes anti-patterns and a decision table for when to apply. Referenced by story-cycle Phase 1 for parallel file discovery and codebase research.
- **Why:** The framework used parallelism in specific places (quality gates, parallel streams, explore subagent) but each skill implemented its own version. A standardized pattern makes it easier to add parallelism to new skills and ensures consistent checkpoint behavior.
- **To test:** Run `/story-cycle` on a multi-module story. Verify Phase 1b-1c file discovery and research uses wave-style parallel reads when touching multiple independent areas.
- **To revert:** Delete `.claude/prompts/wave-execution.md`. Remove `wave-execution` from the phase-1 micro-components list in story-cycle frontmatter.

### Tool Integration Strategy (OPT-123)

#### OPT-123: MCP Server Integration Guide
- **New:** `docs/reference/MCP_INTEGRATION.md` (MCP server selection guide with categories, decision tree, and integration patterns)
- **New:** `.claude/prompts/select-tool.md` (prompt snippet for MCP vs built-in tool selection)
- **Modified:** `.claude/skills/bootstrap/SKILL.md` (added step A4.5 for MCP server detection)
- **Modified:** `CLAUDE.md` (added MCP_INTEGRATION.md to Important Files)
- **What:** A reference document documenting 5 MCP server categories (documentation, memory, search, browser automation, code intelligence) with integration points for each framework skill. Includes a decision tree for server selection and graceful degradation guidance. Bootstrap now optionally detects installed MCP servers. A select-tool prompt snippet guides MCP vs built-in tool choices.
- **Why:** Skills were tool-agnostic with no guidance on leveraging MCP servers. Users with servers installed got no framework-level optimization. The guide enables conditional enhancement while maintaining full functionality without MCP.
- **To test:** Read `docs/reference/MCP_INTEGRATION.md` and verify the server categories and decision tree are clear. Run `/bootstrap` on a project — verify step A4.5 appears (and is skipped gracefully if no MCP servers detected). Check CLAUDE.md for the new Important Files entry.
- **To revert:** Delete `docs/reference/MCP_INTEGRATION.md` and `.claude/prompts/select-tool.md`. Remove step A4.5 from bootstrap SKILL.md. Remove the MCP_INTEGRATION.md line from CLAUDE.md Important Files.

### Agent Specialization (OPT-124)

#### OPT-124: Domain-Specific Subagent Personas
- **New:** `.claude/prompts/agents/security-analyst.md` (attacker-mindset security analysis persona)
- **New:** `.claude/prompts/agents/performance-engineer.md` (systems profiling performance analysis persona)
- **New:** `.claude/prompts/agents/architecture-reviewer.md` (boundary-enforcement architecture review persona)
- **What:** Three domain-specific agent personas that carry specialized knowledge, behavioral frameworks, analysis patterns, key questions, and red flags. Each follows a structured template: Mindset, Focus Areas, Key Questions, Red Flags, Analysis Framework, Output Format.
- **Why:** Existing subagent templates (code-reviewer, spec-reviewer) defined what to review but not how to think about it. A security review benefits from an attacker mindset; a performance review benefits from a systems profiling perspective. Domain personas prime the agent with relevant mental models.
- **To test:** During `/security-audit`, verify the security-analyst persona is available for dispatch. Check that each persona file contains: Mindset, Focus Areas (ranked), Key Questions (5-7), Red Flags, Analysis Framework, and Output Format sections.
- **To revert:** Delete `.claude/prompts/agents/security-analyst.md`, `.claude/prompts/agents/performance-engineer.md`, and `.claude/prompts/agents/architecture-reviewer.md`.

## [3.3.0] - 2026-02-23

### Context Intelligence (OPT-109, OPT-110)

#### OPT-109: Intent-Aware Context Priming
- **Modified:** `.claude/prompts/context-prime.md` (added intent classification table and dynamic loading order)
- **What:** The context-prime micro-component now classifies the current task's intent (security, UI, data/API, refactoring, new feature) and reorders context file loading based on relevance. A security task loads system-patterns first; a UI task loads product-context first.
- **Why:** Previously, context files loaded in a fixed priority order regardless of task type. The most relevant context could be loaded last — or dropped if budget was tight.
- **To test:** Run `/continue` on a security-related task. Verify system-patterns and tech-context load before product-context. Compare with a UI task — product-context should load first.
- **To revert:** Replace the contents of `.claude/prompts/context-prime.md` with the original fixed-order loading (Priority 1: project-overview + tech-context, Priority 2: system-patterns + project-structure, Priority 3: product-context).

#### OPT-110: Intent-Based Rule Activation
- **Modified:** `.claude/rules/security.md` (expanded path scope to include API, routes, middleware, controllers, handlers, DB, models, schema, upload, session, cookie, CORS patterns)
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added intent-based security activation note to Phase 1d)
- **What:** Security rules now activate for a much wider range of security-sensitive file paths (API endpoints, route handlers, middleware, database operations, models, file uploads, sessions, cookies, CORS config). Additionally, story-cycle Phase 1d can flag `Security scope: story-wide` when a story's intent involves user input, APIs, or data handling — activating security review for ALL files in the story.
- **Why:** Previously, security rules only triggered for files matching auth/credential/token patterns. Code handling user input in API routes, database queries with user data, or file upload handlers received no automatic security review.
- **To test:** Edit a file in an `api/` or `routes/` directory. Verify security rules activate. In story-cycle, start a story touching user input — verify security scope is noted as story-wide.
- **To revert:** Restore original `paths:` in security.md (remove lines for api, routes, middleware, controllers, handlers, db, database, models, schema, upload, session, cookie, cors). Remove the "Intent-based security activation" paragraph from story-cycle Phase 1d.

### Failure Resilience (OPT-111, OPT-112)

#### OPT-111: Structured Failure State Persistence
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added "Failure State Persistence" section before Phase 3, version bumped to 3.0.0)
- **Modified:** `.claude/skills/debug-session/SKILL.md` (added "Failure State Persistence" section before Phase 1)
- **Modified:** `.claude/skills/continue/SKILL.md` (added Step 0.5 "Check for Failure State" before session handoff reading, renumbered existing 0.5 to 0.6, version bumped to 2.6.0)
- **What:** When story-cycle or debug-session is running, a structured failure state file (`docs/sessions/.failure-state.md`) is maintained at each phase transition. It records: current skill, phase, sub-step, files modified, test status, last action, and recovery hint. If a session ends unexpectedly, `/continue` detects and prominently displays this file as highest-priority context, enabling precise resumption.
- **Why:** Previously, if a session ended mid-skill, `/continue` relied on handoff files (written manually at session end) or git state inference. An interrupted session lost structured context about what phase was active, what had been completed, and how to resume.
- **To test:** Start `/story-cycle`, let it reach Phase 3, then end the session without `/handoff`. Start new session, run `/continue`. Verify it detects `.failure-state.md` and shows the interrupted session prominently. After successful story completion, verify `.failure-state.md` is deleted.
- **To revert:** Remove the "Failure State Persistence" section from story-cycle/SKILL.md and debug-session/SKILL.md. Remove Step 0.5 from continue/SKILL.md and renumber 0.6 back to 0.5. Revert continue version to 2.5.0 and story-cycle to 2.9.0.

#### OPT-112: Cross-Skill Error Awareness
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added cross-skill status updates to Phase 4)
- **Modified:** `.claude/skills/sprint-end/SKILL.md` (added story completion status check to Step 1, version bumped to 2.9.0)
- **What:** story-cycle now writes structured completion status to `docs/progress.md` at each phase gate (e.g., "Phase 3 — implementation complete, self-review pending"). sprint-end reads this status before quality gates and adjusts expectations — if the last story was only partially completed, sprint-end runs the missing steps rather than flagging them as new issues.
- **Why:** Previously, sprint-end had no structured way to know if the last story was 80% or 100% complete. It would run quality gates, find issues from incomplete work, and couldn't distinguish "known incomplete" from "new problems."
- **To test:** Start a story-cycle, complete Phase 3 but stop before Phase 4. Check progress.md for phase status. Run sprint-end and verify it reads the incomplete status and accounts for it.
- **To revert:** Remove the "Cross-skill status" paragraph from story-cycle Phase 4. Remove the "Check story completion status" paragraph from sprint-end Step 1. Revert sprint-end version to 2.8.0.

### Observability & Metrics (OPT-113, OPT-114, OPT-115)

#### OPT-113: Skill-Level Execution Metrics
- **New:** `scripts/pm/metrics.sh` (executable query script for skill execution metrics)
- **Modified:** `.claude/hooks/activity-logger.sh` (updated comment to document skill event support)
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added skill lifecycle event emission at start and completion)
- **Modified:** `.claude/skills/retrospective/SKILL.md` (added "Skill Execution Metrics" section that runs metrics.sh)
- **What:** A metrics query script (`scripts/pm/metrics.sh`) that parses the activity log for skill-level events (start, phase, end with outcome). Core skills (story-cycle) emit structured lifecycle events to the activity log. The retrospective skill now runs this script for quantitative analysis: skill success/failure rates, per-skill breakdown, tool usage distribution, and rule trigger counts.
- **Why:** The activity logger captured tool-level events (Edit, Write, Bash) but had no visibility into skill-level outcomes. `/retrospective` lacked quantitative data about which skills succeed, which fail, and where bottlenecks exist.
- **To test:** Run `bash scripts/pm/metrics.sh --help` to verify the script works. Run `/story-cycle` on a story — verify skill start/end events appear in `.activity-log.jsonl`. Run `/retrospective` and verify the "Skill Execution Metrics" section appears.
- **To revert:** Delete `scripts/pm/metrics.sh`. Remove the skill event emission blocks from story-cycle (the two `echo "{\"type\":\"skill\"..."` code blocks). Remove the "Skill Execution Metrics" section from retrospective/SKILL.md. Revert the comment change in activity-logger.sh.

#### OPT-114: Ground Rule Compliance Ledger
- **Modified:** `.claude/skills/sprint-end/SKILL.md` (added compliance ledger recording after ground rules check)
- **Modified:** `docs/progress.md` (added "Ground Rule Compliance" table section)
- **What:** After sprint-end checks ground rules compliance, results are recorded in a persistent table in `progress.md`. Tracks: sprint number, rules checked, violations count, and details. Builds a longitudinal compliance profile across sprints.
- **Why:** Ground rule checks happened but results evaporated after each session. Over months, no visibility into which rules are upheld, which are violated frequently (need reinforcement), or which are never tested (dead rules).
- **To test:** Run `/sprint-end` on a project with GROUND_RULES.md. Verify a new row is added to the "Ground Rule Compliance" table in progress.md.
- **To revert:** Remove the "Compliance ledger" paragraph (including the markdown table format) from sprint-end Step 2. Remove the "Ground Rule Compliance" section from progress.md.

#### OPT-115: Rule Effectiveness Tracking
- **Modified:** `.claude/rules/verification.md` (added "Rule Effectiveness Tracking" section with event emission protocol)
- **Modified:** `.claude/skills/weekly-maintenance/SKILL.md` (added Step 5 "Rule Health Review" with metrics.sh integration, renumbered subsequent steps, version bumped to 2.5.0)
- **New:** Rule trigger events in activity log format: `{"type":"rule","rule":"<name>","action":"<what>"}`
- **What:** When a rule influences behavior, a tracking event is emitted to the activity log. The metrics.sh script reports rule trigger counts. Weekly-maintenance now includes a "Rule Health Review" step that flags over-active rules (>20/week), silent rules (0 triggers in 30+ days), and high-failure skills.
- **Why:** Rules are enforced automatically but their effectiveness is invisible. Some rules may trigger constantly (too broad or persistent issue), others never trigger (too narrow or solved problem). Data-driven rule evolution requires measurement.
- **To test:** Edit a file that triggers a rule (e.g., a test file). Check if a rule event appears in `.activity-log.jsonl`. Run `bash scripts/pm/metrics.sh` and check the "Rule Triggers" section. Run `/weekly-maintenance` and verify Step 5 appears.
- **To revert:** Remove the "Rule Effectiveness Tracking" section from verification.md. Remove Step 5 from weekly-maintenance, renumber Step 6→5 and Step 7→6, revert version to 2.4.0.

### Prompt Engineering (OPT-116, OPT-117)

#### OPT-116: Adaptive Depth Calibration
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added adaptive calibration paragraph after size classification table)
- **What:** After the size classification table, story-cycle now checks historical execution data (if 10+ records exist in the activity log) to adjust depth classification. Stories of a type that consistently required full workflow despite SMALL classification get escalated; STANDARD stories that consistently completed without issues are noted as candidates for lightweight treatment.
- **Why:** The size×risk depth matrix is static. In practice, some story types consistently need more depth than their classification suggests. Historical data enables the matrix to adapt to the actual project's characteristics.
- **To test:** After accumulating 10+ story-cycle executions in the activity log, start a new story-cycle. Verify the adaptive calibration check runs and notes any adjustments.
- **To revert:** Remove the "Adaptive calibration" paragraph (from "**Adaptive calibration:**" to the end of the `Depth calibration:` log line) from story-cycle SKILL.md.

#### OPT-117: Dynamic Micro-Component Composition
- **Modified:** `.claude/skills/SKILL_TEMPLATE.md` (added `micro-components` field documentation and usage instructions)
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added `micro-components:` to YAML frontmatter)
- **Modified:** `.claude/skills/sprint-end/SKILL.md` (added `micro-components:` to YAML frontmatter)
- **Modified:** `.claude/skills/continue/SKILL.md` (added `micro-components:` to YAML frontmatter)
- **What:** Skills can now declare which micro-components (from `.claude/prompts/`) they need and at which phase, via a `micro-components:` field in YAML frontmatter. This replaces inline references to micro-components in skill bodies. When a micro-component is updated, all skills that declare it automatically get the update.
- **Why:** Currently, skills reference micro-components inline. When a micro-component changes, every skill referencing it needs manual updating. Declarative composition is DRYer and more maintainable.
- **To test:** Check story-cycle, sprint-end, and continue frontmatter for `micro-components:` entries. Verify the SKILL_TEMPLATE.md documents the new field.
- **To revert:** Remove `micro-components:` blocks from story-cycle, sprint-end, and continue SKILL.md frontmatter. Remove the "Micro-Components in Frontmatter" subsection from SKILL_TEMPLATE.md. Remove `micro-components` row from the frontmatter field table.

### Framework Evolution (OPT-118)

#### OPT-118: Skill Version Regression Detection
- **New:** `.claude/skills/skill-eval/baselines/` (directory for baseline captures)
- **Modified:** `.claude/skills/skill-eval/SKILL.md` (added `baseline` and `regression` modes, updated mode table, version bumped to 2.5.0)
- **What:** Two new modes for skill-eval: `baseline` captures a graded eval output as a reference point for a skill version; `regression` compares the current skill version against the saved baseline and flags any criteria that changed from PASS to FAIL.
- **Why:** `/skill-eval` could test and compare skills, but had no way to detect regressions when skills are updated. Baseline capture + regression comparison closes this gap.
- **To test:** Run `/skill-eval baseline story-cycle --scenario "add user login"`. Verify a baseline file is created in `baselines/`. Modify story-cycle slightly. Run `/skill-eval regression story-cycle`. Verify it compares against the baseline and reports any differences.
- **To revert:** Delete `.claude/skills/skill-eval/baselines/` directory. Remove the "Mode: baseline" and "Mode: regression" sections from skill-eval/SKILL.md. Remove the two new rows from the mode table. Revert version to 2.4.0 and description to original.

## [3.2.0] - 2026-02-23

### Parallel Development Infrastructure (OPT-103, OPT-104)

#### OPT-103: Worktree-Aware Bash Hook
- **New:** `.claude/hooks/worktree-bash-fix.sh`
- **Modified:** `.claude/settings.json` (added PreToolUse hook for Bash with `apply_to_subagents: true`)
- **What:** A POSIX-compliant pre-tool-use hook that detects when Claude Code is running inside a git worktree and transparently injects `cd '/path/to/worktree' &&` before every Bash command. Handles edge cases: commands that already contain `cd`, shell builtins that don't need directory context, background processes, variable assignments.
- **Why:** Claude Code resets the working directory between Bash tool invocations. When `/parallel-work` creates worktrees and agents are spawned to work in them, every Bash command silently executes in the wrong directory. This hook makes the entire parallel worktree system actually functional for multi-agent execution.
- **To test:** Create a worktree with `/parallel-work create`. Open a Claude Code instance in the worktree. Run any Bash command (e.g., `git status`, `ls`). Verify the output reflects the worktree's directory, not the main repo. Verify the hook is transparent (no visible cd injection in output).
- **To revert:** Delete `.claude/hooks/worktree-bash-fix.sh`. Remove the second PreToolUse entry (the one with `apply_to_subagents: true` and `worktree-bash-fix.sh`) from `.claude/settings.json`.

#### OPT-104: Sub-Story Parallel Stream Decomposition
- **New:** `.claude/skills/story-cycle/references/parallel-streams.md`
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added Phase 3a between Phase 2 and Phase 3, updated process flowchart, updated version to 2.9.0, added `references/parallel-streams.md` to frontmatter references)
- **What:** An optional Phase 3a in story-cycle that decomposes STANDARD-size, low/medium-risk stories into independent parallel work streams with non-overlapping file scopes. Each stream is executed in its own worktree by a separate agent. Dependencies between streams are respected (e.g., tests wait for service layer). Falls back to serial execution if file scopes overlap or user declines.
- **Why:** Large stories often contain naturally independent work units (database layer, API layer, UI layer, tests) that can be developed simultaneously. This multiplies throughput while keeping merge conflicts impossible (non-overlapping file scopes).
- **To test:** Run `/story-cycle` on a STANDARD-size Feature story that touches multiple modules. Verify Phase 3a is offered after Phase 2. Verify stream analysis shows file scopes. Accept parallel execution and verify agents are spawned in separate worktrees. Verify serial fallback works when declining.
- **To revert:** Delete `.claude/skills/story-cycle/references/parallel-streams.md`. Remove the `## Phase 3a` section from story-cycle SKILL.md. Remove `→ Phase 3a:` line from the process flowchart. Remove `references/parallel-streams.md` from the frontmatter references array. Revert version to 2.8.0.

### Context Efficiency (OPT-105, OPT-106)

#### OPT-105: Persistent Project Context Knowledge Base
- **New:** `docs/context/project-overview.md`, `docs/context/tech-context.md`, `docs/context/system-patterns.md`, `docs/context/project-structure.md`, `docs/context/product-context.md`
- **New:** `.claude/prompts/context-prime.md` (micro-component for priority-ordered context loading)
- **Modified:** `.claude/skills/continue/SKILL.md` (added Step 1.5 "Load Project Context" before working context reload, version bumped to 2.5.0)
- **Modified:** `.claude/skills/bootstrap/SKILL.md` (added Step A3.55 "Generate Project Context Knowledge Base")
- **Modified:** `.claude/skills/sprint-end/SKILL.md` (added incremental context update to Step 3 documentation updates)
- **What:** A 5-file project context knowledge base at `docs/context/` with a create/prime/update lifecycle. Files capture deep project knowledge (overview, tech stack, design patterns, structure, product domain) that persists across sessions. `/bootstrap` generates initial versions, `/sprint-end` incrementally updates changed files, `/continue` loads them in priority order (essential first, deep context last). A new `context-prime` micro-component handles priority-ordered loading.
- **Why:** Cross-session project knowledge currently lives in CLAUDE.md (intentionally minimal) and session handoff files (capture what happened, not deep knowledge). Each new session requires re-discovering project patterns by reading code. The context knowledge base compounds over a project's lifetime — every session starts smarter than the last.
- **To test:** Run `/bootstrap` on an existing project. Verify 5 context files are generated in `docs/context/` with evidence-based content. Run `/continue` and verify context files are loaded in priority order. Run `/sprint-end` after making changes and verify relevant context files are updated.
- **To revert:** Delete the `docs/context/` directory and its 5 files. Delete `.claude/prompts/context-prime.md`. Remove Step 1.5 from continue/SKILL.md and revert version to 2.4.0. Remove Step A3.55 from bootstrap/SKILL.md. Remove the "Project context" bullet from sprint-end/SKILL.md Step 3.

#### OPT-106: Script Delegation for Simple Queries
- **New:** `scripts/pm/status.sh`, `scripts/pm/next-story.sh`, `scripts/pm/standup.sh`
- **What:** Three bash scripts for common read-only operations: sprint status overview (git state + progress.md + backlog counts + open PRs), next available TODO story from backlog, and daily standup summary (yesterday's commits + today's focus + blockers). Execute as black boxes with zero context token cost.
- **Why:** Simple read-only queries currently require loading full skill prompts (300-800 tokens each). Bash scripts execute as black boxes and return only their output — zero tokens consumed in context. The 80% case for status queries can be answered faster and cheaper.
- **To test:** Run `bash scripts/pm/status.sh` in a project. Verify it shows git state, progress metrics, backlog counts, and open PRs. Run `bash scripts/pm/next-story.sh` and verify it finds TODO stories from backlog. Run `bash scripts/pm/standup.sh` and verify it shows yesterday's work, today's focus, and blockers.
- **To revert:** Delete the three scripts from `scripts/pm/`.

### Quality & Safety (OPT-107, OPT-108)

#### OPT-107: Documentation Accuracy Safeguards
- **New:** `.claude/skills/bootstrap/references/accuracy-safeguards.md`
- **Modified:** `.claude/rules/documentation.md` (added "Documentation Accuracy" section)
- **Modified:** `.claude/skills/bootstrap/SKILL.md` (added accuracy-safeguards.md to references, added accuracy safeguard callout in Step A3.5)
- **What:** Structured anti-hallucination protocol for documentation creation. Includes: self-verification questions before writing technical claims, three evidence levels (Confirmed/Inferred/Assumed), qualifying language rules, post-creation validation checklist, and common hallucination pattern table. Integrated into both the documentation rule (applies to all doc edits) and bootstrap (applies during initial project analysis).
- **Why:** When Claude generates project documentation, it can hallucinate technical details — claiming patterns exist that don't, describing architecture that's imagined, or listing technologies not actually used. These inaccuracies compound: if system-patterns.md incorrectly says "uses repository pattern," future sessions follow that pattern even when the codebase uses something else.
- **To test:** Run `/bootstrap` on an existing project. Verify generated ARCHITECTURE.md and context files reference actual files (not inferred patterns). Check for `[Inferred]` or `[Assumed]` markers on uncertain claims. Read the `documentation.md` rule and verify the "Documentation Accuracy" section exists.
- **To revert:** Delete `.claude/skills/bootstrap/references/accuracy-safeguards.md`. Remove the "## Documentation Accuracy" section (including all bullets and the "See" reference) from `.claude/rules/documentation.md`. Remove `references/accuracy-safeguards.md` from bootstrap SKILL.md frontmatter. Remove the "Apply accuracy safeguards" sentence from Step A3.5.

#### OPT-108: Template Repository Safety Check
- **Modified:** `.claude/hooks/pre-tool-safety.sh` (added framework repository remote URL check before `gh pr create`, `gh issue create`, and `git push`)
- **What:** Before any GitHub write operation (PR creation, issue creation, push), the safety hook checks if the git remote points to the framework template repository. If matched, blocks the operation with a clear message suggesting `git remote set-url origin`. The blocked repo identifier is configurable via `JD_FRAMEWORK_REPO` environment variable (defaults to `joris887/JD-LLM-Development_framework`).
- **Why:** When users install the framework via `install.sh` or manual copy, they may forget to update their git remote. Operations like `/sprint-end` (creates PRs) or `/fix-issue` (creates branches and PRs) could accidentally affect the framework repo instead of the user's project. Low probability but catastrophic when it happens.
- **To test:** In a repo with remote pointing to `joris887/JD-LLM-Development_framework`, run `gh pr create --title "test"`. Verify it's blocked with a message about updating the remote. Verify the block doesn't trigger in repos with different remotes.
- **To revert:** Remove the "Block operations against the framework template repository" section (the comment block and the `if` block checking `FRAMEWORK_REPO`) from `.claude/hooks/pre-tool-safety.sh`.

## [3.1.0] - 2026-02-23

### Quality & Validation (OPT-93, OPT-94)

#### OPT-93: Adversarial Disaster Prevention in Self-Review
- **New:** `.claude/skills/story-cycle/references/disaster-prevention.md`
- **Modified:** `.claude/skills/story-cycle/references/self-review.md` (new "Disaster Prevention" reference at end), `.claude/skills/story-cycle/SKILL.md` (added `disaster-prevention.md` to frontmatter references)
- **What:** Added a structured adversarial checklist targeting specific LLM-typical implementation failures: wheel reinvention (duplicating existing utilities), specification drift (implementation diverging from AC), integration wiring gaps (routes/exports not registered), file structure violations, and regression surface analysis. Loaded during Phase 3.5 after the standard self-review.
- **Why:** The general self-review checklist catches broad issues but doesn't target known LLM failure modes. These specific patterns (reinventing utilities, missing integration wiring, specification drift) are predictable and detectable with active searching rather than passive checking.
- **To test:** Run `/story-cycle` on a feature story. During Phase 3.5, verify that the disaster prevention checklist is loaded and executed after the standard self-review. Verify each category involves an active search (grep, file listing) rather than just a checkbox.
- **To revert:** Delete `.claude/skills/story-cycle/references/disaster-prevention.md`. Remove the "Disaster Prevention" paragraph from the end of `self-review.md`. Remove `references/disaster-prevention.md` from story-cycle SKILL.md frontmatter references.

#### OPT-94: Token-Efficiency Guidelines for Cross-Skill Output
- **Modified:** `.claude/rules/documentation.md` (new "Cross-Skill Output Optimization" section)
- **What:** Added guidelines for structuring skill outputs that will be consumed by downstream skills or future sessions: bullet points over prose, file:line references, imperative instructions, front-loaded critical information, YAML frontmatter for metadata, section budgets, and output template usage.
- **Why:** When skill output is consumed by another skill (plans by Phase 3, session files by `/continue`), format directly impacts context efficiency. Prose-heavy outputs waste tokens; structured outputs maximize value per token.
- **To test:** Read `documentation.md` and verify the "Cross-Skill Output Optimization" section exists with 7 guideline bullets.
- **To revert:** Remove the "## Cross-Skill Output Optimization" section (including all bullets) from `.claude/rules/documentation.md`.

### Workflow Architecture (OPT-95, OPT-96, OPT-97)

#### OPT-95: Per-Workflow State Persistence in Output Artifacts
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 1g context preservation — added `stepsCompleted` field and state update instruction; Phase 3 — added state update instruction), `.claude/skills/story-cycle/references/plan-template.md` (new "Workflow State Frontmatter" section)
- **What:** Added YAML frontmatter-based state tracking to plan files. The Story-Cycle Context header now includes `stepsCompleted` and `phase` fields that are updated at each phase transition. Plan template documents the state schema. When story-cycle is re-invoked, it can detect an existing plan with state frontmatter and offer to resume from the last completed step.
- **Why:** Currently, workflow recovery depends on session handoff files. If those are stale or missing, there's no artifact-level record of which phase completed. Embedding state in the plan file itself makes workflows self-resumable.
- **To test:** Run `/story-cycle` through Phase 1. Save the plan to `docs/plans/`. Verify the Story-Cycle Context includes `stepsCompleted` and `phase` fields. Simulate an interruption and re-invoke — verify the plan's state is detectable.
- **To revert:** Remove the `stepsCompleted` line and the "Update the `phase` and `stepsCompleted` fields at each phase transition" instruction from story-cycle SKILL.md Phase 1g. Remove the "State update:" line from Phase 3. Remove the "## Workflow State Frontmatter" section from `plan-template.md`.

#### OPT-96: Integrated Depth Exploration at Decision Points
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (new Phase 1h "Depth Check" after 1g), `.claude/skills/story-cycle/references/reasoning-tools.md` (new `depth_exploration` reasoning tool)
- **What:** Added an optional [D]/[C] menu after Phase 1g for stories with complexity ≥4 or unresolved uncertainties. If [D] is selected, the `depth_exploration` reasoning tool applies the most relevant elicitation technique from `references/elicitation-techniques.md`, integrates findings, then presents for approval. If [C], proceeds directly to approval.
- **Why:** Going deeper on requirements currently requires leaving the workflow (invoking `/brainstorm` separately). Inline depth options keep the user in flow while enabling richer exploration when the problem warrants it.
- **To test:** Run `/story-cycle` with a complex story (complexity ≥4). Verify the [D]/[C] menu appears after Phase 1g. Select [D] and verify an elicitation technique is applied. Select [C] and verify it proceeds to approval.
- **To revert:** Remove the "### 1h. Depth Check" section from story-cycle SKILL.md. Remove the `## Tool: depth_exploration` section from reasoning-tools.md.

#### OPT-97: Complexity-Calibrated Workflow Depth
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (expanded "Size Classification" to "Size & Risk Classification" with risk matrix), `.claude/skills/story-cycle/references/reasoning-tools.md` (new `risk_classification` reasoning tool)
- **What:** Extended the fast-track classification with a risk dimension. After size classification (trivial/small/standard), the `risk_classification` tool scores domain risk, integration surface, and reversibility (1-3 each). The size × risk matrix adjusts workflow depth: high-risk trivial changes get reclassified as SMALL, high-risk standard changes get all quality agents + architecture-check.
- **Why:** Size alone doesn't capture risk. A 30-line auth change is higher risk than a 200-line documentation page. Risk calibration automatically adjusts planning depth and quality gate intensity.
- **To test:** Run `/story-cycle` for a change to auth code. Verify `risk_classification` is applied and adjusts the workflow depth upward. Run for a documentation change and verify it stays at the size-based default.
- **To revert:** Restore the "## Size Classification" heading (remove "& Risk"). Remove the risk classification table and text from story-cycle SKILL.md. Remove the `## Tool: risk_classification` section from reasoning-tools.md.

### Developer Experience (OPT-98, OPT-99)

#### OPT-98: Artifact-Aware Project Navigator in /continue
- **Modified:** `.claude/skills/continue/SKILL.md` (new Step 0 "Project Health Scan" before session recovery)
- **What:** Added a project health scan step that checks for key artifacts (ARCHITECTURE.md, GROUND_RULES.md, CODING_STANDARDS.md, backlog stories, feature branches, test command) and presents a health dashboard with actionable recommendations for missing or incomplete items.
- **Why:** `/continue` reads session handoff files and git state, but when session files are stale or missing (new session after days away, first-time contributor), it can't assess overall project maturity. The health scan provides project-level context alongside session-level state.
- **To test:** Run `/continue` in a project missing GROUND_RULES.md. Verify the health dashboard shows ❌ for ground rules and suggests `/bootstrap`. Run in a fully configured project and verify the dashboard shows mostly ✅.
- **To revert:** Remove the "## 0. Project Health Scan" section from continue/SKILL.md. Rename "## 0.5. Read Latest Session Handoff" back to "## 0. Read Latest Session Handoff".

#### OPT-99: Output Templates for Document-Producing Skills
- **New:** `.claude/skills/debug-session/assets/debug-report.md`, `.claude/skills/brainstorm/assets/brainstorm-output.md`, `.claude/skills/manual-test/assets/test-plan.md`, `.claude/skills/ideate/assets/story-template.md`
- **What:** Added structured output templates for four document-producing skills. Each template includes YAML frontmatter (skill, date, status) and standardized section headers matching the skill's output structure. Skills copy the template to the output location and fill sections, rather than generating format from scratch.
- **Why:** Skills produce output documents with varying format between invocations. Templates ensure consistency, reduce per-invocation token cost (copy structure vs. generate it), and enable downstream skills to parse outputs reliably.
- **To test:** Run `/debug-session`. Verify output structure matches the `debug-report.md` template sections. Run `/brainstorm` and verify output matches `brainstorm-output.md`.
- **To revert:** Delete the four template files from their respective `assets/` directories.

### Prompt Engineering (OPT-100, OPT-101)

#### OPT-100: Elicitation Techniques Library
- **New:** `.claude/skills/story-cycle/references/elicitation-techniques.md`
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (added `references/elicitation-techniques.md` to frontmatter references)
- **What:** Created a shared reference file with 5 named elicitation techniques: Assumption Surfacing, Constraint Mapping, Failure Mode Exploration, Stakeholder Perspective Shift, and Boundary Probing. Each has a when/method/output structure. Referenced by the `depth_exploration` reasoning tool and available to brainstorm, ideate, and bootstrap.
- **Why:** Multiple skills involve requirements discovery (brainstorm, ideate, story-cycle Phase 1f, bootstrap A3.6). Each uses ad-hoc questioning. A shared library of structured techniques improves quality and consistency, similar to how `reasoning-tools.md` provides named thinking scaffolds.
- **To test:** Read `elicitation-techniques.md` and verify it contains 5 named techniques with structured when/method/output. During a `/story-cycle` depth check, verify a relevant technique is applied.
- **To revert:** Delete `.claude/skills/story-cycle/references/elicitation-techniques.md`. Remove `references/elicitation-techniques.md` from story-cycle SKILL.md frontmatter references.

#### OPT-101: Facilitator Reinforcement in Discovery Phases
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (new Phase 1d.5 "Discovery Gate" between 1d and 1e)
- **What:** Added a lightweight facilitator check before plan writing. If there isn't enough information to write a plan without assumptions, present the top 3 unknowns as focused questions with answer options before proceeding. Includes a red flag: "If you're about to write 'Assuming X...' in the plan, STOP — ask the user about X instead."
- **Why:** The `ambiguity_scan` and `[NEEDS CLARIFICATION]` markers activate after the plan is written (Phase 1f). By then, assumptions are already baked into the plan structure. Moving discovery earlier — before plan writing — catches assumptions before they solidify.
- **To test:** Run `/story-cycle` with a vague request. Verify Phase 1d.5 triggers focused questions before plan writing begins. Verify the plan doesn't contain "Assuming..." language.
- **To revert:** Remove the "### 1d.5. Discovery Gate" section from story-cycle SKILL.md.

### Extensibility (OPT-102)

#### OPT-102: Skill-Specific Persistent Sidecar Memory
- **Modified:** `.claude/skills/SKILL_TEMPLATE.md` (new "Skill-Specific Persistent Memory (Sidecars)" section before Naming Conventions)
- **What:** Added a convention for skills to maintain persistent sidecar files in the auto memory directory (`{memory_dir}/{skill-name}.md`). Skills with `persistent-context: true` in YAML frontmatter check for their sidecar at startup and update it at completion. Sidecars are limited to ≤30 lines.
- **Why:** The auto memory directory is global. Some skills benefit from skill-specific memory across sessions — detected stack, commonly flagged patterns, successful debugging strategies. Sidecars provide this without polluting global memory.
- **To test:** Read SKILL_TEMPLATE.md and verify the "Skill-Specific Persistent Memory" section exists with convention, limits, and examples.
- **To revert:** Remove the "## Skill-Specific Persistent Memory (Sidecars)" section from SKILL_TEMPLATE.md.

### Version Updates

- Updated story-cycle SKILL.md with: risk classification, discovery gate, depth check, workflow state persistence, disaster prevention reference, elicitation techniques reference
- Updated continue SKILL.md with project health scan
- Updated reasoning-tools.md with `risk_classification` and `depth_exploration` tools
- Updated plan-template.md with workflow state frontmatter schema
- Updated self-review.md with disaster prevention reference
- Updated documentation.md with cross-skill output optimization
- Updated SKILL_TEMPLATE.md with sidecar memory convention
- Created 4 output templates for debug-session, brainstorm, manual-test, ideate
- Created elicitation-techniques.md shared reference
- Created disaster-prevention.md checklist reference

## [3.0.0] - 2026-02-22

### CI/CD Integration (OPT-83, OPT-84)

#### OPT-83: Claude-as-CI PR Reviewer
- **New:** `.github/workflows/claude-pr-review.yml`, `.claude/commands/review-pr-ci.md`
- **Modified:** `.claude/skills/sprint-end/SKILL.md` (Step 5 references CI workflow)
- **What:** Added a GitHub Actions workflow triggered on `pull_request` that uses `anthropics/claude-code-action@v1` to run automated code review. Tiered access: full review for repo members, structure-only for external contributors. The `/review-pr-ci` command runs code-quality, test-validator, and security-audit analysis patterns and posts a structured review as a PR comment. Tool sandboxing: `Read,Glob,Grep,Bash(git diff:*),Bash(git log:*),Bash(git status:*)`.
- **Why:** Local quality gates are comprehensive but only run when a developer remembers to invoke `/sprint-end`. CI-based review creates a safety net for PRs that bypass the framework workflow, and gives external contributors automated feedback without requiring framework installation.
- **To test:** Create a test PR. Verify the workflow triggers and posts a structured review comment. For external contributor simulation, create a PR from a fork — verify it gets structure-only review.
- **To revert:** Delete `.github/workflows/claude-pr-review.yml` and `.claude/commands/review-pr-ci.md`. Remove CI reference from sprint-end Step 5.

#### OPT-84: PR Template
- **New:** `.github/pull_request_template.md`
- **Modified:** `.claude/skills/sprint-end/SKILL.md` (Step 4 references template sections)
- **What:** Added a GitHub PR template with sections matching the Phase 3.5 self-review: Type of Change, Summary, Changes, Test Evidence, Quality Gates checklist, and Self-Review Checklist. Sprint-end Step 4 now fills in the template sections rather than a raw body.
- **Why:** Standardizes PR descriptions across the project and ensures quality gate evidence is always documented. Reduces the chance of skipping self-review items.
- **To test:** Create a PR via `gh pr create`. Verify the template sections appear in the PR body.
- **To revert:** Delete `.github/pull_request_template.md`. Restore original PR body format in sprint-end Step 4.

### Hook Lifecycle Completion (OPT-85, OPT-86)

#### OPT-85: SessionStart Hook
- **New:** `.claude/hooks/session-start.sh`
- **Modified:** `.claude/settings.json` (SessionStart hook entry), `.claude/hooks/README.md`
- **What:** Added an advisory hook that runs at session start. Checks: (1) project tools from CLAUDE.md Commands exist in PATH, (2) stale auto-save detection (>24h), (3) git state warnings (on main, detached HEAD, uncommitted changes), (4) missing hook coverage (Stop/PostToolUse not configured). Always exits 0 — never blocks.
- **Why:** Existing hooks enforce quality during and after work, but nothing validates the environment at session start. Common pain points (wrong branch, missing tools, stale state from previous session) are detectable upfront but currently only discovered mid-workflow.
- **To test:** Run `bash .claude/hooks/session-start.sh` on main with uncommitted changes. Verify it outputs warnings for both conditions. Run on a feature branch with clean state — verify no warnings.
- **To revert:** Delete `.claude/hooks/session-start.sh`. Remove SessionStart entry from settings.json. Remove session-start section from hooks README.

#### OPT-86: Hook-Based Activity Logging
- **New:** `.claude/hooks/activity-logger.sh`
- **Modified:** `.claude/settings.json` (PostToolUse hook entry), `.claude/hooks/README.md`, `.claude/skills/retrospective/SKILL.md` (activity log metrics), `.claude/skills/handoff/SKILL.md` (activity summary section)
- **What:** Added a PostToolUse hook that logs Edit, Write, and Bash invocations as timestamped JSON lines to `docs/sessions/.activity-log.jsonl`. Rotates at 200 entries. Extracts file path or command from stdin JSON. The retrospective skill consumes the log for metrics (hotspots, edit-to-bash ratio), and the handoff skill includes an activity summary.
- **Why:** Session metrics in retrospectives rely on estimates ("AI suggestion survival rate: [estimate]"). The activity log provides hard data: which files were edited, how often, and what commands were run — enabling data-driven retrospectives.
- **To test:** Run `echo '{"tool_name":"Edit","tool_input":{"file_path":"test.md"}}' | bash .claude/hooks/activity-logger.sh`. Verify `docs/sessions/.activity-log.jsonl` contains the entry.
- **To revert:** Delete `.claude/hooks/activity-logger.sh`. Remove PostToolUse entry from settings.json. Remove activity log sections from retrospective and handoff skills. Remove activity-logger section from hooks README.

### Framework Self-Validation (OPT-87, OPT-88)

#### OPT-87: Skill Conformance Validator
- **New:** `.claude/skills/doctor/scripts/validate-skills.sh`
- **Modified:** `.claude/skills/doctor/SKILL.md` (added 7th check: Skill Conformance)
- **What:** Added a validation script that iterates all `.claude/skills/*/SKILL.md` files and checks: YAML frontmatter exists with required fields (name, version, description, trigger, depends-on, references), line count ≤150, required sections present, reference file budgets (individual ≤200, total ≤500), and version match with skills-registry.json. Outputs per-skill conformance status and overall score.
- **Why:** Skills can drift from template standards as they evolve — missing frontmatter fields, exceeding line budgets, or version mismatches with the registry. A validator catches this automatically during `/doctor` health checks.
- **To test:** Run `bash .claude/skills/doctor/scripts/validate-skills.sh`. Verify it reports status for each skill and an overall score.
- **To revert:** Delete `.claude/skills/doctor/scripts/validate-skills.sh`. Remove "## 7. Skill Conformance" and "### Skill Conformance" sections from doctor SKILL.md.

#### OPT-88: Skills Registry Schema Validation
- **New:** `.claude/skills/skills-registry.schema.json`
- **Modified:** `.claude/skills/skill-create/scripts/update-registry.sh` (schema validation after regeneration), `.claude/skills/doctor/scripts/validate-skills.sh` (registry schema check)
- **What:** Added a JSON Schema enforcing required fields per registry entry (name, version, description, trigger, path), valid trigger enum values, and version/name format patterns. The update-registry.sh script validates its output against the schema. The validate-skills.sh script includes registry validation in its checks.
- **Why:** The registry is generated by a bash script using string manipulation — subtle format errors (missing fields, invalid JSON) are easy to introduce. Schema validation catches these at generation time rather than at consumption time.
- **To test:** Run `bash .claude/skills/skill-create/scripts/update-registry.sh`. Verify it reports schema check results. Introduce an intentional error (remove a name field) and verify validation catches it.
- **To revert:** Delete `.claude/skills/skills-registry.schema.json`. Remove schema validation block from update-registry.sh. Remove registry schema check from validate-skills.sh.

### Workflow Efficiency (OPT-89, OPT-90)

#### OPT-89: Story-Cycle Fast-Track Mode
- **Modified:** `.claude/skills/story-cycle/SKILL.md`
- **What:** Added size classification at Phase 0 (after intent decomposition): TRIVIAL (single-file, <10 lines, no behavioral change) skips to Phase 3-lite (make change → run tests → abbreviated self-review → commit). SMALL (single-file, <50 lines, clear AC) uses lightweight Phase 1 (skip 1f-1g). STANDARD (everything else) follows full workflow unchanged. Includes a red flag hard gate: "If editing multiple files or changing behavior, STOP and reclassify as STANDARD."
- **Why:** The full story-cycle (7 phases with clarification scanning, reasoning scaffolds, and completion verification) is designed for feature stories and complex changes. Trivial changes (typo fixes, config tweaks, comment updates) spend 80%+ of context on process overhead. Fast-track preserves quality gates for substantive work while reducing ceremony for trivial changes.
- **To test:** Run `/story-cycle "fix typo in README"`. Verify it classifies as TRIVIAL and uses Phase 3-lite (no plan mode, no clarification scan). Run `/story-cycle "add user authentication"`. Verify it classifies as STANDARD and uses full workflow.
- **To revert:** Remove "## Size Classification" section and "Phase 3-lite" section from story-cycle SKILL.md. Restore original process flow diagram (remove size classification branch).

#### OPT-90: Dynamic Quality Agent Scaling
- **Modified:** `.claude/skills/sprint-end/references/quality-gates.md`, `.claude/skills/sprint-end/SKILL.md`
- **What:** Added scope classification before agent dispatch in quality-gates.md Step 2c: Minimal (1-3 files, no src) → test-validator only. Small (1-5 src files) → code-quality + test-validator. Standard (6-15 src files) → all three agents. Large (16+ src files) → all three + multi-perspective review. Security-audit always included if security-sensitive paths in diff.
- **Why:** Current quality gates dispatch all agents regardless of sprint size. A 2-file documentation change runs the same 3-agent pipeline as a 20-file feature sprint. Scaling agents to scope reduces context consumption and latency for small sprints while maintaining thorough review for large ones.
- **To test:** Create a sprint that only changes docs files. Run `/sprint-end`. Verify only test-validator is dispatched. Create a sprint with 10+ src files. Verify all three agents are dispatched.
- **To revert:** Restore original "## 2c. Quality Agents" section in quality-gates.md (remove scope classification table, restore "Always dispatch" / "Conditionally dispatch" format). Remove "scope-based scaling" reference from sprint-end SKILL.md Step 2.

### Extensibility (OPT-91, OPT-92)

#### OPT-91: Tool Restriction per Agent Dispatch
- **Modified:** `.claude/skills/code-quality/SKILL.md`, `.claude/skills/security-audit/SKILL.md`, `.claude/skills/test-validator/SKILL.md`, `.claude/skills/SKILL_TEMPLATE.md`
- **What:** Added explicit tool restriction declarations to each quality agent: code-quality (Read, Glob, Grep only), security-audit (Read, Glob, Grep, Bash for scanners), test-validator (Read, Glob, Grep, Bash for test runner). Added a "Tool Restrictions for Subagents" section to SKILL_TEMPLATE.md with a per-agent-type table and guidance.
- **Why:** Quality agents are dispatched in forked context with `allowed-tools` in the header, but nothing in the skill body reinforces this. Claude can still attempt edits if the analysis suggests a "quick fix." Explicit tool restrictions in the prompt body create defense-in-depth — even if the header restriction fails, the prompt-level instruction prevents writes.
- **To test:** Dispatch `/code-quality` as a forked agent. Verify it does not attempt Edit or Write operations. Check the SKILL_TEMPLATE.md has the new "Tool Restrictions for Subagents" section.
- **To revert:** Remove "**Tool restriction:**" paragraphs from code-quality, security-audit, and test-validator SKILL.md files. Remove "### Tool Restrictions for Subagents" section from SKILL_TEMPLATE.md.

#### OPT-92: GitHub Issue Templates
- **New:** `.github/ISSUE_TEMPLATE/bug_report.yml`, `.github/ISSUE_TEMPLATE/feature_request.yml`
- **What:** Added YAML-form issue templates. Bug report: framework version, project stack, reproduction steps, expected/actual behavior, /doctor output, skill name. Feature request: use case, current workaround, proposed type (skill/rule/hook), backward compatibility.
- **Why:** GitHub issues for framework problems lack structured information — reporters don't know to include framework version, active skill, or /doctor output. Templates ensure consistent, actionable reports.
- **To test:** On GitHub, click "New Issue". Verify both templates appear as options. Fill out each template and verify all fields render correctly.
- **To revert:** Delete `.github/ISSUE_TEMPLATE/bug_report.yml` and `.github/ISSUE_TEMPLATE/feature_request.yml`.

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
- **What:** Added explicit line budgets for on-demand reference files: individual references ≤200 lines, total per skill ≤500 lines, and specific budgets for key project docs (CODING_STANDARDS ≤200, TESTING_STRATEGY ≤250, GROUND_RULES ≤100, ARCHITECTURE ≤200). Added guidance to load only relevant sections via grep hints.
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

#### OPT-74: Project Ground Rules Pattern
- **New file:** `docs/reference/GROUND_RULES.md`
- **Modified:** `.claude/skills/bootstrap/SKILL.md` (new step A3.6, process flow updated, version bumped), `.claude/skills/story-cycle/SKILL.md` (Phase 1e ground rules check, Rules section), `.claude/skills/sprint-end/SKILL.md` (Step 2 ground rules compliance gate)
- **What:** Added a "project ground rules" concept — a set of non-negotiable architectural principles per project (MUST/SHOULD classification). Created during `/bootstrap` (step A3.6) by prompting user for 3-7 principles. Checked during `/story-cycle` Phase 1e (MUST violation = HALT, SHOULD violation = document justification). Checked during `/sprint-end` quality gates (verify no untracked violations). The ground rules template includes sections for principles, amendment history, and tracked violations.
- **Why:** Architectural decisions made in sprint 1 erode by sprint 5 because they exist only in ARCHITECTURE.md prose. Ground rules create checkable constraints validated at planning time and shipping time, catching architectural drift before code is written.
- **To test:** Run `/bootstrap` on a project and verify it prompts for architectural principles and populates GROUND_RULES.md. Run `/story-cycle` with a plan that violates a MUST principle and verify HALT. Run `/sprint-end` and verify ground rules compliance is checked.
- **To revert:** Delete `docs/reference/GROUND_RULES.md`. Remove step A3.6 and its process flow line from bootstrap SKILL.md. Remove the `<IF condition="docs/reference/GROUND_RULES.md exists">` block from story-cycle Phase 1e. Remove the ground rules compliance `<IF>` block from sprint-end Step 2. Remove the ground rules reference from story-cycle Rules section.

#### OPT-75: Violation Tracking with Justification
- **Modified:** `.claude/skills/story-cycle/references/plan-template.md` (Architectural Violations table section)
- **What:** When a story plan violates a ground rules principle, the plan template now requires an explicit table: Principle Violated | Why Needed | Rejected Alternative. These violations are tracked in the ground rules' Tracked Violations section and cross-referenced with `docs/technical-debt.md`.
- **Why:** Creates accountability for technical debt at creation time, not retroactively. Forces justification and documentation of what simpler alternative was rejected.
- **To test:** Run `/story-cycle` with a plan that violates a SHOULD principle. Verify the Architectural Violations table appears in the plan with justification.
- **To revert:** Remove the "## Architectural Violations (if any)" section from plan-template.md. Remove the Tracked Violations section from GROUND_RULES.md.

### Workflow Polish (OPT-76, OPT-77)

#### OPT-76: Consistent Handoff Suggestions with Pre-Filled Commands
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (completion report), `.claude/skills/sprint-end/SKILL.md` (sprint complete summary), `.claude/skills/ideate/SKILL.md` (example output), `.claude/skills/brainstorm/SKILL.md` (example output), `.claude/skills/debug-session/SKILL.md` (example output)
- **What:** Every workflow skill's completion output now includes a "Next Steps" section with 1-3 contextual, ready-to-use slash commands. Story-cycle suggests next story/sprint-end/handoff. Sprint-end suggests sprint-start/retrospective/handoff. Ideate suggests sprint-start/story-cycle. Brainstorm suggests ideate/handoff. Debug-session suggests story-cycle/sprint-end/handoff.
- **Why:** Reduces friction between workflow steps. Users can proceed without remembering the workflow sequence or typing commands from memory. The suggestions are contextual — they reference actual workflow state.
- **To test:** Run any workflow skill to completion. Verify the output includes a "Next Steps" section with valid slash commands.
- **To revert:** Remove the "Next Steps" sections from: story-cycle completion report, sprint-end step 7 summary, ideate example, brainstorm example, debug-session example.

#### OPT-77: Per-Phase Context Loading Manifests
- **Modified:** `.claude/skills/story-cycle/SKILL.md` (Phase 2 Context Transition)
- **What:** Phase 2 now includes a prescriptive "RELOAD for Phase 3" manifest listing exactly which files to load (CODING_STANDARDS.md, TESTING_STRATEGY.md, plan target files, skill-specific context) and a "SKIP until Phase 4" list (progress.md, ARCHITECTURE.md, backlog files, GROUND_RULES.md). This replaces the previous generic "reload coding standards and relevant files."
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
