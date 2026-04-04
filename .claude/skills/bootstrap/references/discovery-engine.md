# Phase 2: Dimension Discovery Engine

Reference loaded by Path B Phase 2. Iterates through OPEN and INFERRED dimensions, presents options, and records user decisions.

## Dimension Ordering

Process dimensions in this order (product → design → technical → operational):

1. Core Problem & Vision (if OPEN)
2. User Personas & Impact (if OPEN)
3. Key Features & MVP Scope (if OPEN/INFERRED)
4. User Experience & Design (if OPEN)
5. Frontend Technology (if OPEN/INFERRED)
6. Backend Technology (if OPEN/INFERRED)
7. Data & Storage (if OPEN/INFERRED)
8. Authentication & Security (if OPEN/INFERRED)
9. Deployment & Infrastructure (if OPEN)
10. Business Model & Growth (if OPEN)

**Skip KNOWN dimensions** — user already decided. Show them in the progress bar as completed.

## Iteration Loop

For each applicable dimension where status is OPEN or INFERRED:

```
1. PRESENT dimension context
   "Now let's figure out [plain-English topic]. Here's what we know so far..."

2. LOAD dimension module from references/dimensions/[NN]-[name].md
   Module contains: questions, options, research queries

3. FOR TECHNICAL DIMENSIONS (5-9): Run quick research
   Compose deep-research at QUICK depth with the module's research query
   Include current year in query for up-to-date results

4. PRESENT 2-4 options
   Each with: plain-English description, pros, cons, real-world examples
   Include: "Pick for me" and "Tell me more about [option]" choices

5. HANDLE user response:
   - Selected an option → record decision, move to next dimension
   - "Tell me more about [X]" → deeper research on X, re-present options
   - "Pick for me" / "auto" → auto-select recommendation, record with "auto" flag
   - "Skip this" → mark as deferred, will generate spike story later
   - "Go back" → return to previous dimension
   - "Auto-fill the rest" → auto-decide all remaining OPEN dimensions

6. AFTER recording: check cross-dimension effects
   If choice constrains other dimensions, note the constraint
```

## Progress Indicator

Show after each dimension:

```markdown
Progress: ████████░░ 8/10 aspects decided
Next up: Where should your app run? (hosting)
```

Use plain language — "aspects" not "dimensions", "decided" not "resolved".

## Cross-Dimension Dependencies

When a choice in one dimension constrains another, apply the constraint and note it:

| If this is chosen... | Then constrain... | Because... |
|---------------------|-------------------|------------|
| Next.js (frontend) | Backend → Next.js API routes preferred | Same framework, zero extra setup |
| React + Vite (frontend) | Backend → separate server needed | Vite is frontend-only |
| Supabase (database) | Auth → Supabase Auth available | Included free with Supabase |
| Serverless hosting | Backend → must support serverless | No persistent server |
| Mobile app | Frontend → React Native/Flutter/etc. | Mobile requires native framework |
| "Passwordless only" (auth) | Remove password-based options | User preference |
| SQLite (database) | Hosting → not serverless | SQLite needs filesystem |
| "1M+ users" (scale) | Hosting → not free tier | Scale exceeds free limits |

When presenting options for a constrained dimension, note: "Based on your earlier choice of [X], these options work best."

## Option Presentation Format

Present options via **AskUserQuestion** (not as plain text). Each dimension's 2-4 options map directly to AskUserQuestion's format:

```
header: "[Dimension]"  // max 12 chars (e.g., "Frontend", "Database", "Auth")
question: "[Plain-English question about this dimension]. Select 'Other' to
           describe your own preference — more detail helps me pick the right
           technology for your needs."
options:
  - label: "[Recommended option] (Recommended)"
    description: "[What it is in plain English]. Used by [examples]. Best for
                  [when to choose]. Trade-off: [honest downside]. Cost: [pricing]."
  - label: "[Option B]"
    description: "[Same structure — what, used by, best for, trade-off, cost]"
  - label: "[Option C]"
    description: "[Same structure]"
```

**Use the `preview` field** for technical choices where visual comparison helps (e.g., file structure examples, config snippets, architecture diagrams).

For non-technical users, lead descriptions with plain-English analogies. For technical users, include version numbers and ecosystem details.

The "Other" option is auto-included by AskUserQuestion — it serves as the "Tell me more" and "I have a different preference" escape hatch. "Pick for me" / "You decide" → select the recommended option.

## INFERRED Dimension Handling

For INFERRED dimensions, confirm the inference via **AskUserQuestion**:

```
header: "[Dimension]"
question: "Based on your description, I'm planning to use [inferred choice]
           because [reason]. Does that sound right?"
options:
  - label: "Sounds good (Recommended)"
    description: "Continue with [inferred choice]. I'll configure everything
                  for this technology."
  - label: "Show me other options"
    description: "I want to see what else is available before deciding."
  - label: "I have a specific preference"
    description: "Select 'Other' and tell me what you'd prefer to use."
```

This is faster than presenting all options but still gives the user control.

## Recording Decisions

After each dimension, append to `vision/discovery.md`:

```yaml
## [Dimension Name]
status: decided | deferred | auto
choice: "[selected option]"
rationale: "[why — user-stated or auto-generated]"
alternatives_considered:
  - "[option 2] — not chosen because [reason]"
research_sources: [URLs if research was performed]
constraints_applied: ["frontend is React → Node.js preferred"]
```

## Batch Fast-Track

When user says "auto-fill the rest" or equivalent:

1. For each remaining OPEN dimension: auto-select the recommended option
2. For each remaining INFERRED dimension: confirm the inference
3. Record all with `status: auto`
4. Present a summary of all auto-decided choices: "I've made these choices for you: [list]. Any changes?"
5. Continue to Phase 3

## Dimension Module Interface

Each dimension module in `references/dimensions/` provides:

1. **Plain-English introduction** — what this dimension covers
2. **Questions to ask** (for OPEN dimensions) — plain English, no jargon
3. **Options to present** — 2-4 with pros/cons/examples
4. **Research query** (for technical dimensions) — what to search for current data
5. **Recommendation logic** — when to recommend which option
6. **Output fields** — what to record in the decision

Load only the module for the current dimension — do not preload all modules.
