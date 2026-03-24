# Markdown-based UAT tracking that AI agents can parse at scale

**The optimal format combines YAML front matter for machine-parseable metadata with structured markdown sections for human-readable test content.** This approach outperforms both dedicated test management tools (which lock data in proprietary databases) and plain spreadsheets (which lack structure for programmatic access). Research across TestRail, Zephyr, qTest, BDD frameworks, and AI parseability benchmarks converges on a specific design: a directory-per-feature structure with one markdown file per user story, using standardized heading levels and a six-status execution model. This format enables the `/claude-sense-check` batch verification pattern, scales to hundreds of test cases through file-system organization, and remains readable by both human testers and AI agents.

---

## 1. Executive summary

The JD-LLM Development Framework needs a UAT tracking format that serves three masters simultaneously: human testers running manual checks, automation scripts executing test cases, and AI agents batch-verifying code logic. Industry research reveals that the **seven fields actually used in practice** are test ID, title, priority, preconditions, steps, expected result, and status — everything else is contextual metadata that most teams ignore. TestRail, Zephyr, and qTest all converge on this core, despite offering dozens of additional fields.

For AI parseability, benchmarks from Improving Agents (2025) show **YAML achieves the best accuracy** for structured data across multiple LLM models, while **markdown uses 34–38% fewer tokens than JSON** — making the YAML-front-matter-plus-markdown-body pattern the clear winner. Testspace has already proven this pattern in production with GitHub-hosted test specifications. The BDD Given/When/Then format provides the ideal acceptance criteria structure because it maps directly to Arrange/Act/Assert and is natively understood by both business stakeholders and LLMs.

The recommendations below define a complete, implementable specification — field schema, status model, directory layout, traceability approach, and AI verification integration — all grounded in evidence from industry practice.

---

## 2. How the leading test management tools structure test cases

### TestRail's three-template model separates procedural from exploratory testing

TestRail organizes cases in a Project → Suite → Section → Test Case hierarchy. Its three default templates reveal what the industry considers distinct testing modes: **Test Case (Text)** for free-form preconditions/steps/expected-result, **Test Case (Steps)** for structured step-by-step with individual expected results per step, and **Exploratory Session** for mission-and-goals charters. The required fields across all templates are just **Title, Section, Template, Type, and Priority**. Steps and expected results are template-dependent optionals. TestRail's enterprise tier adds a review workflow (Draft → Review → Approved) for test case authorship, while execution uses Passed/Blocked/Retest/Failed/Untested plus up to three custom statuses.

The References field links to external issue trackers (Jira IDs), and parameterization supports data-driven testing via `%variable%` syntax with up to 500 variables per project. Custom fields cover String, Integer, URL, Checkbox, Dropdown, Multi-select, and Date types.

### Zephyr Scale bridges BDD and traditional approaches

Zephyr Scale distinguishes itself by supporting three test script types within the same tool: **Step-by-Step**, **Plain Text**, and **BDD (Gherkin)**. Its hierarchy is Project → Folders → Test Cases with execution organized through Test Plan → Test Cycle → Test Execution. Notable features include version control enabled by default (creating new test case versions selectable when adding to cycles), a call-to-test feature for modular test design, and custom fields configurable at project level without Jira admin involvement. Default test case statuses are Draft, Approved, and Deprecated.

### qTest adds approval gating before execution

qTest uses a Module → Test Case structure with an approval workflow that can **prevent execution of unapproved test cases** — a pattern relevant for regulated industries. Its status workflow (New → In Progress → Ready For Baseline → Baselined) emphasizes version control, auto-incrementing version by 0.1 on each save. qTest's "Custom Test Steps" feature (since v11.2) allows up to two additional custom columns per step, enabling structured test data within step definitions.

### Which fields actually get used — evidence from practitioners

Cross-referencing tool defaults with practitioner evidence reveals a stark gap between available and utilized fields:

