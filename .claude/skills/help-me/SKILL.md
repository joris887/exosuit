---
name: help-me
version: 1.0.0
description: Natural language skill discovery — describe what you want to do and get matched to the right skill.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep
argument-hint: "\"I want to...\""
---
______________________________________________________________________

## help-me

Finding the right skill for: **$ARGUMENTS**

## Intent Matching

Map the user's natural language request to the most appropriate skill(s):

### Development Workflow

| User Says | Skill | Why |
|---|---|---|
| "start working", "begin", "new sprint" | `/sprint-start` | Creates a clean feature branch |
| "build", "implement", "add feature", "create", "deliver" | `/story-cycle <description>` | Full story delivery with TDD |
| "ship", "finish sprint", "create PR", "merge" | `/sprint-end` | Quality gates → PR → merge |
| "resume", "pick up where I left off", "continue" | `/continue` | Smart session resumption |
| "done for today", "end session", "save progress" | `/handoff` | Structured session handoff |

### Planning & Design

| User Says | Skill | Why |
|---|---|---|
| "plan", "break down", "decompose", "stories" | `/ideate <idea>` | Decompose into backlog stories |
| "explore design", "compare approaches", "architect" | `/brainstorm <idea>` | Design exploration with alternatives |
| "research", "investigate", "compare technologies" | `/research <topic>` | Deep online research with citations |

### Testing & Quality

| User Says | Skill | Why |
|---|---|---|
| "test plan", "prepare for testing" | `/manual-test` | Generate test plan from changes |
| "found a bug", "test feedback", "this doesn't work" | `/testing-cycle <feedback>` | Classify and process test findings |
| "run UAT", "acceptance test" | `/UAT-cycle <test-case-id>` | Execute formal UAT test case |
| "verify UAT logic", "sense check" | `/claude-sense-check` | Batch UAT code verification |
| "check code quality" | `/code-quality` | Complexity, duplication, patterns |
| "security review", "audit security" | `/security-audit` | CWE checklist, secrets, injection |
| "check architecture" | `/architecture-check` | Module boundaries, drift |

### Debugging & Recovery

| User Says | Skill | Why |
|---|---|---|
| "debug", "error", "broken", "fix bug" | `/debug-session <error>` | 5-phase structured debugging |
| "fix issue", "fix #42", "github issue" | `/fix-issue <number>` | GitHub issue → TDD fix → PR |
| "undo", "revert", "go back", "start over" | `/undo-work` | Safe rollback (3 levels) |

### Maintenance & Review

| User Says | Skill | Why |
|---|---|---|
| "health check", "is framework ok" | `/doctor` | Framework health validation |
| "weekly check", "maintenance" | `/weekly-maintenance` | Comprehensive weekly review |
| "retrospective", "what worked" | `/retrospective` | Sprint review with 4Ls |
| "backlog health", "review stories" | `/backlog-review` | Backlog quality analysis |
| "PR status", "check PRs" | `/pr-status` | Open PR status + actions |
| "upgrade framework" | `/framework-upgrade` | Update to newer version |

### Utility

| User Says | Skill | Why |
|---|---|---|
| "commit" | `/commit` | Conventional commit |
| "parallel", "worktree", "multiple stories" | `/parallel-work` | Manage concurrent worktrees |
| "improve iteratively", "refine" | `/refine-loop "<task>"` | Iterative self-improvement |
| "optimize metric", "increase coverage" | `/optimize "<goal>"` | Metric-driven optimization |
| "create skill" | `/skill-create` | Generate tech-specific skills |
| "test a skill" | `/skill-eval` | Skill testing and comparison |
| "remove framework" | `/uninstall` | Clean framework removal |
| "status", "dashboard" | `/dashboard` | Sprint status overview |

### Prompt Snippets (lightweight, no workflow)

| User Says | Skill | Why |
|---|---|---|
| "review security of file" | `/review-security <file>` | Quick security review |
| "explain this pattern" | `/explain-pattern <pattern>` | Code pattern explanation |
| "suggest tests for file" | `/suggest-tests <file>` | Test case suggestions |

## Presentation

Based on the user's input, present the top 1-3 matching skills:

```markdown
### Recommended

**`/skill-name <arguments>`** — [one-line description of what it does and when to use it]

### Also Consider

- `/other-skill` — [why this might also apply]
```

If the user's intent is ambiguous, present options using AskUserQuestion with descriptions explaining the workflow implications of each choice.

If no skill matches, suggest:
- Direct conversation for simple questions
- `/brainstorm` for complex open-ended exploration
- `/research` for information gathering

## Rules

- This skill is READ-ONLY — it recommends, it doesn't execute
- Always explain WHY a skill is recommended, not just WHAT it does
- If the user describes a multi-step workflow, suggest the sequence (e.g., "/brainstorm → /ideate → /sprint-start → /story-cycle")
- Prefer specific skills over generic advice
