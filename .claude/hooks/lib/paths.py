"""Path resolution for plugin mode compatibility.

Resolves framework core paths via CLAUDE_PLUGIN_ROOT (plugin mode) or
relative to the file system layout (template mode). Project-owned paths
always resolve relative to CWD.

Core paths:    hooks/, rules/, skills/, agents/, prompts/, settings.json
Project paths: docs/, CLAUDE.md, vision/, scripts/
"""

import os


def core_root():
    """Root of the framework core (.claude/ directory or plugin root).

    Plugin mode:   returns $CLAUDE_PLUGIN_ROOT
    Template mode: derives from file layout (lib/paths.py -> hooks/ -> .claude/)
    """
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT")
    if plugin_root:
        return plugin_root
    # Derive: this file -> hooks/lib/ -> hooks/ -> .claude/
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def core_path(*parts):
    """Resolve a path relative to the framework core root.

    Plugin mode:   ${CLAUDE_PLUGIN_ROOT}/<parts>
    Template mode: .claude/<parts> (derived from file layout)

    Use for: hooks/, hooks/rules/, hooks/state/, skills/, agents/, prompts/,
             rules/, settings.json, commands/
    """
    return os.path.join(core_root(), *parts)


def project_path(*parts):
    """Resolve a path relative to the project root (always CWD).

    Use for: docs/, CLAUDE.md, vision/, scripts/, .gitignore, CHANGELOG.md
    """
    return os.path.join(os.getcwd(), *parts)
