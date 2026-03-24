# Architectural ground rules: enforcing your project's DNA

**The most effective architectural governance combines three elements: a small set of testable, RFC 2119-graded principles (3–7 rules), deterministic automated enforcement via fitness functions, and natural-language rule files that AI assistants can interpret during code generation.** This approach works because it addresses the central paradox of architectural governance — rules must be specific enough to enforce yet flexible enough to survive evolution. Industry leaders like Netflix, Spotify, and Google have converged on a model where making the right path the easiest path outperforms mandated compliance, while Neal Ford's fitness function framework provides the theoretical backbone for automated verification. For the JD-LLM Development Framework, the optimal template structure uses TOGAF-inspired rule fields enhanced with machine-readable metadata, organized into 3–4 universal categories plus optional project-specific ones, all fitting under 100 lines.

---

## 1. Fitness functions turn principles into testable assertions

Neal Ford, Rebecca Parsons, and Patrick Kua define an architectural fitness function as "an objective integrity assessment of some architectural characteristic(s)" in *Building Evolutionary Architectures* (O'Reilly, 2017/2023). The key insight is that fitness functions make architectural evolution **guided rather than chaotic** — they protect characteristics from degradation as systems change.

Ford's taxonomy classifies fitness functions along five dimensions: **atomic vs. holistic** (single concern vs. combined), **triggered vs. continual** (event-based vs. always-running), **automated vs. manual**, **static vs. dynamic** (fixed threshold vs. sliding), and **intentional vs. emergent**. The practical implication for ground rules is that each rule should declare which type of fitness function enforces it.

**What can be automatically verified.** Structural properties dominate the automatable space. ArchUnit (Java) expresses layer dependency rules in a fluent DSL — `layeredArchitecture().layer("Controller").definedBy("..controller..").whereLayer("Controller").mayNotBeAccessedByAnyLayer()` — and runs as standard JUnit tests in any CI pipeline. dependency-cruiser (JS/TS) uses a JSON/JS configuration with `forbidden`, `allowed`, and `required` rule arrays matched by regex paths. NetArchTest (.NET) provides equivalent capabilities with a `Types.InAssembly().That().Should()` fluent API, while Deptrac (PHP) uses YAML-defined layers and rulesets. ArchUnitTS and ts-arch bring similar capabilities to TypeScript. All these tools verify dependency direction, circular dependencies, naming conventions, package containment, and annotation presence at build time.

**What requires human judgment.** Domain model quality, architectural style appropriateness, trade-off decisions, business alignment, and communication pattern selection all resist automation. As Ford notes, "readability" makes a poor fitness function because it lacks objectivity. The recommended approach from InfoQ's comprehensive analysis: "automated where possible, thoughtful where necessary — creating a high-fidelity feedback system." For the ground rules template, this means each rule should explicitly declare whether it is `auto-verified` or `review-verified`.

**Tool coverage by ecosystem:**

| Ecosystem | Tool | Key Capabilities |
|-----------|------|-----------------|
| Java/JVM | ArchUnit | Layers, cycles, naming, annotations, onion/hex architecture, PlantUML conformance, freeze rules |
| .NET | NetArchTest / ArchUnitNET | Layers, naming, dependency direction, policy grouping |
| JS/TS | dependency-cruiser | Forbidden/allowed/required dependencies, orphan detection, stability metrics, visualization |
| TypeScript | ts-arch / ArchUnitTS | File-based and slice-based rules, cycle detection, naming |
| PHP | Deptrac | YAML-defined layers and rulesets, hexagonal architecture |
| Python | PyTestArch | Architecture rules as pytest tests |
| C/C++/Rust | Axivion (commercial) | UML model conformance, AUTOSAR, safety certification |

Both ArchUnit and dependency-cruiser support **freeze/baseline** features — recording existing violations so only new violations fail the build. This is critical for adopting ground rules in brownfield projects and directly relevant to the JD-LLM Framework's progress.md compliance tracking.

---

## 2. How Google, Netflix, and Spotify govern architecture differently

Three distinct governance philosophies have emerged from the industry's most influential engineering organizations, each offering lessons for the ground rules template.

**Google enforces through mandatory review.** Every code change requires three approvals: a general LGTM, code owner approval, and a "readability" approval from someone certified in that language's best practices. Published style guides serve as "the absolute authority on style questions." Google's design document process requires approved design docs before major coding begins, with templates mandating consideration of security, privacy, storage, and internationalization implications. The median review turnaround is under 4 hours. This model demonstrates that **specificity works when combined with automation and culture** — but it requires significant organizational investment.

**Netflix governs through incentives with its "Paved Road."** The Paved Road is a set of recommended tools, practices, and standards that engineers are "encouraged to follow by default, while carefully considering trade-offs if they choose to deviate." Teams retain freedom to implement alternatives but assume responsibility for maintenance. Netflix found that "driving adoption of security paved road practices" reduces more risk than vulnerability remediation. The enforcement mechanism is primarily cultural: "For a tool to be widely accepted, it must be compelling, add tremendous value, and reduce the overall cognitive load." Their Conformity Monkey automates compliance checks. The lesson for ground rules: **rules that make the right path the easiest path achieve higher compliance than mandates**.

**Spotify uses Golden Paths with formal exception governance.** Spotify's Golden Path is "the opinionated and supported path to build something," evolved from a 2014 Hack Week project to address fragmentation from autonomous squads. Their governance includes a **Technology Advisory Group (TAG)** that approves exceptions to Golden Tech standards, and **Soundcheck** (a Backstage plugin) that provides component health scorecards showing compliance levels. Not meeting Golden Tech standards for production components requires filing exceptions. This hybrid model — soft defaults with formal exception tracking — maps directly to the JD-LLM Framework's needs.

**RFC 2119 provides the classification vocabulary.** The keywords MUST ("absolute requirement"), SHOULD ("valid reasons may exist to ignore, but implications must be understood"), and MAY ("truly optional") from RFC 2119 have been adopted well beyond IETF standards — by OASIS, W3C, Semantic Versioning, and the EU Digital Identity Framework. RFC 8174 (2017) clarified that only UPPERCASE usage carries normative meaning. The critical guidance from RFC 2119 Section 6: keywords "MUST only be used where it is actually required for interoperation or to limit behavior which has potential for causing harm." For ground rules, this means **MUST-level rules should be rare and automated**, SHOULD-level rules benefit from paved roads, and MAY-level options should be documented but not enforced. The satirical RFC 6919's "MUST (BUT WE KNOW YOU WON'T)" perfectly captures the gap between mandate and compliance when rules lack enforcement mechanisms.

