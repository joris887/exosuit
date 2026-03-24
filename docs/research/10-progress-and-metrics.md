# Metrics that matter for AI-assisted development

**The single most important finding across a decade of DORA research, the SPACE framework, and emerging AI-specific studies is this: AI amplifies what's already there.** Strong teams with good practices get faster; struggling teams accumulate debt faster. The 2025 DORA report found AI now correlates positively with throughput (reversing a negative correlation in 2024), but **instability remains persistently higher** with AI adoption. Faros AI's telemetry across 10,000+ developers confirmed the paradox: **+21% more tasks completed but +9% more bugs, +154% larger PRs, and +91% longer review times** — with organizational delivery metrics remaining flat. This means your metrics framework must balance velocity signals against quality signals, and must be cheap enough to maintain that it doesn't become the problem it's trying to solve.

The framework context — a lean `progress.md` auto-loaded every session, parsed by scripts, consumed by both humans and AI — demands ruthless metric selection. Research consistently shows that **5–8 well-chosen metrics outperform 20+ poorly chosen ones**, and that every metric must pass a simple test: does tracking this change behavior for the better?

---

## DORA metrics in 2025: what changed and what still holds

DORA's four key metrics — deployment frequency, change lead time, change failure rate, and mean time to recovery — remain the most validated delivery performance measures in software engineering, backed by a decade of research across **39,000+ professionals**. But the 2024 and 2025 reports introduced significant changes that matter for this framework.

The 2024 report added a fifth metric, **Rework Rate** (unplanned deployments to fix user-facing bugs relative to total deployments), because change failure rate has always been a statistical outlier that doesn't load cleanly with other metrics. The 2025 report went further: it **dropped the elite/high/medium/low tiers entirely**, replacing them with seven team archetypes based on eight measures spanning throughput, stability, team performance, individual effectiveness, and burnout. About 40% of teams fall into the top two archetypes, suggesting high performance is more reachable than the old "elite" label implied.

For AI-assisted development specifically, the DORA 2024 data showed a **-1.5% reduction in delivery throughput** and **-7.2% reduction in delivery stability** with AI adoption, while simultaneously showing improvements in documentation quality (+7.5%), code review speed (+3.1%), and reduced code complexity (+1.8%). The root cause: AI increases batch size. Developers produce more code faster, creating larger changesets that carry more risk. By 2025, the throughput relationship had reversed to positive, but the stability penalty persisted.

**For solo developers and small teams**, DORA metrics need adaptation. The metrics were designed for team-level measurement, and the DORA team explicitly warned against individual-level use. For solo contexts, deployment frequency measures CI/CD discipline rather than coordination capacity. Change lead time collapses to pipeline efficiency. Change failure rate remains meaningful as a quality signal. The key adaptation: **use metrics for longitudinal self-improvement, not comparison against DORA benchmarks** derived from team data. Track your own trends.

The most substantive criticisms of DORA are worth internalizing. The metrics are **lagging indicators that don't explain root causes**. Quality is underrepresented — change failure rate only captures failures severe enough for rollback, missing performance regressions, UX degradation, and security vulnerabilities. **Value delivery is entirely absent** — DORA tells you how fast you ship, not whether what you shipped was worth building. And developer experience is invisible: DORA metrics can look excellent while developers burn out.

---

## SPACE and DevEx: measuring the human side without surveillance

The SPACE framework (Satisfaction, Performance, Activity, Communication, Efficiency), published in 2021 by Forsgren, Storey, Zimmermann and colleagues, was designed to correct the reductionism of single-metric productivity measurement. Its core principle: **measure across at least three dimensions simultaneously**, because any single dimension can be gamed or misleading. Nicole Forsgren herself has characterized DORA as "an implementation of SPACE," with DORA's delivery metrics mapping primarily to the Efficiency and Performance dimensions.

A landmark 2025 study, "The SPACE of AI" (Houck et al., surveying 530 developers across Microsoft, Airbnb, Atlassian, Meta, Netflix, and others), mapped AI's impact across all five dimensions. **62% reported higher job satisfaction** with AI tools, **88% said AI improves task throughput**, and **82% reported improved efficiency**. But only **48% agreed AI improved collaboration** — making Communication the hardest dimension to improve with AI. Critically, interviews revealed that AI reduced low-value interruptions and enabled higher-quality conversations, benefits invisible to quantitative metrics.

