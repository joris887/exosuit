# Skills Inventory

Last updated: 2026-02-22

## Overview

This project uses the JD-LLM Development Framework skills. Skills are invoked with `/skill-name` or auto-invoked by Claude when relevant context is detected.

**Framework Version:** 3.4

## Core Workflow

The primary development workflow:

```
/sprint-start → /story-cycle (repeat per story) → /sprint-end
```

For first-time setup: `/bootstrap`
For backlog management: `/ideate`
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
| `/ideate`       | `<idea-or-requirement>` | Transform ideas into typed stories (single context window sized) |
| `/skill-create` | -                       | Generate tech skills, rules, and hook configs |

### Quality & Testing (Manual + Auto)

| Skill             | Auto-triggers         | Agent Type          |
| ----------------- | --------------------- | ------------------- |
| `/code-quality`   | After code changes    | Explore (forked)    |
| `/test-validator` | After implementation  | Explore (forked)    |
| `/security-audit` | Auth/credentials code | Explore (forked)    |

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

### Parallel Development (Manual-only)

| Skill            | Arguments                   | Description                              |
| ---------------- | --------------------------- | ---------------------------------------- |
| `/parallel-work` | `[list\|create\|cleanup]`   | Manage git worktrees for concurrent stories (worktree-aware bash hook ensures correct working directory) |

### Testing Workflow (Manual-only)

The user testing workflow runs parallel to the development workflow:

```
/sprint-start → /manual-test → user tests → /testing-cycle (repeat) → /sprint-end
```

For structured UAT with tracked test cases:

```
/sprint-start → /UAT-cycle (repeat per test case) → /sprint-end
```

**When to use which:** Use `/testing-cycle` for ad-hoc exploratory findings during manual testing. Use `/UAT-cycle` for pre-defined acceptance test cases from `UAT_COVERAGE.md`. Use `/claude-sense-check` to batch-verify UAT test case logic against actual code.

| Skill                  | Arguments                       | Description                                      |
| ---------------------- | ------------------------------- | ------------------------------------------------ |
| `/manual-test`         | -                               | Generate test plan from recent changes/issues    |
| `/testing-cycle`       | `<feedback-description>`        | Process one ad-hoc feedback item (classify → fix)  |
| `/UAT-cycle`           | `<test-case-id-or-description>` | Execute a formal UAT test case, process findings |
| `/claude-sense-check`  | -                               | Batch code logic verification of UAT cases (2-5 per run) |

**UAT Coverage File:** `docs/testing/UAT_COVERAGE.md`

### Skill Lifecycle (Manual-only)

| Skill            | Arguments                                              | Description                                          |
| ---------------- | ------------------------------------------------------ | ---------------------------------------------------- |
| `/skill-eval`    | `<mode> [skill-name] [--scenario <desc>]`              | Test, measure, or A/B compare skill effectiveness    |
| `/refine-loop`   | `"<task>" --until "<criteria>" [--max <N>]`            | Iterative self-improvement until completion criteria met |

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
Unified Python engine (`engine.py`) with YAML rule configuration. Two bash hooks kept for POSIX/file-type tasks:
- `engine.py` — Dispatch entry point routing to `handlers/` modules
- `rules/safety.yaml` — PreToolUse blocking patterns (9 rules)
- `rules/quality.yaml` — Stop quality gate rules
- `rules/subagent.yaml` — SubagentStop validation rules
- `rules/intent.yaml` — UserPromptSubmit intent rules
- `handlers/` — Per-event handler modules (pre_tool_use, post_tool_use, stop, user_prompt, subagent_stop, session_start, worktree)
- `state/session.json` — Per-session state (warnings, iterations)
- `post-edit-format.sh` — Auto-format after edits + secrets detection (bash)
- `worktree-bash-fix.sh` — Transparent worktree directory fix for Bash commands (bash, applied to subagents)

## References

- Skill Template: `.claude/skills/SKILL_TEMPLATE.md`
- Coding Standards: `docs/reference/CODING_STANDARDS.md`
- Testing Strategy: `docs/reference/TESTING_STRATEGY.md`
- Architecture: `docs/architecture/ARCHITECTURE.md`
- Hooks: `.claude/hooks/README.md`

## Version History

| Version | Date       | Changes                                                |
| ------- | ---------- | ------------------------------------------------------ |
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
