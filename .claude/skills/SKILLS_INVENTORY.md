# Skills Inventory

Last updated: 2026-08-19

## Overview

This project uses the Exosuit framework skills. Skills are invoked with `/skill-name` or auto-invoked by Claude when relevant context is detected.

**Framework Version:** 5.0

## Core Workflow

The primary development workflow:

```
/bootstrap → /discover (new projects) → /ideate → /sprint-start → /story-cycle (repeat) → /sprint-end
```

For first-time setup: `/bootstrap`
For deep guided discovery: `/discover`
For backlog management: `/ideate`
For phase transition reviews: `/phase-review`
For technology skill generation: `/skill-create`

## Skill Categories

### Setup

| Skill        | Trigger             | Description                                      |
| ------------ | ------------------- | ------------------------------------------------ |
| `/bootstrap` | First-run or reset  | Auto-detect stack, configure hooks/rules, or guide new project creation |

### Sprint Workflow (Manual-only)

| Skill           | Trigger            | Arguments             | Description                               |
| --------------- | ------------------ | --------------------- | ----------------------------------------- |
| `/sprint-start` | Starting new work  | `[branch] [--worktree]` | Pre-flight checks + branch (supports worktrees) |
| `/sprint-end`   | Completing sprint  | -                     | Quality gates, test protection, control flow markers, error recovery tables, graceful degradation, docs, PR, merge |
| `/story-cycle`  | Delivering a story | `<story-description>` | Universal story delivery (intent decomposition, confidence gate, reasoning scaffolds, control flow markers, error recovery tables, error learning, completion verification, parallel stream decomposition, wave execution) |
| `/continue`     | Session start      | -                     | Smart continuation from session files + git state |
| `/handoff`      | Session end        | -                     | Structured session file to docs/sessions/ |

### Backlog & Planning (Manual-only)

| Skill           | Arguments               | Description                                 |
| --------------- | ----------------------- | ------------------------------------------- |
| `/brainstorm`   | `<idea-or-topic>`       | Design exploration with alternatives before story decomposition |
| `/ideate`       | `<idea-or-requirement>` | Transform ideas into typed stories (cohesion-sized) |
| `/skill-create` | -                       | Generate tech skills, rules, and hook configs |
| `/discover`     | `"<idea>" [--quick\|--platform\|--pioneer]` | Deep guided elicitation — archetype-aware, research-backed discovery with assumption tracking and Phase Transition Stories |
| `/phase-review` | `[phase-number]`                             | Phase transition review — walkthrough, assumption validation, and next-phase planning |
| `/research`     | `<topic-or-question>`   | Deep online research with parallel sub-question investigation, source evaluation, and structured reports |

### Quality & Testing (Manual + Auto)

| Skill             | Auto-triggers         | Agent Type          |
| ----------------- | --------------------- | ------------------- |
| `/code-quality`   | After code changes    | Explore (forked)    |
| `/test-validator` | After implementation  | Explore (forked)    |
| `/security-audit` | Auth/credentials code | Explore (forked)    |
| `/quality-check`  | Manual (or via sprint-end/story-cycle) | Dispatches quality agents with profile-aware defaults |

### Architecture (Manual + Auto)

| Skill                | Trigger              | Agent Type       |
| -------------------- | -------------------- | ---------------- |
| `/architecture-check` | Major code changes  | Explore (forked) |

### Maintenance (Manual-only)

| Skill                 | Frequency  | Description                        |
| --------------------- | ---------- | ---------------------------------- |
| `/weekly-maintenance` | Fridays    | Health check + dependency governance |
| `/retrospective`      | Sprint-end | 4Ls framework with metrics dashboard |
| `/backlog-review`     | As needed  | Backlog health analysis            |
| `/doctor`             | As needed  | Framework health check + dependency validation |
| `/framework-upgrade`  | As needed  | Upgrade framework to newer version, preserving project customizations |

### Parallel Development (Manual-only)

