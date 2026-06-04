#!/usr/bin/env python3
# scripts/parity-appium.py — the Appium side of yantra's MOBILE parity
# benchmark. Runs the SAME per-operation workload yantra's mobile e2e exercises
# (open → page source → find → tap) against the SAME app over the SAME local
# Appium server, so the two columns are comparable. Kept out of the build — a
# reference harness you run on a machine with Python + Appium + an emulator/sim:
#
#   pip install Appium-Python-Client
#   # with an Android emulator booted and Appium up on :4723:
#   appium &
#   python3 scripts/parity-appium.py            # Android (default)
#   PLATFORM=ios python3 scripts/parity-appium.py
#
# Prints avg/min/max per operation in the same shape as the Cyrius side
# (programs/benchmarks.cyr). yantra never bundles or fabricates these numbers;
# this is how you obtain the Appium column for the ROADMAP M6 / v1.0 mobile
# comparison. Mirror of scripts/parity-playwright.mjs for the web side.

import os
import time
import statistics

from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.options.ios import XCUITestOptions
from appium.webdriver.common.appiumby import AppiumBy

PLATFORM = os.environ.get("PLATFORM", "android").lower()
APPIUM = os.environ.get("APPIUM_URL", "http://127.0.0.1:4723")


def stats(name, samples_ns):
    avg = statistics.mean(samples_ns)
    lo, hi = min(samples_ns), max(samples_ns)
    us = lambda x: f"{x / 1000:.1f}us"
    print(f"  {name}: {us(avg)} avg (min={us(lo)} max={us(hi)}) [{len(samples_ns)} iters]")


def bench(name, iters, fn):
    s = []
    for _ in range(iters):
        t0 = time.perf_counter_ns()
        fn()
        s.append(time.perf_counter_ns() - t0)
    stats(name, s)


def make_driver():
    if PLATFORM == "ios":
        opts = XCUITestOptions()
        opts.platform_name = "iOS"
        opts.automation_name = "XCUITest"
        opts.bundle_id = "com.apple.Preferences"
        # Match a simulator the host has (xcrun simctl list devices available).
        opts.device_name = os.environ.get("IOS_DEVICE", "iPhone 17")
        opts.platform_version = os.environ.get("IOS_VERSION", "26.5")
        clickable = (AppiumBy.IOS_PREDICATE, "type == 'XCUIElementTypeCell'")
    else:
        opts = UiAutomator2Options()
        opts.platform_name = "Android"
        opts.automation_name = "UiAutomator2"
        opts.app_package = "com.android.settings"
        opts.app_activity = ".Settings"
        # Same quirk yantra works around (architecture 003).
        opts.skip_device_initialization = True
        opts.disable_window_animation = True
        clickable = (AppiumBy.XPATH, '//*[@clickable="true"]')
    return webdriver.Remote(APPIUM, options=opts), clickable


print(f"appium ({PLATFORM}), per-operation round trip:")

# Session open is its own line (it dominates — driver install / WDA build).
t0 = time.perf_counter_ns()
driver, CLICKABLE = make_driver()
open_ns = time.perf_counter_ns() - t0
stats("mobile.open(session)", [open_ns])

try:
    bench("mobile.source(page xml)", 20, lambda: driver.page_source)
    bench("mobile.find(clickable)", 50, lambda: driver.find_element(*CLICKABLE))

    el = driver.find_element(*CLICKABLE)
    bench("mobile.tap", 20, lambda: el.click())

    def flow():
        src = driver.page_source
        driver.find_element(*CLICKABLE).click()
    bench("flow: source+find+tap", 15, flow)
finally:
    driver.quit()
