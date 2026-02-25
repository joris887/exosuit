---
name: skill-create
version: 2.4.0
description: Analyze the repository's technology stack and generate appropriate skills, rules, and hook configurations.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## skill-create

Analyzing repository and generating technology skills.

## 1. Scan Repository

Identify technologies, frameworks, and tools in use:

### 1a. Parse dependency files

Scan for all dependency/config files in the project:

- `package.json`, `pyproject.toml`, `Cargo.toml`, `Package.swift`
- `go.mod`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`
- `.pre-commit-config.yaml`, CI configuration files

### 1b. Scan imports and usage

Identify major technology areas by scanning source code imports and configuration files.

### 1c. Check existing skills

Read `.claude/skills/SKILLS_INVENTORY.md` to avoid creating duplicates.

## 2. Classify Technologies

Categorize each technology by impact and relevance:

| Category                                  | Examples                     | Skill Priority                         |
| ----------------------------------------- | ---------------------------- | -------------------------------------- |
| **Core Framework** (>20% of codebase)     | React, Django, Rails, SwiftUI | High — create skill + reference doc    |
| **Major Library** (significant usage)     | SQLite, Redis, Prisma        | Medium — create skill                  |
| **Build/Dev Tool** (development workflow) | webpack, jest, ruff          | Low — create skill if complex          |
| **Minor Dependency** (small usage)        | lodash, httpx, pydantic      | Skip — standard usage, no skill needed |

### Decision Criteria for Reference Documents

Create reference docs **co-located with the skill** (`.claude/skills/<tech-name>/references/`) when:

- Technology is core (>20% of codebase interaction)
- API is complex with project-specific patterns
- Version-specific gotchas exist that an LLM would miss
- Official documentation is large and we use a specific subset

Co-locating references with skills keeps everything self-contained and allows relative path references from SKILL.md.

Skip reference doc when:

- Usage is standard/well-known (e.g., JSON, basic HTTP)
- Official docs are concise and sufficient
- No project-specific patterns worth documenting

## 3. Generate Skills

For each technology that warrants a skill, scaffold using:

```bash
bash scripts/init-skill.sh <tech-name>
```

Execute directly — do NOT read script source first.

### Skill File Structure

```
.claude/skills/<tech-name>/
├── SKILL.md              # Lean (<100 lines): purpose, version, key patterns, pointers
└── references/            # Loaded on demand
    ├── api.md             # API patterns and quick reference
    ├── gotchas.md         # Version-specific issues and workarounds
    └── examples.md        # Code snippets from the actual codebase
```

### SKILL.md Content (keep under 100 lines)

Each generated skill SKILL.md should include:

1. **Purpose:** What this technology does in the project
1. **Version:** Specific version in use (pinned)
1. **Patterns:** Project-specific patterns and conventions (brief)
1. **Common Tasks:** How to accomplish typical tasks (brief)
1. **Pointers:** "See `references/api.md` for detailed API patterns" etc.

Move detailed content to references/ to keep SKILL.md lean. The context window is a shared resource — only load detail when needed.

### Reference Doc Template (when created, co-located in references/)

```markdown
# <Technology> Reference (v<version>)

## Usage in This Project
<What we use it for, how it fits in the architecture>

## Key Patterns
<Project-specific patterns with code examples>

## API Quick Reference
<The subset of the API we actually use>

## Configuration
<Our configuration settings and why>

## Gotchas
<Version-specific issues, known bugs, workarounds>

## Official Documentation
<Links to official docs for our version>
```

## 4. Generate Path-Scoped Rules

For detected file types that don't already have rules:

- If a linter/formatter was detected, create or update rules referencing its config
- If the project has specific file patterns (e.g., `*.component.tsx`, `*.service.py`), add path-scoped rules for those patterns
- Create per-module rules if major modules have distinct conventions

Save rules to `.claude/rules/<rule-name>.md` with YAML frontmatter containing `paths:`.

## 5. Configure Hooks

Based on detected tools:

- **Formatter found** → Configure `post-edit-format.sh` for the detected formatter
- **Linter found** → Add to `.claude/hooks/rules/quality.yaml`
- **Type checker found** → Add to `.claude/hooks/rules/quality.yaml`
- **Test runner found** → Add to `.claude/hooks/rules/quality.yaml`

Update `.claude/hooks/` scripts and `.claude/settings.json` as needed.

## 6. Version Management

For each technology with a reference doc:

- Record the current version
- Note when the reference doc was last verified
- Flag if a major version update is available

## 7. Update Inventory

After creating all skills:

- Run `bash scripts/update-registry.sh` to regenerate `skills-registry.json`
- Update `.claude/skills/SKILLS_INVENTORY.md` with new technology skills
- Add entries to the Technology Skills category
- List each skill with its technology, version, and whether it has a reference doc

## 8. Output

Present a summary:

```markdown
### Skill Creation Complete

**Technologies analyzed:** [count]
**Skills created:** [count]
**Reference docs created:** [count]
**Rules created:** [count]
**Hooks configured:** [list]
**Skills skipped (already exists or not needed):** [count]

#### Created Skills:
| Technology | Skill | Reference Doc | Version |
|---|---|---|---|
| [name] | `/[skill-name]` | Yes/No | [version] |

#### Rules Created:
| Rule | Paths | Purpose |
|---|---|---|
| [name] | [patterns] | [what it enforces] |

#### Skipped (standard/minor):
- [list of technologies that didn't warrant skills]
```

## Common Mistakes — NEVER:

| Bad Output | Why It's Wrong | What To Do Instead |
|---|---|---|
| Generic content Claude already knows | Wastes context window on every invocation | Only include project-specific patterns and gotchas |
| Skill >150 lines without references/ | Exceeds context budget | Split into lean SKILL.md + references/ |
| Examples from training data, not codebase | Doesn't match project conventions | Use actual code from the repo as examples |
| Documenting standard API usage | Claude knows standard APIs | Document project-specific patterns and version gotchas |

## Rules

- NEVER create skills for trivial/standard technologies (basic Python, JSON, HTTP)
- NEVER duplicate content that's already in existing skills
- ALWAYS pin versions in reference docs
- ALWAYS include examples from the actual codebase, not generic examples
- ALWAYS check for existing skills before creating new ones
- Reference docs go in `.claude/skills/<name>/references/` (co-located with the skill)
- Follow the skill template in `.claude/skills/SKILL_TEMPLATE.md`
