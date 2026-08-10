<p align="center">
  <img src="assets/banner.svg" alt="Exosuit — Suit up. Build anything." width="100%">
</p>

<p align="center">
  One idea is enough. Exosuit wraps Claude Code in a full engineering organization: it interrogates your vision, pressure-tests every assumption, plans the build, and enforces tested, verified shipping.
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

You're not engineering software. You're prompting and hoping, generating plausible code with no discipline behind it.

This isn't a niche complaint. [Veracode's 2025 GenAI report](https://www.veracode.com/blog/genai-code-security-report/) found AI models introduce an OWASP Top-10 vulnerability in **45% of code tasks**, and [Stack Overflow's 2025 survey](https://survey.stackoverflow.co/2025/) found more developers actively **distrust** AI output accuracy (46%) than trust it (33%).

**Exosuit fixes this.** Not with guidelines the AI can ignore, but with deterministic hooks that physically block bad patterns, structured workflows that enforce TDD, and quality gates that require evidence before anything ships. **Hooks, not hopes.**

## What It Does

A drop-in development framework for [Claude Code](https://claude.com/claude-code) that adds 43 slash commands, 13 enforcement hooks, 8 specialized agents, and a complete sprint-based development workflow to any project. Install it in 30 seconds. Run `/bootstrap`. Start building like a professional.

- **Hooks block bad behavior:** force push, leaked secrets, skipped tests, premature "done" claims. These are deterministic shell scripts, not suggestions the AI can skip.
- **TDD is the default:** tests before implementation, always. The framework plans tests first, writes them first, then implements to pass them.
- **Sprints keep scope bounded:** small increments with forced checkpoints prevent the context window death spiral.
- **Git stays clean:** feature branches, conventional commits, squash merge to main. Dangerous commands are blocked at the hook level.
- **Sessions persist:** hand off with `/handoff`, resume with `/continue`. No context is lost between sessions.
- **Any language, any project:** Python, TypeScript, Go, Rust, Ruby, Java, PHP, Dart, C#, Swift, Kotlin, C/C++. The framework detects your stack and configures itself.
- **Verification is non-negotiable:** "it should work" is not accepted. Fresh test output is required before any completion claim.

## Where Exosuit Fits

Structured AI development is a genuinely good neighborhood, and Exosuit stands on its shoulders. [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) pioneered deep agile planning with specialized agents. [Superpowers](https://github.com/obra/superpowers) proved a skills-based methodology could feel native to Claude Code. GitHub's [spec-kit](https://github.com/github/spec-kit) brought spec-driven development to the mainstream. [CCPM](https://github.com/automazeio/ccpm) turned GitHub Issues into a real coordination backbone for parallel agents. [SuperClaude](https://github.com/SuperClaude-Org/SuperClaude_Framework) showed how far behavioral configuration can go, and [tdd-guard](https://github.com/nizos/tdd-guard)/[Probity](https://github.com/nizos/probity) built serious deterministic TDD gates. If one of those matches how you work, use it. They're good tools built by people who care about the same problem.

Exosuit's bet is a specific *combination* none of them focuses on. **Elicitation is mandatory:** The Interrogation happens before code exists, and everything it produces persists into files that every later command actually reads. **Enforcement is deterministic:** exit-code hooks rather than instructions the model can drift away from. Everything else in the framework exists to serve that pairing.

If you build or maintain one of these projects: let's compare notes. The enforcement layer is portable, the integration-test findings are public, and there's an open door in [Discussions](https://github.com/joris887/exosuit/discussions).

## Quick Start

Install into your project, existing repo or new. **macOS / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/joris887/exosuit/main/install.sh | bash
```

**Windows** (needs [Git for Windows](https://git-scm.com/download/win), which Claude Code requires anyway):

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/joris887/exosuit/main/install.ps1 | iex"
```

Then open Claude Code:

```
/bootstrap          # detects your stack, configures everything
/sprint-start       # creates a clean feature branch
/story-cycle "add user authentication"   # plan → TDD → implement → verify → commit
/sprint-end         # quality gates → PR → merge to main
```

That's it. Four commands from zero to shipped PR.

## Your First Session

After install, everything starts with `/bootstrap`. What happens next depends on your situation.

**Take your time with this step.** For an existing repo, bootstrap finishes in minutes. For a new project it starts the discovery interview, and that can take an hour or more. This is deliberate. It is where the deep elicitation happens: expect questions about your idea that you have never asked yourself, and your honest answers become the foundation of everything the framework builds afterwards. Rushing here trades an hour of thinking for weeks of building the wrong thing.

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

`/bootstrap` detects an empty project and launches `/discover`, **The Interrogation**: a deep, research-backed elicitation that pressure-tests your idea before a single line of code exists. It challenges your assumptions, runs a pre-mortem, and makes you declare kill criteria. Your project is built from what survives:

```
What are you building?
> "A marketplace where neighbors rent out their driveways as parking spots"

Classifying... → Marketplace archetype, Standard scale

Phase 1: Classification ████████░░░░ 2/7
  Which side do you win first: drivers who need a spot, or owners with an empty driveway?
  What does a driver do today when there is no parking near their destination?
  Why would a homeowner let a stranger park on their property?

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

This is not a generic questionnaire. `/discover` selects from **11 project archetypes** (utility, marketplace, developer tool, creative expression, etc.) and asks questions specific to your project type.

### Just want to build something fast

```
/build "a habit tracker with streaks and weekly progress emails"
```

`/build` handles everything (setup, planning, implementation) with plain-English output. No framework knowledge needed.

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

## Profiles: Choose Your Level of Ceremony

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

Key insight: the enforcement layer is deterministic; hooks are shell scripts that the AI cannot bypass. The workflow layer is advisory; it guides but doesn't force. When something *must* happen, it lives in enforcement.

## All Commands

### Core Workflow
| Command | What it does |
|---|---|
| `/bootstrap` | First-run setup: detect stack, configure framework, assess readiness |
| `/quickstart` | Guided tour of the framework before your first sprint |
| `/discover` | The Interrogation: deep guided elicitation for new projects (11 archetypes) |
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
| `/backlog-review` | Audit backlog health: story quality, readiness, staleness |
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
| `/test-validator` | Check coverage and assertion quality; detects weakened tests |
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
| `/build` | Build from plain English; handles everything automatically |
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

- **[Claude Code](https://claude.com/claude-code)**, installed and working
- **Git**, configured with your identity
- **[GitHub CLI](https://cli.github.com/)** (`gh`) for PR workflow and issue management
- **A Claude plan that fits the workload.** Exosuit is thorough by design, and thoroughness spends tokens. **Claude Max is recommended** for daily development; Pro is enough to evaluate the framework on the Lean profile. See the [FAQ](#faq) for honest details.

No language runtimes required. The framework itself is pure POSIX shell and markdown.

## FAQ

<details>
<summary><strong>Does this work with my language?</strong></summary>

Yes. The framework detects Python, TypeScript, JavaScript, Go, Rust, Ruby, Java, C#, Swift, Kotlin, PHP, Dart, and C/C++. It configures formatters, linters, test commands, and type checkers for your stack. If your language isn't listed, the safety hooks and workflow still work; you just won't get auto-formatting.
</details>

<details>
<summary><strong>Can I use this with Cursor, Windsurf, or other AI tools?</strong></summary>

The skills (slash commands) are Claude Code-specific. However, `AGENTS.md` is symlinked to `CLAUDE.md`, so tools that read `AGENTS.md` for project context get the full project configuration. The documentation layer (architecture, coding standards, ground rules) works with any tool.
</details>

<details>
<summary><strong>What if bootstrap gets something wrong?</strong></summary>

Edit `CLAUDE.md` directly; it's the source of truth for project configuration. Or re-run `/bootstrap` anytime for a fresh detection. Nothing is locked in.
</details>

<details>
<summary><strong>How do I customize the framework?</strong></summary>

Everything is plain markdown and shell scripts. Edit directly:
- **Skills** (`.claude/skills/{name}/SKILL.md`): modify workflow behavior
- **Rules** (`.claude/rules/*.md`): add or change enforcement rules
- **Hooks** (`.claude/hooks/rules/*.yaml`): configure hook behavior
- **Personal overrides** (`CLAUDE.local.md`): project-specific overrides that aren't committed
</details>

<details>
<summary><strong>Does this support parallel work on multiple stories?</strong></summary>

Yes. `/parallel-work` manages git worktrees for concurrent stories. A worktree-aware hook ensures commands run in the correct directory.
</details>

<details>
<summary><strong>What if my session ends mid-story?</strong></summary>

The framework auto-saves state before every session end. Resume with `/continue`; it detects exactly where you left off, including the current phase, branch, and plan.
</details>

<details>
<summary><strong>Is this overkill for small projects?</strong></summary>

Use the **Lean** profile. It strips ceremony to the minimum (plan → build → verify) while keeping the safety net (secrets, git protection, formatting). The framework adapts to your needs, not the other way around.
</details>

<details>
<summary><strong>What's the context window cost?</strong></summary>

~100 lines for `CLAUDE.md` (loaded every session) + ~140 lines for always-active rules. Skills load on-demand only when invoked. The framework is designed to be context-efficient; it loads less than many project README files.
</details>

<details>
<summary><strong>Do I need a Claude Max subscription?</strong></summary>

Recommended for serious use, honestly. Exosuit's value comes from doing the work most setups skip: The Interrogation researches and challenges your idea, quality gates dispatch review agents, and verification re-runs your tests before anything is called done. All of that spends tokens.

- **Claude Max:** recommended for daily development and full sprints.
- **Claude Pro:** fine for evaluating the framework and lighter projects. Pick the **Lean** profile during `/bootstrap` and expect to hit session limits on long builds.
- **API billing:** works too; cost scales with how much of the workflow you use.

Token efficiency is a known optimization area. Context budgets are already enforced (on-demand skill loading, priority-based compaction), and making the framework substantially leaner is on the roadmap. But today, don't bring a Pro plan to a Max-sized sprint.
</details>

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, development workflow, and PR guidelines.

Found a bug or have an idea? [Open an issue](https://github.com/joris887/exosuit/issues).

## License

Licensed under the [MIT License](LICENSE).