| Skill            | Arguments                       | Description                              |
| ---------------- | ------------------------------- | ---------------------------------------- |
| `/parallel-work` | `[status\|start [count]\|cleanup]` | Work on multiple stories at once: creates isolated parallel streams (git worktrees) from the current branch with local settings wired up, shows stream status, cleans up finished streams (worktree-aware bash hook ensures correct working directory) |
| `/merge-up`      | —                               | Inside a stream: merge its committed work into the parent branch it was created from, then sync the stream back up to the parent |
| `/merge-down`    | —                               | Inside a stream: pull the parent branch's accumulated work (other streams' merged stories) down into this stream |

### Testing Workflow (Manual-only)

The user testing workflow runs parallel to the development workflow:

```
/sprint-start → /manual-test → user tests → /testing-cycle (repeat) → /sprint-end
```

For structured UAT with tracked test cases:

```
/sprint-start → /UAT-cycle (repeat per test case) → /sprint-end
```

For automated testing of the running application (Claude executes the plan itself):

```
/sprint-start → /live-test <scope> → /testing-cycle | /ideate handoffs → /sprint-end
```

**When to use which:** Use `/testing-cycle` for ad-hoc exploratory findings during manual testing. Use `/UAT-cycle` for pre-defined acceptance test cases from `UAT_COVERAGE.md`. Use `/claude-sense-check` to batch-verify UAT test case logic against actual code. Use `/live-test` when Claude should execute the tests itself against the running app (web, API, or CLI surface).

| Skill                  | Arguments                       | Description                                      |
| ---------------------- | ------------------------------- | ------------------------------------------------ |
| `/manual-test`         | -                               | Generate test plan from recent changes/issues    |
| `/live-test`           | `<scope> [--surface <name>|all] [--no-fix]` | Autonomously test the running app: plan → drive → verify → fix criticals → report |
| `/testing-cycle`       | `<feedback-description>`        | Process one ad-hoc feedback item (classify → fix)  |
| `/UAT-cycle`           | `<test-case-id-or-description>` | Execute a formal UAT test case, process findings |
| `/claude-sense-check`  | -                               | Batch code logic verification of UAT cases (2-5 per run) |

**UAT Coverage File:** `docs/testing/UAT_COVERAGE.md`

### Skill Lifecycle (Manual-only)

| Skill            | Arguments                                              | Description                                          |
| ---------------- | ------------------------------------------------------ | ---------------------------------------------------- |
| `/skill-eval`    | `<mode> [skill-name] [--scenario <desc>]`              | Test, measure, or A/B compare skill effectiveness    |
| `/refine-loop`   | `"<task>" --until "<criteria>" [--max <N>]`            | Iterative self-improvement until completion criteria met |
| `/optimize`      | `"<goal>" --metric "<cmd>" --target <N> [--direction min\|max]` | Autonomous metric-driven optimization with git checkpointing and automatic rollback |

### Guided Experiences (Manual-only)

| Skill            | Arguments                  | Description                                      |
| ---------------- | -------------------------- | ------------------------------------------------ |
| `/quickstart`    | -                          | Guided interactive tour of the framework         |
| `/build`         | `"<description>"`          | Build from plain-English description — handles all technical decisions automatically |
| `/deploy`        | `[platform] [--dry-run]`   | Deploy to hosting platform with pre-deploy checks and platform auto-detection |
| `/help-me`       | `"<what you want to do>"`  | Natural language skill discovery                 |
| `/dashboard`     | -                          | Sprint status overview with actionable next steps |

### Utility (Manual-only)

| Skill            | Arguments        | Description          |
| ---------------- | ---------------- | -------------------- |
| `/commit`        | `[type] [scope]` | Conventional commit  |
| `/fix-issue`     | `<issue-number>` | GitHub issue fixer   |
| `/pr-status`     | -                | Check PR status      |
| `/undo-work`     | `[--soft\|--hard\|--story]` | Safely revert failed implementation attempts |
| `/debug-session` | `<error>`        | 5-phase structured debugging with reasoning scaffolds, error recovery tables, error learning, halt conditions |

### Prompt Snippets (`.claude/prompts/`)

Lightweight, reusable prompt templates — simpler than full skills. See `.claude/prompts/README.md`.

