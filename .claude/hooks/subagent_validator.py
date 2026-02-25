#!/usr/bin/env python3
"""SubagentStop hook: validate subagent output quality. Advisory only."""
import json, sys, re


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    message = data.get("last_assistant_message", "")
    if not message:
        sys.exit(0)

    warnings = []

    # Check for weak claims
    weak = re.findall(r'\b(should work|looks correct|I believe|I think)\b', message, re.IGNORECASE)
    if weak:
        warnings.append(f"Subagent used unverified language: {', '.join(set(w.lower() for w in weak))}")

    # Check for file:line references (expected in quality agent output)
    has_refs = bool(re.search(r'[\w/]+\.\w+:\d+', message))
    if not has_refs and len(message) > 200:
        warnings.append("Subagent output lacks file:line references")

    if warnings:
        print("Subagent quality warnings:", file=sys.stderr)
        for w in warnings:
            print(f"  - {w}", file=sys.stderr)

    sys.exit(0)  # Advisory only


if __name__ == "__main__":
    main()
