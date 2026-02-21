#!/usr/bin/env bash
set -euo pipefail

# JD-LLM Development Framework — Drop-in Installer
# Usage: curl -sL https://raw.githubusercontent.com/joris887/JD-LLM-Development_framework/main/install.sh | bash
#    or: bash install.sh

REPO_URL="https://github.com/joris887/JD-LLM-Development_framework.git"
TMP_DIR=$(mktemp -d)
FRAMEWORK_DIR="$TMP_DIR/jd-framework"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "=== JD-LLM Development Framework Installer ==="
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

echo "Cloning framework..."
git clone --quiet "$REPO_URL" "$FRAMEWORK_DIR"

echo "Copying framework files (won't overwrite existing files)..."

# Copy directories (no-clobber)
cp -rn "$FRAMEWORK_DIR/.claude" . 2>/dev/null || true
cp -rn "$FRAMEWORK_DIR/docs" . 2>/dev/null || true
cp -rn "$FRAMEWORK_DIR/vision" . 2>/dev/null || true

# Copy root files (no-clobber)
cp -n "$FRAMEWORK_DIR/CLAUDE.md" . 2>/dev/null || true
cp -n "$FRAMEWORK_DIR/llms.txt" . 2>/dev/null || true

# Create AGENTS.md symlink if it doesn't exist
if [ ! -e "AGENTS.md" ]; then
    ln -s CLAUDE.md AGENTS.md
    echo "  Created AGENTS.md → CLAUDE.md symlink"
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
echo "Files installed:"
echo "  .claude/skills/    — Framework skills"
echo "  .claude/rules/     — Path-scoped rules"
echo "  .claude/hooks/     — Hook scripts"
echo "  docs/              — Documentation templates"
echo "  vision/            — New project braindump flow"
echo "  CLAUDE.md          — Framework entry point"
echo "  AGENTS.md          — Cross-tool compatibility"
echo "  llms.txt           — LLM-friendly project index"
echo ""
echo "Next steps:"
echo "  1. Open Claude Code in this directory"
echo "  2. Run: /bootstrap"
echo "  3. Follow the prompts to configure for your stack"
echo ""
