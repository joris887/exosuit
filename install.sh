#!/usr/bin/env bash
set -euo pipefail

# JD-LLM Development Framework — Drop-in Installer
#
# Prerequisites: None (POSIX shell + git only)
#
# Modes:
#   --mode=template  (default) Clone repo and install everything (core + scaffold)
#   --mode=plugin    Install scaffold files only (core provided by Claude Code plugin)
#
# Options:
#   --dry-run        Show what would be installed without making changes
#   --components=X   Comma-separated list of components to install (template mode only)
#                    Available: hooks,rules,skills,agents,prompts,scaffold,github
#                    Default: all
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/joris887/JD-LLM-Development_framework/main/install.sh | bash
#   bash install.sh
#   bash install.sh --mode=plugin
#   bash install.sh --dry-run
#   bash install.sh --components=hooks,rules,skills

REPO_URL="https://github.com/joris887/JD-LLM-Development_framework.git"
MODE="template"
DRY_RUN=false
COMPONENTS="all"

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --mode=plugin)  MODE="plugin" ;;
        --mode=template) MODE="template" ;;
        --dry-run)      DRY_RUN=true ;;
        --components=*) COMPONENTS="${arg#--components=}" ;;
        --help|-h)
            echo "Usage: install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --mode=template   Install full framework (default)"
            echo "  --mode=plugin     Install scaffold only (core via Claude Code plugin)"
            echo "  --dry-run         Show what would be installed without making changes"
            echo "  --components=X    Comma-separated components (template mode only):"
            echo "                    hooks,rules,skills,agents,prompts,scaffold,github"
            echo "                    Default: all"
            echo ""
            echo "Examples:"
            echo "  bash install.sh                         # Full install"
            echo "  bash install.sh --dry-run               # Preview install"
            echo "  bash install.sh --components=hooks,rules # Hooks + rules only"
            exit 0
            ;;
    esac
done

echo "=== JD-LLM Development Framework Installer ==="
echo "Mode: $MODE"
$DRY_RUN && echo "Dry run: YES (no files will be modified)"
[ "$COMPONENTS" != "all" ] && echo "Components: $COMPONENTS"
echo ""

# Capture project root as absolute path (used for hook path resolution)
PROJECT_ROOT="$(pwd)"

# Verify we're in a project root (has .git or common project files)
if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "pyproject.toml" ] && [ ! -f "Cargo.toml" ] && [ ! -f "go.mod" ] && [ ! -f "Gemfile" ]; then
    echo "Warning: This doesn't look like a project root."
    echo "Current directory: $PROJECT_ROOT"
    if $DRY_RUN; then
        echo "[DRY RUN] Would prompt for confirmation."
    else
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted. cd to your project root and run again."
            exit 1
        fi
    fi
fi

if [ "$MODE" = "template" ]; then
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
    SCAFFOLD_SRC="$FRAMEWORK_DIR"
fi

# --- Helper: check if a component is requested ---
has_component() {
    [ "$COMPONENTS" = "all" ] && return 0
    case ",$COMPONENTS," in
        *",$1,"*) return 0 ;;
    esac
    return 1
}

# --- Helper: safe copy (respects dry-run) ---
safe_cp() {
    local flags="$1"
    shift
    if $DRY_RUN; then
        for src in "$@"; do
            local last="${@: -1}"
            # Skip the last arg (destination) when listing sources
            if [ "$src" != "$last" ]; then
                echo "  [DRY RUN] Would copy: $src -> $last"
            fi
        done
    else
        cp $flags "$@" 2>/dev/null || true
    fi
}

# --- Helper: safe mkdir (respects dry-run) ---
safe_mkdir() {
    if $DRY_RUN; then
        echo "  [DRY RUN] Would create directory: $1"
    else
        mkdir -p "$1"
    fi
}

# --- Scaffold files ---
if has_component "scaffold"; then
    echo "Copying scaffold files (won't overwrite existing files)..."
    safe_cp "-rn" "$SCAFFOLD_SRC/docs" .
    safe_cp "-rn" "$SCAFFOLD_SRC/vision" .
    safe_cp "-rn" "$SCAFFOLD_SRC/scripts" .
    safe_cp "-n" "$FRAMEWORK_DIR/CLAUDE.md" .
    safe_cp "-n" "$SCAFFOLD_SRC/llms.txt" .
    safe_cp "-n" "$SCAFFOLD_SRC/CLAUDE.local.md.template" .
fi

# GitHub integration files
if has_component "github"; then
    echo "Copying GitHub integration files..."
    safe_cp "-rn" "$FRAMEWORK_DIR/.github" .
fi