- **Always used (7 fields):** ID, Title, Priority, Preconditions, Steps, Expected Result, Status
- **Used when scaling:** Section/Category, Requirement References, Assigned To, Type tag
- **Rarely filled accurately:** Time Estimate, Milestone, Automation Status, Post-conditions, Version

Testmo's guidance captures the consensus: "The quality of a test case doesn't depend on the number of fields you fill out." The Bright Inventions practitioner blog adds: "A team could write even up to hundreds of test cases and nobody has time to keep them up-to-date." James Bach's critique is more pointed: "Test cases are a poor basis for organizing a test process." TestLodge recommends: "If a field rarely gets used, it doesn't belong in the template."

The implication for the JD-LLM template: **keep the required fields minimal and make everything else optional metadata in YAML front matter** so it exists for tools that need it without cluttering the human view.

---

## 3. BDD format and test case design patterns that inform the template

### Given/When/Then maps naturally to acceptance criteria and AI verification

Cucumber's Gherkin syntax structures test scenarios as Feature → Rule → Scenario with Given/When/Then steps. Tags (`@smoke`, `@regression`, `@P1`) enable filtering, and Scenario Outlines with Examples tables support data-driven testing. Background sections define shared preconditions. The format's key advantage for UAT: **natural language readable by business stakeholders** while simultaneously being **structured enough for automated execution and AI parsing**.

Over **60% of agile teams** adopted BDD practices as of the 2024 World Quality Report. The primary limitation for UAT is verbosity in complex multi-step workflows and the constraint that each `When` clause should contain only a single trigger action.

### Scenario-based vs step-based: context determines the right granularity

Step-based test cases (numbered actions with per-step expected results) work best in **regulated environments, onboarding contexts, and critical functionality requiring precise reproduction**. Scenario-based cases (high-level "what to test" descriptions) work for **agile teams with experienced testers and exploratory workflows**. The evidence-based recommendation: use scenario-based structure as the default and switch to step-based only for complex, multi-step workflows where order matters.

### Decision tables and boundary analysis deserve documentation slots

Decision tables systematically cover business rule combinations (one test per column in a conditions × actions matrix). State transition testing traces paths through system states. Equivalence partitioning and boundary value analysis target input ranges. These techniques are best documented as **structured test data within or alongside test cases** rather than as separate artifacts. The template should accommodate these via an optional Test Data section.

### Exploratory testing charters follow Elisabeth Hendrickson's model

The established charter format — "Explore [target] With [resources] To discover [information]" — should be supported as an alternative test type. Session-Based Test Management (SBTM) uses timeboxed charters with task breakdown, test notes, charter-vs-opportunity time tracking, and issue flagging.

---

## 4. Traceability — when it's worth it and how to keep it lightweight

### RTMs are essential for regulated industries but unsustainable as manual spreadsheets

A Requirements Traceability Matrix maps requirements → test cases → code → defects across three types: Forward (every requirement has tests), Backward (every test serves a requirement), and Bi-directional (both). The evidence is clear that **bi-directional traceability is justified for regulated industries** (banking SOX/PCI, healthcare FDA 21 CFR Part 11, aviation DO-178C) and **overkill for most agile product teams**.

The critical insight from multiple sources: manual RTM maintenance is universally acknowledged as unsustainable at scale. Jama Software notes RTMs become a "bottleneck in iterative environments." The agile alternative is **organic traceability through tool integration** — Jira issue IDs in test case references, commit message conventions, and CI/CD-embedded links.

### For the JD-LLM framework, traceability lives in YAML front matter

The lightweight approach maps perfectly to YAML front matter: each test case file contains a `story` field linking to the user story ID. A simple script can generate coverage reports by cross-referencing story IDs across all test files. This provides **forward traceability** (does every story have tests?) without maintaining a separate matrix artifact. The `requirements` array in front matter supports linking to specific acceptance criteria.

