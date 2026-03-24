# Architecture Decision Records for AI-native development

**ADRs work best when they are short, stored next to code, and explicitly document rejected alternatives — the single highest-value content for both human onboarding and AI compliance.** The optimal template for AI-assisted workflows combines MADR v4's structured options analysis with YAML frontmatter metadata, a dedicated "Rejected Alternatives" section with machine-parseable markers, and explicit links to ground rules. Research across Spotify, AWS, IBM, ThoughtWorks, and the UK Government converges on a clear finding: **one-to-two-page records stored in the repository at `docs/adr/` with PR-based review achieve the highest adoption and longest survival rates.** For the JD-LLM framework specifically, the critical design choice is bridging ADRs to AI instruction files (CLAUDE.md) so that `/architecture-check` can generate them and `/story-cycle` can discover them without human intervention.

---

## How ADRs evolved from napkin notes to AI-enforceable constraints

Michael Nygard published the original ADR format in November 2011 with five sections: Title, Status, Context, Decision, and Consequences. His core insight remains foundational: without documented rationale, developers face only two choices — "blindly accept the decision" or "blindly change it." He specified records should be **one to two pages**, stored in the repository at `doc/arch/adr-NNN.md`, numbered sequentially and never reused, and "written as if it is a conversation with a future developer."

Three major evolutionary branches followed. **Y-statements**, introduced by Olaf Zimmermann at SATURN 2012, compress an entire decision into a single structured sentence: *"In the context of [use case], facing [concern], we decided for [option] and against [other options], to achieve [quality], accepting [downside]."* Early adopters found these sentences grew unwieldy, which drove the creation of **MADR (Markdown Any Decision Records)**, now at v4.0.0 (September 2024). MADR decomposes the Y-statement into discrete Markdown sections: YAML frontmatter (status, date, decision-makers, consulted, informed), Context and Problem Statement, Decision Drivers, Considered Options, Decision Outcome with consequences, and per-option Pros and Cons. MADR offers four template variants — full annotated, minimal annotated, bare, and bare-minimal — supporting progressive disclosure from quick capture to thorough analysis.

The tooling ecosystem mirrors this evolution. **adr-tools** (Nat Pryce, ~5.3k GitHub stars) provides Bash CLI commands for creating, superseding, and linking Nygard-style ADRs. **Log4brains** adds static site generation with search and hot-reload preview, built on Next.js using MADR templates. The newest entrant, **adrs** (Rust), supports both Nygard and MADR 4.0.0 templates plus an **MCP server with 15 tools** that AI coding assistants can call programmatically — the first tool purpose-built for AI-ADR integration.

Enterprise adoption patterns are remarkably consistent. **Spotify** uses RFCs for discussion and ADRs to capture outcomes; their Creator Team reported that knowledge loss during team ownership changes "has become less severe with the introduction of ADRs," and cross-office alignment improved when New York engineers' React Hooks ADR was adopted by Stockholm teams. **AWS** published prescriptive guidance based on 200+ ADRs across projects, recommending silent-reading review meetings of 30-45 minutes. **ThoughtWorks** moved Lightweight ADRs to the "Adopt" ring on their Technology Radar, stating "for most projects, we see no reason why you wouldn't want to use this technique." The **UK Government Digital Service** uses PR-based ADR review where merge-to-main equals acceptance. **IBM Watson's** WIRE team produced 80+ ADRs and found a strong correlation: services with few ADRs had significantly more technical debt.

The spectrum from lightweight to heavyweight follows a clear taxonomy: Y-statements (1-3 sentences) → Nygard ADRs (1-2 pages) → MADR (1-5 pages) → RFCs/Design Docs (3-10+ pages) → Architecture Review Board documents (10+ pages). The key distinction: **an ADR records a decision already made, while an RFC proposes a change and solicits feedback.** Most mature organizations use both — RFCs for discussion, ADRs for the outcome.

---

## Why rejected alternatives are the most valuable content

Research consistently identifies one finding above all others: **developers care most about "why" a decision was made, and the single most valuable element is understanding why alternatives were rejected.** AWS Prescriptive Guidance states that ADRs focus "on the reason for the decision rather than how the team implemented it," which "prevents other architects who weren't involved in the decision-making process to overrule that decision in the future."

ADRs function as **"case law" for architecture** — each record establishes precedent that future decisions should respect. During code reviews, reviewers reference ADRs when finding violations, sharing a link to the relevant record rather than re-arguing the point. During design discussions, when someone proposes revisiting a settled question, the team points to the existing ADR with full context, alternatives explored, and rationale. Spotify's engineering team framed undocumented decisions memorably: "If a tree falls in a forest and no one is around to hear it, does it make a sound? Similarly, if a decision was made but it was never recorded, can it be a standard?"

