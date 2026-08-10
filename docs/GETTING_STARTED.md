# Getting Started

This guide walks you through your first session with the Exosuit framework.

## Step 1: Install

Into an existing project. macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/joris887/exosuit/main/install.sh | bash
```

Windows (needs [Git for Windows](https://git-scm.com/download/win), which Claude Code requires anyway):

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/joris887/exosuit/main/install.ps1 | iex"
```

Starting from scratch? Run the same command in an empty folder; `/bootstrap` detects a new project and takes it from there.

## Step 2: Open Claude Code and Run `/quickstart`

The quickstart skill gives you a 5-minute tour of how the framework works. It checks your setup, explains the three layers (enforcement, workflow, documentation), and walks you through the core cycle.

If you prefer to skip the tour: run `/bootstrap` directly.

## Step 3: Bootstrap Your Project

`/bootstrap` configures the framework for your specific project:

### Existing repo with code

Bootstrap detects your languages, test framework, linter, formatter, and CI/CD. It generates project documentation (CLAUDE.md, coding standards, architecture, ground rules), configures hooks and rules for your stack, assesses readiness against 15 engineering principles, and creates foundation stories for any gaps it finds.

### New project from an idea

Bootstrap detects an empty project and launches `/discover`, a deep guided elicitation that builds your project from scratch:

- **Classifies your project** into one of 11 archetypes (utility, marketplace, developer tool, creative expression, etc.) and selects questions tailored to your project type
- **Walks through 7 phases**: classification, core identity, deep elicitation, assumption stress-testing, dimension completeness, vision synthesis, and MVP scoping
- **Runs research checkpoints** at each phase to validate decisions against current best practices
- **Generates a complete backlog** with scale-adapted epics, sized stories, and a Phase Transition Story that creates an ongoing build-review-discover cycle

Four modes adapt depth to project scale:

| Mode | Time | Best for |
|---|---|---|
| Quick Start | ~5 min | Small tools, scripts, hackathons |
| Guided (default) | 20-45 min | Standard applications |
| Platform | 60-120 min | Multi-service, regulated systems |
| Pioneering | Variable | Novel concepts (spike-first) |

The time estimates are real, and for a new project they are the point. Do not rush this. The interview asks questions about your idea that you have never asked yourself, and the answers become the vision, backlog, and architecture that every later sprint builds on. An hour of honest thinking here saves weeks of building the wrong thing.

### Just want to build something fast

```
/build "a habit tracker with streaks and weekly progress emails"
```

`/build` handles everything (setup, planning, implementation) with plain-English output. No framework knowledge needed.

## Step 4: Choose Your Profile

Bootstrap recommends a **profile** based on your project. You can accept or override it.

### Lean Profile
**Best for:** Prototypes, MVPs, internal tools, learning projects, hackathons.

What changes:
- Story delivery is streamlined: Plan > Build > Verify (no quality agents)
- Sprint start creates a branch directly (no sprint specs, no metrics checks)
- Sprint end runs tests and creates PR (no quality agent dispatch)
- Bootstrap generates minimal docs (CLAUDE.md and progress.md)
- All safety hooks still run; lean is less ceremonious, never less safe

### Standard Profile (default)
**Best for:** Production apps, APIs, libraries, team projects.

What changes:
- Full story-cycle with readiness gate, quality agents (code + tests + security), and documentation updates
- Sprint planning with capacity estimation and debt health checks
- Sprint end dispatches 3 quality agents before PR
- Bootstrap generates full documentation suite

### Strict Profile
**Best for:** Fintech, healthcare, regulated industries, payment systems, infrastructure.

What changes:
- All phases mandatory, even for trivial changes
- All 5 quality agents + integration tester dispatched on every story
- Coverage cannot decrease (delta must be >= 0)
- Audit trail logged to `.audit-log.jsonl`
- Ground rules and ADR compliance checks mandatory at sprint end

You can change your profile anytime by editing the `**Profile:**` line in CLAUDE.md, or by setting `EXOSUIT_PROJECT_PROFILE=lean|standard|strict` in your environment.

## Step 5: Your First Sprint

```
/sprint-start          # Creates a feature branch
/story-cycle "..."     # Deliver your first story (describe what to build)
/sprint-end            # Quality gates, PR creation, merge
```

That's it. The framework guides you through each step.

## Step 6: Between Sessions

When you're done for the day:
```
/handoff               # Saves session state for next time
```

When you come back:
```
/continue              # Resumes from where you left off
```

## Step 7: After Your First Phase

Once you've built and shipped your first batch of features:

```
/phase-review          # Walkthrough what you built, validate assumptions,
                       # research refresh, plan the next phase
```

This creates the ongoing cycle: **build > review > discover > build**.

## Environment Variables

Customize behavior without editing files:

| Variable | Values | Purpose |
|---|---|---|
| `EXOSUIT_PROJECT_PROFILE` | `lean`, `standard`, `strict` | Override project profile for this session |
| `EXOSUIT_HOOK_PROFILE` | `minimal`, `standard`, `strict` | Override hook strictness independently |
| `EXOSUIT_EXPLAIN_MODE` | `off`, `brief`, `verbose` | Control hook message detail level |
| `EXOSUIT_DISABLED_HOOKS` | comma-separated IDs | Disable specific hooks (e.g., `slop-check,debug-audit`) |
| `EXOSUIT_STOP_MAX_ITERATIONS` | number (default: 5) | Max stop-hook blocks before allowing exit |

## Next Steps

- `/help-me`: describe what you want to do in plain English
- `/dashboard`: see your sprint status at a glance
- `/doctor`: verify the framework is set up correctly
- See the [README](../README.md) for the full skill reference
- See the [Technical Reference](FRAMEWORK_REFERENCE.md) for the complete framework documentation
