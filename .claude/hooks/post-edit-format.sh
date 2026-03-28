#!/usr/bin/env bash
# Requirements: At least one formatter (prettier|biome|ruff|black|rustfmt|gofmt|swift-format|rubocop|google-java-format|ktfmt|php-cs-fixer|dart|dotnet|clang-format)
# Optional: At least one linter (ruff|eslint|biome|golangci-lint|phpstan|dart-analyze)
# Behavior: Auto-formats and lints after edits; reports missing tools once per session
#
# This script receives the edited file path as $1.
# Customize the formatter commands below for your stack.

# Path resolution (plugin/template mode compatible)
source "$(dirname "$0")/lib/paths.sh"

# Hook guard: profile + disable check
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
"$HOOKS_DIR/lib/hook-guard.sh" "post-edit-format" "standard" || exit 0

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
        echo "⚠ post-edit-format: '$tool' not found — skipping $tool formatting/linting" >&2
        touch "$state_file"
    fi
}

# Portable hash function (macOS ships md5, Linux ships md5sum)
portable_hash() {
    if command -v md5sum &>/dev/null; then
        echo "$1" | md5sum | cut -d' ' -f1
    elif command -v md5 &>/dev/null; then
        echo "$1" | md5
    elif command -v shasum &>/dev/null; then
        echo "$1" | shasum | cut -d' ' -f1
    elif command -v cksum &>/dev/null; then
        echo "$1" | cksum | cut -d' ' -f1
    else
        # Last resort: use the string itself (may cause path length issues but won't break)
        echo "$1" | tr '/' '_'
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
        else
            report_missing "ruff/black"
        fi
        ;;
    *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.html)
        # JavaScript/TypeScript: prettier (or biome)
        if command -v prettier &>/dev/null; then
            prettier --write "$FILE" 2>/dev/null
        elif npx biome --help &>/dev/null 2>&1; then
            npx biome format --write "$FILE" 2>/dev/null
        else
            report_missing "prettier/biome"
        fi
        ;;
    *.rs)
        # Rust: rustfmt
        if command -v rustfmt &>/dev/null; then
            rustfmt "$FILE" 2>/dev/null
        else
            report_missing "rustfmt"
        fi
        ;;
    *.go)
        # Go: gofmt
        if command -v gofmt &>/dev/null; then
            gofmt -w "$FILE" 2>/dev/null
        else
            report_missing "gofmt"
        fi
        ;;
    *.swift)
        # Swift: swift-format
        if command -v swift-format &>/dev/null; then
            swift-format -i "$FILE" 2>/dev/null
        else
            report_missing "swift-format"
        fi
        ;;
    *.rb)
        # Ruby: rubocop
        if command -v rubocop &>/dev/null; then
            rubocop -A --fail-level=error "$FILE" 2>/dev/null
        else
            report_missing "rubocop"
        fi
        ;;
    *.java)
        # Java: google-java-format
        if command -v google-java-format &>/dev/null; then
            google-java-format --replace "$FILE" 2>/dev/null
        else
            report_missing "google-java-format"
        fi
        ;;
    *.kt|*.kts)
        # Kotlin: ktfmt
        if command -v ktfmt &>/dev/null; then
            ktfmt "$FILE" 2>/dev/null
        else
            report_missing "ktfmt"
        fi
        ;;
    *.php)
        # PHP: php-cs-fixer
        if command -v php-cs-fixer &>/dev/null; then
            php-cs-fixer fix "$FILE" --quiet 2>/dev/null
        else
            report_missing "php-cs-fixer"
        fi
        ;;
    *.dart)
        # Dart: dart format
        if command -v dart &>/dev/null; then
            dart format "$FILE" 2>/dev/null
        else
            report_missing "dart"
        fi
        ;;
    *.cs)
        # C#: dotnet format
        if command -v dotnet &>/dev/null; then
            dotnet format --include "$FILE" 2>/dev/null
        else
            report_missing "dotnet"
        fi
        ;;
    *.c|*.cpp|*.cc|*.cxx|*.h|*.hpp|*.hxx)
        # C/C++: clang-format
        if command -v clang-format &>/dev/null; then
            clang-format -i "$FILE" 2>/dev/null
        else
            report_missing "clang-format"
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
SECRETS_STATE="$SECRETS_STATE_DIR/secrets-$(portable_hash "$FILE")"

