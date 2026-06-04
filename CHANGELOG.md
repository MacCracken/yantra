# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.6.2] - 2026-06-04

> **M6 — CI device matrix + parity-benchmark harnesses.** yantra's own e2e suite
> now runs against all five backends in CI, and the mobile parity harness lands
> alongside the existing web one.

### Added
- **CI e2e jobs for every backend** (`.github/workflows/ci.yml`), all on
  push/PR:
  - **Firefox** via geckodriver (`tests/e2e/firefox-smoke.tcyr`) — headless
    through yantra's `-headless` cap, no display needed.
  - **WebKit** via WebKitWebDriver / WebKitGTK (`tests/e2e/webkit-smoke.tcyr`),
    run under Xvfb (`webkit2gtk-driver` has no headless cap).
  - **Android** via `reactivecircus/android-emulator-runner` (api-34 /
    google_apis / x86_64, KVM) + Appium/UiAutomator2.
  - **iOS** via `macos-latest` + a runner-matched simulator (the job picks the
    available device/iOS and runs a device-matched copy of the e2e) +
    Appium/XCUITest.
- **`scripts/parity-appium.py`** — the Appium-Python side of the **mobile**
  parity benchmark (open → page source → find → tap), mirroring
  `scripts/parity-playwright.mjs` for web. Reference harness; not run in CI.
- **Benchmark-history CI job** — runs `scripts/bench-history.sh` and uploads
  `bench-history.csv` (normalized ns, AGNOS one-row-per-bench convention) as a
  build artifact.

### Changed
- **`setup-cyrius` action is now OS/arch-aware** — resolves the release triple
  from `uname` (x86_64-linux on ubuntu, aarch64-macos on the macOS runner) and
  keys the toolchain cache on it, so the same action serves the web/Android
  (Linux) and iOS (macOS) jobs.

## [0.6.1] - 2026-06-04

> **M3 — Android Appium backend now LIVE.** The Android/UiAutomator2 path,
> implemented in 0.4.0, is verified end-to-end against a real emulator.

### Added
- `appium:skipDeviceInitialization` + `appium:disableWindowAnimation` to the
  Android session caps. The first bypasses Appium's `io.appium.settings` helper
  app, which fails to register on common emulator system images
  (`Package io.appium.settings unavailable`, `START … result code=-92`) and
  aborts session creation. The UiAutomator2 server that drives
  find/click/source is a separate install and is unaffected, so skipping the
  settings helper makes the session reliable without losing the verbs yantra
  uses. See `docs/architecture/003-android-skip-device-initialization.md`.

### Verified
- **Android e2e 4/4** (`tests/e2e/android-appium-smoke.tcyr`) against a live
  Android-34 / google_apis x86_64 emulator (Appium 3.x + uiautomator2, KVM,
  cyrius 6.0.59): open `com.android.settings` → page source (UiAutomator2 XML)
  → tap first clickable element → close. **All five backends are now live.**

## [0.6.0] - 2026-06-04

> **M5 — auto-teardown + resilience.** Sessions auto-tear-down on exit, failures
> carry a structured cause, transient connects retry, and actions can emit
> tracing spans. New `src/runtime.cyr` carries the surface; all backends + verbs
> are instrumented.

### Added
- **Auto-teardown.** yantra tracks open sessions in a registry;
  `yantra_teardown_all()` closes every open browser/emulator, and
  **`yantra_exit(code)`** (use in place of `syscall(60, code)`) tears down then
  exits — so leaked sessions get closed pass *or* fail. `yantra_open_session_count()`
  reports the live count. (No stdlib atexit hook exists, hence the explicit
  `yantra_exit`.)
- **Structured error surface.** `yantra_last_error()` (code) +
  `yantra_last_error_str()` (message). Codes: `YANTRA_ERR_NULL` / `_BROWSER` /
  `_CONNECT` / `_SESSION` / `_NAV` / `_NO_ELEMENT` / `_ACTION`. Every verb sets
  them on failure instead of returning a bare 0.
- **Retry-on-transient.** The open path retries connect failures with linear
  backoff (driver still starting, connection reset); `yantra_set_open_retry(attempts, backoff_ms)`
  (default 4 × 150ms).
- **Tracing spans.** `yantra_trace_enable(1)` wraps each action in a sakshi span
  for a visible timeline (off by default).
- `tests/m5.tcyr` — offline resilience suite (**14/14**, CI-safe).

### Changed
- New `src/runtime.cyr` module (after `main` in the `[lib]` order); the shared
  auto-wait sleep moved there. `sakshi` added to `[deps] stdlib`.
