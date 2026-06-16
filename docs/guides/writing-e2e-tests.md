# Writing E2E tests with yantra

> Assumes you've done [Getting started](getting-started.md). This guide covers
> the things that make E2E tests *reliable*: auto-waiting, selector strategies,
> sharing a session across steps, structured errors, and teardown.

## Auto-waiting (the default)

Every action verb waits for the element to be actionable before operating —
Playwright's single biggest reliability win, copied deliberately. You do **not**
write `sleep`s:

```cyrius
var s = yantra_web_open("chromium");
yantra_navigate(s, url);          # waits for document.readyState
yantra_click(s, "#submit");       # waits for #submit to exist, then clicks
yantra_type(s, "#name", "alice"); # waits for #name, then types
```

When you genuinely want no-wait semantics (asserting something is *already*
absent, testing a race), use the explicit opt-out:

- `yantra_click_now(session, selector)` — click without the actionability wait.
- `yantra_tap_now(session, selector)` — the mobile equivalent.

Tune the open/connect retry (driver still starting, connection reset) with
`yantra_set_open_retry(attempts, backoff_ms)` (default 4 × 150ms linear backoff).

## Selectors

Selectors are plain strings. A small, kind-aware prefix scheme maps to the right
underlying strategy — the same string works across web and mobile where it makes
sense:

| Prefix | Strategy | Web | Mobile |
|--------|----------|-----|--------|
| `@id/<v>` | id | element id | Android resource-id |
| `~<v>` | accessibility id | — | iOS a11y label / Android content-desc |
| `/<xpath>` | xpath | xpath | xpath |
| `text:<v>` | text match | xpath `contains(text(), …)` | `-android uiautomator` |
| *(anything else)* | default | CSS selector | id |

Examples:

```cyrius
yantra_click(s, "#submit");            # CSS (web default)
yantra_click(s, "button[type=submit]"); # CSS
yantra_click(s, "/html/body/button");  # xpath
yantra_tap(m, "~Add");                 # iOS accessibility id / Android content-desc
yantra_tap(m, "@id/com.app:id/ok");    # Android resource-id
yantra_tap(m, "text:Settings");        # visible-text match
```

## Sharing a session across steps

A session handle is just an `i64`. Open once, thread it through every step, close
at the end — exactly like a Playwright `page` or an Appium `driver`:

```cyrius
fn test_checkout_flow() {
    var s = yantra_web_open("chrome");
    yantra_navigate(s, "https://shop.example/cart");
    yantra_click(s, "#checkout");
    yantra_type(s, "#card", "4242424242424242");
    yantra_click(s, "#pay");
    assert_streq(yantra_url(s), "https://shop.example/receipt", "reached receipt");
    yantra_close(s);
    return assert_summary();
}
```

Reading state mid-flow:

- `yantra_url(session)` — current URL.
- `yantra_eval_str(session, js)` / `yantra_eval_bool(session, js)` — evaluate JS
  in the page (web) and return a string / bool. Transport-agnostic.
- `yantra_mobile_source(session)` — the native UI hierarchy (UiAutomator2 XML /
  XCUITest source) for mobile sessions.

## Structured errors

Verbs return `0` on failure rather than aborting. After a `0`, ask what went
wrong:

- `yantra_last_error()` — a numeric code: `YANTRA_ERR_NULL`, `_BROWSER`,
  `_CONNECT`, `_SESSION`, `_NAV`, `_NO_ELEMENT`, `_ACTION`.
- `yantra_last_error_str()` — a human-readable message.

```cyrius
var s = yantra_web_open("firefox");
assert_nonnull(s, "open firefox session");
if (s == 0) {
    # e.g. geckodriver not running on :4444 — inspect the cause:
    #   yantra_last_error()      -> numeric code (YANTRA_ERR_CONNECT, …)
    #   yantra_last_error_str()  -> human-readable message
    return assert_summary();
}
```

Session IDs are opaque and internal state never leaks into these messages.

## Auto-teardown and resilience

The stdlib has no atexit hook, so yantra tracks open sessions in a registry and
gives you an explicit, leak-proof exit:

- `yantra_exit(code)` — close every open session, then exit. **Use this in place
  of `syscall(60, code)`** so a leaked browser/emulator is closed pass *or* fail.
- `yantra_teardown_all()` — close everything without exiting.
- `yantra_open_session_count()` — how many sessions are currently open.

```cyrius
var code = run_my_tests();
yantra_exit(code);
```

## Tracing

Wrap each action in a [sakshi](../development/state.md) span for a visible
timeline while debugging a flaky flow:

```cyrius
yantra_trace_enable(1);   # off by default; yantra_trace_enabled() reports state
```

## Running against the five backends

Your test body is backend-agnostic; only the opener changes. yantra's own e2e
suite ([`tests/e2e/`](../../tests/e2e/)) dogfoods this exact path against live
headless Chromium, chromedriver, geckodriver, WebKitWebDriver, an Android
emulator, and an iOS simulator — all gating in CI. Use those files as worked
references for each backend.

## See also

- [Migrating from Playwright](migrating-from-playwright.md)
- [Migrating from Appium](migrating-from-appium.md)
- [`docs/examples/`](../examples/) — runnable per-backend examples.
