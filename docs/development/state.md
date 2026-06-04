# yantra — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile). Add release-hook wiring
> when the repo's release workflow lands.

## Version

**0.6.2** — 2026-06-04. **M6 — CI device matrix + parity harnesses.** yantra's
e2e suite now runs against all five backends on every push/PR: Chromium (CDP) +
chromedriver, **Firefox** (geckodriver), **WebKit** (WebKitWebDriver under Xvfb),
**Android** (`android-emulator-runner`, api-34/google_apis/x86_64 + Appium), and
**iOS** (`macos-latest` + a runner-matched simulator + Appium). `setup-cyrius` is
now installed via the canonical OS-aware `scripts/install.sh` (serves both the
Linux and macOS runners). New `scripts/parity-appium.py` (mobile parity, mirrors
the web `parity-playwright.mjs`); bench-history CSV uploaded as a CI artifact.
New e2e: `tests/e2e/firefox-smoke.tcyr`, `webkit-smoke.tcyr`. **Pin → 6.0.62**
(cross-platform floor), which fixes the cyrius macOS installer bug that left
`versions/<v>/lib` unpopulated (broke `cyrius lib sync` on the iOS runner);
`setup-cyrius` keeps a snapshot backfill as a runner-safety net until that CI
confirms. WebKit caps fix: omit `browserName` so WebKitGTK's driver accepts the
session (WebKit CI job stays non-blocking until confirmed green — architecture
004).

**0.6.1** — 2026-06-04. **M3 — Android Appium backend now LIVE.**
`tests/e2e/android-appium-smoke.tcyr` passes **4/4** against a live android-34 /
google_apis x86_64 emulator (Appium 3.x + uiautomator2, KVM): open
`com.android.settings` → page source → tap first clickable → close. Fix: Android
caps set `appium:skipDeviceInitialization` to bypass the `io.appium.settings`
helper, which fails to register on stock emulator images (architecture
[003](../architecture/003-android-skip-device-initialization.md)). **All five
backends are now live** (web 4 + mobile 2). No code change beyond the two added
Android caps; the e2e was already correct.

**0.6.0** — 2026-06-04. **M5 — auto-teardown + resilience.** Session registry +
`yantra_teardown_all()` / `yantra_exit(code)` (leaked browsers/emulators closed
on exit); structured errors (`yantra_last_error()` / `_str()` + codes);
retry-on-transient open (`yantra_set_open_retry`); sakshi tracing spans
(`yantra_trace_enable`). New `src/runtime.cyr`. Verified: M5 offline 14/14, web
11/11 + 9/9, iOS 4/4. Pin held at **6.0.59** (6.0.60 is Linux-only; 6.0.59 is the
cross-platform floor).

**0.5.0** — 2026-06-04. **M4 — iOS Appium/XCUITest backend is LIVE.**
`yantra_mobile_open("ios", …)` drives a real iOS 26.5 simulator over Appium;
`tests/e2e/ios-appium-smoke.tcyr` passes **4/4** (open → source → tap native cell
→ close). Toolchain pin → **6.0.59**, which ports `lib/net.cyr` to Darwin —
**resolving** the 0.4.1 macOS-networking blocker (all yantra networking now works
on macOS arm64). All five planned backends implemented; web + iOS verified live.

**0.4.1** — 2026-06-04. Adds a **Safari** web target (`yantra_web_open("safari")`,
Apple safaridriver), **iOS simulator targeting** (`yantra_mobile_set_ios_device`),
and the **M4 iOS scaffold**. First cross-platform build validation on macOS arm64.
(M4-live was blocked on a cyrius `net.cyr` Darwin-socket bug — resolved in 0.5.0.)

