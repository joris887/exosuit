# Sprint planning for AI-assisted development

**The most effective sprint specification for AI-assisted development is radically leaner than traditional Scrum artifacts.** Research across 50+ sources — empirical studies, practitioner case reports, and emerging AI-native frameworks — converges on a clear pattern: the best sprint documents capture the *why* (sprint goal), *what* (scoped stories), and *boundaries* (definition of done, capacity notes) in under 50 lines of structured text. Everything else is either derived at session start, tracked in code, or wasted overhead. For AI-assisted workflows specifically, the context window replaces velocity as the binding capacity constraint, files replace conversations as the handoff mechanism, and the plan-then-execute pattern is the single most validated workflow across all major AI coding tools.

This report synthesizes findings from Scrum.org, Atlassian, Basecamp's Shape Up, DORA research (39,000+ professionals), the Siemens Health Services case study, GitHub/Microsoft's Copilot RCTs, the METR developer study, DX's quarterly impact reports, BMAD Method documentation, Claude Code official docs, and practitioner frameworks from Mike Cohn, Ron Jeffries, Daniel Vacanti, and Troy Magennis.

---

## Sprint goals are the single highest-leverage planning element

Locke and Latham's goal-setting research — 35+ years, 40,000+ participants, 100+ task types — found that specific, challenging goals led to higher performance in **90% of cases**, with participants achieving over **250% higher performance** than those given easy or vague goals (correlation r = 0.82, p < 0.001). Applied to sprints, Scrum.org practitioners report that sprint goals create coherence, enable flexibility on individual stories, and prevent "feature factory" mode where teams ship without purpose.

The practical evidence is equally strong. Sprint goals serve as the scope-protection anchor: the 2020 Scrum Guide explicitly states "no changes are made that would endanger the Sprint Goal" while allowing the Sprint Backlog itself to evolve. This means teams can drop low-priority stories without failing the sprint — a pattern Maarten Dalmijn argues makes non-goal carry-over a *positive signal* of correct prioritization rather than a planning failure.

For AI-assisted workflows, sprint goals gain an additional function: **they provide the "why" context that AI assistants need to make good implementation decisions.** A goal like "Enable users to authenticate via OAuth2" gives an AI session enough strategic context to resolve ambiguous implementation choices without human intervention. Without it, AI assistants default to asking clarifying questions or making arbitrary decisions — both of which burn context window tokens.

The strongest anti-pattern is compound goals ("achieve X AND Y AND Z"), which split focus and eliminate the flexibility benefit. Mike Cohn recommends single-sentence goals that even executives can understand. For the JD-LLM framework, the sprint goal should be the first line of progress.md and the primary context-setting element for every session.

---

## What minimum viable sprint documentation actually contains

The research converges on five essential elements, with everything else being optional overhead:

**Sprint Goal** (1-2 sentences) provides direction and decision-making context. **Selected stories** (linked, not duplicated) define the work. **Definition of Done** (referenced, not repeated) establishes completion criteria. **Capacity and constraints** (availability, known blockers, dependencies) ground the plan in reality. **An initial plan for the first few days** (not the full sprint) provides enough structure to start without over-specifying.

Scrum.org's advanced sprint planning guidance explicitly warns against over-specifying: "The effort spent refining items three or four Sprints out is often discarded entirely." Ron Jeffries goes further, arguing that backlog items should fit on index cards — the story is a reminder to have a conversation, not a specification. Mike Cohn's critical insight on detail level: "The team doesn't need to know everything before it starts a story. All open questions need to be answered before a story is finished, but not all need to be answered before the story is started."

For documentation overhead, the PMI Disciplined Agile framework codifies the "Just Barely Good Enough" (JBGE) principle: sufficiency is determined by the consumer of the document, not the producer. A Scrum Alliance study found workers spend **5 hours per week just looking for project information** — so documentation must be findable and scannable, not comprehensive. The sweet spot from Martin Fowler and others: document decisions (not discussions), document what won't be obvious in two weeks, let code document the "how," and supplement with "why" (Architecture Decision Records, sprint goals).

For AI-assisted workflows, the most valuable mid-sprint documentation is the Architecture Decision Record (ADR) — a four-field format (Title, Context, Decision, Consequences) that captures technical decisions with rationale. ADRs serve double duty: they inform future human developers *and* provide critical context for AI sessions that need to understand why the codebase is shaped a particular way.

---

## The metrics that actually predict improvement

The Siemens Health Services case study — one of the strongest empirical cases in agile metrics research — found **no correlation between story point estimates and actual cycle time.** When Siemens switched from velocity/story points to flow metrics (WIP, cycle time, throughput), they achieved a **42% reduction in cycle time** and found Monte Carlo simulations using historical throughput data produced "far more accurate and realistic release delivery forecasts" than velocity-based estimation. A Parabol survey confirmed the paradox: velocity was the second most popular metric but also the metric most commonly described as unhelpful.

