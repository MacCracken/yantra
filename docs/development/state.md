# yantra — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile). Add release-hook wiring
> when the repo's release workflow lands.

## Version

**1.0.1** — 2026-07-17. **Toolchain refresh — Cyrius 6.4.64** (from 6.2.15). No
yantra source changes beyond the `yantra_version()` constant; public API and all
five backends unchanged (frozen surface, [ADR 0002](../adr/0002-public-api-frozen-at-0.9.0-for-1.0.0.md)).
Bundled libs advanced with the snapshot: **sandhi 1.6.3 → 1.9.0**, **sigil
3.8.0 → 3.12.0**, **sakshi 2.3.0 → 2.4.6**, **bayan 1.0.1 → 1.1.0**.
**CI/release lib-sync switched to `cyrius lib sync --full`**: on the 6.4.x wrapper
the plain (non-`--full`) sync narrowed to a core-stdlib subset (35 files) and
stopped copying the transport/composite libs yantra's include chain needs
(`net`/`ws`/`tls`/`sandhi`/`sigil`/`sakshi`/`bayan`/`dynlib`/`fdlopen`/`mmap`,
all declared in `[deps] stdlib`) — a fresh clone (vendored `lib/` is gitignored)
would otherwise fail the smoke build with `cannot open include file:
lib/sandhi.cyr` (same class of fresh-sync break as the 0.6.3 base64/json fold).
All green offline on the new pin: smoke + `CYRIUS_DCE=1` release-parity build,
unit 2/2, M5 14/14, M8 21/21, lint 0 warnings, fmt clean, distlib → v1.0.1. Live
e2e (all five backends) validates in CI.

**1.0.0** — 2026-06-16. **Stable.** All five backends live + gating, auto-waiting,
resilience (M5), CI matrix (M6), docs/examples (M7), security audit + sigil cert
pinning (M8), published benchmarks (web ~3× / mobile parity), 46-verb public API
frozen ([ADR 0002](../adr/0002-public-api-frozen-at-0.9.0-for-1.0.0.md)), knife
article shipped (`docs/articles/draw-the-line-after.md`). No code change from
0.9.0 — the stability tag on the frozen surface + the article. Forward plan
(1.x): [roadmap.md](roadmap.md).

**0.9.0** — 2026-06-16. **Public API freeze for a clean 1.0.0.** The 46 public
`yantra_*` verbs are frozen as the 1.0.0 surface — no new verbs / signature
changes / renames / removals until 1.0.0 (bug fixes, internal refactors, docs,
pin bumps only). [ADR 0002](../adr/0002-public-api-frozen-at-0.9.0-for-1.0.0.md)
enumerates the frozen surface. No code changes (freeze + docs pass; README
example moved to the `yantra_exit` idiom). **Remaining for 1.0.0: the knife
article.** All five backends live; M5–M8 done; web + mobile parity published.

**0.8.3** — 2026-06-16. **Mobile parity numbers landed; toolchain → 6.2.15.** The
v1.0 "published benchmark comparison" criterion is met: Android + iOS
yantra-vs-Appium numbers measured and published (Benchmarks section). New
`programs/benchmarks-mobile.cyr` (`android`|`ios`). On the clean read round trip
(`source`), yantra is at **parity** with Appium-Python (Android 224 vs 188 ms,
iOS 455 vs 459 ms) — both ride the same Appium server, so mobile's win is
structural, not raw speed (web is ~3× via CDP). Pin 6.2.12 → **6.2.15** carries
the two arm64-macOS stdlib fixes found here (monotonic clock + `lib/bench.cyr`
measurement); `cyrius bench` works on macOS now. Bundled **sigil 3.7.14 → 3.8.0**.
No public-API changes. All green (smoke/unit/m5/m8/lint/fmt/distlib).

