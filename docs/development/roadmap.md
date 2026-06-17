# yantra — Roadmap

> Forward-facing plan from **1.0.0** onward. Shipped history lives in
> [`CHANGELOG.md`](../../CHANGELOG.md); live state in [`state.md`](state.md).
> This file is **what's next**, not what's done.

## Shipped (≤ 1.0.0)

1.0.0 is out. All five backends live and gating in CI — Chromium (CDP),
Chrome/Firefox/WebKit/Safari (W3C WebDriver), Android/iOS (Appium) — with
Playwright-style auto-waiting, auto-teardown + structured errors + retry, the CI
device matrix, docs + examples + migration guides, a security audit with
sigil-verified cert pinning, and published benchmarks (web ~3× vs Playwright;
mobile parity vs Appium). The 46-verb public API is **frozen**
([ADR 0002](../adr/0002-public-api-frozen-at-0.9.0-for-1.0.0.md)). Full milestone
history (M0–M8) is in the CHANGELOG.

## 1.x — next

Additive and non-breaking — the frozen surface only *grows* (new verbs are minor
bumps; nothing renamed or removed without a 2.0 conversation). Roughly in
priority order:

### Full actionability auto-waiting
The biggest remaining quality win. Today every action waits for element
*existence* + `readyState`; Playwright's deeper guarantee — wait for **visible +
stable (not animating) + enabled** before acting — isn't there yet. It's the one
place the web `click` benchmark isn't apples-to-apples with Playwright (see the
caveat in state.md Benchmarks). Land it *inside* the existing auto-wait so
consumers get it for free; the `*_now` verbs stay the explicit opt-out. Pure
library work, no new required surface.

### Safari live coverage
`yantra_web_open("safari")` is routed through safaridriver but is the one backend
without a live green e2e. Add a Safari e2e on the macOS path (ecb / a macOS CI
job, `sudo safaridriver --enable`) so all six web/mobile targets are verified, not
just five.

### Richer element-state verbs (additive)
Query/assert helpers the actionability work naturally surfaces — e.g.
`yantra_is_visible` / `yantra_text` / `yantra_attr` — so consumers assert on
element state without dropping to `eval_str`. Additive verbs only; keeps tests
reading as intent, not JS.

### Consumer-driven polish
The first downstream adopter (an AGNOS project leaving Playwright/Appium — owl /
agnoshi / tanur when its GUI lands) shapes the rest of 1.x: missing verbs, rough
edges, guide gaps. Hold this slot open rather than guessing.

## Post-1.0 / v2 candidates (unscheduled)

A real v2 scoping is a later conversation. Parked directions, biggest first:

- **Native mobile transport — own the layer below Appium.** The mobile analog of
  the web CDP win, and the *only* path to a real mobile speed advantage. Today's
  mobile parity is structural: yantra and Appium-Python both ride the same Appium
  server, so the device round trip dominates and neither wins on the clock
  (source: Android 224 vs 188 ms, iOS 455 vs 459 ms). Owning the transport end to
  end is where the numbers diverge:
  - **Direct on-device agent** — drive UiAutomator2-server / WDA directly over an
    adb/socket-forwarded channel, no Appium broker. Modest alone, the stepping stone.
  - **AgnosOS on jailbroken Android** — a yantra-native on-device agent (targeted
    hierarchy queries, input-layer injection, an owned wire format). The mobile CDP.
  - **Owned Android emulator image** — fork AOSP/QEMU with a baked-in agent over
    qemu-pipe/vsock; great for reproducible CI control.
  - **iOS note:** an owned *iOS emulator* is out of scope (Apple's stack is closed;
    Simulator is a macOS shim, not a VM). iOS stays owned-device + jailbreak + agent.

  These are device/OS programs, not library changes — they give yantra a transport
  to *own*. Principle: **benchmark only where you own the transport.**
- **Browser-BiDi** — the W3C successor to WebDriver (bidirectional, partial
  CDP-shape). Adopt as a new `protocol/` module when it matures; doesn't disturb
  the public surface.
- **Recorder / codegen** — generate `.tcyr` from a recorded session (Playwright
  Codegen analog).
- **Component testing mode** — framework-less component mount + act + assert
  against a Chromium snippet. In scope only as a pure library helper, never if it
  grows a framework.
- **Playwright-parity auto-download** — vendor-managed browser binaries. Probably
  belongs behind an `ark` flag, not inside yantra itself.
