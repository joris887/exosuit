# JD-LLM Development Framework v3.0 — Deep Dive

A comprehensive reference explaining every element of the framework, its purpose, how it contributes to the whole, and where to look for optimization opportunities.

---

## Table of Contents

1. [Framework Philosophy](#1-framework-philosophy)
2. [Architecture Overview](#2-architecture-overview)
3. [Entry Points & Configuration](#3-entry-points--configuration)
4. [Enforcement Layers](#4-enforcement-layers)
5. [Skills — Setup & Onboarding](#5-skills--setup--onboarding)
6. [Skills — Sprint Workflow](#6-skills--sprint-workflow)
7. [Skills — Planning & Backlog](#7-skills--planning--backlog)
8. [Skills — Quality & Testing](#8-skills--quality--testing)
9. [Skills — Architecture & Security](#9-skills--architecture--security)
10. [Skills — Maintenance & Retrospective](#10-skills--maintenance--retrospective)
11. [Skills — Testing Workflow (User-Facing)](#11-skills--testing-workflow-user-facing)
12. [Skills — Utility](#12-skills--utility)
13. [Context Management Strategy](#13-context-management-strategy)
14. [Git Workflow & Worktrees](#14-git-workflow--worktrees)
15. [Documentation Architecture](#15-documentation-architecture)
16. [Cross-Tool Compatibility](#16-cross-tool-compatibility)
17. [Optimization Opportunities](#17-optimization-opportunities)
18. [Known Limitations](#18-known-limitations)
19. [Experimentation Log](#19-experimentation-log)

---

## 1. Framework Philosophy

### Core Beliefs

The framework is built on six principles. Each one addresses a specific failure mode observed in AI-assisted development:

| Principle | Failure Mode It Prevents | How |
|---|---|---|
| **TDD-first** | AI writes code that "looks right" but doesn't work correctly | Tests define the contract *before* implementation. The AI can't drift. |
| **Sprint-based** | Unbounded scope, context window exhaustion, loss of focus | Small increments with forced checkpoints (sprint-end) ensure regular integration. |
| **Git-disciplined** | Messy history, broken main, lost work | Feature branches + squash merge + never push to main = always-recoverable state. |
| **Documentation-lean** | Context budget wasted on stale docs | Only create docs when needed. Keep auto-loaded files (CLAUDE.md, progress.md) minimal. |
| **AI-aware** | Hallucinated APIs, weakened tests, phantom packages, over-engineering | Guard rails at every layer: rules block bad patterns, hooks enforce quality, skills guide methodology. |
| **Progressive disclosure** | Loading the entire project context into every conversation | Load only what's needed. Reference files by path. Session files capture state for resumption. |
| **Verification-driven** | AI claims completion without evidence | Evidence before claims, fresh output before completion, task list enforcement. |
| **Context-efficient** | Context window exhaustion during long sessions | Priority-based compaction, context budget awareness heuristics, directory-level context files. |
| **Clarification-first** | LLM makes plausible but incorrect assumptions | Forced `[NEEDS CLARIFICATION]` markers and structured ambiguity scanning make uncertainty visible at planning time. |
| **Ground-rules-governed** | Architectural decisions erode across sprints | Per-project principles (MUST/SHOULD) checked at planning and shipping time. |

### Why This Matters

Claude Code (and any LLM coding tool) has a finite context window. Every token of context loaded is a token that can't be used for reasoning. The framework is designed to:

1. **Minimize context consumption** — CLAUDE.md is 66 lines, not 200. Rules are loaded only when matching files are edited. Skills are loaded only when invoked.
2. **Maximize context utility** — What IS loaded is high-signal: commands, conventions, current focus. No placeholders, no boilerplate.
3. **Preserve context across sessions** — Session handoff files and progress.md ensure no work is lost when context compacts or sessions end.

### Added Value

Without this philosophy, AI-assisted development tends toward: long unfocused sessions → context exhaustion → lost work → weakened tests → technical debt. The framework breaks this cycle by imposing structure.

---

## 2. Architecture Overview

### Three-Layer Design

```
┌─────────────────────────────────────────────────┐
│                  ENFORCEMENT                     │
│  Hooks (deterministic) → Rules (advisory) →      │
│  Settings (configuration)                        │
├─────────────────────────────────────────────────┤
│                   WORKFLOW                        │
│  Skills (29 skills, lean SKILL.md + references/)  │
│  Bootstrap → Sprint → Story → Quality → Ship     │
├─────────────────────────────────────────────────┤
│                 DOCUMENTATION                     │
│  CLAUDE.md (entry) → docs/ (reference) →         │
│  progress.md (state) → sessions/ (handoff)       │
└─────────────────────────────────────────────────┘
```

**Enforcement** guarantees behavior. Hooks run shell scripts — they can't be ignored or "interpreted creatively" by the AI. Rules are loaded automatically and influence behavior strongly but can theoretically be worked around.

**Workflow** guides behavior. Skills are markdown instructions that tell Claude what methodology to follow, what steps to take, what to check. They're the core of the framework.

**Documentation** provides context. CLAUDE.md is auto-loaded. Other docs are loaded on demand. Progress and session files maintain state across conversations.

### How the Layers Interact

1. User invokes `/sprint-start` → **Workflow layer** (skill) runs pre-flight checks
2. User invokes `/story-cycle "add login"` → **Workflow** enters plan mode, picks TDD methodology
3. Claude edits a test file → **Enforcement** (rules) loads `testing.md` rules automatically
4. Claude edits source code → **Enforcement** (hooks) auto-formats the file
5. Claude tries to report completion → **Enforcement** (hooks) runs quality suite first
6. User invokes `/sprint-end` → **Workflow** runs quality gates including test protection
7. Claude tries `git push --force` → **Enforcement** (hooks) blocks the command

---

## 3. Entry Points & Configuration

### CLAUDE.md — The Hub

**File:** `CLAUDE.md` (~104 lines)
**Auto-loaded:** Yes, every conversation
**Added value:** Single source of truth for project-specific configuration

This is the most important file in the framework. It's loaded into every Claude Code conversation automatically. Every line costs context tokens, so it must be ruthlessly concise.

**What it contains:**
- Project overview (filled by /bootstrap)
- Commands table (test, lint, format, build, typecheck)
- Architecture one-liner
- Git workflow rules (4 lines)
- Current focus (updated per sprint)
- Backlog file references
- Testing strategy reference
- Skill quick-reference table
- Important file paths (including ground rules)
- Compaction directive

**What it does NOT contain:**
- Detailed coding standards (those are in `docs/reference/CODING_STANDARDS.md`, loaded only when needed)
- Full testing strategy (in `docs/reference/TESTING_STRATEGY.md`)
- Architecture details (in `docs/architecture/ARCHITECTURE.md`)
- Placeholder comments (removed in v2.0 — they waste tokens)

**Optimization opportunity:** The template CLAUDE.md is ~104 lines before /bootstrap fills it. Monitor actual CLAUDE.md content after /bootstrap runs on real projects — the template placeholders should be replaced with concise content, not expanded. The compaction directive at the bottom is critical — it tells Claude what to preserve when context is compressed.

### .claude/settings.json — Claude Code Configuration

**File:** `.claude/settings.json`
**Added value:** Configures hooks and tool permissions

Currently contains the pre-tool safety hook, session-start hook, activity-logger hook, and project-specific hooks added by bootstrap. The bootstrap skill adds more hooks based on detected stack (formatter, linter, test runner).

**SessionStart hook** (*new in v3.0*): A `SessionStart` event hook that runs `session-start.sh` at the beginning of every Claude Code session. Validates framework integrity, ensures required directories exist, and reports stale session files.

**Activity-logger hook** (*new in v3.0*): A `PostToolUse` event hook that runs `activity-logger.sh` after tool invocations. Logs tool usage patterns (which tools, frequency, timing) to `docs/sessions/.activity-log.jsonl` for retrospective analysis and context budget insights.

**Optimization opportunity:** The hook system is relatively new in Claude Code. As the hook API evolves, this file may need restructuring. Monitor Claude Code release notes.

### .gitignore — What Not to Track

**File:** `.gitignore`
**Added value:** Prevents accidental commits of local overrides and sensitive files

Key framework-specific patterns:
- `CLAUDE.local.md` — Personal overrides that shouldn't be shared
- `.claude/settings.local.json` — Personal Claude Code settings
- `*.session-handoff.md` — Legacy handoff files (new ones go to `docs/sessions/`)

### install.sh — Drop-in Installer

**File:** `install.sh` (executable)
**Added value:** One-command installation for existing projects

Uses `cp -rn` (no-clobber) to avoid overwriting existing files. Creates the AGENTS.md symlink. Appends framework patterns to .gitignore. Prints clear next-step instructions.

**Optimization opportunity:** Currently clones the full repo to a temp directory. Could be optimized to use `git archive` or a release tarball for faster installation. Consider adding a `--update` flag for upgrading existing installations.

---

## 4. Enforcement Layers

### 4.1 Hooks (Deterministic Enforcement)

Hooks are the strongest enforcement mechanism. They execute shell scripts at specific points in the Claude Code workflow. The AI cannot bypass them.

#### pre-tool-safety.sh (PreToolUse)

**File:** `.claude/hooks/pre-tool-safety.sh`
**Trigger:** Before any Bash command executes
**Added value:** Prevents destructive operations that could lose work

**What it blocks:**
- `git push --force` / `git push -f` — Could overwrite remote history
- `git checkout .` — Discards all uncommitted changes
- `git reset --hard` — Discards commits and changes
- `git clean -f` — Permanently deletes untracked files
- `rm -rf /`, `rm -rf ..`, `rm -rf ~` — Catastrophic file deletion
- Package publishing (`npm publish`, `cargo publish`, `twine upload`, `gem push`, `pod trunk push`) — Accidental releases
- Destructive database operations (`DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`) — Data loss
- Mass process killing (`kill -9 -1`, `killall`, `pkill -9`) — System destabilization

**Why this matters:** LLMs sometimes take shortcuts. If a merge conflict is complex, an LLM might try `git checkout .` to "start fresh" — losing all the user's work. This hook prevents that.

**Per-session state tracking** (*new in v2.4*): The hook now tracks which patterns have been blocked in the current session using a state file in `$TMPDIR`. First occurrence shows the full block message; repeated occurrences show "(repeated)" suffix. Stale state files (>24h) are auto-cleaned. This reduces warning fatigue without weakening protection.

**Optimization opportunity:** Monitor blocked commands to see if legitimate operations are being caught. The grep patterns are string-based — more sophisticated parsing could reduce false positives.

#### post-edit-format.sh (PostToolUse)

**File:** `.claude/hooks/post-edit-format.sh`
**Trigger:** After Claude edits or writes a file
**Added value:** Consistent formatting without relying on the AI to remember

**How it works:** Detects file extension, runs the appropriate formatter (prettier, ruff, rustfmt, gofmt, etc.), then runs the linter in auto-fix mode on the same file. Falls back gracefully if no formatter or linter is installed.

**Supported linters (auto-fix):** ruff (Python), eslint/biome (JS/TS), golangci-lint (Go). Rust clippy and Swift swiftlint are skipped because they require full project context.

**Automated secrets detection** (*new in v2.9*): After formatting and linting, the hook scans the edited file for credential patterns: AWS access keys (AKIA...), OpenAI/Stripe-style keys (sk-...), GitHub personal access tokens (ghp_...), private keys (BEGIN PRIVATE KEY), and generic hardcoded credentials. Findings are reported but do NOT block edits. Per-file session state tracking avoids duplicate warnings.

**Hook self-validation** (*new in v2.9*): The hook now declares its requirements in a header comment and includes a `report_missing()` helper that reports missing formatters/linters once per session. This replaces silent degradation with informed degradation.

**Why this matters:** LLMs produce code with inconsistent formatting and occasional lint violations. Auto-formatting and auto-linting after every edit means issues are caught immediately rather than accumulating until sprint-end. The secrets detection adds a deterministic safety net that catches leaked credentials regardless of which skill is running.

**Optimization opportunity:** The secrets detection uses regex patterns — consider adding support for `detect-secrets` when installed for more comprehensive scanning. Monitor false positive rate on the credential patterns.

#### pre-stop-quality.sh (Stop)

**File:** `.claude/hooks/pre-stop-quality.sh`
**Trigger:** Before Claude reports a task as complete
**Added value:** Creates a self-correction loop — if quality checks fail, Claude must fix them before finishing

**How it works:** First auto-saves minimal session state (branch, recent commits, uncommitted/staged changes) to `docs/sessions/.auto-save.md` as a safety net for `/continue`. Then runs lint, typecheck, and test suite. If any fail, exits with error code 1, which prevents Claude from marking the task as done.

**Auto-save session state** (*new in v2.6*): Before running quality checks, the hook writes a lightweight state snapshot. This ensures that even if a session ends abruptly (context exhaustion, crash), the `/continue` skill has breadcrumbs to resume from.

**Why this matters:** Without this, Claude might report "done" with failing tests or lint errors. The stop hook forces self-correction — Claude sees the failures and must fix them before it can complete.

**Optimization opportunity:** Currently all commands are commented out (configured per-project by /bootstrap). The self-correction loop can sometimes lead to infinite loops if the AI can't fix the issue. Consider adding a retry limit or fallback behavior. Monitor how often this hook triggers and whether it leads to productive fixes or loops.

#### session-start.sh (SessionStart) (*new in v3.0*)

**File:** `.claude/hooks/session-start.sh`
**Trigger:** At the start of every Claude Code session
**Added value:** Surfaces configuration issues before they cause mid-session failures

**What it does (all advisory — never blocks):**
1. **Tool existence check:** Verifies tools referenced in CLAUDE.md Commands (test, lint, build, etc.) are available in PATH
2. **Stale session detection:** Warns if `.auto-save.md` is older than 24 hours (suggests using `/continue` instead of starting fresh)
3. **Git state warnings:** Reports if on main/master, detached HEAD, or with uncommitted changes
4. **Hook coverage check:** Warns if Stop or PostToolUse hooks are not configured

**Why this matters:** Without session-start checks, a misconfigured environment is only discovered when a skill or hook fails mid-session. Early advisory warnings surface issues at the point where they're cheapest to fix.

#### activity-logger.sh (PostToolUse) (*new in v3.0*)

**File:** `.claude/hooks/activity-logger.sh`
**Trigger:** After every tool invocation (Bash, Edit, Write, etc.)
**Added value:** Provides observability into tool usage patterns for retrospective analysis

**What it does:**
- Appends a JSON line to `docs/sessions/.activity-log.jsonl` with timestamp, tool name, and target file/command
- Only logs Edit, Write, and Bash invocations (skips other tools)
- Truncates long commands to 120 characters
- Rotates at 200 entries (keeps the most recent; cycles out oldest)
- Falls back to sed-based extraction if jq is unavailable
- Data feeds into `/retrospective` metrics and context budget analysis

**Why this matters:** Understanding which tools are used most frequently, which files are edited repeatedly (churn indicators), and how context budget is consumed across a session enables data-driven framework optimization.

### 4.2 Rules (Advisory Enforcement)

Rules are markdown files with YAML frontmatter specifying which file paths they apply to. When Claude edits a matching file, the rules are loaded into context. They're strong guidance but not technically unbypassable.

#### testing.md

**File:** `.claude/rules/testing.md`
**Paths:** `**/*.test.*`, `**/*.spec.*`, `**/test_*`, `**/tests/**`, `**/conftest.py`, `**/__tests__/**`
**Added value:** Prevents the #1 LLM failure mode: test degradation

**Key rules:**
- Never weaken assertions (the most common and insidious failure)
- Never delete tests without approval
- Never reduce test count
- Every test must have meaningful assertions

**Why this matters:** Research shows that AI coding assistants frequently weaken tests to make them pass. For example, changing `expect(result).toBe(42)` to `expect(result).toBeTruthy()` — the test still passes but now accepts any truthy value. This rule catches that pattern.

**Red flags section:** Lists specific anti-patterns (tautological tests, happy-path-only, testing the mock, etc.) so Claude recognizes them.

**AI-specific anti-patterns** (*new in v2.6*): A dedicated table of AI-generated test failures: hallucinated test APIs, copy-paste assertion drift, weakened assertions to make tests pass, over-specific snapshots, and testing framework internals.

**Optimization opportunity:** The rules are advisory — Claude *can* ignore them if it "decides" the situation warrants it. Consider whether the test protection should be escalated to a hook (deterministic) rather than a rule (advisory). Monitor whether Claude actually follows these rules consistently.

#### documentation.md

**File:** `.claude/rules/documentation.md`
**Paths:** `docs/**`, `**/*.md`
**Added value:** Prevents documentation bloat

**Key rules:** Only create docs when explicitly requested. Update existing over creating new. Keep auto-loaded files lean.

**Reference file size budgets** (*new in v2.9*): Explicit line budgets prevent reference files from silently consuming context as projects grow: individual references ≤200 lines, total per skill ≤500 lines, CODING_STANDARDS ≤200, TESTING_STRATEGY ≤250, GROUND_RULES ≤100, ARCHITECTURE ≤200. When loading references, prefer section-level grep over full file reads.

**Why this matters:** LLMs love generating documentation. Without this rule, Claude will happily create README files, add JSDoc to every function, and generate architectural diagrams nobody asked for. This wastes context and creates maintenance burden. The size budgets prevent progressive disclosure from being undermined by growing reference files.

**Directory-level context** (*new in v2.6*): `.claude-context.md` files in directories provide module-specific context (patterns, conventions, quirks). Story-cycle reads the nearest one when working in a directory. These are never created proactively — only when a user explicitly requests module-specific documentation.

#### security.md

**File:** `.claude/rules/security.md`
**Paths:** `**/*.env*`, `**/auth/**`, `**/security/**`, `**/credentials*`, `**/secrets*`, `**/*password*`, `**/*token*`, `**/*key*`
**Added value:** Reduces AI-introduced vulnerability density by 59-64% (per research)

**Key feature:** CWE checklist of the 10 most common weaknesses in AI-generated code. When Claude edits security-sensitive files, it sees this checklist and checks against it.

**Fix-immediately pattern** (*new in v2.2*): When safety issues are discovered during normal work (exposed secrets, missing .gitignore entries, unsafe permissions), the rule mandates immediate fix without asking or deferring. This prevents broken state from propagating.

**Why this matters:** AI-generated code has measurably higher vulnerability rates in certain categories (hardcoded credentials, injection, path traversal). This checklist creates a "pause and check" moment. The fix-immediately pattern ensures safety issues aren't deferred into a backlog where they might be forgotten.

**Optimization opportunity:** The path patterns are broad — `**/*key*` matches files like `keyboard.ts`. Consider refining. The CWE list could be expanded or tailored per project type (web app vs CLI vs library).

#### verification.md (*new in v2.2*)

**File:** `.claude/rules/verification.md`
**Paths:** `**` (applies everywhere)
**Added value:** Mandates evidence before completion claims

**Key rules:**
- Never claim "tests pass" without showing command output
- Never say "should work" — run the verification command
- Fresh evidence required — "I already ran this" is not sufficient
- Partial verification is not proof

**Why this matters:** Claude frequently reports tasks as complete with "tests pass" or "should work" without actually running the commands. This rule enforces a "show, don't tell" discipline — every completion claim must have supporting command output from the current turn.

**Task completion enforcement** (*new in v2.6*): Before reporting "done", check the task list — ALL tasks must be completed or explicitly deferred with reason. "Almost done" is not done.

**Context budget awareness** (*new in v2.6*): Five heuristics for managing context consumption: summarize after 10+ file reads, discard bulk after exploration phases, prefer targeted grep over full file reads, summarize verbose tool outputs, proactively note findings and move on.

**Context relevance scoring** (*new in v2.7*): A 5-level classification system (ACTIVE, ANCHORED, REFERENCE, STALE, DUPLICATE) for systematically identifying and pruning irrelevant context. Applied at phase transitions, after 5+ file reads, and before compaction. Includes "signs of context rot" detection heuristics to catch performance degradation from accumulated stale context.

**Pre-compaction state persistence** (*new in v2.9*): When context is approaching compaction (15+ turns, large tool outputs), Claude persists session state to `docs/sessions/.auto-save.md` before compaction occurs. After compaction, critical state is verified against the auto-save. This complements the pre-stop hook auto-save (session end) by protecting against mid-session compaction loss.

#### code-slop.md (*new in v2.6*)

**File:** `.claude/rules/code-slop.md`
**Paths:** All source files (`**/*.ts`, `**/*.py`, `**/*.go`, etc. — 15 extensions)
**Added value:** Eliminates low-quality AI-generated comments and code prose

**Key rules:**
- 15 banned comment patterns (e.g., "Initialize the X", "Set up the Y", "Handle the error")
- Obvious comment detection — comments that restate the code
- Code prose anti-patterns — unnecessary docstrings, parameter descriptions that restate types, file-level descriptions, section separators
- When comments ARE required — edge cases, business logic rationale, workarounds with ticket references, non-obvious algorithm choices

**Why this matters:** AI-generated code is plagued by "slop" — comments that add no information ("Initialize the database connection" above `db.connect()`). These waste tokens when re-read and signal low quality. This rule creates a systematic filter.

#### edit-recovery.md (*new in v2.6*)

**File:** `.claude/rules/edit-recovery.md`
**Paths:** `**` (applies everywhere)
**Added value:** Prevents wasted retries when edits fail

**Key rules:**
- Decision tree: "old_string not found" → re-read file; "not unique" → add context; "file modified" → re-read and verify
- ALWAYS re-read before retrying a failed edit
- NEVER retry the exact same edit call
- After 3 failures, pause and reconsider approach

**Why this matters:** Claude sometimes retries failed edits verbatim, wasting turns and context. The decision tree provides a structured recovery path that diagnoses the root cause before retrying.

#### git.md

**File:** `.claude/rules/git.md`
**Paths:** `**` (applies everywhere)
**Added value:** Enforces git discipline consistently

**Key rules:** Never push to main, never force push, conventional commits, squash merge.

**Why this matters:** Git mistakes are hard to undo. A force push can lose teammates' work. Pushing directly to main bypasses CI/CD. These rules prevent the most damaging git operations.

**Optimization opportunity:** The `**` path pattern means this rule is loaded on every file edit. That's intentional (git rules should always be in context) but it does consume tokens. Monitor if any rules are redundant with the pre-tool-safety hook.

#### dependencies.md

**File:** `.claude/rules/dependencies.md`
**Paths:** `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, etc.
**Added value:** Prevents supply chain attacks and phantom package installation

**Key rules:** Never add dependencies without approval. Prefer established packages. Verify packages exist. Flag young packages.

**Why this matters:** LLMs hallucinate package names. They might suggest `npm install react-auth-helper` — a package that doesn't exist, or worse, exists as a typosquatting attack. This rule forces verification.

**Optimization opportunity:** "Well-established" is defined as >1000 weekly downloads and >6 months old. These thresholds may need tuning. Consider integrating with actual registry lookups.

---

## 5. Skills — Setup & Onboarding

### /bootstrap

**File:** `.claude/skills/bootstrap/SKILL.md`
**Purpose:** First-run setup. The single most important skill for adoption.
**Added value:** Turns a generic framework into a project-specific tool in one command.

**Two paths:**

**Path A (Existing Repository):**
1. A1: Detect stack (languages, package manager, test framework, linter, CI/CD)
2. A2: Detect commands (test, lint, format, build)
3. A2.5: Assess documentation state (what exists vs template) — *new in v2.0*
4. A2.6: Assess test coverage baseline — *new in v2.0*
5. A2.7: Assess architecture (module boundaries, entry points) — *new in v2.0*
6. A3: Measure codebase (file counts, test counts)
7. A3.5: Generate architecture overview — *new in v2.0*
8. A3.6: Establish project ground rules — *new in v2.8*
9. A4: Generate configuration (CLAUDE.md, CODING_STANDARDS.md, progress.md)
10. A5: Run /skill-create
11. A5.5: Configure hooks — *new in v2.0*
12. A5.6: Configure rules — *new in v2.0*
13. A6: Clean up templates
14. A7: Present summary

**Path B (New Project):**
1. B1: Check for vision content
2. B2: Guide braindump (if no vision files)
3. B2.5: Accept inline braindump — *new in v2.0* (iterative questioning mode)
4. B3: Generate from vision (PRD, architecture, epics, stories, rules, .gitignore)
5. B4: Present summary

**Why A2.5-A2.7 matter:** The original bootstrap only detected the stack and commands. The new steps assess the project's current state more deeply — is there documentation? What's the test coverage? What does the architecture look like? This gives the developer a baseline to improve from.

**Why A5.5-A5.6 matter:** Without these, hooks and rules are generic. After bootstrap, they're tailored to the detected stack (e.g., prettier configured as the formatter, pytest as the test runner in the stop hook).

**Why B2.5 matters:** The original flow required the user to use a separate AI tool for braindumping, then save files, then re-run bootstrap. The inline mode lets users describe their idea directly and get started faster.

**Reference splitting** (*new in v2.3*): The skill is split into lean SKILL.md (~140 lines) + `references/stack-detection.md` (detection tables and commands) + `references/new-project.md` (Path B workflow). Path A loads stack-detection.md; Path B loads new-project.md. Never both.

**Helper script** (*new in v2.3*): `scripts/detect-stack.sh` automates basic stack detection. Run with `--help` for usage.

**Document quality check** (*new in v2.3*): After generating ARCHITECTURE.md, a fresh sub-agent reviews it from a reader's perspective to catch context blindness.

**Ground rules establishment** (*new in v2.8*): Step A3.6 prompts the user for 3-7 non-negotiable architectural principles, classified as MUST or SHOULD. These are stored in `docs/reference/GROUND_RULES.md` and checked during `/story-cycle` planning (Phase 1e) and `/sprint-end` quality gates. If users have no strong preferences, bootstrap suggests principles based on detected stack.

**Optimization opportunity:** Bootstrap is the first thing users experience. It must be robust. Test it against diverse project types: pure Python, TypeScript monorepo, Rust CLI, Swift iOS app, Go microservice. Each should detect correctly.

---

## 6. Skills — Sprint Workflow

### /sprint-start

**File:** `.claude/skills/sprint-start/SKILL.md`
**Purpose:** Create a clean, verified starting point for new work.
**Added value:** Prevents the "started working on a dirty branch" problem.

**Pre-flight checks:**
1. Check for open PRs (merge if approved, warn if pending)
2. Verify clean working tree (no uncommitted changes)
3. Ensure on main and up to date
4. Verify tests pass on main

**Worktree mode** (*new in v2.0*): Creates a git worktree for parallel development. Each worktree has its own branch and working directory, allowing multiple Claude Code instances to work simultaneously.

**Why pre-flight checks matter:** Without them, developers start work on stale branches, forget about open PRs, or begin with failing tests. Each of these leads to wasted effort or merge conflicts later.

**Conditional test verification** (*new in v2.6*): Step 1d now reads CLAUDE.md Commands section first. If a test command is configured, it runs. If not, it skips with a note: "No test command configured — consider running /bootstrap to set up." This prevents sprint-start from failing in projects without tests.

**Optimization opportunity:** The pre-flight checks are sequential. They could be parallelized (check PRs and verify clean tree simultaneously). Also consider: should sprint-start auto-load the next story from the backlog? Currently it doesn't (intentionally — separation of concerns), but some users might prefer it.

### /story-cycle

**File:** `.claude/skills/story-cycle/SKILL.md`
**Purpose:** Universal story delivery. The core development skill.
**Added value:** Ensures every story follows the right methodology with proper quality gates.

**Seven phases** (*updated in v2.6 — added Phase 0 and Phase 4.5*):
0. **Intent Decomposition** (*new in v2.6*) — Before any exploration, decompose the user's request into ALL distinct deliverables, identify dependencies, suggest splitting compound requests
1. **Plan** (in plan mode) — Research, identify type, write plan with context preservation header
2. **Context Transition** — Selectively prune exploration context, keeping discovery metadata (file paths, edge cases, patterns) while discarding bulk content (full file reads, dead-end searches). Reload coding standards + relevant files fresh.
3. **Execute** — Follow the methodology for the story type (TDD for features, reproduce-first for bugs, etc.)
3.5. **Self-Review** (*new in v2.2*) — Completeness, quality, testing, discipline checklists + spec compliance verification for complex stories
4. **Wrap Up** — Run tests, update docs, commit, print completion report
4.5. **Completion Verification** (*new in v2.6*) — Re-check ALL acceptance criteria with evidence (test output, code references). Loop back to Phase 3 for gaps (max 2 extra passes). Hard gate: do NOT report done until every criterion has evidence.

**Process flowchart** (*new in v2.2*): A flowchart at the top of the skill defines the authoritative process, with decision diamonds for plan approval and self-review pass/fail. Prose sections below provide supporting detail.

**The Context Transition is the most important innovation.** After planning, Claude selectively prunes its context — keeping the *insights* from exploration (~200 tokens of file paths and edge cases) while discarding the *bulk* (~20,000 tokens of full file reads). The plan's "Story-Cycle Context" header (including cumulative `<files-read>` and `<files-modified>` tags) ensures Claude knows it's in a story-cycle, what files it has explored, and what steps remain.

**Recovery guidance** (*new in v2.1*): The skill now includes explicit failure recovery instructions for test failures, context exhaustion, git conflicts, and missing skills — making behavior predictable when things go wrong.

**Hard gates** (*new in v2.2*): A `<HARD-GATE>` block between planning and execution prevents Claude from writing code before plan approval. Red flag tables in the self-review prevent common rationalizations ("tests probably pass", "user wants this fast").

**Self-review** (*new in v2.2*): Phase 3.5 adds inline quality verification during story execution. Checklists cover completeness, quality, testing, and discipline. For stories with 4+ acceptance criteria, Claude must re-read each criterion and cite the implementing code (file:line) and test (file:line), preventing drift between intent and implementation.

**10 story types** with distinct methodologies. This matters because the approach for a Feature (TDD) is fundamentally different from a Refactoring (characterization tests first) or a Spike (explore, no production code required). Using the wrong methodology leads to poor outcomes.

**New in v2.0:**
- Plans must be under 50 lines (prevents context bloat)
- Complex plans are saved to `docs/plans/` for persistence across compaction
- `ultrathink` keyword for complex planning decisions
- Multi-agent TDD guidance for Feature stories (write tests without implementation knowledge)

**Reference splitting** (*new in v2.3*): The skill is split into a lean SKILL.md (~150 lines) with the flowchart, phase skeleton, and hard gates, plus `references/story-types.md` (per-type execution details) and `references/self-review.md` (checklist and red flags). Claude loads references on demand, so a Feature story only loads the TDD instructions — not all 10 story types.

**Conditional environment adaptation** (*new in v2.3*): Phase 3.5 includes fallback instructions for when sub-agents are not available — the self-review is performed manually instead.

**Agent-first file discovery** (*new in v2.4*): Phase 1 now includes a Step 1b that dispatches a lightweight Explore agent to identify the 5–10 most relevant files before deep reading. This narrows the scope before committing context budget, reducing unnecessary token consumption during planning.

**Intent decomposition** (*new in v2.6*): Phase 0 now decomposes compound requests ("refactor auth AND add rate limiting AND create a PR") into distinct deliverables before planning begins. This prevents missing later parts of multi-part requests.

**Parallel research optimization** (*new in v2.6*): When a story touches multiple modules, 2-3 explore agents can be dispatched in parallel with independent questions (API patterns, test conventions, data models), then findings are synthesized before writing the plan.

**Completion verification** (*new in v2.6*): Phase 4.5 adds a self-referential verification loop — re-read every acceptance criterion and provide evidence (test output, file:line reference). If any criterion lacks evidence, loop back to Phase 3 (max 2 extra passes). A hard gate prevents reporting completion without evidence for every criterion.

**Directory-level context** (*new in v2.6*): Phase 1c now checks for `.claude-context.md` files in the target directory and parent directories for module-specific patterns and conventions.

**Cognitive reasoning scaffolds** (*new in v2.7*): Skills now reference a shared library of named reasoning tools (`scope_analysis`, `test_strategy_selection`, `failure_diagnosis`, `architectural_impact`, `plan_completeness`) at critical decision points. Phase 0 uses `scope_analysis` for structured intent decomposition; Phase 1e uses `plan_completeness` for verification; Phase 3 uses `test_strategy_selection` before writing tests. These scaffolds improve reasoning reliability by structuring *how to think* at decision points, not just *what to do*.

**Symbolic state encoding** (*new in v2.7*): The Story-Cycle Context header now uses structured key-value format (`workflow:`, `phase:`, `remaining_steps:`) instead of prose. This survives compaction with higher fidelity because each field is atomic and independently preservable.

**Control flow markers** (*new in v2.7*): Phase 4 now uses `<IF>/<ELSE>` markers for conditional test execution. Phase 4.5 uses `<LOOP>/<HALT>` markers for bounded verification loops. These extend the `<HARD-GATE>` vocabulary to make all control flow equally explicit.

**Phase-specific error recovery** (*new in v2.7*): A dedicated `references/error-recovery.md` provides error/cause/recovery tables for every phase (19 error patterns across 7 phases). Skills reference specific phases: "Consult `references/error-recovery.md` — search for `## Phase 3`."

**Forced clarification markers** (*new in v2.8*): Any uncertain requirement in the plan must be marked with `[NEEDS CLARIFICATION: specific question]` instead of assumed. Maximum 3 markers before triggering a hard gate for user input. The `scope_analysis` reasoning tool now includes ambiguity detection as step 6.

**Structured clarification sub-phase** (*new in v2.8*): A new Phase 1f between plan draft and approval gate applies the `ambiguity_scan` reasoning tool to scan for assumptions across seven categories (scope, data model, UX, non-functional, integration, edge cases, constraints). Top 3-5 questions ranked by impact are presented to the user. Answers integrate into the plan before approval.

**WHAT/WHY vs HOW plan separation** (*new in v2.8*): Plans now require two distinct sections: Specification (WHAT/WHY — user-visible behavior, Given/When/Then acceptance criteria, no technical terms) and Implementation Approach (HOW — files, patterns, technical strategy). A `plan-template.md` reference file enforces this structure. The `plan_completeness` reasoning tool (now Phase 1g) verifies the spec section contains zero implementation details and the implementation section traces to every acceptance criterion.

**Ground rules compliance checking** (*new in v2.8*): Phase 1e checks the plan against `docs/reference/GROUND_RULES.md` if it exists. MUST violations trigger HALT. SHOULD violations require documented justification in an Architectural Violations table.

**Contextual handoff suggestions** (*new in v2.8*): The completion report now includes a Next Steps section with ready-to-use slash commands (next story, sprint-end, handoff) so users can proceed without remembering the workflow sequence.

**Per-phase context loading manifests** (*new in v2.8*): Phase 2 now includes prescriptive manifests listing exactly which files to load (RELOAD) and skip (SKIP) per phase, replacing the previous generic guidance. This prevents unnecessary file reads.

**Fast-track mode** (*new in v3.0*): Phase 0 now classifies story size as TRIVIAL (rename/typo fix, <3 files), SMALL (single-concern change, 3-5 files), or STANDARD (everything else). TRIVIAL stories skip Phase 1 planning and Phase 3.5 self-review entirely — proceed directly from intent decomposition to execution. SMALL stories use a condensed single-paragraph plan instead of the full plan template. Only STANDARD stories follow the complete phase sequence. This eliminates ceremony overhead for simple changes without weakening quality gates for complex work.

**Optimization opportunity:** The context reset is manual — Claude follows the instruction to "clear and reload." In practice, Claude sometimes carries over more context than intended. Consider whether a more forceful reset mechanism is possible. Also: the 50-line plan limit may be too restrictive for complex stories — monitor and adjust.

### /sprint-end

**File:** `.claude/skills/sprint-end/SKILL.md`
**Purpose:** Ship quality code with documentation and clean history.
**Added value:** Prevents shipping untested, undocumented code to main.

**Seven steps:**
1. Discover sprint state from git (no assumptions about prior context)
2. Quality gates (tests, test protection, quality agents)
3. Documentation updates (epics, backlog, progress, CLAUDE.md)
4. Push and create PR
5. Wait for CI
6. Merge and clean up (including worktree cleanup)
7. Sprint complete summary

**Test Protection Gates** (*new in v2.0*):
- **Test count gate:** Tests on branch >= tests on main. Catches test deletion.
- **Coverage delta gate:** Coverage for touched files must not decrease.
- **Assertion density:** Detects weakened assertions.

**Why test protection matters:** Without it, a sprint that "adds 5 features and deletes 3 test files" would pass all other quality gates. The test count gate catches this. The assertion density gate catches the more subtle pattern where tests still exist but have been weakened.

**Recovery guidance** (*new in v2.1*): When quality gates fail, the skill now provides explicit recovery instructions: debug-session for test failures, explicit approval for decreased test count, mandatory fix for security issues, and log-to-technical-debt for deferrable issues.

**Hard gate and red flags** (*new in v2.2*): A `<HARD-GATE>` between quality gates and PR creation prevents proceeding with failures. A red flag table catches rationalizations like "tests mostly pass" and "CI will catch it."

**Process flowchart** (*new in v2.2*): An authoritative flowchart at the top of the skill defines the 7-step process with decision points for quality gates and CI status.

**Reference splitting** (*new in v2.3*): Quality gate details (test protection specifics, quality agent dispatch, recovery instructions, red flags) moved to `references/quality-gates.md`. SKILL.md stays lean with the flowchart and step skeleton.

**Helper script** (*new in v2.3*): `scripts/test-count-delta.sh` automates the test count comparison between branch and main. Supports auto-detection and explicit test commands. Run with `--help` for usage.

**"Assume problems" QA framing** (*new in v2.3*): Quality gates step now opens with: "Assume there are problems. Your job is to find them."

**CI fallback** (*new in v2.3*): If no CI is configured, the skill proceeds with local quality gate results instead of stalling.

**Parallel quality gate dispatch** (*new in v2.4*): Quality agents (code-quality, test-validator, security-audit) now run simultaneously instead of sequentially, saving ~60% wall-clock time and ensuring each agent has a truly independent perspective.

**Multi-perspective code review** (*new in v2.4*): For significant sprints (10+ files), 2–3 code-reviewer agents can be dispatched in parallel with different review lenses (correctness, conventions, security). Issues flagged by 2+ independent reviewers are auto-elevated to Critical.

**Confidence-based filtering** (*new in v2.4*): All quality agents now score findings 0–100. Only findings ≥80 are actionable. This reduces noise and focuses sprint-end on genuine issues.

**Expanded graceful degradation** (*new in v2.6*): The skill now includes a degradation table for all optional dependencies: sub-agents, CI pipeline, test runner, linter, type checker, and `gh` CLI. Each entry specifies the fallback behavior (e.g., "Skip lint check, note in PR body"). This prevents sprint-end from stalling when a tool is missing.

**Project state adaptation** (*new in v2.6*): Before running quality gates, sprint-end reads CLAUDE.md Commands section to determine which gates are applicable. If no test command exists, the test gate is skipped (noted in PR body). If no build command exists, the build step is skipped. This prevents failures in projects that haven't configured all tools.

**Control flow markers** (*new in v2.7*): Step 5 (CI) and Project State Adaptation now use `<IF>/<ELSE>` markers instead of prose conditionals, making the conditional logic machine-parseable and less likely to be skipped.

**Phase-specific error recovery** (*new in v2.7*): A dedicated `references/error-recovery.md` provides error/cause/recovery tables for all 6 steps (18 error patterns). Quality gate failures, push rejections, CI failures, and merge conflicts each have specific recovery actions.

**Micro-component references** (*new in v2.7*): Project State Adaptation now references the `discover-commands` micro-component from `.claude/prompts/` for standardized command extraction from CLAUDE.md.

**Ground rules compliance gate** (*new in v2.8*): Quality gates now include ground rules compliance — verifying sprint changes don't introduce untracked violations of MUST principles.

**Handoff suggestions** (*new in v2.8*): Sprint complete summary now includes contextual next-step suggestions (sprint-start, retrospective, handoff).

**Dynamic quality agent scaling** (*new in v3.0*): Sprint-end now classifies sprint scope before dispatching quality agents: Minimal (1-2 files, config-only changes — skip quality agents entirely), Small (3-5 files — single code-quality agent only), Standard (6-15 files — code-quality + test-validator), Large (16+ files or security-sensitive — all agents including security-audit + multi-perspective review). This prevents over-analysis of trivial sprints while ensuring thorough review of large changes.

**PR template** (*new in v3.0*): Sprint-end now uses `.github/pull_request_template.md` when creating PRs via `gh pr create`. The template includes structured sections for summary, changes, testing, and review checklist — ensuring consistent PR quality without relying on the LLM to remember what to include.

**Optimization opportunity:** The quality agents run as forked contexts — monitor their usefulness and whether confidence scoring effectively reduces false positives.

### /continue

**File:** `.claude/skills/continue/SKILL.md`
**Purpose:** Resume development without losing context.
**Added value:** Prevents the "where was I?" problem that wastes the first 15 minutes of every session.

**How it works:**
1. Read latest session handoff file from `docs/sessions/` (*new in v2.0*)
1.5. Reload working context from file access log (*new in v2.1*) — selectively reads modified files, context-relevant reads, and skips investigated-only files
2. Assess git state (branch, changes, PRs)
3. Assess project state (progress.md, backlog)
4. Determine continuation point
5. Handle pending PRs
5.5. Health dashboard (*new in v2.1*) — shows test status, last commit time, open changes count, session file age
6. Quick verification (run tests)
7. Present options and wait for direction

**Session file reading** (*new in v2.0*): The continue skill reads structured session files written by /handoff. These contain: completed work, pending items, next steps, files to load, and warnings.

**Smart context reload** (*new in v2.1*): Using the enriched file access history from /handoff (Modified, Read, Investigated categories), /continue selectively reloads only the files that matter — avoiding redundant exploration of files already investigated last session.

**Health dashboard** (*new in v2.1*): Before presenting options, shows a quick health pulse so developers immediately know whether things are green.

**Optimization opportunity:** The continue skill loads several files (session, progress, backlog). This front-loads context consumption. Consider a "light continue" mode that only reads git state and the session file, skipping the full backlog scan.

### /handoff

**File:** `.claude/skills/handoff/SKILL.md`
**Purpose:** End a session without losing context.
**Added value:** Creates a structured handoff document that the next session can read.

**What it saves** (*enhanced in v2.0, enriched in v2.1*):
- Git state (branch, uncommitted changes, PR status)
- Work completed and in-progress
- Key decisions with rationale
- Blockers and issues
- Files accessed with three categories (*new in v2.1*): Modified (what changed and why), Read (context-relevant for resume), Investigated (can skip on resume)
- Test status
- Next steps (minimal first action — very specific)
- Files to load on resume
- Warnings and gotchas

**Saved to:** `docs/sessions/session-YYYY-MM-DD.md`

**Why structured files matter:** The old handoff generated a session summary in the conversation. When the conversation ended, it was gone. The new approach writes to a file that persists and can be read by /continue.

**Document quality check** (*new in v2.3*): After generating the session file, a fresh sub-agent reviews it from a reader's perspective — "Can I understand what was done? Are next steps actionable? Is any critical context missing?"

**Optimization opportunity:** Session files accumulate. Consider auto-archiving sessions older than 2 weeks. Also: should the handoff skill auto-commit the session file? Currently it doesn't — the user might want to review first.

---

## 7. Skills — Planning & Backlog

### /brainstorm (*new in v2.2*)

**File:** `.claude/skills/brainstorm/SKILL.md`
**Purpose:** Structured design exploration before story decomposition.
**Added value:** Prevents building the wrong thing by exploring alternatives first.

**Six steps:**
1. Explore the problem space (what, who, why, constraints)
2. Research the codebase (existing patterns, architecture constraints)
3. Propose 2-3 alternative approaches with tradeoffs
4. Identify risks and open questions
5. Present design for approval
6. Next steps (invoke /ideate, save design, or create spikes)

**Hard gate:** A `<HARD-GATE>` prevents story decomposition or implementation until the user approves a design approach.

**When to use:** For complex features where the architecture decision matters more than the implementation details. For simple features, skip brainstorm and go directly to `/ideate`.

**Workflow:** `/brainstorm` → design approval → `/ideate` → stories → `/sprint-start` → `/story-cycle`

### /ideate

**File:** `.claude/skills/ideate/SKILL.md`
**Purpose:** Transform ideas into properly typed, scoped backlog stories.
**Added value:** Prevents the "one giant story" anti-pattern and ensures every story has testing strategy.

**Key features:**
- 10 story types with templates
- Story structure: description, AC, skills, testing approach, verification, file hints, non-goals, dependencies
- Dependency-ordered output
- E2E test strategy for multi-story features

**Story sizing constraint** (*new in v2.0*): Each story must fit within a single Claude Code context window (1-3 hours, 5-8 files max). This is critical — a story that touches 20 files will exhaust the context window before completion, leading to partial implementations and lost context.

**Why non-goals matter:** LLMs are scope-creep machines. If a story says "add login form" without non-goals, Claude might also add: password reset, remember me, OAuth, 2FA. Explicit non-goals prevent this.

**Document quality check** (*new in v2.3*): Before presenting stories for approval, a fresh sub-agent reviews the decomposition from an implementer's perspective — "Is each story clear enough to start work? Are acceptance criteria testable?"

**Story template** (*new in v2.8*): Stories now follow a structured template in `references/story-template.md` with user-centric framing (As a/I want/So that), Given/When/Then acceptance criteria, independent testability requirement, priority justification, and anti-pattern guidance.

**Optimization opportunity:** The "1-3 hours, 5-8 files" sizing constraint is a heuristic. Track actual story completion rates — are stories consistently finishing within context? If many stories require multiple sessions, the sizing guidance may need tightening. Conversely, if stories are trivially small, loosen it.

### /skill-create

**File:** `.claude/skills/skill-create/SKILL.md`
**Purpose:** Generate technology-specific skills from the actual codebase.
**Added value:** Gives Claude project-specific knowledge about the tech stack.

**Classification system:**
| Category | Example | Action |
|---|---|---|
| Core Framework (>20%) | React, Django | Skill + reference doc |
| Major Library | Prisma, Redis | Skill only |
| Build/Dev Tool | webpack, jest | Skill if complex |
| Minor Dependency | lodash | Skip |

**New in v2.0:**
- Also generates path-scoped rules for detected file types
- Configures hooks for detected formatters and linters
- Creates per-module rules if major modules have distinct conventions

**Why this matters:** Generic LLM knowledge about "React" is different from "React 18.2 in this project using server components with Zustand for state management." Project-specific skills bridge that gap.

**Co-located references** (*new in v2.3*): Generated tech skills now store reference docs in `.claude/skills/<tech>/references/` (co-located with the skill) instead of `docs/reference/tech/`. This keeps skills self-contained and allows relative path references. SKILL.md stays under 100 lines with pointers to detailed content.

**"Common Mistakes — NEVER" table** (*new in v2.3*): Prevents common skill creation anti-patterns like generic content Claude already knows, skills >150 lines without references, and examples from training data instead of the actual codebase.

**Scaffolding and registry scripts** (*new in v2.5*): `scripts/init-skill.sh` scaffolds a new skill directory with SKILL.md template (including YAML frontmatter), references/, scripts/, and assets/ subdirectories. `scripts/update-registry.sh` walks all skills and generates `skills-registry.json` from YAML frontmatter — a machine-readable index of all skills.

**Optimization opportunity:** Monitor the context cost of generated tech skills when auto-invoked. The reference splitting should keep SKILL.md lean, but verify that Claude actually reads the references when needed.

---

## 8. Skills — Quality & Testing

### /code-quality

**File:** `.claude/skills/code-quality/SKILL.md`
**Purpose:** Analyze complexity, duplication, and pattern consistency.
**Agent type:** Explore (forked context)
**Added value:** Catches quality issues that tests don't cover.

**When invoked:** After code changes (auto-invocable), during sprint-end quality gates.

**Key checks:**
- Functions with cyclomatic complexity > 10
- Code duplication patterns
- Pattern consistency (are similar things done consistently?)

**Why forked context matters:** Quality analysis loads a lot of code to compare patterns. Running it in a forked context (separate Claude instance) prevents this from polluting the main conversation's context.

**v2.3 additions:** "Assume problems exist" QA framing, "Common Mistakes — NEVER" table, and `--help` first pattern for CLI tools.

**v2.4 additions:** Confidence-based scoring (0–100) with ≥80 threshold for actionable findings. `<example>` block triggers for better auto-invocation reliability.

**Dead code detection** (*new in v2.9*): The analysis process now includes dead code detection — unused exports, orphaned functions, unreferenced modules. Uses language-specific tools when available (knip/ts-prune for JS/TS, vulture for Python) with manual grep-based fallback. Findings use the existing confidence scoring (≥80 actionable). Also added to `/weekly-maintenance` as a periodic check.

**Tool restrictions** (*new in v3.0*): The code-quality agent is restricted to Read, Glob, and Grep tools only — no Bash, no Edit, no Write. This ensures the agent analyzes without modifying code, preventing accidental changes during quality review.

### /test-validator

**File:** `.claude/skills/test-validator/SKILL.md`
**Purpose:** Validate that tests are meaningful, not just present.
**Agent type:** Explore (forked context)
**Added value:** Catches the subtle ways AI degrades test quality.

**New in v2.0 — Degradation Detection:**
- **Weakened assertions:** `toBeTruthy()` replacing `toBe(42)` — technically passes but accepts any truthy value
- **Deleted tests:** Test blocks removed or `skip`/`xit` added without reason
- **Tautological tests:** Tests that always pass (e.g., asserting on mock return values)
- **Assertion density:** Each test should have ≥1.5 assertions on average

**Why this matters:** Test count and coverage can remain identical while test quality drops to zero. A test that asserts `expect(true).toBe(true)` contributes to coverage and count but validates nothing. The degradation detection catches these patterns.

**v2.3 additions:** "Assume problems exist" QA framing, "Common Mistakes — NEVER" table, and `--help` first pattern for CLI tools.

**v2.4 additions:** Confidence-based scoring (0–100) with ≥80 threshold for actionable findings. `<example>` block triggers for better auto-invocation reliability.

**Tool restrictions** (*new in v3.0*): The test-validator agent is restricted to Read, Glob, Grep, and Bash (for running the test suite) — no Edit or Write. The agent validates test quality but cannot modify test files.

**Optimization opportunity:** The assertion density ratio of 1.5 is a heuristic. Track across projects — some testing styles (BDD with nested describes) naturally have lower assertion density. Consider making this configurable per project.

### /security-audit

**File:** `.claude/skills/security-audit/SKILL.md`
**Purpose:** Security review for sensitive code.
**Agent type:** Explore (forked context, with Bash access for security scanning tools)
**Added value:** Catches vulnerabilities that functional tests miss.

**New in v2.0:**
- **CWE checklist:** Top 10 vulnerabilities in AI-generated code, presented as a table with specific things to check
- **Phantom package detection:** Verifies that all imported packages actually exist in the registry and aren't typosquatting attacks
- **Hardcoded secret patterns:** Regex patterns for common secret formats

**Why the CWE checklist matters:** AI-generated code has measurably higher rates of CWE-798 (hardcoded credentials), CWE-79 (XSS), and CWE-89 (SQL injection). The checklist creates a systematic check rather than relying on the AI to "remember" security best practices.

**Why phantom package detection matters:** LLMs hallucinate package names. `npm install react-auth-helper` installs... what? If that package was registered as a typosquatting attack, it could contain malware. Verification prevents this.

**v2.4 additions:** Confidence-based scoring (0–100) with ≥80 threshold for actionable security findings. `<example>` block triggers for better auto-invocation reliability.

**AI-specific security anti-patterns** (*new in v2.6*): A dedicated table in the security rule for AI-specific vulnerabilities: phantom packages (hallucinated npm/pip packages), typosquatted dependencies (names similar to popular packages), permissive CORS (allowing `*` origin), logging sensitive data (passwords/tokens in logs), and disabled SSL verification (for "development convenience").

**Tool restrictions** (*new in v3.0*): The security-audit agent is restricted to Read, Glob, Grep, and Bash (for running security scanners like `npm audit`, `pip-audit`, `cargo audit`) — no Edit or Write. The agent identifies vulnerabilities but cannot modify code.

**Optimization opportunity:** The phantom package check is manual (grep imports, verify against registry). Consider adding a script that automates this. Also: the CWE checklist is generic — consider creating project-type-specific checklists (web app, API, CLI, mobile).

---

## 9. Skills — Architecture & Security

### /architecture-check (*new in v2.0*)

**File:** `.claude/skills/architecture-check/SKILL.md`
**Purpose:** Validate that code follows documented architecture.
**Agent type:** Explore (forked context)
**Added value:** Prevents architectural drift, the slow erosion of module boundaries.

**What it checks:**
- Module boundary violations (cross-layer imports)
- Circular dependencies
- Dependency direction (do imports flow the right way?)
- New modules not documented in ARCHITECTURE.md
- Missing modules (documented but don't exist)

**Cognitive reasoning scaffold** (*new in v2.7*): Step 2 now references the `architectural_impact` reasoning tool for structured assessment of module boundaries, dependency direction, and responsibility scope.

**ADR generation:** When architectural drift is detected, suggests creating an Architecture Decision Record documenting the change and its implications.

**Fitness function suggestions:** For each architectural rule, suggests an automatable test (e.g., a script that fails if a circular dependency is introduced).

**Why this matters:** Architecture is documentation until it's enforced. Without regular checks, module boundaries erode — the "just this once" import becomes standard practice, and eventually the clean architecture is a monolith again.

**Optimization opportunity:** The import analysis is language-specific and currently relies on grep patterns. For more accurate analysis, consider integrating with language-specific tools (madge for JavaScript, pydeps for Python, etc.). Also: architecture checking is expensive (loads many files). Consider running it only at sprint-end, not after every commit.

---

## 10. Skills — Maintenance & Retrospective

### /weekly-maintenance

**File:** `.claude/skills/weekly-maintenance/SKILL.md`
**Purpose:** Prevent slow quality degradation with regular health checks.
**Added value:** Catches issues before they compound.

**Six steps:**
1. Codebase health (complexity, duplication, churn, dead code)
2. Code quality agent review
3. Documentation review (accuracy, efficiency, drift)
4. Dependency review (outdated, vulnerable, recently added)
5. Weekly summary (update progress.md)
6. Plan next week

**Dead code detection** (*new in v2.9*): Step 1 now includes dead code scanning — unused exports, orphaned functions. Run monthly or when codebase exceeds 5K LOC.

**Dependency governance** (*new in v2.0*):
- Run vulnerability scanners (npm audit, pip-audit, cargo audit)
- Flag packages less than 7 days old (supply chain risk)
- Check lockfile sync
- Report on recently added dependencies with age and download counts

**Why regular maintenance matters:** Quality degrades slowly. One complex function this week, two next week. Dependencies go stale. Documentation drifts from implementation. Weekly checks catch the early signals.

**Optimization opportunity:** 1-2 hours is a significant time investment. Consider a "quick maintenance" mode (30 minutes) that only checks the most critical items (tests pass, no high-severity vulnerabilities, progress.md is current). Full maintenance can be monthly.

### /doctor (*new in v2.9*)

**File:** `.claude/skills/doctor/SKILL.md`
**Purpose:** Quick framework health check — validates that configuration, hooks, dependencies, and documentation are consistent and functional.
**Added value:** Catches misconfigurations early (missing commands, broken hooks, stale docs) before they cause failures in other skills.

**Six check categories:**
1. **Command Verification** — Confirms CLAUDE.md commands (test, lint, format, build, typecheck) actually work
2. **Hook Dependencies** — Validates each hook's declared requirements are installed (prettier, eslint, etc.)
3. **Rule Relevance** — Checks that rule glob patterns match actual files in the project
4. **Skill Dependencies** — Validates `requires` fields in skill YAML frontmatter
5. **Documentation Freshness** — Flags docs not updated in >30 days
6. **Git State** — Reports uncommitted changes, unpushed commits, diverged branches

**Output format:** Structured health report with PASS/WARN/FAIL per check and actionable fix suggestions.

**When to use:**
- After `/bootstrap` to verify setup
- When a skill or hook fails unexpectedly
- After updating framework files manually
- As a periodic sanity check

### /retrospective

**File:** `.claude/skills/retrospective/SKILL.md`
**Purpose:** Data-driven process improvement.
**Added value:** Prevents repeating the same mistakes sprint after sprint.

**New in v2.0 — Metrics Dashboard:**

| Metric | What It Measures | Why It Matters |
|---|---|---|
| Test count trend | Tests added/removed per sprint | Catches gradual test erosion |
| Coverage trend | Coverage delta per sprint | Catches coverage regression |
| Code duplication | Duplicate code percentage | Catches copy-paste development |
| Churn rate | Files added then quickly changed | Indicates rework / poor planning |
| Security findings | Vulnerabilities per sprint | Catches security regression |
| Stories delivered | Velocity per sprint | Measures throughput |
| AI suggestion survival rate | Code from AI that survives review | Measures AI contribution quality |
| Context resets | Compaction/clear events | Measures context management |

**Why AI-specific metrics matter:** Traditional retrospectives don't ask "was the AI helpful?" These metrics reveal whether the AI is contributing quality code (high survival rate) or creating rework (high churn, low survival).

**Optimization opportunity:** Most of these metrics require manual collection. Consider automating them with a `metrics.sh` script that git-log analysis to compute churn, survival rate, etc.

---

## 11. Skills — Testing Workflow (User-Facing)

These skills handle the human-driven testing side of development — generating test plans, processing manual test feedback, and executing formal UAT test cases. They complement the automated quality agents (code-quality, test-validator, security-audit) which focus on code-level analysis.

### /manual-test

**File:** `.claude/skills/manual-test/SKILL.md`
**Purpose:** Generate a structured test plan for manual user testing.
**Added value:** Bridges the gap between automated tests and user experience validation.

**How it works:**
1. **Gather context** — Reads recent changes (git log), known issues (backlog), acceptance criteria (current stories), and existing UAT coverage
2. **Pre-flight** — Runs automated test suite to establish baseline
3. **Generate test plan** with three sections:
   - **Regression tests** — Verify existing functionality still works after recent changes
   - **Known issue checks** — Test known issues from the backlog
   - **Exploratory testing** — Unscripted testing areas based on recent change patterns
4. **Present plan** with instructions to report findings via `/testing-cycle`

**Why this matters:** Automated tests can verify logic but can't test user experience — is the UI intuitive? Does the flow feel right? Are error messages helpful? Manual testing fills this gap, and this skill provides the structure so testers know what to focus on.

### /testing-cycle

**File:** `.claude/skills/testing-cycle/SKILL.md`
**Purpose:** Process one item of user testing feedback.
**Added value:** Structured response to user-reported issues — prevents ad-hoc bug-fixing that skips classification.

**Four steps:**
1. **Classify feedback** into one of four types:
   - **Bug (Critical)** — Blocks functionality, fix immediately
   - **Bug (Minor)** — Incorrect but non-blocking, fix or log
   - **Gap** — Missing functionality, log to backlog
   - **Test Correction** — Test expectation was wrong, update test
   - **Enhancement** — Not a bug, log as future improvement
2. **Act by type** — Investigate, write test, fix, or log to backlog
3. **Verify** — Run tests, confirm fix with user if applicable
4. **Report** — Summarize findings and actions taken

**When to use:** After manual testing when a user reports an issue. Each `/testing-cycle` invocation handles one feedback item — invoke multiple times for multiple items.

### /UAT-cycle

**File:** `.claude/skills/UAT-cycle/SKILL.md`
**Purpose:** Execute a formal UAT test case with tracked results.
**Added value:** Formal acceptance testing with audit trail in `docs/testing/UAT_COVERAGE.md`.

**Five steps:**
1. **Select test case** from `docs/testing/UAT_COVERAGE.md` (by ID or description)
2. **Execute test** — User performs the test steps, reports pass/fail
3. **Process findings** — Classify and act on failures (same classification as testing-cycle)
4. **Update UAT coverage** — Mark test case status in UAT_COVERAGE.md
5. **Close cycle** — Completion report with pass/fail summary

**When to use:** For pre-defined acceptance test cases that need tracked results. Typically used before major releases or at sprint boundaries.

**How the three skills work together:**

```
/manual-test → generates test plan → user tests manually → /testing-cycle (per issue) → /sprint-end
```

Or for formal UAT:
```
/UAT-cycle TC-001 → /UAT-cycle TC-002 → ... → results in docs/testing/UAT_COVERAGE.md
```

**When to use which:**
- `/manual-test` — Generate a test plan when you need to decide *what* to test
- `/testing-cycle` — Process ad-hoc findings from exploratory or manual testing
- `/UAT-cycle` — Execute pre-defined test cases with formal tracking

**Optimization opportunity:** The testing workflow skills are less mature than the development workflow skills. Monitor usage patterns — are users using all three skills or just one? Are the test plans useful? Do users prefer /testing-cycle or /UAT-cycle?

---

## 12. Skills — Utility

### /debug-session (*significantly enhanced in v2.2*)

**File:** `.claude/skills/debug-session/SKILL.md`
**Purpose:** Systematic debugging with mandatory root cause investigation.
**Added value:** Prevents guess-and-check debugging loops.

**Five phases:**
1. **Root Cause Investigation** (MANDATORY) — Read full error, reproduce, check recent changes, trace backward from symptom to source
2. **Pattern Analysis** — Find working examples, compare against broken code, identify differences
3. **Hypothesis and Testing** — Single hypothesis, one variable at a time, explicit stopping points after 3 failed attempts
4. **Fix Implementation** — TDD: write reproduction test (must fail), implement minimal fix, verify
5. **Verify and Document** — All tests pass, error no longer reproducible, commit with root cause explanation

**Hard gate:** A `<HARD-GATE>` between investigation and fix prevents attempting fixes without identified root cause.

**Stopping points table:** Explicit situations where Claude must stop and reconsider (3+ failed fixes, "just try this", multiple changes at once).

**Cognitive reasoning scaffold** (*new in v2.7*): Phase 1d now references the `failure_diagnosis` reasoning tool — a structured backward trace that scaffolds the thinking process for root cause identification.

**Explicit halt condition** (*new in v2.7*): A `<HALT>` marker in Phase 3 triggers after 3 failed fix attempts, forcing a return to Phase 1 for re-investigation instead of continued guessing.

**Phase-specific error recovery** (*new in v2.7*): A dedicated `references/error-recovery.md` provides error/cause/recovery tables for all 5 phases (15 error patterns). Covers: unreproducible errors, wrong hypotheses, failed fixes, and regression introduction.

**Supporting references** (in `references/` subdirectory):
- `references/root-cause-tracing.md` — Backward tracing technique through call stacks, multi-component tracing, git bisect
- `references/condition-based-waiting.md` — Replacing arbitrary timeouts with condition polling for deterministic tests
- `references/error-recovery.md` — Phase-specific error/cause/recovery decision tables

### /skill-eval (*new in v2.4*)

**File:** `.claude/skills/skill-eval/SKILL.md`
**Purpose:** Test, measure, and compare skill effectiveness.
**Added value:** Enables data-driven skill improvement instead of qualitative observation.

**Three modes:**
- **eval**: Test a skill against a known scenario, grade output against evaluation criteria
- **compare**: Blind A/B test two versions of a skill against the same scenario, pick the winner
- **metrics**: Analyze a skill's evaluation readiness — check for evaluation criteria, identify pressure scenarios, assess hard gate testability

**Why this matters:** Previously, skill iterations (v2.0→v2.3) were based on qualitative observation. This enables systematic verification that skill changes actually improve outcomes, and catches regressions.

### /refine-loop (*new in v2.4*)

**File:** `.claude/skills/refine-loop/SKILL.md`
**Purpose:** Iterative self-improvement on deliverables until completion criteria are met.
**Added value:** Formalizes the "write → review → improve" loop with safety controls.

**How it works:**
1. Execute task to produce first draft
2. Self-review against completion criteria
3. If not met and iterations remain: identify SPECIFIC improvements, apply, re-evaluate
4. Hard gate: "make it better" is not a valid improvement — must name the specific gap
5. Default max 5 iterations; produces completion report with iteration log

**When to use:** Polishing docs, refining prompts, iterating on complex designs. Not for story-cycle execution (use story-cycle's own phases).

### Quality Agent Tool Restrictions (*new in v3.0*)

Quality agents (code-quality, test-validator, security-audit) now have explicit tool restrictions that enforce the principle of least privilege:

| Agent | Allowed Tools | Rationale |
|---|---|---|
| code-quality | Read, Glob, Grep | Analysis only — no code modification, no command execution |
| test-validator | Read, Glob, Grep, Bash | Needs Bash to run the test suite, but cannot modify test files |
| security-audit | Read, Glob, Grep, Bash | Needs Bash for security scanners (npm audit, pip-audit, etc.), but cannot modify code |

This prevents quality agents from accidentally modifying the codebase during analysis and ensures their output is purely advisory.

### /undo-work (*new in v3.0*)

**File:** `.claude/skills/undo-work/SKILL.md`
**Purpose:** Safely revert failed implementation attempts and restore a clean working state.
**Added value:** Prevents manual git archaeology when an approach fails.

**Three rollback levels:**

| Level | Flag | What It Does | Recoverable? |
|---|---|---|---|
| **Soft** | `--soft` | Stash uncommitted changes | Yes — `git stash pop` |
| **Hard** | `--hard` | Discard uncommitted changes | No |
| **Story** | `--story` | Reset branch to before story commits | No |

**Five steps:**
1. **Assess current state** — Branch, uncommitted changes, commits since branch point
2. **Confirm scope with user** — Show exactly what will be lost (hard gate — never proceeds without approval)
3. **Execute rollback** — Apply the chosen level
4. **Verify clean state** — Confirm the working tree is clean
5. **Document learnings** (optional) — Note what went wrong for future reference

**Why this matters:** When an implementation approach fails, developers often waste time manually reverting changes across multiple files. This skill provides a structured, safe way to "undo and try again" without losing unrelated work. The confirmation gate prevents accidental data loss.

### /commit, /fix-issue, /pr-status

Small, focused utility skills:

| Skill | What It Does | Added Value |
|---|---|---|
| `/commit` | Generates conventional commit message | Consistent commit history |
| `/fix-issue` | Reads GitHub issue, creates fix with TDD | Structured bug-fixing workflow |
| `/pr-status` | Checks PR status and CI | Quick status check without leaving the terminal |

---

## 13. Context Management Strategy

### The Context Budget Problem

Claude Code has a finite context window. Everything loaded into it — CLAUDE.md, skill content, file contents, conversation history — consumes tokens. When the budget is exhausted, context compacts (older messages are summarized), losing detail.

### Framework's Approach

**Minimize auto-loaded content:**
- CLAUDE.md: ~104 lines (was 173 in v1.0)
- progress.md: Minimal template, filled per sprint
- BACKLOG_INDEX.md: Index only, epic files loaded on demand

**Progressive disclosure:**
- Full coding standards only loaded when a skill requests them
- Architecture doc only loaded when architecture-check runs
- Technology skills only loaded when working with that technology

**Context preservation across compaction:**
- Structured compaction template in CLAUDE.md (*enhanced in v2.1*) tells Claude exactly how to format the compacted summary (Goal, Sprint State, Progress, Decisions, Commands, Plan, File Context with `<files-read>`/`<files-modified>` tags)
- Story-cycle plans have a "Story-Cycle Context" header with cumulative file tracking tags that survive compaction
- Complex plans saved to `docs/plans/` for file-system persistence

**Context preservation across sessions:**
- /handoff writes structured session file to `docs/sessions/`
- /continue reads the latest session file
- progress.md tracks sprint state

### Token Budget Estimates

| Item | Estimated Tokens | Loaded When |
|---|---|---|
| CLAUDE.md | ~1200 | Always |
| progress.md | ~200 | Always (auto-loaded) |
| BACKLOG_INDEX.md | ~300 | Always (auto-loaded) |
| A skill SKILL.md | 400-800 | When skill is invoked |
| A skill reference file | 200-600 | On demand within skill |
| A helper script (--help) | ~50 | When invoked |
| A rule file | 200-400 | When matching file is edited |
| CODING_STANDARDS.md | ~800 | During story-cycle execution |
| TESTING_STRATEGY.md | ~2500 | When story-cycle loads it |

**Total auto-loaded overhead:** ~1700 tokens (CLAUDE.md + progress.md + BACKLOG_INDEX.md)

**v2.3 context efficiency improvements:** Skills now follow a three-level loading pattern: lean SKILL.md (always loaded when invoked, <150 lines) → references/ (loaded on demand when specific detail is needed) → scripts/ (executed as black boxes, never read into context). This means a `/story-cycle` invocation loads ~800 tokens initially, then only loads `references/story-types.md` (~500 tokens) for the specific story type being executed. Previously, all 317 lines loaded every time.

**v2.4 context efficiency improvements:** Agent-first file discovery in story-cycle Phase 1 reduces unnecessary file reading during planning (~5-15 files avoided per story). Confidence-based scoring in quality agents reduces noise in sprint-end reports. YAML frontmatter adds ~50 tokens per skill but enables automated inventory and dependency validation.

**v2.5 context efficiency improvements:** Script black-boxing policy — scripts in `scripts/` are executed directly without reading their source, saving ~500 tokens per script invocation. Reference navigation pattern — skills now include section-level grep hints ("search for `## Section`") so Claude loads one section instead of an entire reference file. New `assets/` resource type for output templates that are copied without being read into context.

**v2.6 context efficiency improvements:** Priority-based compaction directive tags items as CRITICAL (survive all compactions verbatim), HIGH (preserve if space), NORMAL (summarize if needed), LOW (drop first — these are recoverable). Context budget awareness heuristics in verification.md encourage summarizing after 10+ file reads and discarding bulk after exploration phases. Directory-level `.claude-context.md` files provide module-specific context without loading global standards. Auto-save session state in pre-stop hook ensures `/continue` has breadcrumbs even after abrupt termination.

**v2.7 context efficiency improvements:** Symbolic state encoding — compaction format changed from prose paragraphs to structured key-value pairs (`goal:`, `commands:`, `branch:`, `decisions:`) that LLMs preserve with higher fidelity. Context relevance scoring — a 5-level classification system (ACTIVE/ANCHORED/REFERENCE/STALE/DUPLICATE) for systematic context pruning, applied at phase transitions and after extended exploration. Reusable micro-components — 3 commonly duplicated operations (discover-commands, quality-gate-sequence, verify-clean-git-state) extracted into shared snippets in `.claude/prompts/`, reducing cross-skill duplication.

**v2.8 context efficiency improvements:** Per-phase context loading manifests in story-cycle prescribe exactly which files to load and skip at each phase transition, preventing unnecessary reads. Plan template enforces structured output that separates specification from implementation, reducing plan revision cycles. Clarification scanning surfaces ambiguity before execution, avoiding costly mid-implementation rework and context consumption.

**v2.9 context efficiency improvements:** Reference file token budgets — explicit line limits for on-demand references (individual ≤200, per-skill total ≤500) and project docs (CODING_STANDARDS ≤200, TESTING_STRATEGY ≤250, GROUND_RULES ≤100, ARCHITECTURE ≤200) prevent context creep as projects grow. Context budget visibility — a new `context-budget` micro-component lets users estimate context usage and compaction proximity. Pre-compaction state persistence saves session state before compaction events, not just at session end. Subagent context protocol formalizes what context forked agents receive (Full vs Minimal mode), preventing token waste from irrelevant framework state in analysis agents.

**Optimization opportunity:** Measure actual token consumption. If certain auto-loaded files aren't being used in most conversations, consider making them on-demand.

---

## 14. Git Workflow & Worktrees

### Standard Flow

```
main ──────────────────────────────────────── main (after squash merge)
  └── sprint-1 ── commit ── commit ── PR ──┘
```

**Why squash merge:** Keeps main history clean. Each sprint is one commit on main, regardless of how many intermediate commits were made. This makes `git bisect`, `git log`, and `git revert` much more useful.

**Why feature branches:** Isolates work-in-progress from the stable main branch. If a sprint goes wrong, main is unaffected.

### Worktree Flow (*new in v2.0*)

```
my-project/           (main worktree, on main)
my-project-sprint-5/  (worktree, on sprint-5 branch)
my-project-sprint-6/  (worktree, on sprint-6 branch)
```

**When to use worktrees:**
- Working on multiple stories simultaneously
- Running Claude Code in parallel (each instance in its own worktree)
- Isolating experiments without affecting the main working directory

**Why worktrees matter for AI-assisted development:** Claude Code instances don't share context. If you want two stories developed in parallel, you need two separate working directories. Git worktrees provide this without duplicating the entire repository.

**Optimization opportunity:** Worktree support is new and lightly tested. Key questions: How does /sprint-end handle worktree merge when another worktree has also merged to main? How do multiple instances coordinate? The CLAUDE_CODE_TASK_LIST_ID shared task list is mentioned but not deeply integrated.

### CI/CD Integration (*new in v3.0*)

#### Claude-as-CI PR Reviewer

**File:** `.github/workflows/claude-pr-review.yml`
**Trigger:** On pull request open and synchronize events
**Added value:** Automated, consistent PR review using Claude Code as a CI step

**How it works:** When a PR is opened or updated, a GitHub Actions workflow dispatches Claude Code to review the diff using `.claude/commands/review-pr-ci.md` — a non-interactive PR review command. The review checks for: code quality issues (complexity >10, duplication >10 lines), test coverage gaps (missing test files, weakened assertions, assertion density <1.5), security concerns (hardcoded secrets, CWE patterns, input validation), and convention violations. Findings are posted as structured PR review comments with severity levels and confidence scoring (only ≥80 findings are actionable). Tiered access ensures external contributors receive structure-only review (no code-level analysis).

**Why this matters:** Human code review is bottlenecked by availability. Claude-as-CI provides immediate, consistent feedback on every PR without waiting for a human reviewer. This is complementary to (not a replacement for) human review — it catches mechanical issues so human reviewers can focus on design and intent.

**Integration with framework:** The CI reviewer respects the project's CODING_STANDARDS.md, GROUND_RULES.md, and TESTING_STRATEGY.md — the same standards enforced by `/sprint-end` quality gates are applied in CI.

**Optimization opportunity:** Monitor false positive rate in CI review comments. If the reviewer generates too much noise, refine the review scope or raise the confidence threshold. Consider whether the CI reviewer should block merge on high-severity findings or remain advisory only.

---

## 15. Documentation Architecture

### Layer 1: Auto-Loaded (Every Session)

| File | Purpose | Target Size |
|---|---|---|
| CLAUDE.md | Project config, commands, skill reference | <100 lines |
| docs/progress.md | Current sprint state, recent history | <50 lines active |
| docs/reference/BACKLOG_INDEX.md | Epic overview, story mapping | <30 lines active |

**Design principle:** These files are the most expensive because they're loaded every time. Every line must justify its token cost.

### Layer 2: On-Demand (Loaded by Skills)

| File | Loaded By | Purpose |
|---|---|---|
| docs/reference/CODING_STANDARDS.md | /story-cycle Phase 2 | Language-specific conventions |
| docs/reference/TESTING_STRATEGY.md | /story-cycle, /test-validator | TDD workflow and quality criteria |
| docs/architecture/ARCHITECTURE.md | /architecture-check, /story-cycle | Module boundaries and structure |
| docs/reference/backlog/E##-*.md | /sprint-start, /ideate | Individual epic with story details |
| docs/reference/GROUND_RULES.md | /story-cycle Phase 1e, /sprint-end | Architectural principles |

**Design principle:** Loaded only when needed. Not every story needs the full testing strategy. Not every conversation needs architecture details.

### Layer 3: Persistent State (Written by Skills)

| File/Directory | Written By | Read By | Purpose |
|---|---|---|---|
| docs/sessions/ | /handoff | /continue | Session state across conversations |
| docs/plans/ | /story-cycle | /story-cycle (after compaction) | Plan persistence |
| docs/sprints/ | /sprint-start | /sprint-end, /retrospective | Sprint specifications |
| docs/testing/UAT_COVERAGE.md | /UAT-cycle | /UAT-cycle, /sprint-end | UAT test results |

**Design principle:** State that must survive across sessions or compaction goes to the filesystem. The conversation context is ephemeral; files are persistent.

### Layer 4: Reference (Rarely Changed)

| File | Purpose |
|---|---|
| docs/reference/tech/*.md | Technology-specific reference docs |

### Layer 4.5: GitHub Templates (*new in v3.0*)

| File | Purpose |
|---|---|
| .github/pull_request_template.md | Structured PR template with summary, changes, testing, and review checklist sections |
| .github/ISSUE_TEMPLATE/bug_report.yml | GitHub issue form for bug reports with structured fields (steps to reproduce, expected/actual behavior, environment) |
| .github/ISSUE_TEMPLATE/feature_request.yml | GitHub issue form for feature requests with structured fields (problem statement, proposed solution, alternatives) |

**Design principle:** GitHub templates standardize collaboration artifacts. The PR template ensures sprint-end PRs are consistently documented. Issue templates lower the barrier for external contributors and ensure bug reports contain the information needed for `/fix-issue` or `/debug-session`.

### Layer 5: Skill Assets (Copy, Don't Read)

| Directory | Purpose |
|---|---|
| .claude/skills/*/assets/ | Output templates — copied to target location and edited, never read into context |

**Design principle:** Assets are boilerplate templates used in skill output. Copy an asset to the target location and Edit it — never Read the asset into context first. This keeps context cost at zero.
| docs/adr/*.md | Architecture Decision Records |
| docs/technical-debt.md | Technical debt inventory |

**Design principle:** Reference material that changes infrequently. Loaded only when specifically needed.

### Skill Metadata (*new in v2.4*)

All skills now include YAML frontmatter with machine-readable metadata: `name`, `version`, `trigger`, `depends-on`, `references`. This enables automated inventory generation, version tracking, dependency validation, and integration with `/skill-eval`. The frontmatter adds ~50 tokens per skill.

### Prompt Snippets (*new in v2.1*)

| File | Purpose |
|---|---|
| .claude/prompts/review-security.md | Security review of a specific file |
| .claude/prompts/explain-pattern.md | Explain a code pattern in this codebase |
| .claude/prompts/suggest-tests.md | Suggest test cases for a file |

**Design principle:** Lighter than full skills — simple parameterized templates for common prompts. No workflow scaffolding, no plan mode, just the prompt with `$1`/`$2` argument expansion.

### Micro-Components (*new in v2.7*)

| File | Purpose | Used By |
|---|---|---|
| .claude/prompts/discover-commands.md | Extract configured commands from CLAUDE.md | sprint-start, sprint-end, story-cycle, continue |
| .claude/prompts/quality-gate-sequence.md | Run lint → typecheck → test in order | sprint-end, story-cycle Phase 4, pre-stop hook |
| .claude/prompts/verify-clean-git-state.md | Check working tree cleanliness | sprint-start, sprint-end, continue |
| .claude/prompts/context-budget.md | Estimate context budget usage and compaction proximity | story-cycle Phase 2, manual invocation |

**Design principle:** Reusable operation sequences that multiple skills reference to avoid duplicating the same logic. Each is 5-15 lines — lightweight enough to not burden context, but centralized enough to maintain once. Skills reference them as shared procedures: "Use the `discover-commands` micro-component."

### Subagent Prompt Templates (*new in v2.2*)

| File | Purpose |
|---|---|
| .claude/prompts/agents/code-reviewer.md | Code review dispatch with severity classification, confidence scoring, and optional review lens ($3) |
| .claude/prompts/agents/spec-reviewer.md | Spec compliance verification with file:line references |

**Design principle:** Structured templates for dispatching quality subagents. Each includes: context slots ($1, $2, $3), review checklists, explicit skepticism ("do NOT trust claims — read actual code"), confidence scoring (0–100), and severity classification requirements. Used by sprint-end when dispatching quality agents.

**Multi-perspective review** (*new in v2.4*): The code-reviewer template now supports a `$3` lens parameter (correctness, conventions, security) for focused independent review. Multiple reviewers with different lenses can be dispatched in parallel. Issues flagged by 2+ independent reviewers are auto-elevated to Critical.

---

## 16. Cross-Tool Compatibility

### AGENTS.md

**File:** `AGENTS.md` → symlink to `CLAUDE.md`
**Purpose:** Tools like Cursor, Aider, and Windsurf look for `AGENTS.md` as their configuration file.

By symlinking to CLAUDE.md, any tool gets the same project configuration: commands, conventions, architecture, and current focus.

**Limitation:** The skills system is Claude Code-specific. Other tools won't understand `/bootstrap` or `/story-cycle`. But they will understand the project context (commands, conventions, file structure).

### llms.txt

**File:** `llms.txt`
**Purpose:** Emerging standard for LLM-readable project indexes.

Lists all key files with descriptions so any LLM tool can understand the project structure without exploring the filesystem.

**Optimization opportunity:** Monitor whether any tools actually consume llms.txt. The standard is new and adoption is uncertain. If it gains traction, consider auto-updating it during /bootstrap and /sprint-end.

---

## 17. Optimization Opportunities

### Implemented in v3.0

| ID | Optimization | Status |
|---|---|---|
| OPT-87 | Claude-as-CI PR Reviewer (automated PR review workflow via GitHub Actions) | Implemented |
| OPT-88 | PR Template (structured `.github/pull_request_template.md` for consistent PR documentation) | Implemented |
| OPT-89 | SessionStart Hook (framework integrity validation at session start) | Implemented |
| OPT-90 | Hook-Based Activity Logging (PostToolUse activity-logger for tool usage observability) | Implemented |
| OPT-91 | Skill Conformance Validator (validates skill structure against SKILL_TEMPLATE.md conventions) | Implemented |
| OPT-92 | Skills Registry Schema Validation (JSON schema validation for skills-registry.json) | Implemented |
| OPT-93 | Story-Cycle Fast-Track Mode (TRIVIAL/SMALL/STANDARD size classification skips ceremony for simple changes) | Implemented |
| OPT-94 | Dynamic Quality Agent Scaling (Minimal/Small/Standard/Large scope-based agent dispatch) | Implemented |
| OPT-95 | Tool Restriction per Agent (least-privilege tool access for quality agents) | Implemented |
| OPT-96 | GitHub Issue Templates (structured bug report and feature request forms) | Implemented |
| OPT-97 | Undo-work skill (safe rollback with soft/hard/story levels and confirmation gate) | Implemented |

**Key changes in v3.0:** CI/CD integration improved with Claude-as-CI PR reviewer and PR template for consistent PR documentation. Session lifecycle improved with SessionStart hook for framework validation and activity-logger hook for tool usage observability. Workflow efficiency improved with story-cycle fast-track mode that eliminates ceremony for trivial/small changes and dynamic quality agent scaling that right-sizes review effort to sprint scope. Security posture improved with per-agent tool restrictions enforcing least privilege. Skill quality improved with conformance validation and registry schema validation. Collaboration improved with GitHub issue templates for structured bug reports and feature requests. Recovery improved with `/undo-work` skill for safe rollback of failed implementation attempts.

See `CHANGELOG.md` for detailed test and revert instructions for each optimization.

### Implemented in v2.9

| ID | Optimization | Status |
|---|---|---|
| OPT-78 | Pre-compaction state persistence (save state before mid-session compaction) | Implemented |
| OPT-79 | Reference file token budgets (explicit line limits for on-demand references) | Implemented |
| OPT-80 | Automated secrets detection in post-edit hook (AWS keys, API tokens, private keys, credentials) | Implemented |
| OPT-81 | Skill prerequisites declaration (`requires` field in YAML frontmatter) | Implemented |
| OPT-82 | Subagent context protocol (Full vs Minimal mode for forked agents) | Implemented |
| OPT-83 | Hook self-validation with requirements metadata (once-per-session missing tool reports) | Implemented |
| OPT-84 | Context budget visibility (micro-component for estimating context usage) | Implemented |
| OPT-85 | Framework health check skill (`/doctor` — validates config, hooks, dependencies, docs) | Implemented |
| OPT-86 | Dead code detection in code-quality and weekly-maintenance (unused exports, orphaned functions) | Implemented |

**Key changes in v2.9:** Resilience improved with pre-compaction state persistence and reference file budgets that prevent context creep. Security improved with automated secrets detection in the post-edit hook. Skill architecture improved with prerequisites declaration, subagent context protocol, and hook self-validation. Observability improved with context budget visibility and a `/doctor` health check skill. Quality tooling expanded with dead code detection.

See `CHANGELOG.md` for detailed test and revert instructions for each optimization.

### Implemented in v2.8

| ID | Optimization | Status |
|---|---|---|
| OPT-71 | Forced clarification markers in story planning (`[NEEDS CLARIFICATION]` convention) | Implemented |
| OPT-72 | Structured clarification sub-phase with ambiguity scanning (7-category scan, ranked questions) | Implemented |
| OPT-73 | WHAT/WHY vs HOW plan separation with output templates (plan-template.md, story-template.md) | Implemented |
| OPT-74 | Project Ground Rules pattern (MUST/SHOULD principles, checked at planning and shipping) | Implemented |
| OPT-75 | Violation tracking with justification (architectural violations table in plans) | Implemented |
| OPT-76 | Consistent handoff suggestions with pre-filled commands across all workflow skills | Implemented |
| OPT-77 | Per-phase context loading manifests (prescriptive RELOAD/SKIP lists per story-cycle phase) | Implemented |

**Key changes in v2.8:** Specification quality improved with forced clarification markers and structured ambiguity scanning that prevent LLM assumptions. Plan quality improved with WHAT/WHY vs HOW separation enforced by output templates. Architectural governance added with project ground rules pattern and violation tracking. Workflow polish with consistent handoff suggestions across all skills and per-phase context manifests.

See `CHANGELOG.md` for detailed test and revert instructions for each optimization.

### Implemented in v2.7

| ID | Optimization | Status |
|---|---|---|
| OPT-65 | Cognitive reasoning scaffolds at critical decision points (5 named reasoning tools) | Implemented |
| OPT-66 | Symbolic state encoding for compaction (key-value format replaces prose) | Implemented |
| OPT-67 | Explicit control flow markers — IF/ELSE/LOOP/HALT extending HARD-GATE | Implemented |
| OPT-68 | Phase-specific error recovery tables for complex skills (52 error patterns) | Implemented |
| OPT-69 | Formalized context relevance scoring (5-level classification + context rot detection) | Implemented |
| OPT-70 | Reusable micro-components for cross-skill operations (3 shared snippets) | Implemented |

**Key changes in v2.7:** Reasoning quality improved with structured cognitive scaffolds at critical decision points. Workflow reliability improved with explicit control flow markers and phase-specific error recovery tables. Context efficiency improved with symbolic state encoding, formalized relevance scoring, and reusable micro-components. The control flow markers (IF/ELSE/LOOP/HALT) extend the successful HARD-GATE pattern to cover all conditional logic. Error recovery tables extend the edit-recovery pattern to all major workflow failure modes.

See `CHANGELOG.md` for detailed test and revert instructions for each optimization.

### Implemented in v2.6

| ID | Optimization | Status |
|---|---|---|
| OPT-50 | AI slop detection rule (banned comment patterns, obvious comment detection) | Implemented |
| OPT-51 | Comment quality standards in CODING_STANDARDS.md | Implemented |
| OPT-52 | Edit failure recovery protocol (decision tree, escalating retry) | Implemented |
| OPT-53 | Automated session state preservation (pre-stop hook auto-save) | Implemented |
| OPT-54 | Priority-based context compaction (CRITICAL/HIGH/NORMAL/LOW) | Implemented |
| OPT-55 | Directory-level context files (.claude-context.md convention) | Implemented |
| OPT-56 | Task completion enforcement (check task list before reporting done) | Implemented |
| OPT-57 | Proactive context budget awareness (5 heuristics) | Implemented |
| OPT-58 | Intent decomposition gate (Phase 0 in story-cycle) | Implemented |
| OPT-59 | Parallel research dispatch (2-3 explore agents for multi-module stories) | Implemented |
| OPT-60 | Self-referential completion verification (Phase 4.5 with evidence loop) | Implemented |
| OPT-61 | Dynamic skill content (conditional test/build gates in sprint-start/sprint-end) | Implemented |
| OPT-62 | Expanded graceful degradation (linter, type checker, gh CLI fallbacks) | Implemented |
| OPT-63 | AI-specific testing anti-patterns (hallucinated APIs, weakened assertions, etc.) | Implemented |
| OPT-64 | AI-specific security anti-patterns (phantom packages, typosquatted deps, etc.) | Implemented |

**Key changes in v2.6:** Code quality improved with AI slop detection and comment quality standards. Developer experience improved with edit recovery protocol and session auto-save. Context efficiency improved with priority-based compaction and budget awareness heuristics. Story delivery improved with intent decomposition, parallel research, and completion verification. Resilience improved with expanded graceful degradation and dynamic skill content.

See `CHANGELOG.md` for detailed test and revert instructions for each optimization.

### Implemented in v2.5

| ID | Optimization | Status |
|---|---|---|
| OPT-40 | Script execution policy — black-box directives for scripts/ | Implemented |
| OPT-41 | Reference navigation pattern — section-level grep hints | Implemented |
| OPT-42 | Resource types table (scripts/, references/, assets/) | Implemented |
| OPT-43 | Skill scaffolding script (init-skill.sh) | Implemented |
| OPT-44 | Input/output examples in skills (debug-session, brainstorm, ideate) | Implemented |
| OPT-45 | Imperative language cleanup (minor) | Implemented |
| OPT-46 | DO/DON'T anti-pattern pairs at critical transition points | Implemented |
| OPT-47 | Graceful degradation pattern for missing dependencies | Implemented |
| OPT-48 | Pre-execution validation for file-producing skills | Implemented |
| OPT-49 | Skills registry generator (update-registry.sh → skills-registry.json) | Implemented |

**Key changes in v2.5:** Context efficiency improvements through script black-boxing and reference navigation. Skill development experience improved with scaffolding tools and I/O examples. Resilience improved with graceful degradation and pre-execution validation patterns. Tooling improved with automated skills registry generation.

See `CHANGELOG.md` for detailed test and revert instructions for each optimization.

### Implemented in v2.4

| ID | Optimization | Status |
|---|---|---|
| OPT-31 | Confidence-based scoring for quality agents (0–100, ≥80 threshold) | Implemented |
| OPT-32 | Parallel quality gate execution (simultaneous dispatch) | Implemented |
| OPT-33 | Multi-perspective independent code review (correctness/conventions/security lenses) | Implemented |
| OPT-34 | Skill evaluation framework (/skill-eval with eval, compare, metrics modes) | Implemented |
| OPT-35 | Iterative refinement loop (/refine-loop with completion criteria) | Implemented |
| OPT-36 | Agent-first file discovery in story-cycle Phase 1 | Implemented |
| OPT-37 | Example block triggers for auto-invoked skills | Implemented |
| OPT-38 | Per-session hook state tracking (reduced warning fatigue) | Implemented |
| OPT-39 | YAML frontmatter for all skill metadata | Implemented |

**Key architectural changes in v2.4:** Quality agents now use confidence scoring to separate signal from noise. Quality gates run in parallel instead of sequentially. Skills have machine-readable YAML frontmatter enabling automated inventory and dependency tracking. Story-cycle uses agent-first file discovery to reduce context consumption during planning.

See `CHANGELOG.md` for detailed test and revert instructions for each optimization.

### Implemented in v2.3

| ID | Optimization | Status |
|---|---|---|
| OPT-22 | Skill reference splitting (story-cycle, sprint-end, bootstrap) | Implemented |
| OPT-23 | Helper scripts bundled with skills | Implemented |
| OPT-24 | "Assume problems exist" QA framing | Implemented |
| OPT-25 | Explicit "Don'ts" lists in quality skills | Implemented |
| OPT-26 | "Discover before invoking" CLI pattern | Implemented |
| OPT-27 | Fresh-perspective sub-agent document testing | Implemented |
| OPT-28 | "Context window is a shared resource" principle | Implemented |
| OPT-29 | Co-located reference architecture for tech skills | Implemented |
| OPT-30 | Conditional environment adaptation | Implemented |

**Key architectural change in v2.3:** Skills now follow a three-level structure: lean SKILL.md (<150 lines) + `references/` subdirectory (loaded on demand) + optional `scripts/` (executable helpers). This enforces the context budget principle already defined in SKILL_TEMPLATE.md but not previously followed by the three largest skills.

### Implemented in v2.2

| ID | Optimization | Status |
|---|---|---|
| OPT-10 | Hard gate markers in skills | Implemented |
| OPT-11 | Trigger-only skill descriptions | Implemented |
| OPT-12 | Verification-before-completion rule | Implemented |
| OPT-13 | Red flag tables in key skills | Implemented |
| OPT-14 | Inline self-review in story-cycle | Implemented |
| OPT-15 | Spec-compliance review for complex stories | Implemented |
| OPT-16 | Deepened debug-session skill | Implemented |
| OPT-17 | Brainstorm skill (design exploration) | Implemented |
| OPT-18 | Process flowcharts in complex skills | Implemented |
| OPT-19 | Subagent prompt templates | Implemented |
| OPT-20 | TDD for skill creation | Implemented |
| OPT-21 | Fix-immediately pattern | Implemented |

See `CHANGELOG.md` for detailed test and revert instructions for each.

### Remaining High Impact

1. **Measure actual token consumption** — Instrument a few sessions to measure how many tokens each auto-loaded file consumes. Trim the most expensive low-value content. v2.4 added ~50 tokens/skill for YAML frontmatter — verify this doesn't cause issues.

2. **Test bootstrap against diverse projects** — Run /bootstrap against 5+ different project types and record: detection accuracy, command correctness, generated skill quality. This is the highest-leverage test because bootstrap is every user's first experience.

3. **Validate test protection gates** — Create a test project, deliberately weaken tests, and verify that /sprint-end catches it. This is the core v2.0 value proposition.

4. **Monitor hook behavior** — Enable all three hooks on a real project and track: how often they trigger, false positive rate, whether the self-correction loop resolves issues or creates loops. v2.4 added session state tracking — verify it reduces warning fatigue without weakening protection.

5. **Validate v2.4 improvements** — Test whether confidence scoring effectively filters false positives in quality agents. Test whether parallel quality gate dispatch produces better results than sequential. Use `/skill-eval` to test key skills against pressure scenarios. Verify agent-first file discovery in story-cycle reduces context consumption.

6. **Validate v2.6 improvements** — Test slop detection against real AI output to verify pattern coverage. Test edit recovery protocol with deliberate edit failures to verify decision tree works. Test completion verification loop to confirm it catches real gaps without excessive looping. Test priority-based compaction under heavy context pressure. Verify auto-save state is useful for `/continue` recovery.

7. **Validate v2.7 improvements** — Test reasoning scaffolds: run `/story-cycle` with a compound request and verify `scope_analysis` produces numbered deliverables with complexity ratings. Test symbolic compaction: trigger compaction and verify key-value format survives. Test control flow markers: run `/sprint-end` without CI and verify `<IF>/<ELSE>` branching. Test error recovery tables: introduce a deliberate test failure during `/story-cycle` Phase 3 and verify the error-recovery table is consulted. Test context relevance scoring: during a long session, verify STALE context is identified and pruned. Test micro-components: verify sprint-end references `discover-commands` correctly.

### Remaining Medium Impact

7. **Automate metrics collection** — The retrospective skill's metrics dashboard is mostly manual. A `scripts/metrics.sh` that computes test count, coverage, churn, and LOC from git would make retrospectives much faster.

8. **Session file lifecycle** — Define when old session files get archived or deleted. Without this, `docs/sessions/` will grow indefinitely.

9. **Rule path refinement** — The security rule's `**/*key*` pattern matches too broadly. The verification rule uses `**` (all files). Audit token cost of rules loaded per-edit.

### Remaining Lower Impact

10. **install.sh optimization** — Currently clones the full repo. Consider using `git archive` or a release tarball for faster, lighter installation.

11. **Worktree integration depth** — The parallel-work skill is new. Test it with 2-3 concurrent Claude Code instances to verify coordination works.

12. **llms.txt auto-update** — Auto-generate llms.txt content during /bootstrap based on actual project files.

---

## 18. Known Limitations

### Context Window Constraints

- **Story size ceiling:** Even with careful context management, very large stories (touching 10+ files) may exhaust the context window. The 5-8 file guideline in /ideate is a mitigation, not a guarantee.
- **Compaction loss:** When context compacts, nuanced decisions from early in the conversation may be lost. The compaction directive in CLAUDE.md helps but can't prevent all loss.

### Advisory vs Deterministic

- **Rules are advisory:** Claude can technically ignore rules. The testing, security, verification, and documentation rules are strong guidance, but not unbypassable. Critical protections should be hooks (deterministic), not just rules.
- **Skill compliance varies:** Skills are markdown instructions. Claude follows them well most of the time, but complex multi-step skills sometimes have steps skipped or combined. Mitigations: hard gate markers, red flag tables, trigger-only descriptions, process flowcharts, "assume problems" QA framing. v2.3 further mitigates by splitting large skills into lean entry points + reference files, reducing cognitive load per invocation.
- **Hard gates are still advisory:** The `<HARD-GATE>` blocks are stronger than prose but are not deterministic enforcement. They rely on Claude respecting the XML-style markers. If a hard gate is consistently bypassed, consider escalating to a hook.
- **Reference loading depends on Claude:** The v2.3 reference splitting pattern relies on Claude reading `references/*.md` files when directed by SKILL.md. If Claude skips reading the reference, it may miss detailed instructions. Monitor whether this happens and consider inlining critical content if it does.
- **Confidence scoring is prompt-based:** The v2.4 confidence scoring relies on Claude's self-assessment of finding severity. Scores may not perfectly correlate with actual issue importance. Monitor whether the ≥80 threshold effectively filters false positives without hiding real issues.
- **YAML frontmatter adds token overhead:** Each skill now has ~50 extra tokens of frontmatter metadata. For 29 skills this is ~1450 tokens if all were loaded simultaneously (they aren't — only invoked skills load). Monitor if the overhead is noticeable.
- **Slop detection is pattern-based:** The code-slop rule uses string matching for banned patterns. Novel slop patterns not in the list will pass through. The rule should be expanded as new patterns are observed.
- **Completion verification adds turns:** Phase 4.5 re-reads acceptance criteria and loops back up to 2 times. For simple stories this may add unnecessary overhead. Monitor whether the verification loop catches real issues or just adds latency.
- **Priority-based compaction is advisory:** The CRITICAL/HIGH/NORMAL/LOW tags guide Claude's compaction behavior but are not deterministic. Claude may still drop CRITICAL items if context pressure is severe enough.
- **Reasoning scaffolds depend on Claude following the steps:** The named reasoning tools (scope_analysis, failure_diagnosis, etc.) are structured prompts, not deterministic tools. Claude may abbreviate or skip steps if it "thinks" it already knows the answer. Monitor whether the scaffolds produce consistently structured output.
- **Control flow markers are still advisory:** The `<IF>/<ELSE>/<LOOP>/<HALT>` markers are stronger than prose but not unbypassable — Claude could still interpret them loosely. If consistently bypassed, consider escalating critical conditionals to hooks.
- **Error recovery tables may not cover all errors:** The 52 error patterns across 3 skills cover known failure modes. Novel errors not in the tables will still require Claude to improvise. Expand the tables as new patterns are observed.
- **Micro-components add a level of indirection:** Skills referencing micro-components must read two files instead of one. If this causes issues with Claude not finding the component, consider inlining the most critical operations.
- **Ground rules are optional:** The project ground rules are only checked if `docs/reference/GROUND_RULES.md` exists and has principles defined. Projects that skip the bootstrap ground rules step get no architectural governance.
- **Clarification markers depend on Claude's uncertainty detection:** The `[NEEDS CLARIFICATION]` convention relies on Claude recognizing its own uncertainty. Confidently wrong assumptions will still pass through without markers.
- **Ambiguity scan adds turns:** Phase 1f introduces additional user interaction before plan approval. For simple, unambiguous stories this adds latency. Monitor whether it catches real issues or just slows down obvious work.
- **Pre-compaction state persistence is best-effort:** The auto-save to `docs/sessions/.auto-save.md` triggers based on heuristics (15+ turns, large outputs). It may not fire before every compaction event, and the saved state may already be slightly stale. It supplements, not replaces, the compaction directive.
- **Secrets detection is regex-based:** The post-edit hook scans for known patterns (AWS keys, API tokens, private keys). Novel credential formats or obfuscated secrets will not be caught. This is a safety net, not a replacement for proper secrets management (`.gitignore`, vault tools).
- **Skill prerequisites are not enforced deterministically:** The `requires` field in YAML frontmatter tells Claude what to check, but Claude may skip the check if it's confident the tools exist. Missing prerequisites will surface as errors mid-execution rather than upfront.
- **Reference file budgets are advisory:** The ≤200 lines per reference file guideline in documentation.md is a rule, not a hook. Files can exceed the budget without triggering a block. Monitor via `/doctor` or periodic manual review.
- **Hook self-validation degrades gracefully but silently:** When a hook dependency is missing, it reports once per session and continues. This means the hook's intended protection (formatting, linting) is quietly absent. Check `/doctor` output if quality seems to drift.
- **Dead code detection depends on language tooling:** The code-quality skill's dead code detection relies on language-specific tools (ts-prune, vulture, etc.). If no tool is available for the project's language, the check is skipped silently.

### Git Workflow Assumptions

- **GitHub-centric:** The framework assumes GitHub (gh CLI, GitHub PRs, GitHub CI). GitLab or Bitbucket users would need to adapt sprint-end and pr-status skills.
- **Single-developer optimized:** The sprint workflow works best for solo developers or small teams. Large teams with multiple concurrent PRs may need adapted branch naming and merge strategies.

### Recovery Limitations

- **Undo-work scope:** The `/undo-work` skill operates on git state (stash, discard, reset). Changes that were committed and pushed cannot be undone locally — they require remote operations (revert commits, force push). The `--story` level resets to the branch point, which may undo more commits than intended if the branch was reused.

### Detection Limitations

- **Bootstrap accuracy:** Stack detection relies on file presence and content parsing. Unusual project structures (e.g., monorepos with multiple package.json files) may confuse detection.
- **Phantom package detection:** Verifying package existence requires network access and registry knowledge. Not all registries are checked.

---

## 19. Experimentation Log

Use this section to track experiments, findings, and adjustments as you optimize the framework.

### Template

```markdown
#### [Date] — [Experiment Name]

**What I tested:** [description]
**Project type:** [language/framework]
**Result:** [what happened]
**Adjustment made:** [what was changed, or "none — will monitor"]
**Files affected:** [list]
```

### Experiments

<!-- Add your experiments below -->
