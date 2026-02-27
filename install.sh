#!/usr/bin/env bash
set -euo pipefail

# JD-LLM Development Framework — Drop-in Installer
#
# Prerequisites:
#   Python 3.8+ (required for hook engine)
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

# Capture project root as absolute path (used for hook path resolution)
PROJECT_ROOT="$(pwd)"

# Verify we're in a project root (has .git or common project files)
if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "pyproject.toml" ] && [ ! -f "Cargo.toml" ] && [ ! -f "go.mod" ] && [ ! -f "Gemfile" ]; then
    echo "Warning: This doesn't look like a project root."
    echo "Current directory: $PROJECT_ROOT"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. cd to your project root and run again."
        exit 1
    fi
fi

# --- Python 3 detection (required for hook engine) ---
if [ "$MODE" = "template" ]; then
    PYTHON_PATH=$(command -v python3 2>/dev/null || true)
    if [ -z "$PYTHON_PATH" ]; then
        echo "ERROR: Python 3.8+ is required for the JD-LLM Framework hook engine."
        echo ""
        echo "The hook engine (engine.py) enforces quality gates, security checks,"
        echo "and workflow rules. It runs regardless of your project's language."
        echo ""
        echo "Install Python 3:"
        echo "  macOS:   brew install python3"
        echo "  Ubuntu:  sudo apt install python3"
        echo "  Fedora:  sudo dnf install python3"
        echo "  Windows: https://www.python.org/downloads/"
        echo ""
        echo "Then re-run this installer."
        exit 1
    fi

    # Check minimum version (3.8+)
    PYTHON_VERSION=$("$PYTHON_PATH" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "unknown")
    if [ "$PYTHON_VERSION" != "unknown" ]; then
        PYTHON_MAJOR=$("$PYTHON_PATH" -c 'import sys; print(sys.version_info.major)' 2>/dev/null || echo "0")
        PYTHON_MINOR=$("$PYTHON_PATH" -c 'import sys; print(sys.version_info.minor)' 2>/dev/null || echo "0")
        if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]; }; then
            echo "WARNING: Python $PYTHON_VERSION detected at $PYTHON_PATH"
            echo "The framework requires Python 3.8+. Some hook features may not work."
            echo ""
            read -p "Continue with Python $PYTHON_VERSION? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Aborted. Install Python 3.8+ and try again."
                exit 1
            fi
        fi
    fi

    echo "  Python:       $PYTHON_PATH (version $PYTHON_VERSION)"
    echo "  Project root: $PROJECT_ROOT"
    echo ""
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
    # Core: hooks, skills, rules, agents, prompts (won't overwrite existing)
    cp -rn "$FRAMEWORK_DIR/.claude" . 2>/dev/null || true

    # Always update settings.json — it's framework-managed, not user-customizable
    # User customizations belong in settings.local.json
    cp "$FRAMEWORK_DIR/.claude/settings.json" .claude/settings.json

    # Replace placeholders with absolute paths for reliable hook resolution
    # Uses | delimiter since paths don't contain pipe characters
    tmp_settings=$(mktemp)
    sed "s|__PROJECT_ROOT__|${PROJECT_ROOT}|g; s|__PYTHON_PATH__|${PYTHON_PATH}|g" ".claude/settings.json" > "$tmp_settings"
    mv "$tmp_settings" ".claude/settings.json"
    echo "  Hook paths configured for: $PROJECT_ROOT"
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