- **Pin stays 6.0.59** (not 6.0.60): 6.0.60 has no aarch64-macOS build, and
  yantra is verified on Linux *and* macOS — 6.0.59 is the cross-platform floor
  (it carries the macOS net port + sandhi 1.4.1).

### Verified
- M5 offline **14/14**; web e2e regression **CDP 11/11 + WebDriver 9/9** (Linux);
  **iOS 4/4** with M5 instrumentation (macOS, live). No happy-path regressions.

## [0.5.0] - 2026-06-04

> **M4 — iOS Appium/XCUITest backend is live.** Toolchain → Cyrius 6.0.59,
> which ports the stdlib socket layer to Darwin — unblocking all yantra
> networking on macOS (the 0.4.1 known-issue). All five planned backends are now
> implemented; web (CDP/WebDriver) and iOS are verified live.

### Added
- **M4 — iOS backend, live-verified.** `yantra_mobile_open("ios", "<bundleId>")`
  drives a real iOS Simulator over Appium/XCUITest. `tests/e2e/ios-appium-smoke.tcyr`
  passes **4/4** against an iOS 26.5 simulator (Appium 3.5 + xcuitest 11.9):
  open Settings → page source → **tap a native cell (xpath → find + click)** →
  close. Meets the roadmap M4 acceptance. Runs via the shared `sandhi_wd_*` /
  `sandhi_ap_*` RPC layer — same path as M2/M3.

### Changed
- **Toolchain pin → 6.0.59** (was 6.0.57). 6.0.59 ports `lib/net.cyr` to Darwin
  (BSD socket syscalls translated by the Mach-O backend; BSD `sockaddr_in` /
  `SO_*` / `O_NONBLOCK` / `EINPROGRESS` constants `#ifdef CYRIUS_TARGET_MACOS`).
  **Resolves** the 0.4.1 known-issue — yantra networking (CDP/WebDriver/Appium)
  now works on macOS arm64. Verified: a raw `tcp_socket()`+`connect` on Darwin
  now succeeds (was a garbage fd + EBADF). Filed/closed:
  `cyrius/docs/development/issues/2026-06-04-macos-net-socket-syscalls-unported.md`.

### Status
- **Backends**: M1 Chromium/CDP (live), M2 Firefox/WebKit/Chrome/Safari WebDriver
  (live), M3 Android Appium (implemented; live run pending an emulator), M4 iOS
  Appium/XCUITest (**live**). yantra builds + runs on Linux x86_64 and macOS arm64.

## [0.4.1] - 2026-06-04

> Adds a Safari (safaridriver) web target and iOS simulator targeting, lands the
> M4 iOS scaffold, and records first cross-platform (macOS arm64) validation.
> M4 iOS-live is deferred on an upstream cyrius stdlib fix (see Known issues).

### Added
- **`yantra_web_open("safari")`** — Apple's built-in `safaridriver`
  (`browserName: "safari"`, default port 4445), distinct from Playwright's
  `"webkit"`. Routes through the same WebDriver path.
- **iOS simulator targeting** — `yantra_mobile_set_ios_device(name, version)`
  sets `appium:deviceName` / `appium:platformVersion` for XCUITest sessions.
- **`tests/e2e/ios-appium-smoke.tcyr`** — M4 iOS acceptance scaffold
  (open Settings → source → close). Compile+link verified.

### Notes
- **First cross-platform validation**: yantra builds and runs on **macOS arm64**
  — smoke build, unit suite (2/2), lint (0 warnings), and `distlib` all green on
  Apple Silicon with the `sandhi 1.4.1` lib. The full iOS toolchain (Xcode 26.5,
  iOS 26.5 sim, Appium 3.5 + xcuitest 11.9) was stood up and the iOS session was
  verified end-to-end via `curl` with yantra's exact capabilities (XCUITest
  session created, WebDriverAgent launched).

### Known issues
- **M4 iOS-live blocked on a cyrius stdlib bug** — `lib/net.cyr` hardcodes Linux
  socket syscall numbers (`SYS_SOCKET=41`/`SYS_CONNECT=42`), so on Darwin
  `tcp_socket()` returns a garbage fd and `connect` fails (EBADF). This breaks
  *all* yantra networking on macOS (CDP/WebDriver/Appium). yantra and sandhi are
  correct; the gap is below them. Filed:
  `cyrius/docs/development/issues/2026-06-04-macos-net-socket-syscalls-unported.md`.
  yantra's iOS path is verified correct up to the socket boundary; the live run
  resumes once net.cyr is ported to Darwin.

## [0.4.0] - 2026-06-03

> Migrates the M2 WebDriver backend onto the stdlib `sandhi` RPC layer and
> adds the **M3 Android Appium backend**. Toolchain → Cyrius 6.0.57.

