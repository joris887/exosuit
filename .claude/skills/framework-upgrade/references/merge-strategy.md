# Merge Strategy Reference

How to merge framework updates with project-specific customizations for each component type.

## Hooks

### engine.py

- **Strategy**: REPLACE (take new framework version)
- **Reason**: Core dispatch logic, error isolation improvements benefit all projects
- **Risk**: None — engine is generic

### handlers/pre_tool_use.py

- **Strategy**: REPLACE then verify
- **Preserve**: None (project rules are in safety.yaml, not in handler code)
- **Note**: Framework repo protection is generic and harmless

### handlers/session_start.py

- **Strategy**: MERGE
- **From new framework**: Dynamic tool detection (parsing CLAUDE.md Commands section)
- **From project**: Project-specific tool checks (e.g., language runtimes, package managers, custom CLIs)
- **Pattern**: Add project tools as fallback after dynamic detection

### handlers/stop.py, post_tool_use.py, user_prompt.py, subagent_stop.py, worktree.py

- **Strategy**: Usually IDENTICAL — diff before replacing
- **If identical**: Skip
- **If different**: REPLACE (these handlers are generic)

### rules/safety.yaml

- **Strategy**: MERGE
- **From new framework**: Base safety patterns (force push, rm -rf, package publish, etc.)
- **From project**: Project-specific patterns (custom blocking rules, tool restrictions)
- **Pattern**: Concatenate — new framework patterns first, project patterns after with comment separator

### rules/workflow.yaml, intent.yaml, quality.yaml, subagent.yaml

- **Strategy**: Usually REPLACE
- **Diff first**: These are typically unchanged between projects

### post-edit-format.sh

- **Strategy**: REPLACE (take comprehensive new version)
- **Reason**: More language support benefits future growth
- **Note**: Project-specific formatters are auto-detected by file extension

### lib/paths.py, lib/paths.sh

- **Strategy**: REPLACE (plugin mode support is backward-compatible)

### hooks.json

- **Strategy**: REPLACE (plugin distribution definitions, not used in template mode)

## Agents

### Shared agents (code-reviewer, security-analyst, architecture-reviewer, codebase-explorer)

- **Strategy**: REPLACE with new framework versions
- **Reason**: YAML frontmatter, temperature settings, improved prompts

### Project-only agents

- **Strategy**: PRESERVE — never overwrite
- **Detection**: Agent exists in current but not in new framework

### New agents (e.g., spec-reviewer, performance-engineer)

- **Strategy**: ADD — copy from framework

## Prompts

### All prompts

- **Strategy**: REPLACE existing, ADD new
- **Reason**: Prompts are generic micro-components; project customization happens in skills, not prompts
- **Exception**: If project has created custom prompts not in framework, PRESERVE them

## Rules

### code-slop.md

- **Strategy**: REPLACE
- **From new framework**: Broader language paths, enhanced anti-patterns
- **Project sections**: None (code-slop rules are universal)

### security.md

- **Strategy**: MERGE
- **From new framework**: Broader paths, enhanced CWE list, new vulnerability patterns
- **From project**: Project-specific security section (technology-specific concerns, custom security boundaries)
- **Pattern**: New framework base + project-specific section appended

### verification.md

- **Strategy**: MERGE
- **From new framework**: Rule effectiveness tracking, context relevance scoring, pre-compaction persistence
- **From project**: Project-specific verification commands section
- **Pattern**: New framework base + project commands section inserted after "Evidence Required"

### testing.md

- **Strategy**: PRESERVE (project version is more specific)
- **Reason**: Project testing rules include language-specific conventions, speed budgets, and tool exclusions that are tightly coupled to project toolchain
- **Enhancement**: Cherry-pick new anti-patterns from framework version if any

### dependencies.md

- **Strategy**: PRESERVE (project version is toolchain-specific)
- **Reason**: Package manager commands and audit tools are project-specific

### documentation.md

- **Strategy**: PRESERVE (project version has file size budgets)
- **Reason**: Session-loaded file budgets are project-specific knowledge

### edit-recovery.md, git.md

- **Strategy**: Usually IDENTICAL — diff and skip if same
- **If different**: Review diff carefully, REPLACE if safe

### Project-only rules

- **Strategy**: PRESERVE — never overwrite

## Skills

### Shared skills (story-cycle, sprint-start, sprint-end, etc.)

- **Strategy**: REPLACE SKILL.md + references/ with new framework versions
- **Reason**: Skills are generic workflow orchestrators; project customization is in CLAUDE.md, rules, and settings
- **Important**: New framework skills may reference micro-components — ensure prompts are updated first

### Project-only skills

- **Strategy**: PRESERVE — never overwrite
- **Detection**: Skill directory exists in current but not in new framework

### New skills from framework

- **Strategy**: ADD — create directory, copy SKILL.md + references/

## Documentation

### docs/reference/ files (TESTING_STRATEGY, MCP_INTEGRATION, CODING_STANDARDS, GROUND_RULES)

- **Strategy**: Diff first
- **If project has customized**: PRESERVE project version
- **If project uses framework template**: REPLACE

### docs/context/ files

- **Strategy**: PRESERVE if populated with project content
- **If empty/template**: POPULATE with project-specific content
- **If project has populated files but framework adds new template**: ADD new file, populate

### New directories (docs/solutions/, docs/brainstorms/)

- **Strategy**: ADD with .gitkeep if they don't exist

### SKILLS_INVENTORY.md

- **Strategy**: REGENERATE completely
- **Content**: All skills (updated + new + preserved) with correct versions

### CLAUDE.md

- **Strategy**: MERGE carefully
- **Update**: Framework version number, skills table (add new skills), docs references (add new docs)
- **Preserve**: Everything else (project overview, commands, architecture, testing, current focus, backlog, compaction directives)

### llms.txt

- **Strategy**: UPDATE with current project stats
- **Update**: File counts, test counts, skill counts, framework version

### scripts/pm/

- **Strategy**: ADD or REPLACE (generic scripts)
