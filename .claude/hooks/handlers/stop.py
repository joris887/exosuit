"""Stop handler: auto-save session state + validate completion evidence.

Always saves session state first (safety net for /continue). Then checks
the last assistant message for unverified completion claims.
"""

import os
import re
import subprocess
from datetime import datetime, timezone


def handle(input_data, event, state, load_rules):
    # Always auto-save first (safety net)
    _auto_save()

    last_message = input_data.get("last_assistant_message", "")
    if not last_message:
        return None

    rules = load_rules("quality")
    issues = []

    # Check weak claim patterns
    for pattern in rules.get("weak_claims", []):
        matches = re.findall(pattern["regex"], last_message, re.IGNORECASE)
        if matches:
            unique = set(m.lower() for m in matches)
            issues.append(f"{pattern['message']}: {', '.join(unique)}")

    # Check completion without evidence
    completion_re = rules.get(
        "completion_regex",
        r"\b(complete|done|finished|implemented|delivered|ready for review)\b",
    )
    evidence_re = rules.get(
        "evidence_regex",
        r"(\d+ tests?.*pass|PASS\b|Tests:\s+\d+|test result:.*ok|pytest.*passed|All \d+ tests passed)",
    )
    claims_completion = bool(re.search(completion_re, last_message, re.IGNORECASE))
    has_evidence = bool(re.search(evidence_re, last_message, re.IGNORECASE))

    if claims_completion and not has_evidence:
        issues.append(
            "Task claimed complete but no test output found. Run tests and show output."
        )

    if issues:
        msg = "Quality check before completion:\n" + "\n".join(
            f"  - {i}" for i in issues
        )
        return {"action": "block", "message": msg}

    return None


def _auto_save():
    """Save minimal session state for /continue."""
    if not os.path.isdir(".git"):
        return

    sessions_dir = "docs/sessions"
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
