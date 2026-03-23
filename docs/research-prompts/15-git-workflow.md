# 15. Git Workflow Documentation

## Research Prompt

```
I need comprehensive deep research on git workflow documentation and conventions for AI-assisted development. The goal is a git workflow reference that ensures clean history, safe collaboration, and effective AI-human coordination — covering branching, committing, reviewing, and merging.

Research these specific areas:

1. **Branching Strategies**
   - GitHub Flow — simplicity and when it breaks down
   - GitFlow — when the complexity is justified (versioned releases)
   - Trunk-based development — Google's approach and prerequisites
   - Ship/Show/Ask model — categorizing PRs by review needs
   - Feature flags vs feature branches — when each is appropriate
   - Branch naming conventions — research on what's most effective

2. **Commit Conventions**
   - Conventional Commits specification — adoption, tooling, benefits
   - Semantic versioning from commits — automated changelog generation
   - Atomic commits — research on optimal commit granularity
   - AI-generated commit messages — quality and review patterns
   - Co-authorship attribution for AI-assisted commits
   - Commit signing — when and why to enforce

3. **Pull Request Practices**
   - Optimal PR size — research on review effectiveness by PR size
   - PR templates that actually get filled out — what makes them work?
   - Draft PRs — when to use, signals they send
   - Stacked PRs (dependent PRs) — tools and approaches
   - PR descriptions that help reviewers — research on effective formats

4. **Merge Strategies**
   - Squash merge vs merge commit vs rebase — trade-offs with evidence
   - Why squash merge is preferred for AI-assisted work (clean history)
   - Merge queue / merge train — when scale justifies it
   - Post-merge branch cleanup — automation approaches

5. **AI-Specific Git Patterns**
   - Git checkpointing during AI implementation (experiment branches)
   - Safe rollback patterns when AI implementation fails
   - Worktree management for parallel AI sessions
   - Protecting main branch from AI-generated commits
   - How to handle large diffs from AI (review strategies)

6. **Safety & Hooks**
   - Pre-commit hooks — what to check, tool comparison (husky, pre-commit, lefthook)
   - Pre-push hooks — when to use
   - Branch protection rules — recommended configuration
   - Force push prevention — technical enforcement approaches
   - Sensitive file protection patterns (CODEOWNERS + branch rules)

For each finding, include sources, team size applicability, and tooling recommendations.

Output a structured research report with: recommended git workflow for AI-assisted teams, commit convention details, PR best practices, and safety configuration.
```

## Implementation Prompt

```
I have completed deep research on git workflow best practices. The research findings are saved in docs/research/git-workflow.md (or I will paste them below).

Your task: Update the framework's git workflow documentation to be the most effective git workflow for AI-assisted development.

**Context:** Git-related files:
- docs/reference/GIT_WORKFLOW.md (and scaffold/) — practical examples and conventions
- .claude/rules/git.md — enforcement rule (always active)
- .claude/hooks/pre-tool-use.sh + rules/safety.patterns — command blocking
- CLAUDE.md Git Workflow section — summary loaded every session

They must:
- Enforce clean git hygiene (conventional commits, squash merge, branch protection)
- Prevent destructive operations (force push, reset --hard, checkout .)
- Support sprint-based workflow (sprint branches, story commits)
- Work for solo developers AND teams
- Be enforceable by AI (git.md rule) and by hooks (pre-tool-use.sh)

**Instructions:**
1. Read all current git-related files
2. Read the research findings
3. Update GIT_WORKFLOW.md:
   - Branching strategy section (research-backed recommendations)
   - Commit convention section (with practical examples)
   - PR process section (template usage, review guidance)
   - Merge strategy section (why squash, when not to)
   - Safety section (what's enforced by hooks, what needs discipline)
4. Update git.md rule if research suggests improvements
5. Update safety.patterns if new dangerous commands should be blocked
6. Update scaffold version to match
7. Verify sprint-start and sprint-end branch handling aligns

Make this the git workflow document that produces a clean, traceable, safe git history — whether the developer is human, AI, or both.
```