| Snippet             | Arguments            | Description                          |
| ------------------- | -------------------- | ------------------------------------ |
| `/review-security`  | `<file-path>`        | Security review of a specific file   |
| `/explain-pattern`  | `<pattern> [file]`   | Explain a code pattern in this codebase |
| `/suggest-tests`    | `<file-path>`        | Suggest test cases for a file        |

Internal prompt snippets (composed by skills, not user-invocable):

| Snippet              | Purpose                                                  |
| -------------------- | -------------------------------------------------------- |
| `deep-research`      | Research engine: decompose → parallel dispatch → reflect → synthesize → deepen |
| `source-evaluator`   | Source quality scoring (0-10) with positive/negative signal criteria |

### Native Agents (`.claude/agents/`)

Claude Code native agents with YAML frontmatter. Discoverable via `claude agents` CLI.

| Agent                  | Model   | Purpose                                              |
| ---------------------- | ------- | ---------------------------------------------------- |
| `code-reviewer`        | inherit | Code review with severity classification             |
| `spec-reviewer`        | haiku   | Spec compliance verification with file:line refs     |
| `security-analyst`     | inherit | Security-focused analysis with attacker mindset      |
| `performance-engineer` | inherit | Performance analysis with bottleneck identification  |
| `architecture-reviewer`| inherit | Architecture validation with boundary enforcement    |
| `codebase-explorer`    | haiku   | Fast file discovery and codebase mapping             |
| `research-analyst`     | haiku   | Deep web research with source evaluation and reflection output |
| `integration-tester`   | inherit | Independent dynamic verification — runs tests and acceptance criteria, breaking the self-assessment cycle |

### Technology Skills (Auto-invocable)

Generated by `/skill-create`. Auto-invoked when working with the relevant technology.

Run `/skill-create` after `/bootstrap` to generate technology-specific skills for your stack.

## Story Type Reference

The `/story-cycle` skill adapts its methodology based on story type:

| Type           | Approach                                   | When to Use                |
| -------------- | ------------------------------------------ | -------------------------- |
| Feature        | TDD (RED-GREEN-REFACTOR)                   | New user-facing capability |
| Bug Fix        | Reproduce → Test → Fix → Verify            | Defects and error reports  |
| Refactoring    | Characterization tests → Refactor → Verify | Code restructuring         |
| Spike/Research | Explore → Document → Decide                | Unknowns and evaluations   |
| Infrastructure | Plan → Implement → Smoke Test              | CI/CD, tooling, config     |
| Testing        | Design → Generate → Validate               | Test coverage, E2E tests   |
| Documentation  | Gather → Generate → Review                 | Docs, READMEs, ADRs        |
| Security       | Threat model → Implement → Audit           | Hardening, vulnerabilities |
| Performance    | Baseline → Optimize → Benchmark            | Speed, memory, latency     |
| Skill/Tooling  | Design → Build → Document                  | Developer experience       |
| Review         | Walkthrough → Document → Decide             | Phase transition reviews   |

## Skill Design Patterns

### YAML Frontmatter

All skills include machine-readable YAML frontmatter with: `name`, `version`, `trigger`, `depends-on`, `references`. See `SKILL_TEMPLATE.md` for format.

### Agent Types

- **`agent: Explore`** — Read-only analysis (code-quality, test-validator, security-audit, architecture-check)
- **`agent: general-purpose`** — Full capabilities (Edit, Write, Bash)
- **`agent: Plan`** — Planning without execution

### Resource Types

| Directory      | Purpose                             | Context Impact             |
|----------------|-------------------------------------|----------------------------|
| `scripts/`     | Executable code — run, don't read   | Zero (black-box execution) |
| `references/`  | Documentation — load on demand      | Medium (grep for sections) |
| `assets/`      | Output templates — copy, don't read | Zero (copy and edit)       |

### Context Management

