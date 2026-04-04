#!/usr/bin/env bash
set -euo pipefail

# JD-LLM Development Framework — Installer
#
# Copies the framework into the current project directory.
# Won't overwrite existing project files (except settings.json which is framework-managed).
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/joris887/JD-LLM-Development_framework/main/install.sh | bash
#   bash install.sh
#   bash install.sh --dry-run

REPO_URL="https://github.com/joris887/JD-LLM-Development_framework.git"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)  DRY_RUN=true ;;
        --help|-h)
            echo "Usage: install.sh [--dry-run]"
            echo "  Installs the JD-LLM Development Framework into the current directory."
            echo "  --dry-run  Preview what would be installed without making changes."
            exit 0
            ;;
    esac
done

echo "=== JD-LLM Development Framework ==="
echo "Installing into: $(pwd)"
$DRY_RUN && echo "(Dry run — no files will be modified)"
echo ""

# Clone to temp directory
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT
echo "Fetching framework..."
git clone --quiet --depth 1 "$REPO_URL" "$TMP/fw"
SRC="$TMP/fw"

# --- Helpers ---
run() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@" 2>/dev/null || true
    fi
}

# --- 1. Core framework (.claude/) ---
# Copy all framework files. Won't overwrite existing files (user customizations preserved).
# settings.json is always overwritten — it's framework-managed, not user-editable.
echo "Installing core framework (.claude/)..."
run cp -rn "$SRC/.claude" .
if $DRY_RUN; then
    echo "  [dry-run] Would overwrite .claude/settings.json"
else
    cp "$SRC/.claude/settings.json" .claude/settings.json
fi

# --- 2. Project scaffold (docs/, vision/, scripts/, etc.) ---
# Everything in scaffold/ maps to the project root. Won't overwrite existing files.
echo "Installing project scaffold..."
if [ -d "$SRC/scaffold" ]; then
    run cp -rn "$SRC/scaffold/." .
fi

# --- 3. Entry point + GitHub integration ---
echo "Installing entry point and GitHub integration..."
run cp -n "$SRC/CLAUDE.md" .
[ -d "$SRC/.github" ] && run cp -rn "$SRC/.github" .
[ ! -e AGENTS.md ] && run ln -s CLAUDE.md AGENTS.md

# --- 4. Gitignore patterns ---
# Patterns are stored in the framework (.gitignore.framework), not hardcoded in this script.
if [ -f "$SRC/.gitignore.framework" ]; then
    echo "Updating .gitignore..."
    if $DRY_RUN; then
        echo "  [dry-run] Would append framework patterns to .gitignore"
    else
        touch .gitignore
        while IFS= read -r line; do
            # Skip empty lines and comments
            [ -z "$line" ] || [ "${line:0:1}" = "#" ] && continue
            grep -qxF "$line" .gitignore 2>/dev/null || echo "$line" >> .gitignore
        done < "$SRC/.gitignore.framework"
    fi
fi

echo ""
echo "=== Installed ==="
echo ""
echo "Next steps:"
echo "  1. Open Claude Code in this directory"
echo "  2. Run /quickstart (guided tour) or /bootstrap (direct setup)"
echo ""
