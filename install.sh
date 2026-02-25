#!/usr/bin/env bash
set -euo pipefail

# JD-LLM Development Framework — Drop-in Installer
#
# Modes:
#   --mode=template  (default) Clone repo and install everything (core + scaffold)
#   --mode=plugin    Install scaffold files only (core provided by Claude Code plugin)
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/joris887/JD-LLM-Development_framework/main/install.sh | bash
#   bash install.sh
#   bash install.sh --mode=plugin

REPO_URL="https://github.com/joris887/JD-LLM-Development_framework.git"
MODE="template"

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --mode=plugin)  MODE="plugin" ;;
        --mode=template) MODE="template" ;;
        --help|-h)
            echo "Usage: install.sh [--mode=template|--mode=plugin]"
            echo "  template (default): Install full framework (core + scaffold)"
            echo "  plugin:             Install scaffold only (core via Claude Code plugin)"
            exit 0
            ;;
    esac
done

echo "=== JD-LLM Development Framework Installer ==="
echo "Mode: $MODE"
echo ""

# Verify we're in a project root (has .git or common project files)
if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "pyproject.toml" ] && [ ! -f "Cargo.toml" ] && [ ! -f "go.mod" ] && [ ! -f "Gemfile" ]; then
    echo "Warning: This doesn't look like a project root."
    echo "Current directory: $(pwd)"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. cd to your project root and run again."
        exit 1
    fi
fi

TMP_DIR=$(mktemp -d)
FRAMEWORK_DIR="$TMP_DIR/jd-framework"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Cloning framework..."
git clone --quiet "$REPO_URL" "$FRAMEWORK_DIR"

# Determine the source for scaffold files
SCAFFOLD_SRC="$FRAMEWORK_DIR/scaffold"
if [ ! -d "$SCAFFOLD_SRC" ]; then
    # Fallback: older repo without scaffold/ — use root-level files
    SCAFFOLD_SRC="$FRAMEWORK_DIR"
fi

echo "Copying scaffold files (won't overwrite existing files)..."

# Scaffold files: project templates
cp -rn "$SCAFFOLD_SRC/docs" . 2>/dev/null || true
cp -rn "$SCAFFOLD_SRC/vision" . 2>/dev/null || true
cp -rn "$SCAFFOLD_SRC/scripts" . 2>/dev/null || true
cp -n "$SCAFFOLD_SRC/CLAUDE.md" . 2>/dev/null || true
cp -n "$SCAFFOLD_SRC/llms.txt" . 2>/dev/null || true
cp -n "$SCAFFOLD_SRC/CLAUDE.local.md.template" . 2>/dev/null || true

if [ "$MODE" = "template" ]; then
    echo "Copying core framework files..."
    # Core: hooks, skills, rules, agents, prompts, settings
    cp -rn "$FRAMEWORK_DIR/.claude" . 2>/dev/null || true
fi

# Create AGENTS.md symlink if it doesn't exist
if [ ! -e "AGENTS.md" ]; then
    ln -s CLAUDE.md AGENTS.md
    echo "  Created AGENTS.md -> CLAUDE.md symlink"
fi

# Update .gitignore — append framework patterns if not present
GITIGNORE_PATTERNS=(
    "CLAUDE.local.md"
    ".claude/settings.local.json"
    "*.session-handoff.md"
)

if [ -f ".gitignore" ]; then
    for pattern in "${GITIGNORE_PATTERNS[@]}"; do
        if ! grep -qF "$pattern" .gitignore; then
            echo "$pattern" >> .gitignore
            echo "  Added '$pattern' to .gitignore"
        fi
    done
else
    printf '%s\n' "${GITIGNORE_PATTERNS[@]}" > .gitignore
    echo "  Created .gitignore with framework patterns"
fi

# Create directories
mkdir -p docs/sessions docs/plans

echo ""
echo "=== Installation Complete ==="
echo ""

if [ "$MODE" = "template" ]; then
    echo "Files installed (template mode):"
    echo "  .claude/skills/    — Framework skills"
    echo "  .claude/rules/     — Path-scoped rules"
    echo "  .claude/hooks/     — Hook scripts"
    echo "  .claude/agents/    — Expert agent personas"
    echo "  .claude/prompts/   — Prompt templates"
    echo "  docs/              — Documentation templates"
    echo "  vision/            — New project braindump flow"
    echo "  CLAUDE.md          — Framework entry point"
    echo "  AGENTS.md          — Cross-tool compatibility"
    echo "  llms.txt           — LLM-friendly project index"
else
    echo "Files installed (plugin mode — core via Claude Code plugin):"
    echo "  docs/              — Documentation templates"
    echo "  vision/            — New project braindump flow"
    echo "  CLAUDE.md          — Framework entry point"
    echo "  AGENTS.md          — Cross-tool compatibility"
    echo "  llms.txt           — LLM-friendly project index"
fi

echo ""
echo "Next steps:"
echo "  1. Open Claude Code in this directory"
echo "  2. Run: /bootstrap"
echo "  3. Follow the prompts to configure for your stack"
echo ""
