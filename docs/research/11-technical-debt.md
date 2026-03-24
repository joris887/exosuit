# Technical debt tracking for AI-assisted development

**The most effective approach to tracking technical debt in AI-assisted projects combines a lightweight markdown register with a classification system tuned to AI-specific debt patterns, reviewed on a fixed weekly cadence.** Research across academic literature, industry practice, and emerging AI-code-quality studies converges on a clear finding: the format matters less than three properties — debt must be *visible* (in the repo, not a separate tool), *quantified* (impact stated in developer-hours or business terms), and *owned* (every item assigned to a person). The framework below synthesizes Ward Cunningham's original metaphor, Martin Fowler's quadrant, SonarQube's SQALE model, CodeScene's behavioral analysis, and the rapidly growing body of research on AI-generated code quality to propose a complete classification, tracking, and management approach.

---

## The debt metaphor is widely misunderstood, and that matters for tracking

Ward Cunningham coined "technical debt" at OOPSLA 1992 in his experience report on the WyCash Portfolio Management System. His original framing was narrow and precise: *"Shipping first time code is like going into debt. A little debt speeds development so long as it is paid back promptly with a rewrite... Every minute spent on not-quite-right code counts as interest on that debt."* Critically, Cunningham clarified in 2009 that the metaphor describes **evolving understanding** — shipping code that reflects current (partial) knowledge, then refactoring as understanding deepens. He explicitly rejected the common interpretation that debt means deliberately writing bad code: *"I'm never in favor of writing code poorly."*

Martin Fowler extended this in 2009 with his **Technical Debt Quadrant**, a 2×2 matrix crossing reckless/prudent against deliberate/inadvertent. The four quadrants produce distinct debt types: reckless-deliberate ("we don't have time for design"), reckless-inadvertent ("what's layering?"), prudent-deliberate ("we must ship now and deal with consequences"), and prudent-inadvertent ("now we know how we should have done it"). Fowler considered the prudent-inadvertent quadrant most interesting — and most aligned with Cunningham's original intent — because it represents the *inevitable* debt that even excellent teams accumulate as they learn. Steve McConnell added a further distinction between intentional and unintentional debt, arguing true debt requires a conscious decision.

These distinctions matter for tracking because **different quadrants demand different responses**. Prudent-deliberate debt needs a repayment plan at creation time. Reckless-inadvertent debt needs training, not just a backlog entry. A tracking format should capture the *nature* of the decision that created the debt, not just its symptoms.

The academic taxonomy is well-established. Alves et al. (2014/2016) produced the definitive ontology identifying **13 types**: architecture, build, code, defect, design, documentation, infrastructure, people, process, requirement, service, test, and test automation debt. Rios et al. (2018) later expanded this to 15 types. For a lightweight tracking file, this granularity is excessive — the recommended classification below consolidates these into 7 actionable categories.

## Architecture debt compounds exponentially while code debt gets all the attention

Research consistently identifies **architectural and design debt as the highest-carrying-cost category**. Besker, Martini, and Bosch (2019, Journal of Systems and Software) found through longitudinal study of 43 developers that **23% of development time is wasted on technical debt**, with architectural debt generating the most negative effect. Martini and Bosch (2017) demonstrated that architectural debt is *contagious* — its interest is "not only fixed but potentially compound, which leads to the hidden growth of interest (possibly exponential)." Ernst et al. (2015, SEI/CMU) surveyed 1,831 engineers and found **architectural decisions are the most important source of technical debt**.

Yet a 2025 systematic literature review found "a disproportionate focus on code-related technical debt" in both research and tooling, overshadowing other types. SonarQube and NDepend provide broad coverage of code, design, test, and architecture debt, but documentation debt remains "one of the most underrepresented categories, despite its recognized impact."

The interest-rate model provides the clearest prioritization lens. The key insight, articulated by Berkes (2022): **coupling determines the interest rate**. Decoupled architecture keeps interest linear; coupled architecture makes it exponential. A poor framework choice raises the interest rate of the *entire* codebase. This maps directly to prioritization — debt in tightly coupled, frequently changed code on the critical path demands immediate attention, while isolated debt in dead code has near-zero carrying cost.

CodeScene's hotspot analysis operationalizes this by intersecting **change frequency** (from Git history) with **code health** (static analysis). Files that change often and score poorly are "red refactoring targets." This approach outperforms pure static analysis because it factors in how the code is actually used. SonarQube's SQALE model takes a different approach, summing remediation costs across quality characteristics and producing a debt ratio (remediation cost ÷ development cost), with letter grades from A (≤5%) to E (>50%). Both approaches are valuable, but CodeScene's behavioral lens is more useful for prioritization while SonarQube's ratio is better for executive communication.

