#!/usr/bin/env python3
"""Unified hook engine for JD-LLM Development Framework.

Single entry point for all hook events. Dispatches to per-event handler
modules and manages shared session state.

Usage: python3 .claude/hooks/engine.py <event_type>
Stdin: JSON payload from Claude Code
Exit:  0 = allow, 2 = block (message on stderr)
"""

import importlib
import json
import os
import sys

# Bootstrap: add hooks dir to path for lib imports
_HOOKS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _HOOKS_DIR)

from lib.paths import core_path  # noqa: E402

HOOKS_DIR = core_path("hooks")
STATE_FILE = core_path("hooks", "state", "session.json")
RULES_DIR = core_path("hooks", "rules")

HANDLER_MAP = {
    "PreToolUse": "pre_tool_use",
    "PostToolUse": "post_tool_use",
    "Stop": "stop",
    "UserPromptSubmit": "user_prompt",
    "SubagentStop": "subagent_stop",
    "SessionStart": "session_start",
    "WorktreeCreate": "worktree",
    "WorktreeRemove": "worktree",
}


# --- YAML loader (PyYAML with built-in fallback) ---


def load_rules(name):
    """Load a rules YAML file by name. Returns dict or empty dict on failure."""
    path = os.path.join(RULES_DIR, f"{name}.yaml")
    if not os.path.isfile(path):
        return {}
    with open(path) as f:
        text = f.read()
    try:
        import yaml
        return yaml.safe_load(text) or {}
    except ImportError:
        return _parse_yaml(text)


def _parse_yaml(text):
    """Minimal YAML parser for framework rule files.

    Handles the subset used by rule files: top-level mappings,
    lists of flat mappings, and scalar values. Not a general-purpose
    YAML parser — sufficient for key: value, lists of dicts, and scalars.
    """
    result = {}
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        indent = len(line) - len(line.lstrip())
        if indent == 0 and ":" in stripped:
            key, _, val = stripped.partition(":")
            key = key.strip()
            val = val.strip()
            if val:
                result[key] = _scalar(val)
                i += 1
            else:
                i += 1
                result[key], i = _parse_block(lines, i)
        else:
            i += 1
    return result


def _parse_block(lines, i):
    """Parse an indented block (list or mapping)."""
    while i < len(lines) and (not lines[i].strip() or lines[i].strip().startswith("#")):
        i += 1
    if i >= len(lines):
        return None, i
    base = len(lines[i]) - len(lines[i].lstrip())
    if lines[i].lstrip().startswith("- "):
        return _parse_list(lines, i, base)
    return _parse_mapping(lines, i, base)


def _parse_list(lines, i, base):
    """Parse a YAML list of scalars or flat mappings."""
    result = []
    item = None
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        indent = len(line) - len(line.lstrip())
        if indent < base:
            break
        if stripped.startswith("- "):
            if item is not None:
                result.append(item)
            content = stripped[2:].strip()
            if ":" in content:
                k, _, v = content.partition(":")
                item = {k.strip(): _scalar(v.strip())}
            else:
                item = _scalar(content)
            i += 1
        elif isinstance(item, dict) and ":" in stripped:
            k, _, v = stripped.partition(":")
            item[k.strip()] = _scalar(v.strip())
            i += 1
        else:
            i += 1
    if item is not None:
        result.append(item)
    return result, i


def _parse_mapping(lines, i, base):
    """Parse a flat YAML mapping."""
    result = {}
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        indent = len(line) - len(line.lstrip())
        if indent < base:
            break
        if ":" in stripped:
            k, _, v = stripped.partition(":")
            result[k.strip()] = _scalar(v.strip())
        i += 1
    return result, i


def _scalar(val):
    """Parse a YAML scalar value."""
    if not val:
        return None
    if (val.startswith('"') and val.endswith('"')) or \
       (val.startswith("'") and val.endswith("'")):
        return val[1:-1]
    low = val.lower()
    if low in ("true", "yes"):
        return True
    if low in ("false", "no"):
        return False
    if low in ("null", "~"):
        return None
    try:
        return int(val)
    except ValueError:
        pass
    try:
        return float(val)
    except ValueError:
        pass
    return val


# --- Session state ---


def load_state():
    """Load session state from state/session.json."""
    if os.path.isfile(STATE_FILE):
        try:
            with open(STATE_FILE) as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def save_state(state):
    """Persist session state."""
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except OSError:
        pass


# --- Dispatch ---


def main():
    if len(sys.argv) < 2:
        sys.exit(0)

    event = sys.argv[1]
    module_name = HANDLER_MAP.get(event)
    if not module_name:
        sys.exit(0)

    # Read stdin
    try:
        input_data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError, ValueError):
        input_data = {}

    # Import handler (HOOKS_DIR already on sys.path from bootstrap)
    try:
        handler = importlib.import_module(f"handlers.{module_name}")
    except ImportError as e:
        print(f"Hook engine: handler {module_name} not found: {e}", file=sys.stderr)
        sys.exit(0)

    # Load state and dispatch with error isolation
    state = load_state()
    try:
        result = handler.handle(input_data, event, state, load_rules)
    except Exception as handler_err:
        # Individual handler failure should not block the user's workflow.
        # Safety-critical handlers (PreToolUse) are the exception — if they fail,
        # we still allow the action but warn, since a crashed safety check is
        # better surfaced than silently swallowed.
        print(f"Hook handler error ({module_name}): {handler_err}", file=sys.stderr)
        result = None
    save_state(state)

    # Process result
    if result and result.get("action") == "block":
        print(result["message"], file=sys.stderr)
        sys.exit(2)
    if result and result.get("action") == "warn":
        print(result["message"], file=sys.stderr)

    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        # Graceful degradation: never crash the user's workflow
        print(f"Hook engine error (allowing): {e}", file=sys.stderr)
        sys.exit(0)
