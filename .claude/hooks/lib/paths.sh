#!/usr/bin/env bash
# Path resolution helpers for bash hooks.
#
# Source this file to get core_root, core_path, and project_path functions.
# Usage: source "$(dirname "$0")/lib/paths.sh"
#
# Plugin mode:   CLAUDE_PLUGIN_ROOT is set by Claude Code
# Template mode:  derives paths from the script's file location

# Root of the framework core (.claude/ or plugin root)
core_root() {
    if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
        echo "$CLAUDE_PLUGIN_ROOT"
    else
        # Derive: lib/paths.sh -> hooks/lib/ -> hooks/ -> .claude/
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    fi
}

# Resolve a path relative to the framework core root
# Usage: core_path "hooks/rules/safety.yaml"
core_path() {
    echo "$(core_root)/$1"
}

# Resolve a path relative to the project root (always CWD)
# Usage: project_path "docs/progress.md"
project_path() {
    echo "$(pwd)/$1"
}
