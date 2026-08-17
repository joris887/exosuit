# Exosuit — Technical Reference

The complete reference for every element of the framework, structured as the user journey from installation through ongoing maintenance. Start with the [README](../README.md) for an overview, or [Getting Started](GETTING_STARTED.md) for your first 5 minutes.

**Framework version:** v5.0.0
**Date:** 2026-04-05

---

## Table of Contents

1. [Framework Overview](#1-framework-overview)
2. [Architecture at a Glance](#2-architecture-at-a-glance)
3. [Quick Start](#3-quick-start)
4. [Flow: Installation](#4-flow-installation)
5. [Flow: Bootstrap & Project Setup](#5-flow-bootstrap--project-setup)
6. [Flow: Planning & Backlog Creation](#6-flow-planning--backlog-creation)
7. [Flow: Building — The Sprint Lifecycle](#7-flow-building--the-sprint-lifecycle)
8. [Flow: Testing](#8-flow-testing)
9. [Flow: Session Management](#9-flow-session-management)
10. [Flow: Debugging & Recovery](#10-flow-debugging--recovery)
11. [Flow: Maintenance & Review](#11-flow-maintenance--review)
12. [Flow: Parallel Work & Utilities](#12-flow-parallel-work--utilities)
13. [Under the Hood: The Three Layers](#13-under-the-hood-the-three-layers)
14. [File Structure & Inventory](#14-file-structure--inventory)
15. [Glossary](#15-glossary)
16. [Troubleshooting](#16-troubleshooting)

---

## 1. Framework Overview

### The Problem

Ask an AI to add a feature, and it probably will, but it might silently break three other things in the process. Ask it to fix a bug, and it might weaken your test suite to make the tests pass. Ask it to refactor a module, and it might claim success without ever running a single test.

This is the core challenge of AI-assisted development. Language models optimize for the immediate instruction. They are still just Large **Language** Models and not Common Sense Models, so the common sense that any experienced developer takes for granted, the awareness to protect existing tests, respect architectural boundaries, verify their own claims, and preserve the dozens of unwritten conventions that hold a codebase together is not there in a language model. On simple projects, this is manageable. On complex projects with production users, real test suites, and team conventions, AI development becomes a frustrating cycle of building and breaking.

### The Vision

Exosuit exists to solve this. It imposes software engineering methodology on AI-assisted development, not through guidelines the AI can choose to ignore, but through deterministic enforcement hooks, structured workflows, and quality gates at every level.

The goal: make AI-assisted development viable for real projects. Not just prototypes and demos, but complex applications with existing codebases, production users, and team conventions. Any language. Any project size. Any developer.

Install it once. Run `/quickstart`. Start building. The framework provides that common sense.

### What It Is

A drop-in development framework for Claude Code that provides 45 skills (slash commands), 13 hook scripts, path-scoped rules, quality gates, backlog management, session continuity, 8 native agents with deterministic tool restrictions for multi-perspective review, 20 reusable prompt snippets, deep guided elicitation with 11 project archetypes, and a persistent project knowledge base, all as markdown and shell scripts that live inside the repository.

### Who It's For

- **Solo developers** and **teams** — both benefit from structured AI workflow
- **Any project size** — from small scripts to large monorepos (workflow depth adapts via project profiles and per-story risk calibration)
- **Any language** — Python, JavaScript, TypeScript, Go, Rust, Ruby, Java, PHP, Dart, C#, C/C++, Swift, Kotlin (auto-detects and configures)
- **Existing repositories** (brownfield) and **new projects** (greenfield) — both have dedicated bootstrap paths

Not needed for one-off questions, quick scripts, or projects where you don't want structured workflow.

### Prerequisites

| Requirement | Why | Notes |
|---|---|---|
| **Claude Code** | The framework is built for Claude Code's skill/hook/rule system | Required |
| **Git** | Sprint branches, feature branches, squash merge workflow | Required |
| **GitHub account** | PR workflow, CI review, issue tracking | Required for full workflow; local-only works without |
| **`gh` CLI** | PR creation, issue management, CI status checks | Required for `/fix-issue`, `/pr-status`, `/sprint-end` |
| **Stack-specific tools** | Auto-format on every edit, quality gates | Optional — framework detects what's available |

No language runtimes required. The framework itself is pure POSIX shell and markdown.

### Design Principles

| Principle | What It Prevents |
|---|---|
| **TDD-first** | Code that "looks right" but doesn't work |
| **Sprint-based** | Unbounded scope, context exhaustion |
| **Git-disciplined** | Messy history, broken main, lost work |
| **Documentation-lean** | Context budget wasted on stale docs |
| **AI-aware** | Hallucinated APIs, weakened tests, phantom packages |
| **Verification-driven** | AI claims completion without evidence |
| **Context-efficient** | Context window exhaustion mid-session |
| **Clarification-first** | LLM makes plausible but wrong assumptions |
| **Ground-rules-governed** | Architectural decisions erode over time |
| **Risk-calibrated** | Trivial changes over-processed, risky changes under-reviewed |
| **Confidence-first** | Wrong-direction implementation wastes context |
| **Observable** | No visibility into framework effectiveness |
| **Secrets-aware** | Credentials committed to source control |
| **CI-enforced** | Local workflow bypassed on shared branches |
| **Anti-slop** | AI-generated filler comments, obvious narration |
| **Session-resilient** | Context loss across sessions |
| **Team-aware** | Solo developer assumptions in shared projects |
| **Profile-adaptive** | One-size-fits-all workflow mismatches project needs |
| **Archetype-aware** | One-size-fits-all elicitation misses project-specific concerns |
| **Assumption-tracked** | Silent LLM assumption filling leads to wrong-direction builds |

How each principle is enforced is documented throughout this reference — hooks, rules, skills, and quality gates work together to make these operational, not aspirational.

### Context Footprint

| Component | When loaded | Approximate size |
|---|---|---|
| CLAUDE.md | Every session (auto) | ~100 lines |
| Always-active rules (git.md, verification.md, edit-recovery.md) | On any file edit | ~140 lines combined |
| Conditional rules (testing.md, security.md, code-slop.md, etc.) | When matching files are edited | Only relevant ones load |

Skills load on-demand (only when invoked) with a lean entry point (~150 lines) and references loaded as needed.

**Settings (v4.1):**

| Setting | Value | Purpose |
|---|---|---|
| `attribution` | `Co-Authored-By: Claude <noreply@anthropic.com>` | Native commit byline (replaces advisory git.md rule) |
| `plansDirectory` | `docs/plans` | Plan files co-located with project |
| `includeGitInstructions` | `false` | Saves ~500 tokens/session (framework provides git.md rule) |
| `outputStyle` | `.claude/output-styles/framework.md` | Structured engineering output format |
| `statusLine` | `bash .claude/hooks/status-line.sh` | Status bar: `Sprint N \| branch-name*` |
| `spinnerVerbs` | Discovering, Planning, Building, Testing, ... | Framework-specific progress verbs |
| `spinnerTipsOverride` | `/story-cycle`, `/doctor`, TDD, `/handoff`, ... | Framework tips during processing |

**Environment Variables (v4.1):**

| Variable | Values | Default | Purpose |
|---|---|---|---|
| `EXOSUIT_PROJECT_PROFILE` | `lean\|standard\|strict` | `standard` | Controls skill ceremony depth and agent dispatch |
| `EXOSUIT_HOOK_PROFILE` | `minimal\|standard\|strict` | Derived from project profile | Controls hook behavior; overrides project-derived default |
| `EXOSUIT_DISABLED_HOOKS` | Comma-separated hook IDs | (empty) | Disable specific hooks at runtime |
| `EXOSUIT_EXPLAIN_MODE` | `off\|brief\|verbose` | `brief` | Hook message verbosity — `verbose` adds WHY/INSTEAD explanations |
| `EXOSUIT_STOP_MAX_ITERATIONS` | Integer (≤0 = no limit) | `5` (`10` for strict) | Stop hook safety valve iteration limit |

---

## 2. Architecture at a Glance

### The Three Layers

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│   ┌──────────────────────────────────────────────────────────────────┐   │
│   │                     ENFORCEMENT LAYER                            │   │
│   │                                                                  │   │
│   │   Hooks (13 POSIX shell scripts)     Rules (9 markdown files)    │   │
│   │   ════════════════════════════       ═════════════════════════   │   │
│   │   DETERMINISTIC — AI cannot          ADVISORY — auto-loaded      │   │
│   │   bypass. Scripts physically         when matching files are     │   │
│   │   run on Claude Code events.         edited. Strongly guide      │   │
│   │   Block or allow actions.            behavior.                   │   │
│   │                                                                  │   │
│   │   Examples:                          Examples:                   │   │
│   │   • Block git push --force           • Never weaken assertions   │   │
│   │   • Auto-format on every edit        • CWE top 10 checklist      │   │
│   │   • Scan for secrets                 • No filler comments        │   │
│   │   • Block premature "done"           • Evidence for completion   │   │
│   └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌──────────────────────────────────────────────────────────────────┐   │
│   │                      WORKFLOW LAYER                              │   │
│   │                                                                  │   │
│   │   Skills (43)          Agents (8)          Micro-Components (20) │   │
│   │   ═══════════          ══════════          ════════════════════  │   │
│   │   Slash commands       Subagent            Reusable prompt       │   │
│   │   loaded on demand.    personas with       snippets composed     │   │
│   │   Guide methodology.   restricted          into skills.          │   │
│   │                        tools.                                    │   │
│   │   Examples:            Examples:           Examples:             │   │
│   │   • /story-cycle       • code-reviewer     • readiness-gate      │   │
│   │   • /sprint-end        • security-analyst  • quality-gate-seq    │   │
│   │   • /bootstrap         • codebase-explorer • context-prime       │   │
│   └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌──────────────────────────────────────────────────────────────────┐   │
│   │                    DOCUMENTATION LAYER                           │   │
│   │                                                                  │   │
│   │   CLAUDE.md (entry)  →  docs/context/* (knowledge base)          │   │
│   │   progress.md (state) →  docs/sessions/ (handoff + auto-save)    │   │
│   │   docs/reference/*    →  docs/solutions/ (learnings)             │   │
│   │                                                                  │   │
│   │   Auto-loaded: CLAUDE.md (~100 lines, every session)             │   │
│   │   On-demand: everything else (loaded by skills as needed)        │   │
│   └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### How the Layers Interact — A Single Edit

When Claude edits a file, all three layers activate:

```
Claude edits src/auth/login.ts
     │
     ├──→ ENFORCEMENT (automatic, deterministic)
     │    ├── [Hook] post-edit-format.sh → auto-format with prettier
     │    ├── [Hook] post-edit-format.sh → scan for hardcoded secrets
     │    ├── [Hook] post-tool-use.sh    → log to activity-log.jsonl
     │    ├── [Rule] security.md         → auto-loaded (auth/** path match)
     │    ├── [Rule] code-slop.md        → auto-loaded (*.ts path match)
     │    ├── [Rule] git.md              → always active (** path match)
     │    ├── [Rule] verification.md     → always active (** path match)
     │    └── [Rule] edit-recovery.md    → always active (** path match)
     │
     ├──→ WORKFLOW (guided by active skill)
     │    └── /story-cycle Phase 3 → TDD implementation methodology
     │
     └──→ DOCUMENTATION (persistent state)
          └── docs/sessions/.activity-log.jsonl updated
```

### How the Layers Interact — A File Read

```
Claude reads .env.production
     │
     └──→ ENFORCEMENT (automatic, deterministic)
          └── [Hook] pre-read-check.sh → warn: "secrets may enter context window"

Note: Rules (security.md, etc.) only auto-load on EDITS, not reads.
The pre-read-check.sh hook is the sole guard on sensitive file reads.
```

### How the Layers Interact — Full Story Delivery

```
User types: /story-cycle "add login"
     │
     ▼ ─── WORKFLOW ─────────────────────────────────────────
     │  story-cycle SKILL.md loaded
     │  Phase 0: Intent decomposition (classify size + risk)
     │  Phase 1: Plan Mode (research, plan, user approval)
     │  Phase 2: Context transition (discard bulk, keep insights)
     │  Phase 2.5: Readiness gate (5 objective PASS/FAIL checks)
     │  Phase 3: Implementation begins
     │     │
     │     ├── Claude edits test_login.py
     │     │      ▼ ─── ENFORCEMENT ──────────────────────────
     │     │      │  [Rule] testing.md → "never weaken assertions"
     │     │      │  [Hook] post-edit-format.sh → auto-format + secrets
     │     │      │  [Hook] post-tool-use.sh → log to activity-log
     │     │      ▼ ─── DOCUMENTATION ────────────────────────
     │     │         activity-log.jsonl updated
     │     │
     │     ├── Claude edits auth.py
     │     │      ▼ ─── ENFORCEMENT ──────────────────────────
     │     │      │  [Rule] security.md → CWE checklist, no secrets
     │     │      │  [Rule] code-slop.md → no filler comments
     │     │      │  [Hook] post-edit-format.sh → format + lint
     │     │
     │     ├── Claude runs `git push --force`
     │     │      ▼ ─── ENFORCEMENT ──────────────────────────
     │     │      │  [Hook] pre-tool-use.sh → BLOCKED
     │     │
     │     ├── Claude tries to stop (claim "done")
     │     │      ▼ ─── ENFORCEMENT ──────────────────────────
     │     │         [Hook] stop.sh → check evidence → block if none
     │     │         → auto-save to .auto-save.md
     │
     ▼ ─── WORKFLOW ─────────────────────────────────────────
        Phase 3.5: Self-review + disaster prevention
        Phase 4: quality-gate-sequence + commit
        Phase 4.5: Completion verification
```

---

## 3. Quick Start

Five commands take a project from zero to structured development:

```
1. Install    ./install.sh                         copies framework into your project
2. Start      /quickstart                          guided tour (or /bootstrap for direct setup)
3. Discover   /discover "build user auth"           deep guided elicitation (new projects)
4. Plan       /ideate "build user auth"             decomposes ideas into sized stories
5. Sprint     /sprint-start                        creates a clean feature branch
6. Deliver    /story-cycle "E01-001"               implements with TDD + quality gates
```

Then repeat steps 5–6. Ship with `/sprint-end` (creates PR, runs CI, squash merges to main). After the first batch of features, `/phase-review` evaluates what you built and plans the next phase.

**For non-technical users:** `/build "a task management app"` handles everything (setup, planning, implementation) in one command with plain-English output.

### Typical Day

```
Start Claude Code session
     │
     ▼
/sprint-start                  ← clean state, feature branch
     │
     ├── /story-cycle "E02-003"  ← plan → approve → implement → verify → commit
     ├── /story-cycle "E02-004"  ← repeat for next story
     │
     ▼
/sprint-end                    ← quality gates → PR → merge to main
```

### Minimal Viable Workflow

```
/bootstrap → /sprint-start → /story-cycle → /sprint-end
```

For new projects with deep discovery:

```
/bootstrap → /discover → /ideate → /sprint-start → /story-cycle → /sprint-end → /phase-review
```

Everything else — `/brainstorm`, `/manual-test`, `/weekly-maintenance`, `/retrospective`, etc. — adds value but can be adopted incrementally.

### What Happens Behind the Scenes

While you work, the framework is active in the background:
- **Hooks** auto-format your code, scan for secrets, block dangerous commands, auto-save session state
- **Rules** auto-load when you edit test files, security-sensitive code, or dependency manifests
- **Quality agents** review your code for correctness, test quality, and security before shipping

You don't invoke these directly — they fire automatically based on what you're doing.

---

## 4. Flow: Installation

### Overview

```
YOU ARE HERE ──→ install.sh ──→ /bootstrap ──→ /ideate ──→ /sprint-start ──→ building
                 ▲▲▲▲▲▲▲▲▲▲▲
```

### install.sh

No prerequisites beyond POSIX shell and git. Clones via HTTPS with SSH fallback.
On Windows, `install.ps1` is a thin wrapper that locates Git Bash (bundled with
Git for Windows, which Claude Code on Windows requires) and runs `install.sh`
through it — all install logic lives in one script.

```
./install.sh [--mode=plugin|template] [--components=X] [--force] [--dry-run]
     │
     ├── Verify project root
     │    ├── .git exists? ──→ continue
     │    └── no .git ──→ check package.json, Cargo.toml, etc.
     │         └── nothing found ──→ WARN (may not be a project root)
     │
     ├── Determine mode
     │    │
     │    ├── --mode=plugin ───────────────────────┐
     │    │   PLUGIN MODE                          │
     │    │   Copy scaffold only:                  │
     │    │   ├── docs/ (templates)                │
     │    │   ├── vision/ (braindump)              │
     │    │   ├── CLAUDE.md                        │
     │    │   ├── scripts/pm/                      │
     │    │   └── .github/ (CI, templates)         │
     │    │   Core from plugin: $CLAUDE_PLUGIN_ROOT│
     │    │                                        │
     │    └── (default) ───────────────────────────┤
     │        TEMPLATE MODE                        │
     │        Copy everything:                     │
     │        ├── .claude/ (skills, hooks, rules,  │
     │        │    agents, prompts, settings)      │
     │        ├── docs/ (templates)                │
     │        ├── vision/ (braindump)              │
     │        ├── scripts/pm/                      │
     │        ├── CLAUDE.md                        │
     │        ├── llms.txt                         │
     │        └── .github/ (CI, templates)         │
     │                                             │
     ├── --force? → remove existing framework files first (clean reinstall)
     ├── --dry-run? → preview what would be copied, no changes
     ├── --components=X → selective .claude/ install (auto-detected from structure)
     ├── cp -rn (no clobber — never overwrite unless --force) ◄───┘
     │
     ├── Create AGENTS.md → CLAUDE.md symlink
     │
     ├── Update .gitignore
     │    ├── CLAUDE.local.md
     │    ├── settings.local.json
     │    └── session handoff files
     │
     └── Print summary + next step: run /quickstart (or /bootstrap for direct setup)
```

### Template vs Plugin Mode

```
┌─────────────────────┬────────────────────────┬────────────────────────┐
│                     │ TEMPLATE MODE          │ PLUGIN MODE            │
│                     │ (default)              │ (--mode=plugin)        │
├─────────────────────┼────────────────────────┼────────────────────────┤
│ Core framework      │ Copied into project    │ Provided by plugin     │
│ (.claude/)          │ repo as regular files  │ via $CLAUDE_PLUGIN_ROOT│
├─────────────────────┼────────────────────────┼────────────────────────┤
│ Path resolution     │ git rev-parse          │ $CLAUDE_PLUGIN_ROOT    │
│                     │ --show-toplevel        │ resolved at runtime    │
│                     │ resolved at runtime    │                        │
├─────────────────────┼────────────────────────┼────────────────────────┤
│ Hook registration   │ settings.json          │ hooks.json             │
│                     │ (git rev-parse prefix) │ (${CLAUDE_PLUGIN_ROOT})│
├─────────────────────┼────────────────────────┼────────────────────────┤
│ Updates             │ Manual (re-copy files) │ Plugin auto-update     │
├─────────────────────┼────────────────────────┼────────────────────────┤
│ Multi-project       │ One copy per project   │ Shared core, per-      │
│                     │                        │ project scaffold       │
├─────────────────────┼────────────────────────┼────────────────────────┤
│ Customization       │ Edit directly          │ Override via           │
│                     │                        │ settings.local.json    │
└─────────────────────┴────────────────────────┴────────────────────────┘
```

### Path Resolution

The `lib/paths.sh` library provides portable path resolution across both modes:

- **Template mode:** Each hook command in `settings.json` is prefixed with `cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"` — dynamically resolving the project root at runtime regardless of CWD. No install-time path replacement needed.
- **Plugin mode:** `hooks.json` uses `${CLAUDE_PLUGIN_ROOT}` resolved at runtime by Claude Code

**After installation, run `/quickstart` for a guided tour, or `/bootstrap` to configure directly.**

---

## 5. Flow: Bootstrap & Project Setup

### Overview

```
install.sh ──→ /bootstrap ──→ /ideate ──→ /sprint-start ──→ building
               ▲▲▲▲▲▲▲▲▲▲▲
```

Bootstrap detects your project state and configures everything:

```
/bootstrap
     │
     ▼
Step 0: Detect Installation Mode
     ├──→ Plugin mode (CLAUDE_PLUGIN_ROOT set) → core via plugin
     └──→ Template mode (default) → full framework in project
     │
     ▼
Step 0.5: README Management
     ├──→ framework README detected? → rename to FRAMEWORK_README.md
     ├──→ scaffold template? → leave for A4.2 / Phase 7D to populate
     ├──→ real project README? → preserve unchanged
     └──→ no README? → will be generated in A4.2 / Phase 7D
     │
     ▼
Step 1: Detect Project State
     ├──→ Source files exist? ──→ Path A (Existing Repository)
     └──→ No source files?   ──→ Path B (New Project)
```

### Path A — Existing Repository

```
A1-A2.6: Detect Stack & Measure
     ├──→ run detect-stack.sh (languages, frameworks, tools)
     ├──→ detect commands (test, lint, format, build, typecheck)
     ├──→ assess documentation state + architecture
     ├──→ measure test coverage baseline
     └──→ measure codebase (LOC, files, complexity)
     │
     ▼
A2.8-A2.85: Assess Tooling Readiness
     ├──→ type checking readiness (per-stack type checker detection)
     └──→ quality tooling offer (missing formatter/linter/coverage/
          typechecker with install commands → user selects → install)
     │
     ▼
A2.9: Stack Best Practices Research (optional)
     └──→ quick-depth web research on current best practices
          for detected stack → feeds into readiness report
     │
     ▼
A3-A3.2: Assess Codebase Quality
     ├──→ LLM-readiness (file size, fan-out, circular deps)
     └──→ technical debt assessment → docs/technical-debt.md
     │
     ▼
A3.5-A3.6: Generate Core Documentation
     ├──→ ARCHITECTURE.md (module structure derived from code)
     ├──→ docs/context/* (6 knowledge base files from codebase analysis)
     └──→ GROUND_RULES.md (ask user for 3-7 architectural principles)
     │
     ▼
A3.8: Profile Detection
     ├──→ analyze project characteristics (compliance refs, CI, LOC, tests)
     ├──→ recommend lean / standard / strict
     │       ├── Strict: 2+ indicators (HIPAA/SOC2/PCI, multi-service, k8s)
     │       ├── Standard: CI configured, test framework, >5K LOC (default)
     │       └── Lean: no CI, no tests, <2K LOC, no deployment config
     ├──→ user confirms or overrides profile choice
     └──→ lean profile: skip A3.1-A3.5c, A5-A5.9 (minimal bootstrap)
     │
     ▼
A4-A4.5: Generate Configuration
     ├──→ CLAUDE.md (project overview, commands, architecture one-liner)
     ├──→ README.md (generate from detected info, or review existing for gaps)
     ├──→ CODING_STANDARDS.md (language-specific conventions)
     ├──→ TESTING_STRATEGY.md (test infrastructure from detected stack)
     ├──→ progress.md (baseline metrics)
     ├──→ detect default branch
     └──→ detect MCP servers (optional)
     │
     ▼
A5-A5.6: Configure Framework
     ├──→ /skill-create: scan repo → generate technology-specific skills
     ├──→ configure hooks (formatter, linter, safety for detected stack)
     ├──→ configure rules (path-scoped for detected file types)
     └──→ initialize BACKLOG_INDEX.md from template
     │
     ▼
A5.65-A5.7: Assess Infrastructure Readiness
     ├──→ pre-commit hook readiness (detect pre-commit/husky/lint-staged)
     ├──→ CI/CD foundation assessment (detect GitHub Actions → offer workflow)
     └──→ document quality check (Explore sub-agent reviews ARCHITECTURE.md)
     │
     ▼
A5.8-A5.9: Readiness Report & Foundation Backlog
     ├──→ Framework Readiness Report: 15-principle assessment
     │       → save to READINESS_REPORT.md (baseline for /doctor)
     └──→ foundation backlog: auto-generate E00-foundation stories
          from Risk/Missing items → user reviews → E00-foundation.md
     │
     ▼
A6-A7: Clean Up & Present Summary
     ├──→ remove vision/, scaffold/, template placeholders, empty sections
     └──→ present: detected stack, commands, hooks, generated skills,
          readiness report, foundation stories, README status, next steps
```

**Readiness Report Example:**

```
Principle              Status    Evidence
─────────────────────  ────────  ─────────────────────────────
TDD-first              ✓ Ready   pytest detected, 127 tests, coverage 72%
Sprint-based           ✓ Ready   Git repo, clean state
Git-disciplined        ✓ Ready   main branch, remote configured
Verification-driven    ✓ Ready   Test command works and passing
CI-enforced            ✗ Missing No GitHub Actions workflow
Secrets-aware          ✓ Ready   Hook active, .env gitignored
Anti-slop              ✓ Ready   code-slop.md rule exists
Quality gates          ⚠️ Risk   Formatter + linter OK, no type checker
Context-efficient      ✓ Ready   No oversized files, low coupling
Documentation-lean     ✓ Ready   Core docs generated
Pre-commit hooks       ⚠️ Risk   No pre-commit framework detected
Type-safe              ✗ Missing No type checker configured
Contract-first         ⚠️ Risk   API endpoints detected but no spec file
API-documented         ✗ Missing API_DOCUMENTATION.md empty
Decisions-documented   ─ N/A     Skip (existing project, no ADRs yet)
                                  │
                                  ▼
                       Foundation stories generated:
                       E00-001: Configure GitHub Actions CI
                       E00-002: Add type checking (mypy)
                       E00-003: Configure pre-commit hooks
                       E00-004: Create OpenAPI spec for API endpoints
                       E00-005: Populate API documentation
```

### Path B — New Project (Deep Guided Elicitation via /discover)

```
Phase 0: Idea Capture (bootstrap)
     ├──→ vision/ has files?  ──→ load existing braindump
     ├──→ vision/ empty?      ──→ 3 entry options:
     │       ├── Option 1: describe idea inline → capture to vision/
     │       ├── Option 2: import vision files (from Claude Projects research)
     │       └── Option 3: fast-track (minimal questions, auto-pick defaults)
     └──→ assess completeness → save to vision/idea-capture.md
     │
     ▼
/discover (replaces legacy Phases 1-4 — deep guided elicitation)
     │
     ├──→ Phase 1: Classification
     │       ├── Axis 1: Archetype selection (recognition-based, 10+1 types)
     │       │     Utility | Experiential | Viral | Educational | Creative
     │       │     Personal | DevTool | Dashboard | Marketplace | Automation
     │       │     + Uncategorized/Hybrid
     │       ├── Sub-variant confirmation via analogy
     │       ├── Hybrid check (primary + secondary archetype)
     │       ├── Axis 2: Scale classification
     │       │     Quick Build | Standard | Platform | Pioneering
     │       ├── 5 universal context questions (scaffolded)
     │       └── Mode selection → save to vision/classification.md
     │
     ├──→ Phase 2: Core Identity (archetype-specific)
     │       ├── load archetype question bank from references/archetypes/
     │       ├── 5-10 scaffolded questions (scale-adapted count)
     │       ├── platform additions: stakeholders, compliance, NFRs
     │       ├── 🔍 Research Checkpoint 1: landscape scan
     │       └── *** HARD GATE: "Does this change anything?" ***
     │
     ├──→ Phase 3: Deep Elicitation (archetype-specific)
     │       ├── full question bank → workflow/experience description
     │       ├── feature map extracted from experience → MUST/IMPORTANT/NICE/CUT
     │       ├── 🔍 Research Checkpoint 2: feature-level best practices
     │       ├── edge case exploration (6 dimensions: Boundaries/Errors/Users/
     │       │     States/Scale/Time)
     │       ├── 🔍 Research Checkpoint 3: UX/interaction patterns
     │       └── platform additions: domain modeling, multi-user journeys
     │
     ├──→ Phase 4: Assumption Surfacing & Stress Testing
     │       ├── LLM generates assumptions FROM Phases 2-3 → user rates each
     │       │     (Desirability/Feasibility/Viability/Usability)
     │       ├── 🔍 Research Checkpoint 4: assumption validation
     │       ├── pre-mortem with archetype-specific failure scenarios
     │       ├── No-Gos declaration → *** HARD GATE: user approves ***
     │       └── save to ASSUMPTION_REGISTER.md + vision/stress-test.md
     │
     ├──→ Phase 5: Dimension Completeness Sweep
     │       ├── load DECISION_LOG → skip items decided in Phases 2-4
     │       ├── run through D04-D10 (scale-adapted depth)
     │       │     Quick Build: confirm defaults | Standard: 2-3 options
     │       │     Platform: full treatment + ADRs | Pioneering: defer
     │       ├── archetype-specific additions per dimension
     │       ├── 🔍 Research Checkpoint 5: stack + architecture
     │       ├── cross-dimension constraint check
     │       └── external dependency summary (conditional)
     │             if any choices need accounts/API keys/external setup:
     │             compile list → present setup requirements → confirm/revise
     │             → save to vision/external-dependencies.md
     │             (skip entirely if all choices are self-hosted/local)
     │
     ├──→ Phase 6: Vision Synthesis
     │       ├── Shape Up pitch: Problem, Appetite, Solution, Rabbit Holes, No-Gos
     │       ├── highlight ASSUMED + SPECULATIVE decisions
     │       └── *** HARD GATE: user approves full vision ***
     │
     └──→ Phase 7: MVP Scoping & Backlog Generation
            ├── feature selection → archetype-specific success criteria
            ├── external service setup stories (from vision/external-dependencies.md)
            │     infra story per service, ordered before dependent features
            ├── scale-adapted epic structure:
            │     Quick Build: E01 Core + E02-REVIEW (3 stories)
            │     Standard: E01-E03 + E04-REVIEW (6 stories)
            │     Platform: E01-E06 + E07-REVIEW (7 stories)
            │     Pioneering: E01 Spikes + E02-REVIEW
            ├── *** LAST EPIC IS ALWAYS PHASE TRANSITION ***
            │     → creates infinite build→review→discover→build cycle
            ├── *** HARD GATE: user approves stories ***
            └── generate: PRD, BACKLOG_INDEX, DECISION_LOG, ASSUMPTION_REGISTER
     │
     ├──→ Phase 7D: Populate Project Documentation (MANDATORY)
     │       ├── docs/context/* (6 files) populated from vision/ + decisions
     │       │     project-overview, product-context, tech-context,
     │       │     system-patterns, project-structure, error-patterns
     │       ├── README.md (project README from discovery decisions)
     │       ├── ARCHITECTURE.md populated from tech decisions
     │       ├── CODING_STANDARDS.md populated from stack choices
     │       ├── GROUND_RULES.md populated with No-Gos + constraints
     │       ├── TESTING_STRATEGY.md populated with archetype testing approach
     │       └── CLAUDE.md filled (overview, stack, commands, architecture)
     │       Scale-adapted: Quick Build = CLAUDE.md + README.md + GROUND_RULES.md only
     │
     ▼
Post-discovery (bootstrap continues)
     ├──→ .gitignore with stack-specific patterns
     ├──→ create empty dirs (research/, solutions/, brainstorms/, reviews/)
     ├──→ delete scaffold/ if present (template-mode artifact)
     └──→ present summary → /sprint-start
```

**Four discovery modes** adapt depth to project scale:

| Mode | Scale | Time | Phases |
|---|---|---|---|
| **Quick Start** | Quick Build, or `--quick` | ~5 min | Classification + 3-5 Qs + 1 research + auto-pick + ext-dep notice |
| **Guided** (default) | Standard | 20-45 min | All 7 phases |
| **Platform** | Platform, or `--platform` | 60-120 min | All phases + stakeholders, compliance, ADRs |
| **Pioneering** | Pioneering, or `--pioneer` | Variable | Core identity + deep research → spikes first |

**11 archetype question banks** ensure each project type gets relevant questions:

| Archetype | Core Question | Tailored For |
|---|---|---|
| Utility/Productivity | "What task does this make easier?" | CRM, expense tracker, booking system |
| Experiential/Entertainment | "What should someone FEEL?" | Games, interactive art, simulations |
| Viral/Shareable | "What makes someone share this?" | Wordle, quizzes, data visualizers |
| Educational/Explanatory | "What should someone understand after?" | Data essays, interactive courses |
| Creative Expression | "What can people MAKE?" | Design tools, level editors |
| Personal/Hobby | "What annoys YOU about how you do this?" | Personal tools, automations |
| Developer Tool/Library | "What workflow pain for devs?" | CLIs, SDKs, testing frameworks |
| Data & Analytics | "What decision should this inform?" | Dashboards, monitoring, admin panels |
| Marketplace/Platform | "What two sides are you connecting?" | Two-sided platforms |
| Automation/Integration | "What manual process does this eliminate?" | Workflow automation, RPA |
| Uncategorized/Hybrid | "Tell me more and I'll help classify" | Novel concepts |

**Persistent tracking artifacts:**

| Artifact | Purpose | Written By | Read By |
|---|---|---|---|
| `docs/reference/DECISION_LOG.md` | Every decision with confidence + rationale | `/discover` | `/story-cycle`, `/sprint-end`, `/phase-review` |
| `docs/reference/ASSUMPTION_REGISTER.md` | Every assumption with validation plan | `/discover` | `/story-cycle`, `/phase-review` |
| `vision/project-pitch.md` | Shape Up pitch with No-Gos | `/discover` | `/ideate`, `/story-cycle` |
| `vision/external-dependencies.md` | External service list with setup requirements | `/discover` Phase 5 | `/ideate` (setup story generation) |
| `docs/reviews/phase-N-*.md` | Phase transition review outputs | `/phase-review` | Next `/discover` cycle |

### What Bootstrap Produces (Both Paths)

| Output | Path A (Existing) | Path B (New) |
|---|---|---|
| README.md | Generated from detected info (or existing preserved with gap analysis) | Generated from discovery decisions |
| FRAMEWORK_README.md | Framework README renamed (if present) | Framework README renamed (if present) |
| CLAUDE.md | Filled from detected stack | Filled from vision decisions |
| ARCHITECTURE.md | Derived from existing code | Proposed from vision synthesis |
| docs/context/* (6 files) | Analyzed from codebase | Generated from vision |
| CODING_STANDARDS.md | Language-specific from detection | Populated by /discover Phase 7D from stack decisions |
| TESTING_STRATEGY.md | Test infrastructure populated | Populated by /discover Phase 7D with archetype testing strategy |
| GROUND_RULES.md | User-provided principles | Populated by /discover Phase 7D (No-Gos + architectural constraints) |
| progress.md | Baseline metrics | Initialized empty |
| technical-debt.md | Populated from assessment | Empty |
| READINESS_REPORT.md | 15-principle assessment | Not generated |
| E00-foundation.md | From readiness gaps | Not generated |
| DECISION_LOG.md | Not generated | Generated by /discover (every decision tracked) |
| ASSUMPTION_REGISTER.md | Not generated | Generated by /discover Phase 4 |
| PRD_SUMMARY.md | Not generated | Generated by /discover Phase 7 |
| BACKLOG_INDEX.md | Initialized from template | Generated with scale-adapted epics by /discover |
| vision/*.md | Not generated | classification, core-identity, deep-elicitation, stress-test, project-pitch, external-dependencies (conditional) |
| docs/reviews/*.md | Not generated | Generated by /phase-review after first phase |
| Technology skills | Generated via /skill-create | If stack decided during dimension sweep |
| Hook configuration | Configured for detected tools | Default configuration |

**Graceful degradation:** If a package manager, formatter, or test runner isn't detected, bootstrap skips the dependent step and notes it in the summary rather than failing.

**What fires during bootstrap:** `SessionStart` hook (environment checks), `PostToolUse` hook (activity logging), `documentation` rule (when generating docs), Explore sub-agent (document quality review).

**After bootstrap:** For existing repos, use `/ideate` or `/brainstorm` to fill your backlog. For new projects, `/discover` (invoked by bootstrap Path B) already generated the backlog — proceed to `/sprint-start`.

---

## 6. Flow: Planning & Backlog Creation

### Overview

```
install.sh ──→ /bootstrap ──→ /discover ──→ /ideate ──→ /sprint-start ──→ building
                              ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
```

Three paths to fill your backlog — deep discovery, direct decomposition, or design exploration first:

```
New project idea                   After first phase built
     │                                  │
     ▼                                  ▼
  /discover                        /phase-review
     │                                  │
     ├──→ classify archetype + scale    ├──→ feature walkthrough with user
     ├──→ deep elicitation (7 phases)   ├──→ validate assumptions
     ├──→ research checkpoints (6)      ├──→ research refresh
     ├──→ assumption tracking           ├──→ pivot or persevere decision
     ├──→ dimension sweep (D04-D10)     ├──→ next phase elicitation
     ├──→ vision synthesis + approval   ├──→ next phase backlog generation
     └──→ MVP scoping + backlog         │     (last epic = Phase Transition again)
          with Phase Transition Stories  └──→ invoke /ideate for new stories
     │
     ▼
```

```
Simple idea                        Complex idea
     │                                  │
     ▼                                  ▼
  /ideate                          /brainstorm
     │                                  │
     │                                  ├──→ explore problem space (PRD context if available)
     │                                  ├──→ research codebase + system-patterns + ADR constraints
     │                                  ├──→ research alternatives (web, STANDARD depth)
     │                                  ├──→ propose 2-3 approaches with Pattern Fit scoring
     │                                  ├──→ identify risks + STRIDE-Light threat analysis
     │                                  ├──→ *** HARD GATE: user approves design ***
     │                                  ├──→ save to docs/brainstorms/<topic-slug>.md
     │                                  ├──→ create ADR if architecturally significant
     │                                  │
     │◄─────────────────────────────────┘ (suggests /ideate after approval)
     │
     ├──→ check docs/brainstorms/ for prior designs
     ├──→ research codebase + PRD context (requirements, scope, NFRs)
     ├──→ feasibility research (if unfamiliar tech, QUICK depth)
     ├──→ decompose via SPIDR splitting (Paths/Data/Rules/Interface/Spike)
     │       each story: one coherent unit, vertical slice (cohesion, not file count)
     ├──→ classify: Feature / Bug Fix / Refactoring / Spike / Infra /
     │    Testing / Documentation / Security / Performance / Skill
     ├──→ auto-append security AC for auth/data/API stories
     ├──→ generate NFR stories from PRD (observability, accessibility, etc.)
     ├──→ order for testability (testing infra → foundation → features → quality)
     ├──→ validate Definition of Ready (title, type, size, 3-7 AC, verification)
     ├──→ identify missing skills → /skill-create if needed
     ├──→ *** HARD GATE: user approves stories ***
     │
     ▼
Stories written to docs/reference/backlog/Exx-name.md
BACKLOG_INDEX.md updated
```

### /research — Deep Online Research

Available standalone or composed into other skills:

```
/research "compare SQLAlchemy vs Tortoise ORM for async Python APIs"
     │
     ▼
Phase 1: Clarification Gate
     │  └── vague query? → ask 1-2 focused questions
     ▼
Phase 2: Check Prior Research
     │  └── search docs/research/, docs/solutions/, docs/brainstorms/
     ▼
Phase 3: Plan Research
     │  ├── classify depth (quick/standard/deep)
     │  ├── decompose into sub-questions
     │  └── *** HARD GATE: user approves plan ***
     ▼
Phase 4: Execute Research
     │  ├── QUICK: inline search (no subagents)
     │  └── STANDARD/DEEP: parallel subagent dispatch
     │       ├── Agent 1: sub-question 1 → reflection
     │       ├── Agent 2: sub-question 2 → reflection
     │       └── Agent 3: sub-question 3 → reflection
     ▼
Phase 5: Synthesize & Evaluate
     │  ├── merge reflections, resolve contradictions
     │  ├── assess confidence (weighted average)
     │  └── if below threshold → ask user to deepen
     ▼
Phase 6: Output & Persist
     │  └── save to docs/research/<topic-slug>.md
     ▼
Phase 7: Cross-Reference
     └── check backlog and solutions for impact
```

**Three depth modes:**

| Depth | Sub-Qs | Searches | Iteration | Typical Time |
|-------|--------|----------|-----------|--------------|
| Quick | 1-2 | 2-3/sub-Q | None | ~30s |
| Standard | 3-4 | 5-8/sub-Q | 1 round | ~2-3 min |
| Deep | 4-6 | 10-15/sub-Q | 2-3 rounds | ~5-10 min |

### /skill-create — Technology-Specific Skills

Called by `/bootstrap` and available standalone:

1. Scan repository (dependency files, imports, existing skills)
2. Classify technologies: Core Framework → full skill, Major Library → focused skill, Build Tool → rule only, Minor → skip
3. Generate skills, rules, and hook configs for detected stack
4. Update skills registry and inventory

**After planning, start building with `/sprint-start`.**

---

## 7. Flow: Building — The Sprint Lifecycle

### Overview

```
install.sh ──→ /bootstrap ──→ /ideate ──→ /sprint-start ──→ building
                                          ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
```

### Full Lifecycle

```
TIME ──────────────────────────────────────────────────────────────────────►

 Sprint N                                              Sprint N+1
 ┌─────────────────────────────────────────────┐      ┌──────────
 │                                             │      │
 │  /sprint-start                              │      │  /sprint-start
 │  ├── verify clean state                     │      │  ├── ...
 │  ├── pull latest main                       │      │
 │  └── create sprint-N branch                 │      │
 │       │                                     │      │
 │       ├── /story-cycle "story A" ──→ commit │      │
 │       │    (Phase 0→1→2→2.5→3→3.5→4→4.5)    │      │
 │       │                                     │      │
 │       ├── /story-cycle "story B" ──→ commit │      │
 │       │                                     │      │
 │       ├── /manual-test ──→ /testing-cycle   │      │
 │       │    (optional: find + fix bugs)      │      │
 │       │                                     │      │
 │       └── /sprint-end                       │      │
 │            ├── quality gates (test, lint)   │      │
 │            ├── test count protection        │      │
 │            ├── quality agents (parallel)    │      │
 │            ├── ground rules check           │      │
 │            ├── push + PR                    │      │
 │            ├── CI review                    │      │
 │            ├── squash merge to main         │      │
 │            └── branch cleanup               │      │
 └─────────────────────────────────────────────┘      └──────────

 Session boundaries (within a sprint):
 ···· Session 1 ────│···· Session 2 ────│···· Session 3 ····
     /story-cycle    │    /story-cycle    │    /story-cycle
     /story-cycle    │    /story-cycle    │    ...
     (stop)         │    (stop)         │    (stop)
                    │                   │
                    [Stop hook:         [Stop hook:
                     auto-save]          auto-save]
```

### What Each Step Triggers

| Step | Skill | Hooks | Rules | Agents | Docs Written |
|---|---|---|---|---|---|
| Branch | `/sprint-start` | PreToolUse (git) | git | — | — |
| Deliver | `/story-cycle` | PreToolUse (safety, read-check), PostToolUse (format, secrets, log), PostToolUseFailure (recovery), PreCompact (state), Stop (quality) | testing, security, code-slop, verification, dependencies, edit-recovery | codebase-explorer, integration-tester (strict), code-quality, test-validator, security-audit | plans/*, .failure-state.md |
| Ship | `/sprint-end` | PreToolUse (git push), UserPromptSubmit (skill suggestion) | git, documentation | code-quality, test-validator, security-audit, architecture-check, performance-check | progress.md, BACKLOG_INDEX.md, PR |

### 7.1 Sprint Start

```
/sprint-start [branch-name] [--worktree]
     │
     ├──→ Profile check (lean: skip 1.5, 1.6, step 3; strict: all mandatory)
     │
     ├──→ 1. Pre-flight checks
     │       ├── 1a. check for open PRs (merge approved ones)
     │       ├── 1b. verify clean working tree
     │       ├── 1c. ensure on default branch and up to date
     │       └── 1d. run tests on default branch (must pass before branching)
     │
     ├──→ 1.5. Metrics Health Check (read progress.md)
     │       └── surface quality signals: cycle time ↑, churn 🟡, coverage declining
     │
     ├──→ 1.6. Debt Health Check (read technical-debt.md)
     │       └── flag critical/growing debt items as sprint candidates
     │
     ├──→ 2. Create sprint-<N> branch
     │       ├── standard: git checkout -b sprint-N
     │       ├── worktree: git worktree add ../<project>-sprint-N
     │       └── optional: draft PR for early CI feedback
     │
     └──→ 3. Sprint Planning
            ├── show ready stories from backlog (grouped by priority)
            ├── define sprint goal (one sentence outcome)
            ├── select stories + estimate capacity (S=1, M=2, L=4 sessions)
            ├── PRD integration (if exists): NFRs as sprint DoD, scope boundaries
            └── create sprint spec (docs/sprints/sprint-N.md)
```

### 7.2 Story Delivery — /story-cycle

The framework's most comprehensive skill. Adapts workflow depth to story size and risk.

#### Story Size Adaptation

```
User: /story-cycle "<description>"
     │
     ▼
Phase 0: Classify size + risk
     │
     ├── TRIVIAL + low risk ─────────────────────────────────┐
     │   (rename, typo, config tweak)                        │
     │   Skip Phase 1, 2, 2.5 entirely                       │
     │   ▼                                                   │
     │   Phase 3 → 3.5 → 4 → 4.5                             │
     │   (implement → self-review → wrap → verify)           │
     │                                                       │
     ├── SMALL ──────────────────────────────────────────────┤
     │   (single function, isolated change)                  │
     │   Phase 1 lightweight:                                │
     │     ✓ pre-flight checks                               │
     │     ✓ context-prime                                   │
     │     ✓ grep-first only (no agents)                     │
     │     ✗ skip clarification check (1f)                   │
     │     ✗ skip plan completeness (1g)                     │
     │     ✓ plan approval HARD GATE                         │
     │   ▼                                                   │
     │   Phase 2 → 2.5 (readiness gate) → 3 → 3.5 → 4 → 4.5  │
     │   (all gates enforced)                                │
     │                                                       │
     ├── STANDARD ───────────────────────────────────────────┤
     │   (multi-file, needs planning)                        │
     │   Full Phase 1:                                       │
     │     ✓ all checks + agents                             │
     │     ✓ grep-first + codebase-explorer agents           │
     │     ✓ discovery gate + clarification                  │
     │     ✓ plan completeness check                         │
     │   ▼                                                   │
     │   Phase 1 → 2 → 2.5 (readiness) → 3a? → 3 → 3.5 → 4 → 4.5│
     │   (parallel streams optional)                         │
     │                                                       │
     └── ANY + high risk ────────────────────────────────────┘
         (security, auth, data migration)
         Size path + extra gates:
           ✓ security-focused grep stream
           ✓ research decision gate → always research
           ✓ ground rules compliance
```

#### Phase-by-Phase Flow

```
Phase 0: Intent Decomposition
     │  ├──→ context-prime loads docs/context/* (intent-aware priority)
     │  ├──→ backlog story lookup (if ID provided) + dependency check
     │  ├──→ sprint context load (if on sprint branch: goal, boundaries, capacity)
     │  ├──→ PRD scope guard (if PRD_SUMMARY.md exists: non-goals, boundaries)
     │  ├──→ discovery context loading:
     │  │       ├── DECISION_LOG.md → use logged decisions, don't re-decide
     │  │       ├── ASSUMPTION_REGISTER.md → track validation, flag invalidations
     │  │       └── No-Gos → stop if scope creeps toward documented No-Go
     │  ├──→ scope analysis: list ALL deliverables, flag compound requests
     │  ├──→ classify size: TRIVIAL / SMALL / STANDARD
     │  ├──→ classify risk: low / medium / high (domain, integration, reversibility)
     │  └──→ TRIVIAL + low risk? ──yes──→ skip to Phase 3 (fast-track)
     │
     ▼
Phase 1: Story Analysis (Plan Mode)
     │  ├──→ pre-flight: discover-commands + verify-clean-git-state
     │  ├──→ context-prime loads docs/context/* (intent-aware)
     │  ├──→ identify story type
     │  ├──→ grep-first codebase exploration (depth scales with size)
     │  │       + check docs/solutions/ for prior learnings
     │  │       + check system-patterns.md for applicable conventions/recipes
     │  ├──→ Research Decision Gate (see below)
     │  ├──→ Dependency Freshness Check (always-on for external deps)
     │  ├──→ Discovery Gate: ambiguity check → clarifying questions if needed
     │  ├──→ write plan (WHAT/HOW separation)
     │  ├──→ clarification scan + plan completeness check
     │  ├──→ ground rules check (if GROUND_RULES.md exists)
     │  └──→ *** HARD GATE: wait for user plan approval ***
     │
     ▼
Phase 2: Context Transition
     │  └──→ keep insights + plan, discard bulk exploration content
     │
     ▼
Phase 2.5: Readiness Gate (Objective Pre-Conditions)
     │  ├──→ 5 objective PASS/FAIL checks (see below)
     │  ├──→ all PASS → proceed
     │  ├──→ any FAIL → address specific gap
     │  └──→ user can override with acknowledgement
     │
     ▼
Phase 3a (optional): Parallel Stream Decomposition
     │  └──→ STANDARD stories with non-overlapping scopes → parallel worktrees
     │
     ▼
Phase 3: Implementation (by story type)
     │  ├──→ Feature:    RED → GREEN → REFACTOR (TDD)
     │  ├──→ Bug Fix:    Reproduce → Test → Fix → Verify
     │  ├──→ Refactor:   Characterization tests → Refactor → Verify
     │  ├──→ Spike:      Explore → Document → Decide
     │  ├──→ Infra:      Plan → Implement → Smoke Test
     │  ├──→ Testing:    Design → Generate → Validate
     │  ├──→ Docs:       Gather → Generate → Review
     │  ├──→ Security:   Threat model → Implement → Audit
     │  ├──→ Perf:       Baseline → Optimize → Benchmark
     │  ├──→ Skill:      Design → Build → Document
     │  └──→ Review:     Walkthrough → Document → Decide (Phase Transition)
     │
     │  [During implementation:]
     │  [  PostToolUse hooks auto-format + scan secrets on every edit  ]
     │  [  Rules auto-load: testing, security, code-slop, dependencies]
     │  [  Failure state persisted at each phase transition            ]
     │
     ▼
Phase 3.5: Self-Review
     │  ├──→ self-review checklist + pattern alignment check (vs system-patterns.md)
     │  ├──→ adversarial disaster prevention analysis
     │  └──→ misdiagnoses/rework? ──→ record-failure → error-patterns.md
     │
     ▼
Phase 4: Wrap Up
     │  ├──→ run quality-gate-sequence (lint → typecheck → test)
     │  ├──→ update docs if needed (including writing UAT test cases)
     │  ├──→ capture-learnings → docs/solutions/ (if non-obvious patterns)
     │  ├──→ capture-outcome → .story-outcomes.tsv (code delta, tests, coverage)
     │  └──→ conventional commit
     │
     ▼
Phase 4.5: Completion Verification
     └──→ re-check ALL acceptance criteria with evidence
          ├──→ each criterion: [PASS file:line] or [FAIL reason]
          └──→ four-question protocol
```

#### Story Type Implementation Patterns

```
Feature (TDD):
  ┌─────┐     ┌─────────┐     ┌──────────┐
  │ RED │────→│  GREEN  │────→│ REFACTOR │──┐
  │write│     │implement│     │clean up  │  │
  │test │     │minimal  │     │patterns  │  │
  │first│     │to pass  │     │          │  │
  └─────┘     └─────────┘     └──────────┘  │
     ▲                                      │
     └──────── next test case ──────────────┘

Bug Fix:
  Reproduce ──→ Write failing test ──→ Fix ──→ Verify all tests pass
     │
     └── HARD GATE: must reproduce before fixing

Refactoring:
  Write characterization tests ──→ Refactor ──→ Verify tests still pass

Security:
  Threat model ──→ Implement mitigations ──→ /security-audit

Performance:
  Baseline metrics ──→ Optimize ──→ Benchmark ──→ compare
```

#### Research Decision Gate (Phase 1c.5)

```
Signal 1: Risk Level        Signal 2: Local Context    Signal 3: Uncertainty
├── high (security,         ├── strong (patterns       ├── high (new API,
│   new APIs, auth)         │   well-established,      │   unfamiliar domain)
│   → RESEARCH              │   good docs/solutions)   │   → RESEARCH
├── medium                  │   → weight toward SKIP   ├── medium
│   → check other signals   ├── moderate               │   → check other signals
└── low (internal           │   → neutral              └── low (well-understood
    refactoring)            └── weak (new area,            change pattern)
    → weight toward SKIP        no prior learnings)        → weight toward SKIP
                                → weight toward RESEARCH

Decision:
├── ANY signal = high ─────────────→ RESEARCH (deep-research engine)
├── ALL signals = low ─────────────→ SKIP (note reason transparently)
└── Mixed ─────────────────────────→ evaluate: 2+ toward research = RESEARCH
```

#### Readiness Gate — Objective Pre-Conditions (Phase 2.5)

```
Readiness Gate (5 PASS/FAIL checks — all must pass to proceed)
════════════════════════════════════════════════════════════════

  Check                             Evidence Required
  ──────────────────────────────    ─────────────────────────────────────
  1. Files Read                     Every file the plan touches has been
                                    read (at least relevant sections)
  2. Tests Baseline                 Test command run this session with
                                    passing output (skip if no test cmd)
  3. Pattern Match                  Plan references existing code as
                                    pattern source (skip for greenfield)
  4. Scope Bounded                  ≤5 files: PASS; 6-10: advisory;
                                    >10: requires explicit user approval
  5. No Conflicts                   Zero GROUND_RULES.md or ADR conflicts

  Example output:
  ┌─────────────────────────────────────────────────────────────────┐
  │  Readiness Gate:                                                │
  │    [✓] Files read: 4/4 planned files examined                   │
  │    [✓] Tests baseline: 23 passing (from test run at turn 12)    │
  │    [✓] Pattern match: following pattern in src/auth/middleware   │
  │    [✗] Scope bounded: plan touches 8 files — advisory noted     │
  │    [✓] No conflicts: 0 ground rule violations                   │
  │                                                                 │
  │  Decision: 4/5 pass — proceed (scope advisory noted)            │
  └─────────────────────────────────────────────────────────────────┘

  Story-type adjustments:
  ├── TRIVIAL → skip gate entirely (fast-track)
  ├── Spike/Research → Check 1 becomes "identified where to look",
  │                    Check 2 skipped
  └── Documentation → Check 2 skipped

  Override: user can acknowledge specific gap to proceed
  (gate is a speed bump, not a wall)
```

**v4.0 change:** Replaced the subjective 5-dimension scoring (0-100) with 5 objective pre-condition checks (PASS/FAIL). The old system relied on self-assessed confidence which is inherently unreliable for LLMs — the new system requires concrete evidence for each check.

#### Context-Prime Intent Loading (Phase 1)

```
Intent Classification → Context Loading Priority
══════════════════════════════════════════════════

Task: "add OAuth login"  →  Intent: Security/Auth

  Loading order (highest priority first):
  ┌───┬──────────────────────┬──────────────────────────────────┐
  │ # │ File                 │ Why prioritized                  │
  ├───┼──────────────────────┼──────────────────────────────────┤
  │ 1 │ system-patterns.md   │ Auth patterns, middleware chain  │
  │ 2 │ tech-context.md      │ Auth stack, session management   │
  │ 3 │ project-overview.md  │ General context                  │
  │ 4 │ project-structure.md │ Where auth code lives            │
  │ 5 │ product-context.md   │ User roles, permissions model    │
  │ 6 │ error-patterns.md    │ Past mistakes (always loaded last)│
  └───┴──────────────────────┴──────────────────────────────────┘

  Intent types and their top-priority files:
  ├── Security/Auth    → system-patterns, tech-context
  ├── UI/Frontend      → product-context, project-structure
  ├── Data/API         → tech-context, API_DOCUMENTATION
  ├── Refactoring      → system-patterns, project-structure
  ├── Research/Spike   → tech-context, system-patterns (+prior research)
  └── New Feature      → product-context, tech-context

  Budget check: if context is >70% full, load only top 3 files
```

### 7.3 Sprint End — Quality Gates & Shipping

```
/sprint-end
     │
     ├──→ Profile check
     │       ├── lean: skip quality agents + docs updates (tests must still pass)
     │       ├── standard: user selects gates (multi-select)
     │       └── strict: /quality-check --all mandatory (no selection)
     │
     ├──→ Step 1: Discover state from git (no assumptions)
     │       ├── discover-commands + verify-clean-git-state
     │       ├── detect default branch
     │       └── check for incomplete story (partial phase → complete during sprint-end)
     │
     ├──→ Step 2: Quality gates
     │       ├── quality-gate-sequence (lint → typecheck → test) *** HARD GATE ***
     │       ├── test-count-delta.sh *** HARD GATE ***
     │       ├── dispatch via /quality-check (profile-aware defaults):
     │       │     standard: /quality-check (code + tests + security)
     │       │     strict:   /quality-check --all (all 5 agents + integration-tester)
     │       │     or user custom selection (--code --security etc.)
     │       ├── ground rules compliance → logged to sprint spec compliance ledger
     │       ├── ADR compliance → flag contradictions
     │       └── 2.5: UAT coverage check (advisory — warn but don't block)
     │
     ├──→ Step 3: Documentation updates
     │       ├── epic files (story status → done) + lifecycle events
     │       ├── BACKLOG_INDEX.md (counts, health, zombie stories)
     │       ├── sprint spec outcome (metrics: throughput, churn, coverage, etc.)
     │       ├── progress.md (metrics, sprint history row, satisfaction rating)
     │       ├── CLAUDE.md Current Focus
     │       ├── docs/context/* (if architecture/patterns changed)
     │       ├── ARCHITECTURE.md (if update triggers hit)
     │       ├── PRD Living Document Review (assumptions, scope creep check)
     │       ├── technical-debt.md (new items, resolved items, AI-origin tracking)
     │       └── SBOM update (informational, if CycloneDX/Syft available)
     │
     ├──→ Step 3.5: Commit documentation artifacts (separate commit)
     │       └── PR size check (warn >400 LOC, offer splitting strategies)
     │
     ├──→ Step 4: Push + PR
     │       ├── git push → gh pr create (uses pull_request_template.md)
     │       └── PR includes: AI-assisted components disclosure, quality gate evidence
     │
     ├──→ Step 5: CI review + Human review
     │       ├── .github/workflows/claude-pr-review.yml runs quality checks
     │       └── if CODEOWNERS: request human reviewers, guide Layer 4 review focus
     │
     ├──→ Step 6: Squash merge (gh pr merge --squash)
     │
     └──→ Step 7: Branch cleanup + worktree prune
```

**Quality Agent Execution Model:**

```
  Main context (sprint-end)
     │
     ├──→ [fork] /code-quality ──→ Explore agent (read-only)
     │         ├── Run project tools (ruff, eslint, clippy...)
     │         ├── AI analysis (complexity, duplication, patterns)
     │         ├── Score each finding 0-100
     │         └── Return only findings ≥80 confidence
     │
     ├──→ [fork] /test-validator ──→ Explore agent (read-only)
     │         └── coverage, TDD compliance, assertion quality
     │
     ├──→ [fork] /security-audit ──→ Explore agent (read-only)
     │         └── findings ≥80 are BLOCKING (must fix)
     │
     ├──→ [fork] /architecture-check ──→ Explore agent (read-only)
     │         └── drift detection + ADR generation
     │
     └──→ [fork] /performance-check ──→ Explore agent (read-only)
              └── N+1 queries, unbounded ops, blocking I/O, memory

  All run in PARALLEL — results merged after all complete
```

---

## 8. Flow: Testing

### Testing Decision Tree

```
What kind of testing work?
     │
     ├── Need a test plan? ────────────→ /manual-test
     │   (before manual testing)
     │
     ├── Found a bug during testing? ──→ /testing-cycle "description"
     │   (ad-hoc exploratory finding)
     │
     ├── Running formal UAT? ──────────→ /UAT-cycle "UAT-001"
     │   (pre-defined test case)
     │
     └── Verify UAT logic vs code? ────→ /claude-sense-check
         (batch automated verification)
```

### Manual Testing Flow

```
/sprint-start
     │
     ▼
/manual-test
     │  ├──→ gather context (recent changes, known issues, UAT coverage)
     │  ├──→ pre-flight: automated tests must pass first
     │  └──→ generate test plan (regression + known issues + exploratory)
     │
     ▼
User performs manual testing
     │
     ▼
/testing-cycle "feedback" ──→ (repeat for each issue found)
     │  ├──→ classify: Bug Critical / Bug Minor / Gap / Test Correction / Enhancement
     │  ├──→ act by type:
     │  │       Bug Critical: investigate → test first → fix → verify → commit
     │  │       Bug Minor: identify → fix → optional test → commit
     │  │       Gap: document → add to backlog → DO NOT implement
     │  │       Test Correction: find test → fix test → possibly fix code
     │  │       Enhancement: trivial → fix + commit / large → log to backlog
     │  └──→ verify: run tests + ask user to verify in app
     │
     ▼
/sprint-end ──→ ships fixes via PR
```

### UAT Testing Flow

```
/UAT-cycle "UAT-001" ──→ (repeat per test case)
     │  ├──→ Phase 1: find test case in docs/testing/UAT_COVERAGE.md
     │  ├──→ Phase 2: guide user through steps, collect Pass/Fail/Blocked/N/A
     │  ├──→ Phase 3: classify failures, act by type (fix / log / note)
     │  ├──→ Phase 4: update UAT_COVERAGE.md with results
     │  └──→ Phase 5: run verification, commit, report
```

### /claude-sense-check — Automated UAT Verification

Batch code logic verification: load UAT coverage → select 2-5 test cases → trace code paths against each criterion → classify (CONFIRMED/MISMATCH/UNTESTABLE/MISSING) → fix mismatches via `/story-cycle` → update tracking → report.

---

## 9. Flow: Session Management

### Session Lifecycle

```
Session Start
     │
     ├──→ [SessionStart hook]
     │       ├── check required tools in PATH
     │       ├── detect stale sessions (old .auto-save.md)
     │       └── verify git state (warn if on main, detached HEAD, etc.)
     │
     ├──→ CLAUDE.md auto-loaded ──→ rules auto-loaded as files are touched
     │
     ▼
  ┌──────────────────┐
  │  First session?  │──yes──→ /quickstart (or /bootstrap)
  │  Resuming work?  │──yes──→ /continue
  │  New sprint?     │──yes──→ /sprint-start
  └──────────────────┘
     │
     ▼
  [ Active work: /story-cycle, /debug-session, /fix-issue, etc. ]
     │
     ├──→ Every edit ──→ [PostToolUse: format, secrets scan, activity log]
     ├──→ Every bash ──→ [PreToolUse: safety check, worktree fix]
     │
     ▼
  ┌────────────────────────────────────────────┐
  │  End session                               │
  │  Option A: /handoff ──→ session file       │
  │  Option B: just stop ──→ [Stop hook]       │
  │            ├──→ auto-save state            │
  │            ├──→ check for incomplete work  │
  │            └──→ check completion evidence  │
  └────────────────────────────────────────────┘
```

### Always-Active Enforcement (During Any Session)

```
Every Bash command:
  [PreToolUse: pre-tool-use.sh]     → block dangerous commands + advisory warnings
  [PreToolUse: worktree-bash-fix.sh] → inject cd if in worktree

Every Read:
  [PreToolUse: pre-read-check.sh]   → warn when reading sensitive files (.env, keys, credentials)

Every Edit:
  [PostToolUse: post-edit-format.sh] → auto-format + linter + secrets scan
  [PostToolUse: post-tool-use.sh]    → log to activity-log.jsonl

Every user prompt:
  [UserPromptSubmit: user-prompt.sh] → warn about destructive requests + suggest relevant skills

Every subagent completion:
  [SubagentStop: subagent-stop.sh]   → flag weak claims, missing references

Every stop attempt:
  [Stop: stop.sh]                    → auto-save + workflow enforcement + evidence check

Before context compaction:
  [PreCompact: pre-compact.sh]       → snapshot session state to .auto-save.md + inject preservation guidance

Every tool failure:
  [PostToolUseFailure: post-tool-failure.sh] → log failure + inject recovery guidance + detect cascading failures

All hooks: exit 0 = ALLOW, exit 2 = BLOCK, stderr = ADVISORY
Graceful degradation: own failures never block the user
```

### /handoff — Explicit Session End

Captures: branch, work completed, decisions, blockers, files accessed (modified/read/investigated), test status, next steps, activity summary from log → writes to `docs/sessions/session-YYYY-MM-DD.md` with YAML frontmatter (date, sprint, sprint_goal, branch, stories, status). Includes quality check sub-agent to verify the handoff is complete from a reader's perspective. Optionally adds a PR session summary comment for team visibility.

### /continue — Smart Session Resumption

```
/continue
     │
     ├──→ 0. Project health scan (ARCHITECTURE.md, GROUND_RULES.md, backlog, ADRs, tests)
     ├──→ 0.5. Failure state detection (.failure-state.md — YAML frontmatter parsing)
     │         highest priority: resume interrupted skill from next_action field
     ├──→ 0.6. Read latest session handoff (docs/sessions/session-*.md)
     ├──→ 0.7. Team context check (recent commits by others, conflicting PRs)
     ├──→ 1. Git state assessment (branch, changes, remote status)
     ├──→ 1.5. Load project context via context-prime (intent-aware)
     ├──→ 1.6. Reload working context (re-read modified files from session handoff)
     ├──→ 2. Project state assessment (progress, backlog, metrics warnings)
     ├──→ 2.5. Sprint context load (sprint spec: goal, capacity, decisions, boundaries)
     ├──→ 3. Determine continuation point (branch scenario → next action)
     ├──→ 4. Handle pending PRs
     ├──→ 5. Quick verification (run tests)
     ├──→ 5.5. Health dashboard (tests, last commit, open changes, session age)
     └──→ 6. Present options → wait for user direction
```

### Cross-Session Data Persistence

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                     DATA FLOW ACROSS SESSIONS                                 │
│                                                                               │
│  Session N                              Session N+1                           │
│  ─────────                              ──────────                            │
│                                                                               │
│  /story-cycle ─┐                        /continue ─────────┐                  │
│                │                                           │                  │
│                ├──→ docs/sessions/                         │                  │
│                │    session-YYYY-MM-DD.md ────────────────→├── reload state   │
│                │                                           │                  │
│  [Stop hook] ──┤──→ docs/sessions/                         │                  │
│                │    .auto-save.md ────────────────────────→├── git state      │
│                │                                           │                  │
│  [Phase fail] ─┤──→ docs/sessions/                         │                  │
│                │    .failure-state.md ────────────────────→├── resume skill   │
│                │                                           │                  │
│  record-failure┤──→ docs/context/                          │                  │
│                │    error-patterns.md ────────────────────→├── avoid pitfalls │
│                │                                           │                  │
│  capture-      │──→ docs/solutions/                        │                  │
│  learnings     │    <topic-slug>.md ──────────────────────→├── reuse patterns │
│                │                                           │                  │
│  /brainstorm ──┤──→ docs/brainstorms/                      │                  │
│                │    <design-slug>.md ─────────────────────→├── design context │
│                │                                           │                  │
│  [PostToolUse] ┤──→ docs/sessions/                         │                  │
│                │    .activity-log.jsonl ──────────────────→├── metrics        │
│                │                                           │                  │
│  /sprint-end ──┘──→ docs/progress.md ─────────────────────→├── sprint state   │
│                     docs/context/* ───────────────────────→└── project KB     │
│                                                                               │
│  ┌────────────────── Persistence Categories ────────────────────────────┐     │
│  │ VOLATILE (per-session):  .auto-save.md, .failure-state.md            │     │
│  │ CUMULATIVE (grows):      error-patterns.md, solutions/, brainstorms, │     │
│  │                          DECISION_LOG.md, ASSUMPTION_REGISTER.md     │     │
│  │ STRUCTURAL (snapshots):  session-*.md, progress.md, context/*        │     │
│  │ DISCOVERY (per-phase):   vision/*.md, docs/reviews/phase-N-*.md      │     │
│  │ METRICS (rotated):       .activity-log.jsonl (200 entry cap),        │     │
│  │                          .story-outcomes.tsv, .audit-log.jsonl,     │     │
│  │                          .failure-log.jsonl                          │     │
│  └──────────────────────────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────────────────────────┘
```

### Error Learning Flow (Cross-Session)

```
Session N:
  /story-cycle Phase 3.5 self-review catches rework
       ──→ record-failure micro-component
            ──→ appends to docs/context/error-patterns.md
                 (wrong approach, root cause, correct approach, prevention)

  /debug-session Phase 4.5 catches misdiagnosis
       ──→ same record-failure flow

Session N+1:
  /continue ──→ context-prime loads docs/context/error-patterns.md
       ──→ prevention strategies available during planning

  /story-cycle Phase 1 ──→ error patterns checked against current task
       ──→ known pitfalls surfaced before implementation begins
```

---

## 10. Flow: Debugging & Recovery

### /debug-session — Structured Debugging

```
/debug-session "TypeError in checkout"
     │
     ▼
Phase 1: Root Cause Investigation
     │  ├──→ understand error
     │  ├──→ reproduce consistently
     │  ├──→ check recent changes
     │  ├──→ trace backward (root-cause-tracing, failure_diagnosis)
     │  └──→ *** HARD GATE: evidence required before any fix ***
     │
     ▼
Phase 2: Pattern Analysis
     │  ├──→ find working examples, compare line by line
     │  └──→ optional web search for third-party issues
     │
     ▼
Phase 3: Hypothesis Testing
     │  ├──→ single hypothesis with prediction
     │  ├──→ one variable at a time
     │  └──→ *** STOPPING POINT: 3+ failed attempts → escalate ***
     │
     ▼
Phase 4: Fix (TDD)
     │  ├──→ write failing test reproducing bug
     │  ├──→ implement minimal fix
     │  └──→ run full test suite
     │
     ▼
Phase 4.5: Error Learning
     │  └──→ misdiagnosis? → record-failure → error-patterns.md
     │
     ▼
Phase 5: Verify and Document
```

### /fix-issue — GitHub Issue Resolution

```
/fix-issue 42
     │
     ├──→ get issue via gh issue view
     ├──→ understand problem (description, related issues, AC)
     ├──→ create branch fix/issue-42
     ├──→ search for relevant code
     ├──→ TDD fix (failing test → verify failure → minimal fix → verify pass)
     ├──→ verify (lint, typecheck, code review)
     ├──→ commit with "Closes #42"
     ├──→ create PR via gh pr create
     └──→ return PR URL
```

### /undo-work — Safe Revert

Three rollback levels:

```
/undo-work
     │
     ├── --soft  ──→ git stash (recoverable)
     ├── --hard  ──→ git checkout + git clean (discard uncommitted)
     └── --story ──→ git reset to before story commits
     │
     └── *** HARD GATE: never discard without explicit user confirmation ***
         Shows affected files, commits, and uncommitted work first
```

---

## 11. Flow: Maintenance & Review

### /weekly-maintenance — Weekly Health Check

```
Weekly (Friday recommended):
  /weekly-maintenance ──→ 1-2 hours
       ├──→ codebase health (complexity, duplication, churn, dead code)
       ├──→ code-quality agent
       ├──→ documentation review (CLAUDE.md accuracy, doc-implementation drift)
       ├──→ dependency review (outdated, vulnerabilities, lockfile sync)
       ├──→ rule health review (scripts/pm/metrics.sh)
       │       ├──→ over-active rules → may be too broad
       │       ├──→ silent rules → may be too narrow
       │       └──→ high-failure skills → need adjustment
       ├──→ weekly summary → progress.md
       └──→ plan next week from backlog
```

### /retrospective — Sprint Review

```
After sprint:
  /retrospective
       ├──→ gather data (progress.md, git log, blockers)
       ├──→ metrics dashboard:
       │       ├── sprint: commits, files changed, LOC
       │       ├── quality: test count, coverage, duplication, security findings
       │       ├── AI-specific: suggestion survival rate, context resets, TDD compliance
       │       ├── activity log: tool invocations, hotspots, edit-to-bash ratio
       │       └── skill execution: via scripts/pm/metrics.sh
       ├──→ 4Ls framework (Liked, Learned, Lacked, Longed For)
       ├──→ AI-assisted development reflection
       ├──→ action items
       └──→ update CLAUDE.md with discovered patterns
```

### /backlog-review — Backlog Health

Theme coverage analysis, INVEST criteria scan, dependency mapping, estimation review → health score X/10.

### /doctor — Framework Health Check

```
/doctor
     ├──→ command verification (dry-run each configured command)
     ├──→ hook dependencies (scripts exist, executable, tools available)
     ├──→ rule relevance (path patterns vs actual project files: ACTIVE/DORMANT)
     ├──→ skill dependencies (depends-on, calls fields validated)
     ├──→ documentation freshness (CLAUDE.md, progress.md, BACKLOG_INDEX.md)
     ├──→ git state (branch naming, stale branches, remote)
     ├──→ skill conformance (frontmatter, line budget, references, registry)
     ├──→ readiness progress (if READINESS_REPORT.md exists: re-evaluate
     │       Risk/Missing items against current state, show ↑Fixed/→Unchanged)
     └──→ output: PASS / WARN / FAIL per check + readiness progress table
```

### /framework-upgrade — Version Upgrade

Fetch new version → `/doctor` → 3-way diff (core vs customizations vs new) → classify files → merge strategy → `/doctor` again → summary. Preserves project customizations.

### /dashboard — Sprint Status Overview

Quick read-only status check: git state, sprint progress, test health, backlog snapshot, open PRs, session state, framework health → suggested next action.

### /quickstart — Guided Framework Tour

Interactive walkthrough of the framework for new users: orientation → readiness check → guided sprint → next steps. Four options: guided sprint, skill reference, enforcement explained, or jump to building.

### /help-me — Natural Language Skill Discovery

Maps natural language requests ("I want to...") to the appropriate skill(s). Covers all workflow stages with intent-matching tables. Suggests skill sequences for multi-step workflows.

### /pr-status — PR Status Check

`gh pr list` + `gh pr view` + `gh pr checks` → status summary → offer actions (merge / address feedback / fix checks / wait).

---

## 12. Flow: Parallel Work & Utilities

### /parallel-work — Parallel Streams

Opt-in. The default workflow is one branch, one story at a time; parallel streams
are for self-contained stories with no shared files (see the story template's
"Self-Contained by Default" guidance).

```
/sprint-start ──→ creates sprint branch on main worktree
     │
     ▼
/parallel-work start ──→ sense-checks the plan (dependencies, overlapping files)
     │                     creates N worktrees off the sprint branch, one branch each
     │                     (scripts/new-worktree.sh: records parent in git config
     │                      branch.<name>.exosuitParent, propagates .env,
     │                      settings.local.json, CLAUDE.local.md, .mcp.json)
     │                     offers to open each in its own Claude Code tab
     │                     (scripts/open-worktree-terminals.sh, cross-platform)
     │
     ▼
In each stream: /story-cycle as normal
     │  ├──→ [settings.json hook prefix resolves the correct worktree root]
     │  ├──→ /merge-up   — publish this stream's work into the sprint branch,
     │  │                  then fast-forward the stream back up to it
     │  └──→ /merge-down — pull sibling streams' merged work into this stream
     │
     ▼
/parallel-work status ──→ all streams, parents, ahead/behind counts
     │
     ▼
/parallel-work cleanup ──→ removes fully-merged streams (safe delete only)
     │
     ▼
/sprint-end ──→ verifies every stream is merged up (stops on unmerged work),
                removes child worktrees and branches, ships the sprint via PR
```

### /commit — Conventional Commit

Review changes → determine type → generate `<type>(<scope>): <description>` → execute → verify. Includes `Co-Authored-By` footer.

### /skill-eval — Skill Testing

Five modes: **eval** (test against scenario), **compare** (blind A/B test), **metrics** (testability analysis), **baseline** (capture output), **regression** (compare against baseline).

### /refine-loop — Iterative Improvement

Initial execution → self-review against criteria → iterate until all MET (max 5 rounds). HARD GATE: "make it better" invalid — must name specific gap.

### /custom-hooks — Project-Specific Hook Creation

Guide creating POSIX shell hooks: select event type → generate script → register in settings.json → test → document. Follows framework hook conventions (jq with sed fallback, graceful degradation).

### /uninstall — Clean Framework Removal

Safely remove framework from project: confirm intent → inventory framework vs project files → remove framework files → clean up CLAUDE.md → update .gitignore. Three modes: full removal, keep documentation, cancel. Technology skills can be preserved or removed.

### /performance-check — Performance Analysis

Quality agent skill (like /code-quality, /test-validator) analyzing: N+1 queries, unbounded operations, blocking I/O, memory leaks, scaling behavior. Forked Explore agent, read-only, confidence scoring ≥80.

### /build — Build From Natural Language

Orchestrates full project build from a plain-English description. Designed for non-technical users but useful for anyone wanting fast results.

```
/build "a task management app with user accounts and due dates"
     │
     ├──→ Phase 0: Check setup (silent minimal bootstrap if needed, force lean profile)
     ├──→ Phase 1: Decompose (internal only — no methodology jargon shown to user)
     │       ├── dependency-ordered steps, each one cohesive, independently verifiable unit
     │       └── retroactive discovery capture: infer archetype, generate
     │           minimal DECISION_LOG.md (all ASSUMED), add Phase Transition
     │           Stories to backlog for future review cycle
     ├──→ Phase 2: Execute each step
     │       ├── plain-English progress: "Setting up the database..."
     │       ├── lean story-cycle behavior (TDD, but don't explain TDD)
     │       └── all technical decisions made silently
     └──→ Phase 3: Completion report (what was built, files, tests, decisions, how to run)
```

Rules: plain English only, silent technical decisions, stop only for product questions (not tech choices), skip gracefully on failure.

### /deploy — Platform Deployment

```
/deploy [platform] [--dry-run]
     │
     ├──→ Step 1: Pre-deploy checks (clean git, tests pass)
     ├──→ Step 2: Detect platform (Vercel, Netlify, Fly.io, Railway, Render, Heroku, etc.)
     ├──→ Step 3: Verify CLI tool installed
     ├──→ Step 4: Execute deployment
     └──→ Step 5: Report (URL, status, next steps)
```

### /optimize — Metric-Driven Iterative Optimization

```
/optimize "increase test coverage" --metric "pytest --cov | grep TOTAL" --target 90
     │
     ├──→ Pre-flight: clean git state, feature branch (HARD GATE)
     ├──→ Baseline measurement
     ├──→ Experiment loop (up to --max iterations, default 20):
     │       ├── Analyze + propose change
     │       ├── Implement (one idea per experiment)
     │       ├── Commit checkpoint
     │       ├── Measure new metric value
     │       ├── KEEP (metric improved) or DISCARD (git reset + restore)
     │       └── Log to .optimization-log.tsv
     ├──→ Diminishing returns detection (3 consecutive failures → stop early)
     └──→ Completion report (baseline → final, experiments kept/discarded)
```

Safety: git checkpoint per experiment, auto-rollback on regression, branch protection, crash isolation.

### /quality-check — Unified Quality Gate Dispatcher

```
/quality-check [--code] [--tests] [--security] [--architecture] [--performance] [--all]
     │
     ├──→ Parse flags (or apply profile defaults: lean=code, standard=code+tests+security, strict=all)
     ├──→ Run quality-gate-sequence first (lint → typecheck → test)
     │       └── *** HARD GATE: tests must pass before agent dispatch ***
     ├──→ Dispatch selected quality agent skills in parallel
     │       ├── /code-quality, /test-validator, /security-audit
     │       ├── /architecture-check, /performance-check
     │       └── (strict profile: also dispatch integration-tester agent)
     └──→ Unified report: PASS / WARN / FAIL per check + overall verdict
```

### User-Invocable Prompt Snippets

| Snippet | Purpose |
|---|---|
| `/review-security <file>` | Security review: input validation, injection, secrets, CWE top 10 |
| `/explain-pattern <pattern> [file]` | Explain a code pattern as used in this codebase |
| `/suggest-tests <file>` | Suggest test cases with priority and category |

### PM Scripts

| Script | Purpose |
|---|---|
| `scripts/pm/status.sh` | Sprint status dashboard |
| `scripts/pm/next-story.sh` | Next TODO story from backlog |
| `scripts/pm/standup.sh` | Daily standup summary |
| `scripts/pm/metrics.sh` | Skill/rule/tool metrics from activity log |

---

## 13. Under the Hood: The Three Layers

This section provides the technical reference for every component. The flow sections above show WHAT happens from the user perspective — this section explains HOW each component works internally.

### 13.1 Enforcement: Hooks

Hooks are POSIX shell scripts that execute automatically on Claude Code events. They are the only fully deterministic enforcement mechanism — the AI cannot bypass them.

**Architecture:**
- Individual shell scripts — each event has a dedicated script
- No language runtimes required — pure POSIX shell (`#!/bin/sh`)
- JSON field extraction uses `jq` when available, with `sed` fallback
- Graceful degradation — own failures never block the user (exit 0 on error)
- Session state in `.claude/hooks/state/` (plain text files: `project-profile`, `stop-iteration`)
- Rule files use simple plain-text formats (`.patterns`, `.conf`) — no parser dependencies

**Exit codes:** exit 0 = allow, exit 2 = block, stderr = advisory warnings

#### Hook Processing Pipeline

```
Claude Code Event
     │
     ├──→ hook-guard.sh (called by each hook)
     │       ├── Check EXOSUIT_DISABLED_HOOKS → skip if disabled
     │       ├── Resolve profile (project → hook)
     │       └── Current level >= minimum? → run or skip
     │
     ▼
settings.json / hooks.json
     │  (match event type + tool matcher)
     │
     ├──→ [PreToolUse: Bash]
     │       ├── pre-tool-use.sh ── block + advisory patterns
     │       └── worktree-bash-fix.sh ── inject cd prefix
     │
     ├──→ [PreToolUse: Read]
     │       └── pre-read-check.sh ── sensitive file warning
     │
     ├──→ [PostToolUse: Edit|Write|Bash]
     │       ├── post-tool-use.sh ── activity logging
     │       └── post-edit-format.sh ── format + lint + secrets
     │
     ├──→ [UserPromptSubmit]
     │       └── user-prompt.sh ── intent detection + skill suggestions
     │
     ├──→ [Stop]
     │       └── stop.sh ── auto-save + evidence check + debug audit
     │
     ├──→ [SubagentStop]
     │       └── subagent-stop.sh ── weak claim detection
     │
     ├──→ [PreCompact]
     │       └── pre-compact.sh ── snapshot state + inject preservation guidance
     │
     └──→ [PostToolUseFailure]
            └── post-tool-failure.sh ── log failure + recovery guidance
```

#### Hook Registration

| Event | Script | Purpose | Type |
|---|---|---|---|
| `SessionStart` | `session-start.sh` | Tool checks, stale sessions, git state (once per session) | Advisory |
| `PreToolUse` (Bash) | `pre-tool-use.sh` | Dangerous command blocking + sanitization + context injection | Blocking/Modifier |
| `PreToolUse` (Bash) | `worktree-bash-fix.sh` | Worktree cd prefix injection | Modifier |
| `PreToolUse` (Read) | `pre-read-check.sh` | Sensitive file warning (.env, keys, credentials) | Advisory |
| `PostToolUse` (Edit\|Write\|Bash) | `post-tool-use.sh` | Activity logging | Logging |
| `PostToolUse` (Edit) | `post-edit-format.sh` | Auto-format + secrets scan | Non-blocking |
| `Stop` | `stop.sh` | Completion evidence validation + workflow enforcement + auto-save | Blocking |
| `UserPromptSubmit` | `user-prompt.sh` | Destructive intent detection + skill suggestions | Advisory |
| `SubagentStop` | `subagent-stop.sh` | Weak claim detection | Advisory |
| `WorktreeCreate` | `worktree.sh` | Copy state files to new worktree | Advisory |
| `WorktreeRemove` | `worktree.sh` | Merge activity logs back | Advisory |
| `PreCompact` | `pre-compact.sh` | Snapshot session state + inject compaction preservation guidance | Advisory |
| `PostToolUseFailure` | `post-tool-failure.sh` | Log tool failures + inject recovery guidance + detect cascading failures | Advisory |

#### lib/hook-guard.sh — Profile-Based Hook Gating

Every hook script calls `hook-guard.sh` as its first action to determine whether it should run. This enables profile-adaptive behavior across the entire enforcement layer.

```
Hook invocation:
     │
     ├──→ hook-guard.sh "<hook-id>" "<minimum-profile>"
     │       │
     │       ├── Check EXOSUIT_DISABLED_HOOKS → skip if hook ID in list
     │       │
     │       ├── Resolve project profile:
     │       │     1. EXOSUIT_PROJECT_PROFILE env var
     │       │     2. CLAUDE.md **Profile:** line
     │       │     3. Default: standard
     │       │
     │       ├── Resolve hook profile:
     │       │     EXOSUIT_HOOK_PROFILE env var → overrides project-derived default
     │       │     OR derive from project: lean→minimal, standard→standard, strict→strict
     │       │
     │       └── Compare: current level >= minimum level?
     │             minimal(1) < standard(2) < strict(3)
     │             ├── Yes → exit 0 (hook runs)
     │             └── No  → exit 1 (hook skipped)
     │
     └──→ Hook proceeds or exits with: || exit 0
```

This enables lean projects to skip ceremony-heavy hooks while strict projects get maximum enforcement.

#### pre-read-check.sh — Sensitive File Warning

Advisory hook on `PreToolUse` (Read). Matches file paths against `rules/sensitive-files.patterns`:

| Pattern | What It Warns About |
|---|---|
| `.env*` | Environment files — secrets may enter context window |
| `*.key`, `*.pem`, `*.p12`, `*.pfx` | Cryptographic key files |
| `credentials*` | Credential files |
| `secrets?/.` | Files with 'secret' in path |
| `id_rsa`, `id_ecdsa`, etc. | SSH private keys |
| `.htpasswd` | Password hash files |

Always advisory (exit 0) — warns on stderr but never blocks reads. Runs at standard profile minimum.

#### session-start.sh — Environment Checks

Checks: tool availability (parses CLAUDE.md Commands section), stale session detection (`.auto-save.md` >24h → warn to run `/continue`), git state (warn if on main, detached HEAD, uncommitted changes), state initialization, first-run detection (CLAUDE.md still has placeholder commands → suggests `/quickstart`).

#### pre-tool-use.sh — Safety Blocking + Advisory Warnings

Loads patterns from `rules/safety.patterns` (blocking) and `rules/advisory.patterns` (warnings). Also includes framework repo protection — blocks push/PR if remote points to the template repository.

**Explanation mode (v4.0):** When `EXOSUIT_EXPLAIN_MODE=verbose`, blocked commands include WHY (what damage it causes) and INSTEAD (safer alternative). Controlled per-pattern via a 5th field in safety.patterns: `id@@regex@@message@@severity@@explanation`.

**Blocked patterns (safety.patterns):**

| ID | What It Blocks |
|---|---|
| `git-push-force` | `git push --force` |
| `git-push-f` | `git push -f` |
| `git-checkout-dot` | `git checkout .` (discards all changes) |
| `git-reset-hard` | `git reset --hard` |
| `git-clean-f` | `git clean -f` (deletes untracked files) |
| `git-branch-force-delete` | `git branch -D` (force-deletes unmerged branch) |
| `git-no-verify` | `--no-verify` (skips safety hooks) |
| `git-push-main` | `git push ... main` (direct push to main) |
| `git-push-master` | `git push ... master` (direct push to master) |
| `rm-rf-git` | `rm -rf .git` (destroys repository) |
| `rm-rf-dangerous` | `rm -rf /`, `rm -rf ..`, `rm -rf ~` |
| `package-publish` | npm publish, cargo publish, twine upload, gem push |
| `db-destructive` | DROP TABLE, DROP DATABASE, TRUNCATE TABLE |
| `mass-kill` | kill -9 -1, killall, pkill -9 |

**Advisory patterns (advisory.patterns — warn but never block):**

| Category | What It Warns About |
|---|---|
| Dev servers | `npm run dev`, `flask run`, `uvicorn`, `rails server`, etc. — long-running commands that block the session |

#### post-edit-format.sh — Auto-Format + Secrets

Two functions on every edit:

**1. Auto-formatting by language:**

```
Language    │ Extensions          │ Formatter              │ Linter (auto-fix)
────────────┼─────────────────────┼────────────────────────┼──────────────────
Python      │ .py                 │ ruff format / black    │ ruff check --fix
JavaScript  │ .js, .jsx           │ prettier / biome       │ eslint --fix / biome
TypeScript  │ .ts, .tsx           │ prettier / biome       │ eslint --fix / biome
Go          │ .go                 │ gofmt                  │ golangci-lint --fix
Rust        │ .rs                 │ rustfmt                │ —
Ruby        │ .rb                 │ rubocop -A             │ —
Java        │ .java               │ google-java-format     │ —
Kotlin      │ .kt, .kts           │ ktfmt                  │ —
Swift       │ .swift              │ swift-format           │ —
PHP         │ .php                │ php-cs-fixer           │ —
Dart        │ .dart               │ dart format            │ —
C#          │ .cs                 │ dotnet format          │ —
C/C++       │ .c, .cpp, .h, .hpp  │ clang-format           │ —
JSON/CSS    │ .json, .css         │ prettier / biome       │ —
HTML        │ .html               │ prettier / biome       │ —

Fallback: if primary formatter missing, try alternative
Missing tool: report ONCE per session, then silently skip
```

**2. Secrets detection:** Scans for AWS keys (`AKIA...`), API keys (`sk-...`), GitHub tokens (`ghp_...`), private keys, hardcoded credential assignments. Reports once per file per session.

#### stop.sh — Quality Gates + Auto-Save

Four functions:

1. **Auto-save** — When uncommitted changes exist, saves branch, commits, and changes to `.auto-save.md`. Skipped when there are no uncommitted changes.
2. **Safety valve** — Max iteration counter (default 5, configurable via `EXOSUIT_STOP_MAX_ITERATIONS`; strict profile defaults to 10), then allows stop unconditionally. Set to ≤0 for no limit.
3. **Completion evidence** — Scans for unverified claims ("complete/done/finished" without test output). Flags weak language ("should work", "looks correct"). Blocks (exit 2) if completion claimed without evidence.
4. **Debug statement audit** — Scans `git diff` output against `rules/debug.patterns` for leftover debug statements (`console.log`, `pdb.set_trace`, `debugger`, `dbg!`, `TODO/FIXME`, etc.). Advisory only — warns but never blocks.

#### Other Hook Scripts

- **user-prompt.sh** — Warns about destructive requests ("delete all", "drop database", etc.) AND suggests relevant skills based on intent (e.g., "bug in login" → suggest `/debug-session`; "ship to main" → suggest `/sprint-end`). Skill suggestions shown at most once per skill per session, suppressed when the prompt already starts with a skill invocation.
- **subagent-stop.sh** — Flags weak claims and missing `file:line` references in substantial subagent output
- **worktree.sh** — WorktreeCreate: copies state files. WorktreeRemove: merges activity logs back.
- **worktree-bash-fix.sh** — Injects `cd '<worktree>'` prefix for commands in worktrees (applied to subagents too)
- **pre-compact.sh** — PreCompact handler. Snapshots current session state (branch, recent commits, uncommitted changes, active skill context from `.failure-state.md`) to `docs/sessions/.auto-save.md`. Injects `systemMessage` guidance for what to preserve during compaction. Advisory only (cannot block compaction). Runs at minimal profile (always active).
- **post-tool-failure.sh** — PostToolUseFailure handler. Logs all tool failures to `docs/sessions/.failure-log.jsonl`. Detects cascading failures (3+ on same target) and escalates. Injects tool-specific recovery guidance via `systemMessage` (Edit: re-read first; Bash: check exit code; Read: verify path; Write: check permissions). Advisory only. Runs at standard profile.
- **status-line.sh** — Outputs `Sprint N | branch-name*` for Claude Code status bar. Not a hook — configured via the `statusLine` setting in settings.json (runs as a shell command, not on a hook event)

#### Hook Rule Files

| File | Format | Used By | Content |
|---|---|---|---|
| `safety.patterns` | `id@@regex@@message[@@severity][@@explanation]` | pre-tool-use.sh | 14 blocking patterns with WHY/INSTEAD explanations |
| `advisory.patterns` | `id@@regex@@message[@@severity]` | pre-tool-use.sh | 11 advisory patterns (long-running commands) |
| `sensitive-files.patterns` | `id@@regex@@message` | pre-read-check.sh | 6 sensitive file path patterns |
| `debug.patterns` | `id@@regex@@message` | stop.sh | 11 debug statement patterns (console.log, pdb, debugger, dbg!, TODO/FIXME, etc.) |
| `skill-suggestions.patterns` | `regex@@skill@@reason` | user-prompt.sh | 8 intent→skill suggestion mappings |
| `quality.conf` | `key=value` | stop.sh | Completion/evidence/weak-claim patterns |
| `intent.patterns` | `regex@@message` | user-prompt.sh | Destructive request patterns |
| `subagent.patterns` | `regex@@message` | subagent-stop.sh | Weak claim patterns |
| `subagent.conf` | `key=value` | subagent-stop.sh | `require_references=true` |

### 13.2 Enforcement: Rules

Rules are markdown files in `.claude/rules/` with YAML frontmatter specifying `paths:` glob patterns. Auto-loaded when matching files are edited. Advisory (not physically enforced like hooks) but strongly influence AI behavior.

#### Rule Activation Matrix

```
                  testing  security  code-slop  dependencies  git  verification  edit-recovery  documentation  research
                  ───────  ────────  ─────────  ────────────  ───  ────────────  ─────────────  ─────────────  ────────
*.test.ts            ●        ○         ●           ○         ●        ●             ●              ○            ○
*.spec.py            ●        ○         ●           ○         ●        ●             ●              ○            ○
src/auth/*.ts        ○        ●         ●           ○         ●        ●             ●              ○            ○
src/api/*.go         ○        ●         ●           ○         ●        ●             ●              ○            ○
package.json         ○        ○         ○           ●         ●        ●             ●              ○            ○
*.env                ○        ●         ○           ○         ●        ●             ●              ○            ○
docs/*.md            ○        ○         ○           ○         ●        ●             ●              ●            ○
docs/research/*.md   ○        ○         ○           ○         ●        ●             ●              ●            ●
src/utils.py         ○        ○         ●           ○         ●        ●             ●              ○            ○

● = auto-loaded    ○ = not loaded
Note: git.md, verification.md, edit-recovery.md match ** (all files — always active)
```

#### Rule Details

| Rule | Paths | Key Protections |
|---|---|---|
| **testing.md** | `**/*.test.*`, `**/*.spec.*`, `**/tests/**` | Never weaken assertions, delete tests, reduce test count. Anti-patterns table (tautological tests, over-mocking, copy-paste assertion drift, etc.) |
| **security.md** | `**/*.env*`, `**/auth/**`, `**/api/**`, `**/routes/**`, `**/middleware/**`, etc. | CWE top 10 for AI code, no hardcoded secrets, parameterized SQL, fix immediately (don't defer). AI-specific anti-patterns (phantom packages, typosquatting). |
| **code-slop.md** | `**/*.ts`, `**/*.py`, `**/*.go`, etc. | 15 banned filler phrases, obvious comment detection, no docstrings on self-explanatory functions |
| **dependencies.md** | `package.json`, `pyproject.toml`, `go.mod`, etc. | No phantom packages, verify registry, user approval required, flag packages <7 days old |
| **git.md** | `**` (always active) | Never push to main, conventional commits, squash merge, never skip pre-commit hooks |
| **verification.md** | `**` (always active) | Evidence required for completion, four-question protocol, context budget awareness, relevance scoring |
| **edit-recovery.md** | `**` (always active) | Re-read before retry, 3-failure pause, never retry same edit |
| **documentation.md** | `docs/**`, `**/*.md` | Lean docs, size budgets (SKILL.md ≤150 lines, reference ≤200, etc.), reference by path |
| **research.md** | `docs/research/**` | Source citations required, confidence justification, URL verification, sources ≥3/10 quality |

### 13.3 Workflow: Skills

Skills are markdown files (`.claude/skills/<name>/SKILL.md`) loaded on `/skill-name` invocation.

#### Skill Structure

```
.claude/skills/<name>/
  SKILL.md           # Entry point (<150 lines)
  references/        # On-demand detail docs loaded when needed
  scripts/           # Executable helper scripts
  assets/            # Output templates (copy, don't read)
```

#### YAML Frontmatter

```yaml
---
name: skill-name
version: X.Y.Z
description: one-line purpose
trigger: manual|auto|conditional
depends-on: [skill-a, skill-b]
references: [references/file.md]
micro-components:
  phase-N: [component-name]
user-invocable: true
allowed-tools: Read, Glob, ...
argument-hint: "<description>"
context: fork              # for quality agents
agent: Explore             # subagent type
---
```

#### Skill Dependency Graph

```
                    ┌─────────────┐
                    │  bootstrap  │
                    └──────┬──────┘
                           │ calls
                           ▼
                    ┌─────────────┐
                    │ skill-create│
                    └─────────────┘

  ┌──────────┐      ┌──────────────┐      ┌──────────────┐
  │brainstorm│─────→│    ideate    │      │   fix-issue  │
  └──────────┘ next └──────────────┘      └───────┬──────┘
                                                  │ calls
                                                  ▼
                                          ┌──────────────┐
                                          │ story-cycle  │
                                          └──────┬───────┘
                                                 │ calls
                          ┌──────────────────────┼──────────────────────┐
                          ▼                      ▼                      ▼
                   ┌─────────────┐      ┌────────────────┐     ┌───────────────┐
                   │code-quality │      │ test-validator │     │security-audit │
                   └─────────────┘      └────────────────┘     └───────────────┘
                          ▲                      ▲                      ▲
                          └──────────────────────┼──────────────────────┘
                                                 │ calls
                                          ┌──────┴───────┐
                                          │  sprint-end  │──────→ architecture-check
                                          └──────────────┘

                   ┌────────────────────┐
                   │weekly-maintenance  │───→ code-quality, doctor
                   └────────────────────┘

                   ┌────────────────────┐
                   │  quality-check     │───→ code-quality, test-validator,
                   └────────────────────┘     security-audit, architecture-check,
                                              performance-check

                   ┌────────────────────┐
                   │      build         │───→ bootstrap, ideate, story-cycle
                   └────────────────────┘

                   ┌────────────────────┐
                   │     discover       │───→ ideate
                   └────────────────────┘

                   ┌────────────────────┐
                   │   phase-review     │───→ ideate
                   └────────────────────┘

Standalone (no dependencies):
  commit, continue, handoff, sprint-start, parallel-work,
  merge-up, merge-down,
  manual-test, testing-cycle, UAT-cycle, debug-session,
  undo-work, pr-status, backlog-review, retrospective,
  refine-loop, skill-eval, claude-sense-check, deploy,
  optimize
```

#### Complete Skills List

| Skill | Version | Purpose | Trigger |
|---|---|---|---|
| `/bootstrap` | v2.13.0 | First-run framework setup | Manual |
| `/sprint-start` | v2.7.0 | Start sprint with clean state + planning | Manual |
| `/story-cycle` | v4.4.0 | Universal story delivery (TDD, quality gates, profile-adaptive) | Manual |
| `/sprint-end` | v2.10.0 | Ship sprint via PR (quality gates + merge) | Manual |
| `/continue` | v2.7.0 | Smart session resumption | Manual |
| `/handoff` | v2.6.0 | Structured session end | Manual |
| `/discover` | v1.0.0 | Deep guided elicitation (archetype-aware, 7-phase, 4 modes) | Manual |
| `/phase-review` | v1.0.0 | Phase transition review (walkthrough, assumptions, next phase) | Manual |
| `/brainstorm` | v2.7.0 | Design exploration with alternatives | Manual |
| `/ideate` | v2.10.0 | Decompose ideas into typed stories | Manual |
| `/research` | v1.0.0 | Deep online research with citations | Manual |
| `/skill-create` | v2.4.0 | Generate technology-specific skills | Manual |
| `/code-quality` | v2.4.0 | Code quality analysis (forked agent) | Auto |
| `/test-validator` | v2.4.0 | Test coverage + TDD compliance (forked agent) | Auto |
| `/security-audit` | v3.0.0 | Security review (forked agent, BLOCKING) | Conditional |
| `/architecture-check` | v2.7.0 | Module boundary + drift detection (forked agent) | Conditional |
| `/manual-test` | v2.4.0 | Generate manual test plan | Manual |
| `/testing-cycle` | v2.4.0 | Process testing feedback | Manual |
| `/UAT-cycle` | v2.4.0 | Execute formal UAT test case | Manual |
| `/claude-sense-check` | v3.4.0 | Batch UAT code logic verification | Manual |
| `/debug-session` | v2.9.0 | Structured debugging (5 phases) | Manual |
| `/fix-issue` | v2.4.0 | GitHub issue → TDD fix → PR | Manual |
| `/undo-work` | v3.0.1 | Safe revert (3 levels) | Manual |
| `/commit` | v2.4.0 | Conventional commit | Manual |
| `/parallel-work` | v3.0.0 | Parallel streams (create, status, cleanup) | Manual |
| `/merge-up` | v1.0.0 | Merge stream into its parent branch | Manual |
| `/merge-down` | v1.0.0 | Pull parent branch into stream | Manual |
| `/weekly-maintenance` | v2.6.0 | Weekly health check | Manual |
| `/retrospective` | v3.0.0 | Sprint review (4Ls) | Manual |
| `/backlog-review` | v3.0.0 | Backlog health analysis | Manual |
| `/doctor` | v3.0.0 | Framework health check | Manual |
| `/framework-upgrade` | v1.1.0 | Framework version upgrade | Manual |
| `/pr-status` | v2.4.0 | Check open PR status | Manual |
| `/skill-eval` | v2.5.0 | Skill testing + comparison | Manual |
| `/refine-loop` | v2.5.0 | Iterative self-improvement | Manual |
| `/quickstart` | v1.0.0 | Guided framework tour | Manual |
| `/help-me` | v1.0.0 | Natural language skill discovery | Manual |
| `/dashboard` | v1.2.0 | Sprint status overview | Manual |
| `/custom-hooks` | v1.0.0 | Create project-specific hooks | Manual |
| `/uninstall` | v1.0.0 | Clean framework removal | Manual |
| `/performance-check` | v1.0.0 | Performance analysis (forked agent) | Conditional |
| `/build` | v1.0.0 | Build project from natural language description | Manual |
| `/deploy` | v1.0.0 | Deploy to hosting platform (Vercel, Fly.io, etc.) | Manual |
| `/optimize` | v1.0.0 | Metric-driven iterative optimization with git checkpointing | Manual |
| `/quality-check` | v1.0.0 | Unified quality gate dispatcher (profile-aware defaults) | Manual |

### 13.4 Workflow: Quality Agents

Quality agents run as forked Explore subagents — isolated context, read-only, confidence scoring (only findings ≥80 reported):

| Quality Skill | Focus | Native Agent Equivalent | Blocking? |
|---|---|---|---|
| `/code-quality` | Complexity, duplication, patterns, coupling | `code-reviewer` | No |
| `/test-validator` | Coverage, TDD compliance, assertion quality | `spec-reviewer` | No |
| `/security-audit` | CWE top 10, phantom packages, secrets | `security-analyst` | Yes (≥80) |
| `/architecture-check` | Module boundaries, drift, ADR generation | `architecture-reviewer` | No |
| `/performance-check` | N+1 queries, unbounded ops, blocking I/O, memory | `performance-engineer` | No |

**Unified dispatcher:** `/quality-check` provides a single entry point for all quality agents with profile-aware defaults:

| Profile | Default Checks | Notes |
|---|---|---|
| Lean | `/code-quality` only | Lint + complexity |
| Standard | `/code-quality` + `/test-validator` + `/security-audit` | Default for most projects |
| Strict | All 5 + `integration-tester` agent | Maximum rigor |

### 13.5 Workflow: Native Agents

Persona definitions in `.claude/agents/` running as Claude Code subagents:

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                              NATIVE AGENT COMPARISON                                  │
├───────────────────┬─────────┬───────────────┬──────────────────────────┬────────┬──────┤
│ Agent             │ Model   │ Tools         │ Focus                    │maxTurns│effort│
├───────────────────┼─────────┼───────────────┼──────────────────────────┼────────┼──────┤
│ code-reviewer     │ inherit │ Glob,Grep,Read│ Correctness, conventions │ 20     │      │
│ spec-reviewer     │ haiku   │ Glob,Grep,Read│ AC compliance            │ 15     │      │
│ security-analyst  │ inherit │ Glob,Grep,Read│ Attacker-mindset review  │ 20     │      │
│ integration-tester│ inherit │ Glob,Grep,    │ Independent dynamic      │ 25     │      │
│                   │         │ Read,Bash     │ verification (runs tests)│        │      │
│ perf-engineer     │ inherit │ Glob,Grep,    │ Hot paths, N+1, leaks    │ 20     │      │
│                   │         │ Read,Bash     │                          │        │      │
│ arch-reviewer     │ inherit │ Glob,Grep,Read│ Boundaries, drift        │ 20     │      │
│ codebase-explorer │ haiku   │ Glob,Grep,Read│ Fast file discovery      │ 10     │ low  │
│ research-analyst  │ haiku   │ WebSearch,    │ Deep web research with   │ 25     │      │
│                   │         │ WebFetch,Read,│ source evaluation and    │        │      │
│                   │         │ Grep,Glob     │ reflection output        │        │      │
│                   │         │               │                          │        │      │
│ ALL agents        │         │               │ disallowedTools: [Edit, Write, NotebookEdit]  │
└───────────────────┴─────────┴───────────────┴──────────────────────────┴────────┴──────┘

         Model Selection
         haiku ◄───── cost/speed ──────── capability ─────► inherit
         ▲                                                     ▲
         │                                                     │
    spec-reviewer (simple PASS/FAIL)              code-reviewer
    codebase-explorer (file discovery)            security-analyst
    research-analyst (search+reflect)             arch-reviewer
                                                  perf-engineer
                                                  integration-tester
```

**Native agents not covered by quality skills:** `codebase-explorer` (used by `/story-cycle` Phase 1), `research-analyst` (used by deep-research engine), `integration-tester` (used by `/quality-check` in strict profile — independently runs test suites and verifies acceptance criteria with command output evidence, breaking the self-assessment cycle where the implementer verifies their own work).

### 13.6 Workflow: Micro-Components

Reusable prompt snippets in `.claude/prompts/` composed into skills. Not directly user-invocable — building blocks.

#### Composition Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SKILL → MICRO-COMPONENT MATRIX                     │
├──────────────────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬────┤
│                  │disc-│veri-│cont-│qual-│conf-│reco-│wave-│grep-│capt-│capt-│sel │
│                  │over │fy-  │ext- │ity- │iden-│rd-  │exec-│first│ure- │ure- │ect │
│                  │cmds │clean│prime│gate-│ce-  │fail-│ution│expl-│learn│outc-│tool│
│                  │     │git  │     │seq  │gate │ure  │     │ore  │ings │ome  │    │
├──────────────────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼────┤
│ story-cycle      │ P1  │ P1  │ P1  │ P4  │P2.5 │P3.5 │ P1  │ P1  │ P4  │ P4  │    │
│ sprint-end       │ S1  │ S1  │     │ S2  │     │     │     │     │     │     │    │
│ continue         │ S5  │     │S1.5 │     │     │     │     │     │     │     │    │
│ debug-session    │     │     │     │     │     │P4.5 │     │     │     │     │    │
│ (any skill)      │     │     │     │     │     │     │     │     │     │     │  ● │
├──────────────────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴────┤
│ P = Phase, S = Step, ● = available on demand                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Micro-Component Reference

| Component | What It Does | Used By |
|---|---|---|
| `discover-commands` | Extract test/lint/format/build/typecheck from CLAUDE.md | story-cycle P1, sprint-end S1, continue S5 |
| `quality-gate-sequence` | Run lint → typecheck → test in order | story-cycle P4, sprint-end S2 |
| `verify-clean-git-state` | Check no uncommitted changes, on expected branch | story-cycle P1, sprint-end S1 |
| `context-prime` | Intent-aware loading of docs/context/* knowledge base | story-cycle P1, continue S1.5 |
| `confidence-gate` | 5 objective pre-condition checks (PASS/FAIL) — files read, tests baseline, pattern match, scope bounded, no conflicts | story-cycle P2.5 |
| `record-failure` | Append error patterns to error-patterns.md | story-cycle P3.5, debug-session P4.5 |
| `wave-execution` | Parallel execution: Wave 1 (reads) → Checkpoint → Wave 2 (actions) | story-cycle P1 |
| `grep-first-explore` | Extract terms, parallel grep, rank by density, read top 5-10 | story-cycle P1 |
| `capture-learnings` | Save learnings to docs/solutions/ with YAML frontmatter | story-cycle P4 |
| `capture-outcome` | Capture measurable story metrics (code delta, test count, coverage, deps) to `.story-outcomes.tsv` | story-cycle P4 |
| `deep-research` | Query decompose → parallel subagents → reflection → synthesis | /research, /bootstrap, /brainstorm, /ideate, /story-cycle |
| `source-evaluator` | Score web sources 0-10, discard below 3 | deep-research, /research |
| `select-tool` | MCP vs built-in tool decision matrix | Any skill |
| `context-budget` | Estimate context usage, report compaction proximity | Any skill |
| `validate-arguments` | Parse and validate skill arguments | Any skill |
| `interactive-ux` | AskUserQuestion protocol — when/how to ask, progress tracking, UX guidelines | story-cycle, discover, brainstorm, ideate, any skill |
| `error-recovery-central` | Centralized error recovery patterns | story-cycle, sprint-end, debug-session, any skill |

### 13.7 Profile System — Adaptive Workflow Depth

The framework adapts its behavior based on project complexity via a three-tier profile system:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     PROJECT PROFILE → FRAMEWORK BEHAVIOR                     │
├──────────┬────────────────────┬───────────────────┬─────────────────────────┤
│          │ LEAN               │ STANDARD          │ STRICT                  │
│          │ (prototypes, MVPs) │ (production apps) │ (regulated industries)  │
├──────────┼────────────────────┼───────────────────┼─────────────────────────┤
│ Hook     │ minimal — skip     │ standard — all    │ strict — all hooks +    │
│ profile  │ ceremony hooks     │ standard hooks    │ extra enforcement       │
├──────────┼────────────────────┼───────────────────┼─────────────────────────┤
│ Story    │ Simplified: Plan   │ Full phases with  │ Maximum rigor: all      │
│ cycle    │ (optional for      │ all gates         │ phases mandatory even   │
│          │ SMALL) → Build →   │                   │ for TRIVIAL; all quality│
│          │ Verify             │                   │ agents every story      │
├──────────┼────────────────────┼───────────────────┼─────────────────────────┤
│ Quality  │ /code-quality only │ code + tests +    │ All 5 agents +          │
│ agents   │                    │ security          │ integration-tester      │
├──────────┼────────────────────┼───────────────────┼─────────────────────────┤
│ Stop     │ 5 iterations       │ 5 iterations      │ 10 iterations          │
│ valve    │                    │                   │                         │
├──────────┼────────────────────┼───────────────────┼─────────────────────────┤
│ Docs     │ Skip capture-      │ Full capture      │ Full capture + audit    │
│ ceremony │ outcome/learnings  │                   │ log entries             │
└──────────┴────────────────────┴───────────────────┴─────────────────────────┘
```

**Profile detection:** Bootstrap auto-detects based on codebase characteristics (compliance files → strict, domain complexity, CI/CD presence, LOC). Override per-session via `EXOSUIT_PROJECT_PROFILE=lean|standard|strict`.

**Safety is constant across profiles:** TDD enforcement, test-before-ship, all blocking hooks, and secrets detection run identically in all profiles. Lean reduces ceremony, not safety.

### 13.8 Documentation Layer

#### Project Knowledge Base (docs/context/)

```
┌──────────────────────────────────────────────────────────────────────┐
│                      WHAT THE PROJECT IS                             │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────┐  │
│  │ project-overview│  │ product-context │  │ project-structure    │  │
│  │                 │  │                 │  │                      │  │
│  │ Mission, goals, │  │ Domain terms,   │  │ Directory layout,    │  │
│  │ users, scope    │  │ user personas,  │  │ module duties,       │  │
│  │                 │  │ business rules  │  │ file conventions     │  │
│  └─────────────────┘  └─────────────────┘  └──────────────────────┘  │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────┐  │
│  │ tech-context    │  │ system-patterns │  │ error-patterns       │  │
│  │                 │  │                 │  │                      │  │
│  │ Stack, deps,    │  │ Impl patterns,  │  │ Past mistakes,       │  │
│  │ APIs, integra-  │  │ conventions,    │  │ root causes,         │  │
│  │ tion points     │  │ recipes, errors │  │ prevention rules     │  │
│  └─────────────────┘  └─────────────────┘  └──────────────────────┘  │
│                                                                      │
│  Written by: /bootstrap (initial) + /sprint-end (ongoing)            │
│  Read by:    /story-cycle (plan + self-review) + /brainstorm (scoring)│
│  Compounds:  error-patterns grows; system-patterns grows with recipes │
└──────────────────────────────────────────────────────────────────────┘

Companion knowledge stores:

  docs/solutions/              docs/brainstorms/           docs/research/
  ┌──────────────────────┐    ┌──────────────────────┐    ┌───────────────────────┐
  │ What WORKED          │    │ What was EXPLORED    │    │ What was RESEARCHED   │
  │                      │    │                      │    │                       │
  │ Written by:          │    │ Written by:          │    │ Written by:           │
  │ capture-learnings    │    │ /brainstorm          │    │ /research, spikes,    │
  │ (story-cycle Ph.4)   │    │                      │    │ /discover, /phase-    │
  │ Read by:             │    │ Read by:             │    │ review                │
  │ grep-first-explore   │    │ /ideate              │    │ Read by:              │
  │                      │    │                      │    │ context-prime,        │
  │                      │    │                      │    │ /story-cycle,/research│
  └──────────────────────┘    └──────────────────────┘    └───────────────────────┘

  docs/reviews/                docs/reference/             vision/
  ┌──────────────────────┐    ┌──────────────────────┐    ┌───────────────────────┐
  │ What was REVIEWED    │    │ What was DECIDED     │    │ What was DISCOVERED   │
  │                      │    │                      │    │                       │
  │ Written by:          │    │ DECISION_LOG.md      │    │ Written by:           │
  │ /phase-review        │    │ ASSUMPTION_REGISTER  │    │ /discover             │
  │                      │    │                      │    │                       │
  │ Read by:             │    │ Written by:          │    │ Read by:              │
  │ /discover (next      │    │ /discover            │    │ /ideate, /bootstrap,  │
  │ cycle), /phase-review│    │ Read by:             │    │ /phase-review         │
  │                      │    │ /story-cycle, /ideate│    │                       │
  │                      │    │ /phase-review        │    │                       │
  └──────────────────────┘    └──────────────────────┘    └───────────────────────┘
```

#### Key Documentation Files

| File/Directory | Purpose | Written By | Read By |
|---|---|---|---|
| `CLAUDE.md` | Auto-loaded entry point (~100 lines) | `/bootstrap` | Every session |
| `README.md` | Project README (generated or preserved) | `/bootstrap` A4.2, `/discover` 7D | External users, GitHub |
| `FRAMEWORK_README.md` | Framework documentation (renamed from README.md) | `/bootstrap` 0.5 | Reference |
| `CLAUDE.local.md.template` | Personal overrides (gitignored) | User | Every session (if exists) |
| `AGENTS.md` | Symlink → CLAUDE.md (cross-tool compat) | `install.sh` | Cursor, Aider, Windsurf |
| `llms.txt` | LLM-friendly project index | `/bootstrap` | LLM tools |
| `docs/sessions/session-*.md` | Session handoffs | `/handoff` | `/continue` |
| `docs/sessions/.auto-save.md` | Auto-saved state (volatile) | Stop hook | `/continue` |
| `docs/sessions/.failure-state.md` | Interrupted workflow (volatile) | Phase transitions | Stop hook, `/continue` |
| `docs/sessions/.activity-log.jsonl` | Tool usage log (rotated 200) | PostToolUse hook | `/retrospective`, `/weekly-maintenance` |
| `docs/sessions/.story-outcomes.tsv` | Story metrics (code delta, tests, coverage) | `capture-outcome` | `/retrospective` |
| `docs/sessions/.optimization-log.tsv` | Optimization experiment results | `/optimize` | Reference |
| `docs/sessions/.failure-log.jsonl` | Tool failure log (cascading failure detection) | PostToolUseFailure hook | `post-tool-failure.sh` (recovery) |
| `docs/sessions/.audit-log.jsonl` | Strict-profile audit trail | `/story-cycle` (strict) | Compliance |
| `docs/progress.md` | Sprint history + metrics | `/sprint-end`, `/weekly-maintenance` | `/continue`, `/retrospective` |
| `docs/architecture/ARCHITECTURE.md` | System architecture | `/bootstrap` | `/architecture-check` |
| `docs/reference/GROUND_RULES.md` | Architectural MUST/SHOULD principles | `/bootstrap` | `/story-cycle`, `/sprint-end` |
| `docs/reference/BACKLOG_INDEX.md` | Epic status overview | `/ideate`, `/sprint-end` | `/continue`, `/backlog-review` |
| `docs/reference/CODING_STANDARDS.md` | Language-specific conventions | `/bootstrap` | Reference |
| `docs/reference/TESTING_STRATEGY.md` | TDD practices | `/bootstrap` | Reference |
| `docs/reference/DECISION_LOG.md` | Decision tracking with confidence + rationale | `/discover` | `/story-cycle`, `/phase-review` |
| `docs/reference/ASSUMPTION_REGISTER.md` | Assumption tracking with validation plan | `/discover` | `/story-cycle`, `/phase-review` |
| `docs/reference/READINESS_REPORT.md` | 15-principle readiness baseline | `/bootstrap` (Path A) | `/doctor` (progress tracking) |
| `docs/reference/WORKFLOW.md` | Development workflow reference | `/bootstrap` | Reference |
| `docs/reference/GIT_WORKFLOW.md` | Git workflow with examples | `/bootstrap` | Reference |
| `docs/reference/MCP_INTEGRATION.md` | MCP server guide | `/bootstrap` | Reference |
| `docs/reference/PRD_SUMMARY.md` | Product requirements summary | `/bootstrap` (Path B) | Reference |
| `docs/testing/UAT_COVERAGE.md` | UAT test case tracking | `/UAT-cycle` | `/claude-sense-check`, `/manual-test` |
| `docs/technical-debt.md` | Technical debt inventory | `/bootstrap` | `/weekly-maintenance` |
| `docs/adr/` | Architecture Decision Records | `/architecture-check` | Reference |
| `docs/reference/TEAM_WORKFLOW.md` | Team collaboration guide | `/bootstrap` | Reference |
| `docs/reference/API_DOCUMENTATION.md` | API endpoint documentation | `/bootstrap` | Reference |
| `docs/reference/SECRETS_INVENTORY.md` | Secret rotation tracking | `/bootstrap` | `/weekly-maintenance` |
| `core/MANIFEST.md` | Framework file classification | Install | `/framework-upgrade` |

#### GitHub Integration

| File | Purpose |
|---|---|
| `.github/workflows/claude-pr-review.yml` | CI: runs code-quality, test-validator, security-audit on PRs |
| `.github/pull_request_template.md` | PR template with quality gates checklist |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Structured bug report form |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Structured feature request form |
| `.github/CODEOWNERS` | Human review required on tests, security, dependencies |

#### Cross-Tool Compatibility

- **AGENTS.md** → CLAUDE.md symlink for Cursor, Aider, Windsurf
- **llms.txt** — LLM-friendly project index for any tool
- **`.claude/commands/review-pr-ci.md`** — Non-interactive CI PR review command
- **Limitations:** Skills, hooks, and rules are Claude Code-specific. Other tools get CLAUDE.md, AGENTS.md, llms.txt, and documentation only.

---

## 14. File Structure & Inventory

```
project-root/
├── CLAUDE.md                          # Auto-loaded entry point (~100 lines)
├── CLAUDE.local.md.template           # Personal override template
├── AGENTS.md → CLAUDE.md             # Cross-tool compatibility symlink
├── llms.txt                          # LLM-friendly project index
├── install.sh                        # Drop-in installer
├── CHANGELOG.md                      # Release history (machine-parseable for /framework-upgrade)
├── CONTRIBUTING.md                   # Open source contribution guide
├── README.md                         # Public-facing framework documentation
│                                     # (renamed to FRAMEWORK_README.md during /bootstrap)
│
├── .claude/
│   ├── settings.json                 # Hook registration + permissions
│   ├── settings.local.json.template  # Personal override template
│   ├── keybindings.json.template     # Keybinding customization
│   ├── output-styles/framework.md    # Structured engineering output format
│   │
│   ├── agents/                       # 8 native agent personas
│   │   ├── code-reviewer.md, spec-reviewer.md, security-analyst.md
│   │   ├── performance-engineer.md, architecture-reviewer.md
│   │   ├── codebase-explorer.md, research-analyst.md
│   │   ├── integration-tester.md
│   │
│   ├── commands/review-pr-ci.md      # Non-interactive CI PR review
│   │
│   ├── hooks/                        # All POSIX shell — no Python required
│   │   ├── hooks.json                # Plugin mode hook declarations
│   │   ├── session-start.sh          # Environment checks (advisory)
│   │   ├── pre-tool-use.sh           # Dangerous command blocking + advisory warnings
│   │   ├── pre-read-check.sh         # Sensitive file warning (advisory)
│   │   ├── pre-compact.sh            # Session state snapshot before compaction
│   │   ├── post-tool-use.sh          # Activity logging
│   │   ├── post-edit-format.sh       # Auto-format + secrets scan
│   │   ├── post-tool-failure.sh      # Tool failure logging + recovery guidance
│   │   ├── stop.sh                   # Quality gates + auto-save
│   │   ├── user-prompt.sh            # Intent classification
│   │   ├── subagent-stop.sh          # Subagent output validation
│   │   ├── worktree.sh              # Worktree create/remove
│   │   ├── worktree-bash-fix.sh      # Worktree directory fix
│   │   ├── status-line.sh            # Status bar
│   │   ├── rules/                    # 9 rule files: safety, advisory, sensitive-files,
│   │   │                             # debug, skill-suggestions, quality, intent, subagent.*
│   │   ├── lib/hook-guard.sh         # Profile-based hook gating
│   │   ├── lib/paths.sh              # Shell path resolution
│   │   ├── state/                     # Ephemeral state (project-profile, stop-iteration)
│   │   └── tests/                    # Hook test suite (8 test scripts)
│   │       ├── run-all.sh, test-hook-guard.sh, test-install.sh
│   │       ├── test-post-edit-format.sh, test-pre-tool-use.sh
│   │       ├── test-session-start.sh, test-stop.sh, test-user-prompt.sh
│   │
│   ├── prompts/                      # 20 prompt snippets & micro-components
│   │   ├── validate-arguments.md     # Argument parsing and validation
│   │   ├── interactive-ux.md         # AskUserQuestion protocol + progress tracking
│   │   └── error-recovery-central.md # Centralized error recovery patterns
│   ├── rules/                        # 9 path-scoped rule files
│   ├── scripts/file-suggestions.sh   # File suggestion utility
│   │
│   └── skills/                       # 45 skills
│       ├── SKILLS_INVENTORY.md       # Human-readable index
│       ├── SKILL_TEMPLATE.md         # Skill writing conventions
│       ├── skills-registry.json      # Machine-readable registry
│       ├── quickstart/               # Guided framework tour
│       ├── help-me/                  # Natural language skill discovery
│       ├── dashboard/                # Sprint status overview
│       ├── custom-hooks/             # Project-specific hook creation
│       ├── uninstall/                # Clean framework removal
│       ├── performance-check/        # Performance analysis (forked agent)
│       ├── discover/                  # Deep guided elicitation (7 phases, 4 modes)
│       │   ├── SKILL.md
│       │   ├── references/           # scale-guide, question-scaffolding, dimension-sweep,
│       │   │   │                     # external-dependencies, research-protocols,
│       │   │   │                     # engineering-by-archetype, phase-transition-template
│       │   │   └── archetypes/       # 11 archetype question bank files
│       │   └── assets/               # decision-log, assumption-register, phase-walkthrough
│       ├── phase-review/             # Phase transition review
│       │   └── SKILL.md
│       └── <skill-name>/             # SKILL.md + references/ + scripts/ + assets/
│
├── core/
│   └── MANIFEST.md                   # Framework file classification (CORE vs PROJECT)
│
├── docs/
│   ├── CLAUDE.md                     # Directory-level context (+ subdirectory CLAUDE.md files)
│   ├── progress.md                   # Sprint history + metrics
│   ├── technical-debt.md             # Debt inventory
│   ├── architecture/ARCHITECTURE.md  # System architecture
│   ├── adr/                          # Architecture Decision Records
│   ├── context/                      # 6 persistent knowledge base files
│   ├── reference/                    # BACKLOG_INDEX, CODING_STANDARDS, etc.
│   │   ├── backlog/                  # E##-name.md epic files
│   │   ├── TEAM_WORKFLOW.md          # Team collaboration guide
│   │   ├── API_DOCUMENTATION.md      # API endpoint documentation
│   │   └── SECRETS_INVENTORY.md      # Secret rotation tracking
│   ├── sessions/                     # Handoffs + auto-save + activity log
│   ├── plans/                        # Saved plan files
│   ├── testing/UAT_COVERAGE.md       # UAT test tracking
│   ├── solutions/                    # Learnings database
│   ├── brainstorms/                  # Design exploration archive
│   ├── research/                     # Research reports
│   └── reviews/                      # Phase transition review outputs
│
├── scripts/pm/                       # 4 read-only query scripts
│   ├── status.sh, next-story.sh, standup.sh, metrics.sh
│
├── vision/                           # New project braindump flow
│   ├── README.md, BRAINDUMP_PROMPT.md
│
├── scaffold/                         # Template files for new projects (includes README.md template)
│                                     # (cleaned up by /bootstrap A6 after contents installed)
├── .claude-plugin/plugin.json        # Plugin manifest
│
└── .github/                          # CI, PR template, CODEOWNERS, issue templates
```

### File Inventory

| Component | Files |
|---|---|
| Skills (SKILL.md files) | 43 |
| Skill references + assets + scripts | ~67 |
| Rules | 9 |
| Agents | 8 |
| Prompts/micro-components | 20 |
| Hook shell scripts | 13 |
| Hook rules (.patterns/.conf) | 9 |
| Hook tests | 8 |
| Documentation templates | ~28 |
| PM scripts | 4 |
| GitHub config | 5 |
| Root config + plugin + scaffold | ~29 |
| **Total** | **~241** |

---

## 15. Glossary

| Term | Definition |
|---|---|
| **Skill** | Markdown-based slash command (`.claude/skills/<name>/SKILL.md`) providing workflow instructions |
| **Rule** | Path-scoped markdown in `.claude/rules/` — advisory, auto-loaded on file match |
| **Hook** | POSIX shell script on Claude Code events — deterministic, cannot be bypassed |
| **Native Agent** | Persona in `.claude/agents/` running as subagent with restricted tools |
| **Quality Agent Skill** | Forked Explore subagent skill with confidence scoring (`/code-quality`, etc.) |
| **Micro-component** | Reusable prompt snippet in `.claude/prompts/` composed into skills |
| **Prompt Snippet** | User-invocable lightweight prompt (`/review-security`, `/explain-pattern`, `/suggest-tests`) |
| **Forked Context** | Subagent execution mode — isolated context copy, read-only |
| **Plan Mode** | Claude Code's built-in planning mode used during story-cycle Phase 1 |
| **HARD GATE** | Mandatory checkpoint that cannot be skipped regardless of story size/risk |
| **Fast-track** | TRIVIAL + low-risk path: skip Phases 1, 2, 2.5 → direct to Phase 3 |
| **Readiness Gate** | 5 objective pre-condition checks (PASS/FAIL) replacing the old subjective confidence scoring. All must pass to proceed. User can override specific failures. |
| **Hook Guard** | Profile-based gating system (`lib/hook-guard.sh`) — determines whether a hook should run based on project profile, hook profile override, and per-hook disable list |
| **Project Profile** | `lean\|standard\|strict` — controls skill ceremony depth and hook defaults. Set via `EXOSUIT_PROJECT_PROFILE` env var or CLAUDE.md `**Profile:**` line |
| **Hook Profile** | `minimal\|standard\|strict` — controls hook behavior. Derived from project profile (lean→minimal, standard→standard, strict→strict) or overridden via `EXOSUIT_HOOK_PROFILE` |
| **Explanation Mode** | `EXOSUIT_EXPLAIN_MODE=off\|brief\|verbose` — controls hook message verbosity. `verbose` adds WHY (what damage a blocked command causes) and INSTEAD (safer alternative) |
| **Ralph Loop** | Stop hook workflow enforcement — blocks exit when `.failure-state.md` is active (safety valve at configurable iterations, default 5, strict 10) |
| **Archetype** | Project classification (1 of 10+1 types) that drives elicitation style — what questions to ask, what research to run, what success looks like. Examples: Utility, Experiential, Viral, Marketplace |
| **Scale** | Project size classification (Quick Build / Standard / Platform / Pioneering) that drives discovery depth — question count, research depth, documentation level |
| **Discovery Mode** | One of 4 modes selected by scale: Quick Start (~5 min), Guided (20-45 min), Platform (60-120 min), Pioneering (spike-first) |
| **Decision Log** | Persistent record (`docs/reference/DECISION_LOG.md`) of every product and technical decision with confidence level (CONFIRMED / ASSUMED / SPECULATIVE) and rationale |
| **Assumption Register** | Persistent record (`docs/reference/ASSUMPTION_REGISTER.md`) tracking assumptions with impact, validation method, and status (PENDING → VALIDATED / INVALIDATED) |
| **Phase Transition Stories** | Non-code "Review" stories at the end of each epic batch — walkthrough, assumption validation, research refresh, pivot-or-persevere decision, next-phase planning. Creates infinite build→review→discover→build cycle |
| **No-Go** | Explicit declaration of what the project is NOT (from `/discover` Phase 4C). Logged in project-pitch.md, enforced by story-cycle scope-creep detection |
| **Question Scaffolding** | 6 rules governing how /discover asks questions: recognition before recall, example before abstraction, one at a time, scaffold format, escape hatches, adaptive depth |
| **Foundation Stories** | Auto-generated E00 backlog stories from bootstrap readiness gaps |
| **Failure State** | Persisted workflow in `.failure-state.md` for interrupted skill resumption |
| **Context Budget** | Context window portion consumed by framework — managed via lean loading and compaction |
| **Compaction** | Auto-compression with CRITICAL/HIGH/NORMAL/LOW priority levels |
| **MANIFEST** | File classification document (`core/MANIFEST.md`) — CORE vs PROJECT files for upgrade targeting |
| **CHANGELOG** | Machine-parseable version log used by `/framework-upgrade` for targeted upgrades |

---

## 16. Troubleshooting

| Problem | Likely Cause | Fix |
|---|---|---|
| Hooks not firing | settings.json missing or hook script not found | Re-run `install.sh` (or `install.sh --force` for clean reinstall) |
| Missing formatter warnings | Expected — reports once per session, then skips | Install the tool, or run `/doctor` |
| Context exhaustion | Too many large files read | Use `/handoff` + new session; prefer grep-first |
| Stale session state | Old `.auto-save.md` | Delete stale files, run `/continue` fresh |
| Stop hook blocks exit | Ralph Loop: incomplete `.failure-state.md` | Complete workflow, or wait for safety valve (5 iterations default), or set `EXOSUIT_STOP_MAX_ITERATIONS=1` |
| Hooks too noisy | Explanation mode on, or hooks running at wrong profile | Set `EXOSUIT_EXPLAIN_MODE=off`, or `EXOSUIT_HOOK_PROFILE=minimal` for lean projects |
| Hooks too silent | Profile too lean for your needs | Set `EXOSUIT_HOOK_PROFILE=strict` or `EXOSUIT_PROJECT_PROFILE=strict` |
| Specific hook annoying | Want to disable one hook without changing profile | `EXOSUIT_DISABLED_HOOKS="hook-id"` (comma-separated for multiple) |
| Worktree commands fail | `worktree-bash-fix.sh` not registered | Check `settings.json` hook entries |
| Push blocked (framework repo) | Remote still points to template repo | `git remote set-url origin <your-repo>` |
| Sensitive file warnings | `pre-read-check.sh` warns on .env etc. | Expected behavior — secrets shouldn't enter context. Disable with `EXOSUIT_DISABLED_HOOKS="pre-read-check"` |
