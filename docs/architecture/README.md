# Architecture notes

Non-obvious constraints, quirks, and invariants that a reader cannot derive from the code alone. Numbered chronologically — never renumber.

Not decisions (those live in [`../adr/`](../adr/)) and not guides (those live in [`../guides/`](../guides/)). An item here describes *how the world is*, not *what we chose* or *how to do something*.

## Items

- [001 — Chromium's DevTools HTTP endpoint requires HTTP/1.1](001-chromium-devtools-requires-http11.md) — why the CDP backend rolls its own discovery GET instead of using stdlib `http_get`.
- [002 — The WebDriver backend uses its own HTTP client, not `sandhi`](002-webdriver-uses-own-http-client.md) — `sandhi`'s `Connection: close` path drains until EOF and hangs against chromium-family servers; yantra uses a Content-Length-framed client until that's fixed upstream.
- [003 — Android sessions skip the `io.appium.settings` helper](003-android-skip-device-initialization.md) — why the Android path sets `skipDeviceInitialization` / `skipServerInstallation` on the hosted emulator.
- [004 — The WebKit CI job is non-blocking (WebKitGTK driver mismatch)](004-webkitgtk-ci-is-non-blocking.md) — **resolved (0.6.2)**; kept for the WebKitGTK `browserName` background and why omitting the cap is the correct fix.
- [005 — The iOS CI job is non-blocking (hosted-runner Appium/sandhi flakiness)](005-ios-ci-is-non-blocking.md) — why the XCUITest e2e job is best-effort on hosted macOS runners.
- [006 — A bracketed token inside a `cyrius.cyml` array silently truncates it](006-no-brackets-inside-manifest-arrays.md) — `[deps]` written inside a comment *within* the `stdlib = [...]` array ends the array; cyrius saw 17 of 27 leaves. Root cause of both the `lib sync --full` requirement and the 1.0.3 `distlib` failure.
