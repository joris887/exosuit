"""Stop handler: auto-save + completion evidence validation.

1. Always auto-saves session state (safety net for /continue).
2. Validates last assistant message for unverified completion claims.

Safety valve: max iterations per session (default 5), then allows stop.

Note: Workflow enforcement via .failure-state.md was removed — it caused
tight coupling between story-cycle, stop hook, and /continue with fragile
stale detection. The auto-save already captures git state for /continue.
Weak-claims detection was also removed — it caused false positives on
discussion text that merely mentioned common phrases. The completion-
evidence check already covers this (claims completion → must show output).
"""

import os
import re
import subprocess
from datetime import datetime, timezone

from lib.paths import project_path


def handle(input_data, event, state, load_rules):
    # Always auto-save first (safety net)
    _auto_save()

    # Safety valve: max iterations before unconditional allow
    quality_rules = load_rules("quality")
    max_iterations = quality_rules.get("max_iterations", 5)
    iteration = state.get("stop_iteration", 0)
    if iteration >= max_iterations:
        return None  # Allow stop unconditionally

    last_message = input_data.get("last_assistant_message", "")
    issues = []

    # --- Completion evidence checks ---
    if last_message:
        evidence_issues = _check_evidence(last_message, quality_rules)
        issues.extend(evidence_issues)

    if issues:
        state["stop_iteration"] = iteration + 1
        msg = "Quality check before completion:\n" + "\n".join(
            f"  - {i}" for i in issues
        )
        return {"action": "block", "message": msg}

    return None


def _check_evidence(message, rules):
    """Check for unverified completion claims per quality rules."""
    issues = []

    # Check completion without evidence
    completion_re = rules.get(
        "completion_regex",
        r"\b(complete|done|finished|implemented|delivered|ready for review)\b",
    )
    evidence_re = rules.get(
        "evidence_regex",
        r"(\d+ tests?.*pass|PASS\b|Tests:\s+\d+|test result:.*ok|pytest.*passed|All \d+ tests passed|\d+ passed)",
    )
    claims_completion = bool(re.search(completion_re, message, re.IGNORECASE))
    has_evidence = bool(re.search(evidence_re, message, re.IGNORECASE))

    if claims_completion and not has_evidence:
        issues.append(
            "Task claimed complete but no test output found. Run tests and show output."
        )

    return issues


def _auto_save():
    """Save minimal session state for /continue."""
    if not os.path.isdir(".git"):
        return

    sessions_dir = project_path("docs", "sessions")
    os.makedirs(sessions_dir, exist_ok=True)

    def git(*args):
        try:
            return subprocess.check_output(
                ["git"] + list(args), stderr=subprocess.DEVNULL, timeout=5
            ).decode().strip()
        except Exception:
            return ""

    branch = git("branch", "--show-current") or "unknown"
    commits = git("log", "--oneline", "-5") or "no commits"
    uncommitted = git("diff", "--name-only")
    staged = git("diff", "--cached", "--name-only")
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    uncommitted_block = f"```\n{uncommitted}\n```" if uncommitted else "None"
    staged_block = f"```\n{staged}\n```" if staged else "None"

    content = f"""# Auto-Save Session State

**Generated:** {now}
**Branch:** {branch}

## Recent Commits
```
{commits}
```

## Uncommitted Changes
{uncommitted_block}

## Staged Changes
{staged_block}
"""
    try:
        with open(os.path.join(sessions_dir, ".auto-save.md"), "w") as f:
            f.write(content)
    except OSError:
        pass