The academic concept of **"architectural knowledge vaporization"** (Van Heesch & Avgeriou, University of Groningen) explains why context preservation matters. Three types of knowledge vaporize: context knowledge (the problem space), reasoning knowledge (rationale and trade-offs), and design knowledge (the outcome). Traditional documentation captures only outcomes. ADRs specifically target context and reasoning — the knowledge most frequently lost and most expensive to recover. Studies show that recovering undocumented decisions after the fact is extremely costly, often impossible when original architects are unavailable.

The best ADRs include **revisit criteria** — explicit conditions under which a decision should be reconsidered. Microsoft Azure's Well-Architected Framework recommends recording **confidence levels**: "Sometimes an architecturally significant decision is made with relatively low confidence. Documenting that low confidence status could prove useful for future reconsideration decisions." This transforms ADRs from rigid mandates into living documents that acknowledge uncertainty.

---

## Ten anti-patterns that kill ADR programs

Empirical evidence from IBM, Spotify, and academic studies reveals consistent failure modes. The most damaging anti-patterns, ranked by severity:

1. **Rubber-stamping** — decisions documented without genuine alternatives considered. IBM's Keeling and Runde found that "some people started recording an idea as an ADR without talking to anyone about it," leading to churn during reviews. Their remedy: explore at a whiteboard first, record only after a decision is actually made.

2. **Post-hoc rationalization** — ADRs written months after implementation. Context degrades rapidly; what gets written is a justification, not a record. Microsoft Azure pragmatically notes that retroactive ADRs are acceptable for brownfield projects if the team acknowledges lost context.

3. **Missing "why not"** — ADRs that document the chosen option without explaining why alternatives were rejected. This is the single biggest content gap and the primary reason AI assistants re-propose rejected approaches.

4. **Orphaned from code** — ADRs stored in Confluence or wikis, disconnected from the codebase. The ECSA 2024 research study confirmed that "the decision on where documentation is stored has a massive influence on its perceived usefulness." ADRs in external wikis are invisible to both developers and AI tools.

5. **Signal drowning** — too many ADRs covering trivial decisions. InfoQ warns that "when it becomes bloated with every decision a team makes, it becomes the antithesis because the architectural decisions can't be easily seen." A GitHub mining study found **~50% of repositories with ADRs contain only 1-5 records**, suggesting many teams try ADRs but abandon them, possibly from this exact noise problem.

6. **Decisions in Slack** — architectural decisions made in meetings or chat but never formalized. Spotify addresses this by treating ADRs as the *output* of RFC processes or engineering meetings.

7. **Mega-ADRs** — Zimmermann identifies records where "a lot of detailed information about the architecture is stuffed into several multi-page ADRs serving as documentation master (or monster?)." The remedy: one decision per ADR. Microsoft says "avoid making decision records design guides."

8. **Blame shields** — using ADRs as insurance against accountability, where the goal is maximizing approvers rather than capturing rationale. InfoQ warns this is a sign of toxic management culture.

9. **Too few ADRs** — IBM's WIRE team found that "our most problematic service had only two ADRs. Other services that were the same age and experienced far fewer issues had nearly a dozen decisions logged."

10. **Topic drift** — Zimmermann's "Frog-to-Cucumber" pattern, where ADRs discuss positive attributes of an option that have nothing to do with the actual problem and stakeholder concerns.

---

## Governance that balances friction with rigor

The consensus across AWS, Spotify, ThoughtWorks, 18F, and the UK Government is unambiguous: **any team member can author an ADR.** Quality control comes through the review process, not authorship gates. AWS specifies that the creator becomes the "ADR owner" responsible for shepherding the record through review. Senior architects mentor ADR quality rather than monopolize authorship.

**PR-based review is the dominant pattern** for teams storing ADRs alongside code. The UK Government Digital Service approach is elegant: "There is no need to record a 'status' for an ADR when it is first proposed. The status of your ADR's pull request reflects the status of the decision until it has been accepted." A merged PR equals an accepted ADR. For high-impact decisions, AWS recommends **readout meetings**: 10-15 minutes of silent reading with inline comments, followed by discussion, with cross-functional participants kept below 10 people. Most decisions should require **one to three readout meetings**; more suggests the scope is too large.

The status lifecycle should be minimal. The practical consensus is **four statuses**: Proposed → Accepted → Deprecated → Superseded, with an optional Rejected status for negative decisions. Accepted ADRs are treated as immutable — changes require creating a new ADR that supersedes the old one. The old record is preserved with only its status updated to "Superseded by ADR-XXX." Numbers are sequential and never reused.