The perception-reality gap is the most important finding for any metrics framework. The METR randomized controlled trial (16 experienced open-source developers, 246 real tasks) found AI tools **increased completion time by 19%** — developers were objectively slower — yet they **perceived a 20% speedup** even after completing tasks. The BNY Mellon study (2,989 developers) found 86% satisfied with Copilot but roughly **60% saving less than one hour per week**, with only a weak correlation (r=0.34) between satisfaction and actual time savings. This means **satisfaction metrics and performance metrics must be tracked together** to detect divergence.

For the JD-LLM framework specifically, the measurable SPACE dimensions without surveillance are:

- **Satisfaction**: Self-reported at sprint end (1–5 scale). A leading indicator — declining satisfaction predicts upcoming burnout and reduced productivity.
- **Efficiency**: Cycle time, context-switching frequency, flow state. Measurable from activity logs and self-report.
- **Activity**: Commits, tasks completed, AI interactions. Measurable from tooling but dangerous alone.
- **Performance**: Defect rates, customer outcomes. Measurable but lagging.

Communication metrics require surveys or qualitative observation and are impractical for solo developers to track automatically. The framework should acknowledge this gap rather than forcing measurement.

---

## Code quality metrics: what the evidence actually says

Not all code quality metrics are equal. Research identifies a clear hierarchy of predictive value.

**Relative code churn is the strongest predictor of defects.** Nagappan and Ball's landmark 2005 study at Microsoft Research found that relative churn measures (churned LOC / total LOC, files churned / file count) can discriminate between fault-prone and non-fault-prone binaries with **89% accuracy**. The critical distinction: absolute churn measures are poor predictors; only relative measures work. For AI-assisted development, this is especially relevant — GitClear's analysis found **41% higher code churn** for AI-generated code and a Pearson correlation of **0.98** between Copilot prevalence and "mistake code."

**Cyclomatic complexity correlates moderately-to-strongly with defects**, particularly when combined with size metrics. The practical consensus: target **≤10 per function**, flag at 15, hard-block at 20–25. SonarQube's cognitive complexity metric, which measures human comprehension difficulty rather than path count, is increasingly preferred. AI-generated code tends to be individually simpler (ChatGPT Python averages 2.47 complexity vs. 3.97 for human Python) but collectively contributes to higher duplication and more total issues — the volume effect outweighs per-unit quality.

**Test coverage has weak-to-moderate correlation with defect rates when confounders are controlled.** Inozemtseva and Holmes (2014) found coverage "is not strongly correlated with test suite effectiveness" after controlling for test suite size. Martin Fowler warns he'd "be suspicious of anything like 100% — it would smell of someone writing tests to make the coverage numbers happy." The evidence supports treating **80% as a reasonable target** with sharply diminishing returns above that, while recognizing that the specific 80% matters far more than the number. Low coverage is a reliable risk signal; high coverage is not a reliable quality signal. **Track coverage delta on new code** (is new code being tested?) rather than overall percentage.

**Technical debt ratio** (remediation cost / rewrite cost × 100%) should stay below **5%** for healthy codebases. Multiple studies found AI adoption increases technical debt by **30–41%**, driven by additive rather than integrative code patterns, refactoring avoidance, and context blindness. The most practical low-overhead approach combines automated tooling (SonarQube) with Adam Tornhill's forensic code analysis: identify hotspots where high change frequency intersects with high complexity. These hotspots represent the highest debt risk and are derivable entirely from version control history.

For the JD-LLM framework, **the recommended quality metrics are: relative code churn trend, complexity trend on changed files, test coverage delta on new code, and defect escape count.** These are automatable, predictive, and resistant to gaming.

---

## AI-specific metrics: separating signal from noise

The emerging landscape of AI-specific metrics is dominated by one finding: **acceptance rate is becoming "the new lines of code" — easy to measure, easy to misuse, largely irrelevant to business value.** GitHub's own research (Ziegler et al., 2024) found acceptance rate was the best single correlate with self-reported productivity, but multiple authoritative sources now warn against using it as a KPI. One company pushed acceptance rate to 45% while their change failure rate increased 30%. The metric is useful during initial tool evaluation and adoption tracking, then should be demoted to diagnostic status.

**Suggestion survival rate** (how long AI-generated code stays unmodified) was developed by GitHub as a quality signal. Their research found it was less correlated with productivity than acceptance rate, and shorter persistence windows correlated better than longer ones. GitClear tracks a proxy — code reverted or substantially modified within two weeks — which is more practically measurable. For the JD-LLM framework, tracking **7-day survival of AI-generated code** provides a meaningful quality signal without excessive overhead.

