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

✅ **Done** (shipped 0.3.0; **migrated onto `sandhi_wd_*` in 0.4.0**).
`src/protocol/webdriver.cyr` is now a thin adapter over sandhi's WebDriver RPC
dialect — sandhi 1.4.1 fixed the close-path drain that had forced a temporary
in-tree client (architecture 002, resolved). Transport-aware `src/web.cyr`.
`yantra_web_open("firefox"/"webkit")` → geckodriver/webkitwebdriver (4444);
`"chrome"` → chromedriver (9515). Shared session semantics + auto-waiting with
the CDP path. E2E **9/9** against live chromedriver
(`tests/e2e/webdriver-smoke.tcyr`); identical wire for the Firefox/WebKit
drivers. Selector translation unified + kind-aware (`@id/`, `~`, `text:`, `/`,
css/id default).

*Original scope:*

- `src/protocol/webdriver.cyr` — W3C WebDriver JSON wire protocol
- `yantra_web_open("firefox")` + `yantra_web_open("webkit")` routing
- Selector translation: WebDriver's `css selector` / `xpath` / `link text` strategies
- Shared session semantics with CDP — same `yantra_web_open` API, same auto-waiting, same `yantra_close` teardown

**Acceptance**: the M1 smoke test file runs unchanged except for the opener call against Firefox headless and WebKit headless. Numbers into `state.md`.

### M3 — Android Appium backend (implemented v0.4.0, **LIVE** 2026-06-04)

✅ **LIVE.** `src/mobile.cyr` rides the
stdlib `sandhi` WebDriver/Appium RPC (`sandhi_wd_*` + `sandhi_ap_*`). A mobile
session is a WebDriver-transport session, so the web verbs (`yantra_type` /
`yantra_close` / `yantra_eval_*`) work directly; M3 adds the Appium opener and
`yantra_tap`/`yantra_tap_now`/`yantra_mobile_source`.

`tests/e2e/android-appium-smoke.tcyr` passes **4/4** against a live
android-34 / google_apis x86_64 emulator (Appium 3.x + uiautomator2, KVM,
cyrius 6.0.59): open `com.android.settings` → page source → tap first clickable
element → close. Android caps set `appium:skipDeviceInitialization` to bypass
the `io.appium.settings` helper, which fails to register on stock emulator
images (architecture [003](../architecture/003-android-skip-device-initialization.md)).

- `src/mobile.cyr` — `yantra_mobile_open("android", "<pkg>")` (UiAutomator2),
  `yantra_tap`, `yantra_tap_now`, `yantra_mobile_source`; `yantra_mobile_set_port`
  (default Appium 4723). Caps built directly (platformName / appium:automationName
  / appium:appPackage) and opened via `sandhi_wd_new_session`.
- Selector translation (shared with web, kind-aware): `@id/<rid>` → id,
  `~<label>` → accessibility id, `text:<t>` → `-android uiautomator`,
  `/<xpath>` → xpath, else → id.
- `tests/e2e/android-appium-smoke.tcyr` — acceptance scaffold; compile+link
  verified.

**Acceptance** (met): `.tcyr` opens an Android emulator session, reads the
UiAutomator2 hierarchy, taps a native widget, closes — 4/4. Benchmark vs
Appium-Python — TODO (M6).

### M4 — iOS Appium backend (shipped v0.5.0, 2026-06-04)

✅ **LIVE.** `yantra_mobile_open("ios", "<bundleId>")` drives a real iOS
Simulator over Appium/XCUITest (via the shared `sandhi_wd_*`/`sandhi_ap_*` RPC
layer + `src/mobile.cyr`). `tests/e2e/ios-appium-smoke.tcyr` passes **4/4**
against an iOS 26.5 simulator (Appium 3.5 + xcuitest 11.9, cyrius 6.0.59 on the
`ecb` Mac): open Settings → page source → tap a native cell (xpath) → close.
Selector translation: `~accessibility-id`, `@id/`, `text:`, `/xpath`. WDA
bootstrap is handled by Appium — yantra doesn't touch WDA directly.

> Unblocked by cyrius **6.0.59**'s `net.cyr` Darwin socket port (the 0.4.1
> macOS-networking blocker; cyrius issue `2026-06-04-macos-net-socket-syscalls-unported.md`).

**Acceptance** (met): `.tcyr` opens an iOS simulator session, taps, asserts,
closes. Benchmark vs Appium-Python — TODO (M6).

### M5 — Auto-teardown + resilience (shipped v0.6.0, 2026-06-04)

✅ **Done.** Surface in `src/runtime.cyr`, all backends/verbs instrumented.
Offline suite `tests/m5.tcyr` 14/14; verified across web (CDP/WebDriver) + iOS.

- **Auto-teardown**: session registry + `yantra_teardown_all()` and
  `yantra_exit(code)` (the stdlib has no atexit hook, so consumers call
  `yantra_exit` in place of `syscall(60, code)` — leaked browsers/emulators
  close pass or fail). `yantra_open_session_count()` reports the live count.
- **Retry-on-transient**: bounded linear-backoff retry on the open/connect path
  (`yantra_set_open_retry(attempts, backoff_ms)`, default 4 × 150ms).
- **Structured error surface**: `yantra_last_error()` + `yantra_last_error_str()`
  with codes `NULL`/`BROWSER`/`CONNECT`/`SESSION`/`NAV`/`NO_ELEMENT`/`ACTION`.
- **Tracing**: `yantra_trace_enable(1)` wraps each action in a sakshi span.

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
