# 13. Team Workflow & Collaboration

## Research Prompt

```
I need comprehensive deep research on team development workflows — specifically how teams collaborate effectively when using AI-assisted development tools. The goal is a team workflow documentation that works for small teams (2-5) to medium teams (5-15) using AI coding assistants alongside human developers.

Research these specific areas:

1. **Team Development Models**
   - InnerSource practices — how open-source collaboration works inside companies
   - Trunk-based development — research on benefits vs feature branches for AI-assisted work
   - GitHub Flow vs GitFlow vs trunk-based — which is best for AI + human teams?
   - Pair programming with AI — how does it change team dynamics?
   - Code ownership models: strong ownership, weak ownership, collective ownership

2. **Code Review in AI-Assisted Teams**
   - How should humans review AI-generated code? (different from human-authored code review)
   - Research on optimal review batch size — PRs from AI sessions tend to be larger
   - Review checklists specific to AI-generated code (phantom packages, weakened tests, over-engineering)
   - Auto-review vs human review — what should each catch?
   - CODEOWNERS patterns that work — research on which files need human eyes

3. **Team Coordination Patterns**
   - How to prevent merge conflicts when multiple AI sessions work on the same codebase
   - Story assignment and locking — preventing duplicate work
   - Communication patterns for AI-assisted teams (async-first?)
   - Shared decision-making — ADRs, RFCs, design docs in AI-assisted context
   - Sprint coordination when different team members use different AI tools

4. **Knowledge Sharing**
   - How AI sessions create knowledge silos (each session has its own context)
   - Effective handoff patterns between developers
   - Shared learnings database — how to compound knowledge across team members
   - Onboarding new team members into an AI-assisted workflow
   - Ground rules as team alignment mechanism

5. **Quality & Consistency**
   - How to maintain code consistency across multiple AI-assisted developers
   - Shared coding standards enforcement with AI
   - Architecture governance in AI-assisted teams
   - Test quality consistency — preventing "race to the bottom"
   - Security standards across team members

6. **Scaling AI-Assisted Development**
   - Research on team productivity with AI tools (GitHub Copilot studies, Cursor studies)
   - When does AI assistance break down at team scale?
   - Tooling standardization — should all team members use the same AI tool?
   - Cost management — AI API costs at team scale
   - Measuring team effectiveness (DORA + SPACE for AI-assisted teams)

For each finding, include sources, team size applicability, and practical implementation guidance.

Output a structured research report with: recommended team workflow structure, coordination patterns, review process, and knowledge sharing mechanisms.
```

## Implementation Prompt

```
I have completed deep research on team workflows for AI-assisted development. The research findings are saved in docs/research/team-workflow.md (or I will paste them below).

Your task: Update the framework's TEAM_WORKFLOW.md to be the definitive guide for team collaboration with AI assistance.

**Context:** The template lives at docs/reference/TEAM_WORKFLOW.md (and scaffold/docs/reference/TEAM_WORKFLOW.md). It's referenced by /bootstrap (team detection) and /sprint-end (human review). It must:
- Work for teams of 2-15 developers
- Address coordination between multiple AI-assisted developers
- Cover code review, backlog coordination, knowledge sharing
- Integrate with the framework's existing sprint-based workflow
- Be practical — not theoretical agile advice

**Instructions:**
1. Read the current docs/reference/TEAM_WORKFLOW.md
2. Read the research findings
3. Update the document:
   - Branch strategy for teams (concurrent sprints, merge order)
   - Code review workflow (AI review + human review — who catches what)
   - Story assignment and conflict prevention
   - Knowledge sharing (handoffs between developers, shared learnings)
   - Onboarding guide (how to introduce new team members to the framework)
   - Quality consistency patterns (shared standards, shared ground rules)
   - Communication patterns (when to sync, async workflows)
4. Update scaffold version to match
5. Verify /sprint-end human review integration aligns with the workflow
6. Verify .github/CODEOWNERS aligns with the review recommendations

Make this the guide that enables any team to use AI-assisted development without the coordination overhead destroying the productivity gains.
```