secrets_check() {
    local file="$1"
    # Skip non-text files and common false-positive paths
    case "$file" in
        *.md|*.txt|*.lock|*.sum|*.svg|*.png|*.jpg|*.gif|*.ico|*.woff|*.woff2|*.ttf|*.eot) return ;;
    esac

    local found=0

    # --- Cloud Provider Keys ---
    # AWS access key (starts with AKIA)
    if grep -qE 'AKIA[0-9A-Z]{16}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible AWS access key in $file"
        found=1
    fi
    # AWS secret key pattern (40-char base64 after assignment)
    if grep -qE 'aws_secret_access_key\s*[:=]\s*["\x27]?[A-Za-z0-9/+=]{40}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible AWS secret key in $file"
        found=1
    fi
    # Google Cloud service account key
    if grep -qE '"type"\s*:\s*"service_account"' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible GCP service account key in $file"
        found=1
    fi
    # Azure connection string
    if grep -qE 'AccountKey=[A-Za-z0-9+/=]{40,}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible Azure connection string in $file"
        found=1
    fi

    # --- API Keys (service-specific prefixes) ---
    # OpenAI / Stripe / Anthropic style (sk- prefix)
    if grep -qE 'sk-[a-zA-Z0-9]{20,}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible API key (sk-...) in $file"
        found=1
    fi
    # Anthropic API key
    if grep -qE 'sk-ant-[a-zA-Z0-9_-]{20,}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible Anthropic API key in $file"
        found=1
    fi

    # --- Source Control Tokens ---
    # GitHub tokens (PAT, OAuth, app)
    if grep -qE '(ghp|gho|ghu|ghs|ghr)_[a-zA-Z0-9]{36,}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible GitHub token in $file"
        found=1
    fi
    # GitHub fine-grained PAT
    if grep -qE 'github_pat_[a-zA-Z0-9_]{22,}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible GitHub fine-grained PAT in $file"
        found=1
    fi
    # GitLab token
    if grep -qE 'glpat-[a-zA-Z0-9\-]{20,}' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible GitLab token in $file"
        found=1
    fi

    # --- Messaging/Collaboration Tokens ---
    # Slack tokens
    if grep -qE 'xox[bporas]-[a-zA-Z0-9\-]+' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible Slack token in $file"
        found=1
    fi

    # --- Cryptographic Material ---
    # Private keys (PEM format)
    if grep -qE 'BEGIN (RSA |DSA |EC |OPENSSH |PGP )?PRIVATE KEY' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible private key in $file"
        found=1
    fi

    # --- JWTs (three base64url segments joined by dots) ---
    if grep -qE 'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible JWT in $file"
        found=1
    fi

    # --- Database Connection Strings ---
    if grep -qE '(mysql|postgres|postgresql|mongodb|mongodb\+srv|redis|amqp)://[^/\s]+:[^@/\s]+@' "$file" 2>/dev/null; then
        echo "⚠ SECRETS: Possible database connection string with password in $file"
        found=1
    fi

    # --- Generic High-Entropy Secrets in Assignments ---
    if grep -qE '(password|passwd|secret|token|api_key|apikey|api_secret|auth_token|access_token|client_secret)\s*[:=]\s*["\x27][A-Za-z0-9+/=_\-]{16,}' "$file" 2>/dev/null; then
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

# Code slop detection: scan for AI-typical filler comments (advisory only)
# Checks patterns from .claude/rules/code-slop.md — warns once per file per session
SLOP_STATE="$HOOK_STATE_DIR/slop-$(portable_hash "$FILE")"

slop_check() {
    local file="$1"
    # Only check source code files
    case "$file" in
        *.py|*.ts|*.tsx|*.js|*.jsx|*.go|*.rs|*.rb|*.java|*.kt|*.kts|*.php|*.dart|*.cs|*.c|*.cpp|*.cc|*.h|*.hpp|*.swift) ;;
        *) return ;;
    esac

    local found=0
    # Self-evident comment patterns (the comment just restates the code)
    if grep -nE '^\s*(#|//|/\*)\s*(Initialize|Set up|Create|Define|Import|Return|Export|Handle|Process|Update|Check|Validate|Get|Set|Add|Remove|Delete|Call|Send|Receive|Start|Stop|Open|Close|Read|Write|Save|Load)\s+(the\s+)?\w+' "$file" 2>/dev/null | head -3 | grep -q .; then
        found=1
    fi
    # "This function/class/method does X" pattern
    if grep -nE '^\s*(#|//|/\*)\s*This\s+(function|class|method|module|file|component|hook|handler|service|controller|middleware)\s' "$file" 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi
    # Obvious section dividers with labels
    if grep -nE '^\s*(#|//)\s*[-=]{3,}\s*(Helper|Utility|Main|Setup|Config|Constants|Types|Interfaces|Exports|Imports)\s*([-=]{3,})?\s*$' "$file" 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    if [ "$found" -eq 1 ]; then
        echo "⚠ SLOP: Possible filler comments detected in $file"
        echo "  Review for self-evident comments. See .claude/rules/code-slop.md"
        touch "$SLOP_STATE"
    fi
}

# Only check if we haven't already flagged this file this session
if [ ! -f "$SLOP_STATE" ]; then
    slop_check "$FILE"
fi

exit 0
