# 11. Technical Debt Inventory

## Research Prompt

```
I need comprehensive deep research on technical debt documentation, classification, and management in software projects. The goal is a technical debt tracking format that makes debt visible, prioritizable, and actionable — specifically considering how AI-assisted development both creates and resolves technical debt.

Research these specific areas:

1. **Technical Debt Classification**
   - Martin Fowler's technical debt quadrant (deliberate/inadvertent × reckless/prudent)
   - Ward Cunningham's original debt metaphor — how has it evolved?
   - Types: code debt, architecture debt, test debt, documentation debt, dependency debt, infrastructure debt
   - SonarQube's technical debt model — what works, what's misleading
   - Research on which types of debt have the highest carrying cost

2. **Debt Measurement & Visualization**
   - CodeScene's hotspot analysis — code health visualization approaches
   - SonarQube's debt ratio (remediation time / development time)
   - Debt heat maps — visualizing where debt accumulates
   - Code churn as a debt indicator — research on correlation
   - File complexity × change frequency = maintenance pain quadrant
   - How to measure debt in terms developers understand (hours to fix, risk level, blast radius)

3. **Debt Prioritization**
   - Interest rate model — which debt compounds fastest?
   - Risk-based prioritization — debt in critical paths vs dead code
   - User impact scoring — debt that affects user experience
   - Developer velocity impact — debt that slows down future work
   - How to decide: fix now vs. defer vs. accept permanently?

4. **AI-Generated Technical Debt**
   - Research on types of debt AI commonly introduces (over-abstraction, phantom dependencies, pattern violations)
   - AI-amplified debt — when AI builds on existing debt, making it worse
   - The "AI cleanup spiral" — AI refactoring that introduces new debt
   - How to track debt introduced by AI vs pre-existing debt
   - Prevention strategies — what catches AI debt before it accumulates?

5. **Debt Management Processes**
   - "20% time" for debt reduction — does it work? (Google's approach)
   - Debt sprints vs continuous debt reduction — research on effectiveness
   - Debt budgets — allocating capacity for debt reduction per sprint
   - How companies like Spotify, Netflix, and Etsy manage technical debt
   - When to pay debt vs when to rewrite

6. **Debt Documentation Formats**
   - Lightweight debt tracking in markdown (not a full tool like SonarQube)
   - What information per debt item actually helps prioritization?
   - Linking debt to code locations (file:line references)
   - Debt lifecycle: identification → assessment → scheduling → resolution → verification
   - How to prevent the debt inventory from becoming stale

For each finding, include research sources, practical examples, and assessment of overhead (tracking debt shouldn't cost more than fixing it).

Output a structured research report with: recommended classification, tracking format, prioritization framework, and AI-debt-specific management patterns.
```

## Implementation Prompt

```
I have completed deep research on technical debt management. The research findings are saved in docs/research/technical-debt.md (or I will paste them below).

Your task: Update the framework's technical-debt.md template to be the most actionable debt tracking format.

**Context:** The template lives at docs/technical-debt.md (and scaffold/docs/technical-debt.md). It's populated by /bootstrap (technical debt assessment) and maintained by /weekly-maintenance. It must:
- Classify debt clearly (type, severity, interest rate)
- Be prioritizable — reader can immediately see what to fix first
- Track AI-introduced debt vs pre-existing debt
- Feed into sprint planning (debt items become stories)
- Stay lean — not a full project management tool

**Instructions:**
1. Read the current docs/technical-debt.md template
2. Read the research findings
3. Redesign the template:
   - Summary metrics (total items, by severity, estimated remediation hours)
   - Debt items with: category, file:line, severity, interest rate, blast radius, discovered date
   - Prioritization guidance (which to fix first and why)
   - AI-introduced debt section (patterns the framework should prevent)
   - Debt reduction tracking (resolved items log)
4. Add category definitions that bootstrap's technical debt assessment (A3.2) can populate
5. Update scaffold version to match
6. Verify /bootstrap A3.2 can populate the new format
7. Verify /weekly-maintenance can update and report on the new format

Make this the debt document that transforms "we should fix this someday" into specific, prioritized, scheduled work.
```
