# Claude Code Hooks

Hook scripts that enforce quality and safety automatically during Claude Code sessions.

## Hook Types

### post-edit-format.sh (PostToolUse)
Runs after Claude edits a file. Auto-formats the file using your project's formatter, then runs the linter in auto-fix mode on the same file.

**Supported formatters:** prettier, biome, ruff, black, rustfmt, gofmt, swift-format, rubocop
**Supported linters (auto-fix):** ruff, eslint, biome, golangci-lint (Rust clippy and Swift swiftlint skipped — they require full project context)

### pre-stop-quality.sh (Stop)
Runs before Claude reports a task as complete. Executes lint, typecheck, and test suite. Blocks completion if any check fails, creating a self-correction loop.

### pre-tool-safety.sh (PreToolUse)
Runs before Bash commands execute. Blocks dangerous operations:
- `git push --force` / `git push -f`
- `git checkout .` (discard all changes)
- `git reset --hard`
- `git clean -f`
- `rm -rf /` or `rm -rf ..` or `rm -rf ~`
- Package publishing (`npm publish`, `cargo publish`, `twine upload`, `gem push`, `pod trunk push`)
- Destructive database operations (`DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`)
- Mass process killing (`kill -9 -1`, `killall`, `pkill -9`)

## Configuration

Hooks are configured in `.claude/settings.json`. The `/bootstrap` skill customizes them for your detected stack.

To enable hooks manually, add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "bash .claude/hooks/post-edit-format.sh $FILE_PATH"
      }
    ],
    "Stop": [
      {
        "command": "bash .claude/hooks/pre-stop-quality.sh"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "bash .claude/hooks/pre-tool-safety.sh \"$COMMAND\""
      }
    ]
  }
}
```

## Customization

Edit the hook scripts directly. They're plain bash scripts.

- **Add formatters:** Edit `post-edit-format.sh` case statement
- **Add quality checks:** Uncomment or add commands in `pre-stop-quality.sh`
- **Add safety rules:** Add grep patterns in `pre-tool-safety.sh`

## Disabling Hooks

Remove or comment out the relevant section in `.claude/settings.json`.