Coverage gap analysis then becomes: parse all test case YAML front matter, extract `story` fields, compare against the story backlog, and report stories without corresponding test files. This is trivially automatable and naturally stays in sync because the links live in the same files as the tests.

---

## 5. Test execution tracking — the right status model and what metrics matter

### A six-status model balances expressiveness with simplicity

Analyzing status models across TestRail (5 + 3 custom), Zephyr (5), QMetry (5+), and community best practices, the **minimum viable set for UAT** is:

| Status | Symbol | When to use |
|--------|--------|-------------|
| **Pass** | ✅ | Test produced expected result |
| **Fail** | ❌ | Test did not produce expected result |
| **Skip** | ⏭️ | Intentionally not executed this cycle |
| **Blocked** | 🚧 | Cannot execute due to dependency/environment |
| **Partial** | ⚠️ | Some steps pass, some fail, or pass with caveats |
| **Untested** | ⬜ | Not yet executed (default state) |

The Ministry of Testing community consensus favors four statuses (Pass/Fail/Blocked/Not Run), but the addition of **Skip** (intentional non-execution) and **Partial** (for complex UAT scenarios where partial credit matters) reflects real-world UAT needs. The `Partial` status avoids the need for teams to hack "Conditional Pass" statuses into tools, as TestLink and QMetry users frequently do.

### Execution history should be append-only within the test file

Each execution creates a new entry under a Results section in the markdown file, capturing: status, date, tester/agent identifier, build/version, and notes. This creates a **built-in audit trail** versioned by git, superior to database-stored history because every change is attributable and diffable. Closed test runs are "frozen" snapshots, matching TestRail's model.

### Five metrics that actually drive decisions

Research consistently identifies **defect escape rate** (defects reaching production divided by total defects, target <5%) as the single most valuable testing metric. Defect Removal Efficiency (defects found in testing divided by total, target >95%) measures testing thoroughness. Requirements Coverage (requirements with tests divided by total) reveals gaps. Test Case Effectiveness (defects found per test executed) shows whether tests catch bugs. Pass Rate provides sprint-level health. Everything else — total tests executed, number of test cases, raw bug counts — is vanity metrics that shows activity without indicating quality.

### Risk-based prioritization belongs in the test case metadata

The PRISMA approach (Product RISk MAnagement) places test items in a 2×2 matrix of Impact × Likelihood. For the markdown template, this translates to a `priority` field in YAML front matter with values `critical`, `high`, `medium`, `low` derived from risk assessment. Research shows risk-based testing **cuts low-risk testing by 40% while achieving 95% defect coverage** and detects critical defects **35% faster** than traditional methods.

---

## 6. AI-assisted testing — how LLMs verify code logic and what formats they parse best

### LLM code verification is production-ready but requires structured input

Meta's TestGen-LLM achieved **73% acceptance rate** from engineers for AI-generated test improvements. Thoughtworks found AI achieves **98.67% acceptance criteria coverage** when generating test cases from well-structured user stories, but with a **27.22% ambiguity rate** — roughly one in four generated tests needs human clarification. Airbnb migrated **3,500 test files in 6 weeks** using LLMs, down from an estimated 1.5 years manually, using a state-machine pipeline with automated retry loops and rich context prompts of 40,000–100,000 tokens.

The key limitation: **business logic validation remains weak**. LLMs excel at structural verification (does the code handle the happy path described in the test case?) but struggle with domain-specific rules that aren't explicitly stated. This means the `/claude-sense-check` command should focus on verifying that code **implements what the test cases describe** rather than validating the completeness of the test cases themselves.

### YAML + markdown is the empirically optimal format for AI parsing

Improving Agents (2025) benchmarked structured data formats across GPT-5 Nano, Llama 3.2 3B, and Gemini 2.5 Flash Lite on 1,000 questions each. **YAML performed best for accuracy** (2 of 3 models), while **markdown was the most token-efficient** (34–38% fewer tokens than JSON, ~10% fewer than YAML). XML required 80% more tokens with poor accuracy. The recommendation: **YAML front matter for metadata, markdown body for content** — maximizing both accuracy and token efficiency.

