#!/usr/bin/env bash
set -euo pipefail

# Exosuit — Installer
#
# Copies the framework into the current project directory.
# Won't overwrite existing project files unless --force is used.
# settings.json is always overwritten (framework-managed).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joris887/exosuit/main/install.sh | bash
#   (Windows: install.ps1 wraps this script via Git Bash)
#   bash install.sh
#   bash install.sh --mode=plugin
#   bash install.sh --components=hooks,rules
#   bash install.sh --dry-run
#   bash install.sh --force
#
# Modes:
#   --mode=template  (default) Install core framework (.claude/) + project scaffold
#   --mode=plugin    Install project scaffold only (core provided by Claude Code plugin)
#
# Options:
#   --components=X   Comma-separated .claude/ subdirectories to install (template mode only).
#                    Default: all. Components are auto-detected from the framework — no
#                    hardcoded list. Run --dry-run to see what's available.
#   --force          Overwrite existing framework files (clean reinstall).
#   --dry-run        Preview what would be installed without making changes.
#
# Environment:
#   REPO_URL         Override the default repository URL (e.g., for SSH access).

REPO_HTTPS="https://github.com/joris887/exosuit.git"
REPO_SSH="git@github.com:joris887/exosuit.git"
MODE="template"
DRY_RUN=false
FORCE=false
COMPONENTS="all"

for arg in "$@"; do
    case "$arg" in
        --mode=template) MODE="template" ;;
        --mode=plugin)   MODE="plugin" ;;
        --dry-run)       DRY_RUN=true ;;
        --force)         FORCE=true ;;
        --components=*)  COMPONENTS="${arg#--components=}" ;;
        --help|-h)
            echo "Usage: install.sh [OPTIONS]"
            echo ""
            echo "Modes:"
            echo "  --mode=template  Install full framework (default)"
            echo "  --mode=plugin    Install scaffold only (core via Claude Code plugin)"
            echo ""
            echo "Options:"
            echo "  --components=X   Comma-separated .claude/ subdirectories (template mode)"
            echo "                   Default: all. Auto-detected from framework contents."
            echo "  --force          Overwrite existing framework files (clean reinstall)"
            echo "  --dry-run        Preview without making changes"
            echo ""
            echo "Environment:"
            echo "  REPO_URL         Override the default repository URL"
            exit 0
            ;;
    esac
done

echo "=== Exosuit: Development Framework for Claude Code ==="
echo "Mode: $MODE"
$DRY_RUN && echo "Dry run: yes"
$FORCE && echo "Force: yes (overwriting existing files)"
[ "$COMPONENTS" != "all" ] && echo "Components: $COMPONENTS"
echo "Target: $(pwd)"
echo ""

# Clone to temp directory
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT
echo "Fetching framework..."

# Use REPO_URL env var if set, otherwise try HTTPS then fall back to SSH
if [ -n "${REPO_URL:-}" ]; then
    git clone --quiet --depth 1 "$REPO_URL" "$TMP/fw"
elif git clone --quiet --depth 1 "$REPO_HTTPS" "$TMP/fw" 2>/dev/null; then
    : # HTTPS succeeded
else
    rm -rf "$TMP/fw"  # clean up partial HTTPS clone
    echo "  HTTPS clone failed, trying SSH..."
    git clone --quiet --depth 1 "$REPO_SSH" "$TMP/fw"
fi
SRC="$TMP/fw"

# --- Helpers ---
# --force: overwrite existing files; default: no-clobber
# Note: variables are intentionally unquoted in cp calls so empty strings vanish
if $FORCE; then
    CP_DIR="-r"
    CP_FILE=
else
    CP_DIR="-rn"
    CP_FILE="-n"
fi

run() {
    if $DRY_RUN; then
        # Show clean paths instead of temp directory
        local display="${*//$SRC/[framework]}"
        echo "  [dry-run] $display"
    else
        "$@" 2>/dev/null || true
    fi
}