### Changed
- **Toolchain pin → 6.0.57** (was 6.0.55); `cyrius lib sync`'d (sandhi 1.4.1
  now in the snapshot, with the `Connection: close` framing fix).
- **M2 WebDriver migrated onto `sandhi_wd_*`.** `src/protocol/webdriver.cyr` is
  now a thin adapter over sandhi's WebDriver RPC dialect
  (`sandhi_wd_new_session` / `navigate_to` / `find_element` / `element_click` /
  `element_send_keys` / `execute_script` / `delete_session`) instead of yantra's
  hand-rolled Content-Length-framed HTTP client. sandhi 1.4.1 fixed the
  close-path drain that originally forced the in-tree client (architecture 002).
  sandhi now owns the HTTP transport, TLS, retries, and pooling. E2E still
  **9/9** against chromedriver; M1 CDP unaffected (**11/11**).
- `web.cyr` selector translation unified + made kind-aware (`_web_sel_using` /
  `_web_sel_value`): `@id/…` → id, `~…` → accessibility id, `text:…` →
  uiautomator (mobile) / xpath (web), `/…` → xpath, else css (web) / id (mobile).
  So `yantra_type` / `yantra_close` / `yantra_eval_*` work on mobile sessions too.

### Added
- **M3 — Android Appium backend.** `src/mobile.cyr`:
  `yantra_mobile_open("android", "<pkg>")` (UiAutomator2; `"ios"` → XCUITest for
  M4) opens an Appium session via `sandhi_wd_new_session` with proper W3C caps,
  then `yantra_tap` / `yantra_tap_now` / `yantra_type` / `yantra_close` /
  `yantra_mobile_source` drive it over sandhi's WebDriver/Appium RPC. Mobile
  sessions are WebDriver-transport sessions, so the web verbs apply directly.
  - `yantra_mobile_set_port` (default Appium 4723).
  - `tests/e2e/android-appium-smoke.tcyr` — M3 acceptance scaffold
    (open → tap → type → tap → source → close). Compile-checked; live run needs
    an Android emulator + Appium server (M6 device matrix), so it's held out of
    CI like the other live-device work.
- `dist/yantra.cyr` now bundles `main → cdp → webdriver → web → mobile`;
  `sandhi`/`tls`/`dynlib`/`fdlopen`/`mmap` added to `[deps] stdlib`.

## [0.3.0] - 2026-06-03

> Adds the **M2 WebDriver backend** (Firefox / WebKit / Chrome via W3C
> WebDriver), corrects the transport-layer story, and bumps the toolchain to
> Cyrius 6.0.55.

### Added
- **M2 — WebDriver backend.** `src/protocol/webdriver.cyr` implements the W3C
  WebDriver JSON wire protocol (new session → navigate → find element → click /
  clear / send keys → execute script → delete session). `yantra_web_open` now
  routes `"firefox"`/`"webkit"` (geckodriver/webkitwebdriver, port 4444) and
  `"chrome"` (chromedriver, port 9515) to it; `yantra_web_set_wd_port` overrides.
  - `src/web.cyr` refactored to a **transport-aware** session (CDP vs
    WebDriver): CDP drives the page via `Runtime.evaluate`, WebDriver via native
    element finding (css selector / xpath) — shared auto-waiting either way.
    Session struct extended to 32 bytes with a transport tag.
  - `tests/e2e/webdriver-smoke.tcyr` — **9/9 passing** against live chromedriver
    (open → navigate → url → type → click → eval → close). The wire protocol is
    identical for geckodriver/webkitwebdriver.
- New session-level verbs `yantra_eval_str` / `yantra_eval_bool` (page.evaluate
  analog), transport-agnostic.

### Changed
- **Toolchain pin → 6.0.55** (was 6.0.53; the wrapper had drifted ahead).
- **Corrected the transport-layer story.** Earlier docs claimed M2–M4 were
  blocked because `lib/http.cyr` is GET-only. That was wrong — it overlooked
  `lib/sandhi.cyr`, the stdlib's full HTTP/1.1+2 client. M2–M4 are not blocked.
- **WebDriver uses yantra's own minimal Content-Length-framed HTTP client**
  (over `net.cyr`), not `sandhi`. `sandhi`'s `Connection: close` read path drains
  until EOF, which hangs against chromium-family servers (chromedriver, Chromium
  DevTools) that don't promptly close. Filed as a sandhi-side bug
  (`sandhi/docs/issues/2026-06-03-http-close-path-drains-until-eof.md`); yantra
  will adopt `sandhi` for the WebDriver/Appium transport once it frames by
  Content-Length. See `docs/architecture/002`.