---

## 3. Universal vs. project-specific rule categories

Analysis across TOGAF, Microsoft's .NET architectural guidance, Continuous Architecture, and multiple practitioner sources reveals a clear hierarchy of rule categories. Patrick Roos at workingsoftware.dev captures the key insight: **"Do not look for universal enterprise architecture principles and attempt to apply them. Another organization's principles do not support your strategy."** The categories are universal; the specific rules within them are not.

**Dependency direction is the single most universal category.** It appears in every framework and every architecture testing tool. Clean Architecture's dependency rule, TOGAF's "Technology Independence," hexagonal architecture's ports-and-adapters boundary — all encode the same principle: dependencies must flow inward toward the domain. This is also the most automatable category, with every tool (ArchUnit, dependency-cruiser, Deptrac, ts-arch) treating it as the primary use case.

**Four categories appear in nearly all sources** and should be considered essential for any ground rules template:

- **Dependency direction** — which layers/modules can depend on which. Universal, highly automatable.
- **Boundary enforcement** — separation of concerns, module boundaries, what constitutes a "component." Universal, partially automatable.
- **Data governance** — how data flows, where state lives, what owns which data. Universal in concept, project-specific in implementation. TOGAF devotes 3 of its example principles to data.
- **Security boundaries** — authentication/authorization patterns, secret handling, data classification. Universal requirement, implementation varies.

**Three categories are important but project-specific:**

- **Technology constraints** — locked technology choices, prohibited libraries, version requirements. Critical for AI enforcement but varies entirely by project.
- **API design standards** — contract formats, versioning strategy, error handling conventions. Important in microservices, less relevant for monoliths.
- **Operational requirements** — observability, deployment patterns, performance thresholds. Always project-specific in their targets.

Kyle Brown (IBM) provides the decisive test: **"Every architectural decision should be testable and should have a test written to accompany it. If a decision is not testable, then it is merely an opinion or a suggestion and not a decision."** This principle should govern which rules make it into the ground rules template.

---

## 4. Writing rules precise enough to enforce, flexible enough to evolve

