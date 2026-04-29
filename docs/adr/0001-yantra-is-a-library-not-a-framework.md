# 0001 — yantra is a library, not a framework

**Status**: Accepted
**Date**: 2026-04-23

> **Headline thesis**: *"Every other language draws the line before what you can see. Cyrius draws it after."* UI automation is the visible-surface tier of the testing pyramid, and every mainstream language — Rust, Go, Zig, Swift, Python, JS — draws its language boundary short of it. Selenium, Playwright, Appium, Cypress, Puppeteer are all third-party ecosystems precisely because their host languages stop before the pixel surface. yantra exists because Cyrius doesn't stop there. See [design-patterns.md §0 Refusal as Architecture](https://github.com/MacCracken/agnosticos/blob/main/docs/design-patterns.md#0-refusal-as-architecture--the-master-frame) for the generalized pattern this ADR instantiates.

## Context

Every mainstream UI-automation tool — Selenium, Playwright, Cypress, Appium, Maestro, WebdriverIO — ships as a *framework*: it brings its own test runner, its own config schema, its own CI integration, its own reporter, its own assertion DSL, and usually its own command-line entry point. A team adopting any of them is adopting a whole ecosystem around their actual tests.

Cyrius already ships a test harness. `cyrius test` runs `.tcyr` files. `cyrius bench` runs `.bcyr` files. `cyrius fuzz` runs `.fcyr` files. Assertions, test discovery, exit codes, CI integration — all already solved by the Cyrius toolchain every AGNOS project already uses.

The question facing yantra was: does yantra follow the incumbent framework pattern (its own runner, its own `.ycyr` format, its own config), or does it deliver the automation *capability* as a library that existing `.tcyr` files import?

## Decision

**yantra is a library.** It exports verbs (`yantra_web_open`, `yantra_navigate`, `yantra_click`, `yantra_type`, `yantra_mobile_open`, `yantra_tap`, etc.) that a normal `.tcyr` file includes and calls. `cyrius test` runs the result. No yantra test runner. No yantra config file. No yantra-specific CI plugin.

The same decision applies transitively: yantra does not ship its own assertion DSL (Cyrius has `assert_eq`, `assert_streq`, `assert_summary`), its own logging format (sakshi exists), its own HTTPS verification (sigil exists), or its own reporter (the existing `.tcyr` exit-code contract is sufficient).

## Consequences

- **Positive**
  - A team adopting yantra adds one dep, not an ecosystem. If they already run `cyrius test` in CI, they already run yantra's tests in CI.
  - yantra's own surface area stays small — library code, no runner, no config parser, no reporter. Less to maintain, less to secure.
  - `.tcyr` test files are portable across yantra versions. Upgrading yantra is a manifest change; it does not break the runner contract.
  - Consumers pick which parts to use via normal Cyrius DCE. A test that only uses `yantra_web_open` does not pay for the mobile backends.
- **Negative**
  - No yantra-branded reporter. Teams that want HTML dashboards / Allure-style reports build them outside yantra.
  - No yantra-branded config schema. Teams that want declarative test shapes do it in Cyrius code, not in YAML / JSON / TOML.
  - Selenium / Playwright migration stories are harder to write because the shape is more different than a port-the-framework story would be.
- **Neutral**
  - The boundary between "library concern" and "runner concern" becomes a recurring design question as yantra grows. Every feature proposal has to pass the "would this work as a function you import?" test.

## Alternatives considered

- **Ship a yantra test runner (`cyrius yantra-test` or a `yrun` binary).** Gives us control over reporting, retries, and parallel-session orchestration. Rejected — duplicates work Cyrius already does, splits the AGNOS testing story across two runners, and adds ecosystem surface for no structural win.
- **Ship a new file format (`.ycyr` for yantra tests).** Would let us enforce yantra-specific conventions at the parser level. Rejected — a new file format is a framework in disguise, and the conventions it would enforce (auto-waiting, session teardown, backend selection) are library concerns expressible as functions.
- **Bind to Playwright or Selenium via Cyrius FFI.** The fastest path to working-today. Rejected on the same grounds as [mabda's wgpu policy](https://github.com/MacCracken/agnosticos/blob/main/docs/articles/why-gpu-belongs-in-the-stdlib.md): FFI bridges to incumbent ecosystems reintroduce the dep chains AGNOS otherwise refuses. Unlike mabda's wgpu exception (temporary, scoped, closing), there is no "native path pending" story for yantra — the whole point is that the native path is the scaffolded path from day one.
- **Port Playwright's API surface to Cyrius.** Gives consumers a familiar shape. Rejected — "reference don't mimic." Playwright's auto-waiting decision is worth inheriting; its chained-builder DSL and node-module-shaped API are not.
