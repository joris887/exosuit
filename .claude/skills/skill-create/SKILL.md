______________________________________________________________________

## name: skill-create description: Analyze the repository's technology stack and generate appropriate skills, rules, and hook configurations. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

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

Create a reference doc (`docs/reference/tech/<name>.md`) when:

- Technology is core (>20% of codebase interaction)
- API is complex with project-specific patterns
- Version-specific gotchas exist that an LLM would miss
- Official documentation is large and we use a specific subset

Skip reference doc when:

- Usage is standard/well-known (e.g., JSON, basic HTTP)
- Official docs are concise and sufficient
- No project-specific patterns worth documenting

## 3. Generate Skills

For each technology that warrants a skill, create:

### Skill File Structure

```
.claude/skills/<tech-name>/SKILL.md
```

### Skill Content Template

Each generated skill should include:

1. **Purpose:** What this technology does in the project
1. **Version:** Specific version in use (pinned)
1. **Patterns:** Project-specific patterns and conventions
1. **Common Tasks:** How to accomplish typical tasks with this technology
1. **Pitfalls:** Known issues, gotchas, anti-patterns
1. **References:** Links to official documentation
1. **Examples:** Code snippets from the actual codebase showing correct usage

### Reference Doc Template (when created)

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
- **Linter found** → Add to `pre-stop-quality.sh`
- **Type checker found** → Add to `pre-stop-quality.sh`
- **Test runner found** → Add to `pre-stop-quality.sh`

Update `.claude/hooks/` scripts and `.claude/settings.json` as needed.

## 6. Version Management

For each technology with a reference doc:

- Record the current version
- Note when the reference doc was last verified
- Flag if a major version update is available

## 7. Update Inventory

After creating all skills:

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

## Rules

- NEVER create skills for trivial/standard technologies (basic Python, JSON, HTTP)
- NEVER duplicate content that's already in existing skills
- ALWAYS pin versions in reference docs
- ALWAYS include examples from the actual codebase, not generic examples
- ALWAYS check for existing skills before creating new ones
- Reference docs go in `docs/reference/tech/`, skill files in `.claude/skills/<name>/`
- Follow the skill template in `.claude/skills/SKILL_TEMPLATE.md`
