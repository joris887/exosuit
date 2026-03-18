# Skill Template & Guidelines

Reference for creating and maintaining Claude Code skills.

## Core Principle: Context Window is a Shared Resource

The context window is shared between: system prompt, conversation history, all loaded skills and rules, and the actual user request. Every token a skill consumes is a token unavailable for the user's actual work.

**Default assumption:** Claude is already very smart. Only add context that Claude doesn't already know. Challenge every paragraph: "Does Claude need this to do the right thing?"

- Keep SKILL.md under 150 lines (target: ~100 lines for frequently-invoked skills)
- Move detailed content to `references/` subdirectory (loaded on demand)
- Prefer concise examples over verbose explanations
- Never duplicate information available in CODING_STANDARDS.md or TESTING_STRATEGY.md

## YAML Frontmatter (Machine-Readable Metadata)

Every SKILL.md starts with a YAML frontmatter block for machine-readable metadata. This enables automated inventory generation, version tracking, and dependency validation via `/skill-eval`.

```yaml
---
# === REQUIRED ===
name: skill-name
version: 2.4.0
description: Brief one-line description of the skill
trigger: manual|auto|conditional
depends-on: [other-skill-1, other-skill-2]
references: [references/file1.md, references/file2.md]

# === EXECUTION CONTROL (all optional) ===
user-invocable: true                # show in / menu (default: true)
disable-model-invocation: false     # prevent Claude auto-loading
argument-hint: "<description>"      # shown in autocomplete
allowed-tools:                      # tools allowed without permission
  - Read
  - Glob
  - Grep
disallowedTools: [Edit, Write]      # tools explicitly blocked (deterministic)

# === EXECUTION CONTEXT (all optional) ===
context: fork                       # run in forked sub-agent
agent: Explore                      # subagent type: Explore, Plan, general-purpose, custom
model: opus                         # model override: opus, sonnet, haiku, full model ID
effort: high                        # effort level: low, medium, high
background: true                    # always run as background task
isolation: worktree                 # git worktree isolation
once: true                          # fire only once per session
memory: project                     # persistent memory: user, project, local

# === SCOPED HOOKS (optional) ===
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: "Check if tests were run"

# === SUBAGENT AUTO-LOADING (optional) ===
skills: [code-quality, research]    # skills preloaded for subagents

# === COMPOSITION (optional) ===
micro-components:
  phase-0: [context-prime]
  phase-4: [quality-gate-sequence]
---
```

| Field | Required | Values | Purpose |
|-------|----------|--------|---------|
| `name` | Yes | lowercase, hyphenated | Skill identifier |
| `version` | Yes | semver | Framework version when last updated |
| `description` | Yes | one line | Purpose (shown in inventory) |
| `trigger` | Yes | `manual`, `auto`, `conditional` | How the skill is invoked |
| `depends-on` | Yes | list of skill names | Skills this may invoke |
| `references` | Yes | list of file paths | Supporting reference files |
| `user-invocable` | No | boolean | Show in `/` menu (default: true) |
| `disable-model-invocation` | No | boolean | Prevent auto-loading |
| `argument-hint` | No | string | Autocomplete hint |
| `allowed-tools` | No | list or comma-separated | Tools allowed without permission |
| `disallowedTools` | No | list | Tools blocked deterministically |
| `context` | No | `fork` | Run in forked sub-agent context |
| `agent` | No | `Explore`, `Plan`, `general-purpose`, custom | Subagent type (with `context: fork`) |
| `model` | No | `opus`, `sonnet`, `haiku`, full ID | Model override |
| `effort` | No | `low`, `medium`, `high` | Model effort level |
| `background` | No | boolean | Always run as background task |
| `isolation` | No | `worktree` | Git worktree isolation |
| `once` | No | boolean | Fire only once per session |
| `memory` | No | `user`, `project`, `local` | Persistent memory scope |
| `hooks` | No | hook config object | Scoped hooks for this skill's lifecycle |
| `skills` | No | list of skill names | Auto-loaded for subagents |
| `micro-components` | No | map of phase → list | Micro-components to load per phase |

### Micro-Components in Frontmatter

Skills can declare which micro-components (from `.claude/prompts/`) they need and when:

```yaml
micro-components:
  phase-0: [context-prime]
  phase-1: [discover-commands, verify-clean-git-state]
  phase-4: [quality-gate-sequence]
```

At the start of each declared phase, load and execute the listed micro-components. This replaces inline references to micro-components in the skill body, making updates to a micro-component automatically affect all skills that declare it.

The frontmatter goes BEFORE the `______________________________________________________________________` separator line.

