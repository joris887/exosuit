---
paths:
  - "package.json"
  - "package-lock.json"
  - "pyproject.toml"
  - "poetry.lock"
  - "requirements*.txt"
  - "Cargo.toml"
  - "Cargo.lock"
  - "go.mod"
  - "go.sum"
  - "Gemfile"
  - "Gemfile.lock"
  - "composer.json"
  - "composer.lock"
  - "pubspec.yaml"
  - "pubspec.lock"
  - "*.lock"
---

# Dependency Management Rules

- Never add dependencies without explicit user approval
- Prefer well-established packages (>1000 weekly downloads, >6 months old)
- Always verify a dependency actually exists in the package registry before adding it
- Never remove or downgrade dependencies without explicit user approval
- Always keep lockfiles in sync — run the package manager's install/lock command after changes
- Flag any package less than 7 days old as a supply chain risk
- Check for known vulnerabilities before adding new dependencies
