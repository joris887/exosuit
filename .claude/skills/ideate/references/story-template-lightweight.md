# Lightweight Story Template (TRIVIAL / SMALL)

Use this template for stories classified as TRIVIAL or SMALL. For STANDARD stories, use the full template in `story-template.md`.

```markdown
---
id: [PROJECT]-[NUMBER]
title: [Clear one-line summary]
type: feature|bugfix|refactor|spike|infra|testing|docs|security|performance|skill
priority: P0|P1|P2|P3
size: TRIVIAL|SMALL
status: draft|ready|in-progress|review|done|blocked
created: YYYY-MM-DD
---

# [Title]

## Why
[One sentence: what and why]

## Acceptance criteria
- [ ] [Testable outcome 1]
- [ ] [Testable outcome 2]

## Verification
```bash
[command that proves completion]
```

## Affected files
[Key files to modify]

## Out of scope
- [What is NOT part of this story]
```

## When to use

- **TRIVIAL**: Config changes, text updates, single-line fixes. 1-2 AC is sufficient.
- **SMALL**: Single-file features, straightforward changes following existing patterns. 2-4 AC.

If you need more than 4 acceptance criteria or more than 2 affected files, escalate to the full STANDARD template.
