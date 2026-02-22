# Skill Template & Guidelines

Reference for creating and maintaining Claude Code skills.

## Core Principle: Context Window is a Shared Resource

The context window is shared between: system prompt, conversation history, all loaded skills and rules, and the actual user request. Every token a skill consumes is a token unavailable for the user's actual work.

**Default assumption:** Claude is already very smart. Only add context that Claude doesn't already know. Challenge every paragraph: "Does Claude need this to do the right thing?"

- Keep SKILL.md under 150 lines (target: ~100 lines for frequently-invoked skills)
- Move detailed content to `references/` subdirectory (loaded on demand)
- Prefer concise examples over verbose explanations
- Never duplicate information available in CODING_STANDARDS.md or TESTING_STRATEGY.md

## Standard Header Format

Every skill file (SKILL.md) starts with a metadata header line:

```
---
## name: <skill-name> description: <one-line description> [optional attributes]
```

### Required Attributes

- `name:` — Skill identifier (used as `/skill-name`)
- `description:` — One-line purpose (shown in skill listings)

### Optional Attributes

| Attribute                        | Values                               | When to Use                                |
| -------------------------------- | ------------------------------------ | ------------------------------------------ |
| `argument-hint:`                 | `<description>`                      | Skill accepts arguments                    |
| `disable-model-invocation: true` | boolean                              | Workflow skills with side effects          |
| `user-invocable: true`           | boolean                              | Can be manually invoked with `/name`       |
| `allowed-tools:`                 | comma-separated                      | Restrict tool access                       |
| `context: fork`                  | `fork`                               | Analysis agents (keeps main context clean) |
| `agent:`                         | `Explore`, `general-purpose`, `Plan` | Delegate to subagent                       |

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

## Referencing Standards

Skills should reference rather than duplicate standards:

```markdown
Follow coding standards in `docs/reference/CODING_STANDARDS.md`.
Follow architecture constraints in `docs/architecture/ARCHITECTURE.md`.
```

## Skill Size Guidelines

- **Target:** < 150 lines for the main SKILL.md
- **If larger:** Split into SKILL.md (main flow) + supporting files in skill directory
- **Supporting files:** `references/`, `examples/`, `templates/`

## Story Skill Metadata

When stories define which skills to load, use this format in the story:

```markdown
**Skills:** `/code-quality`, `/test-validator`, `/security-audit`
```

The story-cycle skill reads this to determine which quality agents to run.

## Recovery Guidance

Workflow skills should include a `## Recovery` section for predictable failure handling. Common patterns:

```markdown
## Recovery

### Test Failure
1. Read the error output carefully
2. Determine if the failure is in new code or pre-existing
3. If new code: fix and re-run
4. If pre-existing: inform user, do not mask the failure

### Git Conflict
1. Show the conflict to the user
2. Do NOT auto-resolve without approval
3. Suggest resolution strategy

### Quality Gate Failure
1. Present findings to user
2. Offer: fix now vs. defer to technical debt
3. If critical (security): must fix before proceeding
```

## Description Trap Warning

Descriptions MUST contain only triggering conditions ("Use when..."). NEVER summarize the workflow in the description — Claude will follow the summary as a shortcut instead of reading the full skill content.

```yaml
# BAD: Workflow summary in description
description: Complete a sprint by discovering work from git, running quality gates, updating docs, creating PR, and merging to main.

# GOOD: Trigger conditions only
description: Use when the user wants to ship a sprint's work to main via PR.
```

## Hard Gate Pattern

Use `<HARD-GATE>` blocks at critical decision points to prevent Claude from skipping mandatory steps:

```markdown
<HARD-GATE>
Do NOT proceed to implementation until the user has approved the plan.
</HARD-GATE>
```

Place gates inline at the decision point, not just as rules at the end. Gates are stronger enforcement than prose instructions.

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

## Naming Conventions

- Skill names: lowercase, hyphenated (`story-cycle`, `skill-create`)
- Directories: match skill name (`.claude/skills/story-cycle/SKILL.md`)
- Arguments: angle brackets for required (`<story-id>`), square for optional (`[type]`)