**When to write an ADR** is the question teams struggle with most. The research converges on five threshold criteria: the decision is **costly to reverse** (technology choices, data models); it **affects multiple teams** or crosses service boundaries; it **impacts non-functional requirements** (security, scalability); it **changes the system's structure** (new patterns, decomposition); or it **will be questioned in 6-12 months** by future team members. A practical heuristic from Spotify: "If a decision was made but never recorded, can it be a standard?" Three scenarios reliably warrant ADRs — backfilling undocumented standards discovered during peer review, proposing large changes (breaking changes, major refactors, new technology), and any decision of significant impact as defined by the team.

**Promoting ADRs to permanent rules** follows a clear pathway. When an ADR decision has been validated in practice and is unlikely to change, it can be encoded as an **architecture fitness function** — an automated test (ArchUnit, NetArchTest, ArchUnitTS) that runs on every commit and fails the build on violation. The ADR is preserved as rationale while the fitness function becomes the living enforcement mechanism. For AI-assisted development, this promotion means moving the constraint from `docs/adr/` into CLAUDE.md or ground rules files, linking back to the original ADR for context.

---

## The AI integration architecture that prevents re-litigation

For the JD-LLM framework, ADR integration must solve three problems: AI must **discover** relevant ADRs during `/story-cycle` planning, `/architecture-check` must **generate** ADR proposals when drift is detected, and the system must **prevent** AI from re-proposing rejected alternatives.

**Discovery** requires ADRs in the repository with consistent structure. The `@imports` pattern in CLAUDE.md is the most direct mechanism:

```markdown
# CLAUDE.md
See @docs/adr/ for all architecture decisions. Before proposing any
implementation approach, search ADRs for relevant prior decisions.
```

Claude Code reads imports recursively up to 5 levels deep, making a lean CLAUDE.md that points to detailed ADRs highly effective. YAML frontmatter with `tags`, `status`, and `scope` fields enables semantic filtering — an AI searching for database-related decisions can scan frontmatter rather than reading every record.

**Generation** by `/architecture-check` is feasible with guardrails. Research from an arXiv study (March 2024) found that **GPT-4 excels at 0-shot ADR generation but falls short of human-level comprehensiveness**, with common flaws including hallucinated references and fabricated product features. The practical approach: AI generates a complete draft from detected drift (code patterns, dependency changes, configuration shifts), filling in context, listing candidate options with pros/cons, and flagging the record as `status: proposed` for human review. The Equal Experts team used an "LLM-as-judge" pattern where a separate prompt critiques generated ADRs for logical flaws before human review.

**Preventing re-proposal of rejected alternatives** is the most critical AI-specific requirement. Four complementary patterns work together:

- **Explicit "DO NOT" sections in ground rules** linked to ADRs: `DO NOT use GraphQL — we use REST exclusively (see ADR-003)`
- **Rejected alternatives with machine-parseable markers** in every ADR: a `## Rejected Alternatives` section with `❌` markers, rejection rationale, and conditions for reconsideration
- **YAML frontmatter with rejected-options field**: `rejected-options: [mongodb, dynamodb, graphql]` enables pattern matching without full-text parsing
- **ADR-as-enforcement via AI code review**: Shing Lyu demonstrated (March 2026) configuring GitHub Copilot Code Review to cross-reference every PR against ADRs in `docs/adr/`, creating a system where "the documented architecture becomes a constraint that even the project owner can't casually override"

The **graduation pathway from ADR to ground rule** is essential for the JD-LLM framework. When a decision is validated and permanent, it moves into CLAUDE.md as a ground rule with a back-reference: "Use the repository pattern for database access (rationale: ADR-007)." The ADR remains as the full record; the ground rule becomes the enforceable constraint that AI encounters first.

---

## Recommended ADR template for the JD-LLM framework

This template balances low friction (completable in 10 minutes), AI parseability (structured YAML frontmatter, consistent headers), and decision quality (mandatory rejected alternatives). It draws from MADR v4's structure, Nygard's brevity principle, and AI-specific requirements unique to the framework.

