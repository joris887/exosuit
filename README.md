<h1 align="center">Exosuit</h1>

<p align="center">
  <strong>Suit up. Build anything.</strong><br>
  One idea is enough. Exosuit wraps Claude Code in a full engineering organization — it interrogates your vision, pressure-tests every assumption, plans the build, and enforces tested, verified shipping.
</p>

<p align="center">
  <em>Founder who's never written code? Engineer with a million-line repo? Same suit. Your strength, amplified.</em>
</p>

<p align="center">
  <a href="https://github.com/joris887/exosuit/actions/workflows/ci.yml"><img src="https://github.com/joris887/exosuit/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://discord.gg/XqBnP6mydA"><img src="https://img.shields.io/badge/Discord-join%20us-5865F2?logo=discord&logoColor=white" alt="Discord"></a>
  <a href="https://github.com/joris887/exosuit/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/joris887/exosuit/releases"><img src="https://img.shields.io/github/v/release/joris887/exosuit" alt="Latest Release"></a>
  <a href="https://claude.com/claude-code"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-blueviolet" alt="Built for Claude Code"></a>
  <a href="https://github.com/joris887/exosuit/stargazers"><img src="https://img.shields.io/github/stars/joris887/exosuit?style=social" alt="GitHub Stars"></a>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="docs/GETTING_STARTED.md">Getting Started</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="docs/FRAMEWORK_REFERENCE.md">Full Reference</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="https://discord.gg/XqBnP6mydA">Discord</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="https://github.com/joris887/exosuit/issues">Issues</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="CONTRIBUTING.md">Contributing</a>
</p>

---

<!-- demo GIF: assets/demo.gif — dropped in at launch -->

---

## The Problem

AI-assisted coding is powerful. It's also chaos.

Without structure, every Claude Code session drifts toward the same failure modes: scope creeps until the context window is exhausted. Tests get skipped because "the code looks right." Git history becomes a wasteland of `fix`, `update`, and `wip` commits. The AI claims "done" without running a single test. And when you start a new session, all context from the last one is gone.

You're not engineering software. You're prompting and praying — generating plausible code with no discipline behind it.

