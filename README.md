# JD-LLM Development Framework

A drop-in development framework for [Claude Code](https://claude.com/claude-code) that turns ad-hoc AI conversations into structured, sprint-based software development.

## Why Use This

- **Guard rails against AI pitfalls** — blocks hallucinated packages, weakened tests, leaked secrets, code slop, and dangerous git commands automatically
- **Sprint-based workflow** — plan, build, test, and ship in focused increments with quality gates at every stage
- **Works for any project** — Python, TypeScript, Go, Rust, Ruby, Java, and more. Solo projects to teams. Prototypes to regulated systems
- **Adaptive complexity** — three profiles (Lean, Standard, Strict) scale ceremony to match your project's needs
- **Session continuity** — hand off between sessions without losing context. Pick up exactly where you left off

## Quick Install

```bash
# Into an existing project:
curl -sL https://raw.githubusercontent.com/joris887/JD-LLM-Development_framework/main/install.sh | bash

# Or start a new project from scratch:
git clone https://github.com/joris887/JD-LLM-Development_framework.git my-project
cd my-project && rm -rf .git && git init
```

Then open Claude Code and run `/quickstart` for a guided tour, or `/bootstrap` to jump straight into setup.

## What Happens After Install

| Your situation | What happens |
|---|---|
| Existing repo with code | `/bootstrap` detects your stack, configures the framework, establishes quality standards |
| New project with an idea | `/bootstrap` guides you through project discovery and generates architecture, stories, and scaffold |
| First time with framework | `/quickstart` walks you through the basics before running bootstrap |

## Architecture

```
ENFORCEMENT (deterministic — hooks and rules that can't be skipped)
  11 hook scripts          9 auto-loaded rules
  Safety patterns          Quality gates
  Secrets detection        Edit recovery
  Formatting               Git workflow

WORKFLOW (advisory — skills that guide structured development)
  39 slash-command skills     8 native agent personas
  Sprint lifecycle            Quality analysis
  Story delivery (TDD)        Research & planning

DOCUMENTATION (context — informs decisions across sessions)
  CLAUDE.md (entry)        docs/ (reference)
  progress.md (state)      sessions/ (handoff)
  context/ (knowledge)     solutions/ (learnings)
```

## Profiles — Choose Your Level of Ceremony

The framework adapts to your project. Set during `/bootstrap` or change anytime.

| | Lean | Standard | Strict |
|---|---|---|---|
| **For** | Prototypes, MVPs, learning, hackathons | Production apps, APIs, libraries | Regulated, high-stakes, complex systems |
| **Story workflow** | Plan > Build > Verify | Full 5-phase with confidence gate | All phases + mandatory all-agent review |
| **Quality gates** | Lint + test only | Code + tests + security | All 5 agents + integration tester |
| **Documentation** | CLAUDE.md + progress.md | Full reference docs | Full + audit trail |
| **TDD** | Advisory for small changes | Required for features/bugs/refactors | Required for everything |
| **Safety hooks** | Always on | Always on | Always on + extended checks |

All profiles enforce the same safety net: secrets detection, dangerous command blocking, git protection, and test-before-ship.

## The Development Cycle

```
/bootstrap  >  /ideate  >  /sprint-start  >  /story-cycle (repeat)  >  /sprint-end
  setup         plan         branch            deliver stories           PR + merge
```

## Common Commands

| I want to... | Command |
|---|---|
| **Get started** | `/quickstart` or `/bootstrap` |
| **Resume work** | `/continue` |
| **Start a sprint** | `/sprint-start` |
| **Deliver a story** | `/story-cycle "add user auth"` |
| **Plan new work** | `/ideate "payment processing"` |
| **Explore a design** | `/brainstorm "caching strategy"` |
| **Deep research** | `/research "best auth library"` |
| **Debug an issue** | `/debug-session "TypeError in checkout"` |
| **Build (plain English)** | `/build "a REST API with auth"` |
| **End a sprint** | `/sprint-end` |
| **End a session** | `/handoff` |
| **Deploy** | `/deploy` |
| **Check status** | `/dashboard` |
| **Run quality gates** | `/quality-check [--all]` |
| **Fix a GitHub issue** | `/fix-issue 42` |
| **Undo failed work** | `/undo-work` |
| **Framework health** | `/doctor` |

## Skills Overview

### Core Workflow (6)
`/bootstrap` `/sprint-start` `/story-cycle` `/sprint-end` `/continue` `/handoff`

### Planning & Design (4)
`/brainstorm` `/ideate` `/research` `/skill-create`

### Quality & Testing (9)
`/code-quality` `/test-validator` `/security-audit` `/architecture-check` `/performance-check` `/quality-check` `/manual-test` `/testing-cycle` `/UAT-cycle`

### Debugging & Recovery (3)
`/debug-session` `/fix-issue` `/undo-work`

### Maintenance (6)
`/weekly-maintenance` `/retrospective` `/backlog-review` `/doctor` `/framework-upgrade` `/pr-status`

### Utility (6)
`/commit` `/parallel-work` `/refine-loop` `/optimize` `/skill-eval` `/custom-hooks`

### Guided Experiences (3)
`/quickstart` `/build` `/deploy` `/help-me` `/dashboard`

### Prompt Snippets (3)
`/review-security` `/explain-pattern` `/suggest-tests`

See `.claude/skills/SKILLS_INVENTORY.md` for the full reference.

## What Gets Enforced Automatically

These hooks run without you invoking them:

| What | When |
|---|---|
| Code formatting (prettier, ruff, rustfmt, gofmt, etc.) | After each edit |
| Secrets detection (AWS keys, API tokens, private keys) | After each edit |
| Dangerous command blocking (force push, rm -rf, accidental publish) | Before bash commands |
| Quality gates (lint, typecheck, tests) | Before task completion |
| Session state auto-save | Before task completion |
| Activity logging for retrospective metrics | After each tool use |
| Environment and framework health checks | At session start |

## How Story Delivery Works

When you run `/story-cycle "add login form"`:

1. **Decomposes intent** — classifies size and risk, identifies deliverables
2. **Plans** — researches codebase, checks ground rules, writes implementation plan
3. **Confidence gate** — verifies files read, tests passing, patterns found, scope bounded, no conflicts
4. **Executes by type** — TDD for features, reproduce-first for bugs, characterization tests for refactoring
5. **Self-reviews** — quality checklists, disaster prevention, failure pattern recording
6. **Wraps up** — runs test suite, creates conventional commit

Trivial changes fast-track through. High-risk changes get extra scrutiny regardless of size.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) installed and working
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Git configured with your identity
- No language runtimes required — the framework is pure POSIX shell and markdown

## FAQ

**Does this work with my language?** Yes. The framework detects Python, TypeScript, Go, Rust, Ruby, Java, C#, Swift, Kotlin, PHP, Dart, and C/C++. It configures formatters, linters, and test commands for your stack.

**Can I use this with Cursor/Windsurf/Aider?** Skills are Claude Code-specific, but `AGENTS.md` (symlinked to `CLAUDE.md`) provides project context to any AI tool.

**What if bootstrap gets something wrong?** Edit `CLAUDE.md` directly — it's the source of truth. Re-run `/bootstrap` anytime.

**How do I customize?** Edit skill files in `.claude/skills/` (they're plain markdown), hook rules in `.claude/hooks/rules/`, or use `CLAUDE.local.md` for personal overrides.

**Does this support parallel work?** Yes. `/parallel-work` manages git worktrees for concurrent stories. A worktree-aware hook ensures commands run in the right directory.

**What if my session ends mid-story?** The framework auto-saves state. Resume with `/continue` and it detects exactly where you left off.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, testing, and PR guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

MIT
