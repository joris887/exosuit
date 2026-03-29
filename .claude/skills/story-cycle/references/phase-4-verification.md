# Phase 4: Verify + Wrap Up

Reference loaded by `/story-cycle` Phase 4. All checks are mandatory — none are skipped because the story feels simple.

### 4a. Self-Review + Disaster Prevention

Read `references/self-review.md` and complete the checklist (completeness, quality, testing, discipline).

Then read `references/disaster-prevention.md` — check for: wheel reinvention, spec drift, integration wiring, file structure, regression surface.

**Security web verification (security-scoped stories only):** If the story was tagged with intent-based security activation (Phase 1d) or is a Security story type, perform a targeted web check before quality gates. See `references/self-review.md` → "Security Web Verification" section for the protocol.

<HARD-GATE>
Do NOT skip self-review for ANY story size. If any checklist item fails, go back to Phase 3 and fix before continuing.
</HARD-GATE>

**Ground rules re-check:** If `docs/reference/GROUND_RULES.md` exists, re-read it and verify the IMPLEMENTATION (not just the plan) complies. Plans can comply while implementation drifts. Check `git diff --name-only` against ground rules — any MUST violation requires fixing before proceeding.

**If sub-agents are available:** Dispatch quality agents in forked context based on the risk matrix from Size & Risk Classification:

| Risk Level | Quality Skills (static analysis) | Native Agents (dynamic verification) |
|---|---|---|
| **Low (3-4)** | `/code-quality`, `/test-validator`, `/security-audit` (lightweight — CWE top 5 + secrets scan only) | — |
| **Medium (5-6)** | `/code-quality`, `/test-validator`, `/security-audit` | `integration-tester` |
| **High (7-9)** | `/code-quality`, `/test-validator`, `/security-audit`, `/architecture-check` | `integration-tester` (mandatory) |

**Why security-audit at ALL risk levels:** AI-generated code contains vulnerabilities 40-45% of the time regardless of story type or perceived risk. At low risk, run a lightweight security pass (hardcoded credentials, SQL injection, XSS, command injection, eval — the 5 CWEs AI produces most). At medium/high, run the full checklist.

For medium-risk STANDARD stories, the risk matrix promises "all quality agents" — dispatch accordingly. For high-risk, add `/architecture-check` as the risk matrix specifies "all agents + architecture-check."

**Why integration-tester at Medium+ risk:** The implementing LLM verifies its own work in Phase 4b (self-assessment). The `integration-tester` native agent (`.claude/agents/integration-tester.md`) independently re-runs the test suite and verifies acceptance criteria in forked context — breaking the self-verification cycle. At low risk, Phase 4b's quality-gate-sequence is sufficient.

**Integration-tester dispatch prompt:** Include: (1) test/lint/typecheck commands from CLAUDE.md, (2) all acceptance criteria from the plan, (3) modified files from `git diff --name-only`. The agent runs everything independently and reports VERIFIED or NEEDS WORK with command output evidence.

**If sub-agents are NOT available:** Complete self-review checklist manually. Do NOT skip quality checks.

**Error learning:** If self-review caught a wrong approach requiring significant rework, invoke the `record-failure` micro-component from `.claude/prompts/record-failure.md`.

### 4b. Quality Gates

Run the `quality-gate-sequence` micro-component from `.claude/prompts/quality-gate-sequence.md`: execute the project's quality commands (from CLAUDE.md Commands section) in order: lint → typecheck → test. Stop on first failure, fix, and re-run.

<IF condition="test command exists in CLAUDE.md Commands">
Execute the configured quality commands. Verify all pass with zero failures.
</IF>
<ELSE>
Run any configured commands (lint, typecheck). No test command configured — skip test verification, note in completion report.
</ELSE>

<HARD-GATE>
Do NOT proceed to Phase 4c/4d until ALL configured quality gates pass with zero failures. Show the passing output in the current turn. "It passed earlier" is not evidence — re-run if any code changed since the last run.
</HARD-GATE>

### 4c. Generate UAT Test Case (Optional)

**Applies to:** Feature and Bug Fix stories that affect user-visible behavior, AND the project has UAT tracking (`docs/testing/UAT_COVERAGE.md`, `docs/testing/uat/`, or `tests/uat/`).
**Skip for:** Spike/Research, Infrastructure, Documentation, Testing, Refactoring, Performance, Skill/Tooling stories. Also skip if no UAT file or directory exists in the project.

1. **Find UAT location:** Check for `docs/testing/UAT_COVERAGE.md` (single-file), `docs/testing/uat/` (directory), or `tests/uat/scenarios/`. If none exists, skip this phase entirely.
2. **Find next UAT ID:** Search for `### UAT-` headings in existing files, increment the highest number, format as `UAT-###` (zero-padded to 3 digits).
3. **Generate test case** matching the template format in UAT_COVERAGE.md:
   - `### UAT-NNN: [Title derived from story]`
   - `**Priority:** [risk-based] | **Type:** [positive|negative|boundary] | **Covers:** [Story IDs] | **Tags:** [relevant tags]`
   - `**Setup:**` — preconditions from story context
   - `**Given**` / `**When**` / `**Then**` / `**And**` — one per acceptance criterion; create multiple test cases if an AC needs multiple scenarios
   - `**Test Data:**` table if applicable
   - `**Status:** ⬜ Untested` / `**Tested On:** —` / `**Findings:** —`
   - `**Claude Sense Check**` and `**Human UAT Check**` checkbox sections
   - `#### Results` append-only table with initial `⬜ Untested` row
