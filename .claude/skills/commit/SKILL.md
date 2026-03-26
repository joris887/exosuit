---
name: commit
version: 2.4.0
description: Create a well-formatted conventional commit with proper message structure. Use when ready to commit changes.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash
argument-hint: "[type] [scope]"
---
______________________________________________________________________

## commit

Create a conventional commit for staged changes.

## 1. Review Changes

```bash
git status
git diff --staged
```

## 2. Determine Commit Type

Based on changes, select appropriate type:

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only
- **style**: Formatting, no code change
- **refactor**: Code restructuring
- **perf**: Performance improvement
- **test**: Adding/updating tests
- **build**: Build system or dependency changes
- **ci**: CI configuration changes
- **chore**: Maintenance tasks

## 3. Generate Commit Message

Format:

```
<type>(<scope>): <short description>

<detailed body if needed>

Co-Authored-By: Claude <noreply@anthropic.com>
```

Arguments provided: **$ARGUMENTS**

## 4. Execute Commit

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<body>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## 5. Verify

```bash
git log -1 --oneline
```