AI coding agents already standardize on markdown configuration: Claude Code reads `CLAUDE.md`, Codex CLI reads `AGENTS.md`, Gemini CLI reads `GEMINI.md`, and Copilot reads `copilot-instructions.md` with YAML front matter for glob-pattern matching. The test case format should follow this established convention.

### The multi-agent verification pattern matches industry direction

The emerging 2026 pattern is multi-agent review workflows: "One agent writes, another critiques, another tests, and another validates compliance." This maps directly to the JD-LLM framework where `/story-cycle` generates test cases, `/UAT-cycle` executes them, and `/claude-sense-check` verifies code logic. Claude Code's subagent architecture (dedicated `.claude/agents/test-verifier.md` files) supports this pattern natively.

---

## 7. UAT process practices from regulated industries set the quality bar

### Banking demands 100% critical scenario pass rates with full audit trails

Banking UAT runs **4–8 weeks** with an 8-step framework: Requirement & Risk Mapping → Strategy & Governance → Production-Like Environment → Business-Centric Scenario Design → Execution by Business Users → Defect Risk Assessment → Regulatory & Audit Validation → Go-Live Readiness & Sign-Off. Entry criteria include SIT sign-off and critical defects resolved. Exit criteria demand **100% critical scenarios passed and zero open Sev-1 issues**. Documentation is scrutinized by internal audit and regulatory examiners per OCC 2011-12.

### Healthcare adds GAMP 5 risk-based validation tiers

FDA 21 CFR Part 11 requires validated systems with ALCOA+ audit trails (Attributable, Legible, Contemporaneous, Original, Accurate). The GAMP 5 lifecycle differentiates testing depth by risk: high-risk items get robust scripted testing, medium-risk gets moderate assurance, low-risk can be covered by configuration checks or UAT. The ePRO Consortium published peer-reviewed UAT best practices requiring UAT plans with purpose, scope, strategy, risk assessment, team roles, test environment info, test cases, and approval signatures.

### Common exit criteria across industries

The general practice threshold is **≥95% of test cases executed, all critical tests passed, and zero open P0/P1 defects**. Microsoft's Dynamics 365 UAT framework requires formal business sign-off before deployment, with UAT scripts documenting system URL, security roles, tester name, date, functional area, scenario, steps, expected result, actual result, and pass/fail status.

---

## 8. Recommended test case format

Based on all research, here is the recommended format for individual test cases within a story file. The format uses YAML front matter for all machine-parseable metadata and structured markdown sections for test content.

### YAML front matter schema

```yaml
---
id: UAT-{STORY_ID}                # Auto-derived from story ID
story: STORY-123                   # Links to user story (traceability)
title: "User login authentication" # Human-readable test suite title
feature: authentication            # Feature/module grouping
priority: critical                 # critical | high | medium | low (risk-based)
status: in-progress                # draft | active | in-progress | complete | deprecated
tags: [smoke, regression, sprint-42]  # Flexible categorization
created: 2026-03-15
updated: 2026-03-24
coverage:                          # Acceptance criteria covered
  - AC1: User can log in with valid credentials
  - AC2: Invalid credentials show error message
  - AC3: Account locks after 5 failed attempts
---
```

**Field justification:** Every field maps to an evidence-backed need. `id` and `story` enable traceability without a separate RTM. `priority` supports risk-based test selection (PRISMA quadrant mapping). `status` tracks the test case lifecycle (not execution — that lives in the body). `tags` replace TestRail's Type field with flexible categorization. `coverage` maps acceptance criteria for gap analysis. Fields like Estimate, Milestone, and Assigned To are deliberately excluded — practitioners consistently report ignoring them.

### Markdown body structure

