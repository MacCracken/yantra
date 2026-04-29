# yantra — Claude Code Instructions

> **Core rule**: this file is **preferences, process, and procedures** —
> durable rules that change rarely. Volatile state (current version,
> module line counts, supported backends, test/smoke surface, consumers)
> lives in [`docs/development/state.md`](docs/development/state.md).
> Do not inline state here.

## Project Identity

**yantra** (Sanskrit यन्त्र — *instrument, device, automation machine*) — a Cyrius library that lets `.tcyr` test files drive browsers and mobile devices.

- **Type**: Library
- **License**: GPL-3.0-only
- **Language**: Cyrius (toolchain pinned in `cyrius.cyml [package].cyrius`)
- **Version**: `VERSION` at the project root is the source of truth
- **Genesis repo**: [agnosticos](https://github.com/MacCracken/agnosticos)
- **Standards**: [First-Party Standards](https://github.com/MacCracken/agnosticos/blob/main/docs/development/applications/first-party-standards.md) · [First-Party Documentation](https://github.com/MacCracken/agnosticos/blob/main/docs/development/applications/first-party-documentation.md)

## Goal

Let `.tcyr` files drive browsers and mobile devices. `cyrius test` stays the runner. yantra is the library that gives test files the verbs to do UI automation — `yantra_web_open`, `yantra_navigate`, `yantra_click`, `yantra_mobile_open`, `yantra_tap`, etc.

yantra is **not a test framework.** The refusal is of the ecosystem pattern (Selenium / Playwright / Appium — separate framework, separate runner, separate CI path), not of the testing activity. See [ADR 0001](docs/adr/0001-yantra-is-a-library-not-a-framework.md).

## Current State

> Volatile state — current version, module line counts, supported
> backends (Chromium CDP, Firefox WebDriver, Android UiAutomator2,
> iOS XCUITest), known-working versions, dep-gap status
> (HTTP + WebSocket transports), consumers — lives in
> [`docs/development/state.md`](docs/development/state.md).

This file (`CLAUDE.md`) is durable rules.

## Scaffolding

Project was scaffolded with `cyrius init yantra`. **Do not manually create project structure** — use the tools. If the tools are missing something, fix the tools.

## Quick Start

```bash
cyrius deps                                          # resolve sibling deps
cyrius build src/main.cyr build/yantra               # build
cyrius test src/test.cyr                             # unit tests
cyrius lint src/*.cyr                                # static checks
CYRIUS_DCE=1 cyrius build src/main.cyr build/yantra  # release-parity build
```

## Architecture

Module responsibilities (file list in `state.md`):

- **`src/main.cyr`** — Session / Selector / Action / Assertion primitives shared across backends. Dispatch to the right protocol implementation
- **`src/web.cyr`** — browser automation public API
- **`src/mobile.cyr`** — mobile automation public API
- **`src/protocol/cdp.cyr`** — Chrome DevTools Protocol (WebSocket frames + JSON message pump)
- **`src/protocol/webdriver.cyr`** — W3C WebDriver JSON wire protocol
- **`src/protocol/appium.cyr`** — Appium JSON-RPC dialect (UiAutomator2 + XCUITest drivers)

Backend selection happens in `web.cyr` / `mobile.cyr`; protocol code never escapes the `protocol/` directory. If a new transport lands (BiDi, CDP v2, future Appium), it's a new file under `protocol/`, not a rewrite of the public surface.

## Key Constraints

- **yantra is a library.** Consumers write normal `.tcyr` tests. yantra never ships a runner, a config file, or a CI plugin. `cyrius test` is sufficient.
- **Public API is Cyrius-idiomatic, not Selenium-idiomatic.** Function names follow Cyrius conventions (`yantra_<noun>_<verb>` or `yantra_<verb>`). Selectors are strings. No classes, no chained builders, no `expect().toBe()` DSL
- **One Session struct per backend.** Browser and mobile sessions are different types but share the core primitives (Selector, Action, WaitCondition). Consumers switch backends by calling a different constructor, not by recompiling
- **Auto-waiting is the default.** Every action has an implicit wait for element-actionable (Playwright-style), killing most flaky-test failure modes at the source. `yantra_click_now` is the opt-out for the rare case consumers want no-wait semantics
- **No FFI.** All transports are first-party Cyrius — JSON, HTTP, WebSocket implemented in-tree or via sibling crates. The whole point is refusing the wgpu-shape "borrow the incumbent" pattern
- **Auto-teardown on test exit.** Sessions register a `syscall(60)` hook so leaked browsers / emulator processes get closed when the test exits, pass or fail

## Development Process

### Work Loop

1. Pick the next item from `ROADMAP.md` (or the scaffold plan if no roadmap yet)
2. Implement behind the stubs — each protocol module can fill in independently
3. `cyrius build` → `cyrius test`
4. Write or update the behavioral test in `tests/*.tcyr` — the library's own tests use yantra against a headless target
5. Update `CHANGELOG.md`
6. Update `docs/development/state.md` if supported backends, dep gaps, or consumer list changed

### Security Hardening (before release)

- WebDriver / Appium endpoints authenticate via sigil-verified HTTPS certs
- No shell-out for anything yantra does — process spawning uses `execve` with explicit argv (the same rule owl enforces for git-diff)
- Session IDs are opaque to yantra consumers; internal state never leaks into error messages
- Audit findings filed in `docs/audit/YYYY-MM-DD-audit.md`

### Closeout Pass (before minor/major bump)

1. Full test suite — all `.tcyr` green
2. `cyrius lint src/*.cyr` — no unaddressed findings
3. Run the library's own E2E suite against live headless targets (Chromium / Android emulator) before tagging
4. Version triple (`VERSION`, `cyrius.cyml`, CHANGELOG header) in sync
5. `state.md` current — supported backends, dep-gap status, consumer list all match reality

## Key Principles

- **`.tcyr` is enough.** Don't invent a new file format, don't wrap `cyrius test`, don't ship a config schema. The runner is already shipped
- **Library, not framework.** Every time an abstraction wants to become a framework, push it back to library shape
- **Auto-waiting over assertions.** Playwright's biggest win was "actions wait for the element to be actionable." Copy that specific decision; refuse the rest of the framework
- **Own the transport.** Every transport (HTTP, WebSocket, JSON) is first-party Cyrius. If stdlib doesn't have it yet, sibling-crate it with a git+tag pin
- **Reference don't mimic.** Selenium's object model is 20 years old and carries twenty years of CSS-selector / XPath / `findElementBy*` accretion. WebDriver's JSON wire protocol is worth inheriting; `findElementBy...()`-style API surface is not
- **Benchmark against incumbents.** When the native path is live, every consumer operation yantra supports gets timed against the same operation on Playwright / Appium on representative workloads

## Rules (Hard Constraints)

- **Read the genesis repo's CLAUDE.md first** — [agnosticos/CLAUDE.md](https://github.com/MacCracken/agnosticos/blob/main/CLAUDE.md)
- **Do not commit or push** — the user handles all git operations
- **NEVER use `gh` CLI** — use `curl` to the GitHub API if needed
- **Do not add FFI dependencies.** No `libcurl`, no `libwebsockets`, no platform-specific C bindings. If yantra needs a transport, the transport is Cyrius or a sibling Cyrius crate
- **Do not ship a custom test runner.** `cyrius test` is the runner. yantra is a library
- **Do not inline volatile state in this file** — that belongs in `docs/development/state.md`
- Do not bypass `cyrius build` with raw `cc5` invocations
- Do not hardcode toolchain versions outside `cyrius.cyml`

## Cyrius Conventions

- `var buf[N]` is N **bytes**, not N elements
- `&&` / `||` short-circuit; mixed in one expression requires parens
- No closures — use named functions
- No negative literals — write `(0 - N)`
- `break` in `while` loops with `var` declarations is unreliable — use flag + `continue`
- Test exit pattern: `syscall(60, assert_summary())`
- All struct fields are 8-byte slots unless explicitly packed

## CI / Release

- **Toolchain pin** — `cyrius.cyml [package].cyrius` is the only authority. **Never** create a `.cyrius-toolchain` file
- **E2E CI matrix** — when backends land, CI runs yantra's own suite against each: Chromium (headless), Firefox (headless), Android emulator, iOS simulator
- **Release artifacts** (planned): source tarball, bundled `dist/yantra.cyr` via `cyrius distlib`, SHA256SUMS
- **State sync** — release post-hook bumps `docs/development/state.md`. Until automated, update by hand at every tag

## Docs

- [`docs/adr/`](docs/adr/) — architecture decision records. *Why did we choose X over Y?* (Start with ADR 0001: library-not-framework thesis.)
- [`docs/architecture/`](docs/architecture/) — non-obvious constraints and quirks
- [`docs/guides/`](docs/guides/) — task-oriented how-tos (writing your first `.tcyr` E2E test)
- [`docs/examples/`](docs/examples/) — runnable `.tcyr` examples per backend
- [`docs/development/roadmap.md`](docs/development/roadmap.md) — completed, backlog, future, v1.0 criteria
- [`docs/development/state.md`](docs/development/state.md) — live state snapshot, refreshed every release
- [`CHANGELOG.md`](CHANGELOG.md) — source of truth for all changes

New quirks and constraints land in `docs/architecture/` as numbered items (`NNN-kebab-case.md`). New decisions land in `docs/adr/` using [`template.md`](docs/adr/template.md). **Never renumber either series.**

## CHANGELOG Format

Follow [Keep a Changelog](https://keepachangelog.com/). Behavior changes (new verbs, new backends, new protocol support) get a dated section. Breaking changes get a **Breaking** section with migration guide. Security fixes get a **Security** section with CVE references where applicable.
