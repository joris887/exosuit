---
name: build
version: 1.0.0
description: Build a project from a plain-English description. Handles all technical decisions automatically. Designed for non-technical users but useful for anyone who wants fast results.
trigger: manual
depends-on: [bootstrap, ideate, story-cycle]
references: []
micro-components:
  setup: [discover-commands]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, Agent
argument-hint: "<description of what to build>"
---
______________________________________________________________________

## build

Build a project from a natural-language description. Orchestrates setup, planning, and implementation automatically.

**All user-facing output MUST use plain English. No jargon: no "TDD", "sprint", "PR", "squash merge", "CI/CD", "ORM", "middleware". If a technical term is unavoidable, explain it in parentheses.**

## Arguments

`$ARGUMENTS` — a plain-English description of what to build (e.g., "a task management app with user accounts and due dates").

<IF condition="$ARGUMENTS is empty">
Ask: "What would you like me to build? Describe it in your own words — as much or as little detail as you like."
Wait for response before proceeding.
</IF>

## Phase 0: Check Setup

<IF condition="CLAUDE.md has placeholder commands (contains '<test command>' or '<lint command>')">
Run a silent minimal bootstrap:
1. Detect stack (languages, package manager, test framework, formatter, linter)
2. Configure CLAUDE.md commands
3. Set profile to **lean** (unless already set)
4. Skip: architecture docs, coding standards, ground rules, readiness report, foundation backlog
5. Show: "Setting up the project..." (nothing more)
</IF>
<ELSE>
Show: "Project already set up. Starting build..."
</ELSE>

Read the current profile from CLAUDE.md. If not lean, note the profile but proceed — `/build` always uses lean-style execution internally regardless of project profile.

## Phase 1: Decompose

Show: "Planning what needs to be built..."

Internally decompose the description into ordered stories using `/ideate` logic:
1. Identify the core entities and features described
2. Break into dependency-ordered implementation steps
3. Classify each as feature, infrastructure, or testing
4. Size each step (aim for steps that touch ≤5 files)

**Do NOT surface any of this to the user.** No story types, no SPIDR, no priority labels, no methodology terminology. Keep the decomposition internal.

Create a simple internal plan (not shown to user):
```yaml
steps:
  - summary: "Set up the database tables"
    type: infrastructure
    files: [...]
  - summary: "Build the API endpoints"
    type: feature
    files: [...]
  - summary: "Add user authentication"
    type: feature
    files: [...]
  - summary: "Write tests"
    type: testing
    files: [...]
```

### Discovery Capture (Retroactive)

Silently capture discovery context for future phase reviews — the user does NOT see this:
1. Infer archetype from description (classify against the 10 archetypes in `.claude/skills/discover/references/scale-guide.md`)
2. Set scale to Quick Build
3. Auto-generate a minimal `docs/reference/DECISION_LOG.md` (copy template from `.claude/skills/discover/assets/decision-log.md`), logging all technical decisions with confidence: ASSUMED
4. Include Phase Transition Stories (E0N-REVIEW: 3-story quick variant — E0N-001, E0N-004, E0N-006) as the last internal step
5. Save classification to `vision/classification.md`

This ensures /build users get the review cycle without upfront friction.

## Phase 2: Execute

For each step in dependency order:

1. **Show progress in plain English:**
   - "Setting up the database..." / "Building the API..." / "Adding user login..." / "Writing tests to make sure everything works..."
   - Use language the user would understand. Never: "Executing story E01-003 (type: feature, size: STANDARD)"

2. **Execute using story-cycle Lean behavior:**
   - Plan (lightweight — no confidence scoring)
   - Build with TDD where non-trivial (run tests, don't explain TDD methodology)
   - Verify tests pass
   - Commit with conventional format (don't explain commit conventions)

3. **Make all technical decisions silently:**
   - Framework/library choices: pick the best fit, document in a final summary
   - Architecture: follow standard patterns for the detected stack
   - File structure: follow existing project conventions or detected stack defaults
   - Only stop for genuine **product** ambiguity: "The design could go two ways: [A] or [B]. Which do you prefer?"
   - Never stop for: database choice, API style, file naming, test framework, folder structure

4. **Handle failures gracefully:**
   - If a step fails after 2 attempts, skip it with a note: "I couldn't get [X] working automatically. Here's what needs to be done manually: [description]"
   - Continue with remaining steps — don't block the entire build

## Phase 3: Complete

Show a completion report in plain English:

```markdown
## All Done!

### What Was Built
- [Feature 1]: [plain-English description of what it does]
- [Feature 2]: [description]
- ...

### Files Created/Modified
- `src/models/user.ts` — User data model
- `src/api/auth.ts` — Login and registration endpoints
- ...

### Tests
- [N] tests written, all passing

### Technical Decisions Made
- **Database:** PostgreSQL (reliable, free, works well with [framework])
- **Auth:** [chosen approach] — [one-line reason]
- ...

### How to Run It
```bash
[the command to start the app, e.g., npm run dev]
```

### Next Steps
- [Suggestion 1, e.g., "Add a payment system with /build 'Stripe payment integration'"]
- [Suggestion 2]
```

## Rules

- **Plain English only** — every user-facing message must be understandable by someone who has never coded
- **Silent technical decisions** — pick good defaults, document them in the completion report, never ask
- **Stop only for product questions** — "Should users be able to delete their account?" is valid. "REST or GraphQL?" is not.
- **Safety hooks still run** — secrets detection, git protection, and test execution happen invisibly
- **Lean execution** — no quality agent dispatch, no sprint specs, no retrospectives, no documentation generation beyond what's needed to work
- **Skip gracefully** — failed steps are noted, not fatal. The build continues.
- **One session** — the first version of /build completes in a single session. Multi-session builds are future work.
