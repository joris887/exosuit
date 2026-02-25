"""PostToolUse handler: log tool invocations to activity log.

Appends timestamped JSON lines for Edit, Write, and Bash tool use.
Rotates at 200 entries.
"""

import json
import os
from datetime import datetime, timezone

from lib.paths import project_path

LOG_DIR = project_path("docs", "sessions")
LOG_FILE = project_path("docs", "sessions", ".activity-log.jsonl")
MAX_ENTRIES = 200


def handle(input_data, event, state, load_rules):
    tool_name = input_data.get("tool_name", "")
    if tool_name not in ("Edit", "Write", "Bash"):
        return None

    tool_input = input_data.get("tool_input", {})
    target = tool_input.get("file_path", "") or tool_input.get("command", "")[:120]
    if not target:
        return None

    os.makedirs(LOG_DIR, exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    entry = json.dumps({"ts": ts, "tool": tool_name, "target": target})

    try:
        with open(LOG_FILE, "a") as f:
            f.write(entry + "\n")

        # Rotate: keep last MAX_ENTRIES lines
        with open(LOG_FILE) as f:
            lines = f.readlines()
        if len(lines) > MAX_ENTRIES:
            with open(LOG_FILE, "w") as f:
                f.writelines(lines[-MAX_ENTRIES:])
    except OSError:
        pass

    return None
