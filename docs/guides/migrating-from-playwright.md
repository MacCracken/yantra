# Migrating from Playwright

> A verb-by-verb translation cookbook for teams moving web E2E tests from
> Playwright to yantra. yantra deliberately copies Playwright's best decision
> (auto-waiting) and refuses the rest of the framework — there's no separate
> runner, no `expect().toBe()` DSL, no page-object machinery. You write a `.tcyr`
> and run `cyrius test`.

## Mental model

| Playwright | yantra |
|------------|--------|
| `browser` + `page` objects | a single session handle (`i64`) |
| `playwright test` runner / config | `cyrius test` — no extra runner |
| `expect(...)` matchers | plain `assert_*` from the stdlib |
| locators / `page.locator(...)` | selector strings passed to each verb |
| actionability auto-wait | built in to every action verb |
| browser auto-download | bring your own browser/driver (a target on a port) |

## Setup

```js
// Playwright
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage();
```

```cyrius
# yantra — connects to a running Chromium DevTools port (default 9222),
# or a chromedriver/geckodriver/webkitwebdriver/safaridriver.
var s = yantra_web_open("chromium");
```

Playwright manages browser binaries; yantra drives a browser/driver you start
(`chromium --headless=new --remote-debugging-port=9222`, or `chromedriver`,
etc.). That's the "own the transport, bring the target" trade.

## Actions

| Playwright | yantra |
|------------|--------|
| `await page.goto(url)` | `yantra_navigate(s, url)` |
| `await page.click(sel)` | `yantra_click(s, sel)` |
| `await page.fill(sel, text)` | `yantra_type(s, sel, text)` |
| `await page.locator(sel).click()` | `yantra_click(s, sel)` |
| `await page.click(sel, {force:true})` | `yantra_click_now(s, sel)` (no actionability wait) |
| `page.url()` | `yantra_url(s)` |
| `await page.evaluate(js)` → string | `yantra_eval_str(s, js)` |
| `await page.evaluate(js)` → bool | `yantra_eval_bool(s, js)` |
| `await browser.close()` | `yantra_close(s)` |

## Selectors

Playwright's CSS/text/xpath engines map onto yantra's prefix scheme:

| Playwright | yantra |
|------------|--------|
| `page.click("#id")` (CSS) | `yantra_click(s, "#id")` (CSS is the web default) |
| `page.click("xpath=//button")` | `yantra_click(s, "/button")` (`/` → xpath) |
| `page.getByText("Save")` | `yantra_click(s, "text:Save")` |
| `page.getByTestId(...)` | use the CSS attribute selector, e.g. `[data-testid=…]` |

## Assertions

Playwright's auto-retrying `expect` becomes a read + a stdlib assert. Because the
*action* already auto-waited, the state is settled by the time you assert:

```js
// Playwright
await expect(page).toHaveURL("https://example.com/dashboard");
```

```cyrius
# yantra
assert_streq(yantra_url(s), "https://example.com/dashboard", "redirect");
```

```js
await expect(page.locator("#flash")).toHaveText("Saved");
```

```cyrius
assert_streq(yantra_eval_str(s, "document.querySelector('#flash').textContent"),
             "Saved", "flash message");
```

## A full test, side by side

```js
// Playwright
test('login redirects', async ({ page }) => {
  await page.goto('https://example.com/login');
  await page.fill('#username', 'alice');
  await page.fill('#password', 'secret');
  await page.click('button[type=submit]');
  await expect(page).toHaveURL('https://example.com/dashboard');
});
```

```cyrius
# yantra — examples/web-consumer/login.tcyr
include "lib/yantra.cyr"

fn test_login_redirects() {
    var s = yantra_web_open("chromium");
    yantra_navigate(s, "https://example.com/login");
    yantra_type(s, "#username", "alice");
    yantra_type(s, "#password", "secret");
    yantra_click(s, "button[type=submit]");
    assert_streq(yantra_url(s), "https://example.com/dashboard", "redirect");
    yantra_close(s);
    return assert_summary();
}

var code = test_login_redirects();
yantra_exit(code);
```

## What has no direct analog (on purpose)

- **Fixtures / `test.beforeEach`** — it's a plain function; call your setup
  helper at the top. No fixture-injection magic.
- **`page` auto-created per test** — open the session yourself; share it across
  steps. `yantra_exit` is the leak-proof teardown.
- **Tracing/video** — yantra has `yantra_trace_enable(1)` (sakshi spans); rich
  artifacts are out of scope for the library.
- **Network interception / `page.route`** — not provided; yantra is a UI-driver,
  not a proxy.

## See also

- [Writing E2E tests](writing-e2e-tests.md) for the full verb surface.
- [Migrating from Appium](migrating-from-appium.md) for the mobile side.
