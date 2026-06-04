# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed
- **Toolchain bumped 5.6.17 → 6.0.53** (`cyrius.cyml [package].cyrius`).
  Re-synced the vendored `lib/` to the 6.0.53 stdlib snapshot via
  `cyrius lib sync` (the stale 5.6.17 snapshot was shadowing the pinned one
  and triggering drift warnings). Replaced two stale dep symlinks
  (`sakshi` → 2.1.0, `sigil` → 2.9.1) with the snapshot files (2.2.6 / 3.6.0).
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
