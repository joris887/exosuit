#!/usr/bin/env bash
set -euo pipefail

# Package the framework core for marketplace distribution.
# Resolves symlinks from core/ and creates a self-contained plugin directory.
#
# Usage: bash core/package.sh [output_dir]
# Default output: dist/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-$REPO_ROOT/dist}"

echo "=== Packaging Exosuit Core ==="
echo "Source: $REPO_ROOT/core/"
echo "Output: $OUTPUT_DIR/"
echo ""

# Clean output
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy core (resolve symlinks with -L)
rsync -rL --exclude='README.md' --exclude='package.sh' \
    "$REPO_ROOT/core/" "$OUTPUT_DIR/"

# Include plugin metadata
if [ -d "$REPO_ROOT/.claude-plugin" ]; then
    mkdir -p "$OUTPUT_DIR/.claude-plugin"
    cp "$REPO_ROOT/.claude-plugin/plugin.json" "$OUTPUT_DIR/.claude-plugin/"
fi

# Include hooks.json for plugin mode
if [ -f "$REPO_ROOT/.claude/hooks/hooks.json" ]; then
    cp "$REPO_ROOT/.claude/hooks/hooks.json" "$OUTPUT_DIR/hooks/"
fi

# Report
echo "Package contents:"
find "$OUTPUT_DIR" -type f | wc -l | xargs -I{} echo "  {} files"
echo ""
echo "Directories:"
find "$OUTPUT_DIR" -type d -mindepth 1 -maxdepth 1 | while read -r dir; do
    count=$(find "$dir" -type f | wc -l)
    echo "  $(basename "$dir")/  ($count files)"
done
echo ""
echo "Ready for marketplace distribution at: $OUTPUT_DIR/"
