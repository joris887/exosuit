Verify the git working tree is in a clean state:

```bash
git status
git branch --show-current
```

Check:
1. **No uncommitted changes** in tracked files
2. **No untracked files** in source directories (src/, lib/, app/, etc.)
3. **On the expected branch** (if `$1` is provided, verify branch matches `$1`)

If the working tree is dirty:
- Report what is uncommitted or untracked
- Ask user how to proceed before continuing
