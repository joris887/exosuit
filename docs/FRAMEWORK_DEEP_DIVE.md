# JD-LLM Development Framework v2.0 — Deep Dive

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
│  Skills (20+ markdown files that guide Claude)   │
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

**File:** `CLAUDE.md` (66 lines)
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
- Important file paths
- Compaction directive

**What it does NOT contain:**
- Detailed coding standards (those are in `docs/reference/CODING_STANDARDS.md`, loaded only when needed)
- Full testing strategy (in `docs/reference/TESTING_STRATEGY.md`)
- Architecture details (in `docs/architecture/ARCHITECTURE.md`)
- Placeholder comments (removed in v2.0 — they waste tokens)

**Optimization opportunity:** Monitor actual CLAUDE.md content after /bootstrap runs on real projects. If it exceeds 80 lines, trim further. The compaction directive at the bottom is critical — it tells Claude what to preserve when context is compressed.

### .claude/settings.json — Claude Code Configuration

**File:** `.claude/settings.json`
**Added value:** Configures hooks and tool permissions

Currently contains only the pre-tool safety hook. The bootstrap skill adds more hooks based on detected stack (formatter, linter, test runner).

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

**Why this matters:** LLMs sometimes take shortcuts. If a merge conflict is complex, an LLM might try `git checkout .` to "start fresh" — losing all the user's work. This hook prevents that.

**Optimization opportunity:** The grep patterns are basic. Could be improved with more sophisticated parsing. Consider adding: `DROP TABLE`, `DELETE FROM` without WHERE, `docker system prune -af`. Monitor blocked commands to see if legitimate operations are being caught.

#### post-edit-format.sh (PostToolUse)

**File:** `.claude/hooks/post-edit-format.sh`
**Trigger:** After Claude edits or writes a file
**Added value:** Consistent formatting without relying on the AI to remember

**How it works:** Detects file extension, runs the appropriate formatter (prettier, ruff, rustfmt, gofmt, etc.). Falls back gracefully if no formatter is installed.

**Why this matters:** LLMs produce code with inconsistent formatting — sometimes tabs, sometimes spaces, sometimes wrong indentation. Auto-formatting after every edit means the codebase stays clean regardless of what the AI produces.

**Optimization opportunity:** Currently commented out in settings.json (not configured by default). The /bootstrap skill should detect the project's formatter and enable this hook. Consider whether the formatter should run on the single edited file or the whole project.

#### pre-stop-quality.sh (Stop)

**File:** `.claude/hooks/pre-stop-quality.sh`
**Trigger:** Before Claude reports a task as complete
**Added value:** Creates a self-correction loop — if quality checks fail, Claude must fix them before finishing

**How it works:** Runs lint, typecheck, and test suite. If any fail, exits with error code 1, which prevents Claude from marking the task as done.

**Why this matters:** Without this, Claude might report "done" with failing tests or lint errors. The stop hook forces self-correction — Claude sees the failures and must fix them before it can complete.

**Optimization opportunity:** Currently all commands are commented out (configured per-project by /bootstrap). The self-correction loop can sometimes lead to infinite loops if the AI can't fix the issue. Consider adding a retry limit or fallback behavior. Monitor how often this hook triggers and whether it leads to productive fixes or loops.

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

**Optimization opportunity:** The rules are advisory — Claude *can* ignore them if it "decides" the situation warrants it. Consider whether the test protection should be escalated to a hook (deterministic) rather than a rule (advisory). Monitor whether Claude actually follows these rules consistently.

#### documentation.md

**File:** `.claude/rules/documentation.md`
**Paths:** `docs/**`, `**/*.md`
**Added value:** Prevents documentation bloat

**Key rules:** Only create docs when explicitly requested. Update existing over creating new. Keep auto-loaded files lean.

**Why this matters:** LLMs love generating documentation. Without this rule, Claude will happily create README files, add JSDoc to every function, and generate architectural diagrams nobody asked for. This wastes context and creates maintenance burden.

#### security.md

**File:** `.claude/rules/security.md`
**Paths:** `**/*.env*`, `**/auth/**`, `**/security/**`, `**/credentials*`, `**/secrets*`, `**/*password*`, `**/*token*`, `**/*key*`
**Added value:** Reduces AI-introduced vulnerability density by 59-64% (per research)

**Key feature:** CWE checklist of the 10 most common weaknesses in AI-generated code. When Claude edits security-sensitive files, it sees this checklist and checks against it.

**Why this matters:** AI-generated code has measurably higher vulnerability rates in certain categories (hardcoded credentials, injection, path traversal). This checklist creates a "pause and check" moment.

