# Architecture documentation optimized for AI-assisted development

**The most effective architecture documentation for AI consumption is not a comprehensive description of the codebase — it is a concise set of prescriptive rules about what an AI cannot discover on its own.** The ETH Zurich AGENTbench study (February 2026) — the first rigorous empirical evaluation of AI context files — found that auto-generated codebase overviews actually *reduced* task success by 2–3% while increasing cost by 20%+. Human-written, constraint-focused context files improved success by ~4%. The critical insight: AI agents independently discover directory structures, tech stacks, and code patterns. What they cannot infer is *intent* — architectural boundaries, non-obvious conventions, known landmines, and the reasoning behind decisions. A 200-line architecture document should therefore be dense with non-inferable rules and sparse on descriptions the AI can derive from reading code. The recommended template below synthesizes findings from the C4 model, arc42, industry practices at Google/Netflix/Stripe/Spotify, academic research on LLM code comprehension, and the emerging AGENTS.md ecosystem.

---

## Documentation frameworks that actually work in practice

No major tech company uses IEEE 42010, the 4+1 view model, or formal C4 as their primary documentation approach. Google uses lightweight **10–20 page design docs** (or 1–3 page "mini design docs") focused on goals/non-goals, the design itself, and alternatives considered. Spotify embeds RFCs and ADRs deeply into engineering culture alongside Backstage service catalogs. Netflix relies on metadata-driven, self-documenting systems with operational tooling rather than static documents. Stripe maintains a strong writing culture with design docs and open-sourced its engineering handbook templates.

The practical sweet spot for any project is a combination of **C4 diagrams (Levels 1–2), selected arc42 sections, and Architecture Decision Records**. The C4 model, created by Simon Brown, provides four hierarchical abstraction levels: System Context (your system as a black box with users and external systems), Container (deployable units like APIs, databases, SPAs), Component (internal building blocks within a container), and Code (class-level). Most practitioners agree that **Levels 1 and 2 are essential for all projects**, Level 3 is useful only for complex containers, and Level 4 should never be manually maintained. C4 is technology-agnostic — a "container" can be a Python microservice, a React SPA, or a PostgreSQL database — making it ideal for a language-agnostic template.

Arc42, created by Gernot Starke and Peter Hruschka, provides a 12-section documentation template. Its creators emphasize that everything is optional. For a compact architecture document, the essential sections are: **Introduction & Goals (Section 1), Context & Scope (Section 3), Solution Strategy (Section 4), Building Block View (Section 5), Architecture Decisions (Section 9), and Glossary (Section 12)**. Arc42 and C4 are complementary — arc42 defines *what to write about* while C4 defines *how to draw diagrams*. IEEE 42010 and the 4+1 view model contribute valuable *concepts* (stakeholder-driven viewpoints, multiple architectural views), but their formal rigor is disproportionate for anything except regulated industries requiring certification. The 4+1 model's Logical and Development views remain the most relevant for code comprehension, though its UML-centric notation has been superseded by diagrams-as-code tools.

---

## Mermaid is the only viable diagram tool for this use case