## Leading companies converge on 15–25% sprint allocation with no consensus on tactics

**Google** uses quarterly engineering satisfaction surveys asking engineers to rate how much technical debt hinders them. They tested 117 automated metrics against survey results and found **no single metric predicted developer reports of technical debt** — human perception remained the best measure. They built a maturity model with 4 levels, classroom instruction, and tooling. The result: a majority of Google engineers now report only slight or no hindrance from debt.

**Shopify** classifies debt into four temporal categories with a total allocation of roughly **25% of engineering time**: daily tidying (~5%), weekly card creation (~5%), monthly small projects (~10%), and yearly rewrites (~5%). This temporal taxonomy is particularly useful because different debt types require different approval processes and time horizons.

**Etsy** uses continuous deployment (25–50+ deploys per day) as a debt management strategy — small changesets reduce the severity of any individual problem. They run a "Debt Busters" program with regular refactoring sprints and a monthly bug-rotation day. **Netflix** takes a distinctive view, treating debt "not necessarily as a burden but as an opportunity," and operates on the principle that most code will be rewritten every 2–3 years anyway. They assemble **dedicated teams for legacy code** rather than distributing the work. **Spotify's** squad model makes each squad responsible for its own debt, though former PM Jeremiah Lee revealed the model "was only ever aspirational and never fully implemented."