if [ "$MODE" = "template" ]; then
    # --- Component-based installation ---
    if [ "$COMPONENTS" = "all" ]; then
        echo "Copying core framework files..."
        safe_cp "-rn" "$FRAMEWORK_DIR/.claude" .
    else
        # Selective component installation
        echo "Copying selected components..."

        # Always create .claude directory
        safe_mkdir ".claude"

        if has_component "hooks"; then
            echo "  Installing hooks..."
            safe_cp "-rn" "$FRAMEWORK_DIR/.claude/hooks" .claude/
            # Hooks need rules to function — warn if rules not included
            if ! has_component "rules"; then
                echo "  WARNING: Hooks reference rule files. Consider adding 'rules' to --components."
            fi
        fi

        if has_component "rules"; then
            echo "  Installing rules..."
            safe_cp "-rn" "$FRAMEWORK_DIR/.claude/rules" .claude/
        fi

        if has_component "skills"; then
            echo "  Installing skills..."
            safe_cp "-rn" "$FRAMEWORK_DIR/.claude/skills" .claude/
        fi

        if has_component "agents"; then
            echo "  Installing agents..."
            safe_cp "-rn" "$FRAMEWORK_DIR/.claude/agents" .claude/
        fi

        if has_component "prompts"; then
            echo "  Installing prompts..."
            safe_cp "-rn" "$FRAMEWORK_DIR/.claude/prompts" .claude/
        fi

        # Always copy output style and settings template
        safe_cp "-rn" "$FRAMEWORK_DIR/.claude/output-styles" .claude/
    fi

    # Always update settings.json — it's framework-managed, not user-customizable
    # User customizations belong in settings.local.json
    if $DRY_RUN; then
        echo "  [DRY RUN] Would update: .claude/settings.json"
    else
        cp "$FRAMEWORK_DIR/.claude/settings.json" .claude/settings.json
    fi

    # Hook paths resolve at runtime via git rev-parse — no placeholder replacement needed
fi

# Create AGENTS.md symlink if it doesn't exist
if [ ! -e "AGENTS.md" ]; then
    if $DRY_RUN; then
        echo "  [DRY RUN] Would create: AGENTS.md -> CLAUDE.md"
    else
        ln -s CLAUDE.md AGENTS.md
        echo "  Created AGENTS.md -> CLAUDE.md symlink"
    fi
fi

# Update .gitignore — append framework patterns if not present
GITIGNORE_PATTERNS=(
    "CLAUDE.local.md"
    ".claude/settings.local.json"
    "*.session-handoff.md"
    ".env"
    ".env.*"
    ".env.local"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "docs/sessions/.activity-log.jsonl"
    "docs/sessions/.auto-save.md"
    "docs/sessions/.failure-state.md"
    "docs/sessions/.failure-log.jsonl"
    "docs/sessions/.story-outcomes.tsv"
    "docs/sessions/.optimization-log.tsv"
    "docs/sessions/.refine-log.tsv"
)

if $DRY_RUN; then
    echo "  [DRY RUN] Would update .gitignore with framework patterns"
else
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
fi

# Create directories
if $DRY_RUN; then
    echo "  [DRY RUN] Would create directories: docs/sessions, docs/plans, docs/research, docs/solutions, docs/brainstorms, docs/adr, docs/sprints"
else
    mkdir -p docs/sessions docs/plans docs/research docs/solutions docs/brainstorms docs/adr docs/sprints
fi

echo ""
echo "=== Installation Complete ==="
$DRY_RUN && echo "(DRY RUN — no files were modified)"
echo ""

if [ "$MODE" = "template" ]; then
    if [ "$COMPONENTS" = "all" ]; then
        echo "Files installed (template mode):"
        echo "  .claude/skills/    — Framework skills"
        echo "  .claude/rules/     — Path-scoped rules"
        echo "  .claude/hooks/     — Hook scripts"
        echo "  .claude/agents/    — Expert agent personas"
        echo "  .claude/prompts/   — Prompt templates"
        echo "  docs/              — Documentation templates"
        echo "  .github/           — PR template, CI workflow, issue templates"
        echo "  vision/            — New project braindump flow"
        echo "  CLAUDE.md          — Framework entry point"
        echo "  AGENTS.md          — Cross-tool compatibility"
        echo "  llms.txt           — LLM-friendly project index"
    else
        echo "Files installed (selective: $COMPONENTS):"
        has_component "hooks" && echo "  .claude/hooks/     — Hook scripts"
        has_component "rules" && echo "  .claude/rules/     — Path-scoped rules"
        has_component "skills" && echo "  .claude/skills/    — Framework skills"
        has_component "agents" && echo "  .claude/agents/    — Expert agent personas"
        has_component "prompts" && echo "  .claude/prompts/   — Prompt templates"
        has_component "scaffold" && echo "  docs/, vision/, CLAUDE.md — Scaffold files"
        has_component "github" && echo "  .github/           — GitHub integration"
    fi
else
    echo "Files installed (plugin mode — core via Claude Code plugin):"
    echo "  docs/              — Documentation templates"
    echo "  .github/           — PR template, CI workflow, issue templates"
    echo "  vision/            — New project braindump flow"
    echo "  CLAUDE.md          — Framework entry point"
    echo "  AGENTS.md          — Cross-tool compatibility"
    echo "  llms.txt           — LLM-friendly project index"
fi

echo ""
echo "Next steps:"
echo "  1. Open Claude Code in this directory"
echo "  2. Run: /quickstart"
echo "     (Guided tour → checks readiness → runs /bootstrap for you)"
echo ""
