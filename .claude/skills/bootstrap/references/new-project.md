# New Project Setup (Path B)

Reference loaded by `/bootstrap` when no existing source files are detected.

## Flow Overview

```
Phase 0: CAPTURE → Phase 1: ANALYZE → Phase 2: DISCOVER → Phase 3: SYNTHESIZE → Phase 4: GENERATE
```

- **Fast-track:** description + "just build it" → skip to Phase 4, LLM makes all decisions
- **Guided:** full discovery with questions at each dimension → all phases
- **Braindump:** user pre-wrote vision files → skip Phase 0 questions, start Phase 1

## Phase 0: Idea Capture

### Check for Existing Vision Content

```bash
ls vision/ 2>/dev/null
```

**If `vision/` has content beyond templates** (README.md, BRAINDUMP_PROMPT.md, CLAUDE.md): Parse existing `.md` files and extract problem, users, features, technical preferences, constraints → Phase 1.

**If empty or templates only:** Present entry options.

### Entry Options

```markdown
### New Project Setup

No existing codebase detected. Let's build your project from an idea.

1. **Describe your idea** — I'll ask a few questions to understand it fully
2. **I already wrote a vision** — I'll check the `vision/` folder for your notes
3. **Just build it** — Give me a one-liner and I'll make all the decisions
```

### Inline Description (Option 1)

1. Accept the user's description (any length, any format)
2. Assess which of these are addressed: problem/purpose, target users, key features, technical preferences, scale/timeline
3. Ask up to **5 focused questions** for the top gaps — adapt to what's missing:
   - Problem unclear → "What problem does this solve? Describe it as if telling a friend."
   - Users unclear → "Who will use this? Describe your typical user in one sentence."
   - Features unclear → "What are the 3 most important things it needs to do?"
   - No tech preferences → "Do you have any technology preferences, or should I choose?"
   - Scale unknown → "How many users do you expect in the first 3 months?"
4. **Stop after 5 questions maximum.** Users abandon after 5.

### Braindump File (Option 2)

Parse all `.md` files in `vision/` and extract: problem statement, target users, proposed features, technical preferences, constraints. Treat as inline description with pre-filled answers.

### Fast-Track (Option 3)

Triggered by: user says "just build it" / "fast-track" / "quick" / "skip questions", OR `$ARGUMENTS` includes `--fast`.

1. Record the raw idea
2. Mark all dimensions as "auto-decide"
3. Jump directly to Phase 4 — LLM makes all decisions with documented assumptions
4. Present summary of auto-decided choices for quick approval before generating

### Completeness Assessment

After capture, classify the idea:
- **Complete** (problem + users + features + 4 more aspects addressed) → Phase 1
- **Partial** (problem + 2-5 other aspects) → ask focused questions for top gaps → Phase 1
- **Minimal** (just a sentence or two) → ask more questions OR offer fast-track

### Output

Save to `vision/idea-capture.md`:
```yaml
---
captured: YYYY-MM-DD
mode: inline | braindump | fast-track
completeness: complete | partial | minimal
---
```
Followed by: raw input, Q&A transcript, and extracted dimension status (KNOWN/INFERRED/OPEN per dimension).

**All user-facing text must be jargon-free.** No "dimensions", "phases", "sprint", "TDD", "PR", "ORM".

## Phase 1: Idea Analysis

Read `references/phase-1-analysis.md` and follow its steps.

Phase 1 classifies the project type, runs competitive landscape research, and decomposes the idea into addressable dimensions — marking each as KNOWN (user specified), INFERRED (derivable from input), or OPEN (needs user decision).

**Output:** `vision/analysis.md` with project type, competitive findings, and dimension status map.

## Phase 2: Dimension Discovery

Read `references/discovery-engine.md` and follow the iteration loop.

Phase 2 walks through each OPEN or INFERRED dimension, presents research-backed options, and records the user's choice. Dimension content modules live in `references/dimensions/`.

**Skip when:** Fast-track mode (all dimensions auto-decided).

**Output:** `vision/discovery.md` with per-dimension decisions.

## Phase 3: Vision Synthesis

### Contradiction Detection

Check all decisions for incompatible combinations:

