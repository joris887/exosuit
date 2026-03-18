---
name: framework-upgrade
version: 1.0.0
description: Upgrade JD-LLM Development Framework to a newer version while preserving project customizations.
trigger: manual
depends-on: [doctor]
references: [references/upgrade-checklist.md, references/merge-strategy.md]
requires:
  binaries: [git]
  files: [CLAUDE.md, .claude/skills/SKILLS_INVENTORY.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: "[local-path | --branch <branch>]"
---
______________________________________________________________________

## framework-upgrade

Upgrades the JD-LLM Development Framework to a newer version while preserving all project-specific customizations (skills, rules, hooks, settings).

### Phase 0: Validate & Discover

1. **Fetch new framework version:**
   - **Default (no argument or `--branch <branch>`):** Clone the framework repo from GitHub into a temp directory. Use `main` branch unless `--branch` specifies otherwise.
     ```bash
     FRAMEWORK_REPO="https://github.com/joris887/JD-LLM-Development_framework.git"
     TEMP_DIR=$(mktemp -d)
     git clone --depth 1 [--branch <branch>] "$FRAMEWORK_REPO" "$TEMP_DIR"
     ```
   - **Local path override:** If `$ARGUMENTS` is a directory path, use it directly (for testing local changes before pushing).
   - **Validate:** The source (cloned or local) must contain `.claude/skills/`, `.claude/hooks/`, `CLAUDE.md`.
1. **Current version** — Read `SKILLS_INVENTORY.md`, extract `Framework Version:` line. Record as `CURRENT_VERSION`.
1. **New version** — Read `<source>/CHANGELOG.md` or `<source>/.claude/skills/SKILLS_INVENTORY.md` for version. Record as `NEW_VERSION`.
1. **Git safety** — Verify working tree is clean (`git status --porcelain`). If dirty, HALT: "Commit or stash changes before upgrading."
1. **Report**: "Upgrading framework: v{CURRENT} → v{NEW}. Source: {GitHub main | GitHub branch | local path}. Branch: {branch}."
1. **Cleanup note**: If a temp directory was created, delete it at the end of Phase 3 (after verification).

### Phase 1: Inventory & Classify

Run 4 parallel exploration agents to build a complete diff inventory:

**Agent 1 — Skills diff**: Compare `.claude/skills/` between current and new. For each skill directory:

- EXISTS IN BOTH → check SKILL.md + references/ for content differences → classify as `UPDATE` or `IDENTICAL`
- ONLY IN NEW → classify as `ADD`
- ONLY IN CURRENT → classify as `PRESERVE` (project-specific)

**Agent 2 — Hooks diff**: Compare `.claude/hooks/` (*.sh, rules/*.patterns, rules/*.conf, *.json, lib/). Classify each file.

**Agent 3 — Agents + Prompts + Commands diff**: Compare `.claude/agents/`, `.claude/prompts/`, `.claude/commands/`. Classify each file.

**Agent 4 — Rules + Docs diff**: Compare `.claude/rules/`, `docs/reference/` (TESTING_STRATEGY, MCP_INTEGRATION, CODING_STANDARDS, GROUND_RULES, GIT_WORKFLOW, WORKFLOW), `docs/context/` template structure, `scripts/pm/`, `llms.txt`.

Compile results into a structured upgrade plan:

```
## Upgrade Plan: v{CURRENT} → v{NEW}

### REPLACE (take new version as-is)
- [file]: [reason]

### MERGE (new framework + project customizations)
- [file]: [what to preserve from current]

### ADD (new files from framework)
- [file]: [purpose]

### PRESERVE (project-specific, no changes)
- [file]: [reason]

### POPULATE (templates that need project content)
- [file]: [what content to write]
```

<HARD-GATE>
Present the upgrade plan to the user. Do NOT proceed until they approve.
Ask: "Approve this upgrade plan? I'll preserve all project-specific customizations listed under PRESERVE."
</HARD-GATE>

### Phase 2: Execute Upgrade

Work through the approved plan in dependency order:

**Step 1 — Infrastructure** (hooks, settings, lib/)

- REPLACE files: Read from new framework, Write to project
- MERGE files: Read both versions, combine (new framework base + project-specific additions)
- For hooks: preserve project-specific safety rules (e.g., custom blocking patterns)
- For settings.json: keep project paths, adopt new hook structure
- For session_start.py: keep project-specific tool checks, add new framework features

**Step 2 — Agents + Prompts + Commands**

- REPLACE: copy new versions (preserve project-only agents)
- ADD: create new files from framework

**Step 3 — Rules**

- MERGE: adopt new framework patterns + paths, preserve project-specific sections (e.g., custom security rules, project verification commands, technology-specific patterns)

**Step 4 — Skills**

- UPDATE: copy new SKILL.md + references/ from framework for each shared skill
- ADD: create new skill directories
- PRESERVE: leave project-specific skills untouched

**Step 5 — Documentation**

- UPDATE: TESTING_STRATEGY.md, MCP_INTEGRATION.md, CODING_STANDARDS.md (if changed)
- POPULATE: Any new `docs/context/` templates → write project-specific content
- ADD: new directories (docs/solutions/, docs/brainstorms/, scripts/pm/)
- UPDATE: llms.txt with current project stats

**Step 6 — Inventory & Config**

- Regenerate SKILLS_INVENTORY.md with all skills (updated + new + preserved)
- Update skills-registry.json
- Update CLAUDE.md: framework version, new skills in tables, new docs references

### Phase 3: Verify

1. Run the project's test command (from CLAUDE.md Commands): verify all tests pass
1. Run `/doctor` to validate framework health
1. Show summary:

```
## Framework Upgrade Complete: v{CURRENT} → v{NEW}

### Changes
- X files updated
- Y files added
- Z project-specific files preserved
- Tests: [PASS/FAIL]

### New Capabilities
- [list new skills added]
- [list new agents added]
- [list key improvements]
```

### Merge Strategy Reference

For detailed merge patterns (which sections to preserve, which to replace), consult `${CLAUDE_SKILL_DIR}/references/merge-strategy.md` — search for the relevant component type.

### Recovery

| Error                         | Cause                                   | Recovery                                                       |
| ----------------------------- | --------------------------------------- | -------------------------------------------------------------- |
| Test failures after upgrade   | Skill/hook incompatibility              | `git checkout -- <file>` to revert specific file, re-run tests |
| Missing project customization | Merge missed a project-specific section | Read both old and new versions, manually merge                 |
| Framework path not found      | Wrong argument                          | Verify path exists and contains .claude/ directory             |
| Dirty working tree            | Uncommitted changes                     | Commit or stash first, then retry                              |

### Evaluation Criteria

- [ ] All project-specific skills preserved (not overwritten)
- [ ] All project-specific rule sections preserved
- [ ] All project-specific hook rules preserved
- [ ] New framework skills added and functional
- [ ] Tests pass after upgrade
- [ ] SKILLS_INVENTORY.md reflects correct version and all skills