This isn't a niche complaint. [Veracode's 2025 GenAI report](https://www.veracode.com/blog/genai-code-security-report/) found AI models introduce an OWASP Top-10 vulnerability in **45% of code tasks**, and [Stack Overflow's 2025 survey](https://survey.stackoverflow.co/2025/) found more developers actively **distrust** AI output accuracy (46%) than trust it (33%).

**Exosuit fixes this.** Not with guidelines the AI can ignore, but with deterministic hooks that physically block bad patterns, structured workflows that enforce TDD, and quality gates that require evidence before anything ships. **Hooks, not hopes.**

## What It Does

A drop-in development framework for [Claude Code](https://claude.com/claude-code) that adds 43 slash commands, 13 enforcement hooks, 8 specialized agents, and a complete sprint-based development workflow to any project. Install it in 30 seconds. Run `/bootstrap`. Start building like a professional.

- **Hooks block bad behavior** — force push, leaked secrets, skipped tests, premature "done" claims. These are deterministic shell scripts, not suggestions the AI can skip.
- **TDD is the default** — tests before implementation, always. The framework plans tests first, writes them first, then implements to pass them.
- **Sprints keep scope bounded** — small increments with forced checkpoints prevent the context window death spiral.
- **Git stays clean** — feature branches, conventional commits, squash merge to main. Dangerous commands are blocked at the hook level.
- **Sessions persist** — hand off with `/handoff`, resume with `/continue`. No context is lost between sessions.
- **Any language, any project** — Python, TypeScript, Go, Rust, Ruby, Java, PHP, Dart, C#, Swift, Kotlin, C/C++. The framework detects your stack and configures itself.
- **Verification is non-negotiable** — "it should work" is not accepted. Fresh test output is required before any completion claim.

## Why Exosuit?

Every framework in this space has a planning step. Almost none can *enforce* anything — they're instructions the model can drift away from. Exosuit's difference is the combination: interrogate the idea before code exists, then enforce the discipline with hooks, not hopes.

| | Exosuit | [Superpowers](https://github.com/obra/superpowers) | [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | [spec-kit](https://github.com/github/spec-kit) | [SuperClaude](https://github.com/SuperClaude-Org/SuperClaude_Framework) | [CCPM](https://github.com/automazeio/ccpm) |
|---|---|---|---|---|---|---|
| **Pre-code idea interrogation** | Mandatory, hard-gated — 11 archetypes, assumption stress-tests, pre-mortem, kill criteria | Strong, prompt-gated | Deepest menus, but optional phase | Optional `/clarify` | Brainstorm mode (nudge) | PRD template |
| **Enforcement mechanism** | **Deterministic shell hooks** — dangerous commands, secrets, and force-pushes are blocked by exit codes, not requests | Instructions + a context-injecting hook | Instructions (MD/YAML) | Templates + slash commands | Instruction injection | Convention + GitHub Issues |
| **"Done" requires fresh test evidence** | Yes — Stop-hook quality gates run lint/tests before completion | Subagent-checked (bypassable) | No | No | No | No |
| **Session continuity** | Auto-save, `/handoff`, `/continue` | No | Partial | No | No | Via GitHub Issues |
| **Adapts ceremony to risk** | 3 profiles + per-story risk calibration | No | 3 tracks (v6) | No | No | No |
| **Runtime dependencies** | None — POSIX shell + markdown | None | Node.js 20+ | Python 3.11+ / uv | Python | GitHub CLI |

All of these are good projects — several inspired parts of Exosuit. The gap Exosuit fills is the fusion: the frameworks with deep elicitation enforce by instruction, and the tools with deterministic hooks do no elicitation. Exosuit does both.

## Quick Start

```bash
# Install into your project (existing repo or new)
curl -sL https://raw.githubusercontent.com/joris887/exosuit/main/install.sh | bash
```

Then open Claude Code:

```
/bootstrap          # detects your stack, configures everything
/sprint-start       # creates a clean feature branch
/story-cycle "add user authentication"   # plan → TDD → implement → verify → commit
/sprint-end         # quality gates → PR → merge to main
```

That's it. Four commands from zero to shipped PR.

<details>
<summary><strong>Alternative: clone and install locally</strong></summary>

```bash
git clone https://github.com/joris887/exosuit.git
cd your-project
path/to/exosuit/install.sh
```

Or start a brand new project:

```bash
git clone https://github.com/joris887/exosuit.git my-project
cd my-project && rm -rf .git && git init
```

</details>

## Your First 5 Minutes

After install, everything starts with `/bootstrap`. What happens next depends on your situation:

### Existing project with code

`/bootstrap` scans your repository and configures everything automatically:

```
Detecting stack...
  Language:   Python 3.12
  Framework:  FastAPI
  Tests:      pytest (127 tests, 72% coverage)
  Formatter:  ruff
  Linter:     ruff
  CI:         GitHub Actions

Generating configuration...
  ✓ CLAUDE.md configured
  ✓ Architecture documented
  ✓ Coding standards generated
  ✓ Testing strategy populated
  ✓ Ground rules established

Framework Readiness Report:
  TDD-first          ✓ Ready    pytest detected, 127 tests
  Git-disciplined     ✓ Ready    main branch, remote configured
  CI-enforced         ✗ Missing  No GitHub Actions workflow
  Type-safe           ⚠ Risk     No type checker configured

Foundation stories generated:
  E00-001: Configure GitHub Actions CI
  E00-002: Add type checking (mypy)
```

The framework tells you exactly what your project needs to be production-ready, then generates stories to get there.

### New project from an idea

`/bootstrap` detects an empty project and launches `/discover` — **The Interrogation**: a deep, research-backed elicitation that pressure-tests your idea before a single line of code exists. It challenges your assumptions, runs a pre-mortem, and makes you declare kill criteria — then builds your project from what survives:

```
What are you building?
> "A task management API with team workspaces"

Classifying... → Utility/Productivity archetype, Standard scale

Phase 1: Classification ████████░░░░ 2/7
  What task does this make easier?
  Who uses this day-to-day?
  What's the one thing that makes someone switch from their current tool?

Phase 2: Core Identity ████████████░░░░ 3/7
  [researching competitive landscape...]
  [5 targeted questions about your specific use case]

Phase 3: Deep Elicitation ████████████████░░░░ 4/7
  [feature mapping: MUST / IMPORTANT / NICE / CUT]
  [edge case exploration across 6 dimensions]

Phase 4: Assumption Surfacing ████████████████████░░░░ 5/7
  [surfacing and stress-testing assumptions]
  [pre-mortem: what could kill this project?]

→ Vision synthesis, backlog generation, architecture decisions
→ Ready for /sprint-start
```

Not a generic questionnaire — `/discover` selects from **11 project archetypes** (utility, marketplace, developer tool, creative expression, etc.) and asks questions specific to your project type.

### Just want to build something fast

```
/build "a REST API with authentication and rate limiting"
```

`/build` handles everything — setup, planning, implementation — with plain-English output. No framework knowledge needed.

## What Runs Behind the Scenes

While you work, the enforcement layer is always active:

| What happens | When | How |
|---|---|---|
| Code auto-formatted (prettier, ruff, rustfmt, gofmt, etc.) | Every edit | Post-edit hook |
| Secrets scanned (AWS keys, API tokens, private keys) | Every edit | Post-edit hook |
| Dangerous commands blocked (force push, `rm -rf`, `--no-verify`) | Before execution | Pre-command hook |
| Quality gates run (lint, typecheck, tests) | Before task completion | Pre-stop hook |
| Session state auto-saved | Before task completion | Pre-stop hook |
| Activity logged for metrics | Every tool use | Post-tool hook |

These aren't rules the AI reads and follows. They're shell scripts that execute deterministically. The AI cannot skip them.

## How Story Delivery Works

When you run `/story-cycle "add login form"`:

```
Phase 0: Decompose — classify size (XS→XL) and risk, identify deliverables
Phase 1: Plan     — research codebase, check ground rules, write implementation plan
                    ↳ Confidence gate: files read? tests passing? patterns found?
                      scope bounded? no conflicts? (≥85% to proceed)
Phase 2: Build    — TDD for features, reproduce-first for bugs,
                    characterization tests for refactors
Phase 3: Review   — quality checklists, disaster prevention, failure recording
Phase 4: Ship     — run full test suite, create conventional commit
```

Trivial changes (XS) fast-track through. High-risk changes get extra scrutiny regardless of size.

## Profiles — Choose Your Level of Ceremony

Set during `/bootstrap`. Change anytime.

| | Lean | Standard | Strict |
|---|---|---|---|
| **Best for** | Prototypes, MVPs, hackathons | Production apps, APIs, libraries | Regulated, high-stakes systems |
| **Story workflow** | Plan → Build → Verify | Full 5-phase with confidence gate | All phases + mandatory multi-agent review |
| **Quality gates** | Lint + test | Code + tests + security | All 8 agents + integration tester |
| **TDD** | Advisory for small changes | Required for features/bugs/refactors | Required for everything |
| **Safety hooks** | Always on | Always on | Always on + extended checks |

All profiles enforce the same safety net: secrets detection, dangerous command blocking, git protection.

## Architecture

Three layers, from most to least deterministic:

```
ENFORCEMENT — hooks and rules that cannot be skipped
  13 hook scripts              9 auto-loaded rules
  ├─ Auto-format on edit       ├─ Never weaken test assertions
  ├─ Block secrets in code     ├─ CWE top-10 security checklist
  ├─ Block force push          ├─ No AI filler comments
  ├─ Require evidence for      ├─ Conventional commits
  │  completion claims         └─ Evidence before "done"
  └─ Auto-save session state

WORKFLOW — skills and agents that guide structured development
  43 slash commands            8 native agents
  ├─ Sprint lifecycle          ├─ Code reviewer
  ├─ Story delivery (TDD)     ├─ Security analyst
  ├─ Planning & discovery      ├─ Test strategist
  └─ Quality analysis          └─ Architecture advisor

DOCUMENTATION — project context that persists across sessions
  CLAUDE.md (entry)          docs/context/* (knowledge base)
  progress.md (state)        docs/sessions/ (handoff)
```

Key insight: The enforcement layer is deterministic — hooks are shell scripts that the AI cannot bypass. The workflow layer is advisory — it guides but doesn't force. When something *must* happen, it lives in enforcement.

## All Commands

### Core Workflow
| Command | What it does |
|---|---|
| `/bootstrap` | First-run setup — detect stack, configure framework, assess readiness |
| `/quickstart` | Guided tour of the framework before your first sprint |
| `/discover` | The Interrogation — deep guided elicitation for new projects (11 archetypes) |
| `/sprint-start` | Create sprint branch, select stories |
| `/story-cycle` | Deliver a story with TDD + quality gates |
| `/sprint-end` | Quality gates → PR → merge to main |
| `/pr-status` | Check open PRs and decide next steps |
| `/continue` | Resume exactly where you left off |
| `/handoff` | Save session state for next time |

### Planning & Design
| Command | What it does |
|---|---|
| `/ideate` | Decompose ideas into sized, estimated stories |
| `/backlog-review` | Audit backlog health — story quality, readiness, staleness |
| `/brainstorm` | Explore designs, tradeoffs, approaches |
| `/research` | Deep web + codebase research with source citations |
| `/phase-review` | Evaluate what you built, plan the next phase |

### Quality & Testing
| Command | What it does |
|---|---|
| `/quality-check` | Run all quality gates manually |
| `/code-quality` | Deep code review with multi-agent analysis |
| `/security-audit` | Security-focused review (OWASP, CWE) |
| `/architecture-check` | Verify architecture against ground rules |
| `/test-validator` | Check coverage and assertion quality — detects weakened tests |
| `/performance-check` | Find N+1 queries, blocking I/O, memory leaks, scaling issues |
| `/testing-cycle` | Process test feedback into fixes |
| `/UAT-cycle` | User acceptance test case execution |
| `/claude-sense-check` | Batch-verify UAT test cases against actual code |
| `/manual-test` | Generate test plans for manual verification |

### Debugging & Recovery
| Command | What it does |
|---|---|
| `/debug-session` | Structured debugging with hypothesis tracking |
| `/fix-issue` | Fix a GitHub issue (reads context, plans, implements, PRs) |
| `/undo-work` | Safely revert failed implementations |

### Guided Experiences
| Command | What it does |
|---|---|
| `/build` | Build from plain English — handles everything automatically |
| `/deploy` | Guided deployment setup |
| `/dashboard` | Visual overview of sprint progress and project health |
| `/help-me` | Context-aware help |

### Maintenance & Utilities
| Command | What it does |
|---|---|
| `/doctor` | Framework health check and diagnostics |
| `/retrospective` | Sprint retro with metric analysis |
| `/weekly-maintenance` | Dependency updates, debt tracking, rule health |
| `/parallel-work` | Manage git worktrees for concurrent stories |
| `/commit` | Conventional commit with quality checks |
| `/refine-loop` | Iterative refinement until criteria met |
| `/optimize` | Optimize a specific metric (performance, bundle size, etc.) |
| `/framework-upgrade` | Upgrade framework to latest version |
| `/skill-create` | Generate project-specific skills from codebase analysis |
| `/skill-eval` | Evaluate skill effectiveness with metrics |
| `/custom-hooks` | Create and register project-specific hooks |
| `/uninstall` | Cleanly remove the framework, keeping your project intact |

## Supported Languages

The framework auto-detects your stack during `/bootstrap` and configures formatters, linters, test runners, and type checkers:

| Language | Formatter | Linter | Test Runner | Type Checker |
|---|---|---|---|---|
| Python | ruff | ruff | pytest | mypy / pyright |
| TypeScript | prettier | eslint | vitest / jest | tsc |
| JavaScript | prettier | eslint | vitest / jest | — |
| Go | gofmt | golangci-lint | go test | (built-in) |
| Rust | rustfmt | clippy | cargo test | (built-in) |
| Ruby | rubocop | rubocop | rspec / minitest | sorbet |
| Java | google-java-format | checkstyle | junit / maven | (built-in) |
| C# | dotnet format | dotnet analyzers | dotnet test | (built-in) |
| PHP | php-cs-fixer | phpstan | phpunit | phpstan |
| Dart | dart format | dart analyze | dart test | (built-in) |
| Swift | swift-format | swiftlint | XCTest | (built-in) |
| Kotlin | ktlint | detekt | junit | (built-in) |
| C/C++ | clang-format | clang-tidy | ctest / gtest | — |

Only tools that are already installed get configured. Bootstrap offers to install missing ones.

## Design Philosophy

The framework is built on a simple observation: **AI is great at generating code, but terrible at engineering discipline.** It doesn't protect existing tests, respect architectural boundaries, verify its own claims, or maintain conventions. On simple projects this is manageable. On real projects with production users and team conventions, it's a cycle of building and breaking.

The framework solves this with three ideas:

1. **Enforce what matters.** If something must happen (format code, scan for secrets, verify before "done"), it goes in the enforcement layer as a deterministic hook. The AI cannot skip it.

2. **Guide everything else.** If something should happen (TDD workflow, confidence gates, sprint structure), it goes in the workflow layer as a skill. The AI follows it because the methodology is sound, but nothing breaks if a step is adapted.

3. **Adapt to the project.** A hackathon prototype and a regulated medical system need different amounts of ceremony. Three profiles (Lean, Standard, Strict) scale the workflow. Per-story risk calibration adds scrutiny where it matters, regardless of profile.

## Prerequisites

- **[Claude Code](https://claude.com/claude-code)** — installed and working
- **Git** — configured with your identity
- **[GitHub CLI](https://cli.github.com/)** (`gh`) — for PR workflow and issue management

No language runtimes required. The framework itself is pure POSIX shell and markdown.

## FAQ

<details>
<summary><strong>Does this work with my language?</strong></summary>

Yes. The framework detects Python, TypeScript, JavaScript, Go, Rust, Ruby, Java, C#, Swift, Kotlin, PHP, Dart, and C/C++. It configures formatters, linters, test commands, and type checkers for your stack. If your language isn't listed, the safety hooks and workflow still work — you just won't get auto-formatting.
</details>

<details>
<summary><strong>Can I use this with Cursor, Windsurf, or other AI tools?</strong></summary>

The skills (slash commands) are Claude Code-specific. However, `AGENTS.md` is symlinked to `CLAUDE.md`, so tools that read `AGENTS.md` for project context get the full project configuration. The documentation layer (architecture, coding standards, ground rules) works with any tool.
</details>

<details>
<summary><strong>What if bootstrap gets something wrong?</strong></summary>

Edit `CLAUDE.md` directly — it's the source of truth for project configuration. Or re-run `/bootstrap` anytime for a fresh detection. Nothing is locked in.
</details>

<details>
<summary><strong>How do I customize the framework?</strong></summary>

Everything is plain markdown and shell scripts — edit directly:
- **Skills:** `.claude/skills/{name}/SKILL.md` — modify workflow behavior
- **Rules:** `.claude/rules/*.md` — add or change enforcement rules
- **Hooks:** `.claude/hooks/rules/*.yaml` — configure hook behavior
- **Personal overrides:** `CLAUDE.local.md` — project-specific overrides that aren't committed
</details>

<details>
<summary><strong>Does this support parallel work on multiple stories?</strong></summary>

Yes. `/parallel-work` manages git worktrees for concurrent stories. A worktree-aware hook ensures commands run in the correct directory.
</details>

<details>
<summary><strong>What if my session ends mid-story?</strong></summary>

The framework auto-saves state before every session end. Resume with `/continue` — it detects exactly where you left off, including the current phase, branch, and plan.
</details>

<details>
<summary><strong>Is this overkill for small projects?</strong></summary>

Use the **Lean** profile. It strips ceremony to the minimum (plan → build → verify) while keeping the safety net (secrets, git protection, formatting). The framework adapts to your needs, not the other way around.
</details>

<details>
<summary><strong>What's the context window cost?</strong></summary>

~100 lines for `CLAUDE.md` (loaded every session) + ~140 lines for always-active rules. Skills load on-demand only when invoked. The framework is designed to be context-efficient — it loads less than many project README files.
</details>

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, development workflow, and PR guidelines.

Found a bug or have an idea? [Open an issue](https://github.com/joris887/exosuit/issues).

## License

Licensed under the [MIT License](LICENSE).
