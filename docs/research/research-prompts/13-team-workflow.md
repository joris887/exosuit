# 13. Team Workflow & Collaboration

## Research Prompt

```
I need deep research on team development workflows — specifically how teams collaborate effectively when using AI-assisted development tools. The goal is to determine the best possible approach for team workflow documentation that works for small teams (2-5) to medium teams (5-15) using AI coding assistants alongside human developers.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Team workflow:
- Is referenced by /bootstrap (team detection) and /sprint-end (human review step)
- Must integrate with the framework's sprint-based workflow
- Must address coordination between multiple AI-assisted developers working on the same codebase
- The framework already enforces: feature branches, squash merge, conventional commits, PR workflow
- AI sessions create knowledge silos (each session has its own context) — handoff is critical
The template must be practical, not theoretical agile advice.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Team Development Models** — InnerSource, trunk-based development, GitHub Flow vs GitFlow. Pair programming with AI. Code ownership models (strong, weak, collective). What changes when AI is in the mix?

2. **Code Review in AI-Assisted Teams** — How to review AI-generated code (different from human-authored). Optimal review batch size for AI PRs. Review checklists for AI code. Auto-review vs human review responsibilities. CODEOWNERS patterns.

3. **Team Coordination Patterns** — Preventing merge conflicts from parallel AI sessions. Story assignment and locking. Communication patterns (async-first?). Shared decision-making. Sprint coordination across different AI tools.

4. **Knowledge Sharing** — How AI sessions create knowledge silos. Handoff patterns between developers. Shared learnings. Onboarding new team members into AI-assisted workflow. Ground rules as alignment mechanism.

5. **Quality & Consistency** — Code consistency across multiple AI developers. Shared standards enforcement. Architecture governance in teams. Test quality consistency. Security standards.

6. **Scaling AI-Assisted Development** — Team productivity research (Copilot studies, Cursor studies). When AI breaks down at scale. Tooling standardization. Cost management. Measuring team effectiveness.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended team workflow structure** — propose the specific coordination patterns, review process, and knowledge sharing mechanisms, with justification
4. **Recommended code review process** — AI + human review, who catches what
5. **Recommended scaling guidance** — what changes as team grows from 2 to 15
6. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on team workflows for AI-assisted development. The research findings are saved in docs/research/team-workflow.md (or I will paste them below).

Your task: Update the framework's TEAM_WORKFLOW.md to be the definitive guide for team collaboration with AI assistance, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations: docs/reference/TEAM_WORKFLOW.md AND scaffold/docs/reference/TEAM_WORKFLOW.md
- Must work for teams of 2-15 developers
- Must address coordination between multiple AI-assisted developers
- Must cover code review, backlog coordination, knowledge sharing
- Must integrate with the framework's existing sprint-based workflow
- Referenced by /bootstrap (team detection) and /sprint-end (human review)

**Instructions:**
1. Read the current docs/reference/TEAM_WORKFLOW.md
2. Read the research findings thoroughly
3. Implement the team workflow structure, review process, and scaling guidance the research recommends — trust the research over your own defaults
4. Update scaffold version to match
5. Verify /sprint-end human review integration aligns with the new workflow
6. Verify .github/CODEOWNERS recommendations align

**Outcome criteria (how to evaluate the result):**
- Any team can adopt AI-assisted development without coordination overhead destroying productivity gains
- Code review catches AI-specific issues (phantom packages, weakened tests, over-engineering)
- Knowledge doesn't stay siloed in individual AI sessions
- New team members can onboard into the workflow within a day
- Works for a 2-person team and a 15-person team with appropriate scaling
```
