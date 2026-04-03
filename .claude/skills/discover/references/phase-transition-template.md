# Phase Transition Stories

The last epic in every batch. NOT code stories — guided conversations using the "Review" story type in `/story-cycle`. Creates the infinite build→review→discover→build cycle.

## E0N-REVIEW: Phase Transition

### E0N-001: MVP/Phase Walkthrough
**Type:** Review

Walk through every built feature with user. Per feature ask:
- "Does this match what you expected?"
- "What's missing that you assumed would be there?"
- "What surprised you (good or bad)?"
- "Importance 1-5 now that you've seen it working?"

**Acceptance Criteria:**
- [ ] Every built feature reviewed with user
- [ ] Deviation log created (expected vs actual)
- [ ] Feature importance re-ranked

**Output:** `docs/reviews/phase-N-walkthrough.md` (use `assets/phase-walkthrough.md` template)

---

### E0N-002: Assumption Validation Review
**Type:** Review

Go through `docs/reference/ASSUMPTION_REGISTER.md`. Per HIGH-impact assumption:
- "Based on what we built: VALIDATED, INVALIDATED, or STILL UNKNOWN?"
- If INVALIDATED: "What does this mean? What needs to change?"
- If STILL UNKNOWN: "What would we need to build/do to answer this?"

**Acceptance Criteria:**
- [ ] Every high-impact assumption updated
- [ ] Invalidated assumptions have documented implications
- [ ] Unknown assumptions have proposed validation experiments

**Output:** Updated `docs/reference/ASSUMPTION_REGISTER.md`

---

### E0N-003: Research Refresh
**Type:** Research

Run archetype-specific context research again (from `references/research-protocols.md` RC6):
- Has competitive/creative landscape changed?
- New tools/approaches that affect decisions?
- What are people saying about similar projects now?
- Technology updates affecting stack decisions?
- Archetype-specific: viral → "Anything similar go viral recently?"

**Acceptance Criteria:**
- [ ] Research report with findings
- [ ] Updated DECISION_LOG entries if any decisions affected

**Output:** `docs/research/phase-N-refresh.md`

---

### E0N-004: Pivot or Persevere Decision
**Type:** Review

Review success criteria from `references/engineering-by-archetype.md`. Present current status vs targets. Apply decision framework:
- **SCALE:** Metrics met → optimize and grow
- **PERSEVERE:** Not proven but not failed → more experiments
- **PIVOT:** Below fail condition → change direction
- **KILL:** No ideas + no runway → stop

**Acceptance Criteria:**
- [ ] Success criteria evaluated with evidence
- [ ] Direction decision documented with rationale

**Output:** `docs/reviews/phase-N-direction.md`

---

### E0N-005: Next Phase Elicitation
**Type:** Discovery

Based on direction from E0N-004:
- **SCALE:** "What would make users LOVE this? Tell others?" + research growth patterns for this archetype
- **PERSEVERE:** "What experiments validate our unknowns?" + generate spike stories per unvalidated assumption
- **PIVOT:** Run Phases 1-3 of /discover with new direction

**Acceptance Criteria:**
- [ ] Next-phase vision document created
- [ ] New assumptions identified and registered
- [ ] Draft epic structure for next phase

**Output:** `vision/phase-N+1-discovery.md`

---

### E0N-006: Next Phase Backlog Generation
**Type:** Planning

Generate next batch of epics from phase N+1 discovery. Each story has Decisions, Assumptions, No-Gos. **THE LAST EPIC IS AGAIN A PHASE TRANSITION EPIC** — this creates the infinite cycle.

**Acceptance Criteria:**
- [ ] New epics in BACKLOG_INDEX.md
- [ ] Phase Transition epic included as final epic
- [ ] All stories pass Definition of Ready

**Output:** New backlog entries + updated BACKLOG_INDEX.md

---

## Scale Adaptations

| Scale | Stories Included |
|---|---|
| **Quick Build** | E0N-001 + E0N-004 + E0N-006 (3 stories) |
| **Standard** | All 6 stories |
| **Platform** | All 6 + E0N-007: Architecture Review |
| **Pioneering (post-spike)** | E0N-001 + E0N-004 + full /discover re-entry |

### E0N-007: Architecture Review (Platform only)
**Type:** Review

Review architecture decisions against actual implementation. Check: did the architecture hold? What drift occurred? What needs updating? Review ARCHITECTURE.md against code reality.

**Acceptance Criteria:**
- [ ] Architecture doc verified against actual code
- [ ] Drift items documented
- [ ] ADRs updated or new ADRs proposed

**Output:** Updated `docs/architecture/ARCHITECTURE.md` + new ADRs if needed
