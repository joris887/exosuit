---
paths:
  - "**"
---

# Edit Failure Recovery Rules

When an edit operation fails, follow this recovery protocol. NEVER retry an edit without first re-reading the file.

## Recovery Decision Tree

| Error | Cause | Recovery |
|-------|-------|----------|
| "old_string not found" | File changed since last read | Re-read the file, find the actual current content, retry with fresh content |
| "old_string not unique" | Multiple matches in file | Include more surrounding context lines to make the match unique |
| "file has been modified" | External change during session | Re-read the file, verify your change is still needed, retry |
| Multiple failures on same edit | Stale context or wrong target | Stop. Re-read the file completely. Verify you're editing the right file and location |

## Rules

- ALWAYS re-read a file before retrying a failed edit — your context may be stale
- NEVER retry the exact same edit call that just failed — something changed
- If an edit fails twice on the same file, read the ENTIRE file before the third attempt
- After 3 failed edits on the same file, pause and reconsider the approach
- When including more context for uniqueness, prefer adding lines ABOVE the target (they're less likely to have changed)
- If a file has been heavily edited this session, re-read it before each subsequent edit — accumulated changes may have shifted line content
