# Prompt Snippets

Lightweight, reusable prompt templates — simpler than full skills.

## What Are Prompt Snippets?

Prompt snippets are simple markdown files with argument placeholders. They fill the gap between typing ad-hoc prompts and creating full workflow skills.

**Use a snippet when:** You have a prompt you repeat often but it doesn't need workflow scaffolding (plan mode, context management, completion reports).

**Use a skill when:** The task has multiple phases, side effects, or needs specific tool restrictions.

## Argument Syntax

- `$1`, `$2`, `$3` — Positional arguments
- `$@` — All arguments

## Creating a Snippet

1. Create a `.md` file in `.claude/prompts/`
2. Write your prompt template with `$1`/`$2` placeholders
3. The file name becomes the command: `review-security.md` → `/review-security`

## Example

**File:** `.claude/prompts/review-security.md`
```markdown
Review `$1` for security vulnerabilities. Focus on:
- Input validation and sanitization
- SQL injection and command injection
- Hardcoded secrets or credentials
- CWE top 10 for AI-generated code

Report findings with severity (critical/high/medium/low) and suggested fixes.
```

**Usage:** `/review-security src/auth/login.ts`

## Included Snippets

| Snippet | Arguments | Purpose |
|---------|-----------|---------|
| `/review-security` | `<file-path>` | Security review of a specific file |
| `/explain-pattern` | `<pattern> [file]` | Explain a code pattern found in the codebase |
| `/suggest-tests` | `<file-path>` | Suggest test cases for a file |

## Subagent Templates (`agents/`)

Structured prompt templates for dispatching subagents with context and review checklists. These are not invoked directly — they're used by skills (like `/sprint-end`) when dispatching quality agents.

| Template | Purpose |
|----------|---------|
| `agents/code-reviewer.md` | Code review with severity classification (Critical/Important/Minor) |
| `agents/spec-reviewer.md` | Spec compliance verification with file:line references |
