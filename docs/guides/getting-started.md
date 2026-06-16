# Getting started — your first yantra test

> From zero to a passing `.tcyr` browser test. yantra is a **library**, not a
> framework: you write a normal `.tcyr` file and run it with `cyrius test` — the
> runner you already have. No separate test runner, config file, or CI plugin
> (see [ADR 0001](../adr/0001-yantra-is-a-library-not-a-framework.md)).

## 1. Add yantra to your project

yantra ships as a single bundled file, `dist/yantra.cyr` (built with
`cyrius distlib`). A consumer vendors it as `lib/yantra.cyr` and includes it:

```cyrius
include "lib/yantra.cyr"
```

That one include pulls in the whole public surface — the web verbs, the mobile
verbs, auto-waiting, structured errors, and auto-teardown. The stdlib transports
yantra rides on (`net`, `ws`, `bayan`, `sandhi`, `tls`, `sakshi`) resolve from
your own `cyrius.cyml [deps] stdlib` list.

## 2. Start a target

yantra drives a *real* browser or device — it does not bundle one. For the first
test, run headless Chromium with the DevTools port open:

```bash
chromium --headless=new --remote-debugging-port=9222 about:blank &
```

`yantra_web_open("chromium")` connects to that port (9222 by default; override
with `yantra_web_set_cdp_port`).

## 3. Write the test

```cyrius
# tests/first.tcyr
include "lib/yantra.cyr"

fn test_navigate_and_read_title() {
    var s = yantra_web_open("chromium");

    yantra_navigate(s, "data:text/html,<title>hi</title><h1 id=greeting>hello</h1>");

    # Auto-waiting is implicit — yantra_eval_str waits for the page to be ready
    # and the element to exist before reading. No manual sleeps.
    assert_streq(yantra_eval_str(s, "document.getElementById('greeting').textContent"),
                 "hello", "h1 text");

    yantra_close(s);
    return assert_summary();
}

var code = test_navigate_and_read_title();
yantra_exit(code);   # tears down any leaked session, then exits
```

## 4. Run it

```bash
cyrius test tests/first.tcyr
```

That's the whole loop. The same `cyrius test` invocation that runs your unit
tests runs your browser tests — they're just `.tcyr` files.

## What just happened

- **`yantra_web_open("chromium")`** opened a CDP session against the running
  browser and returned a session handle (an `i64` you pass to every other verb).
- **`yantra_navigate`** drove the page and waited for `document.readyState`.
- **`yantra_eval_str`** evaluated JavaScript in the page and returned a string —
  the transport-agnostic `page.evaluate` analog (there's also
  `yantra_eval_bool`).
- **`yantra_exit`** closed the session and exited. Use it in place of
  `syscall(60, code)` so a browser leaked by a failing assertion still gets
  closed (the stdlib has no atexit hook — see
  [auto-teardown](writing-e2e-tests.md#auto-teardown-and-resilience)).

## Switching backends

The opener is the only thing that changes per backend. Everything downstream —
`navigate`, `click`, `type`, `eval`, `close`, auto-waiting — is shared:

| Call | Target | Default port |
|------|--------|--------------|
| `yantra_web_open("chromium")` | headless/headed Chromium over CDP | 9222 |
| `yantra_web_open("chrome")` | chromedriver (W3C WebDriver) | 9515 |
| `yantra_web_open("firefox")` | geckodriver | 4444 |
| `yantra_web_open("webkit")` | WebKitWebDriver (WebKitGTK) | 4444 |
| `yantra_web_open("safari")` | safaridriver (`sudo safaridriver --enable`) | 4445 |
| `yantra_mobile_open("android", "<pkg>")` | Appium → UiAutomator2 | 4723 |
| `yantra_mobile_open("ios", "<bundleId>")` | Appium → XCUITest | 4723 |

Override any port before opening: `yantra_web_set_wd_port(p)` (WebDriver),
`yantra_web_set_cdp_port(p)` (CDP), `yantra_mobile_set_port(p)` (Appium).

## Next

- [Writing E2E tests](writing-e2e-tests.md) — auto-waiting, selector strategies,
  session sharing, error handling, teardown.
- [Migrating from Playwright](migrating-from-playwright.md) /
  [from Appium](migrating-from-appium.md) — verb-by-verb translation.
- [`docs/examples/`](../examples/) — one runnable example per backend.
