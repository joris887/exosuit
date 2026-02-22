# Changelog

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
