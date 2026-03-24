# Coding Standards That AI Actually Follows

**The single most important finding: less is more.** Frontier LLMs like Claude can reliably follow roughly 150–200 instructions before compliance degrades uniformly across *all* rules — meaning every irrelevant line in your standards document makes the AI worse at following the important ones. The most effective coding standards for AI-assisted development are short (under 200 lines per language section), binary (do/don't, never vague), and structured as concrete code examples rather than prose. Industry data confirms this: **65% of developers cite "missing context" as the top barrier to useful AI-generated code**, yet the solution is not more context but *better-targeted* context. Teams that pair concise, specific standards with automated tooling see measurably better outcomes — 81% report quality improvements versus 55% for teams relying on standards alone.

This report synthesizes research across industry style guides, AI compliance studies, multi-language project organization, testing standards, AI code anti-patterns, and standards maintenance practices to propose an optimal template structure for the JD-LLM Development Framework.

---

## 1. What the best style guides have in common

Every successful coding style guide — Google's (Python, C++, Go), Airbnb JavaScript (148K+ GitHub stars), PEP 8, Swift API Design Guidelines, Rust's official guide, Microsoft .NET, and Kotlin conventions — shares five structural traits regardless of language or organization.

**Code examples are the universal communication mechanism.** No successful guide relies on prose alone. The highest-compliance format is the **do/don't code pair with a one-line rationale** — used by Airbnb (`// bad` / `// good` + "Why?"), Google (`Yes:` / `No:` + Definition/Pros/Cons/Decision), and Swift (inline examples with call-site context). Tables are surprisingly rare; only naming conventions benefit from tabular format.

**Rationale is non-negotiable.** Every widely-adopted guide explains *why* behind every rule. Google's four-part structure (Definition → Pros → Cons → Decision) forces rigorous justification. Airbnb includes a "Why?" paragraph after each rule. Rules without reasons breed resentment and non-compliance — a finding confirmed by both Google's internal research ("Software Engineering at Google," Chapter 8) and practitioner surveys.

**Tooling integration drives adoption more than documentation quality.** Airbnb ships `eslint-config-airbnb`. Google provides pylintrc files. Rust's style guide exists literally as the specification for `rustfmt`. Go's `gofmt` handles all formatting with zero configuration, freeing the style guide to focus entirely on semantic decisions. The pattern is clear: guides with ready-made linter configs achieve near-universal adoption; guides without them become shelf-ware.

**The optimal length is 3,500–12,000 words.** Swift's API Design Guidelines (~3,500 words) achieve industry-standard adoption because they're short enough to read in one sitting. PEP 8 (~10,000 words) and Airbnb JS (~12,000 words) are the most widely followed comprehensive guides. Google's C++ guide (~40,000 words) works only because of organizational enforcement and tooling automation. For a context-budget-constrained AI template, this translates to **150–200 lines per language section** — achievable by delegating formatting to tools and using the "base + exceptions" pattern (reference an authoritative guide, then document only deviations).

**Google Go's three-tier hierarchy is the most sophisticated structural innovation**: a concise *Style Guide* (canonical, mandatory), a verbose *Style Decisions* document (normative rationale), and advisory *Best Practices* (optional patterns). This separation prevents guide fatigue while capturing institutional knowledge at the appropriate level.

## 2. How LLMs respond to coding standards

Research from the MSR '26 empirical study of 401 open-source repos with cursor rules, HumanLayer's analysis of Claude Code behavior, and Qodo's 2025 State of AI Code Quality report converge on several critical findings about writing standards that AI actually follows.

**LLMs exhibit linear instruction-following decay.** Frontier thinking models can handle ~150–200 instructions with reasonable consistency, but compliance decreases uniformly across all instructions as count increases. Smaller models show exponential decay. Claude Code's system prompt already consumes ~50 instructions of this budget before any user rules load. This means **a CLAUDE.md file should stay under 300 lines, ideally under 60 lines** for the root file, with detailed standards loaded on demand via progressive disclosure.

**Specific, binary rules dramatically outperform vague guidance.** The instruction "Use ES modules (`import`/`export`), not CommonJS (`require`)" achieves near-perfect compliance. The instruction "follow modern JavaScript practices" achieves essentially nothing. Negative constraints ("NEVER use `any` type") are followed more reliably than positive preferences ("prefer strict types"). The MSR '26 study found that **28.7% of all cursor rule content is duplicated or redundant**, wasting precious context budget.

**One to two code examples is the sweet spot.** Research on LLM code evaluation found all major models performed better with one example but experienced quality declines when more were included. Aider's documentation demonstrates that a single `CONVENTIONS.md` example changed GPT's behavior from using `requests` to `httpx` with type hints — matching the convention exactly. However, overloading with examples causes the model to pattern-match superficially rather than understanding the underlying rule.

**LLMs bias toward prompt peripheries.** Instructions at the very beginning (system message/CLAUDE.md header) and very end (most recent user messages) receive disproportionate attention. Instructions in the middle are most likely to be ignored. This has direct implications for template structure: **put critical, never-violate rules at the top**.

The categories of rules that LLMs follow well versus struggle with reveal a clear automation boundary:

| High AI Compliance | Low AI Compliance |
|---|---|
| Naming conventions (camelCase, PascalCase) | Subjective quality ("write clean code") |
| Technology constraints ("use httpx not requests") | Architectural decisions requiring system context |
| File/project structure rules | Performance optimization trade-offs |
| Import preferences and type system rules | Business logic correctness |
| Framework idioms well-represented in training data | Cross-cutting concerns spanning multiple files |
| Explicit forbidden patterns | Complex error recovery strategies |

## 3. Optimal structure for multi-language standards

The research reveals a clear consensus: **modular documents beat monolithic guides** for polyglot projects. Google maintains separate guides per language under a shared organizational philosophy. Chromium uses the "base + exceptions" pattern ("Follow Google C++ Style Guide unless an exception is listed below"). Kubernetes maintains a single cross-cutting conventions document for its primary language with separate guides for secondary concerns.

**The three-tier enforcement model** is the most effective organizing principle for what goes where. **Tier 1** (formatters handle — don't document): indentation, whitespace, brace placement, import ordering, trailing commas. **Tier 2** (linters enforce — brief documentation): unused variables, basic naming patterns, deprecated API usage, simple code smells. **Tier 3** (requires judgment — detailed documentation): naming intent, error handling strategy, architecture patterns, code organization, API design. An internal Google survey estimated **roughly 90% of C++ style guide rules could be automatically verified**; academic research found **72.1% of Google Java rules** enforceable by Checkstyle and **40.3% of Google JavaScript rules** by ESLint.

For the JD-LLM template specifically, the recommended hierarchy is:

```
CLAUDE.md (root, <60 lines)
├── .claude/
│   └── standards/
│       ├── shared-conventions.md    (~100 lines)
│       ├── [language].md            (~150-200 lines each)
│       ├── testing.md               (~100 lines)
│       └── tooling-config.md        (~50 lines)
```

**Shared conventions should cover philosophy, not syntax.** What's genuinely language-agnostic: naming *philosophy* (meaningful names, avoid abbreviations), error handling *principles* (categorize recoverable vs. unrecoverable, never swallow silently), documentation *requirements* (what must be documented), testing *philosophy* (coverage expectations, test naming structure), and security baseline (input validation, parameterized queries, no hardcoded secrets). Language-specific sections then handle naming *conventions* (camelCase vs. snake_case), error handling *syntax* (try/catch vs. Result types vs. error returns), and idiomatic patterns.

**The "base + exceptions" pattern is essential for the 200-line budget.** Each language section should reference an authoritative external standard (PEP 8 for Python, Effective Go for Go, Airbnb guide for TypeScript) and document only project-specific deviations. This approach, used by Chromium and ChromiumOS, dramatically reduces document size while maintaining comprehensive coverage.

For naming conventions specifically, **tables are the one place they outperform prose** — a cross-language comparison table showing the convention for variables, functions, classes, constants, and files across all project languages communicates in 10 lines what would take 50 lines of prose.

## 4. Testing standards that actually improve code quality

Testing standards are among the highest-ROI additions to a coding standards document because they're both highly enforceable and commonly violated — especially by AI-generated code. Research shows **40–50% of AI-generated tests require rewrites for validity**, and AI tests exhibit systematic biases: happy-path clustering, tautological assertions (`expect(result).toBe(result)`), and implementation coupling over behavioral testing.

**The three-element naming convention has universal expert consensus.** Roy Osherove, Dan North, Vladimir Khorikov, and Jon Reid all agree test names must contain: (1) the behavior/action under test, (2) the scenario/condition, and (3) the expected outcome. The specific syntax varies by ecosystem — `test_action_should_expected_when_condition` for Python, `should expected when condition` for JavaScript describe blocks — but the three-part structure is universal and enforceable via linting rules that reject generic names like `test1()`.

**AAA (Arrange-Act-Assert) should be mandatory, with sections separated by blank lines.** Described as "almost a standard across the industry" by multiple authoritative sources (Microsoft Learn, ThoughtBot, Semaphore), the AAA pattern is the single most effective structural standard for test quality. The Act section should be 1–3 lines — if it's longer, the test is testing too much.

**The "one assertion per test" rule is widely misunderstood.** Mark Seemann (Stack Overflow Blog, 2022) clarifies: "Multiple assertions are fine... It's not the number of assertions that cause problems, but that the test does too much." The correct standard is **one logical behavior per test**, with multiple assertions verifying different facets of the same behavior being perfectly acceptable. Each assertion should include a descriptive failure message when the failure reason wouldn't be obvious from the test name alone.

**Coverage thresholds converge on 80% for new code.** Martin Fowler expects "a coverage percentage in the upper 80s or 90s" for thoughtfully tested code. Atlassian, Industrial Logic, and Bullseye Testing Technology all recommend **80% line coverage as the standard gate**. But Fowler warns: "High numbers don't necessarily mean much" — coverage finds untested code but doesn't prove test quality. The recommended CI configuration: fail if coverage drops below 70% (safety net), target 80%+ on new code, and require ≥90% branch coverage on critical business logic.

For AI-generated tests specifically, standards should require: (1) the same code review process as human-written tests, (2) verification that each test fails when the code-under-test is broken (mutation testing or manual check), (3) explicit prohibition of tautological assertions, and (4) at least one negative/error case per function tested.

## 5. AI code anti-patterns and how standards prevent them

GitClear's analysis of **211 million changed lines of code** (2020–2024) provides the most comprehensive evidence of AI code quality degradation. Code blocks with 5+ duplicated lines increased **8x during 2024**. Refactoring dropped from 25% of changes to under 10%. For the first time in history, **copy/paste exceeded code reuse**. Google's 2025 DORA Report found 90% increase in AI adoption correlated with a 9% climb in bug rates and 91% increase in code churn.

The most damaging and documentable anti-patterns, with their preventive standards:

**Unnecessary comments are the most pervasive AI slop pattern.** GitHub issue #59697 (open since 2023, still active) documents that Copilot generates comments that "essentially mirror the function name in a more verbose way." The standard that works: "Comments explain WHY, not WHAT. Delete every comment that restates what the code does." The `deslop` npm tool (dabit3/deslop) can detect and flag this automatically in CI.

**Over-engineering and excessive verbosity** manifest as higher cyclomatic complexity, more lines of code, and unnecessary abstractions. SonarSource's 2025 analysis found that AI-generated code increases Lines of Code, Halstead Metrics, and Cyclomatic Complexity, mathematically decreasing the Maintainability Index. Effective standards: "Functions do one thing and are under 40 lines. Cyclomatic complexity per method stays under 10."

**Hallucinated APIs represent both a correctness and security risk.** Attackers now register malicious packages under names LLMs commonly hallucinate — a vulnerability called "slopsquatting." The single most impactful preventive standard is **version-pinning with explicit technology constraints**: "React 18.3 (not 19 — do not use React 19 APIs like `use()`). TypeScript 5.4 strict mode." As the Agent Rules Builder guide states: "AI models contain knowledge of multiple incompatible versions of the same library. Without version pins, they guess — and guess inconsistently."

**Excessive defensive programming** produces unnecessary try-catch blocks, redundant null checks, and over-complicated conditionals. The standard: define explicit error handling patterns per language and prohibit empty catch blocks — `catch (error) { console.error(error) }` is almost never the right approach; require either re-throwing with context or structured error handling via a project-specific error class.

**Security vulnerabilities are 1.57x more common in AI-generated code** according to CodeRabbit's 2025 comparative study, with **2.74x more XSS vulnerabilities** and **1.91x more insecure object references**. The OpenSSF's 2025 Security-Focused Guide confirms: "AI-generated code is not secure by default. All models tend to generate vulnerabilities for both common and less common types." Providing security hints in the standards document measurably improves output safety. Minimum security standards: parameterized queries (never string concatenation), no hardcoded secrets, input validation on all external data.

**The amplification thesis** from Google's DORA Report provides the meta-framework: "AI doesn't fix a team; it amplifies what's already there." Teams with strong standards and tooling see AI accelerate quality code production. Teams without see quality decline accelerate. This makes the coding standards template not just a nice-to-have but a force multiplier for AI-assisted development.

## 6. Keeping standards effective over time

The research is unambiguous: **automation is the primary driver of compliance, not documentation quality.** Teams that treat standards as code — version-controlled, CI-enforced, reviewed via RFC processes — maintain compliance over time. Teams that rely on documentation alone see standards degrade within months.

**~70–80% of coding standard rules can be automated today.** Academic research found 72.1% of Google Java rules enforceable by Checkstyle; LDRA covers ~80% of the Embedded C Coding Standard; combining linters with LLM-powered semantic review reaches ~90%. The remaining 10–22% — architectural decisions, business logic, design quality, cross-service coordination — requires human judgment and is precisely what the standards document should focus on.

**SonarQube's "Clean As You Code" is the gold standard for progressive enforcement.** Apply strict quality gates to new code (zero new bugs, zero new security vulnerabilities, coverage ≥80%) while allowing legacy code to improve incrementally. This avoids the "boil the ocean" problem that kills standards adoption. For phased rollout of new rules, the pattern is: introduce as warnings for 1–2 weeks, switch to errors once understood, then enforce strictly.

**Standards ownership requires a small council, not a committee.** Google assigns dedicated style arbiters per language. LSST Data Management requires explicit System Architect approval for changes. The recommended model: 2–5 senior engineers as stewards who own the document, with team-wide input via lightweight RFC processes (summary → motivation → proposed change → alternatives → approvers). Companies using RFC processes for standards evolution include Airbnb, Spotify, Stripe, Uber, and Wise.

**The "pull their weight" test prevents bloat.** Google's guiding principle — "The benefit of a style rule must be large enough to justify asking all of our engineers to remember it" — is the most effective filter against standards expansion. Add rules only when they address actual pain points observed in the codebase. Remove rules the AI has learned to follow. One practitioner found that mandating "comment every method" standardized procedure rather than the goal — producing vast quantities of useless documentation.

The most common reasons developers ignore standards, from research by DaedTech, Codacy, and Google's SWE book: (1) time pressure, (2) lack of buy-in from top-down imposition, (3) too many rules degrading memory and compliance, (4) no automation making compliance depend on discipline under pressure, (5) rules that don't solve real problems, and (6) perceived punitive framing. Every one of these is addressable through the template design proposed below.

## 7. Recommended template structure

Based on all research findings, the following structure optimizes for AI compliance while remaining effective for human developers. The design principles are: progressive disclosure (root file is tiny, detail loaded on demand), binary rules over vague guidance, code examples over prose, and separation of automated concerns from judgment calls.

### Root CLAUDE.md (target: 40–60 lines)

```markdown
# [Project Name]
[One-line description]

## Tech Stack
[Language] [version] / [Framework] [version] / [Key libraries with versions]

## Commands
- build: [command]
- test: [command]  
- lint: [command]
- format: [command]

## Critical Rules
- [3-5 NEVER-violate rules, e.g., "No hardcoded secrets", "No `any` types"]

## Code Style
- [5-8 highest-impact rules, specific and binary]

## Architecture
- [Brief directory purpose map, 5-10 lines]
- [Key patterns: "API routes in /api, components in /components"]

## Standards
See .claude/standards/ for complete conventions.
```

### Per-language section (target: 150–200 lines each)

```markdown
# [Language] Conventions

## Base Standard
Follow [authoritative guide] with these project-specific exceptions:

## Naming
| Construct | Convention | Example |
|-----------|-----------|---------|
[Table: 6-8 rows covering variables, functions, types, constants, files, tests]

## Error Handling
[3-5 specific patterns with do/don't code examples]
- Use [project error type] for application errors
- [Language-specific pattern, e.g., "Wrap errors with context: fmt.Errorf("x: %w", err)"]

## Patterns We Use
[3-5 do/don't code pairs for project-specific conventions]

## Patterns to Avoid
[3-5 explicit anti-patterns with alternatives]
❌ [bad code example]
✅ [good code example]
Why: [one line]

## Imports & Dependencies
[2-3 rules about import ordering, approved/prohibited libraries]

## Tooling
- Formatter: [tool] (handles: indentation, spacing, line length — don't fight it)
- Linter: [tool] with config at [path]
- Type checker: [tool]
```

### Shared conventions section (target: ~100 lines)

```markdown
# Shared Conventions

## Philosophy
[2-3 sentences: e.g., "Clarity over cleverness. Code is read 10x more than written."]

## Documentation
- Comments explain WHY, never WHAT
- Public APIs require docstrings with: purpose, parameters, return value, errors
- No commented-out code — use version control

## Security Baseline
- All database queries use parameterized statements
- No hardcoded secrets, API keys, or credentials
- Validate all external input

## Git Conventions
- Commit format: [conventional commits or project pattern]
- PR requirements: [description, tests, review]
```

### Testing section (target: ~100 lines)

```markdown
# Testing Standards

## Naming
Tests follow: [action]_[scenario]_[expected]
Example: `test_parse_email_returns_none_when_missing_at_sign`

## Structure
Every test uses Arrange-Act-Assert with blank line separation.
Act section: 1-3 lines maximum.

## Coverage
- New code: ≥80% line coverage (CI-enforced)
- Critical business logic: ≥90% branch coverage
- CI fails if coverage drops below 70%

## What to Test
- One logical behavior per test
- Every function: at minimum one happy path + one error case
- Test behavior, not implementation

## Anti-Patterns (NEVER)
- Tautological assertions (assert x == x)
- Tests that can't fail when code breaks
- More than 3 levels of mock nesting
- Tests depending on execution order
```

### Justification for this structure

The format choices are evidence-based. **Do/don't code pairs** are the highest-compliance format across all style guide research (used by the most-adopted guide, Airbnb, and present in every successful guide). **Tables for naming conventions** are the one context where they outperform prose — communicating in 10 lines what takes 50 in prose. **Imperative, specific rules** achieve near-perfect AI compliance versus vague guidance. **Progressive disclosure** (tiny root file referencing detailed sections) respects the ~150-instruction LLM budget while keeping comprehensive standards accessible. The **"base + exceptions" pattern** for per-language sections keeps each under 200 lines by leveraging authoritative external guides.

## 8. Recommended enforcement strategy

### What to automate (don't put in the standards document)

Everything a deterministic tool can handle should be automated and excluded from the AI-facing standards document. HumanLayer's research is direct: "Never send an LLM to do a linter's job. LLMs are comparably expensive and incredibly slow compared to traditional linters and formatters."

- **Formatters** (Prettier, Black, gofmt, rustfmt, clang-format): All whitespace, indentation, brace placement, line length, import ordering. Configure once, never discuss again.
- **Linters** (ESLint, Ruff, clippy, golangci-lint): Unused variables, basic naming patterns, deprecated APIs, simple code smells, type safety (no `any`), security patterns (no hardcoded secrets).
- **Pre-commit hooks**: Run formatters + fast linting on staged files. Keep under 5 seconds. Use the `pre-commit` framework or Husky/Lefthook.
- **CI quality gates**: Full linting, test suite, coverage thresholds, security scanning (CodeQL, Bandit, Snyk). Block merge on failures. Use SonarQube's "Clean As You Code" — strict gates on new code, progressive improvement on legacy.
- **AI slop detection**: Tools like `deslop` can flag excessive comments, unnecessary defensive code, and debug artifacts in CI.

### What to express as standards (requires AI/human judgment)

The standards document should focus exclusively on decisions that require judgment — the ~20–30% of conventions that automation cannot enforce:

- **Naming intent**: Whether a name communicates its purpose (not just whether it matches a regex pattern)
- **Error handling strategy**: When to use which error pattern, error categorization, recovery approaches
- **Architecture patterns**: Component structure, module boundaries, dependency direction
- **API design**: Consistency, resource naming, response formats
- **Code organization**: When to extract functions, appropriate abstraction level
- **Anti-patterns**: AI-specific issues (verbose code, hallucinated APIs, unnecessary comments)
- **Technology choices**: "Use X not Y" with version pins — the single most impactful rule for AI compliance
- **Testing depth**: What scenarios to cover, when to use mocks vs. real implementations

### The four-layer enforcement architecture

1. **IDE/Editor** (real-time): SonarLint, ESLint plugins, language server feedback — instant, zero-friction
2. **Pre-commit hooks** (local, <5s): Formatting + fast linting on staged files
3. **CI pipeline** (comprehensive): Full linting, tests, coverage, security scans, AI slop detection
4. **Human review** (irreplaceable): Architecture, business logic, cross-service impact, design quality

This layered approach means the AI-facing standards document needs to cover only layer 4 concerns — everything else is already handled before a human ever sees the code.

## 9. Knowledge gaps and areas needing further research

**Quantitative AI compliance measurement is almost nonexistent.** While there is extensive practitioner reporting and some academic research on AI code quality, no study has systematically measured how well LLMs follow specific types of coding standards with controlled experiments. The "150–200 instruction" finding from HumanLayer is based on observed behavior, not rigorous benchmarking. A controlled study varying rule format (prose vs. examples vs. tables), specificity level, and document length while measuring compliance rates would be enormously valuable.

**Cross-model variation is underexplored.** Most research focuses on GPT-4/Claude individually. How the same standards document performs across Claude, GPT-4, Gemini, and open-source models (Llama, DeepSeek) is unclear. The MSR '26 study found TypeScript dominated cursor rules repos (51%), suggesting findings may not generalize well to Python, Go, or Rust ecosystems.

**Long-term standards evolution with AI is uncharted.** How should standards documents adapt as AI models improve? Rules that were necessary for GPT-3.5 may be unnecessary for Claude 4. No framework exists for systematically retiring standards that AI has "learned" versus maintaining those it consistently struggles with.

**The interaction between CLAUDE.md, system prompts, and tool-specific features is poorly documented.** HumanLayer discovered that Claude Code wraps CLAUDE.md content with a system reminder telling Claude to ignore content it deems irrelevant — but the exact mechanism and threshold for "relevance" is opaque. How standards files interact with tool-specific context injection (Cursor's auto-attached rules, Aider's conventions loading, Claude's skills system) needs more investigation.

**Security-specific standards for AI-generated code lack mature benchmarks.** The OpenSSF guide establishes that "providing security hints in instructions improves code safety," but optimal phrasing, placement, and coverage of security rules for AI-assisted development remain an open research area. The 2.74x increase in XSS vulnerabilities in AI code demands more rigorous security-focused standards research.

**Mutation testing as a standard is promising but undervalidated.** While multiple testing authorities recommend mutation testing for validating AI-generated tests (which are prone to tautological assertions), practical guidance on mutation score thresholds, CI integration approaches, and performance trade-offs for large codebases is sparse. Stryker/PIT defaults exist but lack empirical validation at scale.