**0.4.0** — 2026-06-03. Migrates **M2 WebDriver onto the stdlib `sandhi` RPC
layer** (`sandhi_wd_*`; sandhi 1.4.1's close-path fix landed) and adds the **M3
Android Appium backend** (`src/mobile.cyr`, on `sandhi_wd_*`/`sandhi_ap_*`).
Toolchain pin → 6.0.57.

**0.3.0** — 2026-06-03. Adds the **M2 WebDriver backend** (Firefox / WebKit /
Chrome via W3C WebDriver) on top of M1 (Chromium/CDP). Toolchain pin → 6.0.55.

**0.2.1** — 2026-06-03. First release on the Cyrius 6.0.x toolchain: modernized
build/CI/release pipeline, benchmark system, and the **M1 Chromium/CDP backend**
(yantra's first live browser-automation backend).

**0.1.0** — scaffolded 2026-04-23 via `cyrius init yantra` (released). Module
skeletons + session / selector / action primitives. Browser and mobile
backends stubbed pending transport-layer depth.

## Toolchain

- **Cyrius pin**: `6.0.62` (in `cyrius.cyml [package].cyrius`) — carries the
  6.0.59 Darwin `net.cyr` port; ships all platforms (x86_64/aarch64 ×
  linux/macos + windows), so it stays the cross-platform floor. Vendored `lib/`
  is gitignored and materialized with `cyrius lib sync`. 6.0.62 **fixes** the
  macOS installer bug (`versions/<v>/lib` left empty by the whole-dir `cp -r`;
  now uses the contents form + fail-loud assert) — verified locally, pending
  `macos-15-arm64` runner confirmation. `setup-cyrius` retains a snapshot
  backfill as a runner-safety net until then (cyrius issue
  `2026-06-04-macos-install-lib-snapshot-missing-breaks-lib-sync`).
- **Bundled sandhi**: 1.4.1 (includes the `Connection: close` Content-Length
  framing fix that yantra's M2 WebDriver backend depends on).
- **sigil 3.6.0 requires** `thread.cyr` + `thread_local.cyr` included before
  it. Both are listed in `cyrius.cyml [deps] stdlib`. yantra does not include
  sigil yet (it enters at M8, cert verification) — this is a forward-looking
  constraint, not a current one.

## Supported backends

| Platform | Protocol | Status |
|----------|----------|--------|
| Chromium (headless + headed) | Chrome DevTools Protocol (WebSocket) | **LIVE (M1)** — open/navigate/click/type/url/eval/close, auto-waiting; e2e green against headless Chromium |
| Firefox | W3C WebDriver (HTTP + JSON) | **LIVE (M2)** — `yantra_web_open("firefox")` via geckodriver |
| WebKit (WebKitGTK) | W3C WebDriver | **LIVE (M2)** — `yantra_web_open("webkit")`, same WebDriver wire as Firefox |
| Safari (macOS) | W3C WebDriver (safaridriver) | **routed** — `yantra_web_open("safari")`; macOS net now works (0.5.0), runnable with `sudo safaridriver --enable` |
| Chrome | W3C WebDriver (chromedriver) | **LIVE (M2)** — e2e green (9/9) against chromedriver |
| Android (native apps) | Appium → UiAutomator2 (on `sandhi_wd_*`/`sandhi_ap_*`) | **LIVE (M3)** — `yantra_mobile_open("android",…)`/`tap`/`type`/`close`; e2e 4/4 against an android-34 x86_64 emulator |
| iOS (native apps) | Appium → XCUITest (on `sandhi_wd_*`/`sandhi_ap_*`) | **LIVE (M4)** — `yantra_mobile_open("ios",…)`/`tap`/`type`/`close`; e2e 4/4 against iOS 26.5 simulator |

> **HTTP-transport note (updated 0.4.1)**: the **M2 WebDriver and M3 Appium**
> backends ride the stdlib **`sandhi`** RPC layer (`sandhi_wd_*` / `sandhi_ap_*`)
> — sandhi 1.4.1 fixed the close-path drain that had forced a temporary in-tree
> client ([architecture 002](../architecture/002-webdriver-uses-own-http-client.md),
> resolved). The **M1 CDP** backend keeps its own one-shot discovery GET
> ([architecture 001](../architecture/001-chromium-devtools-requires-http11.md));
> CDP commands ride `ws.cyr`.
>
> **macOS networking (resolved 0.5.0)**: the 0.4.1 blocker — cyrius `lib/net.cyr`
> using Linux socket syscall numbers on Darwin — is fixed in **6.0.59** (Darwin
> socket port). yantra networking now works on macOS arm64; the M4 iOS e2e runs
> live (4/4). cyrius issue
> `2026-06-04-macos-net-socket-syscalls-unported.md` resolved.

## Transport layer (corrected 2026-06-03)

An earlier revision of this section wrongly claimed M2–M4 were blocked on
`http.cyr` being GET-only. That was a mistake: it looked only at the *minimal*
`lib/http.cyr` and missed `lib/sandhi.cyr`, the stdlib's full HTTP client.
**Nothing is transport-blocked.**

- **`lib/sandhi.cyr` (v1.3.4)** — the real HTTP client: a complete HTTP/1.1 +
  HTTP/2 stack. `sandhi_http_get/post/put/patch/delete/head(url, headers,
  body, len)`, full header management (`sandhi_headers_*`), **HTTPS/TLS**
  (`sandhi_conn_open(.., use_tls, sni_host)`, ALPN, TLS 1.3 0-RTT, session
  cache), redirects, per-phase timeouts, connection pooling, retry, streaming.
  Response via `sandhi_http_status/body/body_len/headers/err_kind`. This is
  what **M2 (WebDriver)** and **M3/M4 (Appium)** ride on — POST + `Content-Type:
  application/json` + HTTPS are all present today.
- **`lib/json.cyr`** — tagged value-tree (`json_v_parse`, `json_v_obj_get`,
  `json_v_arr_*`, `json_v_str/int/bool`): full nesting/arrays/typed values.
  Carries WebDriver/Appium request and response bodies cleanly.
- **`lib/ws.cyr`** — RFC 6455 client (text/binary/ping/pong/close). The M1
  Chromium/CDP transport. No gap.
- **`lib/http.cyr`** — the *minimal* GET-only client. Not used by yantra; the
  CDP backend rolls its own HTTP/1.1 discovery GET (see architecture note 001),
  everything else uses `sandhi`.
- **`lib/tls.cyr`** — HTTPS via the `libssl.so.3` `fdlopen` bridge (sandhi's
  TLS path; works today). **`lib/tls_native.cyr`** — pure-Cyrius TLS 1.3, still
  a **v6.0.10 scaffold** (returns `TLS_ERR_NOT_IMPLEMENTED`); the bridge remains
  the working transport. The native-TLS transition is a Cyrius-side concern.

Net: all five backends are live — M1 (Chromium/CDP), M2 (Firefox/WebKit/Chrome
WebDriver), M3 (Android Appium), M4 (iOS XCUITest).

## Source

- `src/main.cyr` — Session / Selector / Action primitives (`yantra_version`,
  session field accessors). **Live.**
- `src/runtime.cyr` — **M5 resilience surface**: structured errors
  (`yantra_last_error`/`_str`), session registry + auto-teardown, retry/backoff
  config, tracing-span helpers, shared sleep. **Live (M5).**
- `src/protocol/cdp.cyr` — Chrome DevTools Protocol over `ws.cyr`: discovery
  GET, command build/escape, response matching, eval/navigate/connect/close.
  **Live (M1).**
- `src/protocol/webdriver.cyr` — W3C WebDriver backend, a **thin adapter over
  `sandhi_wd_*`** (sandhi owns the HTTP transport). **Live (M2).**
- `src/web.cyr` — browser public API (`yantra_web_open` / `navigate` / `click` /
  `click_now` / `type` / `url` / `eval_str` / `eval_bool` / `close`),
  transport-aware (CDP vs WebDriver) with unified, kind-aware selector
  translation and Playwright-style auto-waiting. **Live.**
- `src/mobile.cyr` — mobile public API (`yantra_mobile_open` / `tap` /
  `tap_now` / `mobile_source`; `type`/`close`/`eval_*` inherited from web.cyr).
  Appium via `sandhi_wd_*`/`sandhi_ap_*`. **Live (M3 + M4); e2e 4/4 on both
  Android and iOS.**

The `[lib] modules` bundle order is `main → runtime → cdp → webdriver → web → mobile`;
these modules carry no `include`s (stdlib resolved by the consumer).
`programs/smoke.cyr` stitches the stdlib chain on for a local link-check.

## Tests & benchmarks

- `tests/yantra.tcyr` — unit suite (`cyrius test`). Smoke-level today (2 passing).
- `tests/yantra.bcyr` — micro-benchmark harness (`cyrius bench`), real now:
  measures the session-primitive decode paths (~5 ns each).
- `tests/yantra.fcyr` — fuzz harness (`cyrius fuzz`), stub.
- `tests/m5.tcyr` — M5 resilience suite (**14/14**): structured errors,
  null-guards, session registry + teardown, tracing toggle. Offline / CI-safe.
- `tests/e2e/chromium-smoke.tcyr` — M1 acceptance E2E. **Passing (11/11)**
  against live headless Chromium: open → navigate → url → type (value
  round-trips) → click (checkbox toggles) → click_now → close, all over CDP
  with auto-waiting. Runs in the CI `E2E (Chromium / CDP)` job.
- `tests/e2e/webdriver-smoke.tcyr` — M2 acceptance E2E. **Passing (9/9)**
  against live chromedriver via `yantra_web_open("chrome")`: open → navigate →
  url → type → click → eval → close over the W3C WebDriver wire. CI job
  `E2E (WebDriver / chromedriver)`.
- `tests/e2e/firefox-smoke.tcyr` / `webkit-smoke.tcyr` — M6 web e2e for the
  remaining WebDriver targets. Same flow as the chromedriver smoke via
  `yantra_web_open("firefox")` (geckodriver, headless cap) / `("webkit")`
  (WebKitWebDriver under Xvfb). CI jobs `E2E (Firefox …)` (gates) /
  `E2E (WebKit …)` (non-blocking — WebKitGTK driver mismatch, architecture 004).
- `tests/e2e/android-appium-smoke.tcyr` — M3 acceptance E2E. **Passing (4/4)**
  against a live android-34 / google_apis x86_64 emulator (Appium 3.x +
  uiautomator2): open `com.android.settings` → page source (UiAutomator2 XML) →
  tap first clickable element → close. CI job `E2E (Android …)` via
  `reactivecircus/android-emulator-runner` (KVM).
- `tests/e2e/ios-appium-smoke.tcyr` — M4 acceptance E2E. **4/4** vs an iOS 26.5
  simulator locally (open Settings → source → tap cell → close). CI job
  `E2E (iOS …)` on `macos-latest` runs a runner-matched copy (the committed file
  targets the maintainer's local sim).
- `programs/benchmarks.cyr` — incumbent-parity benchmark program (yantra vs
  Playwright/Appium). Scaffold + planned matrix; runs primitive benches today.
- `scripts/bench-history.sh` → `bench-history.csv` — AGNOS bench-history
  convention: one normalized (ns) row per benchmark per run, keyed by UTC
  timestamp + git short-sha. Run in CI; CSV uploaded as an artifact.
- `scripts/parity-playwright.mjs` (web) / `scripts/parity-appium.py` (mobile) —
  incumbent-parity harnesses. Run manually on a box with Playwright / Appium +
  a device; produce the incumbent column. Not in CI (need the incumbent).
- `examples/web-consumer/login.tcyr` + `docs/examples/` — minimal
  "hello browser" consumer reference (mabda `examples/stdlib-consumer` analog).

## Benchmarks — M1 parity (Chromium/CDP vs Playwright)

Measured 2026-06-03 on one box, headless Chromium 148, identical `data:` URL
workload. yantra: `programs/benchmarks.cyr`. Playwright (Node 26, system
Chromium): `scripts/parity-playwright.mjs`. Representative averages:

| Operation | yantra (CDP) | Playwright | Note |
|-----------|-------------:|-----------:|------|
| `navigate` (data URL) | ~19 ms | ~19 ms | parity — both bounded by Chromium's load |
| `eval` (querySelector) | ~0.3 ms | ~0.6 ms | yantra ~2× |
| `click` | ~0.3 ms | ~33 ms | **not apples-to-apples** — Playwright's click does full actionability (visibility/stability/scroll); yantra's is existence-wait + dispatch |
| `type` | ~0.6 ms | ~2.9 ms | yantra ~5× |
| **flow** (navigate+click+assert) | **~21 ms** | **~67 ms** | apples-to-apples; yantra ~3× (Playwright's heavyweight click dominates) |

Caveats / honesty: yantra's `click` waits only for element *existence*, not
full actionability (visible + stable + enabled) — that richer wait is future
work and is the main semantic gap behind the click number. Two fixes during
M1 closeout made these numbers real: **TCP_NODELAY** on the CDP socket (each
round trip was pinned at ~40ms by Nagle/delayed-ACK → ~0.3ms after), and a
**5ms auto-wait poll** interval (navigate was ~43ms on a 50ms poll → ~19ms).
The Playwright column is reproduced, never fabricated.

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

1. **M1 — Chromium CDP backend** (shipped v0.2.1). ✅ **DONE** — `src/protocol/cdp.cyr`
   + `src/web.cyr` live, `tests/e2e/chromium-smoke.tcyr` green against headless
   Chromium, bundled into `dist/yantra.cyr`, and Playwright parity benchmarked
   (see Benchmarks above — yantra ~3× on the flow). Full milestone closed.
2. **M2 — Firefox + WebKit WebDriver backends** (shipped v0.3.0; migrated onto
   `sandhi_wd_*` in v0.4.0). ✅ **DONE** — e2e 9/9 against chromedriver (same
   wire for geckodriver/webkitwebdriver); also routes `"chrome"`.
3. **M3 — Android Appium backend** (v0.4.0). ✅ **Implemented** — `src/mobile.cyr`
   on `sandhi_wd_*`/`sandhi_ap_*`; compile+link verified. **Live e2e pending an
   Android emulator + Appium server** (M6 device matrix).
4. **M4 — iOS Appium backend** (shipped v0.5.0). ✅ **LIVE** — `yantra_mobile_open("ios",…)`
   drives a real iOS 26.5 simulator over Appium/XCUITest; e2e 4/4
   (open → source → tap → close). Verified on `ecb` (arm64 macOS), cyrius 6.0.59.
5. **M5 — auto-teardown + resilience** (shipped v0.6.0). ✅ **DONE** — registry +
   `yantra_exit`/`teardown_all`, structured `yantra_last_error`, retry-on-transient,
   tracing spans (`src/runtime.cyr`). Offline 14/14; verified across web + iOS.
6. **M6 onward** — CI device matrix (Android emulator + iOS sim), docs/guides,
   security hardening, v1.0.

Knife article ("Why UI Automation Belongs in Your Language" or similar) lands when yantra has at least one live backend with a benchmark against the Playwright or Appium equivalent on the same workload — earliest opportunity is M1 closeout.
