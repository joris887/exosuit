# Archetype: Utility / Productivity

**Core Question:** "What task does this make easier?"
**Examples:** CRM, expense tracker, booking system, project management, invoice generator

## Phase 2: Core Identity Questions

**Q1:** "Who has this problem, and how painful is it?"
Scaffold: "Think of a specific person. What's their role? How often do they hit this problem? Rate the pain: mild annoyance (3), real frustration (6), hair-on-fire (9)."

**Q2:** "How do they solve it today?"
Scaffold: "Spreadsheet? Manual process? A competitor's tool? Just living with it?"

**Q3:** "What's broken about the current solution?"
Scaffold: "Too slow? Too expensive? Missing a key feature? Too technical for them?"

**Q4:** "What ONE thing must this do better than anything else?"
Scaffold: "Speed? Simplicity? Price? A specific feature no one else has?"

**Q5:** "How will you know it's working?"
Scaffold: "100 paying users? Saves 5 hours/week? Replaces that spreadsheet? Be specific."

## Phase 3: Deep Dive

Walk through the complete workflow step by step:

**First-time user flow:**
"User opens your app for the first time. What do they see? What do they do next?"
Per step: "What info is needed at this point? What could go wrong here? What happens after?"

**Returning user flow:**
"Now a RETURNING user. What's different? What's their most common action?"

**Power user flow:**
"Most complex thing a power user would do? Walk me through it."

Extract features FROM the workflow description — don't ask for a feature list, derive it from the user journeys.

## Pre-Mortem Failure Scenarios

Present these for user rating (Likely / Possible / Unlikely):
- "Users sign up but never come back after day 1"
- "The core workflow is actually harder than the manual way"
- "A free alternative does 80% of what this does"
- "Users want a feature that's architecturally hard to add"
- "Data migration from their current tool is too painful"
- "The pricing model doesn't match willingness to pay"

For each "Likely" or "Possible": "How would we prevent or mitigate this?"