The metrics specific to the JD-LLM framework context — **edit-to-bash ratio, TDD compliance rate, skill success/failure rates, context reset frequency** — have no validation in published research. They are operational metrics for a specific AI coding workflow. However, they map to validated concepts:

- **Edit-to-bash ratio** maps to the balance between code generation and execution/testing — a proxy for TDD discipline and iterative development. No published measurement framework exists, but the concept aligns with DORA's finding that automated testing is a foundational capability that amplifies AI benefits.
- **TDD compliance rate** relates to the well-established finding that test-first development reduces defects. DORA 2025 emphasizes automated testing as a key AI capability amplifier.
- **Skill success/failure rates** are framework-specific (Claude Code's skills architecture) with no external validation, but tracking tool effectiveness over time is conceptually sound.
- **Context reset frequency** maps to the METR finding that context overhead is a major cost of AI assistance. High reset frequency could indicate poor context management, inefficient sessions, or tasks that exceed the AI's effective context window.

The DX Core 4 framework (launched January 2025 by the authors of SPACE, DORA, and DevEx) represents the most current unified approach: **Speed** (throughput, PR cycle time), **Effectiveness** (Developer Experience Index), **Quality** (PR revert rate, change failure rate), and **Impact** (percentage of time on feature development). Booking.com reported a **16% throughput increase** using this framework.

---

## The recommended metrics set for progress.md

Based on the research, the metrics framework for `progress.md` should follow three principles: **(1) balance velocity against quality**, because AI reliably increases the first while degrading the second; **(2) include at least one human/satisfaction signal**, because perception and reality diverge dramatically with AI; and **(3) automate collection**, because manual metrics become measurement theater within weeks.

**Track these 7 metrics:**

| Metric | Dimension | Why include | Collection method |
|--------|-----------|-------------|-------------------|
| **Tasks completed** | Activity/Speed | Direct output measure; denominator for quality ratios | Issue tracker or manual count |
| **Cycle time** | Efficiency | Time from task start to done; captures real throughput better than velocity | Git timestamps + task timestamps |
| **Change failure rate** | Quality | Percentage of changes causing bugs/rollbacks; DORA's most stable quality signal | Count post-deploy fixes / total deploys |
| **Test coverage delta** | Quality | Coverage on new/changed code this sprint; catches testing discipline decay | CI pipeline output |
| **Code churn ratio** | Quality | Lines modified within 14 days / total lines; strongest defect predictor | Git analysis (scripts/pm/metrics.sh) |
| **AI effectiveness** | AI-specific | Composite: context resets per session + skill success rate from activity log | Parse .activity-log.jsonl |
| **Dev satisfaction** | Satisfaction | 1–5 self-report at sprint end; leading indicator for burnout; catches perception-reality gaps | Manual at /sprint-end |

**Explicitly do NOT track these:**

- **Lines of code**: Completely broken by AI. A developer can generate thousands of lines in minutes. Correlated 0.98 with "mistake code" in GitClear's data.
- **Acceptance rate**: Becoming "the new LOC." Useful only during initial AI tool evaluation, then misleading. Games easily — accept everything, fix later.
- **Velocity (story points)**: Scrum.org, the *Accelerate* authors, and every serious engineering metrics researcher warns against using velocity for anything other than internal sprint planning. Inflates when observed.
- **Raw commit count**: Rewards splitting work artificially. No correlation with value.
- **Deployment frequency for solo developers**: When you control the entire pipeline, this metric primarily measures your CI/CD configuration, not your effectiveness.
- **Overall test coverage percentage**: Games trivially. Track delta on new code instead.
- **AI-authored code percentage**: DX data shows this doesn't vary much between daily and monthly AI users (24% vs 20%). Measures tool usage, not value.

---

## Recommended tracking format for progress.md

The format must be machine-parseable by `metrics.sh`, human-scannable in raw markdown, and lean enough to load in every Claude Code session without wasting context. Unicode sparklines provide maximum information density — eight data points in eight characters.

```markdown
## Metrics
<!-- FORMAT: metric|current|target|trend(last 6)|status -->
<!-- Parsed by scripts/pm/metrics.sh — do not alter format -->

| Metric | Current | Target | Trend | Status |
|:-------|:-------:|:------:|:-----:|:------:|
| Tasks completed | 8 | 8 | ▃▅▄▆▇█ | 🟢 |
| Cycle time (days) | 2.1 | ≤3.0 | ▇▆▅▄▃▂ | 🟢 |
| Change failure rate | 12% | ≤15% | ▂▃▂▄▅▃ | 🟡 |
| Test coverage Δ | +3% | ≥0% | ▄▅▃▆▅▇ | 🟢 |
| Code churn ratio | 0.08 | ≤0.12 | ▃▃▄▃▅▄ | 🟢 |
| AI effectiveness | 0.82 | ≥0.70 | ▅▅▆▆▇▇ | 🟢 |
| Dev satisfaction | 4 | ≥3 | ▅▄▅▅▄▅ | 🟢 |

**Sprint note:** CFR trending up — investigate if batch size increasing with AI.
```

Design rationale for this format:

**Sparkline trends encode six sprints of history in eight characters.** The Unicode block characters `▁▂▃▄▅▆▇█` map values to visual height. For metrics where lower is better (cycle time, CFR, churn), the sparkline should be inverted so that "going up visually" always means "improving." This is the single highest information-density representation available in plain text.

**RAG status (🟢🟡🔴) earns its place only with quantitative thresholds.** Research on the "watermelon effect" — projects green on the outside, red on the inside — shows RAG fails when humans pick the color subjectively. In this format, status is computed by `metrics.sh` from the current value vs. target: green if within target, yellow if within 120% of target, red if exceeding 120%. This eliminates subjectivity. For solo developers, there's no incentive to hide red from yourself, but automated computation still prevents optimism bias.

**The sprint note line is mandatory when any metric is yellow or red.** RAG without narrative context is the primary failure mode of traffic-light systems. One sentence explaining causality transforms a dashboard from a scorecard into a diagnostic tool.

**For teams**, add a row for each team member's satisfaction score and a team-level satisfaction average. Individual activity metrics should never appear — the SPACE framework, DORA team, and every serious researcher explicitly warns that individual-level activity tracking destroys trust.

---

## How to detect real changes vs noise in trends

The core challenge: sprint-to-sprint variation is high and most fluctuations are meaningless. A single bad sprint does not indicate a systemic problem. Research points to four practical approaches for distinguishing signal from noise without statistical infrastructure.

**The three-sprint rule.** A single-sprint deviation is noise. Two consecutive sprints in the same direction are a weak signal. **Three consecutive sprints trending in the same direction is a strong signal** requiring investigation. This maps to standard statistical process control: three points on the same side of the center line trigger an investigation in control chart methodology. For `progress.md`, this means the sparkline is the primary diagnostic — a monotonically increasing or decreasing trend across the last three data points should trigger the yellow status automatically.

**Relative, not absolute thresholds.** Research on code churn (Nagappan & Ball, 2005) found that relative measures predict defects at 89% accuracy while absolute measures fail. Apply this principle to all metrics: a change failure rate of 15% means nothing in isolation; a change failure rate that doubled from the previous three-sprint average is a strong signal. `metrics.sh` should compute both the current value and the percentage change from the rolling three-sprint average.

**Leading-lagging pairing.** Track leading indicators (complexity trends, coverage changes, churn rate, satisfaction) alongside lagging indicators (defect density, change failure rate, MTTR). When a leading indicator deteriorates but lagging indicators haven't moved yet, you have an early warning window. When leading indicators improve but lagging indicators remain poor, you have a delayed-effect scenario — maintain patience.

**The forensic hotspot approach.** When metrics indicate degradation, don't investigate everything. Adam Tornhill's method identifies hotspots: files that change frequently AND have high complexity. These are the highest-risk areas and the most likely source of quality problems. `metrics.sh` can identify the top 5 most-churned files each sprint from git log data, creating a targeted investigation list rather than a general alarm.

---

## Anti-pattern warnings: what will undermine your metrics

**Goodhart's Law is the primary threat.** "When a measure becomes a target, it ceases to be a good measure." In software engineering, this manifests as velocity inflation (teams assign higher story points to look productive), test coverage gaming (assertion-free tests that execute code without verifying behavior), deployment frequency gaming (shipping unstable changes to hit a number), and bug count manipulation (reclassifying or closing issues to reduce visible defects). The strong version of Goodhart's Law, articulated by Hillel Wayne, is that even 100% honest pursuit of a metric taken far enough is harmful — an inescapable consequence of the gap between metrics and actual goals.

**AI makes LOC-based metrics actively dangerous.** GitClear's analysis across 211 million changed lines found a Pearson correlation of 0.98 between Copilot prevalence and "mistake code." Google claims 25% of their code is AI-generated, Microsoft 30%, Anthropic's CEO predicts 90% — but these LOC-based headlines are "one-dimensional" and tell you nothing about value. Any metric that rewards code volume (LOC, commit count, PR count) will be inflated by AI without corresponding value increase.

**The measurement theater trap is especially acute for solo developers.** When you're the only person looking at your metrics, the overhead of tracking must be near zero. If updating metrics takes more than 2 minutes at sprint end, you'll stop doing it within a month. The `/sprint-end` command should auto-compute everything possible from git history and the activity log, leaving only the satisfaction score for manual input.

**The streetlight effect — measuring what's easy rather than what matters — gets worse with AI tooling.** AI tools generate abundant telemetry (acceptance rates, completion counts, token usage) that is trivially measurable but largely irrelevant to outcomes. Meanwhile, the metrics that actually matter (code comprehension difficulty, architectural coherence, whether the feature solved the user's problem) require judgment and are hard to automate. Resist the pull of available data.

