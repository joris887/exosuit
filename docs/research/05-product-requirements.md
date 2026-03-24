# PRD design for AI-assisted development

**The emerging paradigm of Spec-Driven Development (SDD) has fundamentally changed how product requirements should be written.** Research across GitHub's analysis of 2,500+ agent configuration files, Amazon Kiro's EARS notation, Addy Osmani's "Agent Experience" framework, and practices from Stripe, Linear, and Notion reveals a clear consensus: requirements optimized for AI coding agents need to be structured as executable specifications — precise enough to implement, modular enough for context-efficient loading, and bounded enough to prevent scope drift. The traditional 20-page PRD is dead. What works is a concise, dependency-ordered, boundary-explicit document that bridges vision to implementation through a **Specify → Plan → Tasks → Implement** pipeline. This report synthesizes findings from practitioner sources, academic research, and real-world AI tool workflows to propose a PRD template purpose-built for the JD-LLM Development Framework.

---

## 1. Modern PRD approaches have converged on problem-first brevity

Every high-performing product organization — from Amazon to Intercom to Linear — has independently converged on the same principle: **spend more time on the problem than feels comfortable before jumping to solutions.** The specific format matters less than this discipline.

**Amazon's Working Backwards (PR/FAQ)** starts with a hypothetical press release written in "Oprah-speak, not geek-speak," followed by external and internal FAQs. The writing process itself surfaces gaps in thinking. AWS, Kindle, and Prime Video all started this way. Strength: unmatched customer-centricity for new products. Weakness: weeks-to-months of upfront investment makes it too heavyweight for feature-level work.

**Marty Cagan's Opportunity Assessment** replaces heavyweight PRDs with 10 fundamental questions — the most important being: *What problem are you solving? For whom? How will you measure success?* Cagan advocates prototypes over documents and warns against "documenting details for engineers until you've figured out the right product." This approach works best for empowered product teams adding value to existing products.

**Teresa Torres' Opportunity Solution Trees** create a visual hierarchy: business outcome → customer opportunities → solutions → assumption tests. Requirements emerge from validated opportunities, not assumptions. The tree forces generation of **at least 3 solutions per opportunity** to enable compare-and-contrast decisions rather than binary "whether or not" thinking.

**Shape Up's Pitch format** introduces the critical concept of **appetite** — not "how long will this take?" but "how much time are we willing to spend?" The pitch has five components: Problem, Appetite, Solution (at the right level of abstraction), Rabbit Holes (known risks), and **No-Gos** (explicit exclusions). The circuit breaker principle — if it's not done by end of cycle, it's killed by default — prevents zombie projects.

**Lenny Rachitsky's 1-Pager** is widely considered the gold standard for lightweight specs: Problem → Success Criteria → Context → Solution Direction → Timeline. **Intercom's "Intermission" enforces a one-page constraint** — Paul Adams (VP Product) notes that "the longer the doc, the less it gets read." Notably, Intercom's format uses Job Stories ("When \_\_, I want to \_\_, so I can \_\_") and excludes solutions entirely — those emerge from collaborative design.

**Stripe's approach** stands out for documenting tradeoffs: design documents outline all options considered and why each was rejected. Their "Gavel Blocks" system lists impacted stakeholders at the top of documents with checkboxes. **Linear invests in detailed project specs before building**, with design and engineering collaborating from the spec-writing stage, not after handoff. Both companies treat requirements as collaborative artifacts, not sequential deliverables.

The cross-cutting lesson for the JD-LLM Framework: a PRD should be **1-5 pages**, problem-first, with explicit non-goals, measurable success criteria, and just enough solution direction to enable AI decomposition — not pixel-perfect specifications.

---

## 2. Writing requirements that AI agents can actually implement

The field has rapidly converged on **Spec-Driven Development** as the primary methodology for AI-consumable requirements. GitHub's open-source Spec Kit (71k+ stars), Amazon's Kiro IDE, and JetBrains' Junie all implement variations of the same four-phase pipeline: **Specify → Plan → Tasks → Implement**.