The empirically validated metrics fall into three tiers. **Tier 1 (essential)** includes cycle time by work type, throughput (items per period), work in progress, and defect escape rate. These are grounded in Daniel Vacanti's flow framework, adopted by Scrum.org for Professional Scrum with Kanban, and linked to business outcomes through DORA research spanning 39,000+ professionals across the *Accelerate* study. DORA's key finding: **speed and stability are not tradeoffs** — top performers excel at both.

**Tier 2 (contextually useful)** includes sprint goal achievement rate (predictability signal), burnup charts (scope visibility), and velocity (for internal team planning only — never as a performance metric, never for cross-team comparison). LinearB's founder documents three main velocity abuses: comparing teams, measuring performance, and pressuring commitments. Ron Jeffries, who may have invented story points, has said: "I may have invented story points, and if I did, I'm sorry now."

**Tier 3 (leading indicators)** includes work item age (Vacanti's strongest daily signal for flow problems), sprint churn rate (target below 20%), backlog readiness, and team satisfaction. Applied Frameworks identifies team happiness as "the only leading indicator in the bunch — a low happiness score is nearly always a sign of underlying problems."

For AI-assisted sprints specifically, traditional velocity becomes even less meaningful because AI accelerates coding but shifts bottlenecks to code review and validation. The Faros AI report across 10,000+ developers found that developers using AI produced **47% more PRs per day** but organizations saw "no measurable improvement in delivery velocity or business outcomes." Track cycle time and throughput instead — they capture the end-to-end reality, including the review overhead that AI-generated code creates.

---

## How AI reshapes sprint capacity and session architecture

The productivity evidence is more nuanced than vendor claims suggest. Controlled studies show **21-55% speedup on isolated coding tasks** (GitHub/Microsoft RCT: 55.8% faster; Google internal RCT: 21% faster; multi-company study across 5,000 developers: 26% average). But the METR study — 16 experienced open-source developers working on their own familiar codebases — found AI users took **19% longer**, despite believing they were faster. The DX Q4 2025 Impact Report across 266 companies found productivity gains plateauing at **~10%** at the team level, with **22% of merged code being AI-authored** but most organizations seeing "no measurable performance gains" in delivery metrics.

The reconciliation: **AI accelerates individual code production but shifts bottlenecks to review, testing, and integration.** Faros AI found review queues ballooning with 98% more PRs, and reviewers spending 91% longer validating AI code. The practical implication for sprint capacity: **do not increase sprint commitments by more than 10-15%** based on AI adoption. The real benefit is reduced cognitive load on routine tasks, not a velocity multiplier.

The context window has emerged as the binding capacity constraint for AI-assisted sprints. All major tools — Claude Code, Cursor, GitHub Copilot, aider — converge on the same session architecture pattern:

**One session per story** is the dominant approach. Claude Code's `--worktree` flag creates isolated worktrees per feature. Cursor 2.0 supports background agents on separate branches. GitHub Copilot's coding agent creates one PR per task. For complex stories, a three-session pattern emerges: planning session (produces plan.md), implementation session(s) (executes plan), and review/testing session.

**Files are the handoff mechanism between sessions.** The community has converged on structured markdown files as the bridge. Claude Code uses a three-tier memory architecture: CLAUDE.md (~150 lines, loaded every session, survives compaction), auto-memory (build commands, debugging insights saved automatically), and session memory (structured summaries extracted per session). The Long-Term Context Management Protocol (LCMP) uses a `./context/` directory with state.md, schema.md, decisions.md, and insights.md. Nick Tune's minimalist approach uses tasks.md plus session.md with a state machine enforcing when Claude updates these files.

**The plan-then-execute pattern is universal.** Cursor's Plan Mode drafts before Agent Mode edits. BMAD's four-phase cycle separates Analysis → Planning → Solutioning → Implementation. Aider's ask/code bouncing uses `/ask` for discussion, then switches to `/code` for execution. Carl Rannaberg's widely-cited workflow uses Gemini for planning (outputting plan.md with checkboxes) and Claude for execution. This separation is critical for AI-assisted development because it front-loads human judgment (strategy, architecture, scope decisions) into a phase where context windows are fresh, then delegates execution to AI when the path is clear.

**The BMAD Method is the most mature AI-native framework** found in this research. It defines 12+ specialized AI agent personas as "Agent-as-Code" markdown files, uses a four-phase development cycle, and includes sprint planning commands that produce sprint-status.yaml. Its core insight — documentation as source of truth with code as a downstream derivative — inverts the traditional agile relationship between working software and documentation, because AI agents need written specifications to maintain coherence across context boundaries.

---

## Recommended sprint specification format

Based on this research, here is the recommended sprint spec template for the JD-LLM Development Framework. The design principles: **lean enough to load every session** (< 50 lines in progress.md), **structured for both human scanning and AI parsing**, **captures only what won't be obvious from code or git history**, and **provides the "why" context that AI sessions need for autonomous decision-making**.

```markdown
# Sprint [N]: [Sprint Goal — one sentence]

## Goal
[1-2 sentences: what outcome this sprint achieves and why it matters]

## Stories
| # | Story | Size | Status | Session |
|---|-------|------|--------|---------|
| 1 | [Story title] | S/M/L | 🔲/🔄/✅ | - |
| 2 | [Story title] | S/M/L | 🔲/🔄/✅ | - |

## Boundaries
- **Done means**: [DoD reference or 1-line summary]
- **Out of scope**: [What this sprint explicitly does NOT include]
- **Risks/blockers**: [Known dependencies or risks, if any]

## Capacity
- **Available sessions**: [estimated count]
- **Buffer**: [% reserved for unplanned work — default 15%]
- **Constraints**: [PTO, deadlines, external dependencies]

## Decisions
[Append-only log: date, decision, rationale — added during sprint]

## Notes
[Anything important for next session — updated at session end]
```

**Justification for each section:**

The **Goal** section is the highest-leverage element (Locke & Latham, Scrum.org). It provides the decision-making context AI assistants need and the scope-protection anchor for mid-sprint changes. The **Stories table** uses T-shirt sizes (S/M/L) rather than story points — Ron Jeffries and the Siemens case study both argue that story points add estimation overhead without proportional planning value. The Session column tracks which stories were completed in which session, creating the session-to-sprint mapping the framework needs. **Boundaries** captures scope exclusions (Shape Up's "appetite" concept — fixed time, variable scope) and the Definition of Done reference. **Capacity** includes the unplanned work buffer (research consensus: 10-20% for most teams, per AgileLAB and Zenhub). **Decisions** is an append-only ADR-lite log that persists rationale across sessions — the single most valuable mid-sprint documentation practice identified. **Notes** is the session handoff field, updated at session end for the next `/continue`.

The template intentionally excludes: detailed task breakdowns (emerge during sessions), hour-by-hour schedules, individual assignments (contradicts Scrum.org's team commitment model), and acceptance criteria per story (these belong in story definitions, not the sprint spec — Mike Cohn's Card/Conversation/Confirmation model).

For progress.md specifically (loaded every session), this template should be further compressed to the Goal, Stories table, and Notes — roughly 15-20 lines. The full sprint spec lives in a sprint file (e.g., `sprints/sprint-N.md`) while progress.md carries only what the AI session needs to orient itself.

---

## Recommended metrics with evidence

**Track these (empirically validated):**

- **Cycle time by story type** — The Siemens case study's 42% improvement validates this as the most actionable process metric. Categorize stories as feature/bug/refactor/infrastructure. In AI-assisted workflows, also track cycle time for AI-generated vs human-generated code to identify where AI actually helps.
- **Throughput** (stories completed per sprint) — Objective, enables Monte Carlo forecasting (Troy Magennis), and doesn't require estimation. Count completed items; let the statistics handle prediction.
- **Sprint goal achievement** (yes/no per sprint) — The simplest predictability metric. ProductPlan targets 80% sprint goal completion across their engineering org. Binary tracking avoids Goodhart's Law gaming.
- **Defect escape rate** — "The truest measure of testing effectiveness" per quality metrics research. Track defects that reach production, not total defects found (which rewards creating bugs then finding them).
- **Sprint churn** — Percentage of stories added/removed mid-sprint. Target below 20%. Above 40% signals broken upstream processes per Harness benchmarks.

**Track if relevant (contextually useful):**

- **Test coverage delta** — Useful as a leading quality indicator when measured per sprint (did coverage go up or down?), not as an absolute target. A dropping trend signals tech debt accumulation.
- **Work item age** — Vacanti's strongest daily leading indicator. Any story in progress for longer than the team's average cycle time is at risk. Critical for Daily Scrum equivalent in AI-assisted workflows.
- **Done-to-commit ratio** — Track over time to calibrate planning accuracy. 80% is healthy; above 95% means under-committing; below 65% means over-committing.

**Avoid these (vanity or harmful):**

- **Velocity as a target or comparison metric** — Universally warned against by Scrum.org, Mike Cohn, LinearB, and practitioners. Use only for internal team release forecasting if story points are used at all.
- **Lines of code** — Classic vanity metric. AI makes this even more misleading since AI-generated code volume doesn't correlate with value. GitClear found AI tools increase code that gets discarded within two weeks.
- **Hours worked or story points completed** — Activity metrics that reward busyness over outcomes.
- **Raw PR count** — AI inflates PR volume (Faros: 47% more PRs) without proportional delivery improvement. Track merge-to-deploy lead time instead.

---

## Recommended AI-specific sprint patterns

**Session management: one story, one session, clean handoff.**

Start each session by reading progress.md and the sprint spec. Work on one story per session. At session end, update the Stories table status, add any decisions to the Decisions log, and write next-session context to Notes. Use `/continue` to resume within a story; start a new session for a new story. For complex stories spanning multiple sessions, the three-session pattern (plan → implement → verify) prevents context window exhaustion by resetting between phases.

**Capacity planning: sessions, not velocity.**

Replace traditional velocity-based capacity with session-based planning. Estimate the number of AI sessions available in the sprint period (accounting for human review time between sessions). Size stories as S (1 session), M (2-3 sessions), or L (3-5 sessions). A typical 2-week sprint might contain 8-12 sessions for a solo developer. Buffer 15% of sessions for unplanned work. **Do not assume AI multiplies capacity** — the research consensus is 10-15% team-level productivity gain, with bottlenecks shifting to review and integration.

**Context continuity: structured files over conversation history.**

The dominant pattern across Claude Code, Cursor, Copilot, and aider is structured markdown files as the session bridge. For the JD-LLM framework, the recommended hierarchy is:

- **CLAUDE.md** (~150 lines): Project-level context loaded every session — architecture, conventions, tooling, standing instructions. Survives compaction. Keep under 200 lines.
- **progress.md** (~20 lines): Sprint-level context — current goal, story statuses, active notes. The minimum viable session initializer.
- **Sprint file** (sprints/sprint-N.md): Full sprint spec with decisions log, retrospective data, and historical record. Referenced but not loaded every session.
- **Story files** (optional, for M/L stories): Implementation plan, acceptance criteria, technical decisions specific to that story.

**The plan-then-execute pattern is non-negotiable.**

Every major AI tool converges on separating planning from execution. Human judgment handles strategy, scope, and architecture in a planning phase when context windows are fresh. AI handles implementation when the path is clear. This maps naturally to sprint planning (human-driven) → story execution (AI-assisted) → review (human-driven). For the JD-LLM framework: `/sprint-start` produces the plan; individual sessions execute stories; `/sprint-end` captures outcomes; `/retrospective` drives improvement.

**Parallel work via git worktrees, not context sharing.**

Claude Code's `--worktree` flag, Cursor's background agents, and Copilot's coding agent all use git worktree isolation for parallel AI work. Each worktree gets its own context, avoiding the context-sharing problem entirely. For solo developers, this enables working on one story while an AI agent independently progresses another on a separate branch. Track parallel sessions in the Stories table's Session column.

---

## Knowledge gaps and areas of uncertainty

**AI productivity at scale remains contested.** Lab studies show 21-55% speedup; the METR field study shows 19% slowdown for experts on familiar codebases; DX reports ~10% team-level gains. The truth is likely task-dependent and experience-dependent, but no definitive model exists for predicting AI productivity impact on a per-team basis.

**No rigorous comparison of AI-native frameworks exists.** BMAD is the most documented, but no study compares BMAD, Claude Code Workflows, ContextKit, or similar frameworks on outcomes like delivery speed, code quality, or developer satisfaction. These frameworks are months old, and evidence is entirely anecdotal.

**Session-optimal story sizing is unexplored.** The recommendation to size stories as S/M/L based on sessions is grounded in the context window constraint, but no study has validated whether session-based sizing improves planning accuracy compared to traditional story points in AI-assisted workflows.

**Long-term technical debt from AI-assisted sprints is unmeasured.** GitClear projects doubled code churn and DORA reports 4x more code cloning, but no longitudinal study tracks whether AI-assisted sprints accumulate technical debt faster than human-only sprints over 6-12 month horizons. The quality metrics recommended above (defect escape rate, coverage delta) are the best available proxy, but they don't capture architectural degradation.

**Multi-developer AI coordination is largely uncharted.** Nearly all documented AI-assisted workflows assume a solo developer. How multiple developers coordinate AI sessions on the same codebase — merge conflicts from parallel AI agents, review bottlenecks from AI-generated code volume, shared context management — lacks both research and mature tooling. The JD-LLM framework's stated goal of supporting teams will require patterns that don't yet exist in the literature.

**Retrospective formats for AI-assisted work are undefined.** Traditional retrospective formats (Start/Stop/Continue, 4Ls, Sailboat) were designed for human team dynamics. No format has been developed or tested for reflecting on AI-assisted sprint execution — questions like "where did AI help most?", "where did AI-generated code cause problems?", and "how should we adjust session patterns?" are absent from existing retrospective research.