```markdown
# {title}

> **Story:** {story} | **Priority:** {priority} | **Last Run:** {date}

## Setup
<!-- Shared preconditions for all test cases in this file -->
- Valid test user account exists (user@test.com / TestPass123)
- Browser cleared of cached sessions
- Environment: staging (https://staging.example.com)

## TC-001: Valid login redirects to dashboard
**Priority:** critical | **Type:** positive

**Given** a registered user on the login page
**When** they enter valid credentials and click Sign In
**Then** they are redirected to `/dashboard` within 3 seconds

**Test Data:**
| Input | Value |
|-------|-------|
| Email | user@test.com |
| Password | TestPass123 |

### Results
<!-- Append-only execution log -->
| Status | Date | Verified By | Build | Notes |
|--------|------|-------------|-------|-------|
| ✅ Pass | 2026-03-24 | @claude-sense-check | v2.5.1 | Code logic verified |
| ✅ Pass | 2026-03-20 | @jane | v2.5.0 | Manual verification |

## TC-002: Invalid password shows error message
**Priority:** critical | **Type:** negative

**Given** a registered user on the login page
**When** they enter an incorrect password and click Sign In
**Then** the error message "Invalid credentials" is displayed
**And** the password field is cleared

### Results
| Status | Date | Verified By | Build | Notes |
|--------|------|-------------|-------|-------|
| ⬜ Untested | - | - | - | - |

## TC-003: Account locks after 5 failed attempts
**Priority:** high | **Type:** security

**Given** a registered user on the login page
**When** they enter wrong passwords 5 consecutive times
**Then** the account is locked with message "Account locked. Try again in 30 minutes."
**And** valid credentials are rejected until timeout expires

### Results
| Status | Date | Verified By | Build | Notes |
|--------|------|-------------|-------|-------|
| ❌ Fail | 2026-03-20 | @john | v2.5.0 | Locks after 3 attempts, not 5. Bug: #1234 |

## Teardown
- Log out of active sessions
- Reset account lockout status via admin API
```

### Status model specification

The six statuses with their emoji markers enable both visual scanning and regex-based parsing:

- `✅ Pass` — test produced expected result
- `❌ Fail` — test did not produce expected result (must include notes)
- `⏭️ Skip` — intentionally not executed this cycle (must include reason)
- `🚧 Blocked` — cannot execute due to dependency/environment issue
- `⚠️ Partial` — some criteria met, others not (must include details)
- `⬜ Untested` — default state, not yet executed

For AI parsing, the text after the emoji (`Pass`, `Fail`, etc.) is the canonical status value. The emoji serves as a visual accelerator for human readers. A regex like `/^[|]\s*(✅|❌|⏭️|🚧|⚠️|⬜)\s*(Pass|Fail|Skip|Blocked|Partial|Untested)/` extracts status from results tables.

---

## 9. Recommended tracking structure at scale

### Directory layout mirrors feature architecture

```
uat/
├── _index.md                    # Auto-generated dashboard/summary
├── _config.yml                  # Status emoji definitions, priority levels
├── authentication/
│   ├── _index.md                # Feature-level summary
│   ├── STORY-123-user-login.md  # One file per story
│   ├── STORY-124-password-reset.md
│   └── STORY-125-sso-integration.md
├── payments/
│   ├── _index.md
│   ├── STORY-200-checkout-flow.md
│   └── STORY-201-refund-processing.md
├── admin/
│   ├── _index.md
│   └── STORY-300-user-management.md
└── exploratory/
    ├── EXPLORE-001-new-dashboard.md  # Charter-based sessions
    └── EXPLORE-002-mobile-responsive.md
```

**Design rationale:** One file per story keeps test cases co-located with their acceptance criteria and prevents merge conflicts when multiple testers work in parallel. Feature directories mirror the product architecture so developers intuitively find relevant tests. The `_index.md` files at each level provide roll-up summaries. The `exploratory/` directory accommodates charter-based testing sessions using the Hendrickson format.