```markdown
---
# ADR Metadata (machine-parseable)
status: proposed  # proposed | accepted | rejected | deprecated | superseded
date: YYYY-MM-DD
decision-makers: []
tags: []  # e.g., [database, api, security, infrastructure]
rejected-options: []  # e.g., [mongodb, graphql] — for AI filtering
supersedes: null  # ADR-NNN if applicable
superseded-by: null
linked-ground-rules: []  # e.g., [GR-003] if this became a ground rule
confidence: high  # high | medium | low — flags decisions for future review
---

# ADR-NNN: {Decision title as imperative phrase}

## Context

{What situation are we in? What forces are at play — technical, business,
team, timeline? Write as value-neutral facts. 2-4 sentences.}

## Decision

**We will {decision in active voice}.**

{1-2 sentences expanding on the decision if needed.}

## Alternatives considered

### ✅ {Chosen option} (Selected)
- **Why chosen:** {core rationale, 1-2 sentences}

### ❌ {Rejected option 1}
- **Why rejected:** {specific reason, 1-2 sentences}
- **Reconsider when:** {conditions that would reopen this}

### ❌ {Rejected option 2}
- **Why rejected:** {specific reason, 1-2 sentences}
- **Reconsider when:** {conditions that would reopen this}

## Consequences

- **Positive:** {what gets better}
- **Negative:** {what gets worse or becomes harder}
- **Operational:** {what the team must now do differently}

## Compliance

{How will we verify this decision is followed? Reference fitness functions,
code review checks, or architectural tests. Optional for low-impact decisions.}
```

**Justification for each field:**

The **YAML frontmatter** serves dual duty — human scanning and AI filtering. The `rejected-options` array is the critical AI-specific addition: when `/story-cycle` runs, it can grep frontmatter for options that were already evaluated and rejected across all ADRs, without parsing prose. The `confidence` field flags low-confidence decisions for periodic review. The `linked-ground-rules` field creates bidirectional traceability between ADRs and the ground rules they generated.

The **"Alternatives considered" section with ✅/❌ markers** is mandatory, not optional. This is the single most important structural choice. It directly addresses the top anti-pattern (rubber-stamping), provides the highest-value content for future developers, and gives AI clear signal about what not to propose. The **"Reconsider when"** sub-field beneath each rejected option is novel — it acknowledges that rejections are contextual and tells both humans and AI under what changed circumstances the alternative should be re-evaluated.

The **Compliance section** bridges ADRs to enforcement. For the JD-LLM framework, this is where teams note whether a decision should become a fitness function, a ground rule, or a code review check. This field is what `/architecture-check` reads to determine how violations should be detected.

The template deliberately omits MADR's "Decision Drivers" (folded into Context), "More Information" (use links inline), and the detailed per-option pros/cons matrix (overkill for most decisions — the chosen/rejected structure captures enough). For complex decisions requiring deeper analysis, teams add a comparison table inside the Alternatives section.

---

## Recommended governance process

**Who writes:** Any developer who makes or discovers an architecturally significant decision. `/architecture-check` can auto-generate a `status: proposed` draft when it detects drift. The developer or AI that introduces a change is responsible for creating the ADR.

**When to write:** Apply the **reversibility test** — if the decision would be costly to reverse, affects multiple components, changes system structure, or will be questioned in six months, write an ADR. For the JD-LLM framework: `/architecture-check` should trigger an ADR proposal when it detects a new dependency, a pattern change in more than three files, or a deviation from an existing ADR.

**Review process:** PR-based. The ADR is committed as `status: proposed` in the same PR as the code change (or in a dedicated ADR PR for pre-implementation decisions). One approving review from a team member not involved in the decision is required. For cross-team decisions, request review from affected teams. Merge equals acceptance; update status to `accepted` on merge.

**Status lifecycle:** Proposed → Accepted (on PR merge) → Deprecated (when no longer relevant) or Superseded (when replaced by a new ADR). Never delete ADRs. When superseding, update only the old ADR's `superseded-by` field and status.

**Ground rule graduation:** When an accepted ADR has been stable for two or more sprints and the team wants it enforced automatically, promote it: add the constraint to CLAUDE.md ground rules, update the ADR's `linked-ground-rules` field, and optionally create a fitness function for CI enforcement.

**Periodic review:** Review low-confidence ADRs quarterly. Review all ADRs annually during architecture health checks. Any team member can propose superseding an ADR by opening a new ADR PR.

---

## Recommended AI integration for the JD-LLM framework

The integration architecture has three layers operating at different points in the development cycle:

**Layer 1 — Discovery during `/story-cycle` planning.** Before proposing an implementation approach, the AI reads `docs/adr/` and filters by tags relevant to the current story. CLAUDE.md should contain: `Before proposing implementation approaches, check docs/adr/ for relevant decisions. Respect all accepted ADRs. Do not propose approaches listed in rejected-options frontmatter of any ADR.` The AI should specifically scan for: accepted decisions constraining the relevant domain, rejected alternatives matching its candidate approaches, and ground rules derived from ADRs.