- **Inline** (default) — Workflow skills guiding main conversation
- **`context: fork`** — Analysis agents (keeps main context clean)
- **Confidence scoring** — Quality agents rate findings 0–100; only ≥80 is actionable
- **Parallel dispatch** — Sprint-end quality agents run simultaneously, not sequentially
- **Reasoning scaffolds** — Named reasoning tools (scope_analysis, test_strategy_selection, failure_diagnosis, architectural_impact, plan_completeness) scaffold thinking at critical decision points
- **Control flow markers** — `<IF>/<ELSE>`, `<LOOP>`, `<HALT>` extend HARD-GATE to cover all conditional logic
- **Error recovery tables** — Phase-specific error/cause/recovery decision tables for complex skills
- **Micro-components** — Reusable operation sequences (discover-commands, quality-gate-sequence, verify-clean-git-state, confidence-gate, record-failure, wave-execution, select-tool) referenced by multiple skills

### Invocation Control

- **`disable-model-invocation: true`** — Workflow skills with side effects
- **Auto-invocable** — Analysis agents triggered by context keywords and `<example>` blocks

## Enforcement Layers

### Rules (`.claude/rules/`)
Path-scoped rules loaded automatically when matching files are edited:
- `testing.md` — Test protection (never weaken, never delete)
- `documentation.md` — Documentation discipline
- `security.md` — CWE checklist for sensitive files + fix-immediately pattern
- `git.md` — Git workflow rules
- `dependencies.md` — Dependency governance
- `verification.md` — Evidence required before completion claims + task completion enforcement + context budget awareness + context relevance scoring + pre-compaction state persistence
- `code-slop.md` — AI slop detection: banned comment patterns, obvious comment detection, code prose anti-patterns
- `edit-recovery.md` — Edit failure recovery decision tree with escalating recovery strategy
- `documentation.md` — Documentation discipline + reference file size budgets

### Hooks (`.claude/hooks/`)
POSIX shell scripts — no Python or other runtime required. Each event has its own self-contained script:
- `pre-tool-use.sh` — Block dangerous Bash commands (9 safety patterns)
- `post-tool-use.sh` — Activity logging to `.activity-log.jsonl`
- `session-start.sh` — Advisory environment checks
- `stop.sh` — Auto-save + completion evidence validation
- `user-prompt.sh` — Advisory intent classification
- `subagent-stop.sh` — Subagent quality warnings
- `worktree.sh` — Worktree init + cleanup
- `worktree-bash-fix.sh` — Transparent worktree directory fix (applied to subagents)
- `post-edit-format.sh` — Auto-format after edits + secrets detection (bash)
- `post-tool-failure.sh` — Log tool failures + inject error recovery guidance
- `pre-compact.sh` — Preserve critical session state before context compaction
- `pre-read-check.sh` — Warn when reading sensitive files (pattern-matched)
- `status-line.sh` — Rich status line: sprint, branch, context bar, model, rate limits
- `rules/safety.patterns` — PreToolUse blocking patterns (@@-delimited)
- `rules/quality.conf` — Stop quality gate rules (key=value)
- `state/` — Session state (plain text files: counters, timestamps)

## References

- Skill Template: `.claude/skills/SKILL_TEMPLATE.md`
- Coding Standards: `docs/reference/CODING_STANDARDS.md`
- Testing Strategy: `docs/reference/TESTING_STRATEGY.md`
- Architecture: `docs/architecture/ARCHITECTURE.md`
- Hooks: `.claude/hooks/README.md`

## Version History

