# 005 — The iOS CI job is non-blocking (hosted-runner Appium/sandhi flakiness)

> **RESOLVED (0.6.2).** The `E2E (iOS / XCUITest)` job is now **gating** —
> `continue-on-error` has been removed. With a matched Xcode↔iOS-runtime
> generation pair, prebuilt WebDriverAgent, and `appium:noReset`, the full e2e
> passes **4/4** on the hosted runner (open Settings → page source → tap a native
> cell → close). It was briefly soft-gated (this note's original subject) while
> that stack was worked out. The background below is kept for the next person who
> hits hosted-runner iOS pain.
>
> **Updated (1.0.1).** The hosted `macos-latest` image moved to **Xcode 26.x with
> iOS 26.x runtimes only** — the iOS 18.x runtime / Xcode 16.4 this job pinned was
> removed, so the job started failing at the runtime-selection step (`No iOS 18.x
> runtime on this runner`). The boot step no longer hard-codes a generation: it
> derives the **active Xcode's major version** and targets the newest iOS runtime
> of that same generation (now 26.x — the combo yantra is verified on live at
> `ecb`: iPhone 17 / iOS 26.5 / xcuitest 11.9), self-adjusting for a future
> Xcode 27 / iOS 27 image.

> **Why** the job *carried* `continue-on-error: true` for a few iterations while
> the GitHub hosted runner's Appium/sandhi flakiness was chased. Soft-gate
> precedent: architecture 004 (WebKit).

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

- **Matched Xcode↔runtime generation** — derive the active Xcode's major version
  and target the newest iOS runtime of that same generation (now Xcode 26.x /
  iOS 26.x; through 1.0.1 it was Xcode 16.4 / iOS 18.x, until the runner image
  dropped the 18.x/16.4 pair). A cross-generation mix (Xcode-N binary vs iOS-M
  runtime) flakes the simulator boot with an empty-status timeout.
- **`appium:udid`** (`yantra_mobile_set_ios_udid`) — pin the exact booted sim.
- **`appium:isHeadless`** (`yantra_mobile_set_ios_headless`) — a display-less
  runner can't do Appium's "restart with the Simulator window visible" path.
- **`appium:noReset`** (`yantra_mobile_set_no_reset`) — the app-reset phase hung
  ~5.5 min on the runner.
- **Prebuilt WDA** (`yantra_mobile_set_ios_prebuilt_wda` + a CI
  `appium driver run xcuitest download-wda` step) — the cold `xcodebuild` WDA
  build is ~4 min and intermittently *stalls*.

The last blocker was a **cyrius/sandhi Darwin gap**, not yantra: sandhi's
**non-blocking connect** and **`SO_RCVTIMEO`** used Linux-only socket constants
(`O_NONBLOCK=2048`/`EINPROGRESS=115`/`SO_RCVTIMEO=20`; Darwin is
`0x4`/`36`/`0x1006`), so a connect-in-progress was misread as failure and yantra's
`POST /session` returned a spurious `SANDHI_ERR_CONNECT`. Tracked in cyrius issue
`2026-06-06-sandhi-nonblocking-connect-not-darwin-ported` — **resolved** in
bundled **sandhi 1.6.2** (the 0.6.3 / cyrius 6.2.11 pin), which Darwin-ported both
paths via cyrius 6.2.10's `net_connect_nb`.

## Workaround applied (0.6.2) — removed (post-0.6.3)

For 0.6.2, `wd_connect_timeout` (`src/protocol/webdriver.cyr`) forced sandhi's
**blocking** connect (Darwin-ported `net.cyr sock_connect`) by setting
`connect_ms=0` and leaving `total_ms` unset — otherwise `_sandhi_http_clamp_ms`
clamped the 0 connect timeout back up to the deadline and re-armed the broken
non-blocking path. It was correct for any localhost Appium and a no-op on Linux.

**Removed post-0.6.3** now that sandhi 1.6.2 Darwin-ported the connect/timeout
paths: `wd_connect_timeout` restores proper timeouts (`connect_ms=15000` +
`read_ms`/`total_ms` from the caller's budget), correct on both platforms.

## Why non-blocking is acceptable here

- yantra's **library logic** is exercised by the gating web (Chromium/CDP,
  chromedriver, geckodriver, WebKit) and **Android** (UiAutomator2) e2e jobs —
  the WebDriver/Appium wire and the mobile verbs are covered there.
- iOS is verified live on `ecb` at each release closeout.
- So the hosted-runner iOS job is kept as a best-effort signal (it still runs and
  reports pass/fail) without letting runner-specific Appium/sandhi flakiness
  redden the pipeline.

## Exit criteria — met (0.6.2)

`continue-on-error` has been **removed**; the job gates like the other e2e jobs.
The matched-pair + prebuilt-WDA + `connect_ms=0` stack got it to a genuine 4/4 on
the hosted runner. The underlying cyrius/sandhi Darwin connect/timeout port
(issue `2026-06-06-sandhi-nonblocking-connect-not-darwin-ported`) **landed** in
sandhi 1.6.2 with the 0.6.3 / cyrius 6.2.11 pin, so the `connect_ms=0` workaround
was dropped and proper connect/recv timeouts restored (see Unreleased changelog).
Nothing about iOS CI remains outstanding.
