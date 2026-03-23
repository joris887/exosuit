# 15. Git Workflow Documentation

## Research Prompt

```
I need deep research on git workflow documentation and conventions for AI-assisted development. The goal is to determine the best possible approach for a git workflow reference that ensures clean history, safe collaboration, and effective AI-human coordination — covering branching, committing, reviewing, and merging.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Git workflow is enforced at multiple layers:
- .claude/rules/git.md — enforcement rule (always active, blocks violations)
- .claude/hooks/pre-tool-use.sh + rules/safety.patterns — command blocking (prevents force push, reset --hard, etc.)
- CLAUDE.md Git Workflow section — summary loaded every session
- docs/reference/GIT_WORKFLOW.md — detailed reference with examples
- Sprint-based flow: sprint branches → story commits → squash merge to main → PR review
The framework must work for solo developers AND teams.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Branching Strategies** — GitHub Flow, GitFlow, trunk-based development. Ship/Show/Ask model. Feature flags vs feature branches. Branch naming conventions.

2. **Commit Conventions** — Conventional Commits specification. Semantic versioning from commits. Atomic commits — optimal granularity. AI-generated commit messages. Co-authorship attribution. Commit signing.

3. **Pull Request Practices** — Optimal PR size for review effectiveness. PR templates that get filled out. Draft PRs. Stacked PRs. PR descriptions that help reviewers.

4. **Merge Strategies** — Squash merge vs merge commit vs rebase. Why squash is preferred for AI work. Merge queues. Post-merge cleanup.

5. **AI-Specific Git Patterns** — Git checkpointing during AI implementation. Safe rollback when AI fails. Worktree management for parallel sessions. Protecting main from AI commits. Reviewing large AI diffs.

6. **Safety & Hooks** — Pre-commit hooks (husky, pre-commit, lefthook). Pre-push hooks. Branch protection rules. Force push prevention. Sensitive file protection.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended git workflow** — propose the specific branching strategy, commit convention, merge strategy, and PR process, with justification
4. **Recommended AI-specific patterns** — checkpointing, rollback, parallel sessions
5. **Recommended safety configuration** — hooks, branch protection, blocked commands
6. Tool recommendations
7. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on git workflow best practices. The research findings are saved in docs/research/git-workflow.md (or I will paste them below).

Your task: Update the framework's git workflow documentation to be the most effective git workflow for AI-assisted development, guided by the research findings.

**Hard constraints (non-negotiable):**
- Files to update:
  - docs/reference/GIT_WORKFLOW.md (and scaffold/) — practical examples and conventions
  - .claude/rules/git.md — enforcement rule (always active)
  - .claude/hooks/pre-tool-use.sh + rules/safety.patterns — command blocking
  - CLAUDE.md Git Workflow section — summary
- Must enforce clean git hygiene (conventional commits, squash merge, branch protection)
- Must prevent destructive operations (force push, reset --hard, checkout .)
- Must support sprint-based workflow (sprint branches, story commits)
- Must work for solo developers AND teams
- Must be enforceable by AI (git.md rule) and by hooks (pre-tool-use.sh)

**Instructions:**
1. Read all current git-related files listed above
2. Read the research findings thoroughly
3. Implement the git workflow, AI-specific patterns, and safety configuration the research recommends — trust the research over your own defaults
4. Update scaffold version to match
5. Verify sprint-start and sprint-end branch handling aligns with the new workflow
6. Verify safety.patterns blocks all dangerous commands the research identifies

**Outcome criteria (how to evaluate the result):**
- Git history is clean, traceable, and safe — whether the developer is human, AI, or both
- Destructive operations are blocked by deterministic hooks, not advisory rules
- The workflow works naturally for sprint-based AI development
- A developer reading GIT_WORKFLOW.md knows exactly what to do in every git scenario
- Rollback from failed AI implementations is safe and straightforward
```