**Optimization opportunity:** The path patterns are broad — `**/*key*` matches files like `keyboard.ts`. Consider refining. The CWE list could be expanded or tailored per project type (web app vs CLI vs library).

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
8. A4: Generate configuration (CLAUDE.md, CODING_STANDARDS.md, progress.md)
9. A5: Run /skill-create
10. A5.5: Configure hooks — *new in v2.0*
11. A5.6: Configure rules — *new in v2.0*
12. A6: Clean up templates
13. A7: Present summary

**Path B (New Project):**
1. B1: Check for vision content
2. B2: Guide braindump (if no vision files)
3. B2.5: Accept inline braindump — *new in v2.0* (iterative questioning mode)
4. B3: Generate from vision (PRD, architecture, epics, stories, rules, .gitignore)
5. B4: Present summary

**Why A2.5-A2.7 matter:** The original bootstrap only detected the stack and commands. The new steps assess the project's current state more deeply — is there documentation? What's the test coverage? What does the architecture look like? This gives the developer a baseline to improve from.

**Why A5.5-A5.6 matter:** Without these, hooks and rules are generic. After bootstrap, they're tailored to the detected stack (e.g., prettier configured as the formatter, pytest as the test runner in the stop hook).

**Why B2.5 matters:** The original flow required the user to use a separate AI tool for braindumping, then save files, then re-run bootstrap. The inline mode lets users describe their idea directly and get started faster.

**Optimization opportunity:** Bootstrap is the first thing users experience. It must be robust. Test it against diverse project types: pure Python, TypeScript monorepo, Rust CLI, Swift iOS app, Go microservice. Each should detect correctly. Also test the inline braindump flow — does it ask the right questions? Are the generated stories well-scoped?

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

**Optimization opportunity:** The pre-flight checks are sequential. They could be parallelized (check PRs and verify clean tree simultaneously). Also consider: should sprint-start auto-load the next story from the backlog? Currently it doesn't (intentionally — separation of concerns), but some users might prefer it.

### /story-cycle

**File:** `.claude/skills/story-cycle/SKILL.md`
**Purpose:** Universal story delivery. The core development skill.
**Added value:** Ensures every story follows the right methodology with proper quality gates.

**Four phases:**
1. **Plan** (in plan mode) — Research, identify type, write plan with context preservation header
2. **Context Reset** — Clear exploration context, reload only plan + coding standards + relevant files
3. **Execute** — Follow the methodology for the story type (TDD for features, reproduce-first for bugs, etc.)
4. **Wrap Up** — Run tests, update docs, commit, print completion report

**The Context Reset is the most important innovation.** After planning, Claude clears its context and reloads only what's needed for execution. This prevents the "loaded too much during research, now I can't code" problem. The plan's "Story-Cycle Context" header ensures Claude knows it's in a story-cycle and what steps remain.

**10 story types** with distinct methodologies. This matters because the approach for a Feature (TDD) is fundamentally different from a Refactoring (characterization tests first) or a Spike (explore, no production code required). Using the wrong methodology leads to poor outcomes.

**New in v2.0:**
- Plans must be under 50 lines (prevents context bloat)
- Complex plans are saved to `docs/plans/` for persistence across compaction
- `ultrathink` keyword for complex planning decisions
- Multi-agent TDD guidance for Feature stories (write tests without implementation knowledge)

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

**Optimization opportunity:** The test count comparison requires checking out main to run tests, then switching back. This is slow and fragile. Consider caching the main test count in progress.md (updated per sprint-end) to avoid the branch switch. Also: the quality agents (code-quality, test-validator, security-audit) run as forked contexts — monitor their usefulness and whether they catch real issues.

### /continue

**File:** `.claude/skills/continue/SKILL.md`
**Purpose:** Resume development without losing context.
**Added value:** Prevents the "where was I?" problem that wastes the first 15 minutes of every session.

**How it works:**
1. Read latest session handoff file from `docs/sessions/` (*new in v2.0*)
2. Assess git state (branch, changes, PRs)
3. Assess project state (progress.md, backlog)
4. Determine continuation point
5. Handle pending PRs
6. Quick verification (run tests)
7. Present options and wait for direction

**Session file reading** (*new in v2.0*): The continue skill now reads structured session files written by /handoff. These contain: completed work, pending items, next steps, files to load, and warnings. This is much more reliable than trying to reconstruct context from git state alone.

**Optimization opportunity:** The continue skill loads several files (session, progress, backlog). This front-loads context consumption. Consider a "light continue" mode that only reads git state and the session file, skipping the full backlog scan.

### /handoff

**File:** `.claude/skills/handoff/SKILL.md`
**Purpose:** End a session without losing context.
**Added value:** Creates a structured handoff document that the next session can read.

**What it saves** (*enhanced in v2.0*):
- Git state (branch, uncommitted changes, PR status)
- Work completed and in-progress
- Key decisions with rationale
- Blockers and issues
- Files modified
- Test status
- Next steps (minimal first action — very specific)
- Files to load on resume
- Warnings and gotchas