## Skill Prerequisites (requires)

Skills can declare runtime prerequisites in YAML frontmatter. These are checked at skill startup — if missing, the skill reports what's needed and halts.

```yaml
---
name: sprint-end
requires:
  binaries: [gh, git]        # CLI tools that must be installed
  commands: [test]            # References CLAUDE.md Commands section (test, lint, format, build, typecheck)
  files: [docs/progress.md]  # Files that must exist
---
```

| Field | Purpose | Check Method |
|-------|---------|--------------|
| `binaries` | CLI tools required | `command -v <binary>` |
| `commands` | CLAUDE.md Commands that must be configured | Read CLAUDE.md Commands section |
| `files` | Project files that must exist | File existence check |

**Validation step:** At skill start, before Phase 0 or Step 1, check all `requires` entries. If any prerequisite is missing, report clearly and HALT:

```
PREREQUISITE MISSING: `gh` CLI not installed.
Required by: /sprint-end (push and PR creation)
Install: https://cli.github.com/
```

**Graceful alternative:** If a prerequisite has a documented fallback in the skill's Graceful Degradation table, skip the prerequisite check for that item and use the fallback instead.

Not all skills need `requires` — only add it when the skill has hard dependencies that cause confusing failures if missing.

## Standard Header Format

Below the frontmatter and separator line, the skill body starts with a simplified header:

```
## <skill-name>
```

All operational attributes are in the YAML frontmatter — not on the header line.

### Operational Attributes (in YAML frontmatter)

| Attribute                  | Values                               | When to Use                                |
| -------------------------- | ------------------------------------ | ------------------------------------------ |
| `disable-model-invocation` | `true`                               | Workflow skills with side effects          |
| `user-invocable`           | `true`                               | Can be manually invoked with `/name`       |
| `allowed-tools`            | comma-separated                      | Restrict tool access                       |
| `argument-hint`            | `"<description>"`                    | Skill accepts arguments                    |
| `context`                  | `fork`                               | Analysis agents (keeps main context clean) |
| `agent`                    | `Explore`, `general-purpose`, `Plan` | Delegate to subagent                       |

## Context Patterns

### Inline (default)

For workflow skills that guide the main conversation. Use when the skill orchestrates actions (git, edits, tests).

### Forked (`context: fork`)

For analysis agents that should not pollute the main context. Use when the skill only reads and reports (code-quality, test-validator, security-audit).

## Agent Types

| Agent             | Use Case                               | Tools Available                    |
| ----------------- | -------------------------------------- | ---------------------------------- |
| `Explore`         | Read-only analysis, codebase search    | Read, Glob, Grep, Bash (read-only) |
| `general-purpose` | Full capabilities including web search | All tools                          |
| `Plan`            | Planning without execution             | Read, Glob, Grep (no edits)        |
| *(none)*          | Workflow orchestration in main context | As specified in `allowed-tools`    |

## Subagent Context Protocol

When skills dispatch forked subagents (quality analysis, code review), define what context the subagent receives. This prevents subagents from inheriting irrelevant framework context.

### Full Mode (default for inline skills)
Receives: Full conversation context, CLAUDE.md commands, active plan
Use for: Workflow skills that orchestrate the main conversation (story-cycle, sprint-end)

### Minimal Mode (for forked analysis agents)
Receives: CLAUDE.md Commands section + relevant coding standards only
Excludes: Conversation history, backlog state, sprint context, other skill references
Use for: code-quality, test-validator, security-audit, architecture-check

### Tool Restrictions for Subagents

Use `disallowedTools` in frontmatter for deterministic enforcement — the model physically cannot use blocked tools. This replaces advisory prose instructions which can be skipped (T01-015).

```yaml
# In skill frontmatter or agent frontmatter:
disallowedTools: [Edit, Write, NotebookEdit]
```

| Agent Type | disallowedTools | Rationale |
|------------|-----------------|-----------|
| Code quality | Edit, Write, NotebookEdit | Read-only analysis |
| Security audit | Edit, Write, NotebookEdit | Read-only + scanners via Bash |
| Test validator | Edit, Write, NotebookEdit | Read-only + test runner via Bash |
| Code reviewer | Edit, Write, NotebookEdit | Read-only review |

### Specifying Context Mode

In the skill's YAML frontmatter or dispatch template, specify what the subagent needs:

```markdown
## Subagent Context
- **Mode:** minimal
- **Include:** CLAUDE.md Commands, docs/reference/CODING_STANDARDS.md
- **Exclude:** Conversation history, backlog files, sprint state
```