The TOGAF principle format — **Name, Statement, Rationale, Implications** — is the most widely adopted documentation structure for architectural principles, appearing across multiple TOGAF versions and adopted by organizations worldwide. However, the ground rules template needs additional fields for AI enforcement and fitness function integration.

**Enforceable rules share four characteristics.** They have specific measurable thresholds (not "be scalable" but "P95 response time under 200ms"). They have automated checks that run in CI/CD. They produce binary pass/fail outcomes. And they have clear scope defining which code is covered. Aspirational rules fail because they require subjective interpretation — "all software should be written in a scalable manner" provides no decision guidance and cannot be tested.

**Exception handling requires formal process.** TOGAF treats exceptions as "dispensations" with structured approval: the requestor documents business justification, technical and business owners approve, and the governance body reviews based on impact, technical merit, alternatives, and precedent-setting effects. For the JD-LLM Framework, exceptions should be lightweight but tracked — documented in progress.md with justification, scope, and expiration.

**The ADR-to-principle pipeline matters.** Michael Nygard's ADR format (Title, Context, Decision, Status, Consequences) captures point-in-time decisions, while principles capture enduring rules. Andrew Harmel-Law's *Facilitating Software Architecture* (O'Reilly, 2024) describes the bidirectional relationship: principles guide ADR decisions, and ADR outcomes inform principle evolution. An ADR should be promoted to a ground rule when it addresses a recurring, cross-cutting concern with proven consequences. TOGAF advises principles should be "enduring and seldom amended" — but not immutable. They change when enterprise direction changes.

**Preventing rule accumulation is essential.** A March 2026 Risk Business analysis describes "control fatigue" — governance that "accumulates incrementally like sediment" until "employees navigate governance processes defensively rather than thoughtfully." TOGAF recommends **10–20 guiding principles** at the enterprise level and notes "the adaptability of your architecture will be improved if you have fewer principles." For project-level ground rules, the JD-LLM Framework's 3–7 range is well-calibrated. Strategies include regular review cadence, sunset clauses on rules, and the InfoQ warning: "when [ADRs] become bloated with every decision a team makes, the architectural decisions can't be easily seen amidst everything else."

---

## 5. AI-specific governance prevents architectural liquefaction

Vasiliy Shilov coined the term **"architectural liquefaction"** to describe "the progressive loss of structural boundaries under sustained probabilistic code generation." His key observation: "Before AI, architectural violations required effort. A developer had to consciously decide to break a boundary. Now, violations can be generated in seconds." Because AI-generated code often "looks right," structural erosion becomes harder to notice.

**AI assistants exhibit predictable violation patterns.** Research and practitioner reports identify five common failure modes: generating inconsistent patterns for similar problems, prioritizing local optimization over global architecture, creating tightly coupled components that bypass architectural layers, duplicating logic rather than respecting bounded contexts, and making repository calls directly from controllers while "leaking" infrastructure imports into domain layers. These are "helpful violations" — each individual change appears reasonable, but collectively they erode architectural intent.

**Effective AI rule files share common properties.** Anthropic's own guidance recommends CLAUDE.md files stay under **200 lines**. HumanLayer's analysis found that Claude Code's system prompt already consumes nearly a third of instruction-following capacity, so "your CLAUDE.md file should contain as few instructions as possible." Rules must be concrete and actionable — not "use modern web technologies" but "Frontend: Next.js 14 with App Router, TypeScript 5.3." The claude-ground project demonstrates effective RFC 2119 grading so "Claude knows what is a hard rule vs a best practice." Including negative examples ("Don't do X") proves as valuable as positive ones.

**The Constitutional Spec-Driven Development (CSDD) paper** formalizes "software constitutions" as versioned documents encoding non-negotiable requirements with explicit enforcement levels (MUST/SHOULD/MAY per RFC 2119). It identifies four categories of constitutional extension for architecture: layered separation, dependency inversion, bounded context boundaries, and technology boundary enforcement. The paper's key insight: "These principles prevent AI-generated code from violating structural invariants that are difficult to detect through testing alone."

**Soft enforcement must be paired with hard enforcement.** A 2025 arXiv paper on governance architecture for autonomous agents notes that CLAUDE.md constraints are "soft constraint mechanisms" enforced via LLM semantic interpretation, and "a sufficiently crafted prompt injection can bypass such constraints." The recommended architecture: AI-readable rules for generation-time awareness (CLAUDE.md, .cursorrules) combined with deterministic tools (ArchUnit, dependency-cruiser, linters) for build-time verification. This dual-layer approach — **probabilistic execution, deterministic governance** — is the emerging consensus.

---

## 6. Recommended rule format

Based on the research, each ground rule should use this structure:

```markdown
### GR-{number}: {Concise rule name}
- **Level**: MUST | SHOULD  
- **Category**: dependencies | boundaries | data-flow | security | technology | api-design | operational
- **Statement**: {One-sentence declaration using RFC 2119 keyword}
- **Rationale**: {Why this rule exists — the architectural damage if violated}
- **Enforced-by**: auto:{tool/test} | review:{what-to-check} | ai:{instruction}
- **Exceptions**: {How to request exception, or "None — no exceptions"}
```

**Justification for each field:**

The **Level** field uses RFC 2119's MUST/SHOULD distinction because it is the most widely adopted severity vocabulary across standards bodies, and maps directly to enforcement behavior: MUST rules fail builds and block AI code generation; SHOULD rules generate warnings and prompt AI to explain deviations. MAY is excluded because ground rules should capture constraints, not suggestions.

The **Category** field enables the `/bootstrap` conversation to systematically cover rule areas and enables the `/story-cycle` Phase 1e check to quickly identify which categories a story touches. Seven categories cover the full space found in research: dependencies, boundaries, data-flow, security, technology, api-design, operational.

The **Statement** field follows TOGAF's single-sentence declaration pattern — the most enduring format across 25+ years of architecture governance practice. The RFC 2119 keyword must appear in the statement.

The **Rationale** field is required by TOGAF and is critical for AI enforcement. Without rationale, AI assistants cannot distinguish between arbitrary preferences and structural necessities. When an AI understands *why* a rule exists, it makes better judgment calls at boundaries.

The **Enforced-by** field maps directly to Ford's fitness function taxonomy and solves the core problem identified in the research: rules without enforcement mechanisms become "MUST (BUT WE KNOW YOU WON'T)" per RFC 6919. The three enforcement channels — `auto` (CI/CD tools), `review` (human judgment), `ai` (generation-time instruction) — cover the full spectrum. Specifying the tool or check makes the rule actionable rather than aspirational.