| Version | Date       | Changes                                                |
| ------- | ---------- | ------------------------------------------------------ |
| 5.0     | 2026-08-05 | Rebrand: framework renamed to Exosuit (repo `joris887/exosuit`, plugin/marketplace `exosuit`, env vars `JD_*` → `EXOSUIT_*`). No functional changes |
| 4.1     | 2026-04-03 | Deep guided elicitation: `/discover` skill with 11 archetype-aware question banks, 4 discovery modes (Quick/Guided/Platform/Pioneering), DECISION_LOG + ASSUMPTION_REGISTER tracking, Phase Transition Stories (infinite build→review→discover cycle), `/phase-review` skill, "Review" story type, discovery context loading in story-cycle/ideate/build, question scaffolding rules, engineering adaptation by archetype |
| 3.8     | 2026-03-23 | Comprehensive upgrade: `/quickstart`, `/help-me`, `/dashboard`, `/custom-hooks`, `/uninstall`, `/performance-check` skills, centralized error recovery, standardized argument validation, framework test suite for hooks, team workflow support (human review, CODEOWNERS, TEAM_WORKFLOW.md), security enhancements (SBOM, .env template, secret rotation), architecture documentation (C4+Mermaid templates, MADR ADRs, API docs), developer experience (status line skill indicator, keybindings), framework versioning (MANIFEST.md, machine-parseable CHANGELOG), CLAUDE.md lazy-loading (renamed .claude-context.md to CLAUDE.md), skill lifecycle events for metrics, coverage tool reference table, universal coding standards, lightweight story template |
| 3.7     | 2026-03-20 | Metric-driven optimization: `/optimize` skill with git checkpointing and automatic rollback, story-cycle git checkpoint + auto-rollback on verification failure, story-scoped file boundaries, simplicity assessment in `/code-quality`, `capture-outcome` micro-component for structured story outcome tracking, `/refine-loop` autonomous mode with TSV logging and diminishing-returns detection |
| 3.6     | 2026-03-16 | Deep research capability: `/research` skill, `deep-research` engine snippet, `source-evaluator` snippet, `research-analyst` agent, research rule, depth-calibrated research in bootstrap/brainstorm/ideate/story-cycle, reflection-based context compression, parallel subagent dispatch for research, prior research caching |
| 3.4     | 2026-02-23 | Confidence gate, four-question evidence protocol, cross-session error learning, wave execution pattern, MCP integration guide, domain-specific agent personas, completion evidence protocol |
| 3.2     | 2026-02-23 | Worktree-aware bash hook, parallel stream decomposition, project context knowledge base, script delegation (status/standup/next-story), documentation accuracy safeguards, template repo safety check |
| 3.0     | 2026-02-22 | CI PR review, PR template, session-start hook, activity logging, skill conformance validator, registry schema, story-cycle fast-track, dynamic quality scaling, agent tool restrictions, GitHub issue templates |
| 2.9     | 2026-02-22 | Pre-compaction state persistence, secrets detection hook, skill prerequisites, subagent context protocol, reference file budgets, context budget visibility, /doctor health check, hook self-validation, dead code detection |
| 2.7     | 2026-02-22 | Cognitive reasoning scaffolds, symbolic state encoding, control flow markers (IF/ELSE/LOOP/HALT), phase-specific error recovery tables, context relevance scoring, reusable micro-components |
| 2.6     | 2026-02-22 | AI slop detection rule, edit recovery protocol, priority-based compaction, intent decomposition, completion verification, parallel research, session auto-save, expanded anti-patterns, graceful degradation expansion, context budget awareness |
| 2.5     | 2026-02-22 | Script black-boxing, grep navigation hints, resource types, skill scaffolding, I/O examples, DO/DON'T pairs, graceful degradation, pre-execution validation, skills registry |
| 2.4     | 2026-02-22 | Confidence scoring, parallel quality gates, multi-perspective review, skill-eval, refine-loop, agent-first file discovery, example block triggers, session hook state, YAML frontmatter |
| 2.3     | 2026-02-22 | Skill reference splitting, helper scripts, QA framing, Don'ts lists, CLI discovery pattern, doc quality sub-agents, co-located tech skill references, context budget principle, environment adaptation |
| 2.2     | 2026-02-22 | Hard gates, trigger-only descriptions, verification rule, red flag tables, inline self-review, deepened debug-session, brainstorm skill, process flowcharts, subagent templates, TDD for skills, fix-immediately pattern |
| 2.1     | 2026-02-22 | Structured compaction, cumulative file tracking, graduated context reset, enriched handoffs, expanded safety hooks, incremental linting, error recovery, health dashboard, prompt snippets |
| 2.0     | 2026-02-21 | Hooks, rules, worktrees, test protection, CWE checks, metrics, architecture-check, parallel-work, session persistence, context management |
| 1.1     | 2026-02-21 | Added testing workflow: UAT-cycle, testing-cycle, manual-test |
| 1.0     | 2026-02-21 | Initial framework release: 18 skills, bootstrap flow         |