| Combination | Issue |
|-------------|-------|
| Next.js + non-Node hosting | Framework requires Node.js runtime |
| SQLite + serverless | No persistent filesystem in serverless |
| "1M users" + free tier hosting | Free tiers cap at ~10K-100K monthly |
| "Offline required" + server-rendered | SSR needs server; offline needs client-side |
| Supabase Auth + non-Supabase database | Supabase Auth works best with Supabase |
| Mobile app + web-only deployment | Need native/cross-platform framework |

Present contradictions with explanation and suggested resolution. Let user choose.

### Generate Vision Document

Create `vision/project-vision.md` with YAML frontmatter (project, type, profile, date, discovery_mode) and sections:

1. **The Problem** — from dimension 1
2. **Target Users** — persona cards from dimension 2
3. **Features (MVP)** — tiered feature list from dimension 3
4. **Design Direction** — UX choices from dimension 4
5. **Technology Stack** — frontend, backend, database, auth, hosting from dimensions 5-9
6. **Business Model** — from dimension 10
7. **Decisions Log** — all choices with rationale (including auto-filled)
8. **Research Sources** — all URLs from dimension research

### Present for Approval

Show a one-screen summary:

```markdown
### Your Project at a Glance

**[Name]** — [one-line description]

**Building for:** [primary persona]
**MVP features:** [3-5 bullet points]
**Tech:** [frontend] + [backend] + [database] on [hosting]
**Auth:** [provider]
**Style:** [design direction]

Does this look right? I can change any aspect, or we can start building.
```

User can go back to any dimension. After approval → Phase 4.

## Phase 4: Epic Generation

### Generate PRD

Create `docs/reference/PRD_SUMMARY.md` from the vision document. Map dimensions to PRD sections:
- Problem & users → Sections 1-2
- Features & MVP → Section 5 (requirements with Given/When/Then acceptance criteria)
- UX/design → Section 6 (NFRs, design constraints)
- Business model → Section 3 (success criteria)
- Technical decisions → Section 8 (technical context)

**PRD quality gate:** Check for vague terms ("fast", "user-friendly" without numbers), missing error handling, thin AC (<3 per requirement), premature solutioning, empty NFR section, no non-goals. Fix smells before presenting.

### Generate Epics

Organize by delivery phase:

- **E01: Project Foundation** — Initialize framework, configure database schema, set up auth, configure CI/CD, development environment
- **E02: Core MVP Features** — Dependency-ordered feature stories from dimension 3 must-have tier
- **E03: Design & Polish** — Apply design direction, responsive design, error states, loading indicators
- **E04: Launch Preparation** — Production deployment, domain, analytics, feedback mechanism

Stories must: fit single context window (≤5 files, 1-3 hours), use template from `ideate/references/story-template.md`, reference personas from dimension 2, have machine-verifiable acceptance criteria.

### Generate Scaffold

From technology choices, generate:
- `CLAUDE.md` — commands for chosen stack, profile, architecture overview
- `.gitignore` — stack-specific patterns
- `docs/reference/CODING_STANDARDS.md` — for chosen language(s)
- `docs/architecture/ARCHITECTURE.md` — proposed architecture
- `docs/reference/GROUND_RULES.md` — 3-5 default rules for chosen stack

**Profile-aware generation:**
- Lean: CLAUDE.md with commands only, ~12 core skills in table, minimal docs
- Standard: full documentation suite
- Strict: full docs + compliance structure + audit trail scaffold

Also create `docs/research/`, `docs/solutions/`, `docs/brainstorms/` with `.gitkeep`.

### Present Summary

```markdown
### Bootstrap Complete (New Project)

**Discovery mode:** [full | partial | fast-track]

**Generated:**
- [N] epics, [M] stories
- Project scaffold: [framework] + [database] + [auth] on [hosting]
- Docs: CLAUDE.md, Architecture, Coding Standards, Ground Rules

**Epic Structure:**
| Epic | Stories | Description |
|------|---------|-------------|
| E01  | [count] | Foundation   |
| E02  | [count] | Core MVP     |
| E03  | [count] | Polish       |
| E04  | [count] | Launch       |

**First sprint:** E01 foundation (project setup, database, auth, CI/CD)

**Next:** Review epics in `docs/reference/backlog/`, then `/sprint-start`
```