The **Exceptions** field addresses the universal need for dispensations. TOGAF, Spotify (TAG approval), and every mature governance model includes exception handling. For AI enforcement, explicit exception criteria help the assistant distinguish legitimate deviations from drift.

---

## 7. Recommended categories for the template

**Essential categories (include in every project):**

- **Dependencies** — Dependency direction is the single most automatable and universally applicable rule category. Every architecture testing tool treats it as the primary use case. Rules here govern which modules can import from which, preventing the circular and reverse dependencies that cause architectural decay.

- **Boundaries** — Separation of concerns and module isolation rules. These define what constitutes a component boundary and what cannot cross it. This category is where "architectural liquefaction" occurs first in AI-assisted development.

- **Data flow** — Where state lives, how data moves between components, which layer owns persistence. TOGAF elevates data governance to a top-level concern. In AI-assisted development, data access violations (e.g., controllers querying databases directly) are among the most common "helpful violations."

**Recommended categories (include when relevant):**

- **Security** — Authentication/authorization patterns, secret handling, input validation boundaries. Netflix's experience shows security rules benefit most from paved-road enforcement because per-app security assessments don't scale.

- **Technology** — Locked technology choices and prohibited alternatives. Critical for AI enforcement because AI assistants draw on training data spanning many ecosystems and will introduce unapproved libraries if not constrained.

**Optional categories (project-specific):**

- **API design** — Contract formats, versioning, error handling. Essential for microservices and public APIs; less critical for monoliths or internal tools.
- **Operational** — Deployment patterns, observability requirements, performance thresholds. Important for production systems but often better expressed as fitness functions than as ground rules.

The essential-recommended-optional hierarchy enables `/bootstrap` to always cover the first three categories while prompting for the others based on project context. This aligns with the 3–7 rule target: 3 rules covering essentials, expanding to 7 with project-specific additions.

---

## 8. Recommended template structure

