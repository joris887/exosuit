#!/usr/bin/env bash
# File suggestion script for Claude Code @ mention autocomplete.
# Surfaces framework-relevant files for quick access.

echo "docs/progress.md"
echo "docs/reference/BACKLOG_INDEX.md"
[[ -f ".failure-state.md" ]] && echo ".failure-state.md"
[[ -f "docs/sessions/.failure-state.md" ]] && echo "docs/sessions/.failure-state.md"
ls -t docs/sessions/session-*.md 2>/dev/null | head -3