**The BNY Mellon study identified two anti-patterns missing from traditional frameworks: technical expertise erosion and ownership dilution.** Features with >60% AI assistance take **3.4x longer to modify later**, suggesting that heavy AI reliance can create code the developer doesn't fully understand. Track whether you can explain and modify your AI-assisted code without re-prompting — if not, the AI is generating technical debt you can't see in any metric.

Five specific patterns to watch for and avoid:

- **Accepting AI suggestions to maintain flow state, then never reviewing them** — creates invisible quality debt that only surfaces in production failures weeks later
- **Optimizing acceptance rate or AI-authored-code percentage** — these are adoption metrics, not value metrics; high acceptance with high churn means the AI is creating rework
- **Comparing velocity across sprints without accounting for scope changes** — AI makes it easy to complete more tasks while the tasks themselves get smaller or less valuable
- **Tracking test coverage percentage while tests lack assertions** — Mark Seemann demonstrated that a meaningless try/catch test achieves 100% coverage while testing nothing
- **Ignoring the satisfaction metric because "it's subjective"** — the METR study proved that perceived and actual productivity diverge by nearly 40 percentage points; satisfaction is not performance, but its divergence from performance is itself a critical signal

---

## Knowledge gaps and open questions

Several important areas lack sufficient research as of early 2026.

