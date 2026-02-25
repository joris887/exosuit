# Scaffold — Project Template Files

This directory contains **project-template files** that get installed into new projects.

These files are project-specific and get customized by `/bootstrap`:
- `CLAUDE.md` — Main project entry point (filled by `/bootstrap`)
- `docs/` — Documentation templates (context, architecture, reference, ADR, testing)
- `vision/` — Product vision braindump flow
- `scripts/pm/` — Project management scripts (metrics, standup, status)
- `llms.txt` — LLM-friendly project index

## Distribution Modes

| Mode | What Happens |
|------|-------------|
| **Plugin mode** | Core framework installed as plugin. Run `install.sh --mode=plugin` to copy scaffold files into your project. |
| **Template mode** | Clone/fork the entire repo. All files are already in place. Run `/bootstrap` to configure. |

## Usage

```bash
# Plugin mode: after installing the plugin
bash install.sh --mode=plugin

# Template mode: clone the repo, then run /bootstrap
git clone https://github.com/joris887/JD-LLM-Development_framework.git .claude-framework
bash .claude-framework/install.sh
```
