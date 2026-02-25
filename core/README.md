# Core — Plugin-Distributable Framework

This directory mirrors `.claude/` via symlinks for **plugin distribution packaging**.

## Contents

| Directory | Purpose |
|-----------|---------|
| `hooks/` | Hook engine, handlers, rules, bash hooks |
| `skills/` | 36+ development workflow skills |
| `rules/` | 8 behavioral rules (markdown) |
| `agents/` | 6 expert agent personas |
| `prompts/` | 13+ prompt templates |
| `commands/` | Specialized commands |
| `settings.json` | Hook and status line configuration |

## How It Works

- `.claude/` is the **canonical source** for all framework code
- `core/` contains symlinks to `.claude/` subdirectories
- Claude Code reads from `.claude/` at runtime (both template and plugin mode)
- CI resolves symlinks when packaging for marketplace distribution

## CI Packaging

To create a self-contained plugin package:

```bash
bash core/package.sh dist/
```

This resolves all symlinks and creates a flat directory at `dist/` ready for marketplace upload.

## Distribution Modes

| Mode | Core Source | Scaffold Source |
|------|-----------|----------------|
| **Plugin** | Installed via Claude Code marketplace | `install.sh --mode=plugin` copies `scaffold/` |
| **Template** | `install.sh` copies `.claude/` to project | `install.sh` copies `scaffold/` files to root |
