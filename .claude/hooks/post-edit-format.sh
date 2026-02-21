#!/usr/bin/env bash
# Post-edit hook: Auto-format files after Claude edits them.
# Configured by /bootstrap to use your project's formatter.
#
# This script receives the edited file path as $1.
# Customize the formatter commands below for your stack.

FILE="$1"

if [ -z "$FILE" ]; then
    exit 0
fi

# Detect file type and run appropriate formatter
case "$FILE" in
    *.py)
        # Python: ruff format (or black)
        if command -v ruff &>/dev/null; then
            ruff format "$FILE" 2>/dev/null
        elif command -v black &>/dev/null; then
            black --quiet "$FILE" 2>/dev/null
        fi
        ;;
    *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.html)
        # JavaScript/TypeScript: prettier (or biome)
        if command -v prettier &>/dev/null; then
            prettier --write "$FILE" 2>/dev/null
        elif npx biome --help &>/dev/null 2>&1; then
            npx biome format --write "$FILE" 2>/dev/null
        fi
        ;;
    *.rs)
        # Rust: rustfmt
        if command -v rustfmt &>/dev/null; then
            rustfmt "$FILE" 2>/dev/null
        fi
        ;;
    *.go)
        # Go: gofmt
        if command -v gofmt &>/dev/null; then
            gofmt -w "$FILE" 2>/dev/null
        fi
        ;;
    *.swift)
        # Swift: swift-format
        if command -v swift-format &>/dev/null; then
            swift-format -i "$FILE" 2>/dev/null
        fi
        ;;
    *.rb)
        # Ruby: rubocop
        if command -v rubocop &>/dev/null; then
            rubocop -A --fail-level=error "$FILE" 2>/dev/null
        fi
        ;;
esac

exit 0