Native agents in `.claude/agents/` define their own context requirements via YAML frontmatter. When dispatching a forked agent, pass only the files listed in its context specification — not the full project context.

## Referencing Standards

Skills should reference rather than duplicate standards:

```markdown
Follow coding standards in `docs/reference/CODING_STANDARDS.md`.
Follow architecture constraints in `docs/architecture/ARCHITECTURE.md`.
```

## Skill Size & Resource Types

- **Target:** < 150 lines for SKILL.md
- **If larger:** Split into SKILL.md + supporting files

| Directory      | Purpose                             | Context Impact             |
|----------------|-------------------------------------|----------------------------|
| `scripts/`     | Executable code — run, don't read   | Zero (black-box execution) |
| `references/`  | Documentation — load on demand      | Medium (grep for sections) |
| `assets/`      | Output templates — copy, don't read | Zero (copy and edit)       |

### Reference File Budgets

- Individual reference files: ≤200 lines — if larger, split by topic
- Total references per skill: ≤500 lines across all files
- When loading references, prefer section-level grep (search for `## Heading`) over reading entire files

**assets/** contains templates and boilerplate used in output. Copy an asset to the
target location and Edit it — never Read the asset into context first.

## Script Execution Policy

Scripts in `scripts/` are black boxes — execute them directly, do NOT read their
source code before running. Only read script source when debugging a failure.

This saves significant context: a 50-line script produces 5-10 lines of output.

## Reference Navigation Pattern

When referencing supporting docs, use `${CLAUDE_SKILL_DIR}` for portable paths:
- BAD: "See `.claude/skills/my-skill/references/api.md`"
- GOOD: "In `${CLAUDE_SKILL_DIR}/references/api.md`, search for `## Authentication`"

Include section-level grep hints to load one section instead of the full file.

### String Substitutions Available in Skill Body
- `$ARGUMENTS` — all arguments passed to skill
- `$ARGUMENTS[0]`, `$ARGUMENTS[1]` — positional arguments (indexed)
- `$1`, `$2` — shorthand for positional arguments
- `${CLAUDE_SKILL_DIR}` — the skill's own directory path
- `${CLAUDE_SESSION_ID}` — current session ID
- `` !`command` `` — inline shell command execution (output injected into prompt)

## Story Skill Metadata

When stories define which skills to load, use this format in the story:

```markdown
**Skills:** `/code-quality`, `/test-validator`, `/security-audit`
```

The story-cycle skill reads this to determine which quality agents to run.

## Recovery Guidance

Workflow skills should include a `## Recovery` section for predictable failure handling. For complex skills (3+ phases), create a `references/error-recovery.md` with phase-specific error/cause/recovery tables:

```markdown
## Phase N: [Phase Name] Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| [Specific error] | [Root cause] | [Exact recovery action] |
```

The skill's Recovery section then references it: "Consult `references/error-recovery.md` — search for `## Phase N`."

For simpler skills, inline recovery is sufficient:

```markdown
## Recovery

### Test Failure
1. Read the error output carefully
2. Determine if the failure is in new code or pre-existing
3. If new code: fix and re-run
4. If pre-existing: inform user, do not mask the failure
```

## Reasoning Tools

For skills with complex decision points, reference the shared reasoning tools from `story-cycle/references/reasoning-tools.md`. Available tools: `scope_analysis`, `test_strategy_selection`, `failure_diagnosis`, `architectural_impact`, `plan_completeness`.

## Graceful Degradation

Workflow skills should document fallback behavior when dependencies are missing:

| Dependency      | If Missing                           |
|-----------------|--------------------------------------|
| Sub-agents      | Perform analysis manually in context |
| Formatter/linter| Skip auto-format, note in output     |
| Test runner     | Warn user, skip test verification    |
| CLI tool        | Run `[tool] --help` first; if not installed, skip and note |

## Pre-Execution Validation

Skills that produce structured files (stories, session files, docs) should validate
prerequisites before doing work:

- Target directory exists
- Required input files are readable
- No conflicting work-in-progress

Fail early with a clear message — don't consume context on doomed operations.

## Description Trap Warning

Descriptions MUST contain only triggering conditions ("Use when..."). NEVER summarize the workflow in the description — Claude will follow the summary as a shortcut instead of reading the full skill content.

## Example Block Triggers

For auto-invoked skills (quality agents, security audit), add `<example>` blocks in the skill body immediately after the `## <skill-name>` header. These trigger auto-invocation when the model sees matching user context.

```markdown
## code-quality

<example>Review code quality for the changes in this sprint</example>
<example>Check complexity and duplication in modified files</example>
<example>Analyze code patterns in the diff</example>

[rest of skill content]
```

Include 2–3 examples per auto-invoked skill. Each example should be a realistic user phrase.

```yaml
# BAD: Workflow summary in description
description: Complete a sprint by discovering work from git, running quality gates, updating docs, creating PR, and merging to main.

# GOOD: Trigger conditions only
description: Use when the user wants to ship a sprint's work to main via PR.
```

## Control Flow Markers

Use structured markers at critical decision points. These are stronger enforcement than prose instructions.

### Hard Gate (existing)

```markdown
<HARD-GATE>
Do NOT proceed to implementation until the user has approved the plan.
</HARD-GATE>
```

### Conditional Execution (new in v2.7)

Replace prose conditionals ("if X, do Y") with structured markers:

```markdown
<IF condition="test command exists in CLAUDE.md Commands">
Run the test suite. Verify zero failures.
</IF>
<ELSE>
Skip test verification. Note: "No test command configured."
</ELSE>
```

### Bounded Loops (new in v2.7)

For retry/verification loops, always specify a maximum:

```markdown
<LOOP max="3" until="all acceptance criteria have evidence">
1. Check each criterion against current state
2. For any lacking evidence: implement the fix
3. Re-verify
</LOOP>
```

### Explicit Halt (new in v2.7)

When retry budgets are exhausted, halt clearly:

```markdown
<HALT reason="exceeded retry budget">
Stop attempting. Report what was tried, what failed, and what remains.
Ask user for guidance before continuing.
</HALT>
```

Place all markers inline at the decision point, not just as rules at the end.

## Red Flag Tables

For skills where Claude commonly shortcuts processes, add a table of rationalizations and their refutations:

```markdown
### Red Flags — Stop If You're Thinking:

| Rationalization | Why It's Wrong | Correct Action |
|----------------|----------------|----------------|
| "The user wants this fast" | Fast now = rework later | Follow the process |
```

## Skill Testing Methodology

Before finalizing a new skill, validate that it actually changes Claude's behavior:

1. **Define pressure scenario**: A realistic user prompt that would cause Claude to take the wrong action WITHOUT the skill
   - Example: "Just fix this test quickly" → should trigger investigation, not guess-and-fix
2. **Verify failure (RED)**: Present the pressure scenario without the skill active. Observe Claude taking the wrong action.
3. **Enable skill (GREEN)**: Present the same scenario with the skill active. Verify Claude follows the skill's process.
4. **Refine**: If Claude still shortcuts, strengthen the skill (add hard gates, red flags, explicit prohibitions).

This is TDD applied to documentation: write the test (pressure scenario), observe failure, write the skill, observe compliance.

## Evaluation Criteria

Every skill should include an `## Evaluation Criteria` section defining how to verify the skill works correctly. This enables testing via `/skill-eval`.

```markdown
## Evaluation Criteria
<!-- How would you verify this skill works correctly? -->
- [ ] [Expected behavior under normal conditions]
- [ ] [Hard gate is respected — does not proceed without approval]
- [ ] [Pressure scenario: Claude does X instead of shortcutting to Y]

### Pressure Scenarios
<!-- Realistic prompts that would cause Claude to take the wrong action WITHOUT this skill -->
1. "[User prompt that tempts shortcutting]" → Should trigger [correct behavior]
```

If evaluation criteria are missing, `/skill-eval metrics` will flag the skill for improvement.

## Skill-Specific Persistent Memory (Sidecars)

Skills can optionally maintain a persistent sidecar file that accumulates learned patterns across sessions. Declare in frontmatter:

```yaml
---
persistent-context: true  # Skill reads/writes {memory_dir}/{skill-name}.md
---
```

**Convention:**
- Sidecar files live in the project's auto memory directory: `{memory_dir}/{skill-name}.md`
- Check for the sidecar at skill startup — load if exists
- Update at skill completion with learned patterns (detected stack, common findings, resolved preferences)
- Keep sidecars small: ≤30 lines, structured YAML or bullet points
- Skills without `persistent-context: true` should NOT create sidecar files

**Example use cases:**
- `/bootstrap` remembers detected stack and last run date
- `/code-quality` remembers commonly flagged-and-accepted patterns
- `/debug-session` remembers debugging strategies that worked for this codebase

## Naming Conventions

- Skill names: lowercase, hyphenated (`story-cycle`, `skill-create`)
- Directories: match skill name (`.claude/skills/story-cycle/SKILL.md`)
- Arguments: angle brackets for required (`<story-id>`), square for optional (`[type]`)