**Layer 2 — Generation during `/architecture-check`.** When architectural drift is detected (new dependency introduced, pattern deviation across multiple files, deviation from an accepted ADR), the command generates a draft ADR using the template with `status: proposed`. The AI fills in context from the code change, lists the detected drift as the implicit "decision," identifies the prior ADR being deviated from, and flags the record for human review. The human completes the alternatives analysis and either accepts the drift (new ADR supersedes old) or reverts the code.

**Layer 3 — Enforcement during code review.** Configure AI code review (Copilot, or Claude-based review) to cross-reference PRs against accepted ADRs. When a PR introduces code that contradicts an accepted ADR, the reviewer flags the violation with a link to the specific ADR and suggests either modifying the code or creating a superseding ADR through proper process.

**The ground rules bridge** is the critical connector. CLAUDE.md acts as a "hot cache" of the most important ADR-derived constraints, while `docs/adr/` serves as the complete decision history. The pattern:

```markdown
# CLAUDE.md — Architecture Rules
# These rules are derived from ADRs. See the linked ADR for full rationale.

- Use PostgreSQL exclusively as the database (ADR-007)
- All API endpoints use REST, not GraphQL (ADR-003)
- Authentication uses Auth0; do not implement custom auth (ADR-015)

# Before proposing any architectural change, check docs/adr/ for prior decisions.
```

This two-tier architecture ensures AI encounters the most critical constraints immediately (ground rules in CLAUDE.md) while having access to full decision history (ADR directory) for deeper planning.

---

## Tool comparison for the JD-LLM framework

| Tool | Best for | Template | AI integration | Limitations |
|------|----------|----------|----------------|-------------|
| **adr-tools** (Bash) | Simple projects, Unix environments | Nygard | None | Not maintained; Unix only; no MADR support |
| **Log4brains** (Node.js) | Team visibility, searchable knowledge base | MADR 2.1.2 | Indirect (static site) | Beta; no MADR 4.0; heavy dependencies |
| **adrs** (Rust) | AI-native workflows | Nygard + MADR 4.0.0 | **MCP server with 15 tools** | Newer, smaller community |
| **Backstage ADR Plugin** | Organization-wide discovery | MADR 2.x/3.x | Search collator | Requires Backstage infrastructure |
| **Decision Guardian** | PR enforcement | Any | GitHub Action surfaces ADRs on PRs | Limited to GitHub Actions |
| **Plain MADR templates** | Maximum flexibility | MADR 4.0.0 | Via CLAUDE.md @imports | No CLI tooling |

For the JD-LLM framework, the recommended approach is **plain MADR-derived templates** (the custom template above) stored in `docs/adr/`, managed through git and PR workflow, with CLAUDE.md @imports for AI discovery. If the team wants CLI tooling, the **adrs** Rust tool is the strongest option due to its MCP server enabling direct AI-tool integration. Add **Decision Guardian** or AI code review for PR-level enforcement.

---

## Knowledge gaps and open questions

Several areas lack strong evidence or established best practices. **Quantitative data on ADR effectiveness is sparse** — the Buchgeher et al. GitHub mining study (2023) is the only large-scale empirical study, and it measured adoption, not outcomes. IBM's WIRE team report correlating few ADRs with high technical debt is a single case study, not a controlled experiment. **No published research directly measures how AI assistants interact with ADRs** — the patterns described above are derived from practitioner experiments (Shing Lyu, Equal Experts, Adolfi.dev) rather than systematic studies.

The **optimal number of ADRs per project** remains undefined. The research suggests that teams with fewer than 5 ADRs are likely under-documenting, and projects accumulating hundreds may be documenting non-architectural decisions, but the "sweet spot" likely depends on project complexity and has not been empirically identified. **Cross-repository ADR discovery** — how AI assistants should find ADRs relevant to the current work when decisions live across multiple repositories — is an unsolved problem; Backstage's search collator is the most promising approach but requires significant infrastructure.

The **MCP protocol for ADR integration** is nascent. The adrs Rust tool's MCP server is the first implementation, and patterns for how AI agents should query, filter, and reason over ADR collections are still being established. The **interaction between ADRs and AI-generated code** at scale — whether AI assistants actually reduce re-litigation or merely shift it to the human review step — has not been studied. Finally, the **long-term maintenance burden** of ADR collections, particularly how to handle "ADR archaeology" in projects with years of accumulated records, is acknowledged as a challenge by practitioners but has no established solution beyond periodic review and supersession.