**0.8.2** — 2026-06-16. **M8 complete — F-2 endpoint cert auth wired end-to-end.**
Remote-host support (`yantra_web_set_host` / `yantra_mobile_set_host`, default
127.0.0.1) + sigil-verified HTTPS cert pinning
(`yantra_web_set_tls_pin_ed25519`/`_hybrid` + mobile equivalents): verify a
sigil-signed SPKI pin → switch endpoint to HTTPS → register via sandhi 1.6.3's
`sandhi_rpc_set_default_tls_policy` so every per-action call enforces it. Only
the WebDriver/Appium path; chromium/CDP stays localhost. Localhost sessions
byte-identical (default `http://127.0.0.1:<port>`). `tests/m8.tcyr` **21/21**
(base-URL construction + sandhi registry roundtrip). All green (smoke/unit/m5/m8/
lint/fmt/distlib). M8 audit `docs/audit/2026-06-15-audit.md` fully closed.

**0.8.1** — 2026-06-15. **Toolchain → Cyrius 6.2.12** (from 6.2.11); bundled
**sandhi 1.6.2 → 1.6.3**, **sigil 3.7.13 → 3.7.14**. sandhi 1.6.3 adds an
endpoint-keyed default TLS-policy registry (`sandhi_rpc_set_default_tls_policy`),
**resolving the M8 F-2 sandhi blocker** (per-action `sandhi_wd_*`/`sandhi_ap_*`
calls now carry a registered pin/mTLS/trust-store policy); the filed sandhi issue
is archived. M8 F-2's remaining work is now purely yantra-side: remote-host
support + registering the sigil-verified pin on the connect path. No yantra
source/API changes. All green on the new pin (smoke/unit/m5/m8/lint/fmt/distlib).

**0.8.0** — 2026-06-15. **M8 — security hardening (first pass).** Audit filed
(`docs/audit/2026-06-15-audit.md`): no-shell-out + error-surface verified clean.
**F-1 fixed** — the CDP JSON escaper now escapes the full C0 control range
(`\u00XX`), closing an invalid-JSON / ANSI-injection gap (and a latent
all-control-byte buffer overflow, buffers now 6×). **F-2 (verification half)** —
new `src/security.cyr` `yantra_tls_pin_verify_ed25519`/`_hybrid` verify a
sigil-signed SPKI cert-pin → a `sandhi_tls_policy_new_pinned`; sigil now in
`[deps]`/`[lib]`. End-to-end pinning is gated on a sandhi RPC TLS-policy hook
(sandhi issue `2026-06-15-yantra-sandhi-wd-rpc-no-tls-policy`) + remote-host support.
New `tests/m8.tcyr` (14/14); CI now also gates `m5.tcyr` + `m8.tcyr`. Pin stays
**6.2.11**.

**0.7.0** — 2026-06-15. **M7 — docs + examples**, plus the post-6.2.11 transport
cleanup. No public-API changes; all five backends unchanged. New
`docs/guides/` (getting-started, writing-e2e-tests, migrating-from-playwright,
migrating-from-appium, + index) and a runnable example per backend
(`examples/web-consumer/login.tcyr`, `examples/mobile-consumer/android.tcyr` /
`ios.tcyr`); `docs/examples/README.md` refreshed to "all five live". Dropped the
0.6.2 macOS blocking-connect workaround in `wd_connect_timeout` now that bundled
**sandhi 1.6.2** Darwin-ported the connect/timeout paths (cyrius issue
`2026-06-06-sandhi-nonblocking-connect-not-darwin-ported` resolved) — proper
`connect_ms`/`read_ms`/`total_ms` restored on macOS. Pin stays **6.2.11**.

