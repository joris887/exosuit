#!/usr/bin/env bash
set -euo pipefail

# update-registry.sh — Walk all skills and generate a JSON registry
# Usage: bash update-registry.sh

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: bash update-registry.sh"
  echo ""
  echo "Walks .claude/skills/*/SKILL.md, extracts YAML frontmatter,"
  echo "and outputs a JSON registry to .claude/skills/skills-registry.json"
  echo ""
  echo "The registry contains: name, version, description, trigger,"
  echo "depends-on, references, and file path for each skill."
  exit 0
fi

SKILLS_DIR=".claude/skills"
REGISTRY_FILE="$SKILLS_DIR/skills-registry.json"

echo "[" > "$REGISTRY_FILE"

first=true
for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -f "$skill_file" ]] || continue

  # Extract YAML frontmatter between --- markers
  in_frontmatter=false
  name="" version="" description="" trigger=""
  depends_on="[]" references="[]"

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if $in_frontmatter; then
        break
      else
        in_frontmatter=true
        continue
      fi
    fi

    if $in_frontmatter; then
      case "$line" in
        name:*)       name="${line#name: }" ;;
        version:*)    version="${line#version: }" ;;
        description:*) description="${line#description: }" ;;
        trigger:*)    trigger="${line#trigger: }" ;;
        depends-on:*) depends_on="${line#depends-on: }" ;;
        references:*) references="${line#references: }" ;;
      esac
    fi
  done < "$skill_file"

  [[ -z "$name" ]] && continue

  # Convert YAML lists to JSON arrays
  depends_json=$(echo "$depends_on" | sed 's/\[//;s/\]//;s/,/","/g')
  [[ -n "$depends_json" ]] && depends_json="[\"$depends_json\"]" || depends_json="[]"
  # Handle empty list
  [[ "$depends_json" == '[""]' ]] && depends_json="[]"

  refs_json=$(echo "$references" | sed 's/\[//;s/\]//;s/,/","/g')
  [[ -n "$refs_json" ]] && refs_json="[\"$refs_json\"]" || refs_json="[]"
  [[ "$refs_json" == '[""]' ]] && refs_json="[]"

  if $first; then
    first=false
  else
    echo "," >> "$REGISTRY_FILE"
  fi

  cat >> "$REGISTRY_FILE" << EOF
  {
    "name": "$name",
    "version": "$version",
    "description": "$description",
    "trigger": "$trigger",
    "depends_on": $depends_json,
    "references": $refs_json,
    "path": "$skill_file"
  }
EOF

done

echo "]" >> "$REGISTRY_FILE"

skill_count=$(grep -c '"name"' "$REGISTRY_FILE" || echo 0)
echo "Registry updated: $REGISTRY_FILE ($skill_count skills)"
