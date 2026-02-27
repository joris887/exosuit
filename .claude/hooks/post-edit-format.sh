#!/usr/bin/env bash
# Requirements: At least one formatter (prettier|biome|ruff|black|rustfmt|gofmt|swift-format|rubocop|google-java-format|ktfmt|php-cs-fixer|dart|dotnet|clang-format)
# Optional: At least one linter (ruff|eslint|biome|golangci-lint|phpstan|dart-analyze)
# Behavior: Auto-formats and lints after edits; reports missing tools once per session
#
# This script receives the edited file path as $1.
# Customize the formatter commands below for your stack.

# Path resolution (plugin/template mode compatible)
source "$(dirname "$0")/lib/paths.sh"

FILE="$1"

if [ -z "$FILE" ]; then
    exit 0
fi

# Report missing tools once per session (not per edit)
HOOK_STATE_DIR="${TMPDIR:-/tmp}/.claude-hook-state"
mkdir -p "$HOOK_STATE_DIR" 2>/dev/null
report_missing() {
    local tool="$1"
    local state_file="$HOOK_STATE_DIR/missing-$tool"
    if [ ! -f "$state_file" ]; then
        echo "⚠ post-edit-format: '$tool' not found — skipping $tool formatting/linting"
        touch "$state_file"
    fi
}

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
    *.java)
        # Java: google-java-format
        if command -v google-java-format &>/dev/null; then
            google-java-format --replace "$FILE" 2>/dev/null
        fi
        ;;
    *.kt|*.kts)
        # Kotlin: ktfmt
        if command -v ktfmt &>/dev/null; then
            ktfmt "$FILE" 2>/dev/null
        fi
        ;;
    *.php)
        # PHP: php-cs-fixer
        if command -v php-cs-fixer &>/dev/null; then
            php-cs-fixer fix "$FILE" --quiet 2>/dev/null
        fi
        ;;
    *.dart)
        # Dart: dart format
        if command -v dart &>/dev/null; then
            dart format "$FILE" 2>/dev/null
        fi
        ;;
    *.cs)
        # C#: dotnet format
        if command -v dotnet &>/dev/null; then
            dotnet format --include "$FILE" 2>/dev/null
        fi
        ;;
    *.c|*.cpp|*.cc|*.cxx|*.h|*.hpp|*.hxx)
        # C/C++: clang-format
        if command -v clang-format &>/dev/null; then
            clang-format -i "$FILE" 2>/dev/null
        fi
        ;;
esac

# After formatting, run linter on the specific file (auto-fix mode, quiet)
# This catches lint issues immediately rather than accumulating until sprint-end.
# Customize per project — /bootstrap will configure these.
case "$FILE" in
    *.py)
        if command -v ruff &>/dev/null; then
            ruff check --fix --quiet "$FILE" 2>/dev/null
        fi
        ;;
    *.ts|*.tsx|*.js|*.jsx)
        if command -v eslint &>/dev/null; then
            eslint --fix --quiet "$FILE" 2>/dev/null
        elif npx biome --help &>/dev/null 2>&1; then
            npx biome lint --apply "$FILE" 2>/dev/null
        fi
        ;;
    *.rb)
        # rubocop already runs with -A above (lint + format combined)
        ;;
    *.go)
        if command -v golangci-lint &>/dev/null; then
            golangci-lint run --fix "$FILE" 2>/dev/null
        fi
        ;;
    *.php)
        if command -v phpstan &>/dev/null; then
            phpstan analyse --no-progress "$FILE" 2>/dev/null
        fi
        ;;
    *.dart)
        if command -v dart &>/dev/null; then
            dart analyze "$FILE" 2>/dev/null
        fi
        ;;
    # Rust clippy, Swift swiftlint, Java/Kotlin/C#/C++ linters require full project context — skip per-file
esac

# Secrets detection: lightweight pattern scan for accidentally committed credentials
# Reports once per file per session to avoid noise; does NOT block edits
SECRETS_STATE_DIR="${TMPDIR:-/tmp}/.claude-hook-state"
mkdir -p "$SECRETS_STATE_DIR" 2>/dev/null
SECRETS_STATE="$SECRETS_STATE_DIR/secrets-$(echo "$FILE" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "nomd5")"

secrets_check() {
    local file="$1"
    # Skip non-text files and common false-positive paths
    case "$file" in
        *.md|*.txt|*.lock|*.sum|*.svg|*.png|*.jpg|*.gif|*.ico) return ;;
    esac

    local found=0
    # AWS access key
    if grep -qE 'AKIA[0-9A-Z]{16}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible AWS access key in $file"
        found=1
    fi
    # OpenAI/Stripe-style keys
    if grep -qE 'sk-[a-zA-Z0-9]{20,}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible API key (sk-...) in $file"
        found=1
    fi
    # GitHub personal access token
    if grep -qE 'ghp_[a-zA-Z0-9]{36}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible GitHub token in $file"
        found=1
    fi
    # Private keys
    if grep -qE 'BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible private key in $file"
        found=1
    fi
    # Generic high-entropy secrets in assignments
    if grep -qE '(password|secret|token|api_key|apikey)\s*[:=]\s*["\x27][A-Za-z0-9+/=]{20,}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible hardcoded credential in $file"
        found=1
    fi

    if [ "$found" -eq 1 ]; then
        echo "  Review before committing. See .claude/rules/security.md"
        touch "$SECRETS_STATE"
    fi
}

# Only check if we haven't already flagged this file this session
if [ ! -f "$SECRETS_STATE" ]; then
    secrets_check "$FILE"
fi

exit 0
