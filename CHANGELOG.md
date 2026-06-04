# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
