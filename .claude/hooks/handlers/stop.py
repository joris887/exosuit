"""Stop handler: auto-save + completion evidence + workflow enforcement.

1. Always auto-saves session state (safety net for /continue).
2. Checks .failure-state.md for active (incomplete) workflows — blocks
   exit with continuation prompt if workflow is still in progress.
3. Validates last assistant message for unverified completion claims.

Safety valve: max iterations per session (default 5), then allows stop.
Stale detection: failure state older than configured hours = treat as stale.
"""

import os
import re
import subprocess
from datetime import datetime, timezone

FAILURE_STATE_PATH = "docs/sessions/.failure-state.md"


def handle(input_data, event, state, load_rules):
    # Always auto-save first (safety net)
    _auto_save()

    last_message = input_data.get("last_assistant_message", "")
    issues = []

    # --- Workflow enforcement (Ralph Loop) ---
    workflow_rules = load_rules("workflow")
    workflow_issues = _check_workflow(state, workflow_rules)
    issues.extend(workflow_issues)

    # --- Completion evidence checks ---
    if last_message:
        quality_rules = load_rules("quality")
        evidence_issues = _check_evidence(last_message, quality_rules)
        issues.extend(evidence_issues)

    if issues:
        msg = "Quality check before completion:\n" + "\n".join(
            f"  - {i}" for i in issues
        )
        return {"action": "block", "message": msg}

    return None


def _check_workflow(state, rules):
    """Ralph Loop: detect incomplete workflows and block exit."""
    issues = []

    # Safety valve: max iterations before unconditional allow
    max_iterations = rules.get("max_iterations", 5)
    iteration = state.get("stop_iteration", 0)
    if iteration >= max_iterations:
        return []  # Allow stop unconditionally

    if not os.path.isfile(FAILURE_STATE_PATH):
        return []

    try:
        with open(FAILURE_STATE_PATH) as f:
            content = f.read()
    except OSError:
        return []

    # Parse YAML frontmatter
    frontmatter = _parse_frontmatter(content)
    if not frontmatter or frontmatter.get("status") != "active":
        return []

    # Stale detection
    stale_hours = rules.get("stale_hours", 4)
    started = frontmatter.get("started_at", "")
    if started:
        try:
            start_time = datetime.fromisoformat(
                started.replace("Z", "+00:00")
            )
            age_hours = (
                datetime.now(timezone.utc) - start_time
            ).total_seconds() / 3600
            if age_hours > stale_hours:
                return []  # Stale — allow stop
        except (ValueError, TypeError):
            pass

    # Active workflow detected — block exit
    skill = frontmatter.get("skill", "unknown")
    phase = frontmatter.get("phase", "?")
    phase_name = frontmatter.get("phase_name", "")
    next_action = frontmatter.get("next_action", "continue work")

    phase_display = f"{phase} ({phase_name})" if phase_name else phase
    issues.append(
        f"Incomplete workflow: {skill} Phase {phase_display} — {next_action}"
    )

    # Increment iteration counter
    state["stop_iteration"] = iteration + 1

    return issues


def _check_evidence(message, rules):
    """Check for unverified completion claims per quality rules."""
    issues = []

    # Check weak claim patterns
    for pattern in rules.get("weak_claims", []):
        matches = re.findall(pattern["regex"], message, re.IGNORECASE)
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
    claims_completion = bool(re.search(completion_re, message, re.IGNORECASE))
    has_evidence = bool(re.search(evidence_re, message, re.IGNORECASE))

    if claims_completion and not has_evidence:
        issues.append(
            "Task claimed complete but no test output found. Run tests and show output."
        )

    return issues


def _parse_frontmatter(content):
    """Extract YAML frontmatter from a file with --- delimiters."""
    if not content.startswith("---"):
        return None
    try:
        end = content.index("---", 3)
    except ValueError:
        return None

    fm_text = content[3:end].strip()
    result = {}
    for line in fm_text.split("\n"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" in line:
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.strip()
            # Strip quotes
            if val and ((val[0] == '"' and val[-1] == '"') or
                        (val[0] == "'" and val[-1] == "'")):
                val = val[1:-1]
            # Handle list values (simplified — just store as string)
            result[key] = val if val else None
    return result


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