### The "Goldilocks zone" of specificity

Research reveals a clear spectrum. Too vague ("make the app faster") produces unfocused results and scope creep. Too specific ("put a search box at position (120, 45) with #3366FF border") over-constrains the AI and prevents better solutions. The optimal zone specifies **what and why with measurable criteria, while leaving how to the agent**. Chris Force, who built a 40K-line SaaS app with AI agents, found that **3-5x more detailed specifications initially saves time through reduced rework** — his agent executed 9 out of 10 tasks correctly with comprehensive documentation, but mistakes "started piling up" when documentation slipped.

Addy Osmani introduces **"Agent Experience" (AX)** — designing specs for AI consumption the way we design APIs for developer experience. Key principles: clean Markdown with clear sections, explicit type definitions, code snippets over prose descriptions, and a blend of PRD-style "why" with technical "how." GitHub's analysis of 2,500+ agent configuration files found that the most effective specs cover six areas: **Commands, Testing, Project Structure, Code Style, Git Workflow, and Boundaries.**

### JTBD vs user stories: use both

Job stories ("When [situation], I want [motivation], so I can [outcome]") provide superior context for architectural decisions — they capture the *why* that prevents AI from optimizing for the wrong thing. User stories ("As a [role], I want [action], so that [benefit]") translate more directly to implementable, testable acceptance criteria. The practitioner consensus is clear: **use job stories for discovery and context, convert to user stories for implementation, then express acceptance criteria in EARS notation** ("WHEN [condition] THE SYSTEM SHALL [behavior]") for maximum AI parseability.

### The three-tier boundary system is non-negotiable

AI agents are particularly susceptible to scope creep because they try to be helpful by adding related features, interpret ambiguity by expanding scope, and lack human judgment about what's out of bounds. The most effective boundary specification uses a tiered system:

- **✅ Always**: Run tests before commits, follow naming conventions, use structured logging
- **⚠️ Ask first**: Database schema changes, adding dependencies, modifying public APIs  
- **🚫 Never**: Commit secrets, edit vendor directories, modify production configs, bypass auth

"Never commit secrets" was the single most common helpful constraint found across GitHub's 2,500+ repository analysis. For the JD-LLM Framework, **non-goals and explicit boundaries are as important as the requirements themselves.**

### Context window optimization demands modularity

HumanLayer research shows frontier LLMs can follow approximately **150-200 instructions** with reasonable consistency — performance degrades linearly for large models, exponentially for smaller ones. This means: don't stuff everything into one file. The practical solution is **hierarchical, modular specification files** (requirements.md → design.md → tasks.md) where only relevant sections are loaded per task. Kiro recommends multiple specs per project — one for auth, one for product catalog, one for cart. Cursor's path-scoped rules automatically load context only when the agent works in specific directories.

---

## 3. Personas and user flows that actually influence implementation

### Functional personas over decorative ones

Research from NN/Group and practitioner anti-pattern analysis reveals that most personas fail because they emphasize demographics over behaviors. Age, gender, occupation, hobbies, and personality types are decorative noise that doesn't influence a single implementation decision. The **lean functional persona** format captures only what matters for development:

A functional persona needs just six fields: **Context** (1-2 sentences about environment and constraints), **Primary Goal** (what they're trying to accomplish), **Key Behaviors** (how they interact with similar products), **Pain Points** (specific friction this feature should address), **Decision-Relevant Constraints** (device, accessibility needs, technical proficiency), and **Success Looks Like** (observable outcome from their perspective). Three to five personas is the sweet spot — more than five and teams lose focus.

For AI coding agents specifically, personas serve a dual purpose: they inform implementation decisions (a screen-reader user persona triggers accessibility requirements) and they can activate domain-specific reasoning when the AI is prompted to "approach this as a [persona] would experience it."

### Text-based flows over diagrams for AI consumption

User flows add value when features have multiple decision branches, multi-step processes, different entry points, or significant state management. They're overhead for simple CRUD operations. For AI-assisted development, **text-based flow descriptions are far more useful than visual diagrams** because AI agents process text, not images. The recommended format structures flows as: Entry Points → Preconditions → Happy Path (numbered steps) → Alternate Paths → Error States → Edge Cases. Each step follows the pattern: `User → [Action] → System → [Response/Screen]`.

### Edge case documentation requires systematic categorization

Edge cases fall into three categories that should be documented separately: **input edge cases** (null values, boundary values, malformed data, Unicode), **system edge cases** (network loss mid-transaction, concurrent operations, third-party API failures, rate limiting), and **user behavior edge cases** (browser back button during multi-step process, duplicate submissions, rapid repeated clicks). Prioritize by risk: P1 for security/data corruption/financial impact, P2 for common error states, P3 for validation edge cases, P4 for cosmetic issues with unusual data.

---

## 4. Success metrics and acceptance criteria that convert to automated tests

### OKRs for launches, KPIs for health monitoring

At the feature level, **OKRs work best for new launches** (directional, aspirational — "Achieve 40% feature adoption within 30 days") while **KPIs serve ongoing health monitoring** (task completion rate ≥ 95%, error rate < 2%, average response time < 500ms). Every qualitative requirement must be converted to a measurable target before development begins. "Easy to use" becomes "task completion rate ≥ 95% with SUS score ≥ 68." "Fast" becomes "page load < 3s at P95; API response < 500ms." "Accessible" becomes "WCAG 2.2 AA compliance; 0 critical a11y issues."

### The hybrid acceptance criteria format

Research across Kiro, Cucumber, and property-based testing literature converges on a **three-layer hybrid** as the optimal format for AI implementation:

**Layer 1 — Properties (invariants that must always hold):** These catch bugs that example-based tests miss and enable property-based testing across potentially infinite inputs. Example: "Account balance always equals sum(deposits) - sum(withdrawals)" or "No user can access another user's data."

**Layer 2 — Gherkin scenarios (key behavioral examples):** Given/When/Then format maps directly to automated BDD tests and is the most AI-parseable behavioral format. Over **60% of agile teams** use BDD according to the 2024 World Quality Report.

**Layer 3 — EARS notation for precise system behaviors:** "WHEN [trigger] THE SYSTEM SHALL [behavior]" — pioneered by Rolls-Royce and adopted by Amazon Kiro as their primary acceptance criteria format. Each EARS criterion is independently testable, focuses on behavior over implementation, and covers both happy path and error conditions.

Aim for **3-7 acceptance criteria per story**. If you exceed 10, split the story. Every criterion should answer: "How would I write an automated test for this?"

---

## 5. Structuring a PRD for iterative delivery and AI decomposition

### Per-feature documents replace monolithic PRDs

The dominant modern pattern is **per-feature or per-epic PRDs** rather than product-level documents. Delibr calls these "Feature Documents." This prevents documents from becoming unwieldy, aligns with incremental delivery, and — critically for AI agents — keeps each specification within context window limits. A full product vision lives in a separate strategic document; each feature PRD references it but stands alone.

### Dependency-ordered phases enable sequential AI implementation

Traditional PRDs organize by functional area. AI-optimized PRDs organize by **implementation dependency order**. David Haberlah articulates this clearly: "AI coding agents require specifications that function as programming interfaces — precise enough to execute, structured enough to sequence, constrained enough to prevent scope drift." A feature like "audio file management" restructures from a flat list into sequential phases: database schema → upload API → playback engine → visualization → playlist management → UI polish.

**Limit to three phases maximum.** As Google PM Carlin Yuen notes: "By the time your team actually gets to the third phase, things will have changed — you'll probably need a new doc anyway." Use MoSCoW prioritization within each phase: Must-have (P0), Should-have (P1), Could-have (P2), Won't-have (explicitly excluded).

### Story decomposition follows the SPIDR pattern

Requirements decompose into stories using five splitting patterns: **Spike** (research to reduce uncertainty), **Path** (alternate user paths), **Interface** (browser/device/UI complexity), **Data** (data variations), and **Rules** (business rules — happy path first, edge cases later). Each story must be a **vertical slice** through the architecture (UI + logic + data), not a horizontal layer. The PRD-to-backlog hierarchy maps cleanly:

```
PRD Vision/Goals    → Themes/Initiatives
Feature Groups      → Epics  
Individual Features → User Stories (vertical slices)
Acceptance Criteria → Test Cases
```

### Living documents with version control

Modern PRDs are collaborative, versioned, and linked bidirectionally to backlog items. Update the PRD after each sprint to reflect scope changes. Use an "Open Questions" section to acknowledge unknowns rather than pretending everything is decided. Mark assumptions explicitly — they become the first things to validate during implementation.

---

## 6. Anti-patterns that derail AI implementation

### The six most damaging requirement smells

Academic research from Femmer et al. (2017) and industry practice converge on these as the highest-impact problems:

**Premature solutioning** is the most frequently cited anti-pattern. "User can see a welcome modal dialog with a blue Continue button" is a design solution masquerading as a requirement. The requirement is: "First-time users must understand the product's core value and begin using it within 60 seconds." An empirical study (arXiv 2507.20439) found that **LLMs cannot reliably detect problems in task descriptions** — unlike humans, they don't natively react to low-quality requirements. This means the burden of requirement quality falls entirely on the human author.

**Vague, unmeasurable language** — words like "fast," "user-friendly," "intuitive," "robust," and "high availability" — creates requirements that cannot be tested or verified. Research at MBDA Italy confirmed that **ambiguity and verifiability are the most severe requirement smells.** Every vague term must be replaced with a specific, measurable threshold.

**Missing error handling** is where AI-generated code most commonly fails. As one practitioner notes: "Vibe coding quietly cuts corners in two places: edge cases and error handling." A requirement like "User can upload a file" is incomplete without specifying: accepted formats, size limits, validation error messages, upload progress indication, network failure recovery, and concurrent upload behavior.

**Missing non-functional requirements** are the most commonly overlooked PRD section. Performance, security, scalability, observability, accessibility, and compliance requirements must be explicit — AI agents cannot infer GDPR compliance or that you need structured logging. The NFR checklist should cover: response time targets, uptime SLAs, encryption requirements, WCAG compliance level, supported browsers/devices, monitoring and alerting needs, data retention policies, and disaster recovery targets.

**Implicit context** — assuming the AI knows your conventions, retains context from previous conversations, or understands your codebase structure — causes silent failures. Everything must be explicit: tech stack with exact versions, package manager commands with flags, file organization, naming conventions (via code snippets, not prose), and what files should never be touched.

**Monolithic specifications** overwhelm context windows and cause instruction-following degradation. The solution is modular specs where each task receives only its relevant context, not the entire document.

---

## 7. Recommended PRD template structure

Based on synthesized findings across all research areas, this template is optimized for the JD-LLM Framework's pipeline: `/bootstrap` Path B → PRD → `/ideate` → stories → implementation.

```markdown
# [Product/Feature Name] — PRD
<!-- Version: 1.0 | Last Updated: YYYY-MM-DD | Status: Draft/Review/Approved -->

## 1. Problem & opportunity
<!-- WHY this exists. 3-5 sentences max. -->
<!-- Format: Prose paragraph -->
<!-- Feeds into: Strategic alignment during /ideate planning -->

[What problem are we solving? Who experiences it? What evidence do we have 
(quantitative or qualitative) that this problem matters? What's the cost of 
not solving it?]

## 2. Target users
<!-- WHO we're building for. Lean functional personas. -->
<!-- Format: Structured persona blocks (2-3 max) -->
<!-- Feeds into: Story role definitions, accessibility requirements -->

### [Persona Name] — [Segment Label]
- **Context:** [Environment, tech proficiency, constraints]
- **Primary goal:** [What they need to accomplish]
- **Key behaviors:** [How they interact with similar products]  
- **Pain points:** [Specific friction this feature addresses]
- **Constraints:** [Device, accessibility, proficiency level]

## 3. Success criteria
<!-- HOW we know it worked. Measurable outcomes. -->
<!-- Format: Numbered list of measurable targets -->
<!-- Feeds into: Acceptance criteria derivation, test assertions -->

1. [Metric]: [Target] within [Timeframe]
2. [Metric]: [Target] within [Timeframe]
3. [Metric]: [Target] within [Timeframe]

## 4. User flows
<!-- WHAT the experience looks like. Text-based, not diagrams. -->
<!-- Format: Numbered step sequences with branching -->
<!-- Feeds into: Story decomposition, test scenarios -->

### Flow: [User Goal]
**Entry:** [How user arrives] | **Precondition:** [What must be true]

**Happy path:**
1. User → [action] → System → [response]
2. User → [action] → System → [response]
3. → [Success state]

**Alternate paths:**
- If [condition]: → [behavior] → [outcome]

**Error states:**
- [Error condition] → [System response] → [Recovery path]

## 5. Requirements
<!-- WHAT to build. Dependency-ordered, priority-tagged. -->
<!-- Format: Grouped by phase, each with EARS acceptance criteria -->
<!-- Feeds into: Direct story generation via /ideate -->

### Phase 1 — MVP [Must-have]
#### R1: [Requirement name]
[1-2 sentence description of the requirement and its purpose]

**Acceptance criteria:**
1. WHEN [trigger] THE SYSTEM SHALL [behavior]
2. WHEN [error condition] THE SYSTEM SHALL [error behavior]  
3. WHEN [edge case] THE SYSTEM SHALL [edge behavior]

#### R2: [Requirement name]
...

### Phase 2 — Enhancement [Should-have]
#### R3: [Requirement name]
...

## 6. Non-functional requirements
<!-- Quality attributes. Measurable thresholds. -->
<!-- Format: Category → specific measurable requirement -->
<!-- Feeds into: Definition of Done, infrastructure stories -->

- **Performance:** [e.g., API responses < 200ms at P95 under 500 req/s]
- **Security:** [e.g., All PII encrypted at rest (AES-256) and in transit (TLS 1.3)]
- **Accessibility:** [e.g., WCAG 2.2 AA; keyboard navigable; screen reader compatible]
- **Observability:** [e.g., Structured JSON logging; error alerting for P99 > 500ms]
- **Scalability:** [e.g., Handle 10x current load via horizontal scaling]
- **Compatibility:** [e.g., Last 2 versions of Chrome, Firefox, Safari; iOS 16+]

## 7. Scope boundaries
<!-- What this is NOT. Prevents AI scope creep. -->
<!-- Format: Explicit lists -->
<!-- Feeds into: Agent boundary configuration -->

**Non-goals (out of scope):**
- [Feature/capability explicitly excluded and why]
- [Feature/capability explicitly excluded and why]

**Boundaries for AI implementation:**
- ✅ Always: [Required behaviors — run tests, follow conventions]
- ⚠️ Ask first: [Decisions needing review — schema changes, new dependencies]
- 🚫 Never: [Forbidden actions — modify auth, commit secrets, delete data]

## 8. Technical context
<!-- Stack, constraints, and commands for AI agent setup. -->
<!-- Format: Structured data -->
<!-- Feeds into: CLAUDE.md generation, agent configuration -->

- **Stack:** [Language, framework, versions]
- **Build:** `[exact command]`
- **Test:** `[exact command]`  
- **Lint:** `[exact command]`
- **Key dependencies:** [External services, APIs, libraries with versions]
- **Project structure:** [Brief description of directory layout]

## 9. Open questions & assumptions
<!-- What we don't know yet. What we're assuming. -->
<!-- Format: Table -->
<!-- Feeds into: Spike stories, assumption validation tasks -->

| # | Question/Assumption | Impact | Owner | Status |
|---|-------------------|--------|-------|--------|
| 1 | [Open question]   | [High/Med/Low] | [Who] | Open |
| 2 | [Assumption]      | [High/Med/Low] | [Who] | Assumed |
```

### Why each section exists and its ordering rationale

**Sections 1-3 (Problem, Users, Success)** establish the strategic context that prevents AI from optimizing for the wrong thing. They're loaded first during `/ideate` to frame all subsequent decomposition decisions. Without understanding *why* we're building something, AI agents produce technically correct but contextually wrong implementations.

**Section 4 (User Flows)** provides the behavioral backbone for story decomposition. Text-based flows (not diagrams) are directly parseable by AI agents and naturally decompose into vertical story slices along the happy path, alternate paths, and error states.

**Section 5 (Requirements)** is the core specification. Dependency-ordering by phase means stories can be generated and implemented sequentially without circular dependencies. EARS acceptance criteria on each requirement translate directly to automated tests. Priority tags (MoSCoW) enable `/ideate` to generate appropriately-sized stories for each sprint.

**Section 6 (NFRs)** prevents the most common documentation gap. These generate dedicated infrastructure, security, and accessibility stories that would otherwise be missed entirely.

**Section 7 (Scope Boundaries)** is the second most important section for AI implementation. The three-tier boundary system (Always/Ask First/Never) directly maps to agent configuration. Non-goals prevent the most common AI failure mode: scope creep through "helpful" additions.

**Section 8 (Technical Context)** provides the machine-readable setup information that goes into CLAUDE.md or equivalent agent configuration. Exact commands with flags eliminate the most common agent failure: running incorrect build/test commands.

**Section 9 (Open Questions)** maintains intellectual honesty and generates spike stories during `/ideate`. Assumptions that prove wrong become the most expensive bugs — documenting them explicitly enables early validation.

---

## 8. Recommended requirements format for AI implementation

Individual requirements should follow this structure, which has been validated across GitHub Spec Kit, Amazon Kiro, and practitioner workflows:

```markdown
#### R[N]: [Descriptive requirement name]
[1-2 sentences: What capability + Why it matters (job story context)]

When [situation/context], [user persona] needs to [action/motivation], 
so they can [desired outcome].

**Acceptance criteria:**
1. WHEN [specific trigger] THE SYSTEM SHALL [observable behavior]
2. WHEN [error condition] THE SYSTEM SHALL [error handling behavior]
3. WHEN [edge case] THE SYSTEM SHALL [boundary behavior]

**Properties (invariants):**
- [Condition that must always hold true across all inputs]

**Edge cases:**
| Scenario | Expected behavior |
|----------|------------------|
| [Edge case 1] | [Specific response] |
| [Edge case 2] | [Specific response] |
```

**Key format principles:**

The job story context ("When [situation]...") provides the *why* that helps AI agents make correct judgment calls on ambiguous sub-decisions during implementation. **EARS notation** for acceptance criteria is the most machine-parseable format — each criterion is independently testable and maps 1:1 to an automated test case. Properties express invariants for property-based testing, catching bugs that example-based tests miss. Edge cases are tabulated for scanability and completeness.

**Specificity guidelines — be explicit about:** tech stack versions, performance benchmarks, data validation rules, error handling behavior, and security requirements. **Be outcome-oriented about:** UX flows, business logic intent, success criteria, and architecture patterns. The dividing line: if an AI agent could reasonably choose between two approaches and one would be wrong, you need to be explicit. If both approaches would satisfy the user, leave it flexible.

---

## 9. Integration with backlog decomposition and story generation

### The PRD → /ideate pipeline

The PRD structure above is designed so that `/ideate` can systematically decompose it into stories:

**Step 1 — Parse phases and requirements.** Each Phase in Section 5 becomes an Epic. Each numbered requirement (R1, R2...) becomes a candidate story or set of stories. The dependency ordering within phases means stories can be sequenced without additional analysis.

**Step 2 — Apply SPIDR splitting.** For requirements too large for a single story, apply five splitting patterns: Path (alternate user flows), Interface (device/platform variants), Data (data variations — basic fields first, advanced later), Rules (business rules — happy path first, edge cases later), and Spike (research tasks for open questions from Section 9).

**Step 3 — Generate acceptance criteria from EARS notation.** Each EARS criterion in the PRD maps directly to a story acceptance criterion. Properties become test assertions. Edge case tables become additional test scenarios. The `/ideate` agent can generate Given/When/Then test scenarios from EARS criteria by expanding: `WHEN [trigger] THE SYSTEM SHALL [behavior]` → `Given [precondition state], When [trigger occurs], Then [behavior is observed]`.

**Step 4 — Generate NFR stories.** Section 6 NFRs generate dedicated stories: "Set up structured JSON logging" (observability), "Implement WCAG 2.2 AA keyboard navigation" (accessibility), "Configure TLS 1.3 for all API endpoints" (security). These are often missed when NFRs aren't explicit.

**Step 5 — Derive Definition of Done.** The universal DoD combines Section 6 NFRs (performance, accessibility, security thresholds) with Section 7 boundaries (always run tests, follow conventions). Feature-specific acceptance criteria come from Section 5.

### Context loading strategy for Claude Code

During implementation, the agent should **not** load the entire PRD. Instead:

- **Planning mode**: Load Sections 1-3 (problem, users, success) + Section 5 (requirements for current phase) + Section 7 (boundaries)
- **Implementation mode**: Load only the current requirement's acceptance criteria + Section 8 (technical context) + Section 7 (boundaries)
- **Review mode**: Load Section 3 (success criteria) + the relevant requirement's acceptance criteria for verification

This selective loading keeps context focused within the **150-200 instruction practical limit** identified by HumanLayer research.

---

## 10. Knowledge gaps and areas for further investigation

**No empirical comparison of JTBD vs user stories for AI implementation quality.** The recommendation to use job stories for context and user stories for implementation is practitioner consensus, not empirically validated. A controlled study measuring AI implementation accuracy across requirement formats would be valuable.

**The 150-200 instruction limit needs more rigorous study.** HumanLayer's finding is the only quantitative data point on how many instructions AI agents can reliably follow. The optimal ratio of spec-to-code-to-instruction context allocation within a given context window remains unknown.

**Multi-file task accuracy remains a fundamental challenge.** Academic benchmarks show AI models achieve only **19.36% Pass@1 on multi-file tasks** versus 87.2% on single-function benchmarks — a 68% gap. Better specs help but don't fully solve this. The PRD template mitigates this through modular, single-responsibility requirements, but the underlying capability gap persists.

**Spec maintenance burden is unresolved.** Multiple sources note that specifications become stale during implementation. "Living specs" that auto-update based on code changes (as in Augment Code's Intent system) are nascent. For the JD-LLM Framework, a practical question remains: when and how should the PRD be updated as implementation reveals new information?

**EARS notation is proven in embedded systems but new to web/app development.** Kiro's adoption of EARS (originally from Rolls-Royce aerospace) for web applications is promising but pre-validation at scale. The notation may need adaptation for UI-heavy requirements where behavioral triggers are less discrete than in embedded systems.

**Property-based acceptance criteria adoption is still early.** While theoretically superior for catching edge cases across infinite input spaces, property-based testing requires a mental model shift that most product managers haven't made. The PRD template includes properties as an optional layer, but adoption may require training and tooling support.

**Optimal PRD length for different project types needs calibration.** The template above targets medium-complexity features. A CLI tool PRD may need more emphasis on command syntax and argument validation; a library PRD may need API contract specifications; a mobile app PRD may need offline behavior and platform-specific interaction patterns. The template's section weights should adapt to project type, but specific guidance for each type would benefit from additional research.