4. **Write the test case:**
   - **Single file** (`docs/testing/UAT_COVERAGE.md`): Append before the `## Reference` section
   - **Directory** (`docs/testing/uat/` or `tests/uat/`): Create a new file following existing naming convention
5. **Update Dashboard:** Increment "Total Test Cases" and "⬜ Untested" counts in the Dashboard table

### 4c.1. Sense Check UAT Case (Optional)

**Applies when:** A UAT test case was generated in Phase 4c.
**Skip when:** No UAT case was generated.

Since the implementation code is fresh in context, immediately verify the UAT case logic:

1. **Trace each UAT step** through the code just written:
   - Does the action map to a real UI element / API endpoint / code path?
   - Is the assertion verifiable from the implementation?
   - Are there any steps that reference behavior not actually implemented?
2. **Verify acceptance criteria coverage:**
   - Each UAT acceptance criterion should correspond to tested, reachable code
   - Flag any criterion that assumes functionality beyond what was built
3. **Assign verdict:**
   - **Pass** — all steps and criteria trace to working code
   - **Warning** — potential gap found; note the issue in the UAT file and fix if trivial
   - **Fail** — step references non-existent behavior; fix the UAT case (not the code — the code was already tested)
4. **Update the UAT file:**
   - Check the box: `- [x] Logic verified from code perspective`
   - Fill in Notes with verdict and what was checked

### 4d. Completion Verification

Re-read the original acceptance criteria from the plan. For each criterion, provide concrete evidence: test output, code reference (file:line), or command output.

<LOOP max="2" until="all acceptance criteria have evidence">
If any criterion lacks evidence: identify the gap, loop back to Phase 3 for that specific item, re-verify.
</LOOP>

<HALT reason="max verification loops exhausted">
Report what IS complete with evidence, list remaining gaps.

**Checkpoint Rollback Option:** If verification has failed after 2 loop passes and the implementation appears fundamentally flawed (not just minor gaps), offer the user a rollback:

```
Verification failed after 2 passes. Options:
[R] Rollback — restore to pre-implementation checkpoint (git tag from Phase 3.pre) and re-plan
[C] Continue — keep current code and address remaining gaps in next session
[F] Force complete — mark as done with known gaps documented
```

If [R]: `git stash push --include-untracked -m "story-cycle: checkpoint rollback" && git reset --soft <checkpoint-tag> && git restore . && git tag -d <checkpoint-tag>`. Clear `.failure-state.md`. Suggest re-entering Phase 1 with lessons learned.
If [C]: Save state to `.failure-state.md` for `/continue` pickup.
If [F]: Document gaps in completion report, proceed to Phase 4e.
</HALT>

<HARD-GATE>
Do NOT print the completion report until every acceptance criterion has been verified with evidence. Show test output or code references — not assertions.
</HARD-GATE>

### 4e. Docs + Commit

1. **Capture story outcome:** Run the `capture-outcome` micro-component from `.claude/prompts/capture-outcome.md` to record measurable deltas (lines added/removed, test count, coverage, new deps) to `docs/sessions/.story-outcomes.tsv`. Skip for Spike/Research and Documentation stories.
2. **Update epic file** (`docs/reference/backlog/E##-*.md`):
   - In story checklist: change `- [ ] ID — Title (P#, in-progress)` → `- [ ] ID — Title (P#, review)`
   - In story detail section: update `**Status:** review`
   - Legacy format: mark as `[DONE]` if epic uses old markers
   - Check all acceptance criteria boxes in the detail section (`- [ ]` → `- [x]`)
   - Emit story lifecycle event:
     ```bash
     echo "{\"type\":\"story\",\"event\":\"status-change\",\"id\":\"<id>\",\"from\":\"in-progress\",\"to\":\"review\",\"story_type\":\"<type>\",\"size\":\"<size>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
     ```
3. **Update `docs/reference/BACKLOG_INDEX.md`**: Update story counts per priority group in the status table.
4. **Update `docs/progress.md`** with story status (✅)
4.5. **Update sprint spec** (`docs/sprints/sprint-<N>.md`): set this story's Status to ✅ and Session column to today's date (YYYY-MM-DD). This creates the session-to-sprint mapping needed for cycle time calculation and retrospective analysis.
5. **Update documentation** only if the story's AC requires it
6. **Architecture documentation check:** Read the Update Triggers section of `docs/architecture/ARCHITECTURE.md`. If ANY trigger matches changes in this story (`git diff --name-only`), update the relevant sections and set `Last Verified` date to today. Also:
   - If a non-obvious gotcha was discovered during implementation → add to Known Landmines
   - If a significant architectural choice was made → add to Key Decisions with trade-off
   - If no Update Trigger matches, skip
7. **Capture learnings** (optional): If non-obvious patterns discovered, run the `capture-learnings` micro-component from `.claude/prompts/capture-learnings.md` to save to `docs/solutions/<topic-slug>.md`
8. **Clean up checkpoint:** Delete the git checkpoint tag from Phase 3.pre: `git tag -l 'story-checkpoint-*' | xargs -r git tag -d`
9. **Commit:** Invoke the `/commit` skill. Do NOT merge or create PR — that's `/sprint-end`'s job.

**Skill metrics:** Emit a completion event:
```bash
echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"story-cycle\",\"outcome\":\"success\",\"story\":\"$ARGUMENTS\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```
