# yantra — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile). Add release-hook wiring
> when the repo's release workflow lands.

## Version

**0.2.0** (in development) — opened 2026-06-03. The toolchain/CI/benchmark
modernization landed here and 0.2.0 ships with the M1 (Chromium/CDP) and M2
(Firefox/WebKit WebDriver) backend work — see [roadmap.md](roadmap.md).

**0.1.0** — scaffolded 2026-04-23 via `cyrius init yantra` (released). Module
skeletons + session / selector / action primitives. Browser and mobile
backends stubbed pending transport-layer depth.

## Toolchain

- **Cyrius pin**: `6.0.53` (in `cyrius.cyml [package].cyrius`) — bumped from
  5.6.17 on 2026-06-03; vendored `lib/` re-synced to the 6.0.53 snapshot via
  `cyrius lib sync` (the stale 5.6.17 snapshot was shadowing the pinned one).
- **Bundled lib versions** (6.0.53 snapshot): sakshi 2.2.6, sigil 3.6.0,
  patra 1.10.3, mabda 3.0.1.
- **sigil 3.6.0 requires** `thread.cyr` + `thread_local.cyr` included before
  it. Both are listed in `cyrius.cyml [deps] stdlib`. yantra does not include
  sigil yet (it enters at M8, cert verification) — this is a forward-looking
  constraint, not a current one.

## Supported backends

_None live yet — the scaffold compiles against the stdlib baseline with stubs. Planned backends, in order of expected implementation:_

| Platform | Protocol | Status |
|----------|----------|--------|
| Chromium (headless + headed) | Chrome DevTools Protocol (WebSocket) | **LIVE (M1)** — open/navigate/click/type/url/eval/close, auto-waiting; e2e green against headless Chromium |
| Firefox | W3C WebDriver (HTTP + JSON) | scaffold / blocked on `http.cyr` POST depth |
| WebKit (Safari, WebKitGTK) | W3C WebDriver | scaffold / blocked on `http.cyr` POST depth |
| Android (native apps) | Appium JSON-RPC → UiAutomator2 | scaffold / blocked on `http.cyr` POST depth |
| iOS (native apps) | Appium JSON-RPC → XCUITest | scaffold / blocked on `http.cyr` POST depth |

> **M1 note (2026-06-03)**: the CDP backend builds its own HTTP/1.1 GET for
> target discovery — Chromium's DevTools HTTP server rejects HTTP/1.0 (what
> stdlib `http_get` sends), so `src/protocol/cdp.cyr` issues `GET /json
> HTTP/1.1\r\nConnection: close` directly over `net.cyr` + a recv timeout.
> CDP commands then ride `ws.cyr` end to end. This quirk should be written up
> in `docs/architecture/`.

## Dependency gaps

Re-verified 2026-06-03 against the **6.0.53** stdlib snapshot (not the
roadmap, the actual vendored source). The earlier expectation that the
v5.7.x cycle would close these gaps did **not** hold — they are still open at
6.0.53:

- **`lib/http.cyr`** — minimal HTTP/1.0, **still GET-only at 6.0.53**
  (`http_get`, `http_get_a`, and the Result-typed `http_get_r` added in
  v5.8.31). No POST / PUT / DELETE, no custom headers. WebDriver + Appium
  JSON-RPC need that depth (POST, `Content-Type: application/json`, HTTPS);
  it has not landed. **This is the live blocker for M2–M4.** Depth, not existence.
- **`lib/json.cyr`** — basic parse/build (`json_parse`, `json_get`,
  `json_get_int`, `json_parse_file`). Deeper nesting / array / typed-value
  coverage still thin for WebDriver/Appium response shapes.
- **`lib/tls.cyr`** — HTTPS via the `libssl.so.3` `fdlopen` bridge. yantra's
  HTTPS path works today through it.
- **`lib/tls_native.cyr`** — *new at 6.0.x*: a pure-Cyrius TLS 1.3
  protocol-layer stack (crypto delegated to sigil). **Status: v6.0.10
  scaffold** — every verb returns `TLS_ERR_NOT_IMPLEMENTED`. So the native
  path exists as a module but is not yet functional; `tls.cyr` (the bridge)
  remains the working HTTPS transport. The native-TLS transition stays a
  Cyrius-side concern, not a yantra blocker.
- **`lib/ws.cyr`** — RFC 6455 client with text / binary / ping / pong / close.
  Sufficient for Chrome DevTools Protocol. No known gap here.

