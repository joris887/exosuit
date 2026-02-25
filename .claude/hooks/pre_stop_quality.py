#!/usr/bin/env python3
"""Stop hook: auto-save session state + validate completion evidence.

Reads JSON from stdin with optional 'last_assistant_message' field.
Always saves session state. Blocks (exit 2) only if completion claimed without evidence.
"""
import json, sys, os, re, subprocess
from datetime import datetime, timezone


def auto_save():
    """Save minimal session state (ported from pre-stop-quality.sh lines 8-35)."""
    sessions_dir = "docs/sessions"
    auto_save_path = os.path.join(sessions_dir, ".auto-save.md")

    if not os.path.isdir(".git"):
        return

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
    with open(auto_save_path, "w") as f:
        f.write(content)


def check_completion_evidence(message: str) -> list:
    """Check for unverified completion claims per verification.md rules."""
    issues = []

    # Detect weak claim language (verification.md red flags)
    weak = re.findall(
        r'\b(should work|looks correct|I believe|I think|probably works|seems fine)\b',
        message, re.IGNORECASE
    )
    if weak:
        unique = set(w.lower() for w in weak)
        issues.append(f"Unverified claims detected: {', '.join(unique)}. Show evidence instead.")

    # Check for completion claims without test output
    claims_completion = bool(re.search(
        r'\b(complete|done|finished|implemented|delivered|ready for review)\b',
        message, re.IGNORECASE
    ))
    has_test_output = bool(re.search(
        r'(\d+ tests?.*pass|PASS\b|Tests:\s+\d+|test result:.*ok|pytest.*passed|All \d+ tests passed)',
        message, re.IGNORECASE
    ))

    if claims_completion and not has_test_output:
        issues.append("Task claimed complete but no test output found. Run tests and show output.")

    return issues


def main():
    # Always auto-save first (safety net)
    auto_save()

    # Read stdin JSON
    try:
        input_data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    last_message = input_data.get("last_assistant_message", "")
    if not last_message:
        sys.exit(0)

    issues = check_completion_evidence(last_message)

    if issues:
        msg = "Quality check before completion:\n" + "\n".join(f"  - {i}" for i in issues)
        print(msg, file=sys.stderr)
        sys.exit(2)  # Block with message

    sys.exit(0)


if __name__ == "__main__":
    main()
