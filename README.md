# JD-LLM Development Framework

A project-agnostic, drop-in development framework for [Claude Code](https://claude.com/claude-code). Provides structured sprint workflows, TDD practices, quality gates, and backlog management — all powered by Claude Code skills.

## What This Is

A complete development methodology encoded as Claude Code skills. Drop it into any repository and run `/bootstrap` to auto-configure for your stack.

**18 skills** covering the full development lifecycle:

- **Sprint workflow**: `/sprint-start` → `/story-cycle` → `/sprint-end`
- **Planning**: `/ideate` for decomposing ideas into typed stories
- **Quality**: `/code-quality`, `/test-validator`, `/security-audit`
- **Maintenance**: `/weekly-maintenance`, `/retrospective`, `/backlog-review`
- **Utilities**: `/commit`, `/fix-issue`, `/pr-status`, `/debug-session`

## Two Modes

### 1. Existing Repository

Drop the framework into your project and run `/bootstrap`. It will:

- Detect your languages, package manager, test framework, linter, and CI/CD
- Auto-configure `CLAUDE.md` with your project's commands and conventions
- Generate `docs/reference/CODING_STANDARDS.md` for your stack
- Run `/skill-create` to generate technology-specific skills

### 2. New Project (Braindump → Build)

Start from an idea:

1. Use `vision/BRAINDUMP_PROMPT.md` to do deep research on your idea
2. Save the output to `vision/`
3. Run `/bootstrap` to generate PRD, architecture, epics, and stories
4. Start building with `/sprint-start` → `/story-cycle`

## Installation

### For an Existing Project

```bash
# From your project root:
git clone https://github.com/joris887/JD-LLM-Development_framework.git /tmp/jd-framework

# Copy framework files (won't overwrite your existing files)
cp -rn /tmp/jd-framework/.claude .
cp -rn /tmp/jd-framework/docs .
cp -rn /tmp/jd-framework/vision .
cp -rn /tmp/jd-framework/scripts .
cp -n /tmp/jd-framework/CLAUDE.md .
cp -n /tmp/jd-framework/CLAUDE.local.md.template .

# Clean up
rm -rf /tmp/jd-framework

# Open Claude Code and run:
# /bootstrap
```

### For a New Project

```bash
# Clone directly as your project
git clone https://github.com/joris887/JD-LLM-Development_framework.git my-project
cd my-project
rm -rf .git
git init

# Open Claude Code and either:
# /bootstrap     (guided setup)
# or fill in vision/BRAINDUMP_PROMPT.md first
```

## Quick Start

After installation and `/bootstrap`:

```
/sprint-start           # Create a sprint branch
/story-cycle "Add X"    # Deliver a story with TDD
/story-cycle "Fix Y"    # Deliver another story
/sprint-end             # Quality gates → PR → merge
```

### Session Management

```
/continue               # Resume where you left off
/handoff                # End session, generate next-session prompt
```

### Planning

```
/ideate "New feature"   # Decompose idea into typed stories
/backlog-review         # Check backlog health
```

### Testing

```
/manual-test            # Generate test plan from recent changes
/testing-cycle "Bug X"  # Process a testing feedback item
/UAT-cycle UAT-001      # Execute a formal UAT test case
/UAT-cycle              # Browse available UAT test cases
```

## Skills Reference

| Skill | Purpose | Invocation |
|---|---|---|
| `/bootstrap` | First-run setup, auto-detect stack | Manual |
| `/sprint-start` | Pre-flight checks + branch | Manual |
| `/story-cycle` | Universal story delivery | Manual |
| `/sprint-end` | Quality gates + PR + merge | Manual |
| `/ideate` | Ideas → typed stories | Manual |
| `/continue` | Smart session resumption | Manual |
| `/handoff` | Session end + next prompt | Manual |
| `/skill-create` | Generate tech skills | Manual |
| `/code-quality` | Complexity, duplication, patterns | Auto/Manual |
| `/test-validator` | Coverage, TDD compliance | Auto/Manual |
| `/security-audit` | Vulnerability review | Auto/Manual |
| `/manual-test` | Generate test plan from changes | Manual |
| `/testing-cycle` | Process user test feedback | Manual |
| `/UAT-cycle` | Execute formal UAT test case | Manual |
| `/weekly-maintenance` | Weekly health check | Manual |
| `/retrospective` | 4Ls framework | Manual |
| `/backlog-review` | Backlog health | Manual |
| `/commit` | Conventional commit | Manual |
| `/fix-issue` | GitHub issue fixer | Manual |
| `/pr-status` | PR status checker | Manual |
| `/debug-session` | Structured debugging | Manual |

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

## Philosophy

- **TDD-first**: Tests are how you communicate intent to the AI
- **Sprint-based**: Small, focused increments with quality gates
- **Git-disciplined**: Feature branches, conventional commits, squash merges
- **Documentation-lean**: Only create docs when explicitly needed
- **AI-aware**: Guard rails against common LLM pitfalls (hallucinated APIs, weakened tests, over-engineering)

## File Structure

```
.claude/
  skills/               # 18 framework skills
  rules/                # Path-scoped rules (generated by /bootstrap)
vision/                 # New project braindump flow
docs/
  reference/
    BACKLOG_INDEX.md    # Epic status matrix
    CODING_STANDARDS.md # Code conventions
    TESTING_STRATEGY.md # TDD workflow + quality criteria
    PRD_SUMMARY.md      # Requirements overview
    backlog/            # Epic files with stories
  architecture/
    ARCHITECTURE.md     # System architecture
  adr/                  # Architecture Decision Records
  sprints/              # Sprint spec files
  testing/              # Test coverage docs
  progress.md           # Sprint history + metrics
  technical-debt.md     # TD inventory
scripts/                # Project-specific scripts
CLAUDE.md               # Framework entry point (< 200 lines)
```

## Contributing

Issues and PRs welcome at [github.com/joris887/JD-LLM-Development_framework](https://github.com/joris887/JD-LLM-Development_framework).

## License

MIT
