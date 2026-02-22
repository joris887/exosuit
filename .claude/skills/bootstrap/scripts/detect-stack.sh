#!/usr/bin/env bash
# Detect the technology stack of the current project.
# Usage: bash scripts/detect-stack.sh
#
# Outputs a structured summary of detected technologies.

set -euo pipefail

show_help() {
  cat <<'HELP'
Usage: bash scripts/detect-stack.sh [OPTIONS]

Detect the technology stack of the current project by scanning
configuration files, dependency manifests, and directory structure.

Options:
  -h, --help    Show this help message

Output:
  Prints structured summary of detected technologies including:
  - Languages and versions
  - Package manager
  - Test framework
  - Linter/formatter
  - Build tool
  - CI/CD provider

Examples:
  bash scripts/detect-stack.sh
HELP
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && show_help

echo "## Stack Detection Results"
echo ""

# Languages
echo "### Languages"
[[ -f "package.json" ]] && echo "- JavaScript/TypeScript (package.json found)"
[[ -f "tsconfig.json" ]] && echo "  - TypeScript confirmed (tsconfig.json)"
[[ -f "pyproject.toml" || -f "setup.py" || -f "setup.cfg" ]] && echo "- Python"
[[ -f "Cargo.toml" ]] && echo "- Rust"
[[ -f "go.mod" ]] && echo "- Go"
[[ -f "Package.swift" ]] && echo "- Swift"
[[ -f "pom.xml" || -f "build.gradle" || -f "build.gradle.kts" ]] && echo "- Java/Kotlin"
[[ -f "Gemfile" ]] && echo "- Ruby"
[[ -f "composer.json" ]] && echo "- PHP"
[[ -f "pubspec.yaml" ]] && echo "- Dart/Flutter"
ls *.csproj *.sln 2>/dev/null | head -1 >/dev/null 2>&1 && echo "- C#/.NET"
[[ -f "CMakeLists.txt" ]] && echo "- C/C++"
echo ""

# Package Manager
echo "### Package Manager"
[[ -f "bun.lockb" || -f "bun.lock" ]] && echo "- bun"
[[ -f "pnpm-lock.yaml" ]] && echo "- pnpm"
[[ -f "yarn.lock" ]] && echo "- yarn"
[[ -f "package-lock.json" ]] && echo "- npm"
[[ -f "uv.lock" ]] && echo "- uv"
[[ -f "Pipfile.lock" ]] && echo "- pipenv"
[[ -f "poetry.lock" ]] && echo "- poetry"
[[ -f "Cargo.lock" ]] && echo "- cargo"
[[ -f "go.sum" ]] && echo "- go modules"
[[ -f "Gemfile.lock" ]] && echo "- bundler"
echo ""

# Test Framework
echo "### Test Framework"
if [[ -f "package.json" ]]; then
  grep -q '"jest"' package.json 2>/dev/null && echo "- Jest"
  grep -q '"vitest"' package.json 2>/dev/null && echo "- Vitest"
  grep -q '"mocha"' package.json 2>/dev/null && echo "- Mocha"
  grep -q '"playwright"' package.json 2>/dev/null && echo "- Playwright"
  grep -q '"cypress"' package.json 2>/dev/null && echo "- Cypress"
fi
[[ -f "pytest.ini" || -f "pyproject.toml" ]] && grep -q "pytest" pyproject.toml 2>/dev/null && echo "- pytest"
[[ -f "Cargo.toml" ]] && echo "- cargo test (built-in)"
[[ -f "go.mod" ]] && echo "- go test (built-in)"
[[ -f "Package.swift" ]] && echo "- swift test (built-in)"
echo ""

# Linter / Formatter
echo "### Linter / Formatter"
[[ -f ".eslintrc" || -f ".eslintrc.js" || -f ".eslintrc.json" || -f ".eslintrc.yml" || -f "eslint.config.js" || -f "eslint.config.mjs" ]] && echo "- ESLint"
[[ -f ".prettierrc" || -f ".prettierrc.json" || -f ".prettierrc.js" || -f "prettier.config.js" ]] && echo "- Prettier"
[[ -f "biome.json" || -f "biome.jsonc" ]] && echo "- Biome"
[[ -f "ruff.toml" ]] && echo "- Ruff"
grep -q "ruff" pyproject.toml 2>/dev/null && echo "- Ruff (in pyproject.toml)"
[[ -f ".swiftlint.yml" ]] && echo "- SwiftLint"
[[ -f "rustfmt.toml" || -f ".rustfmt.toml" ]] && echo "- rustfmt"
[[ -f ".golangci.yml" || -f ".golangci.yaml" ]] && echo "- golangci-lint"
echo ""

# Build Tool
echo "### Build Tool"
[[ -f "Makefile" ]] && echo "- Make"
[[ -f "justfile" || -f "Justfile" ]] && echo "- Just"
if [[ -f "package.json" ]]; then
  grep -q '"vite"' package.json 2>/dev/null && echo "- Vite"
  grep -q '"webpack"' package.json 2>/dev/null && echo "- Webpack"
  grep -q '"esbuild"' package.json 2>/dev/null && echo "- esbuild"
  grep -q '"rollup"' package.json 2>/dev/null && echo "- Rollup"
  grep -q '"turbo"' package.json 2>/dev/null && echo "- Turborepo"
  grep -q '"next"' package.json 2>/dev/null && echo "- Next.js"
fi
echo ""

# CI/CD
echo "### CI/CD"
[[ -d ".github/workflows" ]] && echo "- GitHub Actions"
[[ -f ".gitlab-ci.yml" ]] && echo "- GitLab CI"
[[ -f "Jenkinsfile" ]] && echo "- Jenkins"
[[ -f ".circleci/config.yml" ]] && echo "- CircleCI"
[[ -f ".travis.yml" ]] && echo "- Travis CI"
[[ -f "bitbucket-pipelines.yml" ]] && echo "- Bitbucket Pipelines"
echo ""

echo "---"
echo "Detection complete. Review results and adjust as needed."
