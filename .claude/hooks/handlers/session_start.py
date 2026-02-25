"""SessionStart handler: advisory environment checks.

Validates project tools, detects stale state, checks git health.
Never blocks (advisory only).
"""

import os
import shutil
import subprocess
from datetime import datetime, timezone


def handle(input_data, event, state, load_rules):
    warnings = []

    # 1. Check project tool availability
    if os.path.isfile("CLAUDE.md"):
        try:
            with open("CLAUDE.md") as f:
                for line in f:
                    for key in ("test:", "lint:", "format:", "build:", "typecheck:"):
                        if key in line:
                            after = line.split(key, 1)[1].strip()
                            cmd = after.split()[0] if after else ""
                            if cmd and not cmd.startswith("<") and not cmd.startswith("#"):
                                if not shutil.which(cmd):
                                    warnings.append(
                                        f"Tool '{cmd}' (from CLAUDE.md Commands) not found in PATH"
                                    )
        except OSError:
            pass

    # 2. Stale session detection
    auto_save = "docs/sessions/.auto-save.md"
    if os.path.isfile(auto_save):
        try:
            mtime = os.path.getmtime(auto_save)
            age = datetime.now(timezone.utc).timestamp() - mtime
            if age > 86400:
                days = int(age // 86400)
                warnings.append(
                    f"Stale auto-save detected ({auto_save} is {days}d old) "
                    f"-- consider running /continue"
                )
        except OSError:
            pass

    # 3. Git state checks
    branch = _git("branch", "--show-current")
    if branch:
        if branch in ("main", "master"):
            warnings.append(
                f"On {branch} branch -- create a feature branch before making changes"
            )
    elif _git("rev-parse", "--is-inside-work-tree") == "true":
        warnings.append(
            "Detached HEAD state -- checkout a branch before making changes"
        )

    if _git("status", "--porcelain"):
        warnings.append(
            "Uncommitted changes detected -- consider committing or stashing before starting"
        )

    # 4. Initialize session state
    state["started_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    state.setdefault("warnings_shown", {})
    state.setdefault("stop_iteration", 0)

    if warnings:
        msg = "Session start checks:\n" + "\n".join(f"  - {w}" for w in warnings)
        return {"action": "warn", "message": msg}

    return None


def _git(*args):
    try:
        return subprocess.check_output(
            ["git"] + list(args), stderr=subprocess.DEVNULL, timeout=5
        ).decode().strip()
    except Exception:
        return ""