**Saved to:** `docs/sessions/session-YYYY-MM-DD.md`

**Why structured files matter:** The old handoff generated a session summary in the conversation. When the conversation ended, it was gone. The new approach writes to a file that persists and can be read by /continue.

**Optimization opportunity:** Session files accumulate. Consider auto-archiving sessions older than 2 weeks. Also: should the handoff skill auto-commit the session file? Currently it doesn't — the user might want to review first.

---

## 7. Skills — Planning & Backlog

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

**Optimization opportunity:** The generated skills can be verbose. Monitor their context cost when auto-invoked. Consider a "skill summary" mode that loads a condensed version by default and the full version only when deep context is needed.

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

**Optimization opportunity:** The assertion density ratio of 1.5 is a heuristic. Track across projects — some testing styles (BDD with nested describes) naturally have lower assertion density. Consider making this configurable per project.

### /security-audit

**File:** `.claude/skills/security-audit/SKILL.md`
**Purpose:** Security review for sensitive code.
**Agent type:** general-purpose (forked context, needs Bash for security tools)
**Added value:** Catches vulnerabilities that functional tests miss.

**New in v2.0:**
- **CWE checklist:** Top 10 vulnerabilities in AI-generated code, presented as a table with specific things to check
- **Phantom package detection:** Verifies that all imported packages actually exist in the registry and aren't typosquatting attacks
- **Hardcoded secret patterns:** Regex patterns for common secret formats

**Why the CWE checklist matters:** AI-generated code has measurably higher rates of CWE-798 (hardcoded credentials), CWE-79 (XSS), and CWE-89 (SQL injection). The checklist creates a systematic check rather than relying on the AI to "remember" security best practices.

**Why phantom package detection matters:** LLMs hallucinate package names. `npm install react-auth-helper` installs... what? If that package was registered as a typosquatting attack, it could contain malware. Verification prevents this.

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
1. Codebase health (complexity, duplication, churn)
2. Code quality agent review
3. Documentation review (accuracy, efficiency, drift)
4. Dependency review (outdated, vulnerable, recently added)
5. Weekly summary (update progress.md)
6. Plan next week

**Dependency governance** (*new in v2.0*):
- Run vulnerability scanners (npm audit, pip-audit, cargo audit)
- Flag packages less than 7 days old (supply chain risk)
- Check lockfile sync
- Report on recently added dependencies with age and download counts

**Why regular maintenance matters:** Quality degrades slowly. One complex function this week, two next week. Dependencies go stale. Documentation drifts from implementation. Weekly checks catch the early signals.

**Optimization opportunity:** 1-2 hours is a significant time investment. Consider a "quick maintenance" mode (30 minutes) that only checks the most critical items (tests pass, no high-severity vulnerabilities, progress.md is current). Full maintenance can be monthly.

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

### /manual-test

**Purpose:** Generate a test plan for manual user testing.
**Added value:** Bridges the gap between automated tests and user experience validation.

### /testing-cycle

**Purpose:** Process one item of user testing feedback.
**Added value:** Structured response to user-reported issues (classify, reproduce, fix, verify).

### /UAT-cycle

**Purpose:** Execute a formal UAT test case with tracked results.
**Added value:** Formal acceptance testing with audit trail.

**How they work together:**
```
/manual-test → generates test plan → user tests manually → /testing-cycle (per issue) → /sprint-end
```

Or for formal UAT:
```
/UAT-cycle TC-001 → /UAT-cycle TC-002 → ... → results in docs/testing/UAT_COVERAGE.md
```

**Optimization opportunity:** The testing workflow skills are less mature than the development workflow skills. Monitor usage patterns — are users using all three skills or just one? Are the test plans useful? Do users prefer /testing-cycle or /UAT-cycle?

---

## 12. Skills — Utility

### /commit, /fix-issue, /pr-status, /debug-session

Small, focused skills for common operations.

| Skill | What It Does | Added Value |
|---|---|---|
| `/commit` | Generates conventional commit message | Consistent commit history |
| `/fix-issue` | Reads GitHub issue, creates fix | Structured bug-fixing workflow |
| `/pr-status` | Checks PR status and CI | Quick status check without leaving the terminal |
| `/debug-session` | Structured debugging approach | Prevents "random changes until it works" |

**Optimization opportunity:** These are simple skills with small files. They could potentially be combined into a single "utility" skill with subcommands. However, the current separation makes them easy to discover via `/skill-name`.

---

## 13. Context Management Strategy

### The Context Budget Problem

Claude Code has a finite context window. Everything loaded into it — CLAUDE.md, skill content, file contents, conversation history — consumes tokens. When the budget is exhausted, context compacts (older messages are summarized), losing detail.

