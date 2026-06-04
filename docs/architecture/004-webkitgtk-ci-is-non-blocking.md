# 004 — The WebKit CI job is non-blocking (WebKitGTK driver mismatch)

> **Why** the `E2E (WebKit / WebKitWebDriver)` CI job carries
> `continue-on-error: true` while every other backend's e2e job gates. Recorded
> here because a non-gating test job is a deliberate, non-obvious choice.

## The mismatch

yantra's `yantra_web_open("webkit")` sends W3C capabilities
`{"browserName":"webkit"}` (`_web_caps_webkit` in `src/web.cyr`) — the
Playwright-style name for "the WebKit engine". On Linux CI the only freely
installable WebKit WebDriver is **WebKitGTK's `WebKitWebDriver`** (the
`webkit2gtk-driver` apt package). That driver advertises its browser as
`browserName: "WebKitGTK"`, and the W3C *capability matching* algorithm fails
session creation when `alwaysMatch.browserName` doesn't equal the remote end's
browserName. So the session-create is rejected before yantra does anything —
the driver is up (its `/status` returns ready), but `New Session` 400s. Headless
WebKitGTK in a hosted runner is also brittle (needs Xvfb, a GPU-less compositing
mode, and a real WebKit browser binary for the driver to spawn).

We will **not** bend yantra's public cap to `"WebKitGTK"` to satisfy one CI
environment — `"webkit"` is a deliberate, Playwright-parity API choice, and the
Linux WebKitGTK build is not the WebKit yantra users target anyway.

## Why non-blocking is acceptable here

- The **W3C WebDriver wire** yantra speaks is already gated green by two
  engines: `e2e-webdriver` (chromedriver / Chromium) and `e2e-firefox`
  (geckodriver / Gecko). A regression in yantra's WebDriver code path would fail
  those, so coverage of the *protocol* does not depend on WebKit.
- WebKit's **authoritative** coverage is the **iOS / XCUITest** path
  (`e2e-ios`) and Apple's `safaridriver` on macOS — real WebKit, not the GTK
  port. That is where a WebKit-engine regression actually matters for yantra.
- So the WebKitGTK job is kept as a best-effort signal (it still runs and its
  result is visible) without letting an environment quirk redden the pipeline.

## Exit criteria

Make the job gate again once one of these lands:
- a CI recipe that gives WebKitWebDriver a browser binary it accepts and reach a
  green New Session (likely `webkitgtk:browserOptions` + MiniBrowser, supplied
  CI-side without changing yantra's cap), **or**
- a yantra-side option to override the WebDriver `browserName` per session
  (so the public default stays `"webkit"` but CI can request `"WebKitGTK"`).

Until then, remove `continue-on-error` only when the job is reliably green.
