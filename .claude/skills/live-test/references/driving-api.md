# Driving Guide — API Surface (HTTP probes via curl)

How to test a running HTTP API end-to-end. Project specifics (base URL, auth recipe,
endpoints, timing budgets, log access) come from `docs/testing/APP_MAP.md`.

## The probe

A scenario's probe is one or more HTTP requests against the running server:

```bash
BODY=$(mktemp)   # per-request temp file — never a predictable path
curl -s -o "$BODY" -w '%{http_code}' -m <timeout> \
  -X <METHOD> "<base-url><path>" \
  -H 'Content-Type: application/json' [auth headers per app map] \
  [-d '<payload>']
```

- Base URL comes from the app map — localhost only, same refusal rule as every surface.
- Timeouts come from the app map's timing budgets (default: 15s; long-async endpoints
  use the map's long-wait budget).
- Save response bodies to a temp file created with `mktemp`; excerpt into findings —
  never dump large bodies into context. Do NOT use a fixed path like
  `/tmp/live-test-body.json`: it collides between concurrent worktree runs and is
  symlink-clobberable on a shared host. Delete the file when the scenario ends.
- Response bodies routinely contain session tokens and real user data. The framework's
  secrets scanner does not inspect `.md`/`.txt`, so review any excerpt before it is
  written into a committed findings file.

## Three-signal verification (run after EVERY scenario)

| Signal | Source | Pass condition |
|--------|--------|----------------|
| 1. Response | status code + body | Expected status; body matches the scenario's expectations (fields present, values correct, error shape for negative tests) |
| 2. Server log | app map's log-access command | No new errors/stack traces correlated with the request (ignore known-benign noise from the map § Known issues) |
| 3. Side effects | follow-up probe or map-declared check command | State actually changed (or did NOT change, for negative/validation tests): re-GET the resource, or run the map's side-effect check |

Never declare PASS from the status code alone — a 200 with a wrong body, a swallowed
server error, or a missing side effect is a false pass.

## Scenario anatomy

Each scenario declares: `id · account · request(s) · expected status · expected body
assertions · expected side effect · access-sensitive? (y/n)`.

- **Sequences**: multi-step flows (create → read → update → delete) are ONE scenario;
  verify signals after each step; stop the scenario at the first failing step.
- **Validation/negative tests**: send malformed payloads, missing fields, out-of-range
  values — expect 4xx with a useful error body, and NO side effect.
- **Idempotency/double-submit**: repeat a mutating request; verify the API's declared
  behavior (409, no-op, or duplicate — per the scenario's expectation).

## Auth and account switching

- Authenticate exactly as the app map's access recipe describes (login endpoint →
  token/cookie; or static test tokens). Credentials come from the env var the map
  names — never from the map file itself, never hardcoded.
- First scenario authenticates via the real login flow (this tests it); later
  scenarios reuse the session/token.
- Account switch: discard the previous token/cookie completely, re-authenticate.
  Never mix two accounts' credentials in one scenario.

## Access-control (role) testing

- Positive check: the account's request succeeds (2xx) where its role allows.
- Negative check: the same request as a forbidden role returns 401/403 (that IS the
  pass) — and produced NO side effect (verify with signal 3).
- Check every access invariant the app map declares; a violated invariant is
  **Bug (Critical)** — security class.

## Failure evidence bundle

When a scenario fails, capture:

1. The exact request (method, URL, headers minus secrets, payload) — reproducible as
   a curl one-liner in the finding
2. Response: status + body excerpt → `docs/testing/findings/assets/<run-id>/<scenario-id>.txt`
3. Server log correlation: run the app map's log-access command, capture the matching
   stack trace / request log
4. Side-effect state: what the follow-up probe showed vs what was expected