**0.6.3** — 2026-06-15. **Toolchain refresh — Cyrius 6.2.11** (from 6.0.66). No
yantra source changes; the public API and all five backends are unchanged. The
bundled stdlib libs yantra rides on advanced with the snapshot: **sandhi
1.4.1 → 1.6.2** (WebDriver/Appium RPC), **sigil 3.6.4 → 3.7.13** (cert
verification, still M8-forward-looking), **sakshi 2.2.6 → 2.3.0** (tracing).
**`base64.cyr` + `json.cyr` were folded into the new `bayan.cyr` bundle (v1.0.1;
also csv/u128/bigint/toml/cyml)** — every include + the `[deps] stdlib` list now
go through `bayan` (it re-exports the unprefixed `base64_encode`/`json_v_*`, so
no call sites changed). That removal is what broke CI (`cannot open include
file: lib/base64.cyr`): a fresh `cyrius lib sync` no longer ships those files,
and `lib sync` doesn't prune stale local copies that had masked it. Verified on
the new pin against a **freshly re-synced `lib/`**: smoke + benchmark builds,
unit 2/2, M5 14/14, all six e2e compile/link clean (live-connect only in CI),
lint 0, fmt clean, `distlib` → `dist/yantra.cyr` v0.6.3.

**0.6.2** — 2026-06-04. **M6 — CI device matrix + parity harnesses.** yantra's
e2e suite **gates green against all five backends on every push/PR**: Chromium
(CDP) + chromedriver, **Firefox** (geckodriver), **WebKit** (WebKitWebDriver under
Xvfb), **Android** (`android-emulator-runner`, api-34/google_apis/x86_64 + Appium),
and **iOS** (`macos-latest` + Appium/XCUITest, **4/4** on the hosted runner). New
`scripts/parity-appium.py` (mobile parity, mirrors the web `parity-playwright.mjs`);
bench-history CSV uploaded as a CI artifact. New e2e: `tests/e2e/firefox-smoke.tcyr`,
`webkit-smoke.tcyr`. **Pin → 6.0.66** (cross-platform floor); `setup-cyrius`
installs via the canonical OS-aware `scripts/install.sh`.

The macOS/iOS path was a deep chain of toolchain + Appium fixes (all now resolved):
**6.0.63** fixed the arm64-macOS `GETDENTS64` dir-walk bug (broke `cyrius lib
sync`); **6.0.66** fixed two `cbt` bugs behind the iOS-runner `exit 127` (`cyrius
test` routed the arm64 binary through an absent `/usr/bin/qemu-aarch64`, and never
ad-hoc codesigned it). yantra-side: `_yantra_sleep_ms` now uses `poll` not raw
`syscall(35)` (which is `unlinkat`, not nanosleep, on aarch64-macho); and
`wd_connect_timeout` forces sandhi's **blocking** connect (`connect_ms=0`, no
`total_ms`) to dodge sandhi's Linux-only non-blocking-connect constants on Darwin
(cyrius issue `2026-06-06-sandhi-nonblocking-connect-not-darwin-ported`). The iOS
CI job pins **Xcode 16.4 + iOS 18.x** (matched generation), boots headless,
prebuilds WebDriverAgent (`download-wda`), and uses `appium:noReset` +
`usePreinstalledWDA` (new yantra verbs `set_ios_udid`/`set_ios_headless`/
`set_ios_wda_launch_timeout`/`set_no_reset`/`set_ios_prebuilt_wda`). It was briefly
soft-gated, now gating (architecture 005). WebKit is gating too (architecture 004).

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

