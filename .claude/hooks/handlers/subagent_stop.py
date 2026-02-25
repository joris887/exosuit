"""SubagentStop handler: validate subagent output quality. Advisory only."""

import re


def handle(input_data, event, state, load_rules):
    message = input_data.get("last_assistant_message", "")
    if not message:
        return None

    rules = load_rules("subagent")
    warnings = []

    # Check weak claim patterns
    for pattern in rules.get("weak_claims", []):
        matches = re.findall(pattern["regex"], message, re.IGNORECASE)
        if matches:
            unique = set(m.lower() for m in matches)
            warnings.append(f"{pattern['message']}: {', '.join(unique)}")

    # Check for file:line references (expected in quality agent output)
    if rules.get("require_references", False) and len(message) > 200:
        if not re.search(r"[\w/]+\.\w+:\d+", message):
            warnings.append("Subagent output lacks file:line references")

    if warnings:
        msg = "Subagent quality warnings:\n" + "\n".join(f"  - {w}" for w in warnings)
        return {"action": "warn", "message": msg}

    return None  # Advisory only
