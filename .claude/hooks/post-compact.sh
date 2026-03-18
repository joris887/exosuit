#!/bin/sh
# PostCompact hook: remind model of session state after compaction.
# Reads the auto-save file and emits key state as advisory context.
#
# Input:  JSON on stdin (PostCompact event data)
# Output: exit 0 always, stderr = advisory context

AUTOSAVE="docs/sessions/.auto-save.md"

if [ -f "$AUTOSAVE" ]; then
    BRANCH=""
    TRIGGER=""
    GENERATED=""

    # Extract key fields from auto-save
    while IFS= read -r line; do
        case "$line" in
            *"Branch:"*) BRANCH=$(echo "$line" | sed 's/.*Branch:[[:space:]]*//');;
            *"Trigger:"*) TRIGGER=$(echo "$line" | sed 's/.*Trigger:[[:space:]]*//');;
            *"Generated:"*) GENERATED=$(echo "$line" | sed 's/.*Generated:[[:space:]]*//');;
        esac
    done < "$AUTOSAVE"

    printf 'Context compaction completed. Session state preserved:\n' >&2
    [ -n "$BRANCH" ] && printf '  Branch: %s\n' "$BRANCH" >&2
    [ -n "$GENERATED" ] && printf '  Saved at: %s\n' "$GENERATED" >&2
    printf '  Full state: %s\n' "$AUTOSAVE" >&2
    printf 'Read %s if you need to recover context about what you were working on.\n' "$AUTOSAVE" >&2
fi

exit 0