- **Cyrius pin**: `6.4.64` (in `cyrius.cyml [package].cyrius`) — bumped off the
  6.2.x line in 1.0.1 (from 6.2.15). Earlier: refreshed off the 6.0.x line in
  0.6.3 (6.2.11), then 6.2.12 (0.8.1) → 6.2.15 (0.8.3, which added the arm64-macOS
  monotonic-clock + `lib/bench.cyr` fixes found by yantra).
  Carries forward
  the 6.0.59 Darwin `net.cyr` port and
  the 6.0.66 `cbt` macOS fixes; ships all platforms (x86_64/aarch64 ×
  linux/macos + windows), so it stays the cross-platform floor. Build/test/lint/
  fmt/distlib verified green on it. Vendored `lib/` is gitignored and
  materialized with **`cyrius lib sync --full`** — on the 6.4.x wrapper the plain
  (non-`--full`) sync copies only a 35-file core-stdlib subset and skips the
  transport/composite libs yantra needs (`net`/`ws`/`tls`/`sandhi`/`sigil`/
  `sakshi`/`bayan`/`dynlib`/`fdlopen`/`mmap`, all declared in `[deps] stdlib`);
  `--full` copies the whole snapshot. CI/release sync steps pass `--full`
  accordingly. *Toolchain history (6.0.x):* **6.0.63**
  fixed the
  arm64-macOS `GETDENTS64` bug (`61` untranslated → `EBADF`) that made `cyrius lib
  sync` report `snapshot lib not found` on a populated dir (the earlier `cp`/cache
  theories were red herrings — cyrius simply couldn't enumerate the directory on
  arm64 macOS). **6.0.65** makes `chrono.sleep_ms` portable via `poll` (+ thread
  fixes). The iOS-runner `exit 127` was a separate cyrius `cbt` bug (`cyrius test`
  ran the compiled arm64 binary via `/usr/bin/qemu-aarch64`, absent on a native
  Apple-Silicon host, and never ad-hoc codesigned it), **fixed in 6.0.66** (cyrius
  issue `2026-06-05-macos-cyrius-test-run-binary-qemu-aarch64-unsigned`) —
  confirmed: iOS CI is now 4/4 green. `setup-cyrius` installs solely via the
  canonical `scripts/install.sh`; the temporary "Ensure toolchain complete"
  repair/diagnostic step was removed once macOS CI went green (lib-snapshot cyrius
  issue archived). The last known macOS gap — sandhi's non-blocking connect +
  `SO_RCVTIMEO` using Linux-only socket constants (cyrius issue
  `2026-06-06-sandhi-nonblocking-connect-not-darwin-ported`) — is **resolved** by
  the 6.2.11 bump: bundled **sandhi 1.6.2** Darwin-ported both paths (via cyrius
  6.2.10's `net_connect_nb`). yantra's blocking-connect workaround in
  `wd_connect_timeout` was dropped post-0.6.3 (proper connect/recv timeouts
  restored — see Unreleased). No known toolchain gaps remain.
- **Bundled sandhi**: 1.9.0 (carries the `Connection: close` Content-Length
  framing fix the M2 WebDriver backend depends on, plus the endpoint-keyed
  default TLS-policy registry — `sandhi_rpc_set_default_tls_policy`, added in
  1.6.3 — that resolved the M8 F-2 per-action cert-pin gap).
- **sigil 3.12.0 requires** `thread.cyr` + `thread_local.cyr` included before
  it. Both are listed in `cyrius.cyml [deps] stdlib`. yantra **now includes
  sigil** (M8) via `src/security.cyr` for the sigil-verified cert-pin gate — so
  this ordering is a current constraint (the `[lib]` bundle and `programs/smoke.cyr`
  include `thread`/`thread_local` before `sigil`).

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

- **`lib/sandhi.cyr` (v1.9.0)** — the real HTTP client: a complete HTTP/1.1 +
  HTTP/2 stack. `sandhi_http_get/post/put/patch/delete/head(url, headers,
  body, len)`, full header management (`sandhi_headers_*`), **HTTPS/TLS**
  (`sandhi_conn_open(.., use_tls, sni_host)`, ALPN, TLS 1.3 0-RTT, session
  cache), redirects, per-phase timeouts, connection pooling, retry, streaming.
  Response via `sandhi_http_status/body/body_len/headers/err_kind`. This is
  what **M2 (WebDriver)** and **M3/M4 (Appium)** ride on — POST + `Content-Type:
  application/json` + HTTPS are all present today.
- **`lib/bayan.cyr` (v1.1.0)** — bundled data-codec lib; carries the tagged
  JSON value-tree (`json_v_parse`, `json_v_obj_get`, `json_v_arr_*`,
  `json_v_str/int/bool` — full nesting/arrays/typed values, carries
  WebDriver/Appium bodies cleanly) **and** base64 (`base64_encode`, used by the
  CDP WebSocket handshake), plus csv/u128/bigint/toml/cyml. As of the 6.2.x
  snapshot it subsumes the former standalone `json.cyr` and `base64.cyr`.
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
- `src/security.cyr` — **M8 transport security**: sigil-verified cert-pin gate
  (`yantra_tls_pin_verify_ed25519`/`_hybrid` → `sandhi_tls_policy_new_pinned`).
  Wrapped by the web/mobile `set_tls_pin_*` verbs (0.8.2), which switch the
  endpoint to HTTPS and register the pin via `sandhi_rpc_set_default_tls_policy`
  on the connect path. **Live (M8); tested in `tests/m8.tcyr`.**
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

The `[lib] modules` bundle order is
`main → runtime → security → cdp → webdriver → web → mobile`; these modules carry
no `include`s (stdlib resolved by the consumer). `programs/smoke.cyr` stitches the
stdlib chain on for a local link-check (including `thread`/`thread_local`/`sigil`
before the src modules, for `security.cyr`).

## Tests & benchmarks

- `tests/yantra.tcyr` — unit suite (`cyrius test`). Smoke-level today (2 passing).
- `tests/yantra.bcyr` — micro-benchmark harness (`cyrius bench`), real now:
  measures the session-primitive decode paths (~5 ns each).
- `tests/yantra.fcyr` — fuzz harness (`cyrius fuzz`), stub.
- `tests/m5.tcyr` — M5 resilience suite (**14/14**): structured errors,
  null-guards, session registry + teardown, tracing toggle. Offline / CI-safe.
- `tests/m8.tcyr` — M8 security suite (**14/14**): CDP JSON escaper (F-1 —
  named short escapes, `\u00XX` control-byte fallback, UTF-8 passthrough) +
  sigil-verified cert-pin gate (F-2 — Ed25519 sign→verify→tamper-reject,
  null-guards). Offline / CI-safe.
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
  (WebKitWebDriver under Xvfb). CI jobs `E2E (Firefox …)` and `E2E (WebKit …)`
  both gate (the WebKit omit-`browserName` caps fix held green — architecture 004).
- `tests/e2e/android-appium-smoke.tcyr` — M3 acceptance E2E. **Passing (4/4)**
  against a live android-34 / google_apis x86_64 emulator (Appium 3.x +
  uiautomator2): open `com.android.settings` → page source (UiAutomator2 XML) →
  tap first clickable element → close. CI job `E2E (Android …)` via
  `reactivecircus/android-emulator-runner` (KVM).
- `tests/e2e/ios-appium-smoke.tcyr` — M4 acceptance E2E. **4/4** both locally
  (iOS 26.5 sim on `ecb`) and on the **hosted `macos-latest` runner** — open
  Settings → source → tap cell → close. The CI job (gating) runs a runner-matched
  copy: it generation-matches the runner's active Xcode to a same-generation iOS
  sim (now Xcode 26.x / iOS 26.x — the runner image dropped the 18.x/16.4 pair the
  job used through 1.0.1), prebuilds WDA, and injects
  `set_ios_udid`/`set_ios_headless`/`set_no_reset`/`set_ios_prebuilt_wda` (the
  committed file targets the maintainer's local sim). See architecture 005.
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

## Benchmarks — mobile parity (yantra vs Appium-Python)

Same per-op workload as `scripts/parity-appium.py`, same app, same local Appium 3.5
server. yantra: `programs/benchmarks-mobile.cyr <platform>`. Appium-Python:
`scripts/parity-appium.py`. Both columns reproduced, never fabricated.

**Android** (2026-06-16, Linux/KVM, android-34 x86_64 emulator, UiAutomator2,
`com.android.settings`):

| Operation | yantra | Appium-Python | Note |
|-----------|-------:|--------------:|------|
| `open(session)` | ~2.59 s | ~2.31 s | one-shot; dominated by Appium session setup |
| `source(page xml)` | ~224 ms | ~188 ms | read-only round trip — the clean apples-to-apples metric |
| `find(clickable)` | — | ~88 ms | yantra folds find into `tap`; no standalone find verb |
| `tap` | ~534 ms (1×) | n/a | the Appium harness's `tap×20` hit a UiAutomator2 internal click error |

**iOS** (2026-06-16, ecb arm64 macOS, iPhone 17 / iOS 26.5 sim, XCUITest,
`com.apple.Preferences`; cyrius 6.2.15 — the macOS clock+bench fixes):

| Operation | yantra | Appium-Python | Note |
|-----------|-------:|--------------:|------|
| `open(session)` | ~12.1 s | ~3.47 s | **not comparable** — WDA-build-state dependent: yantra paid the cold `xcodebuild` WDA build, Appium then attached to the built WDA |
| `source(page xml)` | ~455 ms | ~459 ms | read-only round trip — the clean apples-to-apples metric → **parity** |
| `find(clickable)` | — | ~86 ms | folded into `tap` |
| `tap` | ~1.10 s (1×) | ~2.41 s (×20) | different methodology (yantra find+actionable+click once vs Appium click-pre-found ×20) |

**Honest read:** mobile is **near parity** on the clean read round trip (source:
Android 224 vs 188 ms, iOS 455 vs 459 ms) — and that's expected, because *both*
yantra and the Python client drive the **same** Appium server, so the device
round trip dominates and client overhead is small. Mobile's win is **structural**
(no separate framework / runner / CI path — one `.tcyr` on `cyrius test`), not
raw speed; the raw-speed advantage shows on **web**, where yantra speaks CDP
directly (~3× on the flow) vs Playwright's heavier client. `open`/`tap` are not
clean client comparisons (WDA build state; differing tap methodology).

## Dependencies

Declared in `cyrius.cyml`:

- **Cyrius stdlib** (comprehensive set — see manifest; `thread` +
  `thread_local` added for the sigil 3.6.0 requirement)
- **sakshi** 2.4.6 — structured logging / tracing (bundled in snapshot)
- **sigil** 3.12.0 — hybrid (Ed25519 + ML-DSA-65) signature verification;
  **now included** (M8) by `src/security.cyr` for sigil-verified cert pins
  (requires `thread` + `thread_local` before it, both in `[deps] stdlib`)
- **sandhi** 1.9.0 — HTTP/1.1+2 + WebDriver/Appium RPC layer; carries the
  endpoint-keyed default TLS-policy registry (`sandhi_rpc_set_default_tls_policy`,
  added in 1.6.3) the M8 F-2 cert-pin path needs (bundled in snapshot)
- **bayan** 1.1.0 — data-codec bundle (base64 + json + csv/u128/bigint/toml/
  cyml); subsumes the former `base64.cyr` + `json.cyr` (bundled in snapshot)

## Consumers

_None yet. yantra is a library for downstream `.tcyr` tests. Expected first consumers:_

- AGNOS-owned projects that need E2E coverage (owl, agnoshi, tanur when GUI lands)
- Any AGNOS consumer that currently shells out to Playwright or Appium

## Next

1.0.0 is out; the M0–M8 milestone history is in
[CHANGELOG.md](../../CHANGELOG.md). The forward plan lives in
[roadmap.md](roadmap.md). **1.x** (additive, non-breaking — the frozen 46-verb
surface only grows), priority order:

1. **Full actionability auto-waiting** — wait for visible + stable + enabled, not
   just existence + `readyState`. Closes the `click` benchmark caveat above; the
   top 1.x item.
2. **Safari live coverage** — `yantra_web_open("safari")` is routed but not yet
   e2e-verified; add a macOS Safari e2e so all targets are green, not just five.
3. **Richer element-state verbs** (additive) — `is_visible` / `text` / `attr`, so
   consumers assert without dropping to `eval_str`.
4. **Consumer-driven polish** — shaped by the first downstream adopter.

Post-1.0 / v2 candidates (native mobile transport — own the layer below Appium;
Browser-BiDi; recorder/codegen; component-testing; browser auto-download) are
parked in the roadmap; a real v2 scoping is a later conversation.
