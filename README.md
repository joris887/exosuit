# JD-LLM Development Framework

A drop-in development framework for [Claude Code](https://claude.com/claude-code). Provides structured sprint workflows, TDD practices, quality gates, and backlog management — all encoded as Claude Code skills. Drop it into any repo, run `/bootstrap`, and start building.

## What It Does

This framework turns Claude Code into a structured development partner. Instead of ad-hoc conversations, you get:

- **Sprint-based workflow** — Plan, build, test, ship in focused increments
- **TDD-first methodology** — Tests define the contract before implementation
- **Quality gates** — Automated checks for code quality, test integrity, security, and architecture
- **Backlog management** — Decompose ideas into properly scoped stories with acceptance criteria
- **Session continuity** — Hand off between sessions without losing context
- **Guard rails** — Prevent common AI pitfalls: hallucinated APIs, weakened tests, code slop, phantom packages
- **Error learning** — Cross-session failure patterns prevent repeating the same mistakes
- **Confidence gates** — Pre-implementation assessment prevents wrong-direction work
- **Solutions database** — Searchable learnings from completed stories compound across sessions
- **Grep-first exploration** — Targeted file discovery reduces context consumption in planning phases

## Prerequisites

- [Claude Code](https://claude.com/claude-code) installed and working
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Git configured with your identity
- No language runtimes required — the framework itself is pure POSIX shell and markdown

## Quick Start

### Drop into an Existing Project

```bash
# Option 1: Install script (recommended)
curl -sL https://raw.githubusercontent.com/joris887/JD-LLM-Development_framework/main/install.sh | bash

# Option 2: Manual install
git clone https://github.com/joris887/JD-LLM-Development_framework.git /tmp/jd-framework
cp -rn /tmp/jd-framework/.claude .
cp -rn /tmp/jd-framework/docs .
cp -rn /tmp/jd-framework/vision .
cp -n /tmp/jd-framework/CLAUDE.md .
cp -n /tmp/jd-framework/.gitignore .
rm -rf /tmp/jd-framework
```

Then open Claude Code and run:

```
/bootstrap
```

Bootstrap detects your languages, package manager, test framework, linter, and CI/CD. It configures `CLAUDE.md`, generates coding standards, establishes architectural ground rules, and creates technology-specific skills for your stack.

### Start a New Project from Scratch

```bash
git clone https://github.com/joris887/JD-LLM-Development_framework.git my-project
cd my-project
rm -rf .git && git init
```

Then open Claude Code and either:

1. **Quick start:** Run `/bootstrap` and describe your idea when prompted
2. **Deep research first:** Copy the prompt from `vision/BRAINDUMP_PROMPT.md` into a Claude Project (or any AI research tool), braindump your idea, save the structured output to `vision/`, then run `/bootstrap`

Bootstrap reads the vision files and generates: PRD, architecture, epic structure, typed stories, and full project configuration.

## What /bootstrap Does

| Your situation | What happens |
|---|---|
| Existing repo with code | Detects stack, configures CLAUDE.md, establishes ground rules, generates coding standards and tech skills |
| Empty repo with vision files | Generates PRD, architecture, epics, stories from your research output |
| Empty repo, no vision | Guides you through the braindump flow or accepts your idea inline |

## The Development Cycle

```
/bootstrap → /ideate → /sprint-start → /story-cycle (repeat) → /sprint-end
   setup      plan       branch          deliver stories        PR + merge
```

### Starting a Session

| Situation | Command |
|---|---|
| First time with this project | `/bootstrap` |
| Resuming work | `/continue` |
| Starting a new sprint | `/sprint-start` |

### During Development

| I want to... | Command |
|---|---|
| Deliver a story | `/story-cycle "add user authentication"` |
| Explore a design | `/brainstorm "payment processing"` |
| Plan new work | `/ideate "payment processing"` |
| Debug an issue | `/debug-session "TypeError in checkout"` |
| Quick commit | `/commit` |
| Fix a GitHub issue | `/fix-issue 42` |
| Undo failed work | `/undo-work` |

### Session Management

| I want to... | Command |
|---|---|
| Resume where I left off | `/continue` |
| End session with handoff | `/handoff` |

### Testing Workflow

```
/sprint-start → /manual-test → user tests → /testing-cycle (repeat) → /sprint-end
```

For structured UAT with tracked test cases:

```
/sprint-start → /UAT-cycle (repeat per test case) → /sprint-end
```

| I want to... | Command |
|---|---|
| Generate a test plan | `/manual-test` |
| Process test feedback | `/testing-cycle "login button unresponsive"` |
| Run a UAT test case | `/UAT-cycle UAT-001` |

### Completing Work

| I want to... | Command |
|---|---|
| Finish a sprint | `/sprint-end` |
| Check PR status | `/pr-status` |
| Weekly health check | `/weekly-maintenance` |
| Sprint retrospective | `/retrospective` |
| Review backlog health | `/backlog-review` |

## How Story Delivery Works

When you run `/story-cycle "add login form"`, the framework:

1. **Decomposes intent** — Identifies all deliverables, classifies size (trivial/small/standard) and risk (domain, integration, reversibility)
2. **Facilitates discovery** — Asks clarifying questions before making assumptions, offers depth exploration for complex areas
3. **Plans in plan mode** — Researches codebase, identifies story type, scans for ambiguity, checks architectural ground rules, writes a specification + implementation plan with workflow state tracking
4. **Waits for your approval** — You review the plan before any code is written
5. **Assesses confidence** — Scores readiness across 5 dimensions before writing any code; low confidence triggers clarification or more research
6. **Executes by story type** — TDD for features, reproduce-first for bugs, characterization tests for refactoring
7. **Self-reviews** — Runs quality checklists, adversarial disaster prevention analysis, records failure patterns for cross-session learning, and verifies acceptance criteria with evidence
8. **Wraps up** — Runs test suite, creates conventional commit

Trivial changes (rename, typo) skip the full planning workflow and go straight to implementation. Risk-calibrated depth ensures high-risk changes get extra scrutiny regardless of size.

## Story Types

The `/story-cycle` skill adapts methodology by story type:

| Type | Approach |
|---|---|
| Feature | TDD: RED-GREEN-REFACTOR |
| Bug Fix | Reproduce → Test → Fix → Verify |
| Refactoring | Characterization tests → Refactor → Verify |
| Spike/Research | Explore → Document → Decide |
| Infrastructure | Plan → Implement → Smoke Test |
| Testing | Design → Generate → Validate |
| Documentation | Gather → Generate → Review |
| Security | Threat model → Implement → Audit |
| Performance | Baseline → Optimize → Benchmark |
| Skill/Tooling | Design → Build → Document |

## What Gets Enforced Automatically

The framework includes hooks that run automatically — you don't need to invoke them:

| What | How | When |
|---|---|---|
| Code formatting | Auto-formats files after every edit (prettier, ruff, rustfmt, etc.) | After each edit |
| Secrets detection | Scans for leaked credentials (AWS keys, API tokens, private keys) | After each edit |
| Dangerous command blocking | Prevents force push, `rm -rf`, accidental publishing, destructive DB ops, template repo operations | Before bash commands |
| Worktree directory fix | Transparently ensures Bash commands execute in the correct worktree directory | Before bash commands (subagents too) |
| Quality gates | Runs lint, typecheck, and test suite before allowing completion | Before task completion |
| Session state auto-save | Saves branch, commits, and changes for `/continue` recovery | Before task completion |
| Activity logging | Logs tool usage and skill lifecycle events for retrospective metrics | After each tool use |
| Environment checks | Validates framework setup, warns about stale sessions | At session start |

## Full Skill Reference

### Core Workflow

| Skill | Purpose |
|---|---|
| `/bootstrap` | First-run setup — detect stack or generate from vision |
| `/sprint-start` | Pre-flight checks + create sprint branch (supports `--worktree`) |
| `/story-cycle` | Universal story delivery with confidence gate, risk-calibrated planning, grep-first exploration, research decision gate, solutions database, intent-based security, adaptive depth, TDD, wave execution, parallel streams, error learning, failure state persistence, and verification |
| `/sprint-end` | Quality gates, compliance ledger, documentation updates, PR creation, squash merge to main |
| `/continue` | Smart session resumption with failure state detection, project health scan, git state, and handoff files |
| `/handoff` | End session with structured handoff document |

### Planning & Design

| Skill | Purpose |
|---|---|
| `/brainstorm` | Design exploration with 2-3 alternative approaches, tradeoffs, and persisted design documents |
| `/ideate` | Decompose ideas into properly typed, scoped backlog stories |
| `/skill-create` | Generate technology-specific skills, rules, and hook configs for your stack |

### Quality Agents (auto-invoked during `/sprint-end`)

| Skill | Purpose | Trigger |
|---|---|---|
| `/code-quality` | Complexity, duplication, pattern analysis (confidence-scored) | After code changes |
| `/test-validator` | Coverage, TDD compliance, test quality (confidence-scored) | After implementation |
| `/security-audit` | Vulnerability review for sensitive code (confidence-scored) | On auth/credential code |
| `/architecture-check` | Validate module boundaries and architectural drift | On major changes |

### Testing

| Skill | Purpose |
|---|---|
| `/manual-test` | Generate test plan from recent changes |
| `/testing-cycle` | Process one user testing feedback item (classify → fix or log) |
| `/UAT-cycle` | Execute a formal UAT test case with tracked results |

### Debugging & Recovery

| Skill | Purpose |
|---|---|
| `/debug-session` | 5-phase structured debugging with root cause tracing and error learning |
| `/fix-issue` | Fix a GitHub issue with TDD, branch, and PR |
| `/undo-work` | Safely revert failed implementation attempts (stash, discard, or reset) |

### Maintenance & Review

| Skill | Purpose |
|---|---|
| `/weekly-maintenance` | Comprehensive weekly health check with rule health review (1-2 hours, Friday recommended) |
| `/retrospective` | Sprint retrospective using 4Ls framework with metrics dashboard |
| `/backlog-review` | Backlog health analysis — coverage, quality, dependencies |
| `/doctor` | Framework health check — validate config, hooks, dependencies |
| `/pr-status` | Check open PR status and available actions |

### Utility

| Skill | Purpose |
|---|---|
| `/commit` | Guided conventional commit |
| `/parallel-work` | Manage git worktrees for concurrent Claude Code instances |
| `/skill-eval` | Test, measure, A/B compare, baseline capture, and regression detection for skills |
| `/refine-loop` | Iterative self-improvement until completion criteria met |

### Prompt Snippets (lightweight, no workflow)

| Snippet | Purpose |
|---|---|
| `/review-security` | Security review of a specific file |
| `/explain-pattern` | Explain a code pattern as used in this codebase |
| `/suggest-tests` | Suggest test cases for a file |

## File Structure

```
.claude/
  skills/               # 33 skills, each with YAML frontmatter + optional micro-components
    <skill>/
      SKILL.md          # Lean entry point (<150 lines)
      references/       # Detailed docs loaded on demand (elicitation techniques, disaster prevention, etc.)
      scripts/          # Executable helper scripts (--help supported)
      assets/           # Output templates — copy, don't read (debug reports, test plans, etc.)
    skills-registry.json          # Machine-readable skill index
    skills-registry.schema.json   # JSON Schema for registry validation
    SKILLS_INVENTORY.md           # Full skill inventory
    SKILL_TEMPLATE.md             # Skill creation guidelines
  commands/
    review-pr-ci.md     # Non-interactive CI PR review command
  agents/               # 7 native agent personas (architecture-reviewer, code-reviewer, codebase-explorer, performance-engineer, research-analyst, security-analyst, spec-reviewer)
  prompts/              # 17 prompt snippets and micro-components
  rules/                # Path-scoped enforcement rules (9 rules)
  hooks/                # Hook scripts (10 hooks) — format, safety, quality, logging, worktree fix, session, status
  settings.json         # Claude Code hook configuration
.github/
  workflows/
    claude-pr-review.yml  # CI-based Claude Code PR review
  ISSUE_TEMPLATE/         # Bug report and feature request forms
  pull_request_template.md
  CODEOWNERS              # Require human review on tests, security, deps
docs/
  reference/
    BACKLOG_INDEX.md    # Epic status overview
    CODING_STANDARDS.md # Code conventions (generated by /bootstrap)
    TESTING_STRATEGY.md # TDD workflow + quality criteria
    GROUND_RULES.md     # Architectural principles (generated by /bootstrap)
    MCP_INTEGRATION.md  # MCP server selection and integration guide
    backlog/            # Epic files with stories
  architecture/
    ARCHITECTURE.md     # System architecture
  adr/                  # Architecture Decision Records
  sprints/              # Sprint spec files
  context/              # Persistent project context knowledge base (6 files, includes error patterns)
  solutions/            # Searchable solutions database — learnings from completed stories
  brainstorms/          # Persisted design exploration documents from /brainstorm
  sessions/             # Session handoff files + activity logs
  plans/                # Saved plan files for context persistence
  testing/              # UAT coverage docs
  progress.md           # Sprint history + metrics
  technical-debt.md     # Technical debt inventory
scripts/
  pm/                   # Read-only query scripts (status, standup, next-story, metrics)
vision/                 # New project braindump flow
CLAUDE.md               # Framework entry point (auto-loaded every session)
AGENTS.md               # Cross-tool compatibility (symlink → CLAUDE.md)
llms.txt                # LLM-friendly project index
install.sh              # Drop-in installer script
```

## FAQ

**Q: Can I use this with other AI coding tools (Cursor, Aider, Windsurf)?**
A: The skills are Claude Code-specific, but `AGENTS.md` (symlinked to `CLAUDE.md`) provides cross-tool compatibility for project context. Other tools pick up the project overview, commands, and conventions — just not the slash command workflows.

**Q: Does this work with monorepos?**
A: Yes. Run `/bootstrap` at the monorepo root. It detects multiple languages and generates skills for each.

**Q: What if `/bootstrap` gets something wrong?**
A: Edit `CLAUDE.md` directly — it's the source of truth. You can re-run `/bootstrap` anytime to re-detect.

**Q: How do I customize the workflow?**
A: Edit the skill files in `.claude/skills/`. They're plain markdown — modify any step, add rules, change the flow. Use `CLAUDE.local.md` for personal overrides (gitignored).

**Q: What about parallel work on multiple stories?**
A: Use `/sprint-start --worktree` or `/parallel-work` to manage concurrent stories in isolated git worktrees with separate Claude Code instances. A worktree-aware bash hook automatically ensures commands execute in the correct directory.

**Q: Can a single story be parallelized?**
A: Yes. For STANDARD-size stories with non-overlapping file scopes, `/story-cycle` can decompose work into parallel streams (e.g., database layer, API layer, tests) and execute them simultaneously in separate worktrees. This is offered as an optional Phase 3a.

**Q: What is the project context knowledge base?**
A: Six files in `docs/context/` that capture deep project knowledge (overview, tech stack, patterns, structure, product domain, and error patterns). Generated by `/bootstrap`, incrementally updated by `/sprint-end` and skill workflows, and loaded by `/continue`. Unlike session handoffs which capture what happened, context files capture what the project IS — and this knowledge compounds across sessions. The error patterns file specifically learns from implementation failures so future sessions avoid the same mistakes.

**Q: What is the solutions database?**
A: A `docs/solutions/` directory where completed stories can produce structured learnings documents with searchable YAML frontmatter (title, tags, module, component). During future story planning, Phase 1b greps these documents to find prior learnings on affected modules — preventing rediscovery of known patterns and integration gotchas. Created by `/bootstrap`, populated by `/story-cycle` Phase 4.

**Q: What is grep-first exploration?**
A: Instead of always launching 3 parallel agents to explore the codebase, Phase 1b now extracts key terms from the story description and runs targeted Grep calls first. This pre-filters candidates, reducing file reads from O(n) to O(relevant). The number of exploration streams also scales with story size — TRIVIAL skips it, SMALL uses grep-first only, STANDARD adds agents.

**Q: What is the confidence gate?**
A: Before writing any implementation code, story-cycle Phase 2.5 scores confidence across 5 dimensions (ambiguity cleared, architecture compliant, patterns matched, test strategy clear, dependencies verified). Scores ≥85 proceed; 70-84 ask for clarification; <70 return to research. This prevents wasting an entire implementation phase on a wrong-direction approach.

**Q: Does the framework support MCP servers?**
A: Yes. All skills work without MCP servers, but when available, they enhance specific workflows (documentation lookup, persistent memory, web research, browser automation, code intelligence). See `docs/reference/MCP_INTEGRATION.md` for the selection guide. Bootstrap optionally detects installed servers.

**Q: What is fast-track mode in story-cycle?**
A: Changes are classified by both size (trivial/small/standard) and risk (domain, integration surface, reversibility). Trivial low-risk changes skip the full planning workflow. High-risk changes get extra quality gates regardless of size. The classification happens automatically.

**Q: What is the depth exploration feature?**
A: During story planning, if areas have high complexity or unresolved uncertainties, you're offered a [D] deep dive option. This applies structured elicitation techniques (assumption surfacing, boundary probing, etc.) to explore alternatives without leaving the workflow.

**Q: Does this integrate with CI/CD?**
A: Yes. The framework includes a GitHub Actions workflow (`.github/workflows/claude-pr-review.yml`) that uses Claude Code to review PRs in CI. It runs code quality, test validation, and security checks, then posts a structured review comment. External contributors get structure-only review (no code-level access).

**Q: What happens if my session ends mid-story?**
A: The framework maintains a failure state file (`docs/sessions/.failure-state.md`) during skill execution. When you resume with `/continue`, it detects the interrupted state and shows exactly where you left off — which phase, what was completed, and how to resume.

**Q: How do I track framework effectiveness over time?**
A: Run `bash scripts/pm/metrics.sh` for skill execution metrics (success rates, per-skill breakdowns, rule trigger counts). `/retrospective` includes these metrics automatically. `/weekly-maintenance` reviews rule health. `/sprint-end` records ground rule compliance.

**Q: How do I check if the framework is set up correctly?**
A: Run `/doctor`. It validates configuration, hooks, dependencies, rules, documentation freshness, and skill conformance.

## Philosophy

- **TDD-first** — Tests communicate intent to the AI; tests are the specification
- **Sprint-based** — Small, focused increments with quality gates prevent context exhaustion
- **Git-disciplined** — Feature branches, conventional commits, squash merges, never push to main
- **Documentation-lean** — Only create docs when explicitly needed; auto-loaded files are minimal
- **AI-aware** — Guard rails against LLM pitfalls: hallucinated APIs, weakened tests, code slop, phantom packages, over-engineering
- **Verification-driven** — Evidence before claims; fresh command output before completion; four-question completion protocol
- **Context-efficient** — Lean entry points + on-demand references; priority-based compaction; per-phase context manifests
- **Clarification-first** — Discovery gates, structured ambiguity scanning, and forced clarification markers prevent LLM assumptions
- **Facilitator-driven** — Asks questions before generating; structured elicitation techniques for deep requirements discovery
- **Ground-rules-governed** — Per-project architectural principles checked at planning and shipping time
- **Risk-calibrated** — Workflow depth adapts to both size and risk; high-risk changes get extra scrutiny regardless of size
- **Observable** — Framework health checks (`/doctor`), skill execution metrics, rule effectiveness tracking, ground rule compliance ledger
- **Data-driven** — Adaptive depth calibration from historical data, rule health analysis, skill regression detection, cross-session error learning, solutions database for compounding knowledge
- **Confidence-first** — Pre-implementation confidence assessment prevents wrong-direction work before it starts
- **MCP-aware** — Optional MCP server integration for enhanced documentation, research, memory, and browser automation
- **Secrets-aware** — Automated credential detection in post-edit hooks, CODEOWNERS protection on sensitive files
- **CI-enforced** — GitHub Actions workflow for automated PR review catches issues even when local workflow is bypassed

## Contributing

Issues and PRs welcome at [github.com/joris887/JD-LLM-Development_framework](https://github.com/joris887/JD-LLM-Development_framework).

## License

MIT
