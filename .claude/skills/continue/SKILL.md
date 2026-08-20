---
name: continue
version: 2.8.0
description: Resume development with smart session continuation. Reads session handoff files, sprint spec, analyzes git state, and determines the best path forward.
trigger: manual
depends-on: []
references: []
micro-components:
  step-1.5: [context-prime]
  step-5: [discover-commands]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---
______________________________________________________________________

## continue

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"continue\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

Resume development. Execute this smart continuation workflow:

## Current Git State (auto-fetched)

- **Branch**: !`git branch --show-current`
- **Status**: !`git status --short`
- **Open PRs**: !`gh pr list --author @me --state open --limit 5 2>/dev/null || echo "No PRs or gh not configured"`

## 0. Project Health Scan

Before session recovery, assess project maturity by checking key artifacts:

| Artifact | Check | If Missing/Incomplete |
|----------|-------|----------------------|
| `docs/architecture/ARCHITECTURE.md` | Exists, non-template, Last Verified < 30 days | Suggest `/bootstrap` if missing; `/architecture-check` if stale |
| `docs/reference/GROUND_RULES.md` | Exists and has ≥3 rules | Suggest `/bootstrap` (A3.5b step) |
| `docs/reference/CODING_STANDARDS.md` | Exists and non-template | Suggest `/bootstrap` |
| `docs/reference/BACKLOG_INDEX.md` | Has ≥1 TODO story | Suggest `/ideate` |
| Feature branch | `git branch --list 'feat/*' 'fix/*' 'sprint-*'` | Suggest `/sprint-start` |
| Test command | CLAUDE.md Commands has test entry | Suggest configuring tests |
| ADR currency | New ADRs accepted since last session (`git log --oneline docs/adr/`) | Surface new decisions that may constrain current work |
| Team workflow | `.github/CODEOWNERS` exists or `>1` contributors | Surface team tier from `docs/reference/TEAM_WORKFLOW.md` scaling guide |

Present as a health dashboard before the session state:

```markdown
### Project Health
- ✅ Architecture documented
- ✅ Ground rules established (5 rules)
- ⚠️ No backlog stories — consider `/ideate`
- ⚠️ Architecture doc stale (Last Verified: 45 days ago) — consider `/architecture-check`
- ❌ Test command not configured
```

Only flag items that are missing or incomplete — don't clutter with all-green checks unless it's the first session.

## 0.5. Check for Failure State

Check for an interrupted skill session:

```bash
cat docs/sessions/.failure-state.md 2>/dev/null
```

If `.failure-state.md` exists, a previous skill was interrupted mid-execution. This is the **highest-priority context source**. The file uses YAML frontmatter with structured fields:

```yaml
---
status: active          # "active" means interrupted workflow
skill: story-cycle      # which skill was running
phase: "3"              # phase number
phase_name: "Execution" # human-readable phase name
started_at: "..."       # when the workflow started (ISO-8601)
story: "..."            # story/task being worked on
branch: "..."           # git branch at time of interruption
next_action: "..."      # what to do next to resume
files_modified: [...]   # files changed so far
---

## Context
[Free-form notes about the interrupted state]
```

Parse the YAML frontmatter to extract structured data. Present it prominently:

```markdown
### Interrupted Session Detected
- **Skill:** [from `skill` field]
- **Phase:** [from `phase` + `phase_name` fields]
- **Story:** [from `story` field]
- **Branch:** [from `branch` field]
- **Next action:** [from `next_action` field]
- **Files modified:** [from `files_modified` field]
```

Check `started_at` — if the failure state is older than 4 hours, flag it as potentially stale:
> "This failure state is [N] hours old. It may be from a previous session that was abandoned. Confirm you want to resume this workflow."

**Validate story status:** If the failure state references a story ID, check its status in the epic file (`docs/reference/backlog/E*.md`). If the story status is `in-progress`, recovery is valid. If it's `done` or `review`, the story may have been completed in another session — inform the user.

Recommend the user resume the interrupted skill (e.g., `/story-cycle` or `/debug-session`) with the recovery context from the `next_action` and `## Context` section.

**Cursor-first resume (flow contracts):** The frontmatter may additionally carry a flow cursor — `flow:`, `node:`, and `attempt:` keys (see `.claude/skills/FLOW_SPEC.md` → Cursor & Resume). If present AND the file's `branch:` matches `git branch --show-current`:

1. Read `.claude/skills/<flow>/flow.yaml` and locate the `node:` id.
2. Resume the skill AT that node — open the node's `doc:` anchor in the skill's SKILL.md for the exact step instructions. An `attempt:` greater than 1 means a retry was in progress at that node.
3. Present it as: "Cursor: /<flow> was at node '<node>' (attempt N) — resume there."

If the branch does NOT match, the file was inherited from another worktree/branch — ignore the cursor keys entirely and fall back to the standard fields above. The same fallback applies when the cursor cannot be resolved: `.claude/skills/<flow>/flow.yaml` does not exist, or the stored `node:` id is not found in it (skill upgraded mid-run) — say so in one line and resume from the standard fields instead. Files without cursor keys (all pre-existing formats) follow the standard behavior above, unchanged.

