# 004 — The WebKit CI job is non-blocking (WebKitGTK driver mismatch)

> **RESOLVED (0.6.2).** The omit-`browserName` caps fix below held green in CI,
> so the `E2E (WebKit / WebKitWebDriver)` job is now **gating** —
> `continue-on-error` has been removed. This note is kept for the background on
> the WebKitGTK browserName mismatch and why the job was temporarily non-blocking.

> **Why** the `E2E (WebKit / WebKitWebDriver)` CI job *carried*
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

## Fix applied (0.6.2) — omit browserName

`_web_caps_webkit` no longer sends `browserName: "webkit"`; it sends an empty
`alwaysMatch` (`{"capabilities":{"alwaysMatch":{}}}`). Per the W3C matching
algorithm, an absent `browserName` matches whatever browser the endpoint
controls — which for a WebKit WebDriver *is* WebKit — so the New Session is no
longer rejected on a name mismatch. This is also more correct than the old
hardcode: `"webkit"` was a Playwright label, never a real WebDriver browser
name, and yantra's webkit path is defined to target webkitwebdriver. The change
only touches the webkit caps; chromedriver / geckodriver / safaridriver keep
their explicit browserName.

This fix was **reasoned from the spec** (no live WebKitWebDriver locally), then
**confirmed green in CI** — the New Session is accepted and the WebKit e2e passes.

## Exit criteria — met (0.6.2)

`continue-on-error` has been **removed**; the job gates like the other web e2e
jobs. The omit-`browserName` fix got it reliably green, as expected.