Net: only the **Chromium/CDP path (ws.cyr) is unblocked** today — exactly as
at scaffold time. WebDriver and Appium backends remain gated on `http.cyr`
POST/headers depth, now an **open** Cyrius-side item, not a delivered one.
Tracked upstream in [agnosticos/docs/development/v5.7.x-proposals.md](https://github.com/MacCracken/agnosticos/blob/main/docs/development/v5.7.x-proposals.md).

## Source

- `src/main.cyr` — Session / Selector / Action primitives (`yantra_version`,
  session field accessors). **Live.**
- `src/protocol/cdp.cyr` — Chrome DevTools Protocol over `ws.cyr`: discovery
  GET, command build/escape, response matching, eval/navigate/connect/close.
  **Live (M1).**
- `src/web.cyr` — browser public API: `yantra_web_open` / `navigate` / `click`
  / `click_now` / `type` / `url` / `eval_str` / `eval_bool` / `close`, with
  Playwright-style auto-waiting. **Live (M1).**

Planned (not yet written):
- `src/mobile.cyr` — mobile public API
- `src/protocol/webdriver.cyr` — W3C WebDriver wire protocol (M2, gated on `http.cyr` POST)
- `src/protocol/appium.cyr` — Appium JSON-RPC dialect (M3/M4)

The `[lib] modules` bundle order is `main → cdp → web`; these modules carry no
`include`s (stdlib resolved by the consumer). `programs/smoke.cyr` stitches the
stdlib chain on for a local link-check.

## Tests & benchmarks

- `tests/yantra.tcyr` — unit suite (`cyrius test`). Smoke-level today (2 passing).
- `tests/yantra.bcyr` — micro-benchmark harness (`cyrius bench`), real now:
  measures the session-primitive decode paths (~5 ns each).
- `tests/yantra.fcyr` — fuzz harness (`cyrius fuzz`), stub.
- `tests/e2e/chromium-smoke.tcyr` — M1 acceptance E2E. **Passing (11/11)**
  against live headless Chromium: open → navigate → url → type (value
  round-trips) → click (checkbox toggles) → click_now → close, all over CDP
  with auto-waiting. Runs in the CI `E2E (Chromium / CDP)` job.
- `programs/benchmarks.cyr` — incumbent-parity benchmark program (yantra vs
  Playwright/Appium). Scaffold + planned matrix; runs primitive benches today.
- `scripts/bench-history.sh` → `bench-history.csv` — AGNOS bench-history
  convention: one normalized (ns) row per benchmark per run, keyed by UTC
  timestamp + git short-sha. Wired into CI.
- `examples/web-consumer/login.tcyr` + `docs/examples/` — minimal
  "hello browser" consumer reference (mabda `examples/stdlib-consumer` analog).

## Dependencies

Declared in `cyrius.cyml`:

- **Cyrius stdlib** (comprehensive set — see manifest; `thread` +
  `thread_local` added for the sigil 3.6.0 requirement)
- **sakshi** 2.2.6 — structured logging / tracing (bundled in snapshot)
- **sigil** 3.6.0 — HTTPS cert verification (bundled in snapshot; not yet
  included by yantra — enters at M8)

## Consumers

_None yet. yantra is a library for downstream `.tcyr` tests. Expected first consumers:_

- AGNOS-owned projects that need E2E coverage (owl, agnoshi, tanur when GUI lands)
- Any AGNOS consumer that currently shells out to Playwright or Appium

## Next

See [roadmap.md](roadmap.md) for the full milestone sequence. Immediate sequence:

1. **M1 — Chromium CDP backend** (v0.2.0). ✅ **DONE** — `src/protocol/cdp.cyr`
   + `src/web.cyr` live, `tests/e2e/chromium-smoke.tcyr` green against headless
   Chromium, bundled into `dist/yantra.cyr`. Benchmark vs Playwright still TODO
   (needs the parity flow in `programs/benchmarks.cyr` wired to a real page).
2. **M2 — Firefox + WebKit WebDriver backends** (v0.3.0). *Blocked* on
   `lib/http.cyr` POST + headers + HTTPS depth (open Cyrius-side gap; still
   GET-only at 6.0.53).
3. **M3 — Android Appium backend** (v0.4.0). *Blocked on v5.7.x.* Needs `lib/http.cyr` depth + `lib/json.cyr` depth.
4. **M4 — iOS Appium backend** (v0.5.0). Same unblock as M3.
5. **M5 onward** — auto-teardown, CI matrix, docs, security hardening, v1.0.

Knife article ("Why UI Automation Belongs in Your Language" or similar) lands when yantra has at least one live backend with a benchmark against the Playwright or Appium equivalent on the same workload — earliest opportunity is M1 closeout.