**Long-term maintainability of AI-generated codebases has no longitudinal data.** The oldest codebases with significant AI-generated code are roughly 3 years old. We don't know how these codebases age. GitClear's churn data and the 30–41% technical debt increase are early signals, but multi-year maintenance cost data doesn't exist yet.

**Context management effectiveness has no standardized metric.** The METR study found context overhead is a major cost of AI assistance, and Claude Code best practices emphasize starting fresh conversations when switching tasks. But no framework defines how to measure whether context management is working well. Context reset frequency is a reasonable proxy but unvalidated.

**The AI productivity paradox remains unresolved.** Individual gains consistently fail to translate into organizational improvements. Faros AI found the correlation "evaporates at the company level." Whether this is a measurement problem, an organizational bottleneck problem, or an inherent limitation of AI-assisted development is unknown.

**Solo developer metrics are underresearched.** Virtually all metrics research targets teams of 5–50+. The adaptations needed for solo developers are based on practitioner reasoning, not empirical validation. Whether DORA metrics provide useful self-improvement signals for individuals (as opposed to teams) has not been studied.

**The deskilling hypothesis lacks rigorous evidence.** The BNY Mellon study raised concerns about technical expertise erosion and reduced code ownership with heavy AI use. Stack Overflow's 2025 survey found only 16.3% of developers report significant AI productivity gains. But no controlled study has measured whether AI-assisted developers lose technical skills over time, or whether their ability to work without AI degrades.

**Edit-to-bash ratio, TDD compliance rate, and skill success/failure rates are framework-specific metrics with zero external validation.** They map to sound concepts (development discipline, tool effectiveness, testing practices) but their predictive value for code quality or developer productivity is unknown. Tracking them is reasonable as experimental metrics, but they should not be treated as validated signals until correlation with outcomes is established within the framework's own data.