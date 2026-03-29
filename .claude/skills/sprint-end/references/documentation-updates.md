# Step 3: Documentation Updates

Reference loaded by `/sprint-end` Step 3. Updates all project documentation to reflect sprint completion.

Based on what was done in the sprint, update relevant documentation:

- **Epic file** (`docs/reference/backlog/E##-*.md`):
  - In the story checklist: change `- [ ] ID — Title (P#, in-progress)` → `- [x] ID — Title (P#, done)`
  - In story detail sections: update `**Status:** done`
  - Legacy format: mark as `[DONE]` if epic uses old markers
  - Emit story lifecycle event for each completed story:
    ```bash
    echo "{\"type\":\"story\",\"event\":\"status-change\",\"id\":\"<story-id>\",\"from\":\"review\",\"to\":\"done\",\"story_type\":\"<type>\",\"size\":\"<size>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
    ```
- **BACKLOG_INDEX.md**: Update story counts per priority group. Update the Backlog Health section: recalculate Definition of Ready %, check for zombie stories (any story with `created:` date >2 sprint cycles old still not done)
- **Sprint spec** (`docs/sprints/sprint-N.md`):
  - Update all story statuses to final state (✅ done or ⏭️ carried over)
  - Fill in the `## Outcome` section with metrics:
    - **Goal achieved**: yes/no — did the sprint goal succeed?
    - **Stories completed**: X/Y
    - **Throughput**: X stories (count of ✅)
    - **Cycle time**: average days per completed story (from git log first/last commit per story)
    - **Sprint churn**: % of stories added or removed mid-sprint vs original plan (compare current stories table against the initial commit of the sprint spec: `git show $(git log --oneline --diff-filter=A -- docs/sprints/sprint-N.md | tail -1 | cut -d' ' -f1):docs/sprints/sprint-N.md`)
    - **Tests**: before → after (+delta)
    - **Coverage**: before% → after%
    - **Ground rules**: X/Y checked, Z violations or "Clean"
    - **PR**: #number
    - **Merged**: today's date
- **progress.md**:
  - Update `## Current Sprint` to show completed state
  - **Collect sprint satisfaction:** Ask the developer to rate LLM output quality this sprint (1–5). Use AskUserQuestion: "Sprint satisfaction (1–5)? 1=significant rework needed, 3=acceptable with corrections, 5=excellent, minimal intervention"
  - **Compute sprint metrics** from git and activity log:
    - **Tasks**: count of ✅ stories
    - **Cycle time**: avg days per story (git log first/last commit dates per story)
    - **Change failure rate**: post-merge fixes / total changes this sprint (count commits with "fix" type after initial implementation)
    - **Test coverage Δ**: coverage change on new/modified code (from CI output or test runner)
    - **Code churn ratio**: run `git log --numstat` to find lines modified within 14 days of creation / total lines (or use `scripts/pm/metrics.sh --churn`)
    - **AI effectiveness**: parse `docs/sessions/.activity-log.jsonl` — compute skill success rate and context reset frequency (or use `scripts/pm/metrics.sh --ai-effectiveness`)
    - **Sprint satisfaction**: from user input above (X/5 format)
  - **Append row to `## Sprint History`**: `| N | [goal] | ✅/❌ | X | X.Xd | X% | +X% | 0.XX | 0.XX | X/5 | #N |`
  - **Update `## Metrics` table**: For each metric row, update the Current column with this sprint's value. Recompute Trend sparklines from the last 6 Sprint History rows (use ▁▂▃▄▅▆▇█ — map values to 8 levels; for lower-is-better metrics like cycle time/CFR/churn, invert so up=improving). Compute Status using BOTH absolute and relative thresholds:
    - **Absolute**: 🟢 if within target, 🟡 if within 120% of target, 🔴 if beyond 120%. For "≥" targets, invert.
    - **Relative**: Also compute % change from the 3-sprint rolling average in Sprint History. If metric worsened >50% from average, set status to at least 🟡 regardless of absolute position. If >100% worse, set to 🔴. Example: CFR at 14% (target ≤15%) is 🟢 by absolute threshold, but if the 3-sprint average was 7%, the 100% increase makes it 🔴.
    - Take the worst status between absolute and relative checks.
  - **Sprint note**: If any metric is 🟡 or 🔴, write a one-sentence explanation of the likely cause. Include Δ3avg context when relative change triggered the status (e.g., "CFR doubled from 3-sprint average despite being within absolute target"). Check for three-sprint trends (3 consecutive sprints in same direction = strong signal requiring action). When code churn ratio is 🟡 or 🔴, run `scripts/pm/metrics.sh --churn` and include the top 3 hotspot files in the note (e.g., "Churn 🟡 — hotspots: src/auth/session.ts (7 changes), src/api/routes.ts (5 changes)").
  - Update `## Next Steps` with post-sprint actions
- **CLAUDE.md**: Update Current Focus if epic status changed
- **Project context** (`docs/context/`): If sprint changes affect architecture, patterns, or tech stack, incrementally update the relevant context files (use `git diff $DEFAULT_BRANCH...HEAD --name-only` to identify affected areas). Update `updated:` timestamps in YAML frontmatter.
- **Architecture doc** (`docs/architecture/ARCHITECTURE.md`): If any story in this sprint changed architecture (check the Update Triggers section), verify the doc was updated during story-cycle Phase 4e. If not, update it now and set `Last Verified` date to today.
- **SBOM (informational):** If CycloneDX or Syft tools are available, generate or update `sbom.json` to reflect current dependencies. If no SBOM tool is available, skip — note "SBOM generation: no tool available" in the PR body. This is informational, not blocking.
- **Technical debt register** (`docs/technical-debt.md`):
  - If quality gates (step 2) identified issues logged to the debt register, ensure each item has the full format (category, severity, origin, quantified impact, interest rate, effort, resolution plan)
  - For debt introduced by AI-assisted code this sprint, set `origin: ai-generated`
  - For debt resolved by sprint stories, move items to "Resolved" section with actual effort and sprint reference
  - Update the header: `Active items: X | Resolved this quarter: Y`
  - Record in sprint spec `## Outcome`: **Debt delta**: +N added / -N resolved (net: +/-N). This data feeds into `/retrospective` for trend analysis.

### PRD Living Document Review

If `docs/reference/PRD_SUMMARY.md` exists, review it against sprint learnings:

- **Section 9 (Open questions):** Were any assumptions validated or invalidated this sprint? Update their Status (Assumed → Validated/Invalidated). Were any open questions answered? Update Status (Open → Resolved).
- **Section 5 (Requirements):** Did any requirement's scope change during implementation? If acceptance criteria were added, modified, or found insufficient, note the delta.
- **Section 3 (Success criteria):** Can any criteria now be measured? Note baseline values if available from test output.
- **Scope creep check:** Compare stories delivered against PRD Section 5 requirements. Flag stories that don't trace to any PRD requirement — these may indicate scope creep or legitimate new requirements that the PRD should absorb.

If changes are needed, update PRD_SUMMARY.md and bump the version in the header comment.