**Naming convention:** `{STORY-ID}-{slug}.md` enables both human navigation and programmatic lookup by story ID. Files are sorted by story ID within directories.

### The `_index.md` dashboard is auto-generated

The root `_index.md` aggregates status across all test files, generated by parsing YAML front matter and results tables:

```markdown
# UAT Dashboard — v2.5.1

**Generated:** 2026-03-24 14:30 UTC

## Summary
| Metric | Value |
|--------|-------|
| Total Test Cases | 147 |
| ✅ Pass | 118 (80.3%) |
| ❌ Fail | 8 (5.4%) |
| 🚧 Blocked | 3 (2.0%) |
| ⬜ Untested | 18 (12.2%) |

## Coverage Gaps
Stories without test cases: STORY-155, STORY-162, STORY-178

## Critical Failures
- **STORY-123 TC-003**: Account lockout threshold wrong (#1234)
- **STORY-200 TC-002**: Payment timeout not handled (#1237)
```

This dashboard generation can run as a pre-commit hook, CI step, or be triggered by the `/testing-cycle` command.

### Scaling characteristics

This structure handles scale through file-system properties: **hundreds of test cases distribute across dozens of files** (typically 3–8 test cases per story file), git handles merges at the file level, and directory listing provides feature-level overview. A project with 500 test cases across 100 stories in 15 features produces approximately 115 markdown files — well within the comfortable range for any file system, editor, or AI context window.

---

## 10. Recommended traceability approach

### Story-level traceability through YAML front matter replaces the RTM

Instead of maintaining a separate Requirements Traceability Matrix, traceability is embedded in each test file's `story` field and `coverage` array. This provides:

- **Forward traceability** (requirement → tests): Script scans all `story` fields, compares against backlog, reports stories without test files
- **Backward traceability** (tests → requirement): Each test file's `story` field links directly to its originating story
- **Coverage mapping** (acceptance criteria → test cases): The `coverage` array maps specific ACs to the test cases below

**A simple traceability report script:**
```
For each story in backlog:
  Find test files where front-matter.story == story.id
  For each acceptance criterion in story:
    Check if criterion appears in any test file's coverage array
  Report: stories without tests, ACs without coverage
```

This approach avoids the maintenance overhead that makes traditional RTMs unsustainable while providing the same analytical value. The traceability data is **always in sync** because it lives in the test files themselves and is version-controlled alongside code.

### Code-level traceability through commit conventions

For story → test → code mapping, follow the established convention: commit messages reference story IDs (`STORY-123: Implement login endpoint`), test files reference story IDs via front matter, and code files can be searched by story ID in git log. This creates a **three-point traceability chain** without any manual matrix maintenance.

### When to add heavier traceability

The embedded approach is sufficient for most agile teams. Add a formal RTM artifact only when: an external audit requires a standalone traceability document (banking SOX, healthcare FDA), the team exceeds ~50 concurrent stories with cross-cutting concerns, or a regulatory framework explicitly mandates bi-directional traceability documentation.

---

## 11. Recommended AI verification integration

### How `/claude-sense-check` should batch-process test files

The verification flow exploits the structured format:

1. **Discovery:** Scan `uat/` directory for all `.md` files with YAML front matter
2. **Parse:** Extract front matter metadata (story, priority, coverage) and body content (test cases with Given/When/Then)
3. **Prioritize:** Process `critical` priority tests first, then `high`, then `medium`/`low`
4. **Verify per test case:** For each test case, read the corresponding source code implementation and check:
   - Does the code implement the behavior described in the Given/When/Then?
   - Are boundary conditions from test data tables handled?
   - Are error paths from negative test cases covered?
   - Does the code match the expected results stated in the test?
5. **Report:** Update the Results table in each test file with a new row, or generate a verification summary

### Structured output for verification results

The AI agent should output verification results in a parseable format:

```yaml
verification:
  file: uat/authentication/STORY-123-user-login.md
  build: v2.5.1
  date: 2026-03-24
  results:
    - test_id: TC-001
      status: pass
      confidence: high
      notes: "Login endpoint returns 302 redirect to /dashboard on valid credentials"
    - test_id: TC-003
      status: fail
      confidence: high
      notes: "MAX_ATTEMPTS constant set to 3 in auth.config, test expects 5"
      code_reference: "src/auth/lockout.js:42"
```

This maps to Qodo's and Phil Schmid's recommended pattern of using typed schemas (Pydantic BaseModel or equivalent) for LLM structured output, constraining verification responses into parseable results.

### What AI verification can and cannot do

Based on the research evidence, AI verification is **strong** at: confirming code implements described happy paths, detecting constant/threshold mismatches between tests and code, identifying missing error handling for documented negative cases, and flagging untested code branches that test cases reference.

AI verification is **weak** at: validating business logic correctness (the AI doesn't know if 5 attempts is the right lockout threshold — only that code says 3 and test says 5), catching race conditions or timing-dependent behavior, verifying UI rendering or visual correctness, and assessing non-functional requirements like performance. The `/claude-sense-check` documentation should explicitly state these boundaries so teams don't develop false confidence.

### Prompt structure for batch verification

Each test case should be verifiable with a prompt pattern like:

```
Given this test case:
[YAML front matter + Given/When/Then from test file]

And this implementation code:
[Relevant source files identified by story ID or feature path]

Verify: Does the code implement the behavior described in each
Given/When/Then clause? Report any mismatches between expected behavior
in the test and actual behavior in the code. Output results as structured
YAML with test_id, status (pass/fail/unclear), confidence (high/medium/low),
and notes explaining your finding.
```

Airbnb's experience shows that **brute-force retries with error feedback outperform sophisticated prompt engineering** — if a verification result has low confidence, re-running with additional context files (up to 50 related files, 40K–100K tokens) is more effective than prompt tuning.

---

## 12. Knowledge gaps and open questions

Several areas lack definitive evidence or established best practices:

**AI verification accuracy at scale.** While Meta's TestGen-LLM and Airbnb's migration provide strong case studies, no published research specifically measures AI verification accuracy for UAT test cases against implementation code across diverse codebases. The **27.22% ambiguity rate** from Thoughtworks' experiment suggests roughly one in four AI-generated findings may need human review, but this was for test generation, not verification. Verification accuracy likely differs.

**Optimal file granularity.** The one-file-per-story recommendation is based on merge-conflict avoidance and cognitive grouping, but no empirical study compares it against one-file-per-test-case or one-file-per-feature for AI agent processing efficiency. Context window management with hundreds of small files versus dozens of medium files presents different trade-offs.

**Results table durability under heavy editing.** Markdown tables are the weakest part of this format — they're rigid, merge-conflict-prone, and can't embed rich content. The append-only results log will accumulate rows over time. Whether this causes practical problems at 20+ executions per test case is untested. An alternative would be moving execution history to a separate `_runs/` directory, but this breaks co-location.

**Cross-story test cases.** The format assumes each test case maps to one story. End-to-end UAT scenarios that span multiple stories (e.g., "user registers, logs in, makes purchase, receives email") don't fit cleanly into a single story file. BDD's atomic scenario constraint makes this worse. A dedicated `e2e/` directory may be needed, with multi-story front matter arrays, but this complicates traceability.

**Exploratory testing integration.** The charter format (Explore/With/Discover) is structurally different from structured test cases. While the `exploratory/` directory accommodates this, the AI verification pattern doesn't apply well to unscripted sessions. How `/claude-sense-check` should handle exploratory findings — or whether it should skip them — needs framework-level definition.

**Long-term maintenance cost.** Testspace has proven the markdown-based model works, but their documentation doesn't address what happens after 2+ years of accumulated test cases, deprecation patterns, and historical cruft. The `deprecated` status in the front matter schema provides a mechanism, but archival and cleanup practices remain undefined.