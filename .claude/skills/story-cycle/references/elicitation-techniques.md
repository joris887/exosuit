# Elicitation Techniques

Structured questioning methods for discovery phases. Apply when you need to go deeper on requirements, design decisions, or constraints. Referenced by story-cycle Phase 1 depth exploration, brainstorm, ideate, and bootstrap.

**Usage:** When a skill phase says "apply an elicitation technique" or the user selects [D] at a depth check, choose the most relevant technique and follow its method.

---

## Technique: Assumption Surfacing

**When:** Planning phase reveals implicit assumptions about behavior, data, or integrations.
**Method:**
1. List 5 assumptions the current plan makes (e.g., "users have a single email", "API responses are under 100ms")
2. For each, ask: "What if this isn't true? What changes?"
3. Present findings as a table: Assumption | Risk if Wrong | Mitigation

**Output:** Validated or corrected assumptions integrated into the plan.

---

## Technique: Constraint Mapping

**When:** Non-functional requirements are unclear or unstated.
**Method:**
1. Walk through each constraint category with the user:
   - Performance targets (response time, throughput)
   - Security requirements (authentication, authorization, encryption)
   - Accessibility (WCAG level, screen reader support)
   - Browser/device support
   - Data volume and growth expectations
   - Uptime/availability SLA
2. For each: "Is there a specific target, or is 'reasonable' acceptable?"

**Output:** Explicit constraint list with thresholds added to acceptance criteria.

---

## Technique: Failure Mode Exploration

**When:** Error handling approach is unclear or only happy-path is specified.
**Method:**
1. For each component in the plan: "What happens when [X] fails?"
2. For each failure: "What should the user see? What should be logged? Should it retry?"
3. Categorize: recoverable (retry/fallback) vs. fatal (error page/notification)

**Output:** Error handling matrix added to implementation plan.

---

## Technique: Stakeholder Perspective Shift

**When:** Requirements seem one-dimensional or focused on a single user type.
**Method:**
1. Reframe the requirement from 3 perspectives:
   - **End user:** "What do I expect to happen? What confuses me?"
   - **System admin:** "How do I configure, monitor, troubleshoot this?"
   - **Future maintainer:** "What will confuse me in 6 months? What's implicit?"
2. For each perspective: identify 1-2 gaps in current requirements

**Output:** Multi-perspective requirements enrichment added to specification.

---

## Technique: Boundary Probing

**When:** Edge cases and limits are undefined or acceptance criteria lack boundary conditions.
**Method:**
1. For each input/parameter in the feature:
   - "What's the minimum valid value? Maximum?"
   - "What happens at 0? At null/empty? At 10x expected volume?"
   - "What happens with special characters, Unicode, extremely long strings?"
2. For each boundary: define expected behavior (accept, reject with message, truncate)

**Output:** Boundary condition table added to acceptance criteria and test plan.
