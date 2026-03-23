# Scaffold Directory

Template files copied into new projects by `install.sh`. This is the framework's project scaffolding.

## Purpose
- Contains the initial file structure for framework-managed projects
- `install.sh` copies these files into the target project's directory
- `/bootstrap` then fills in project-specific content (commands, architecture, etc.)

## Structure
- `CLAUDE.md` — project-level CLAUDE.md template (filled by /bootstrap)
- `CLAUDE.local.md.template` — user-specific overrides template
- `docs/` — documentation directory structure with empty templates
- `scripts/pm/` — project management helper scripts
- `vision/` — braindump prompt for new projects

## Conventions
- All template files use HTML comments (`<!-- -->`) for fill-in-the-blank placeholders
- Keep templates minimal — /bootstrap generates real content
- Changes here affect ALL new projects — test with both Path A (existing) and Path B (new)
- Mirror any new docs/ subdirectories here with appropriate CLAUDE.md context files
