# 0002 — Public API frozen at 0.9.0 for 1.0.0

**Status**: Accepted
**Date**: 2026-06-16

## Context

All five backends are live (M1–M4), resilience (M5), the CI matrix (M6), docs +
examples (M7), and the security audit (M8) are done. The published benchmark
comparison — web (~3× vs Playwright) and mobile (parity vs Appium, both ride the
same Appium server) — is in `docs/development/state.md`. The only thing between
here and 1.0.0 is the knife article.

The public verb surface has grown across 0.2.1 → 0.8.3 (CDP, WebDriver, Appium,
resilience, mobile capability setters, M8 cert pinning). Before 1.0.0 — which
carries a stability promise — consumers need to know the surface won't shift
under them. 1.0.0 should be a *clean cut*: a tag, not a scramble.

## Decision

**0.9.0 freezes the public `yantra_*` API.** The 46 exported verbs as of 0.9.0
are the 1.0.0 surface. Between 0.9.0 and 1.0.0: **no new public verbs, no
signature changes, no renames, no removals.** Only allowed: bug fixes that don't
change signatures, internal refactors, doc/test additions, and toolchain-pin
bumps that don't alter behavior.

Frozen surface (46 verbs):
- **web** — `yantra_web_open`, `navigate`, `click`, `click_now`, `type`, `url`,
  `eval_str`, `eval_bool`, `close`; `web_set_cdp_port`/`cdp_port`/`set_wd_port`;
  `web_set_host`/`host`; `web_set_tls_pin_ed25519`/`_hybrid`.
- **mobile** — `mobile_open`, `tap`, `tap_now`, `mobile_source`;
  `mobile_set_port`/`port`/`set_host`/`host`; iOS setters
  (`set_ios_device`/`_udid`/`_headless`/`_wda_launch_timeout`/`_prebuilt_wda`);
  `set_no_reset`; `mobile_set_tls_pin_ed25519`/`_hybrid`.
- **session/runtime** — `session_kind`/`backend`/`flags`; `exit`,
  `teardown_all`, `open_session_count`; `last_error`/`_str`; `set_open_retry`;
  `trace_enable`/`trace_enabled`; `version`.
- **security** — `tls_pin_verify_ed25519`/`_hybrid` (the low-level gate the
  `set_tls_pin_*` verbs wrap).

A new verb that *must* land before 1.0.0 forces a deliberate re-freeze (a new
0.9.x with an updated ADR), not a quiet addition.

## Consequences

- **Positive** — 1.0.0 is a clean tag: consumers can build against 0.9.0 and know
  it holds. The surface is enumerated in one place, so "is this public?" has a
  definitive answer. Forces discipline — anything not in the list waits for 1.x.
- **Negative** — genuinely-missing verbs discovered during freeze can't slip in
  quietly; they cost a re-freeze. Accepted: the surface is broad and exercised by
  the e2e suite, so gaps are unlikely.
- **Neutral** — post-1.0 additions are additive (new verbs are minor bumps);
  anything that would change an existing signature is a 2.0 conversation. The
  native-mobile-transport direction (post-v1.0, see roadmap) is a *transport*, not
  new public verbs, so it doesn't threaten the freeze.

## Alternatives considered

- **Freeze at 1.0.0 directly (skip 0.9.0).** Rejected — no buffer to catch a
  late gap; the freeze and the stability promise would land in the same tag with
  no soak.
- **Don't formally freeze; just tag 1.0.0 when it feels ready.** Rejected — "feels
  ready" is how a surface keeps drifting. An enumerated, dated freeze is the
  whole point of a clean cut.
