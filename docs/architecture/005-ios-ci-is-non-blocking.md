# 005 — The iOS CI job is non-blocking (hosted-runner Appium/sandhi flakiness)

> **Why** the `E2E (iOS / XCUITest)` CI job carries `continue-on-error: true`
> while the web + Android e2e jobs gate. Recorded here because a non-gating test
> job is a deliberate, non-obvious choice. Soft-gate precedent: architecture 004
> (WebKit).

## What works

- The iOS e2e (`tests/e2e/ios-appium-smoke.tcyr`) passes **4/4 on a real macOS
  arm64 host** (`ecb`): open Settings → page source → tap a cell → close.
- On the GitHub hosted runner, the Appium/XCUITest **session itself is confirmed
  working** — the CI step's `curl POST /session` probe returns **HTTP 200** with
  a real sessionId, driving the prebuilt WebDriverAgent on a booted simulator.

So neither the yantra library logic nor the e2e test is the problem.

## Why it's flaky on the hosted runner

Getting the hosted-runner session even *startable* took a stack of fixes, each a
real, reusable capability (all omit-by-default yantra verbs, opted into by CI):

- **Matched Xcode↔runtime generation** — pin Xcode 16.4 + target the iOS 18.x
  runtime (the image's bleeding-edge iOS 26.x runtimes are paired with Xcode 26;
  mixing them flaked the simulator boot with an empty-status timeout).
- **`appium:udid`** (`yantra_mobile_set_ios_udid`) — pin the exact booted sim.
- **`appium:isHeadless`** (`yantra_mobile_set_ios_headless`) — a display-less
  runner can't do Appium's "restart with the Simulator window visible" path.
- **`appium:noReset`** (`yantra_mobile_set_no_reset`) — the app-reset phase hung
  ~5.5 min on the runner.
- **Prebuilt WDA** (`yantra_mobile_set_ios_prebuilt_wda` + a CI
  `appium driver run xcuitest download-wda` step) — the cold `xcodebuild` WDA
  build is ~4 min and intermittently *stalls*.

The remaining blocker is a **cyrius/sandhi Darwin gap**, not yantra: sandhi's
**non-blocking connect** and **`SO_RCVTIMEO`** use Linux-only socket constants
(`O_NONBLOCK=2048`/`EINPROGRESS=115`/`SO_RCVTIMEO=20`; Darwin is
`0x4`/`36`/`0x1006`), so a connect-in-progress is misread as failure and yantra's
`POST /session` returns a spurious `SANDHI_ERR_CONNECT`. Tracked in cyrius issue
`2026-06-06-sandhi-nonblocking-connect-not-darwin-ported`.

## Workaround applied (0.6.2)

`wd_connect_timeout` (`src/protocol/webdriver.cyr`) forces sandhi's **blocking**
connect (Darwin-ported `net.cyr sock_connect`) by setting `connect_ms=0` and
leaving `total_ms` unset — otherwise `_sandhi_http_clamp_ms` clamps the 0 connect
timeout back up to the deadline and re-arms the broken non-blocking path. This is
correct for any localhost Appium and is a no-op on Linux (Android e2e unaffected).

## Why non-blocking is acceptable here

- yantra's **library logic** is exercised by the gating web (Chromium/CDP,
  chromedriver, geckodriver, WebKit) and **Android** (UiAutomator2) e2e jobs —
  the WebDriver/Appium wire and the mobile verbs are covered there.
- iOS is verified live on `ecb` at each release closeout.
- So the hosted-runner iOS job is kept as a best-effort signal (it still runs and
  reports pass/fail) without letting runner-specific Appium/sandhi flakiness
  redden the pipeline.

## Exit criteria

Remove `continue-on-error` once the hosted-runner iOS job is reliably green —
which needs the cyrius/sandhi Darwin connect/timeout port (the issue above) and
confirmation that the prebuilt-WDA + matched-pair setup holds across runs.
