---
paths:
  - "**"
---

# Verification Rules

## Evidence Required Before Completion Claims

- NEVER claim "tests pass" without running the test command and showing output in the current turn
- NEVER say "should work" or "looks correct" — run the verification command
- NEVER mark a task complete without fresh evidence from the current session
- Partial verification (ran one test, not the suite) is NOT proof of full compliance
- "I already ran this earlier" is NOT fresh evidence — re-run before claiming completion
- Confidence is NOT proof — show command output
- "It compiles" is NOT "it works" — run the tests
- Before invoking any CLI tool with flags you're unsure about, run `[tool] --help` first — do NOT guess flags from memory, tool versions change

## Task Completion Enforcement

- Before reporting "done" or "complete", check your task list (if you created one). ALL tasks must be completed or explicitly noted as deferred with a reason.
- If any tasks are still in_progress or pending, you are NOT done — complete them or explain what remains and why.
- "Almost done" is NOT done. "Just needs testing" is NOT done — run the tests.
- If you created a task list during this session, every item must be resolved before claiming completion.

## Context Budget Awareness

- If you've read more than 10 files this session, summarize findings and reference file paths instead of re-reading
- After exploration phases (story-cycle Phase 1, debug-session Phase 1), explicitly discard bulk content and keep only insights
- Prefer targeted grep with narrow patterns over reading entire files
- When tool outputs are verbose (>50 lines), summarize the key findings before continuing
- If the conversation feels heavy with prior tool outputs, proactively note what you've learned and move on rather than re-reading

## Context Relevance Scoring

At phase transitions and every 5+ sequential tool calls, classify context items:

| Classification | Criteria | Action |
|---------------|----------|--------|
| **ACTIVE** | Currently needed for the task in progress | Keep in full |
| **ANCHORED** | Referenced by the active plan or current phase | Keep as pointer (file:line) |
| **REFERENCE** | Might be needed later this session | Summarize to 1-line description |
| **STALE** | From completed or abandoned subtasks | Discard |
| **DUPLICATE** | Already captured in plan, commit, or summary | Discard |

Apply aggressively at:
- Story-cycle Phase 2 (Context Transition) — mandatory
- After any exploration that read 5+ files — recommended
- Before compaction triggers — automatic via priority tags
- When you notice yourself re-reading files — sign of context rot

Signs of context rot (performance degradation from irrelevant accumulated context):
- Re-reading files you already read earlier this session
- Uncertainty about decisions made 10+ turns ago
- Contradicting earlier analysis without noticing
- Generating code that doesn't match patterns you already identified