Given the hard constraint of GitHub Markdown native rendering, **Mermaid is the only option**. GitHub added native Mermaid support in February 2022, rendering diagrams directly from ` ```mermaid ` code blocks in READMEs, issues, and PRs without plugins or pre-rendering. PlantUML, D2, and Structurizr DSL do not render natively in GitHub — PlantUML requires Java and workarounds like proxy URLs or GitHub Actions; D2 requires pre-rendering to SVG; Structurizr requires export to Mermaid for GitHub display.

Beyond GitHub compatibility, Mermaid has **the strongest AI/LLM readability**. LLMs are extensively trained on Mermaid syntax, and the text is meaningful even without visual rendering — `User --> WebApp --> Database[(PostgreSQL)]` conveys architectural relationships in plain text. Tools like Swark (an open-source VS Code extension) use GitHub Copilot to auto-generate Mermaid from code analysis. The specific diagram types that provide the most value are:

- **`flowchart`** for C4 Context and Container diagrams — the most versatile type, showing system boundaries, components, and their relationships. This single diagram type can represent the two most important architectural views.
- **`sequenceDiagram`** for critical data flows — showing how components interact during key operations. Sequence diagrams are universally cited as the most useful diagram type for developers.

Other Mermaid types (classDiagram, erDiagram, stateDiagram-v2) are useful for specific projects but should not be mandatory in a generic template. Mermaid's C4 diagram support remains experimental with significant limitations, so **using `flowchart` with C4-style labeling** (showing system context and containers) is more reliable than Mermaid's native C4 syntax. The key statistic motivating diagram-as-code: **58% of software architecture diagrams are outdated** according to a Mural/Researchscape study. Storing Mermaid source in the same repository as code, with diagram updates required in PRs that change architecture, is the most effective mitigation.

---

## What AI actually needs from architecture documentation

Research from multiple academic studies and practitioner experience converges on a counterintuitive principle: **AI agents benefit only from information they cannot discover independently**. The ETH Zurich AGENTbench study tested 138 real tasks across 12 Python repositories and found that including architectural overviews or directory structure explanations "did not seem to reduce the time the model spent locating relevant files." What *did* help: mentioning `uv` as the package manager caused agents to use it **1.6 times per task versus 0.01 without** — a 160x improvement for a single non-obvious instruction.

A complementary study (Lulla et al., ICSE JAWs 2026) found that AGENTS.md files reduced **median wall-clock time by 28.64%** and output tokens by 16.58% — but this measured efficiency, not correctness. The ACE Framework (ICLR 2026) demonstrated that treating context as evolving playbooks outperformed static approaches by **12.3%** on agent benchmarks.

The optimal format for AI consumption is **semi-structured Markdown with explicit, imperative rules**. Research from Anthropic, the Arize AI optimization study, and practitioner consensus identifies these principles:

- **Rules over descriptions.** "Controllers ONLY delegate to Services. Controllers NEVER access Repositories directly" works far better than narrative prose about layered architecture. LLMs follow explicit rules more reliably than they absorb descriptive text.
- **Prescriptive over descriptive.** Document what *should and shouldn't happen*, not what exists. The AI can read the code to discover what exists.
- **Three-tier boundary system.** GitHub's analysis of 2,500+ agent context files found the most effective specs use: ✅ Always do, ⚠️ Ask first, 🚫 Never.
- **Progressive disclosure.** Keep the root document minimal; point to detailed documents loaded on demand via "Read when" triggers. Frontier LLMs can follow approximately **150–200 instructions** with reasonable consistency; Claude Code's system prompt already contains ~50.
- **File-path references over code snippets.** Snippets go stale; `src/utils/api.ts` stays accurate.
- **Known landmines and gotchas.** These are the highest-value items because they prevent repeated mistakes across AI sessions and represent information completely invisible in the code structure.

Santos et al. (2025) analyzed 328 Claude Code configuration files from public projects and found **72.6% specify application architecture**, confirming that the developer community has already converged on architecture-in-context-files as a best practice.

---

## Living documentation requires executable constraints, not just text

The core insight from the living documentation research is that **architecture enforcement tools are more reliable documentation than prose**. When an ArchUnit test states `classes().that().resideInAPackage("..service..").should().onlyBeAccessed().byAnyPackage("..controller..", "..service..")`, that *is* documentation that cannot go stale because it breaks the build if violated.

Language-specific enforcement tools include **ArchUnit** (Java — pre-built rules for layered, onion, and hexagonal architectures), **NetArchTest/ArchUnitNET** (.NET), **dependency-cruiser** (JavaScript/TypeScript — generates Mermaid dependency graphs and enforces custom rules), **import-linter** and **Deply** (Python), **go-arch-lint** (Go), and Rust's built-in module visibility system (`pub`, `pub(crate)`, `pub(super)`). Each integrates with CI/CD to catch violations automatically.

Neal Ford's architectural fitness functions extend this concept: automated checks that verify whether a system preserves desired properties over time. Examples include dependency direction enforcement (no circular dependencies), component size thresholds (no single component exceeds 30% of codebase), and continuous resilience testing (Netflix's Chaos Monkey). SonarQube's new Architecture capability (2025–2026) treats architecture as a trackable quality metric, detecting wrong-location files, tangles, and model deviations in the IDE.

For a self-signaling architecture document, the most practical approach combines three mechanisms: a **"Last Verified" date** in the document header that CI can check for staleness, **`<!-- REVIEW-NEEDED: when X changes, update this section -->`** comments linking document sections to code paths, and **architecture tests in CI** that serve as the executable source of truth. When code and tests diverge from the document, the document signals its own obsolescence. The document should also include an explicit "Update Triggers" section listing what code changes require documentation updates.

---

## The most damaging anti-pattern: documenting the fantasy architecture

The single most destructive documentation anti-pattern, confirmed by every authoritative source, is **documenting the aspirational architecture rather than the actual one**. SonarQube's engineering blog describes the "fundamental flaw": architects create beautiful diagrams that become outdated within weeks, and as the gap widens between intended and actual architecture, the system enters the "Big Ball of Mud" phase. One internal study found **30% of production spans involved services not present in official architecture diagrams**. In another platform, a documented hexagonal architecture silently accumulated cross-layer imports until bidirectional edges increased by 40% over six months.

Other critical anti-patterns include **"Architecture by Implication"** — making design decisions implicitly without documentation, which is *particularly devastating* for AI-assisted development because AI has zero access to implicit knowledge in developers' heads. Over-documentation creates documents nobody reads and that become stale faster than they can be maintained. Under-documentation creates knowledge silos and painful onboarding. The sweet spot, articulated by Simon Brown: **"Document what will be hard to figure out later."** Focus on *why* and *how*, not *what* — code already shows *what*.

Missing rationale is another critical failure. Without ADRs explaining *why* decisions were made, teams reverse important decisions, repeat past mistakes, and AI assistants suggest "improvements" that reintroduce problems the architecture was specifically designed to avoid. The fix: every architectural constraint should link to an ADR explaining the reasoning.

---

## Constraints, decisions, and quality attributes in compact format

**Architecture Decision Records** are the single highest-ROI documentation practice. Michael Nygard's original format (2011) uses five sections — Title, Context, Decision, Status, Consequences — and each ADR should be readable in 2–3 minutes. MADR v4.0.0 extends this with Decision Drivers, Considered Options, and Confirmation sections. For ultra-compact capture, Y-statements compress an entire ADR into one sentence: *"In the context of [use case], facing [concern], we decided for [option] to achieve [quality], accepting [downside]."*

For a ~200-line architecture document, **ADRs belong in a separate `docs/decisions/` directory with an inline summary table** in the architecture doc linking to full ADRs. Critical active decisions should also appear as imperative bullet points that AI must respect. Trade-offs embed naturally in ADR Consequences sections using a three-category format: Gained / Traded away / Accepted risk. Quality attributes use a compact tabular format inspired by SEI scenarios: Attribute, Requirement, Measure, Priority. Constraints follow arc42's three categories (Technical, Business, Regulatory) in simple tables with ID, Constraint, and Rationale columns. The constraint ID system enables cross-referencing from ADRs ("Because of C-4 [GDPR], we chose...").

---

## Recommended template structure

Based on all research findings, the following template structure is optimized for AI consumption, language-agnostic projects, GitHub Markdown rendering, and a strict 200-line budget. Each section is justified by specific research findings:

**Section 1: Header and metadata (4–6 lines).** Project name, one-line purpose, "Last Verified" date, and `<!-- REVIEW-NEEDED -->` trigger. *Justification*: The "Last Verified" date is the most practical staleness signal (living documentation research). The one-line purpose orients the AI immediately (BLUF principle).

**Section 2: Tech stack and build commands (5–10 lines).** Language, framework, key dependencies, and non-obvious build/test/lint commands. *Justification*: ETH Zurich study showed non-obvious tooling commands are the *highest-value* content — mentioning the package manager improved agent usage 160x. AI can discover most tech stack details, so only list what's non-standard.

**Section 3: Architecture diagram — Mermaid flowchart (15–25 lines).** C4 Container-level diagram showing major components, their technologies, and communication patterns. *Justification*: C4 Levels 1–2 are essential for all projects (Simon Brown). Flowchart is Mermaid's most reliable diagram type. Visual relationships between components are harder for AI to reconstruct from code alone than file structure.

**Section 4: Module map and dependency rules (15–25 lines).** Directory-to-responsibility mapping and explicit dependency direction rules using imperative language (MUST, NEVER, ONLY). *Justification*: GitHub's analysis of 2,500+ specs found the three-tier boundary system (Always/Ask/Never) most effective. Prescriptive rules outperform descriptive prose for AI (multiple studies).

**Section 5: Key data flow — Mermaid sequence diagram (10–20 lines).** The single most critical workflow (e.g., request lifecycle, primary business operation). *Justification*: Sequence diagrams are universally cited as the most useful diagram type for developers. One well-chosen flow teaches the AI the system's interaction patterns.

**Section 6: Architectural constraints (10–15 lines).** Technical, business, and regulatory constraints in compact table format with ID cross-references. *Justification*: Arc42 Section 2 format. Constraints are non-negotiable and non-inferable — exactly what AI needs.

**Section 7: Key decisions summary (10–20 lines).** ADR summary table linking to full records, plus 3–5 critical active decisions as imperative rules. *Justification*: Nygard ADRs + MADR best practices. OutcomeOps demonstrated that 3 ADRs changed AI output from "generic" to "code a maintainer would merge."

**Section 8: Quality requirements (5–10 lines).** Top 3–5 quality attributes in compact table (Attribute, Requirement, Measure, Priority). *Justification*: SEI quality attribute scenarios, simplified. Keeps the AI aware of NFRs that should inform code decisions.

**Section 9: Cross-cutting concerns (5–10 lines).** Error handling pattern, logging approach, authentication mechanism, data validation approach — one line each. *Justification*: Google design doc template includes cross-cutting concerns. These patterns span module boundaries and are hard to discover consistently from code.

**Section 10: Known landmines and gotchas (5–15 lines).** Non-obvious failure modes, deprecated-but-still-imported code, workarounds, things that have tripped up developers. *Justification*: HumanLayer identifies these as the highest-value items. They prevent AI from making the same mistakes human developers have already encountered.

**Section 11: Update triggers (5–8 lines).** Explicit list of what code changes require updating this document. *Justification*: Living documentation research — self-signaling mechanism that prevents silent staleness.

**Total: ~110–170 lines**, leaving buffer for project-specific additions while staying under the 200-line budget.

---

## Recommended diagram approach

**Tool: Mermaid (non-negotiable given GitHub constraint).** Use `flowchart TD` (top-down) for the architecture overview and `sequenceDiagram` for the critical data flow. These two diagram types, consuming roughly 30–40 lines combined, provide the highest information density for AI consumption.

For the architecture overview, use Mermaid's flowchart with C4-style labeling rather than Mermaid's experimental C4 syntax:

```
flowchart TD
    User([User]) --> WebApp[Web App<br/>React + TypeScript]
    WebApp --> API[API Server<br/>Python FastAPI]
    API --> DB[(PostgreSQL)]
    API --> Cache[(Redis)]
    API --> Queue[Message Queue<br/>RabbitMQ]
    Queue --> Worker[Background Worker<br/>Python Celery]
    Worker --> DB
