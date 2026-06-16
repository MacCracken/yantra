# yantra guides

Task-oriented how-tos for writing UI automation as `.tcyr` tests. yantra is a
**library** — you write a normal test file and run it with `cyrius test`, the
runner you already have (see [ADR 0001](../adr/0001-yantra-is-a-library-not-a-framework.md)).

| Guide | What it covers |
|-------|----------------|
| [Getting started](getting-started.md) | Zero to a passing Chromium `.tcyr` test |
| [Writing E2E tests](writing-e2e-tests.md) | Auto-waiting, selectors, session sharing, errors, teardown |
| [Migrating from Playwright](migrating-from-playwright.md) | Verb-by-verb web translation cookbook |
| [Migrating from Appium](migrating-from-appium.md) | Verb-by-verb mobile translation cookbook |

Runnable examples per backend live in [`../examples/`](../examples/).