```markdown
# Ground Rules — {Project Name}
<!-- Generated by /bootstrap (A3.5b) | Last reviewed: {date} -->
<!-- Target: 3-7 rules. If you need more, some are probably SHOULD-level guidance, not ground rules. -->

## Architecture summary
<!-- 2-3 sentences: pattern, key technology choices, primary quality attributes -->

## Rules

### GR-001: {Rule name}
- **Level**: MUST
- **Category**: dependencies
- **Statement**: {Statement with RFC 2119 keyword}
- **Rationale**: {Why — what breaks if violated}
- **Enforced-by**: auto:{tool} | review:{check} | ai:{instruction}
- **Exceptions**: {Process or "None"}

### GR-002: ...
<!-- Repeat for each rule (3-7 total) -->

## Exception log
<!-- Track approved exceptions with: rule ID, justification, scope, expiry date, approver -->
| Rule | Justification | Scope | Expires | Approved by |
|------|--------------|-------|---------|-------------|

## Change history
<!-- When rules change, record: date, what changed, ADR reference if applicable -->
```

**Justification for this structure:**

The **Architecture summary** at the top gives both humans and AI the context needed to interpret rules correctly. Without it, rules become disconnected from intent. This section is what the CSDD paper calls "constitutional context" — it allows AI to make principled judgment calls when a rule's literal text doesn't cover an edge case.

The **Rules section** uses the format from Section 6. The numbered `GR-{NNN}` prefix enables cross-referencing from progress.md, ADRs, and code review comments — a pattern established by TOGAF's principle numbering and adopted by dependency-cruiser's named rules.

The **Exception log** as a table implements the lightweight dispensation tracking recommended by TOGAF and practiced by Spotify's TAG process. Including an expiry date prevents exceptions from becoming permanent, addressing the "governance sediment" problem. This table also serves as AI context: when the AI encounters an apparent violation, it can check whether an approved exception exists.

The **Change history** creates the audit trail that ADR practice demands. When a ground rule changes, the change should reference the ADR that motivated it, creating the bidirectional link between principles and decisions that Harmel-Law describes in *Facilitating Software Architecture*.

The entire template stays well under 100 lines for a project with 5 rules. The architecture summary adds ~5 lines, each rule adds ~7 lines, and the exception log and change history add ~10 lines for the headers and initial entries — totaling approximately **55–65 lines** for a typical project.

---

## 9. Examples of effective rules for common architectures

**Clean/hexagonal architecture:**

```markdown
### GR-001: Domain layer has zero outward dependencies
- **Level**: MUST
- **Category**: dependencies
- **Statement**: Domain modules MUST NOT import from infrastructure, application, or framework packages.
- **Rationale**: The dependency rule is the foundation of clean architecture. Violations couple business logic to delivery mechanisms, making the domain untestable and non-portable.
- **Enforced-by**: auto:ArchUnit `noClasses().that().resideInAPackage("..domain..").should().dependOnClassesThat().resideInAnyPackage("..infrastructure..", "..framework..")` | ai: "Never add imports from infrastructure or framework layers into domain files"
- **Exceptions**: None — no exceptions. If domain needs external capability, define a port interface.
```

**Microservices:**

```markdown
### GR-002: Services communicate only through defined contracts
- **Level**: MUST
- **Category**: boundaries
- **Statement**: Services MUST NOT share databases, internal models, or bypass API contracts for inter-service communication.
- **Rationale**: Shared databases create hidden coupling that defeats the purpose of service boundaries. Changes to one service's schema silently break others.
- **Enforced-by**: review: "Verify no cross-service database access in schema migrations and connection configs" | ai: "Each service owns its datastore exclusively. Never query another service's database."
- **Exceptions**: Read replicas for analytics SHOULD use CDC/event streaming, not direct access. Exception requires ADR.
```

**Frontend SPA (React/Next.js):**

```markdown
### GR-003: State management follows single-responsibility ownership
- **Level**: MUST
- **Category**: data-flow
- **Statement**: Server state MUST use TanStack Query; client-only state MUST use Zustand. Components MUST NOT mix state management approaches or use raw fetch/useEffect for data fetching.
- **Rationale**: Mixed state management creates inconsistent caching, stale data bugs, and makes refactoring unpredictable.
- **Enforced-by**: auto:eslint-plugin-no-restricted-imports (block raw fetch in components) | ai: "Use useQuery for server data, useStore for client state. Never useState+useEffect for API calls."
- **Exceptions**: None for new code. Legacy components tracked in progress.md for migration.
```

**Event-driven architecture:**

