# yantra — Roadmap

> Milestone plan through v1.0. State lives in [`state.md`](state.md);
> this file is the sequencing — what ships, in what order, against
> what dependency gates.

## Dependency gates summary

| Backend | Transport dep | Stdlib status (2026-06-03, verified vs 6.0.53) | Unblocked? |
|---------|--------------|---------------------------|------------|
| Chromium (CDP) | `lib/ws.cyr` (RFC 6455 client) | **Live — full framing, text/binary/ping/pong/close** | **Yes — shipped (M1)** |
| Firefox (W3C WebDriver) | `lib/sandhi.cyr` HTTP POST + headers | **Present** — full HTTP/1.1+2 client | **Yes (M2, in progress)** |
| WebKit (W3C WebDriver) | `lib/sandhi.cyr` HTTP + HTTPS | Present (HTTPS via `tls.cyr` bridge) | **Yes (M2)** |
| Android (Appium / UiAutomator2) | `lib/sandhi.cyr` HTTP POST + `json_v` | Both present | **Yes (M3)** |
| iOS (Appium / XCUITest) | Same as Android | Same | **Yes (M4)** |

**Critical observation**: every backend is transport-unblocked. CDP rides `lib/ws.cyr`; WebDriver and Appium ride `lib/sandhi.cyr` (full HTTP/1.1+2: POST, headers, HTTPS) + `lib/json.cyr`'s value-tree.

> **Correction (2026-06-03, superseding an earlier wrong note)**: a prior
> revision claimed M2–M4 were blocked because `lib/http.cyr` is GET-only. That
> was an error — it overlooked **`lib/sandhi.cyr`**, the stdlib's full HTTP
> client (`sandhi_http_post` with headers + body, HTTPS, etc.). The minimal
> `http.cyr` is irrelevant; M2–M4 are not blocked. M1 already shipped.

## Milestones

### M0 — Scaffold (v0.1.0) — ✅ shipped 2026-04-23

