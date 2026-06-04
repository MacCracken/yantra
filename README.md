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
syscall(60, exit_code);
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

**0.5.0.** All five planned backends implemented:
- **Chromium via CDP** (M1) — `yantra_web_open("chromium")`, with a Playwright
  parity benchmark.
- **Firefox / WebKit / Chrome / Safari via W3C WebDriver** (M2) —
  `yantra_web_open("firefox"/"webkit"/"chrome"/"safari")`, on the stdlib `sandhi` RPC layer.
- **iOS via Appium/XCUITest** (M4) — `yantra_mobile_open("ios", "<bundleId>")`
  + `yantra_tap` / `yantra_type` / `yantra_close`. **Live** (e2e 4/4 vs iOS 26.5 sim).
- **Android via Appium/UiAutomator2** (M3) — same API; implemented (live run lands with the M6 emulator matrix).

Verified live: CDP 11/11, WebDriver 9/9, iOS 4/4. Runs on Linux x86_64 and
**macOS arm64**. See [the roadmap](docs/development/roadmap.md).

## Build

`src/main.cyr` is the library (no `main()`); build the smoke program to
link-check it, and bundle with `cyrius distlib`.

```sh
cyrius lib sync                                     # sync vendored lib/ to the pin
cyrius build programs/smoke.cyr build/yantra-smoke  # link-check
cyrius test tests/yantra.tcyr                       # unit tests
cyrius bench tests/yantra.bcyr                       # micro-benchmarks
cyrius distlib                                      # → dist/yantra.cyr
```

## License

GPL-3.0-only.
