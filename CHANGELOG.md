# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