```markdown
### GR-004: Events are the sole mechanism for cross-boundary state changes
- **Level**: MUST
- **Category**: data-flow
- **Statement**: Bounded contexts MUST communicate state changes exclusively through domain events. Synchronous cross-context calls MUST NOT mutate state.
- **Rationale**: Direct cross-context mutations create temporal coupling and distributed transaction hazards. Events enable eventual consistency and independent deployability.
- **Enforced-by**: review: "Check that no command handlers call other contexts' repositories" | auto:dependency-cruiser `forbidden: [{from: {path: "^contexts/orders"}, to: {path: "^contexts/inventory/repositories"}}]` | ai: "Cross-context communication happens only through events published to the event bus."
- **Exceptions**: Query-only cross-context reads via CQRS read models are permitted with ADR justification.
```

---

## 10. Knowledge gaps and areas of uncertainty

**No empirical measurement of AI architectural drift.** While multiple practitioners describe "architectural liquefaction" and "helpful violations," no peer-reviewed study quantifies drift rates or measures the effectiveness of CLAUDE.md-style rules in preventing them. Shilov notes: "To make this testable we'd need drift metrics, review cost over time, and refactor scope when fixing violations."

**No cross-tool standard for AI-readable architecture rules.** CLAUDE.md (Claude Code), .cursorrules/.mdc (Cursor), and AGENTS.md (Codex/OpenCode) all use different conventions. The Agentics Foundation is working on standardization, but it remains early-stage. The ground rules template proposed here is tool-agnostic, but real-world usage will require mapping to specific AI assistant conventions.

**Soft enforcement reliability is uncharacterized.** A 2025 arXiv paper on autonomous agent governance identifies that CLAUDE.md constraints are fundamentally "soft constraint mechanisms" enforceable only through LLM semantic interpretation. No systematic testing has established what percentage of architectural violations AI assistants catch when given well-structured ground rules vs. poorly structured ones. The recommendation to pair AI rules with deterministic enforcement (ArchUnit, linters) mitigates this gap.

**Scale evidence is limited.** Most practical examples of AI-assisted architectural governance come from small-to-medium projects. Limited evidence exists on how well these approaches work for large enterprise codebases with hundreds of services and multiple teams.

**The "right number" of rules lacks empirical grounding.** TOGAF recommends 10–20 enterprise principles and observes "fewer is better for adaptability." The JD-LLM Framework targets 3–7. HumanLayer's research suggests AI assistants follow ~150–200 instructions with reasonable consistency. But no controlled study has tested what happens to compliance rates as ground rule count increases from 3 to 5 to 7 to 10. The 3–7 range is a reasonable heuristic based on practitioner experience, not empirical evidence.

**Holistic fitness functions remain underexplored.** Ford's taxonomy distinguishes atomic fitness functions (single concern) from holistic ones (multiple concerns combined). Nearly all practical tooling and examples address atomic functions. How to implement holistic fitness functions that test the interaction between, say, security and performance constraints simultaneously remains an open area with few practical examples.

---

## Conclusion

The ground rules template for the JD-LLM Framework should be a compact, testable document that serves dual audiences: human developers who need decision guidance and AI assistants who need unambiguous constraints. The research converges on several non-obvious insights that should shape the template design.

First, **enforcement channel matters more than rule eloquence**. Kyle Brown's principle — "if a decision is not testable, it is merely an opinion" — should be the admission criteria for ground rules. Every rule in the template must specify its enforcement mechanism, whether automated tooling, human review criteria, or AI instruction.

Second, **RFC 2119 grading creates a natural priority system** that both humans and AI interpret consistently. Limiting ground rules to MUST and SHOULD (excluding MAY) keeps the document focused on constraints rather than suggestions, directly addressing the "control fatigue" problem.

Third, **rationale is the most underappreciated field for AI enforcement**. When an AI assistant understands *why* a rule exists, it makes better boundary decisions — distinguishing between the spirit and letter of the law. Rules without rationale produce brittle compliance; rules with rationale produce intelligent compliance.

Fourth, the **dual-enforcement model** — AI-readable rules for generation time paired with deterministic tools for build time — represents the emerging best practice. Neither layer alone is sufficient. AI rules catch violations before code is written; fitness functions catch what slips through.

Finally, the template must treat **evolution as a feature, not a bug**. The change history section, exception log, and ADR cross-references ensure that ground rules are living documents that evolve with the project rather than fossilizing into ignored shelfware. The goal is not permanence but guided evolution — exactly the principle at the heart of Ford's evolutionary architecture.