# --- 1. Core framework (.claude/) — template mode only ---
if [ "$MODE" = "template" ]; then
    echo "Installing core framework (.claude/)..."

    if [ "$COMPONENTS" = "all" ]; then
        # Copy everything — any new skill/rule/hook is auto-included
        run cp $CP_DIR "$SRC/.claude" .
    else
        # Selective: copy only requested subdirectories + root-level files
        mkdir -p .claude
        # Always copy root-level files in .claude/ (settings, templates, CLAUDE.md)
        for f in "$SRC/.claude"/*; do
            if [ -f "$f" ]; then
                run cp $CP_FILE "$f" .claude/
            fi
        done
        # Copy each requested component (auto-validated against what exists)
        IFS=',' read -ra SELECTED <<< "$COMPONENTS"
        for comp in "${SELECTED[@]}"; do
            comp=$(echo "$comp" | tr -d ' ')
            if [ -d "$SRC/.claude/$comp" ]; then
                echo "  Installing $comp..."
                run cp $CP_DIR "$SRC/.claude/$comp" .claude/
            else
                echo "  Warning: '$comp' not found in .claude/ — skipping"
                echo "  Available: $(ls -d "$SRC/.claude"/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ' ')"
            fi
        done
        echo "  Note: Partial install — some skills may require components you didn't include."
    fi

    # settings.json is always overwritten — it's framework-managed
    if $DRY_RUN; then
        echo "  [dry-run] Would overwrite .claude/settings.json (framework-managed)"
    else
        cp "$SRC/.claude/settings.json" .claude/settings.json
    fi
else
    [ "$COMPONENTS" != "all" ] && echo "  Note: --components ignored in plugin mode (core comes from plugin)"
fi

# --- 2. Project scaffold (docs/, vision/, scripts/, etc.) ---
# Everything in scaffold/ maps to the project root. Won't overwrite unless --force.
echo "Installing project scaffold..."
if [ -d "$SRC/scaffold" ]; then
    run cp $CP_DIR "$SRC/scaffold/." .
else
    echo "  Warning: scaffold/ not found in framework"
fi

# --- 3. Entry point + GitHub integration ---
echo "Installing entry point..."
run cp $CP_FILE "$SRC/CLAUDE.md" .
if [ -d "$SRC/.github" ]; then
    run cp $CP_DIR "$SRC/.github" .
fi
if [ ! -e AGENTS.md ]; then
    run ln -s CLAUDE.md AGENTS.md
fi

# --- 4. Gitignore patterns ---
# Patterns are stored in the framework (.gitignore.framework), not hardcoded here.
if [ -f "$SRC/.gitignore.framework" ]; then
    echo "Updating .gitignore..."
    if $DRY_RUN; then
        echo "  [dry-run] Would append framework patterns from .gitignore.framework"
    else
        touch .gitignore
        while IFS= read -r line; do
            # Skip empty lines and comments
            [ -z "$line" ] || [ "${line:0:1}" = "#" ] && continue
            grep -qxF "$line" .gitignore 2>/dev/null || echo "$line" >> .gitignore
        done < "$SRC/.gitignore.framework"
    fi
fi

# --- Summary ---
echo ""
echo "=== Installed ==="
if [ "$MODE" = "template" ]; then
    echo "  .claude/        Core framework (skills, hooks, rules, agents, prompts)"
fi
echo "  docs/           Documentation templates"
echo "  vision/         New project discovery flow"
echo "  CLAUDE.md       Framework entry point"
echo "  .github/        PR template, CODEOWNERS template, Claude PR-review workflow"
echo ""
echo "Next steps:"
echo "  1. Open Claude Code in this directory"
echo "  2. Run /quickstart (guided tour) or /bootstrap (direct setup)"
echo ""
echo "Note: the Claude PR-review workflow only activates after you add an"
echo "      ANTHROPIC_API_KEY secret to your GitHub repo — until then it skips"
echo "      itself silently. CODEOWNERS ships fully commented out; edit it to"
echo "      enable required reviews."
echo ""