```

For the critical flow, use a focused sequence diagram showing the primary business operation:

```
sequenceDiagram
    Client->>API: POST /orders
    API->>AuthService: Validate token
    API->>OrderService: Create order
    OrderService->>DB: INSERT order
    OrderService->>Queue: Publish OrderCreated
    API-->>Client: 201 Created
```

**Auto-generation strategy:** Use Swark (VS Code extension) or LLM-powered analysis to bootstrap diagrams from code, then manually refine to the right abstraction level. Pure auto-generation produces "spaghetti diagrams" — the best approach combines automated extraction with human/LLM curation. Store Mermaid source in the architecture doc itself (not separate files) so AI reads diagrams inline with context.

---

## Knowledge gaps where more research would be valuable

**Quantitative impact of architecture docs on AI code correctness.** The ETH Zurich study measured task success rates, and the Lulla et al. study measured efficiency, but no study has specifically measured *architectural violation rates* with and without architecture documentation. This is the metric most relevant to the stated use case.

**Optimal instruction density per line.** Research shows LLMs can follow ~150–200 instructions, but there is no study on the relationship between instruction specificity (vague vs. precise rules) and compliance rates in coding contexts. The ACE Framework's "brevity bias" finding (iterative optimization collapses toward short, generic prompts) suggests a tension between conciseness and specificity that deserves further investigation.

**Cross-tool context file standardization.** AGENTS.md is emerging as a cross-tool standard (supported by OpenCode, Zed, Cursor, Copilot CLI, Codex), but its relationship to architecture documentation is undefined. Whether architecture constraints should live in AGENTS.md, CLAUDE.md, a separate ARCHITECTURE.md, or a combination is an open question with no empirical evidence.

**Auto-detection of architectural drift from AI-generated code.** While tools like ArchUnit and dependency-cruiser detect violations in CI, there is no published research on whether AI coding assistants systematically introduce specific *types* of architectural violations, which would inform what constraints to prioritize in documentation.

**Long-context model behavior with architecture docs.** As context windows expand (Claude's 200K tokens, Gemini's 1M+), the 200-line constraint may become less important for token budget reasons but may remain important for instruction-following quality. Research on how architecture document length interacts with code generation quality at different context window sizes would be valuable.