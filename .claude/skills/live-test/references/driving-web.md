# Driving Guide — Web Surface (Browser via MCP)

How to drive a browser reliably and token-efficiently. Project specifics (URLs, accounts,
login recipes, timing budgets, known flakes) come from `docs/testing/APP_MAP.md` — never
hardcode them.

## Tool loading

Browser tools come from a **Playwright MCP** server (deferred tools; the exact tool
prefix depends on how it is installed in this environment). Load them with ToolSearch
before the main pass — a keyword search returns few results by default, so either raise
`max_results` (≥20) on one `"+playwright browser"` query, or use a `select:` query with
the exact names once the first search reveals the prefix.

Load at minimum: navigate, snapshot, click, type, fill_form, wait_for, evaluate,
console_messages, network_requests, take_screenshot, handle_dialog, select_option,
press_key, file_upload, close.

If the Playwright plugin is unavailable, fall back to the Chrome DevTools MCP plugin
(`navigate_page`, `take_snapshot`, `click`, `fill`, `wait_for`, `list_console_messages`,
`list_network_requests`, …). Same principles; tool names differ.

If NEITHER is available: do NOT halt — follow the skill's Graceful Degradation row
(generate the plan as a `/manual-test`-style checklist and hand it to the user;
suggest `claude mcp add playwright -- npx @playwright/mcp@latest` for next time).

## The core loop (per scenario)

```
navigate → wait_for (content) → snapshot → act on refs → wait_for (result) → verify 3 signals
```

1. **navigate** to the route (only ever URLs the app map declares — localhost only).
2. **wait_for** a piece of text/element that proves the page rendered (never sleep).
3. **snapshot** — returns the accessibility tree with element refs.
4. **act** — click/type/select using the `ref` from the snapshot plus a human-readable description.
5. **wait_for** the expected result, with the timeout from the app map's timing budgets.
6. **verify** the three signals (below).

## Three-signal verification (run after EVERY scenario)

A scenario only PASSES when all three signals are clean:

| Signal | Tool | Pass condition |
|--------|------|----------------|
| 1. UI | snapshot / wait_for | Expected text/element present; no error toast or unexpected empty state |
| 2. Console | console messages (level error) | No new errors (ignore known-benign noise listed in the app map § Known issues) |
| 3. Network | network requests | No unexpected 4xx/5xx (expected: 401/403 in negative access tests, 404 on deliberate not-found checks) |

Never declare PASS from the UI signal alone — a rendered page with a silently failed API
call is a classic false pass.

## Token discipline (snapshots are expensive)

- A full accessibility snapshot of a complex page can be 10–50K tokens.
- Snapshot **once per page state**; reuse its refs for multiple actions. Re-snapshot only
  after navigation or a DOM-changing action.
- Use subtree/depth parameters when you only need one region (a form, a table).
- For evidence/archival, save snapshots to disk instead of returning them into context.
- Screenshots: **only on failure**, saved to
  `docs/testing/findings/assets/<run-id>/<scenario-id>.png` — never inline.
- Do NOT spawn parallel agents that share the one browser — browser MCP sessions conflict.

## Element targeting

- Prefer `ref`s from the latest snapshot (deterministic, exists by construction).
- If you must use a selector: prefer role/text/label semantics over CSS classes —
  utility-class names are not stable identifiers.
- Components rendered in portals (dialogs, selects, popovers) appear outside their
  trigger's subtree — after opening one, re-snapshot to see its content.

## Waits

- NEVER sleep. Use wait_for with text/element and the timing budget from the app map.
- Page render: wait for a known heading/label, not for "networkidle".
- Slow asynchronous flows (the app map marks them, e.g. LLM-backed responses): use the
  map's long-wait budget; apply the map's known-flake retry policy before failing.
- Long async jobs: poll the status UI element (re-snapshot per the map's poll interval,
  bounded attempts), don't hold one long wait.

## Dialogs, uploads, downloads

- Native dialogs (confirm/alert): handle immediately after the triggering action —
  the page is blocked until handled.
- File upload: use an absolute path; use fixtures under `docs/testing/` or create a
  small temp file.
- Downloads/exports: verify via the network signal (2xx on the export request) — file
  content itself is out of browser-test scope.

## Access-control (role) testing

- Positive check: the account CAN see/do what its role allows.
- Negative check: the account CANNOT see (hidden control) or do (403 + error UI) what
  its role forbids. A 403 in the network log is a PASS here — record it as such.
- Check every access invariant the app map declares (§ Access invariants); a violated
  invariant is **Bug (Critical)** — security class.
- Switch accounts only via the app map's login/logout recipes; hard-reload after a
  switch so client state rebuilds from the new session. Never interleave two accounts
  in one browser session.

## Failure evidence bundle

When a scenario fails, capture (in this order, before navigating away):

1. Screenshot → `docs/testing/findings/assets/<run-id>/<scenario-id>.png`
2. Console errors → copy verbatim into the finding
3. Failed network requests → method, URL, status, response-body excerpt
4. The snapshot region showing the wrong/missing UI state
5. Backend correlation: run the app map's log-access command and capture the matching
   stack trace / request log
