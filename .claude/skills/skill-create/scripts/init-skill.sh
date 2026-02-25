#!/usr/bin/env bash
set -euo pipefail

# init-skill.sh — Scaffold a new skill directory with SKILL.md template
# Usage: bash init-skill.sh <skill-name>

if [[ "${1:-}" == "--help" ]] || [[ -z "${1:-}" ]]; then
  echo "Usage: bash init-skill.sh <skill-name>"
  echo ""
  echo "Creates a new skill directory under .claude/skills/ with:"
  echo "  SKILL.md       — Skill file with YAML frontmatter and standard sections"
  echo "  references/    — Directory for on-demand reference docs"
  echo "  scripts/       — Directory for executable helper scripts"
  echo "  assets/        — Directory for output templates"
  echo ""
  echo "Example: bash init-skill.sh my-new-skill"
  exit 0
fi

SKILL_NAME="$1"
SKILL_DIR=".claude/skills/${SKILL_NAME}"

if [[ -d "$SKILL_DIR" ]]; then
  echo "ERROR: Skill directory already exists: $SKILL_DIR"
  exit 1
fi

mkdir -p "$SKILL_DIR"/{references,scripts,assets}

cat > "$SKILL_DIR/SKILL.md" << 'TEMPLATE'
---
name: SKILL_NAME_PLACEHOLDER
version: 2.5.0
description: TODO — one-line description (trigger conditions only, not workflow summary)
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## SKILL_NAME_PLACEHOLDER

TODO — Describe what this skill does when invoked.

## Process Flow

```
START → TODO: define process steps → DONE
```

## Rules

- Follow coding standards in `docs/reference/CODING_STANDARDS.md`

## Evaluation Criteria

- [ ] TODO: define expected behavior under normal conditions
- [ ] TODO: define pressure scenario
TEMPLATE

# Replace placeholder with actual skill name
sed -i '' "s/SKILL_NAME_PLACEHOLDER/${SKILL_NAME}/g" "$SKILL_DIR/SKILL.md"

echo "Skill scaffolded at: $SKILL_DIR/"
echo "  SKILL.md       — Edit to define your skill"
echo "  references/    — Add reference docs here"
echo "  scripts/       — Add helper scripts here"
echo "  assets/        — Add output templates here"
echo ""
echo "Next: Edit SKILL.md, then run scripts/update-registry.sh to update the registry."
