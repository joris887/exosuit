---
surface: {{web | api | cli | none}}
verified: {{YYYY-MM-DD}}
---

# App Map — live-test project facts

> Verified {{YYYY-MM-DD}} against {{evidence files, e.g. compose.yaml, src/App.tsx, package.json}}
> Owned by this project (like UAT_COVERAGE.md). Update when preflight disagrees with reality.
> TRUST NOTE: the preflight-checks block below is executable configuration (like a
> Makefile) — only maintainers edit this file, and cmd lines are shown for human
> approval during the /live-test first-run interview.

## Surfaces

The frontmatter `surface:` key names the PRIMARY surface kind. Projects with no runnable
surface set `surface: none` (plus a one-line reason here) — /live-test then halts and
points to /quality-check + /manual-test. List every runnable surface below;
`--surface <name>` selects one, `--surface all` runs each in sequence.

| Surface | Kind | Entry point | Notes |
|---------|------|-------------|-------|
| {{name, e.g. app}} | {{web}} | {{http://localhost:PORT}} | {{primary}} |
| {{name, e.g. admin}} | {{web}} | {{http://localhost:PORT}} | {{optional area}} |

- **CLI working directory:** {{path, or "repo root" — only for cli surfaces}}

## Preflight checks

Machine-parsed by the /live-test preflight script — keep the fence at the start of the
line (not indented, not inside a list or blockquote) and the exact field order:
`type|label|target|required|remedy`. Types: `http` (curl, expects 2xx/3xx;
localhost targets only) · `compose` (docker compose service running) · `cmd` (shell
command, expects exit 0). `required`: `yes` → failure blocks the run; `no` → warning
only. Fields must NOT contain `|` — for piped assertions use `&&` with a temp file,
e.g. body inspection of a degradable health endpoint:
`cmd|llm dependency ok|H=$(mktemp) && curl -s -m 10 -o "$H" http://localhost:8000/healthz && grep -q ok "$H"; r=$?; rm -f "$H"; exit $r|no|LLM-backed scenarios will fail; ask user whether to run the unaffected subset`

```preflight-checks
{{http|backend healthy|http://localhost:8000/healthz|yes|docker compose up -d}}
{{compose|database up|db|yes|docker compose up -d db}}
{{cmd|cli responds|<invocation> --version|yes|<build/install command>}}
```

## Access & test accounts

- **Auth mode:** {{ui-login | token | none}}
- **Login recipe (real flow — first scenario always uses this):** {{steps: URL, fields, expected landing}}
- **Fast switch recipe (optional):** {{token endpoint + injection steps, or "n/a: ui-login only"}}
- **Logout / switch recipe:** {{how to clear session state}}
- **Credentials:** env var {{NAME}} — export before the run; never store secret values in this file.

| Account | Role | Use for |
|---------|------|---------|
| {{user/email}} | {{role}} | Main pass — can do everything |
| {{user/email}} | {{restricted role}} | Role sweep — positive + negative checks |

## Access invariants

One assertion per line; a violated invariant is Bug (Critical) — security class.

- {{e.g. "approve/finalize actions are <role>-only; admins must be refused"}}
- {{e.g. "unauthenticated requests to /api/* return 401"}}

## Routes/endpoints/commands

What the scope argument resolves against. Group by surface.

| Scope keyword | Surface | Route / endpoint / subcommand | Feature / Epic |
|---------------|---------|-------------------------------|----------------|
| {{feature-area}} | {{app}} | {{/route or METHOD /path or subcommand}} | {{E##}} |

## Timing budgets

| Operation | Typical | Wait timeout |
|-----------|---------|--------------|
| Page load / first request | {{2–10 s}} | {{30 s}} |
| Login round-trip | {{1–3 s}} | {{15 s}} |
| CRUD / simple command | {{< 2 s}} | {{15 s}} |
| Long-async flows ({{which}}) | {{10–60 s}} | {{120 s}} |
| Background jobs ({{which}}) | {{minutes}} | poll every {{15 s}}, max {{10}} polls |

## Seed commands

<!-- n/a: no seeding needed — remove this note if filling the table -->

| Scope | Command | Notes |
|-------|---------|-------|
| {{feature}} | {{command}} | {{idempotent?}} |

## Known issues & flakes

Check BEFORE classifying any failure (also re-check `docs/reference/BACKLOG_INDEX.md`
ready/draft stories — those are known gaps, do not re-discover them).

- {{ID}} — {{symptom}} — retry policy: {{retry once | none}}
- Console noise to ignore: {{known-benign warnings, or "none"}}

## Log access

- {{command to tail app/server logs, e.g. `docker compose logs app --since 5m | tail -50`, or "n/a"}}

## Harness facts

| Layer | Harness | Fix-loop rule |
|-------|---------|---------------|
| {{backend}} | {{pytest / jest / none}} | {{harness → failing test first; none → the re-run probe IS the regression check}} |
| {{frontend}} | {{none}} | {{...}} |
