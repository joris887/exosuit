Estimate the current context budget usage and report a structured breakdown.

## Context Budget Report

Assess and report:

1. **Framework base load:**
   - CLAUDE.md (~1,000 tokens) — always loaded
   - Active rules (estimate based on file types edited this session)
   - Currently loaded skill content

2. **Session content:**
   - Conversation turns this session: [count]
   - Reference files currently loaded: [list with estimated sizes]
   - Active plan present: [yes/no, estimated size]
   - Files read into context this session: [count]

3. **Compaction proximity:**
   - LOW: <30% estimated usage — plenty of room
   - MEDIUM: 30-60% — monitor, consider pruning STALE context
   - HIGH: 60-80% — prune aggressively, save state to auto-save
   - CRITICAL: >80% — run /handoff or save plan to docs/plans/

4. **Recommendations:**
   - List any STALE or DUPLICATE context items (per verification.md scoring)
   - Suggest specific items to discard
   - If HIGH/CRITICAL: recommend `/handoff` or pre-compaction state save

Present as:

```
### Context Budget Estimate
- Framework base: ~X tokens
- Loaded references: [list]
- Conversation depth: X turns
- Compaction proximity: [LOW/MEDIUM/HIGH/CRITICAL]
- Recommendation: [continue / prune stale context / consider handoff]
```
