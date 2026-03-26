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

AI hallucinates 19.7% of recommended packages (USENIX Security 2025). 58% of hallucinated names repeat predictably, making them targets for malicious registration (slopsquatting).

- **ALWAYS verify a dependency exists in the package registry before adding it** — this is the single most important check for AI-assisted development
- Never add dependencies without explicit user approval
- Prefer well-established packages (>1000 weekly downloads, >6 months old)
- Never remove or downgrade dependencies without explicit user approval
- Always keep lockfiles in sync — run the package manager's install/lock command after changes
- Flag any package less than 7 days old as a supply chain risk
- Check for known vulnerabilities before adding new dependencies
- Compare AI-suggested package names against well-known packages — typosquatting is common (`requets` vs `requests`, `lodsah` vs `lodash`)
- Never trust AI-generated version numbers without checking the registry — AI mixes API versions across major releases
- Pin dependency versions explicitly — never use `latest` or unbounded ranges in production
