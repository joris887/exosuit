# Skill Template & Guidelines

Reference for creating and maintaining Claude Code skills.

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

## Naming Conventions

- Skill names: lowercase, hyphenated (`story-cycle`, `skill-create`)
- Directories: match skill name (`.claude/skills/story-cycle/SKILL.md`)
- Arguments: angle brackets for required (`<story-id>`), square for optional (`[type]`)
