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

**0.2.1 — released.** **M1 Chromium/CDP backend is live** —
`yantra_web_open("chromium")` drives a real headless browser (navigate / click
/ type / url / eval / close, auto-waiting), with a green end-to-end test
(`tests/e2e/chromium-smoke.tcyr`) and a Playwright parity benchmark. Firefox/
WebKit (WebDriver) and mobile (Appium) fill in per
[the roadmap](docs/development/roadmap.md), gated on `http.cyr` POST depth.

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
