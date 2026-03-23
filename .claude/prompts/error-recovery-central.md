Centralized error recovery patterns. Skills reference this when encountering common failures.

## Common Tool Failures

### gh CLI Failures
| Error | Cause | Recovery |
|-------|-------|----------|
| `gh: command not found` | GitHub CLI not installed | Install: `brew install gh` (macOS) or see cli.github.com. Skip PR features, use manual git push. |
| `gh auth login` required | Not authenticated | Ask user to run `! gh auth login` in the prompt. |
| `GraphQL: Resource not accessible` | Insufficient permissions | Check repo permissions. For forks, use `gh pr create --head user:branch`. |
| `gh pr create` fails | No remote, or remote is template repo | Check `git remote -v`. Set remote: `git remote set-url origin <url>`. |

### Git Failures
| Error | Cause | Recovery |
|-------|-------|----------|
| `fatal: not a git repository` | Not in a git repo | Run from project root. Check `pwd`. |
| `error: pathspec did not match` | File doesn't exist at path | Verify path with `ls`. Check for typos. |
| `CONFLICT` during merge/pull | Merge conflict | Show conflicting files. Guide resolution. Never auto-resolve. |
| `failed to push some refs` | Remote has new commits | `git pull --rebase origin <branch>` then retry push. |

### Test Runner Failures
| Error | Cause | Recovery |
|-------|-------|----------|
| Test command not found | Test runner not installed | Check `CLAUDE.md Commands`. Suggest `/bootstrap` to configure. |
| Import/module errors in tests | Missing dependencies | Run `npm install` / `pip install -e .` / equivalent. |
| Timeout during tests | Slow tests or hanging process | Run with timeout: `timeout 120 <test-command>`. Check for infinite loops. |
| Flaky test (passes sometimes) | Race condition or external dependency | Re-run 3x. If inconsistent, flag as flaky. Check for shared state. |

### Build Failures
| Error | Cause | Recovery |
|-------|-------|----------|
| Type errors | Type mismatch or missing types | Fix types. Don't add `any` or `# type: ignore` as workaround. |
| Missing dependency | Package not installed | Run package manager install. Check lockfile. |
| Out of memory | Large build/test | Close other processes. Set NODE_OPTIONS=--max-old-space-size. |

## Skill-Specific Recovery

### story-cycle
| Phase | Error | Recovery |
|-------|-------|----------|
| Phase 1 (Plan) | Plan mode exit wipes context | Re-read plan file's remaining_steps list immediately |
| Phase 3 (Implement) | Tests fail after implementation | Check test output. Fix implementation, not tests. If 3+ attempts fail, consider wrong approach. |
| Phase 4 (Quality gates) | Lint/typecheck fails | Fix issues. Re-run gates. Don't skip. |

### sprint-end
| Step | Error | Recovery |
|------|-------|----------|
| Push | Remote rejected | Pull latest, resolve conflicts, push again. |
| PR creation | Missing template fields | Fill all required sections. |
| CI | Checks failing | Diagnose from `gh pr checks`. Fix and push. |
| Merge | Not mergeable | Check for conflicts, required reviews, failing checks. |

### debug-session
| Phase | Error | Recovery |
|-------|-------|----------|
| Phase 1 | Cannot reproduce | Gather more context. Check environment differences. |
| Phase 3 | 3+ fix attempts failed | STOP. Return to Phase 1. Root cause was wrong. |
| Phase 4 | Fix introduces new failures | Revert fix. Original bug is better than two bugs. |

## General Recovery Principles

1. **Never brute-force** — If an approach fails 3 times, try a different approach
2. **Preserve work** — Stash or commit before attempting recovery
3. **Diagnose before fixing** — Understand the error before acting
4. **Escalate to user** — If recovery is uncertain, present options rather than guessing
5. **Log failures** — Use `record-failure` micro-component for cross-session learning