## 0.6. Read Latest Session Handoff

Check for the most recent session file:

```bash
ls -t docs/sessions/session-*.md 2>/dev/null | head -1
```

If a session file exists, read it as the primary context source. It contains: completed work, pending items, next steps, files to load, test status, and warnings.

## 0.7. Team Context Check

<IF condition=".github/CODEOWNERS exists or git log shows multiple contributors">
Check for other developers' recent activity that may affect your work:

```bash
# Recent commits by other authors (last 7 days)
git log --since="7 days ago" --format="%an: %s" --no-merges | head -10
# Other open PRs that might conflict
gh pr list --state open --limit 5 2>/dev/null
```

If other PRs touch files related to your current story, flag potential **agentic drift** — semantically incompatible changes that merge cleanly but encode different assumptions. See `docs/reference/TEAM_WORKFLOW.md` for the full team coordination workflow.
</IF>

## 1. Assess Git State

**Branch Scenarios:**

- **On feature branch with changes**: Mid-sprint, continue work
- **On feature branch, clean**: Sprint may be ready for PR or needs more work
- **On main with changes**: Should not happen - create branch first
- **On main, clean**: Between sprints, ready to start new work

## 1.5. Load Project Context

Load the project context knowledge base for deep project understanding (use the `context-prime` micro-component from `.claude/prompts/context-prime.md`):

- Read `docs/context/` files in priority order: overview + tech first, patterns + structure second, product last
- Skip files that are still template placeholders (contain only `<!-- filled by -->` comments)
- This provides persistent project knowledge that compounds across sessions

## 1.6. Reload Working Context

If a session file was found, use its "Files Accessed" section to reload context efficiently:

- **Modified files:** Read all — they contain your changes from last session
- **Read (context-relevant):** Read these only if continuing the same story
- **Investigated (can skip):** Skip unless the user specifically asks about them

This avoids re-exploring files that were already investigated last session.

## 2. Assess Project State

- Read @docs/progress.md for current sprint goal, story statuses, and notes
- **Metrics warnings:** Check `docs/progress.md` → `## Metrics` table for any 🟡 or 🔴 status. If found, surface in the Project Health section (step 0):
  > "⚠️ [Metric name]: [status] ([value], target [target]) — [sprint note context]"
  This warns the user about quality degradation before they choose what to work on. Skip if all 🟢 or no data.
- Read @docs/reference/BACKLOG_INDEX.md for current story status

### 2.5. Load Sprint Context

If on a sprint branch (branch name matches `sprint-*`):

1. Find the matching sprint spec: `docs/sprints/sprint-<number>.md`
2. Read it and extract:
   - **Sprint goal** — display prominently in the continuation summary
   - **Stories table** — current status of all sprint stories
   - **Capacity** — sessions available vs sessions consumed (count ✅ stories by size: S=1, M=2, L=4)
   - **Decisions log** — any decisions made in prior sessions that constrain current work
   - **Boundaries** — out of scope items and risks
3. If a session handoff file exists, cross-reference `sprint_capacity` from its frontmatter

This ensures the sprint goal and constraints survive across sessions — without this, resumed sessions lose the "why" behind the current work.

## 3. Determine Continuation Point

**If on a feature branch:**

- This is an active sprint
- Check if PR already exists: `gh pr view`
- If PR exists and approved: offer to merge
- If PR exists awaiting review: wait or continue work
- If no PR: continue sprint implementation

**If on main:**

- Find current IN_PROGRESS story in backlog
- If found: switch to or create its feature branch
- If none: identify next TODO story for new sprint

## 4. Handle Pending PRs

If there are open PRs awaiting merge, offer to:

- Check review status
- Merge approved PRs
- Address review feedback

## 5. Quick Verification

Run the project's test command (from CLAUDE.md Commands section) to verify everything works:

```bash
# Use the project's test command from CLAUDE.md
```

If mid-sprint: Resume from last checkpoint
If starting new sprint: Execute sprint-start workflow

## 5.5. Health Dashboard

Present a quick status pulse:

```bash
# Last commit time and branch
git log -1 --format="%cr on %D"
# Uncommitted file count
git status --short | wc -l
# Session file age
ls -lt docs/sessions/session-*.md 2>/dev/null | head -1
```

```markdown
### Session Health
- **Tests:** [passing/total] ([green/red])
- **Last commit:** [time ago] on [branch]
- **Open changes:** [count] files
- **Session file:** [age — e.g., "2 days ago" or "none found"]
```

## 6. Present Options

Based on analysis, present relevant options:

- "Continue current sprint on branch \[branch-name\]"
- "**Complete sprint**: run agents, update docs, create PR"
- "Merge approved PR #\[number\] and start next story"
- "Address review feedback on PR #\[number\]"
- "Start next story \[ID\]: \[title\] (will create new branch)"
- "Commit and push current changes to feature branch"

## 7. Wait for Direction

**Skill metrics:** The analysis is complete once findings are ready — emit a completion event BEFORE presenting them (the turn ends waiting for the user, so anything after the wait may never run):

```bash
echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"continue\",\"outcome\":\"success\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

Present findings and wait for user choice before proceeding.
