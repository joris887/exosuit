# First Run — Scaffolding the App Map

`/live-test` reads all project specifics from `docs/testing/APP_MAP.md`. When that file
does not exist, run this interview ONCE. Never create the file silently — the user
confirms every inference (documentation rule: docs are created only with user consent;
the confirmation below is that consent).

## 1. Detect the surface

Gather evidence (do not guess):

| Signal | Where to look | Suggests |
|--------|---------------|----------|
| `dev:` command in CLAUDE.md Commands | project CLAUDE.md | web or api (something serves) |
| SPA/framework config (vite/next/webpack/angular), `index.html` | repo root, frontend dirs | `web` |
| Server framework (fastapi/express/rails/spring…), route definitions, `compose.yaml` port mappings | source + compose files | `api` (or `web` if it also serves a UI) |
| `bin`/`console_scripts`/`cmd/` entrypoints, `--help` handling | package metadata, main module | `cli` |
| No executable entry point at all (importable package only) | package layout | `none` (library) |

A project can have MULTIPLE surfaces (e.g. web UI + admin UI + API). List each as a
named surface. Pick the PRIMARY surface for the default run; `--surface <name>` selects
others.

## 2. Confirm with the user

Ask (single AskUserQuestion, options from the evidence):

1. **Surfaces** — "I detected: <list with evidence>. Correct?" (user can add/remove)
2. **Entry points** — URL(s)/ports for web/api (localhost only), invocation for cli
3. **Access** — how to log in / authenticate (or "no auth"); which test accounts exist
   and which env var holds their credentials (NEVER store secrets in the map)
4. **Seed/reset** — commands that put test data in place (or "none")

If the user declines the interview or the project has no runnable surface: write the
map with `surface: none` and a one-line reason, so future runs halt fast with the
right pointer (`/quality-check` + `/manual-test`) instead of re-deriving this.

## 3. Write the map

1. Copy `${CLAUDE_SKILL_DIR}/assets/app-map-template.md` to `docs/testing/APP_MAP.md`
   (create `docs/testing/` if missing).
2. Fill every section from the interview + detected evidence. Cite evidence files in
   the header (`Verified <date> against <files>`) — claims must trace to code/config,
   per the framework's documentation-accuracy rules.
3. Fill the frontmatter `surface:` key (primary surface kind) and the `preflight-checks`
   block — one line per check the stack needs (`type|label|target|required|remedy`;
   fields must not contain `|`). Derive candidates from: compose services, health
   endpoints, dev-server URLs, `--version` for CLIs. Show every `cmd` check line to the
   user for approval — cmd checks execute as shell, so the map is trusted, executable
   configuration.
4. Leave sections that don't apply with their `<!-- n/a: reason -->` note rather than
   deleting them — future maintainers see what was considered.
5. Show the user the finished map, then run
   `bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh` to prove the checks work before the
   first real run.

## 4. Keep it fresh

The map is project documentation, owned by the adopting project (like
`UAT_COVERAGE.md`). When preflight fails against reality or routes/accounts changed,
update the map in the same run and note it in the findings file. Re-verify the
`Verified` header date when sections change.
