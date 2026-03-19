---
name: upstream-updates
version: 1.0.0
description: Analyze latest Claude Code features and generate framework upgrade plan
trigger: manual
user-invocable: true
argument-hint: "[--deep]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Agent
  - Write
  - Bash
model: opus
---

# Upstream Updates — Claude Code Feature Integration Analysis

Analyze the latest Claude Code release to identify new features the framework can leverage, then generate a prioritized upgrade plan.

## Phase 1: Gather Claude Code Current State

### 1a. Get Claude Code version and release notes
Run `claude --version` to identify the current version. Then use the `/release-notes` slash command output or WebFetch the release notes to identify ALL features added since the framework was last updated.

### 1b. Fetch official documentation
Use WebFetch to load these pages (launch parallel Agent subagents for speed):

| Page | URL | What to extract |
|------|-----|-----------------|
| Hooks | `https://code.claude.com/docs/en/hooks` | All hook event types, input/output schemas, configuration fields |
| Settings | `https://code.claude.com/docs/en/settings` | All settings fields and their types/values |
| Skills | `https://code.claude.com/docs/en/slash-commands` | Frontmatter fields, execution options, discovery |
| Agents | `https://code.claude.com/docs/en/agents` | Agent definition fields, configuration options |
| CLAUDE.md | `https://code.claude.com/docs/en/claude-md` | Auto-loading behavior, import syntax, rules |
| Sub-agents | `https://code.claude.com/docs/en/sub-agents` | Agent tool parameters, isolation options |
| Plugins | `https://code.claude.com/docs/en/plugins` | Plugin system capabilities |
| Memory | `https://code.claude.com/docs/en/memory` | Memory system, auto-memory, rules directory |

### 1c. (--deep only) Clone Claude Code repo
If `--deep` flag is passed:
```bash
git clone --depth 1 https://github.com/anthropics/claude-code.git /tmp/claude-code-analysis 2>/dev/null || git -C /tmp/claude-code-analysis pull
```
Analyze the repo for: settings schema, hook event definitions, tool parameters, undocumented features.

### 1d. Compile Feature Catalog
Create a structured catalog of ALL Claude Code capabilities:

```
HOOK EVENTS: [list all event types with descriptions]
SETTINGS FIELDS: [list all settings with types and defaults]
SKILL FRONTMATTER: [list all supported fields]
AGENT FRONTMATTER: [list all supported fields]
RULE FEATURES: [paths, conditional loading, etc.]
TOOLS: [all available tools and their parameters]
NEW CAPABILITIES: [anything not in the above categories]
```

## Phase 2: Analyze Current Framework

### 2a. Read framework reference
Read `FRAMEWORK_DEEP_DIVE.md` (in the workspace root, NOT in the framework repo) for the complete framework architecture.

### 2b. Inventory framework usage
Catalog what the framework currently uses:

```bash
# Hook events registered
grep -o '"[A-Z][a-zA-Z]*":' .claude/settings.json | sort -u

# Agent frontmatter fields
for f in .claude/agents/*.md; do head -20 "$f"; done

# Skill frontmatter fields
for f in .claude/skills/*/SKILL.md; do head -20 "$f"; done

# Rules
ls .claude/rules/

# Settings (non-hook)
grep -v '"hooks"' .claude/settings.json | head -10
```

### 2c. Create usage matrix
For each Claude Code capability, classify:

| Capability | Framework Status | Notes |
|-----------|-----------------|-------|
| SessionStart hook | CURRENT | Used in session-start.sh |
| PreCompact hook | CURRENT | Used in pre-compact.sh |
| PermissionRequest hook | MISSING | Not used yet |
| ... | ... | ... |

## Phase 3: Gap Analysis

### 3a. Identify gaps
For each MISSING or PARTIAL capability:

1. **Relevance check:** Does this feature help enforce any of the 16 framework principles?
   - TDD-first, Sprint-based, Git-disciplined, Documentation-lean, AI-aware, Verification-driven, Context-efficient, Clarification-first, Ground-rules-governed, Risk-calibrated, Confidence-first, Observable, Secrets-aware, CI-enforced, Anti-slop, Session-resilient
2. **Impact assessment:** How much does it improve the framework? (HIGH/MEDIUM/LOW)
3. **Effort estimate:** How much work to integrate? (trivial/small/medium/large)
4. **Risk assessment:** Could it break existing behavior? What are the dependencies?

### 3b. Prioritize
Group gaps into:
- **P0 — HIGH impact / LOW effort:** Do first
- **P1 — HIGH impact / HIGH effort:** Plan carefully
- **P2 — MEDIUM impact:** Nice-to-have
- **P3 — LOW impact:** Only if time permits

### 3c. Check for deprecations
Review if any Claude Code features the framework currently uses have been deprecated or changed behavior. Flag these as URGENT fixes.

## Phase 4: Generate Upgrade Plan

### 4a. Determine next epic number
Read `plans/FRAMEWORK_UPGRADE_BACKLOG.md` to find the next available epic number.

### 4b. Write epic file
Write the upgrade plan to `plans/E{N}-claude-code-integration.md` with:
- One story per feature integration
- Acceptance criteria for each story
- Grouped into sprints by priority
- Dependencies noted
- Estimated effort per story

### 4c. Update backlog
Add the new epic to `plans/FRAMEWORK_UPGRADE_BACKLOG.md` summary table.

## Phase 5: Present to User

### *** HARD GATE: Wait for user approval ***

Present:
1. **Summary:** X new Claude Code features found, Y applicable to framework, Z already integrated
2. **Deprecation warnings:** Any features the framework uses that have changed
3. **Recommended sprint plan:** Stories grouped by priority with effort estimates
4. **Context savings:** Estimated token savings from new features
5. **Enforcement upgrades:** Which advisory → deterministic conversions are possible

Do NOT implement any changes. Wait for user to approve the plan and direct which sprint to start.

## Error Recovery

| Error | Cause | Recovery |
|-------|-------|----------|
| WebFetch returns 404 | Documentation URL changed | Try the docs landing page `https://docs.anthropic.com/en/docs/claude-code/overview`, navigate from there |
| WebFetch times out | Network or rate limiting | Retry once, then skip that page and note the gap |
| `claude --version` fails | Claude Code not installed or not in PATH | Ask user for version manually, continue with web research only |
| Git clone fails (--deep mode) | Repo access denied or not found | Skip Phase 1c, rely on web docs only |
| No new features found | Framework already up to date | Report "no upgrade needed" with evidence, skip Phases 4-5 |
| FRAMEWORK_DEEP_DIVE.md not found | Wrong workspace or missing file | Ask user for framework reference location |
| Backlog file not found | First run or different structure | Create new epic file, ask user for epic numbering |

## Reference: Documentation URLs

These URLs should be fetched in Phase 1b. If any fail, note the failure and continue with remaining pages.

```
https://code.claude.com/docs/en/hooks
https://code.claude.com/docs/en/settings
https://code.claude.com/docs/en/slash-commands
https://code.claude.com/docs/en/agents
https://code.claude.com/docs/en/claude-md
https://code.claude.com/docs/en/sub-agents
https://code.claude.com/docs/en/plugins
https://code.claude.com/docs/en/memory
```