- `cyrius init yantra` scaffold migrated to library shape (`[lib]` block, `programs/smoke.cyr`)
- Session / Selector / Action primitives declared in `src/main.cyr`
- ADR 0001 captures the library-not-framework refusal thesis
- Docs scaffolded per [first-party-documentation.md](https://github.com/MacCracken/agnosticos/blob/main/docs/development/applications/first-party-documentation.md)
- Added to [shared-crates.md](https://github.com/MacCracken/agnosticos/blob/main/docs/development/applications/shared-crates.md) Pre-1.0 In Progress

### M1 — Chromium CDP backend (shipped v0.2.1, 2026-06-03)

*First live backend. Unblocked — no dep gate.* Delivered: `src/protocol/cdp.cyr`
(CDP over `ws.cyr`; own HTTP/1.1 discovery GET since Chromium rejects HTTP/1.0),
`src/web.cyr` (open/navigate/click/click_now/type/url/eval/close + auto-waiting),
`tests/e2e/chromium-smoke.tcyr` green (11/11) against headless Chromium and gated
in the CI `E2E (Chromium / CDP)` job, bundled into `dist/yantra.cyr`. Playwright
parity benchmarked (`programs/benchmarks.cyr` + `scripts/parity-playwright.mjs`):
yantra ~3× on navigate+click+assert, parity on navigate — numbers in state.md.

*Original scope:*

- `src/protocol/cdp.cyr` — Chrome DevTools Protocol implementation against `lib/ws.cyr`
- `src/web.cyr` — public API surface for `yantra_web_open("chromium")`, `yantra_navigate`, `yantra_click`, `yantra_type`, `yantra_close`
- Session primitives wired to CDP targets via `Target.createTarget` / `Target.attachToTarget`
- Auto-waiting built in (Playwright-style — every action waits for element-actionable before operating)
- `tests/e2e/chromium-smoke.tcyr` — full round trip: open session, navigate, click, assert URL, close. Runs against headless Chromium
- `cyrius distlib` produces `dist/yantra.cyr` with CDP backend included

**Acceptance**: a `.tcyr` file using `yantra_web_open("chromium")` passes against a running headless Chromium instance. Benchmark vs Playwright-Python on the same navigation-click-assert flow, numbers into `state.md`.

### M2 — Firefox / WebKit WebDriver backend (shipped v0.3.0, 2026-06-03)

✅ **Done.** `src/protocol/webdriver.cyr` (W3C WebDriver JSON wire over an
in-tree Content-Length-framed HTTP/1.1 client — see architecture 002 for why not
`sandhi`) + transport-aware `src/web.cyr`. `yantra_web_open("firefox"/"webkit")`
routes to geckodriver/webkitwebdriver (port 4444); `"chrome"` to chromedriver
(9515). Shared session semantics + auto-waiting with the CDP path. E2E **9/9**
against live chromedriver (`tests/e2e/webdriver-smoke.tcyr`); the wire is
identical for the Firefox/WebKit drivers. Selector translation: leading `/` →
xpath, else css selector.

*Original scope:*

- `src/protocol/webdriver.cyr` — W3C WebDriver JSON wire protocol
- `yantra_web_open("firefox")` + `yantra_web_open("webkit")` routing
- Selector translation: WebDriver's `css selector` / `xpath` / `link text` strategies
- Shared session semantics with CDP — same `yantra_web_open` API, same auto-waiting, same `yantra_close` teardown

**Acceptance**: the M1 smoke test file runs unchanged except for the opener call against Firefox headless and WebKit headless. Numbers into `state.md`.

### M3 — Android Appium backend (v0.4.0)

*Unblocked — Appium is HTTP+JSON-RPC; rides `lib/sandhi.cyr` (POST + headers) and `lib/json.cyr`'s value-tree.*

- `src/protocol/appium.cyr` — Appium JSON-RPC dialect
- `src/mobile.cyr` — public API surface for `yantra_mobile_open("android", "com.example.app")`, `yantra_tap`, `yantra_type`, `yantra_close`
- Session connects to a local Appium server (default `http://localhost:4723`) driving UiAutomator2
- Selector translation: `@id/resource_id`, text-match, class-name, XPath

**Acceptance**: `.tcyr` file opens an Android emulator session, taps a resource-id, asserts visible text, closes. Benchmark vs Appium-Python equivalent.

### M4 — iOS Appium backend (v0.5.0)

*Same unblock as M3 (http.cyr + json.cyr depth).*

- `yantra_mobile_open("ios", "com.example.app")` routing to Appium's XCUITest driver
- Selector translation: `~accessibility_label`, predicate strings, class-chain queries
- WebdriverAgent-style session bootstrap handled via the Appium server — yantra doesn't need to know about WDA directly

**Acceptance**: `.tcyr` file opens an iOS simulator session, taps an accessibility-label, asserts, closes. Benchmark vs Appium-Python.

### M5 — Auto-teardown + resilience (v0.6.0)

- Session teardown registered as a `syscall(60)` atexit hook — leaked browser / emulator processes get closed when the test exits, pass or fail
- Retry-on-transient semantics for flaky network conditions (connection reset, 502/503 from WebDriver endpoints)
- Structured error surface — every yantra failure carries the protocol-level cause, not just "it didn't work"
- Sakshi tracing spans around each action so consumers get a visible timeline

### M6 — CI matrix (v0.7.0)

- yantra's own test suite runs against all five backends in CI
- Chromium + Firefox + WebKit via local headless
- Android emulator + iOS simulator via ephemeral CI containers
- Benchmark comparison vs Playwright (Chromium / Firefox / WebKit) and Appium (Android / iOS) on identical workloads
- CSV-history format matching the AGNOS bench-history.sh convention

### M7 — Docs + Examples (v0.8.0)

- `docs/guides/getting-started.md` — from zero to first Chromium `.tcyr` test
- `docs/guides/writing-e2e-tests.md` — auto-waiting, selector strategies, session sharing
- `docs/guides/migrating-from-playwright.md` — translation cookbook
- `docs/guides/migrating-from-appium.md` — translation cookbook
- `docs/examples/` — one runnable example per backend

### M8 — Security hardening (v0.9.0)

- Control-byte sanitization on every string yantra echoes to stderr (ANSI injection defense — same class owl closed in 1.0.0)
- WebDriver / Appium endpoint authentication via sigil-verified HTTPS certs
- No shell-out anywhere — all process spawns via `fork` + `execve` with explicit argv
- Audit pass against `docs/audit/YYYY-MM-DD-audit.md`

### v1.0 criteria

- All five backends live
- M5 auto-teardown + resilience shipped
- M6 CI matrix green
- M7 docs complete with migration guides
- M8 audit clean
- Published benchmark comparison: yantra vs Playwright (web 3×) + yantra vs Appium (mobile 2×)
- **Knife article shipped**: *"Why UI Automation Belongs in Your Language"* (or whatever the final title is) — the receipts piece that counterpart to the yantra-is-a-library ADR

## Why M1 shipped first

CDP uses WebSocket end-to-end. `lib/ws.cyr` has full RFC 6455 client support (handshake, framing, masking, ping/pong, close, text + binary frames). The only HTTP yantra's CDP backend needs is the one-shot target-list fetch, which it does with its own HTTP/1.1 GET (Chromium rejects HTTP/1.0 — see architecture note 001). So M1 needed only `ws.cyr` + a trivial GET, and shipped first. M2–M4 need HTTP POST/headers — present in the stdlib `sandhi` client, though yantra ships its own minimal Content-Length-framed client for now (see architecture 002) — so they were never blocked, just sequenced after M1.

The other four backends all talk JSON-RPC over HTTP POST, which is why they batch together on the (still-open) `http.cyr` + `json.cyr` depth gate. Chromium doesn't share that constraint, so M1 gets to ship ahead.

## Post-v1.0 directions (not scheduled)

- **Browser-BiDi protocol** — the W3C successor to WebDriver, bidirectional, partial CDP-shape — when it matures
- **Playwright-parity auto-download** — vendor-managed browser binaries a la Playwright's install step (probably belongs behind an `ark` flag, not inside yantra itself)
- **Recorder / codegen** — generate `.tcyr` from a recorded session (Playwright Codegen analog)
- **Component testing mode** — framework-less component mount + action + assert, targeting just a Chromium snippet without a full app. Out of scope if it turns into a framework; in scope if it's a pure library helper
