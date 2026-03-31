---
name: deploy
version: 1.0.0
description: Deploy the project to a hosting platform. Detects deployment configuration, runs pre-deploy checks, and guides first-time setup.
trigger: manual
depends-on: []
references: []
micro-components:
  pre-deploy: [discover-commands, verify-clean-git-state]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[platform] [--dry-run]"
---
______________________________________________________________________

## deploy

Deploy the project to a hosting platform.

## Arguments

- `$1` (optional) — platform name override (e.g., `vercel`, `fly`, `railway`)
- `--dry-run` — show what would happen without executing

## Step 1: Pre-Deploy Checks

Run the `verify-clean-git-state` micro-component from `.claude/prompts/verify-clean-git-state.md`.

Run the `discover-commands` micro-component from `.claude/prompts/discover-commands.md`.

<IF condition="test command configured">
Run tests:
```bash
# Run the project's test command
```
<IF condition="tests fail">
**HALT** — "Tests are failing. Fix them before deploying — deploying broken code risks downtime for your users."
Present the failure output and suggest `/debug-session` if needed.
</IF>
</IF>

Check git state:
- Warn if not on the default branch (but allow if user confirms)
- Warn if there are uncommitted changes

## Step 2: Detect Platform

<IF condition="$1 provided (platform override)">
Use the specified platform. Skip auto-detection.
</IF>
<ELSE>
Detect deployment configuration by checking for platform-specific files:

| File / Directory | Platform |
|---|---|
| `vercel.json` or `.vercel/` | Vercel |
| `netlify.toml` or `_redirects` | Netlify |
| `fly.toml` | Fly.io |
| `railway.json` or `railway.toml` | Railway |
| `render.yaml` | Render |
| `app.yaml` (with `runtime:` or `env:`) | Google App Engine |
| `Procfile` + `app.json` | Heroku |
| `amplify.yml` or `amplify/` | AWS Amplify |
| `Dockerfile` + (`docker-compose.yml` or cloud config) | Container deployment |

<IF condition="no platform detected">
Present options:
```
No deployment configuration detected. Where would you like to deploy?

1. **Vercel** — best for Next.js, React, static sites. Free tier available.
2. **Railway** — best for full-stack apps with databases. Starts at $5/month.
3. **Fly.io** — best for apps needing global distribution. Free tier for small apps.
4. **Netlify** — best for static sites and Jamstack. Free tier available.
5. **Render** — best for background workers and cron jobs. Free tier available.
6. **Other** — I'll help you set up a Dockerfile for any platform.
```
Wait for user choice, then guide platform setup (generate config file, install CLI if needed).
</IF>
</ELSE>

## Step 3: Verify CLI Tool

Check if the platform's CLI tool is installed:

| Platform | CLI | Check | Install |
|---|---|---|---|
| Vercel | `vercel` | `vercel --version` | `npm i -g vercel` |
| Netlify | `netlify` | `netlify --version` | `npm i -g netlify-cli` |
| Fly.io | `flyctl` | `flyctl version` | `curl -L https://fly.io/install.sh \| sh` |
| Railway | `railway` | `railway --version` | `npm i -g @railway/cli` |
| Render | — | N/A (git push deploy) | N/A |
| Heroku | `heroku` | `heroku --version` | `brew install heroku/brew/heroku` or `npm i -g heroku` |

<IF condition="CLI not installed">
Show install command and ask user to install. If they can't install, provide manual deployment instructions:
"You can also deploy by pushing to your platform's git remote. Here's how: [platform-specific git push instructions]"
</IF>

## Step 4: Deploy

<IF condition="--dry-run">
Show what would be executed without running it:
```
Dry run — would execute:
  Platform: [name]
  Command: [deploy command]
  Branch: [current branch]
  Tests: [pass count]
```
Stop here.
</IF>

Execute the deployment:

| Platform | Command |
|---|---|
| Vercel | `vercel --prod` (or `vercel` for preview) |
| Netlify | `netlify deploy --prod` |
| Fly.io | `flyctl deploy` |
| Railway | `railway up` |
| Render | `git push render main` |
| Heroku | `git push heroku main` |

Monitor output for:
- Deployment URL (capture and display prominently)
- Build errors (present clearly with suggested fixes)
- Warnings (surface but don't block)

## Step 5: Report

```markdown
## Deployment Complete

**URL:** https://your-app.vercel.app
**Platform:** Vercel
**Branch:** main
**Tests:** 47 passing before deploy

### What Happened
- Built the project successfully
- Deployed to production
- Live at the URL above

### Next Time
Run `/deploy` again to redeploy after changes.
```

<IF condition="deployment failed">
```markdown
## Deployment Failed

**Platform:** [name]
**Error:** [error message]

### What to Try
- [Specific suggestion based on error]
- [Platform documentation link if known]
- Run `/debug-session "[error]"` for deeper investigation
```
</IF>

## Rules

- **Never deploy from a dirty working tree** without explicit user confirmation
- **Never deploy with failing tests** without explicit user confirmation
- **Always show the live URL** after successful deployment
- **Graceful degradation** — if CLI is missing, show manual instructions instead of failing
- **No forced deploys** — if something looks wrong, warn and ask before proceeding
- This skill is READ + BASH only — no file edits. Deployment config generation happens in Step 2 only when no config exists.
