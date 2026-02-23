---
paths:
  - "**"
---

# Verification Rules

## Rule Effectiveness Tracking

When a rule influences your behavior (causes you to change an approach, block an action, or apply a check you wouldn't otherwise do), emit a tracking event:

```bash
echo "{\"type\":\"rule\",\"rule\":\"<rule-name>\",\"action\":\"<what-it-caused>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

This data feeds into `/retrospective` and `/weekly-maintenance` for rule health analysis. Rules that never trigger may be too narrow; rules that trigger constantly may be too broad.

## Evidence Required Before Completion Claims

- NEVER claim "tests pass" without running the test command and showing output in the current turn
- NEVER say "should work" or "looks correct" — run the verification command
- NEVER mark a task complete without fresh evidence from the current session
- Partial verification (ran one test, not the suite) is NOT proof of full compliance
- "I already ran this earlier" is NOT fresh evidence — re-run before claiming completion
- Confidence is NOT proof — show command output
- "It compiles" is NOT "it works" — run the tests
- Before invoking any CLI tool with flags you're unsure about, run `[tool] --help` first — do NOT guess flags from memory, tool versions change

## Completion Evidence Protocol

Before reporting ANY task as complete, explicitly answer ALL four questions:

1. **Are all tests passing?** — Paste the actual command output from THIS turn
2. **Are all acceptance criteria met?** — List each criterion with `[PASS file:line]` or `[FAIL reason]`
3. **Were any assumptions made without verification?** — List each assumption and its evidence source
4. **Is there concrete evidence for every claim?** — Reference specific test results, command outputs, or file:line locations

If ANY answer is incomplete or uncertain, the task is NOT complete.

### Red Flags (self-check before claiming done)
- Using "should work" or "looks correct" language
- Implementation complete but test output not shown in current turn
- Skipping warnings or non-zero exit codes in command output
- Referencing "earlier" output instead of fresh output
- Saying "I believe" or "I think" instead of showing evidence

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

## Pre-Compaction State Persistence

When context is approaching compaction (multiple large tool outputs, 15+ turns of conversation, or system compaction trigger), persist state before it's lost:

1. Save current state to `docs/sessions/.auto-save.md` — branch, phase, active plan, key decisions, files modified
2. Use the same format as the pre-stop-quality hook auto-save, adding: `goal`, `phase`, and `active_plan` fields
3. After compaction, verify critical state survived by cross-checking against the auto-save file
4. If critical state was lost in compaction, reload from the auto-save file

This complements the pre-stop-quality hook auto-save (which triggers at session end) by also protecting against mid-session compaction loss.

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
