# yantra

> **Sovereign UI automation** — browser + mobile, as a Cyrius library.

**yantra** (Sanskrit यन्त्र — *instrument, device, automation machine*) is a library that lets `.tcyr` test files drive browsers and mobile devices. It is **not** a test framework. `cyrius test` stays the runner. yantra just adds the verbs.

The refusal is of the *ecosystem pattern* (separate test framework, separate runner, separate CI path — Selenium/Playwright/Appium's shape), not of the *testing activity*. Your existing test runner is enough.

## What a test looks like

```cyrius
# tests/login_e2e.tcyr
include "lib/yantra.cyr"

fn test_login_redirects_to_dashboard() {
    var session = yantra_web_open("chromium");
    yantra_navigate(session, "https://example.com/login");
    yantra_type(session, "#username", "alice");
    yantra_type(session, "#password", "secret");
    yantra_click(session, "button[type=submit]");
    assert_streq(yantra_url(session), "https://example.com/dashboard", "redirect");
    yantra_close(session);
}

var exit_code = test_login_redirects_to_dashboard();
yantra_exit(exit_code);   # tears down any leaked session, then exits
```

Same assertions, same runner, same `cyrius test` invocation — yantra just gave the test the ability to drive the browser.

Mobile shape is identical:

```cyrius
var session = yantra_mobile_open("android", "com.example.app");
yantra_tap(session, "@id/login_button");
```

## Modules

- `src/web.cyr` — browser automation (Chromium via CDP; Firefox/WebKit via WebDriver W3C)
- `src/mobile.cyr` — mobile automation (Android via UiAutomator2; iOS via XCUITest)
- `src/protocol/cdp.cyr` — Chrome DevTools Protocol (WebSocket frames)
- `src/protocol/webdriver.cyr` — W3C WebDriver JSON wire protocol
- `src/protocol/appium.cyr` — Appium JSON-RPC dialect

## Status

**1.0.0 — stable.** The 46-verb public API is **frozen**
([ADR 0002](docs/adr/0002-public-api-frozen-at-0.9.0-for-1.0.0.md)) — additive
only from here. All five planned backends **live**, each gated by its own CI e2e
job:
- **Chromium via CDP** (M1) — `yantra_web_open("chromium")`, with a Playwright
  parity benchmark.
- **Firefox / WebKit / Chrome / Safari via W3C WebDriver** (M2) —
  `yantra_web_open("firefox"/"webkit"/"chrome"/"safari")`, on the stdlib `sandhi` RPC layer.
- **iOS via Appium/XCUITest** (M4) — `yantra_mobile_open("ios", "<bundleId>")`
  + `yantra_tap` / `yantra_type` / `yantra_close`. **Live** (e2e 4/4 vs iOS 26.5 sim).
- **Android via Appium/UiAutomator2** (M3) — same API. **Live** (e2e 4/4 vs an
  android-34 x86_64 emulator).

**Resilience (M5):** auto-teardown of leaked sessions (`yantra_exit` /
`yantra_teardown_all`), a structured error surface (`yantra_last_error`),
retry-on-transient connects, and opt-in tracing spans (`yantra_trace_enable`).

Verified live: CDP 11/11, WebDriver 9/9, iOS 4/4, Android 4/4 (+ M5 offline
14/14). Runs on Linux x86_64 and **macOS arm64**.

**CI (M6):** the e2e suite runs against all five backends on every push/PR —
Chromium + chromedriver + Firefox + WebKit on Linux, Android on an emulator
(KVM), iOS on a macOS-runner simulator. Parity harnesses
(`scripts/parity-playwright.mjs`, `scripts/parity-appium.py`) produce the
Playwright / Appium comparison columns. See [the roadmap](docs/development/roadmap.md).

**Docs + examples (M7), security audit + sigil-verified cert pinning (M8)** are
done; web parity is ~3× (vs Playwright) and mobile is parity (vs Appium — both
ride the same Appium server). Start at [`docs/guides/`](docs/guides/).

**The thesis, with receipts:** [*Every other language draws the line before what
you can see. Cyrius draws it after.*](docs/articles/draw-the-line-after.md) — why
UI automation belongs in the language, and the numbers behind it.

## Build

`src/main.cyr` is the library (no `main()`); build the smoke program to
link-check it, and bundle with `cyrius distlib`.

```sh
cyrius lib sync --full                              # sync vendored lib/ to the pin (--full pulls transport libs)
cyrius build programs/smoke.cyr build/yantra-smoke  # link-check
cyrius test tests/yantra.tcyr                       # unit tests
cyrius bench tests/yantra.bcyr                       # micro-benchmarks
cyrius distlib                                      # → dist/yantra.cyr
```

## License

GPL-3.0-only.
