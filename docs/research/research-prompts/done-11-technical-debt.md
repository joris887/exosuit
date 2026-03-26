# 11. Technical Debt Inventory

## Research Prompt

```
I need deep research on technical debt documentation, classification, and management in software projects. The goal is to determine the best possible approach for a technical debt tracking format that makes debt visible, prioritizable, and actionable — specifically considering how AI-assisted development both creates and resolves technical debt.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Technical debt:
- Is assessed during /bootstrap (technical debt assessment step A3.2)
- Is maintained by /weekly-maintenance
- Feeds into sprint planning (debt items become stories)
- Must be lightweight — not a full project management tool, just a markdown file
- AI commonly introduces specific types of debt (over-abstraction, phantom dependencies, pattern violations) that need special tracking
The template must work for any project.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Technical Debt Classification** — Martin Fowler's quadrant (deliberate/inadvertent × reckless/prudent). Ward Cunningham's original metaphor. Types: code, architecture, test, documentation, dependency, infrastructure debt. SonarQube's model. Which types have the highest carrying cost?

2. **Debt Measurement & Visualization** — CodeScene's hotspot analysis. SonarQube's debt ratio. Heat maps. Code churn as indicator. Complexity × change frequency. Measuring debt in terms developers understand.

3. **Debt Prioritization** — Interest rate model (which compounds fastest?). Risk-based (critical paths vs dead code). User impact. Developer velocity impact. Fix now vs defer vs accept permanently.

4. **AI-Generated Technical Debt** — Types of debt AI commonly introduces. AI-amplified debt. "AI cleanup spiral." Tracking AI vs pre-existing debt. Prevention strategies.

5. **Debt Management Processes** — "20% time," debt sprints, continuous reduction, debt budgets. How Spotify/Netflix/Etsy manage debt. When to pay vs rewrite.

6. **Debt Documentation Formats** — Lightweight markdown tracking. What information per item helps prioritization. Linking to code locations. Debt lifecycle. Preventing the inventory from becoming stale.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended classification scheme** — propose the specific categories, severity levels, and prioritization framework, with justification
4. **Recommended tracking format** — what fields per debt item, in markdown
5. **Recommended AI-debt management approach** — prevention and tracking
6. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on technical debt management. The research findings are saved in docs/research/technical-debt.md (or I will paste them below).

Your task: Update the framework's technical-debt.md template to be the most actionable debt tracking format, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations: docs/technical-debt.md AND scaffold/docs/technical-debt.md
- Must classify debt clearly for prioritization
- Must be lightweight — markdown file, not a project management tool
- Must track AI-introduced debt vs pre-existing debt
- Must feed into sprint planning (debt items become stories)
- Populated by /bootstrap (step A3.2) and maintained by /weekly-maintenance

**Instructions:**
1. Read the current docs/technical-debt.md template
2. Read the research findings thoroughly
3. Implement the classification scheme, tracking format, and AI-debt approach the research recommends — trust the research over your own defaults
4. Update scaffold/docs/technical-debt.md to match
5. Verify /bootstrap A3.2 can populate the new format
6. Verify /weekly-maintenance can update and report on the new format

**Outcome criteria (how to evaluate the result):**
- A developer reading this immediately knows what to fix first and why
- Debt items are actionable — each could become a story in the next sprint
- AI-introduced debt is identified and tracked separately
- The document doesn't become stale — lifecycle management is built in
- Overhead of maintaining the inventory is less than the value it provides
```
