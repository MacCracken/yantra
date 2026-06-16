# yantra examples

Runnable `.tcyr` examples per backend. Consumers drive these with the
**same `cyrius test` runner** they already use — yantra ships no separate
runner, config schema, or CI plugin (see [ADR 0001](../adr/0001-yantra-is-a-library-not-a-framework.md)).

| Example | Backend | Status |
|---------|---------|--------|
| [`examples/web-consumer/login.tcyr`](../../examples/web-consumer/login.tcyr) | Chromium (CDP) / WebDriver | **live** — swap the opener for chrome/firefox/webkit/safari |
| [`examples/mobile-consumer/android.tcyr`](../../examples/mobile-consumer/android.tcyr) | Android (Appium / UiAutomator2) | **live** |
| [`examples/mobile-consumer/ios.tcyr`](../../examples/mobile-consumer/ios.tcyr) | iOS (Appium / XCUITest) | **live** |

> All five backends are live. Each example needs its target running (a browser
> on the DevTools port, a driver, or an Appium server + device) — see the header
> of each file. New to yantra? Start with
> [`../guides/getting-started.md`](../guides/getting-started.md).

## How a consumer uses yantra

1. Add yantra as a dependency; `cyrius deps` vendors `dist/yantra.cyr` as `lib/yantra.cyr`.
2. `include "lib/yantra.cyr"` in a `.tcyr` test.
3. Call the verbs (`yantra_web_open`, `yantra_navigate`, `yantra_click`, …).
4. Run `cyrius test path/to/test.tcyr`. Same assertions, same runner.

yantra's own E2E suite ([`tests/e2e/`](../../tests/e2e/)) dogfoods this exact path against live headless targets.
