# JD-LLM Development Framework

A drop-in development framework for [Claude Code](https://claude.com/claude-code). Provides structured sprint workflows, TDD practices, quality gates, and backlog management — all encoded as Claude Code skills. Drop it into any repo, run `/bootstrap`, and start building.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) installed and working
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Git configured with your identity

## Installation

### Path A: Drop into an Existing Project

```bash
# Option 1: Use the install script (recommended)
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

Bootstrap will detect your languages, package manager, test framework, linter, and CI/CD. It auto-configures `CLAUDE.md`, generates coding standards, and creates technology-specific skills for your stack.

### Path B: Start a New Project from Scratch

```bash
git clone https://github.com/joris887/JD-LLM-Development_framework.git my-project
cd my-project
rm -rf .git && git init
```

Then open Claude Code and either:

1. **Quick start:** Run `/bootstrap` and describe your idea when prompted
2. **Deep research first:** Open `vision/BRAINDUMP_PROMPT.md`, copy the prompt into a Claude Project (or any AI research tool), braindump your idea, save the structured output back to `vision/`, then run `/bootstrap`

Bootstrap reads the vision files and generates: PRD, architecture, epic structure, typed stories, and project configuration.

## First Run: /bootstrap

| Your situation | What `/bootstrap` does |
|---|---|
| Existing repo with code | Detects stack, configures CLAUDE.md, generates coding standards and tech skills |
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
| Starting new sprint | `/sprint-start` |

### During Development

| I want to... | Command |
|---|---|
| Deliver a story | `/story-cycle "add user authentication"` |
| Explore a design | `/brainstorm "payment processing"` |
| Plan new work | `/ideate "payment processing"` |
| Debug an issue | `/debug-session "TypeError in checkout"` |
| Quick commit | `/commit` |

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
| Browse UAT test cases | `/UAT-cycle` |

### Completing Work

| I want to... | Command |
|---|---|
| Finish a sprint | `/sprint-end` |
| Weekly health check | `/weekly-maintenance` |
| Sprint retrospective | `/retrospective` |

## Skill Reference

| Skill | Purpose |
|---|---|
| `/bootstrap` | First-run setup — detect stack or generate from vision |
| `/sprint-start` | Pre-flight checks + create sprint branch |
| `/story-cycle` | Deliver a story using the right methodology for its type |
| `/sprint-end` | Quality gates, documentation, PR, merge, cleanup |
| `/brainstorm` | Design exploration with alternative approaches |
| `/ideate` | Transform ideas into typed backlog stories |
| `/continue` | Smart session resumption from git state |
| `/handoff` | End session with structured handoff document |
| `/skill-create` | Generate technology-specific skills for your stack |
| `/skill-eval` | Test, measure, or A/B compare skill effectiveness |
| `/refine-loop` | Iterative self-improvement until completion criteria met |
| `/code-quality` | Complexity, duplication, pattern analysis (confidence-scored) |
| `/test-validator` | Coverage, TDD compliance, test quality (confidence-scored) |
| `/security-audit` | Vulnerability review for sensitive code (confidence-scored) |
| `/manual-test` | Generate test plan from recent changes |
| `/testing-cycle` | Process user testing feedback |
| `/UAT-cycle` | Execute formal UAT test cases |
| `/weekly-maintenance` | Comprehensive weekly health check |
| `/retrospective` | 4Ls framework retrospective |
| `/backlog-review` | Backlog health analysis |
| `/commit` | Guided conventional commit |
| `/fix-issue` | Fix a GitHub issue |
| `/pr-status` | Check PR status |
| `/debug-session` | 5-phase structured debugging with root cause tracing |
| `/parallel-work` | Manage parallel worktrees for concurrent stories |
| `/architecture-check` | Validate architecture and module boundaries |
| `/review-security` | Security review of a specific file (prompt snippet) |
| `/explain-pattern` | Explain a code pattern in this codebase (prompt snippet) |
| `/suggest-tests` | Suggest test cases for a file (prompt snippet) |

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

## File Structure

```
.claude/
  skills/               # Framework skills (27+, each with YAML frontmatter)
    <skill>/
      SKILL.md          # Lean entry point (<150 lines)
      references/       # Detailed docs loaded on demand
      scripts/          # Executable helper scripts (--help supported)
      assets/           # Output templates — copy, don't read
  prompts/              # Prompt snippets + subagent templates
    agents/             # Subagent dispatch templates (code-reviewer, spec-reviewer)
  rules/                # Path-scoped rules for testing, security, git, verification, code-slop, edit-recovery
  hooks/                # Hook scripts for auto-format, quality gates, safety
  settings.json         # Claude Code configuration with hooks
docs/
  reference/
    BACKLOG_INDEX.md    # Epic status matrix
    CODING_STANDARDS.md # Code conventions (filled by /bootstrap)
    TESTING_STRATEGY.md # TDD workflow + quality criteria
    backlog/            # Epic files with stories
  architecture/
    ARCHITECTURE.md     # System architecture
  adr/                  # Architecture Decision Records
  sprints/              # Sprint spec files
  sessions/             # Session handoff files
  plans/                # Saved plan files
  testing/              # Test coverage docs
  progress.md           # Sprint history + metrics
vision/                 # New project braindump flow
CLAUDE.md               # Framework entry point (auto-loaded, <100 lines)
AGENTS.md               # Cross-tool compatibility (symlink to CLAUDE.md)
llms.txt                # LLM-friendly project index
install.sh              # Drop-in installer script
```

## FAQ

**Q: Can I use this with other AI coding tools (Cursor, Aider, Windsurf)?**
A: The skills are Claude Code-specific, but `AGENTS.md` provides cross-tool compatibility for the project context. Other tools will pick up the project overview, commands, and conventions.

**Q: Does this work with monorepos?**
A: Yes. Run `/bootstrap` at the monorepo root. It detects multiple languages and generates skills for each.

**Q: What if `/bootstrap` gets something wrong?**
A: Edit `CLAUDE.md` directly. It's the source of truth. Re-run `/bootstrap` anytime to re-detect.

**Q: How do I customize the workflow?**
A: Edit the skill files in `.claude/skills/`. They're plain markdown — modify any step, add rules, change the flow.

**Q: What about git worktrees for parallel work?**
A: Use `/sprint-start --worktree` or `/parallel-work` to manage concurrent stories in isolated worktrees.

## Philosophy

- **TDD-first** — Tests communicate intent to the AI
- **Sprint-based** — Small, focused increments with quality gates
- **Git-disciplined** — Feature branches, conventional commits, squash merges
- **Documentation-lean** — Only create docs when explicitly needed
- **AI-aware** — Guard rails against LLM pitfalls (hallucinated APIs, weakened tests, code slop, over-engineering)
- **Verification-driven** — Evidence before claims, fresh output before completion
- **Progressive disclosure** — Load only what you need, when you need it
- **Context-efficient** — Skills split into lean entry points + on-demand references; context window is a shared resource

## Contributing

Issues and PRs welcome at [github.com/joris887/JD-LLM-Development_framework](https://github.com/joris887/JD-LLM-Development_framework).

## License

MIT
