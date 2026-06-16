# Migrating from Appium

> A translation cookbook for teams moving mobile E2E tests from Appium to yantra.
> yantra rides the same Appium server (UiAutomator2 for Android, XCUITest for
> iOS) over the W3C WebDriver/Appium wire — so your *infrastructure* is
> unchanged. What changes is the client: instead of an Appium client library +
> a separate runner, you write a `.tcyr` and run `cyrius test`.

## Mental model

| Appium (Python client shown) | yantra |
|------------------------------|--------|
| `webdriver.Remote(url, options)` | `yantra_mobile_open(platform, app_id)` |
| `driver` object | a session handle (`i64`) |
| desired capabilities dict | a few explicit `yantra_mobile_set_*` calls |
| pytest / unittest runner | `cyrius test` |
| `By.*` locator strategies | selector-string prefixes |

A mobile session is a WebDriver-transport session, so the **web verbs apply
directly** — `yantra_type`, `yantra_close`, `yantra_eval_*` all work on a mobile
handle. Mobile adds `yantra_tap` / `yantra_tap_now` / `yantra_mobile_source`.

## Setup

```python
# Appium (Android)
from appium import webdriver
from appium.options.android import UiAutomator2Options
opts = UiAutomator2Options()
opts.platform_name = "Android"
opts.app_package = "com.android.settings"
driver = webdriver.Remote("http://127.0.0.1:4723", options=opts)
```

```cyrius
# yantra (Android) — UiAutomator2, Appium on :4723 (yantra_mobile_set_port to override)
var m = yantra_mobile_open("android", "com.android.settings");
```

```python
# Appium (iOS)
opts = XCUITestOptions()
opts.platform_name = "iOS"
opts.bundle_id = "com.apple.Preferences"
opts.device_name = "iPhone 17"
opts.platform_version = "18.6"
driver = webdriver.Remote("http://127.0.0.1:4723", options=opts)
```

```cyrius
# yantra (iOS) — XCUITest
yantra_mobile_set_ios_device("iPhone 17", "18.6");
var m = yantra_mobile_open("ios", "com.apple.Preferences");
```

## Capabilities → setters

yantra exposes the capabilities that actually matter for reliable sessions as
explicit, omit-by-default setters (call them *before* `yantra_mobile_open`):

| Appium capability | yantra setter |
|-------------------|---------------|
| `appium:deviceName` / `appium:platformVersion` (iOS) | `yantra_mobile_set_ios_device(name, version)` |
| `appium:udid` (iOS) | `yantra_mobile_set_ios_udid(udid)` |
| `appium:isHeadless` (iOS) | `yantra_mobile_set_ios_headless(on)` |
| `appium:noReset` (Android + iOS) | `yantra_mobile_set_no_reset(on)` |
| `appium:wdaLaunchTimeout` (iOS) | `yantra_mobile_set_ios_wda_launch_timeout(ms)` |
| `appium:usePreinstalledWDA` + `appium:prebuiltWDAPath` (iOS) | `yantra_mobile_set_ios_prebuilt_wda(app_path)` |
| Appium server port | `yantra_mobile_set_port(p)` |

Android's UiAutomator2 caps (including `appium:skipDeviceInitialization`, which
yantra sets to bypass the flaky `io.appium.settings` helper — see
[architecture 003](../architecture/003-android-skip-device-initialization.md))
are built for you; you only call setters for the per-run knobs above.

## Locators → selectors

| Appium `By` | yantra selector |
|-------------|-----------------|
| `AppiumBy.ID` / resource-id | `@id/<resource-id>` |
| `AppiumBy.ACCESSIBILITY_ID` | `~<label>` |
| `AppiumBy.XPATH` | `/<xpath>` |
| `AppiumBy.ANDROID_UIAUTOMATOR` (text) | `text:<value>` |

```python
driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Add").click()
```

```cyrius
yantra_tap(m, "~Add");
```

## Actions

| Appium | yantra |
|--------|--------|
| `el.click()` | `yantra_tap(m, sel)` |
| tap without waiting | `yantra_tap_now(m, sel)` |
| `el.send_keys(text)` | `yantra_type(m, sel, text)` |
| `driver.page_source` | `yantra_mobile_source(m)` |
| `driver.quit()` | `yantra_close(m)` |

## A full test, side by side

```python
# Appium
def test_open_settings():
    driver = webdriver.Remote("http://127.0.0.1:4723", options=android_opts)
    src = driver.page_source
    assert "android" in src
    driver.find_element(AppiumBy.XPATH, "//android.widget.TextView[1]").click()
    driver.quit()
```

```cyrius
# yantra — examples/mobile-consumer/android.tcyr
include "lib/yantra.cyr"

fn test_open_settings() {
    var m = yantra_mobile_open("android", "com.android.settings");
    assert_neq(yantra_mobile_source(m), 0, "got page source");
    yantra_tap(m, "/(//android.widget.TextView)[1]");
    yantra_close(m);
    return assert_summary();
}

var code = test_open_settings();
yantra_exit(code);   # closes the emulator session pass or fail
```

## What has no direct analog (on purpose)

- **Client-library `WebDriverWait` / explicit waits** — actions auto-wait;
  `yantra_tap_now` is the opt-out.
- **Capabilities for every Appium feature** — yantra surfaces the ones needed
  for reliable sessions; it's not a 1:1 caps passthrough.
- **Separate test runner / reporters** — `cyrius test` is the runner;
  assertions are stdlib `assert_*`.

## See also

- [Writing E2E tests](writing-e2e-tests.md) — selectors, errors, teardown.
- [Migrating from Playwright](migrating-from-playwright.md) — the web side.
- `tests/e2e/android-appium-smoke.tcyr` / `ios-appium-smoke.tcyr` — yantra's own
  live mobile e2e, usable as worked references.
