---
name: quickstart
version: 1.0.0
description: Guided interactive tour of the framework. Walks through your first sprint from zero to shipped PR.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---
______________________________________________________________________

## quickstart

Welcome to the Exosuit framework. This guided tour walks you through your first complete sprint, from planning to shipped PR.

## Phase 1: Orientation (2 minutes)

Present the framework's core concept:

```markdown
### How This Framework Works

The framework adds structure to AI-assisted development:

**Three Layers:**
1. **Enforcement:** hooks that auto-format code, scan for secrets, block dangerous commands (automatic)
2. **Workflow:** skills (slash commands) that guide your development process (you invoke these)
3. **Documentation:** knowledge base that compounds across sessions (generated and updated)

**The Core Loop:**
```
/sprint-start → /story-cycle (repeat) → /sprint-end
```

Each `/story-cycle` takes a story through: plan → approve → implement (TDD) → verify → commit.
```

## Phase 2: Check Readiness (1 minute)

Run a quick health check:

```bash
# Check if bootstrap has been run
if [ -f "docs/architecture/ARCHITECTURE.md" ] && ! grep -q "<!-- " docs/architecture/ARCHITECTURE.md 2>/dev/null; then
    echo "READY: Bootstrap complete"
else
    echo "NOT READY: Run /bootstrap first"
fi
```

<IF condition="bootstrap not complete">
Tell the user:
> Your project hasn't been bootstrapped yet. Run `/bootstrap` first; it detects your stack, configures hooks, and generates project documentation. Come back to `/quickstart` after bootstrap completes.
Stop here.
</IF>

## Phase 3: Interactive Walkthrough

Present options using AskUserQuestion:

- **"Walk me through a sprint"** (description: "Interactive guided sprint with explanations at each step (15 min)")
- **"Show me all available skills"** (description: "Quick reference of every slash command grouped by purpose")
- **"Explain the enforcement layer"** (description: "See what happens automatically (hooks, rules, quality gates)")
- **"I want to start building"** (description: "Skip the tour, jump to /sprint-start")

### Option A: Guided Sprint Walkthrough

Walk through each step with explanation:

#### Step 1: Sprint Start
```markdown
**What happens:** Creates a clean feature branch from main.

Try it: `/sprint-start`

This will:
- Check for open PRs (merge or note them)
- Verify you're on the default branch and up to date
- Run tests to confirm a green baseline
- Create a `sprint-N` branch

**Behind the scenes:** The SessionStart hook checked your environment when you opened Claude Code.
```

Wait for user to run `/sprint-start`, then continue.

#### Step 2: Story Delivery
```markdown
**What happens:** Delivers a single story with TDD and quality gates.

Try it: `/story-cycle "add a health check endpoint"` (or any small feature)

This will:
1. **Phase 0:** Decompose your request, classify size and risk
2. **Phase 1:** Research the codebase, write a plan, ask for your approval
3. **Phase 2:** Score confidence (must be ≥85 to proceed)
4. **Phase 3:** Implement using TDD (tests first, then code)
5. **Phase 4:** Self-review, quality gates, commit

**Behind the scenes:** Every edit triggers auto-formatting and secrets scanning.
The testing.md rule auto-loads when test files are edited.
```

Wait for user to complete a story-cycle, then continue.

#### Step 3: Sprint End
```markdown
**What happens:** Ships your work via a PR with quality gates.

Try it: `/sprint-end`

This will:
- Run lint, typecheck, and test suite
- Verify test count didn't decrease
- Run quality agents (code-quality, test-validator, security-audit)
- Check ground rules compliance
- Create a PR with structured description
- Wait for CI, then squash-merge to main

**Behind the scenes:** Quality agents run as parallel sub-processes with confidence scoring.
Only findings ≥80 confidence are reported.
```

#### Step 4: Session End
```markdown
**What happens:** Captures your session state for continuity.

Try it: `/handoff`

This creates a structured session file in docs/sessions/ that /continue reads next time.
Alternatively, just stop; the Stop hook auto-saves your git state.
```

### Option B: Skill Reference

Present the full skill table from CLAUDE.md organized by workflow stage.

### Option C: Enforcement Explained

Walk through what happens on each event:
- **Edit a file** → post-edit-format.sh (format + lint + secrets scan)
- **Run a bash command** → pre-tool-use.sh (block dangerous commands)
- **Try to stop** → stop.sh (check for completion evidence)
- **Submit a prompt** → user-prompt.sh (warn about destructive requests)

## Phase 4: Next Steps

```markdown
### You're Ready

**Essential skills to know:**
- `/story-cycle`: your daily driver for delivering stories
- `/continue`: resume work from a previous session
- `/debug-session`: when something breaks
- `/doctor`: when the framework seems off

**When you need help:**
- `/help-me "I want to..."`: find the right skill for any task

**Weekly rhythm:**
- Monday-Thursday: `/sprint-start` → `/story-cycle` (repeat) → `/sprint-end`
- Friday: `/weekly-maintenance` → `/retrospective`
```

## Rules

- This skill is READ-ONLY: it explains, it doesn't modify
- Let the user drive: present information, wait for them to act
- Keep explanations concise: show, don't tell
- If the user seems experienced, offer to skip ahead
