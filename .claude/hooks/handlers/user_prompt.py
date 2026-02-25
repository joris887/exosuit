"""UserPromptSubmit handler: advisory intent classification.

Warns about potentially destructive user requests. Never blocks (advisory only).
"""

import re


def handle(input_data, event, state, load_rules):
    prompt = input_data.get("user_prompt", "")
    if not prompt:
        return None

    rules = load_rules("intent")
    warnings = []

    for pattern in rules.get("destructive_patterns", []):
        if re.search(pattern["regex"], prompt, re.IGNORECASE):
            warnings.append(pattern["message"])

    if warnings:
        return {
            "action": "warn",
            "message": "\n".join(f"Warning: {w}" for w in warnings),
        }

    return None  # Advisory only
