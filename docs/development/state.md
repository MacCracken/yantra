# yantra — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile). Add release-hook wiring
> when the repo's release workflow lands.

## Version

**0.1.0** — scaffolded 2026-04-23 via `cyrius init yantra`. Module skeletons + session / selector / action primitives land first. Browser and mobile backends are stubbed until the HTTP + WebSocket transport crates (or stdlib additions) land.

## Toolchain

- **Cyrius pin**: `5.6.17` (in `cyrius.cyml [package].cyrius`)

## Supported backends

_None live yet — the scaffold compiles against the stdlib baseline with stubs. Planned backends, in order of expected implementation:_

| Platform | Protocol | Status |
|----------|----------|--------|
| Chromium (headless + headed) | Chrome DevTools Protocol (WebSocket) | scaffold / blocked on WebSocket transport |
| Firefox | W3C WebDriver (HTTP + JSON) | scaffold / blocked on HTTP client |
| WebKit (Safari, WebKitGTK) | W3C WebDriver | scaffold / blocked on HTTP client |
| Android (native apps) | Appium JSON-RPC → UiAutomator2 | scaffold / blocked on HTTP client |
| iOS (native apps) | Appium JSON-RPC → XCUITest | scaffold / blocked on HTTP client |

## Dependency gaps

Correction (2026-04-23): the earlier "HTTP + WebSocket missing from stdlib" claim was wrong. The transports exist but are thin. Real gaps:

- **`lib/http.cyr`** — minimal HTTP/1.0, **GET-only**, no header support, no HTTPS integration. WebDriver + Appium JSON-RPC need POST / PUT / DELETE, custom headers (`Content-Type: application/json`), and HTTPS (integration with `lib/tls.cyr`). Depth, not existence.
- **`lib/json.cyr`** — basic key-value pair roundtrip. Deeper nesting, arrays, numbers, booleans, null coverage needed before it carries WebDriver/Appium response shapes cleanly.
- **`lib/tls.cyr`** — functional, but is an FFI bridge to `libssl.so.3` / `libcrypto.so.3` via `dynlib`. Native pure-Cyrius TLS 1.3 is scheduled for Cyrius v5.9.0–v5.9.7 per the cyrius roadmap. yantra's HTTPS path works today via the FFI bridge; the native-TLS transition is a Cyrius-side concern, not a yantra blocker.
- **`lib/ws.cyr`** — RFC 6455 client with text / binary / ping / pong / close. Sufficient for Chrome DevTools Protocol. No known gap here.

These gaps are tracked in [agnosticos/docs/development/v5.7.x-proposals.md](https://github.com/MacCracken/agnosticos/blob/main/docs/development/v5.7.x-proposals.md) for the cyrius agent to triage. yantra can start backend scaffolding now against the CDP path (ws.cyr is complete); WebDriver and Appium backends wait on http.cyr depth.

## Source

Scaffolded skeleton only. Line counts will populate as modules fill in.

Planned modules:
- `src/main.cyr` — Session / Selector / Action / Assertion primitives
- `src/web.cyr` — browser public API
- `src/mobile.cyr` — mobile public API
- `src/protocol/cdp.cyr` — Chrome DevTools Protocol
- `src/protocol/webdriver.cyr` — W3C WebDriver wire protocol
- `src/protocol/appium.cyr` — Appium JSON-RPC dialect

## Tests

- `tests/yantra.tcyr` — unit tests (not yet written)
- `tests/e2e/` — E2E suite against live headless browsers + emulators (not yet scaffolded; lands with the first working backend)

## Dependencies

Declared in `cyrius.cyml`:

- **Cyrius stdlib** (comprehensive set — see manifest)
- **sakshi** 2.1.0 — structured logging / tracing
- **sigil** 2.9.1 — HTTPS cert verification

## Consumers

_None yet. yantra is a library for downstream `.tcyr` tests. Expected first consumers:_

- AGNOS-owned projects that need E2E coverage (owl, agnoshi, tanur when GUI lands)
- Any AGNOS consumer that currently shells out to Playwright or Appium

## Next

See [roadmap.md](roadmap.md) for the full milestone sequence. Immediate sequence:

1. **M1 — Chromium CDP backend** (v0.2.0). *Unblocked today.* CDP speaks WebSocket end-to-end; `lib/ws.cyr` is complete. Build `src/protocol/cdp.cyr` + `src/web.cyr` against stdlib, land `tests/e2e/chromium-smoke.tcyr` running against headless Chromium. First live backend does not wait on v5.7.x.
2. **M2 — Firefox + WebKit WebDriver backends** (v0.3.0). *Blocked on v5.7.x.* Needs `lib/http.cyr` POST + headers + HTTPS depth.
3. **M3 — Android Appium backend** (v0.4.0). *Blocked on v5.7.x.* Needs `lib/http.cyr` depth + `lib/json.cyr` depth.
4. **M4 — iOS Appium backend** (v0.5.0). Same unblock as M3.
5. **M5 onward** — auto-teardown, CI matrix, docs, security hardening, v1.0.

Knife article ("Why UI Automation Belongs in Your Language" or similar) lands when yantra has at least one live backend with a benchmark against the Playwright or Appium equivalent on the same workload — earliest opportunity is M1 closeout.