The industry consensus for sprint allocation lands at **15–20%** (Gene Kim's DevOps Handbook, Scrum.org, multiple practitioners). The "boy scout rule" (leave code better than you found it) is universally recommended as a baseline but insufficient alone for larger items. Joel Spolsky's famous warning against rewrites ("the single worst strategic mistake") remains influential, though modern practitioners recognize rewrites are justified when technology is obsolete, architecture is fundamentally misaligned, or the product vision has changed. The **Strangler Fig pattern** — gradually replacing legacy components — offers the safest middle path.

Quantifying business impact is essential for organizational buy-in. Stripe's 2018 Developer Coefficient study found developers spend **42% of their work week** dealing with technical debt. CISQ (2020) estimated the total cost of poor software quality in the US at **$2.08 trillion**, with $1.31 trillion in technical debt principal alone. McKinsey (2022) estimates debt amounts to **20–40% of the value of an organization's entire technology estate**.

## AI-generated code creates a new category of debt that compounds faster than legacy debt

The research on AI-generated code quality is converging rapidly and the findings are sobering. CodeRabbit's December 2025 study of 470 real-world GitHub PRs found AI-generated code contained **~1.7x more issues** on average (10.83 vs 6.45 per PR), with **1.75x more logic errors**, **2.74x more XSS vulnerabilities**, and **3x more readability problems**. GitClear's analysis of 211 million lines of code found an **8-fold increase in duplicate code blocks** in 2024 and a collapse in refactoring activity from 25% of changes to under 10%. The Stanford CCS 2023 study by Perry et al. found developers with AI access wrote significantly less secure code — and were *more likely to believe they wrote secure code*, creating a dangerous confidence gap.

Ox Security's October 2025 "Army of Juniors" report, analyzing 300+ repositories, identified AI-generated code as "highly functional but systematically lacking in architectural judgment" and cataloged 10 critical anti-patterns including over-specification, vanilla-style reinvention of existing libraries, and phantom bug handling. The METR randomized controlled trial (July 2025) found AI tools made experienced developers **19% slower** on real tasks, despite developers believing they were 20% *faster* — a **39-point perception gap**.

AI introduces five distinct debt categories that traditional taxonomies miss:

- **Comprehension debt** — code ships faster than developers understand it. Stack Overflow's 2026 survey found **76% of developers** using AI tools generated code they didn't fully understand at least sometimes.
- **Pattern violation debt** — AI ignores project conventions, introducing inconsistent styles at **3x the human rate** for formatting and 2x for naming.
- **Duplication debt** — AI regenerates rather than reusing existing functions, with GitClear documenting copy-pasted lines exceeding moved lines for the first time in history.
- **Phantom dependency debt** — AI references APIs that don't exist, deprecated methods, and libraries not in the project. **66% of developers** cite "AI solutions that are almost right, but not quite" as their top complaint.
- **Verification debt** — diffs approved without being fully read because AI generates code faster than humans can review. Faros AI found review time increased **91%** as AI-adoption teams generated 98% more pull requests, with productivity gains "vanishing into expanded review queues."

The compounding dynamic is what MIT professor Armando Solar-Lezama calls "a brand new credit card": AI amplifies whatever foundation exists. Strong foundations get amplified into faster shipping; weak foundations get amplified into faster debt accumulation.

## Lightweight markdown tracking works when it has the right fields and a fixed review cadence

Research on debt documentation reveals a clear spectrum. At one extreme, the ms1963/TechnicalDebtRecords project defines 17 fields per item — thorough but too heavy for a markdown file maintained alongside code. At the other, andrewgrewell's open-source project uses a simple bullet list — lightweight but unprioritizable. The UK Government Digital Service's RFC-069 strikes the best balance: impact and effort each rated High/Medium/Low with written justification, reviewed fortnightly by senior technical leadership.

The consensus on what makes debt items actionable centers on **quantified impact**. GOV.UK recommends statements like "we are spending two days per month working around this" rather than vague descriptions. IdeaPlan advises: "'Flaky tests slow CI by 20 minutes per PR, costing 8 engineer-hours per week' is more persuasive than 'our tests are flaky.'" The LobeHub tech debt tracker template adds an "interest rate" field — the ongoing cost of not fixing the item — which directly enables cost-of-delay prioritization.

The critical finding on staleness: a ScienceDirect survey of 226 respondents across 15 organizations found **only 7.2% methodically track technical debt** and only 26% use any tool. Tan, Feitosa, and Avgeriou studied 312 debt items empirically and found an average **~1 year lag** between debt introduction and identification, with test debt items least likely to ever be paid back. The implication is clear: automated detection (static analysis, dependency scanning) must supplement manual tracking, and review cadence must be enforced, not aspirational.

Architecture Decision Records (ADRs) provide a natural companion format. The workingsoftware.dev Lean TDR format is explicitly modeled on ADRs and fits naturally into arc42 Section 11 (Risks and Technical Debt). For the JD-LLM framework context, where debt is assessed during `/bootstrap` and maintained by `/weekly-maintenance`, a TDR-style format in the repo with weekly review is the right approach.

---

## Recommended classification scheme

The following 7-category system consolidates the Alves et al. academic taxonomy into categories that are distinct enough to be useful, granular enough to track patterns, and aligned with AI-specific debt types. Each category includes an estimated relative carrying cost based on the research.

| Category | Description | Carrying cost | Common AI contribution |
|---|---|---|---|
| **Architecture** | Structural issues: coupling, modularity violations, misaligned patterns, framework limitations | **Highest** — compounds exponentially through coupling | Over-abstraction, monolith regression, ignoring project patterns |
| **Code quality** | Complexity, duplication, poor naming, style violations, dead code | **Medium-high** — daily friction in active files | Duplication (8x increase), inconsistent style (3x rate), cargo-cult patterns |
| **Test** | Missing coverage, brittle tests, flaky CI, shallow test suites | **High** — enables all other debt to hide | Inflated coverage with meaningless tests, security theater |
| **Dependency** | Outdated libraries, phantom imports, version conflicts, security vulnerabilities | **High** — compounds through vulnerability exposure | Phantom dependencies, outdated API usage, deprecated patterns |
| **Documentation** | Missing/outdated docs, unclear APIs, knowledge silos | **Medium** — spikes during onboarding and incidents | AI generates code faster than docs, comprehension gaps |
| **Infrastructure** | CI/CD issues, deployment friction, environment drift, build problems | **Medium** — blocks velocity improvements | Configuration drift from AI-suggested infra changes |
| **Security** | Known vulnerabilities, insecure patterns, missing input validation | **Highest potential** — single-incident catastrophic cost | 2.74x more XSS, hardcoded credentials, insecure deserialization |

**Severity levels** (4-tier, aligned with SonarQube conventions and industry practice):

| Severity | Definition | Response time | Interest rate |
|---|---|---|---|
| **Critical** | Blocks development, security vulnerability in production path, data loss risk | Current sprint | Compounding daily |
| **High** | Significant velocity impact, affects multiple components, growing worse | Next 2 sprints | Compounding weekly |
| **Medium** | Noticeable friction, contained to one area, stable | Next quarter | Linear/stable |
| **Low** | Minor inconvenience, cosmetic, isolated, rarely touched code | Opportunistic | Near-zero |

**Prioritization framework** — a 3-factor score:

1. **Impact** (1–3): How much does this slow development or risk production? (1=minor friction, 2=significant velocity impact, 3=blocks work or security risk)
2. **Reach** (1–3): How much code/how many developers does this affect? (1=isolated, 2=one team/module, 3=cross-cutting)
3. **Effort** (1–3): How hard is this to fix? (1=hours, 2=days, 3=weeks+)

**Priority score = (Impact × Reach) / Effort**. Higher scores should be addressed first. This is a simplified WSJF (Weighted Shortest Job First) that captures cost-of-delay dynamics without requiring precise estimation. Items scoring ≥4.5 are candidates for the current sprint; items scoring 1.0 or below are candidates for permanent acceptance.

**Fowler quadrant tag** (optional but recommended for pattern analysis): Each item should be tagged as one of `deliberate-prudent`, `deliberate-reckless`, `inadvertent-prudent`, `inadvertent-reckless`, or `ai-generated`. This enables retrospective analysis of *why* debt is accumulating, not just *what* debt exists.

---

## Recommended tracking format

The format below is designed for a single `TECH_DEBT.md` file in the project root. It balances information density with maintainability, includes every field that research identifies as essential for prioritization, and supports the JD-LLM framework's `/bootstrap` assessment and `/weekly-maintenance` cycle. Items are organized by severity, with resolved items moved to an archive section rather than deleted.

```markdown
# Technical Debt Register

> Last reviewed: YYYY-MM-DD | Next review: YYYY-MM-DD
> Active items: X | Resolved this quarter: Y

## Critical

### TD-001: [Short descriptive title]
- **Category:** Architecture | Code | Test | Dependency | Docs | Infrastructure | Security
- **Severity:** Critical | **Since:** YYYY-MM-DD
- **Origin:** ai-generated | legacy | deliberate-prudent | deliberate-reckless | inadvertent
- **Location:** `src/module/file.ts:45-120`, `src/other/file.ts`
- **Owner:** @person-or-team

**What:** One-paragraph description of the debt and why it exists.

**Impact:** Quantified cost of carrying this debt.
Example: "Adds ~15 min to every deploy. Caused 3 production incidents in Q1.
Blocks migration to new auth provider."

**Interest rate:** Growing | Stable | Shrinking
**Effort:** Hours | Days | Weeks — brief estimate with rationale.

**Resolution:** Concrete next steps, dependencies, and prerequisites.

**Linked:** Sprint story #123 | Blocks TD-004 | See ADR-007

---

## High

### TD-002: ...

## Medium

### TD-003: ...

## Low

### TD-004: ...

---

## Accepted debt
> Items consciously accepted as permanent trade-offs.

### TD-005: [Title]
- **Accepted:** YYYY-MM-DD | **Rationale:** [Why this is acceptable]
- **Review trigger:** [Condition that would reopen this — e.g., "if we exceed 10k users"]

---

## Resolved (last 90 days)
> Archive of recently resolved items for pattern analysis.

### ~~TD-000: [Title]~~
- **Resolved:** YYYY-MM-DD | **Method:** Refactored | Rewritten | Deleted | Superseded
- **Effort actual:** 3 days (estimated 2 days)
- **Sprint:** Sprint 14, Story #89
```

**Design rationale for each field:**

The **origin** field distinguishes AI-generated debt from legacy and deliberate debt — essential for the AI-development context and for tracking whether AI governance is improving over time. **Interest rate** (Growing/Stable/Shrinking) captures the compounding dynamic without requiring precise calculation; items marked "Growing" should be prioritized over "Stable" items of equal severity. **Quantified impact** is the single most important field for prioritization — research consistently shows that vague descriptions like "this is messy" fail to drive action, while "costs 8 engineer-hours per week" does. **Resolution plan** makes items actionable rather than just documented. **Review trigger** on accepted items prevents the register from accumulating permanently deferred items that should be reconsidered when conditions change.

The **resolved section** with actual effort vs. estimated effort enables calibration of future estimates — a lightweight feedback loop. Keeping resolved items for 90 days enables sprint retrospective analysis; older items can be moved to a `TECH_DEBT_ARCHIVE.md` file if desired.

---

## Recommended AI-debt management approach

### Prevention layer: stop AI from creating debt

The most effective prevention strategies target the root cause — AI lacks architectural judgment and project context. Three practices have the strongest evidence base:

**Project conventions file.** GitHub's `.github/copilot-instructions.md` (or equivalent for other AI tools) should define project-specific standards: preferred patterns, banned anti-patterns, logging conventions, error handling approach, and module boundaries. This is the single highest-leverage intervention because it provides context AI tools otherwise lack. For the JD-LLM framework, this maps to the architecture and conventions captured during `/bootstrap`.

**AI-aware code review checklist.** CodeRabbit's research suggests reviewers of AI-generated code should explicitly verify: error path coverage, concurrency correctness, configuration validation, password/secret handling, and adherence to existing patterns. The "whiteboard test" — can the developer trace the data flow from memory without looking at the code? — is a practical comprehension-debt detector. All AI-assisted PRs should be tagged as such.

**Quality gates in CI/CD.** Static analysis (SonarQube, Semgrep), dependency scanning, and CodeScene's CodeHealth metric should run on every PR. The SonarQube default quality gate — zero new bugs, zero new security vulnerabilities, debt ratio ≤5% on new code, ≥80% test coverage on changed code — provides a reasonable baseline. The key insight from Ox Security's research is that AI-generated code passes functional tests while failing structural quality checks, so **static analysis is more important than test coverage** for catching AI-specific debt.

### Detection layer: identify AI-introduced debt early

**Track AI-assisted commits.** Use commit message conventions or git metadata to tag AI-assisted work. This enables trend analysis: is the AI-generated debt ratio improving or worsening? GitClear's code operations classification (distinguishing added, updated, deleted, moved, and copy-pasted code) can identify AI-correlated patterns like the duplication spike their research documents.

**Monitor for AI-specific anti-patterns.** During `/weekly-maintenance`, specifically check for: duplicate code blocks (the 8x increase GitClear found), phantom imports of non-project dependencies, pattern violations against established conventions, and "security theater" tests that achieve coverage without meaningful assertions. These are the anti-patterns most reliably associated with AI generation.

**Comprehension audits.** Periodically (quarterly or during `/bootstrap`), assess whether the team can explain how AI-generated modules work. The **76% of developers** generating code they don't fully understand represents a ticking debt bomb. Modules that no team member can explain should be flagged as comprehension debt.

### Remediation layer: use AI to pay down debt

AI is both the disease and part of the cure. GitHub's billing team reports using Copilot Coding Agent to reduce debt remediation time "from weeks of intermittent, split focus to a few minutes of writing an issue and a few hours reviewing a pull request." The most effective AI-assisted remediation targets:

- **Test generation** for untested legacy code (where AI's tendency toward shallow tests is still better than zero tests)
- **Dependency updates** with automated migration patterns (OpenRewrite)
- **Code documentation** for poorly documented modules (where AI comprehension is sufficient)
- **Mechanical refactoring** like extracting functions, renaming for consistency, and removing dead code

The critical rule: **AI should never remediate security debt or architectural debt autonomously.** These categories require human judgment about trade-offs and system-level reasoning that current AI tools systematically lack.

### Tracking AI debt trends

Add a quarterly summary section to the debt register:

```markdown
## AI debt trends (quarterly)
| Quarter | New items | AI-origin | Resolved | Net change | Top AI pattern |
|---------|-----------|-----------|----------|------------|----------------|
| 2026-Q1 | 12        | 5 (42%)   | 8        | +4         | Duplication     |
| 2025-Q4 | 9         | 3 (33%)   | 7        | +2         | Pattern violation|
```

This lightweight trend table, updated during `/weekly-maintenance`, makes AI debt visible at the strategic level and enables calibration of prevention measures over time.

---

## Knowledge gaps and areas of uncertainty

**No validated metric for AI-specific debt.** Google found that no single automated metric predicted technical debt perception among engineers. For AI-generated debt specifically, there is no validated metric — GitClear's code-churn analysis is the closest, but it measures correlation, not causation. The field needs a reliable, automated way to distinguish AI-introduced debt from human-introduced debt.

**The METR slowdown finding needs replication.** The 19% slowdown finding is from a single study of 16 experienced developers on mature codebases they knew deeply. It may not generalize to less experienced developers, greenfield projects, or different AI tools. The Faros AI study of 10,000+ developers found throughput increases but review bottlenecks — suggesting the productivity picture is nuanced and context-dependent.

**Long-term compounding effects are unknown.** The AI code quality research covers roughly 2022–2025. We don't yet know how AI-generated debt compounds over 3–5 years as codebases mature. The GitClear duplication trend and refactoring collapse are concerning leading indicators, but longitudinal studies don't yet exist.

**Optimal sprint allocation for AI-heavy teams is unresearched.** The 15–20% allocation consensus predates widespread AI adoption. If AI accelerates code generation but not code quality, teams may need to shift allocation — perhaps 20–25% for debt with a specific carve-out for AI-debt review. No empirical research yet validates a specific number.

**Comprehension debt has no established measurement.** Despite being identified as a major AI-specific category, there is no tool or metric for measuring comprehension debt. The "whiteboard test" is practical but subjective. Self-Admitted Technical Debt (SATD) detection via NLP is an active research area that may eventually help, but current tools focus on code comments rather than comprehension gaps.

**Documentation debt remains understudied.** The 2025 systematic literature review explicitly calls out documentation debt as "one of the most underrepresented categories" in research. For AI-assisted development, where code generation outpaces documentation, this gap is particularly concerning.