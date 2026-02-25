"""Worktree handlers: initialize new worktrees, clean up removed ones.

WorktreeCreate: copies state files (.failure-state.md, .auto-save.md) from main.
WorktreeRemove: merges activity logs back to main worktree.
"""

import os
import shutil
import subprocess


def handle(input_data, event, state, load_rules):
    if event == "WorktreeCreate":
        return _init(input_data, state)
    elif event == "WorktreeRemove":
        return _cleanup(input_data, state)
    return None


def _init(input_data, state):
    """Initialize framework state in new worktree."""
    main_worktree = _get_main_worktree()
    if not main_worktree:
        return None

    current = os.getcwd()
    if current == main_worktree:
        return None

    # Copy state files from main worktree
    for rel_path in ("docs/sessions/.failure-state.md", "docs/sessions/.auto-save.md"):
        src = os.path.join(main_worktree, rel_path)
        if os.path.isfile(src):
            os.makedirs(os.path.dirname(rel_path) or ".", exist_ok=True)
            shutil.copy2(src, rel_path)

    os.makedirs("docs/sessions", exist_ok=True)
    return {"action": "warn", "message": "Worktree initialized with framework state."}


def _cleanup(input_data, state):
    """Merge activity logs back to main worktree."""
    main_worktree = _get_main_worktree()
    if not main_worktree:
        return None

    log = "docs/sessions/.activity-log.jsonl"
    main_log = os.path.join(main_worktree, log)

    if os.path.isfile(log):
        os.makedirs(os.path.dirname(main_log), exist_ok=True)
        try:
            with open(log) as src:
                content = src.read()
            with open(main_log, "a") as dst:
                dst.write(content)
        except OSError:
            pass

    return None


def _get_main_worktree():
    try:
        output = subprocess.check_output(
            ["git", "worktree", "list", "--porcelain"],
            stderr=subprocess.DEVNULL, timeout=5,
        ).decode()
        for line in output.split("\n"):
            if line.startswith("worktree "):
                return line[len("worktree "):]
    except Exception:
        pass
    return None
