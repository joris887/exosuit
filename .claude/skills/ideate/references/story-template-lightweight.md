# Lightweight Story Template (TRIVIAL only)

Use this template for stories classified as TRIVIAL. For STANDARD or LARGE stories, use the full template in `story-template.md`.

```markdown
---
id: [PROJECT]-[NUMBER]
title: [Clear one-line summary of the change]
type: feature|bugfix|refactor|spike|infra|testing|docs|security|performance|skill
priority: P0|P1|P2|P3
size: TRIVIAL
status: draft|ready|in-progress|review|done|blocked
created: YYYY-MM-DD
---

# [Title]

## Outcome

### Why
[One sentence: what and why]

### Acceptance Criteria
- [ ] [Observable outcome 1]
- [ ] [Observable outcome 2]

### Out of Scope
- [What is NOT part of this story]

## Verification
```bash
[command that proves completion]
```

## Implementation Hints (STALE BY DEFAULT — refined at sprint-start)
- Affected file(s): [single file or 2 at most]
```

## When to use

**TRIVIAL** — single-file change with no behavioral complexity. Examples: config tweak, text update, rename, comment fix, dependency version bump. 1-3 AC suffices and AC may be as simple as "the file matches the new spec."

For anything that touches multiple files, introduces or modifies user-visible behavior, or needs a plan — use STANDARD (full template).

There is no SMALL tier in v5.0. The old SMALL category collapsed into STANDARD because v5.0's STANDARD upper bound (≤500-1000 LOC, full verification budget) already absorbs what SMALL covered, without the extra ceremony of three tiers.
