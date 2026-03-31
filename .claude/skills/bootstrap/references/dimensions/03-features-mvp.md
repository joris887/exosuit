# Dimension 3: Key Features & MVP Scope

## Introduction

"Let's decide what this thing actually does — and equally important, what it does NOT do yet. Getting the MVP scope right is the difference between launching in weeks versus never launching."

## When This Dimension Is OPEN

Ask: "What are the main things a user should be able to do? List as many as come to mind — we'll prioritize together."

## Feature Tiering

After collecting features, present them in three tiers:

```markdown
### Must Have (MVP)
These are the core features. Without them, the product doesn't solve the problem.
- [ ] [Feature] — [one-line description] *(Simple/Moderate/Complex)*

### Should Have (V1)
Important features that make the product competitive. Build after MVP is proven.
- [ ] [Feature] — [description] *(complexity)*

### Nice to Have (V2+)
Differentiators and polish. Build when there's traction.
- [ ] [Feature] — [description] *(complexity)*
```

**Propose the tier assignment** based on:
- Competitive research (Phase 1): what do competitors all have? → likely MVP
- Primary persona's key need: features that directly address it → MVP
- Technical dependencies: features that others build on → MVP
- Everything else: V1 or V2+

**Complexity indicators** (in plain English):
- **Simple:** "A form that saves data — straightforward" (1-2 stories)
- **Moderate:** "Needs integration work — connecting to an external service" (3-5 stories)
- **Complex:** "Significant effort — real-time processing, complex algorithms" (5+ stories)

## User Can Adjust

"I've suggested which features to build first. You can move any feature between tiers. The goal is: what's the smallest version that's actually useful?"

Let user move features between tiers. If MVP has >7 features, gently suggest: "That's a lot for a first version. Which 3-5 are absolutely essential?"

## When This Dimension Is INFERRED

Present inferred features from the idea capture: "Based on your description, here are the features I identified. Did I miss anything? And which ones are essential for the first version?"

## Output

Record:
- **MVP features:** List with one-line descriptions and complexity
- **V1 features:** Same format
- **V2+ features:** Same format
- **MVP boundary rationale:** Why this cut

## Recommendation Logic

- If user's problem has a clear "core loop" (e.g., create invoice → send → get paid), the core loop is MVP
- If competitive research shows a baseline feature set, match it for MVP
- Auth/accounts are MVP only if the product requires per-user data
- Admin panels, analytics dashboards, and advanced settings are always V1+
- Payment/billing is V1 unless it IS the product
