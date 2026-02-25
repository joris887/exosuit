"""PreToolUse handler: block dangerous Bash commands.

Loads patterns from rules/safety.yaml. Tracks warned patterns per session
in session state to avoid repeating the same block message.
"""

import os
import re
import subprocess


def handle(input_data, event, state, load_rules):
    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")
    if not command:
        return None

    rules = load_rules("safety")
    warned = state.setdefault("warnings_shown", {})

    # Check safety patterns
    for pattern in rules.get("patterns", []):
        if re.search(pattern["regex"], command):
            key = pattern["id"]
            prefix = "BLOCKED (repeated)" if key in warned else "BLOCKED"
            warned[key] = True
            return {"action": "block", "message": f"{prefix}: {pattern['message']}"}

    # Framework repo protection
    if re.search(r"(gh\s+(pr|issue)\s+create|git\s+push)", command):
        framework_repo = os.environ.get(
            "JD_FRAMEWORK_REPO", "joris887/JD-LLM-Development_framework"
        )
        try:
            remote = subprocess.check_output(
                ["git", "remote", "get-url", "origin"],
                stderr=subprocess.DEVNULL, timeout=5,
            ).decode().strip()
        except Exception:
            remote = ""
        if remote and framework_repo in remote:
            return {
                "action": "block",
                "message": (
                    f"BLOCKED: Remote points to the framework template repository "
                    f"({framework_repo}). Run: git remote set-url origin "
                    f"<your-project-repo-url>"
                ),
            }

    return None