### Framework's Approach

**Minimize auto-loaded content:**
- CLAUDE.md: 66 lines (was 173 in v1.0)
- progress.md: Minimal template, filled per sprint
- BACKLOG_INDEX.md: Index only, epic files loaded on demand

**Progressive disclosure:**
- Full coding standards only loaded when a skill requests them
- Architecture doc only loaded when architecture-check runs
- Technology skills only loaded when working with that technology

**Context preservation across compaction:**
- Compaction directive in CLAUDE.md tells Claude what to preserve
- Story-cycle plans have a "Story-Cycle Context" header that survives compaction
- Complex plans saved to `docs/plans/` for file-system persistence

**Context preservation across sessions:**
- /handoff writes structured session file to `docs/sessions/`
- /continue reads the latest session file
- progress.md tracks sprint state

### Token Budget Estimates

| Item | Estimated Tokens | Loaded When |
|---|---|---|
| CLAUDE.md | ~800 | Always |
| progress.md | ~200 | Always (auto-loaded) |
| BACKLOG_INDEX.md | ~300 | Always (auto-loaded) |
| A skill file | 500-1500 | When skill is invoked |
| A rule file | 200-400 | When matching file is edited |
| CODING_STANDARDS.md | ~800 | During story-cycle execution |
| TESTING_STRATEGY.md | ~2500 | When story-cycle loads it |

**Total auto-loaded overhead:** ~1300 tokens (CLAUDE.md + progress.md + BACKLOG_INDEX.md)

**Optimization opportunity:** Measure actual token consumption. If certain auto-loaded files aren't being used in most conversations, consider making them on-demand. The BACKLOG_INDEX.md auto-load might be unnecessary for debugging sessions, for example.

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
| docs/adr/*.md | Architecture Decision Records |
| docs/technical-debt.md | Technical debt inventory |

**Design principle:** Reference material that changes infrequently. Loaded only when specifically needed.

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

### High Impact

1. **Measure actual token consumption** — Instrument a few sessions to measure how many tokens each auto-loaded file consumes. Trim the most expensive low-value content.

2. **Test bootstrap against diverse projects** — Run /bootstrap against 5+ different project types and record: detection accuracy, command correctness, generated skill quality. This is the highest-leverage test because bootstrap is every user's first experience.

3. **Validate test protection gates** — Create a test project, deliberately weaken tests, and verify that /sprint-end catches it. This is the core v2.0 value proposition.

4. **Monitor hook behavior** — Enable all three hooks on a real project and track: how often they trigger, false positive rate, whether the self-correction loop resolves issues or creates loops.

### Medium Impact

5. **Automate metrics collection** — The retrospective skill's metrics dashboard is mostly manual. A `scripts/metrics.sh` that computes test count, coverage, churn, and LOC from git would make retrospectives much faster.

6. **Session file lifecycle** — Define when old session files get archived or deleted. Without this, `docs/sessions/` will grow indefinitely.

7. **Skill size audit** — Some skills are long (story-cycle is ~200 lines). When loaded, they consume significant context. Consider a "skill summary" mode for large skills.

8. **Rule path refinement** — The security rule's `**/*key*` pattern matches too broadly. Audit all rule paths against a real project to check for false matches.

### Lower Impact

9. **install.sh optimization** — Currently clones the full repo. Consider using `git archive` or a release tarball for faster, lighter installation.

10. **Worktree integration depth** — The parallel-work skill is new. Test it with 2-3 concurrent Claude Code instances to verify coordination works.

11. **llms.txt auto-update** — Auto-generate llms.txt content during /bootstrap based on actual project files.

---

## 18. Known Limitations

### Context Window Constraints

- **Story size ceiling:** Even with careful context management, very large stories (touching 10+ files) may exhaust the context window. The 5-8 file guideline in /ideate is a mitigation, not a guarantee.
- **Compaction loss:** When context compacts, nuanced decisions from early in the conversation may be lost. The compaction directive in CLAUDE.md helps but can't prevent all loss.

### Advisory vs Deterministic

- **Rules are advisory:** Claude can technically ignore rules. The testing, security, and documentation rules are strong guidance, but not unbypassable. Critical protections should be hooks (deterministic), not just rules.
- **Skill compliance varies:** Skills are markdown instructions. Claude follows them well most of the time, but complex multi-step skills (like story-cycle's 4-phase flow) sometimes have steps skipped or combined.

### Git Workflow Assumptions

- **GitHub-centric:** The framework assumes GitHub (gh CLI, GitHub PRs, GitHub CI). GitLab or Bitbucket users would need to adapt sprint-end and pr-status skills.
- **Single-developer optimized:** The sprint workflow works best for solo developers or small teams. Large teams with multiple concurrent PRs may need adapted branch naming and merge strategies.

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
