# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased] — 0.2.0 dev cycle (ships with the M1/M2 backends)

> 0.1.0 is released; this modernization opens the 0.2.0 cycle and lands
> alongside the M1 (Chromium/CDP) and M2 (Firefox/WebKit WebDriver) work.
> `VERSION` is now `0.2.0`.

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
- **Benchmark system** (AGNOS convention): real `tests/yantra.bcyr`
  micro-benchmark harness; `programs/benchmarks.cyr` incumbent-parity
  program (vs Playwright/Appium) scaffold; `scripts/bench-history.sh` →
  `bench-history.csv` (normalized-ns history); CI bench step.
- **Example + E2E scaffolding** (modeled on mabda 3.0.1): minimal
  `examples/web-consumer/login.tcyr` "hello browser" reference,
  `docs/examples/README.md` index, and `tests/e2e/chromium-smoke.tcyr`
  (the M1 acceptance test, held out until the CDP backend lands).
- **Governance docs**: `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`
  (first-party-standards root set).

### Fixed
- Documentation accuracy: `state.md`, `roadmap.md`, and the `CLAUDE.md`
  Quick Start corrected to the verified 6.0.53 reality — `lib/http.cyr` is
  **still GET-only** (`http_get_r` added v5.8.31), `lib/json.cyr` still thin,
  and native TLS (`lib/tls_native.cyr`) is a v6.0.10 scaffold, so M2–M4 remain
  blocked on an open `http.cyr` gap (the v5.7.x unblock never materialized).

## [0.1.0]

### Added
- Initial project scaffold
