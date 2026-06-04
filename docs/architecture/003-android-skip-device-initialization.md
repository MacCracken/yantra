# 003 — Android sessions skip the `io.appium.settings` helper

> **Why** `yantra_mobile_open("android", …)` sets
> `appium:skipDeviceInitialization=true` (and `appium:disableWindowAnimation=true`)
> in `_mobile_caps` (`src/mobile.cyr`). Non-obvious — these aren't capabilities a
> reader would expect a UI-automation library to hardcode — so it's recorded here.

## The failure

On a stock Android emulator image (verified on `android-34` / `google_apis` /
x86_64), Appium's default device-initialization step tries to install and launch
its **`io.appium.settings`** helper app before handing back a session. On these
images that install/launch fails:

```
PackageManager$NameNotFoundException: Package io.appium.settings unavailable
SecurityException: Specified package "io.appium.settings" under uid 10192 but it is not
ActivityManager: START … cmp=io.appium.settings/.Settings … result code=-92
```

When the helper can't be resolved, UiAutomator2 instrumentation aborts and
session creation fails. From yantra's side this surfaced as
`yantra_mobile_open` returning 0 with `yantra_last_error() == YANTRA_ERR_SESSION`
("Appium session create failed"). It was also **flaky** — an occasional run
would race past it — which is the usual signature of an install/registration
timing problem rather than a yantra bug. (iOS/XCUITest, identical yantra code,
was 4/4 throughout — confirming the cause was the Android helper, not yantra.)

## The fix

`appium:skipDeviceInitialization=true` tells Appium **not** to push/launch
`io.appium.settings`. That helper provides device conveniences yantra doesn't
use — toggling wifi/data/locale, IME management, clipboard, notifications. The
**UiAutomator2 server** that actually drives `find` / `click` / `tap` / page
`source` is a *separate* APK install and is unaffected by skipping the settings
helper. So the verbs yantra exposes keep working; only the unused conveniences
are dropped. `appium:disableWindowAnimation=true` is a stability nicety (no
animation races during taps), not part of the fix.

## Scope / exit criteria

This is an emulator-image quirk, not an Appium bug per se — the helper install
can also fail for signature/uid reasons on rooted or customized images. Skipping
it is the documented, low-cost mitigation and costs yantra nothing today. If a
future verb needs a capability that only `io.appium.settings` provides (e.g.
programmatic locale switching for i18n tests), revisit: either drop the skip on
images where the helper installs cleanly, or `adb install` a matching
`io.appium.settings` APK before the session. Until then the skip stays
unconditional for Android.