## [0.2.1] - 2026-06-03

> First release on the Cyrius 6.0.53 toolchain. Ships the modernized
> build/CI/release pipeline, the benchmark system, and the **M1 Chromium/CDP
> backend** — yantra's first live browser-automation backend.

### Changed
- **Toolchain bumped 5.6.17 → 6.0.53** (`cyrius.cyml [package].cyrius`).
  The stale 5.6.17 vendored snapshot was shadowing the pinned one and
  triggering drift warnings.
- **`lib/` is no longer tracked in git.** The vendored stdlib snapshot is
  gitignored and materialized on demand with `cyrius lib sync` (CI runs it
  right after toolchain setup; fresh clones run it once — see CONTRIBUTING.md).
  This removes a ~90-file vendored blob from version control and guarantees
  `lib/` always matches the pin. Replaced two stale dep symlinks
  (`sakshi` → 2.1.0, `sigil` → 2.9.1) in the process.
- Added `thread_local` to `[deps] stdlib` (sigil 3.6.0 now requires
  `thread` + `thread_local` before it).
- **CI/release modernized**: new `setup-cyrius` composite action (caches the
  toolchain, reads the pin from `cyrius.cyml`) shared by both workflows;
  CI now runs lint → fmt-check → smoke build → test → bench → `distlib` and
  uploads `dist/yantra.cyr`; the broken steps (`cyrius test src/test.cyr`,
  building the library as a binary) are fixed. Release now ships the real
  deliverable `dist/yantra.cyr` plus the smoke binary and `SHA256SUMS`, and
  the reusable-workflow gate (`workflow_call`) is declared.

### Added
- **M1 — Chromium CDP backend (first live backend).**
  - `src/protocol/cdp.cyr` — Chrome DevTools Protocol over `lib/ws.cyr`:
    target discovery, command build + escaping, response matching by id,
    `cdp_eval` / `cdp_navigate` / `cdp_connect` / `cdp_close`. Issues its own
    HTTP/1.1 `GET /json` for discovery because Chromium's DevTools HTTP server
    rejects HTTP/1.0 (what stdlib `http_get` sends); a recv timeout backstops
    the WebSocket read loop.
  - `src/web.cyr` — public API: `yantra_web_open("chromium")`,
    `yantra_navigate`, `yantra_click`, `yantra_click_now`, `yantra_type`,
    `yantra_url`, `yantra_eval_str`, `yantra_eval_bool`, `yantra_close`, with
    Playwright-style auto-waiting (poll for element-actionable / readyState).
  - `tests/e2e/chromium-smoke.tcyr` — full round trip, **11/11 passing**
    against live headless Chromium; gated in the CI `E2E (Chromium / CDP)` job.
  - Bundled into `dist/yantra.cyr` via the `main → cdp → web` `[lib]` order;
    `net`/`ws`/`base64`/`json` added to `[deps] stdlib`.
  - **Performance**: set `TCP_NODELAY` on the CDP socket — each command round
    trip was pinned near ~40ms by Nagle + delayed-ACK; now ~0.3ms. Tightened
    the auto-wait poll to 5ms (navigate ~43ms → ~19ms).
  - **Parity benchmark**: `programs/benchmarks.cyr` times real CDP operations
    against live Chromium; `scripts/parity-playwright.mjs` is the reproducible
    Playwright side. Result (same workload): yantra ~3× faster on the
    navigate+click+assert flow (~21ms vs ~67ms), ~2–5× on eval/type, parity on
    navigate. Numbers + caveats in `docs/development/state.md`.
- **Benchmark system** (AGNOS convention): real `tests/yantra.bcyr`
  micro-benchmark harness; `programs/benchmarks.cyr` incumbent-parity
  program (vs Playwright/Appium) scaffold; `scripts/bench-history.sh` →
  `bench-history.csv` (normalized-ns history); CI bench step.
- **Example + E2E scaffolding** (modeled on mabda 3.0.1): minimal
  `examples/web-consumer/login.tcyr` "hello browser" reference,
  `docs/examples/README.md` index, and `tests/e2e/chromium-smoke.tcyr`
  (the M1 acceptance test — green against live headless Chromium).
- **Governance docs**: `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`
  (first-party-standards root set).

### Fixed
- Documentation accuracy: `state.md`, `roadmap.md`, and the `CLAUDE.md`
  Quick Start updated to the verified 6.0.53 reality (toolchain, bundled lib
  versions, native TLS `tls_native.cyr` being a v6.0.10 scaffold). _(A
  transport-blocked claim made here was corrected in the next cycle — see
  Unreleased; `sandhi` provides the full HTTP stack.)_

## [0.1.0]

### Added
- Initial project scaffold
