# Contributing to yantra

yantra is a Cyrius **library** that gives `.tcyr` test files the verbs to
drive browsers and mobile devices. `cyrius test` stays the runner — yantra
never ships its own runner, config schema, or CI plugin. Keep that shape:
every time an abstraction wants to become a framework, push it back to
library shape. See [ADR 0001](docs/adr/0001-yantra-is-a-library-not-a-framework.md).

## Setup

```bash
cyrius lib sync        # sync vendored lib/ to the pin in cyrius.cyml
```

The toolchain version is pinned in `cyrius.cyml [package].cyrius`. Never
create a `.cyrius-toolchain` file and never hardcode the version elsewhere.

## Work loop

1. Pick the next item from [`docs/development/roadmap.md`](docs/development/roadmap.md).
2. Implement behind the stubs — each protocol module fills in independently.
3. `cyrius build programs/smoke.cyr build/yantra-smoke` → `cyrius test tests/yantra.tcyr`.
4. Add/update the behavioral test in `tests/*.tcyr`.
5. Update [`CHANGELOG.md`](CHANGELOG.md).
6. Update [`docs/development/state.md`](docs/development/state.md) if backends,
   dep gaps, or consumers changed.

## Quality gates (must pass before review)

```bash
cyrius test tests/yantra.tcyr     # all green
cyrius lint src/main.cyr          # no unaddressed findings
cyrius fmt src/main.cyr --check   # formatted
cyrius bench tests/yantra.bcyr    # benchmarks run
cyrius distlib                    # bundle builds clean
```

CI runs the same gates (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)).
Performance-relevant changes should run `scripts/bench-history.sh` and note
the numbers — never skip benchmarks for performance claims.

## Conventions

- Public API is **Cyrius-idiomatic**, not Selenium-idiomatic:
  `yantra_<noun>_<verb>` / `yantra_<verb>`, string selectors, no chained
  builders, no `expect().toBe()` DSL.
- **No FFI** for yantra's own code — transports are first-party Cyrius.
- **Auto-waiting is the default**; `yantra_<verb>_now` is the opt-out.
- Cyrius gotchas: `var buf[N]` is N **bytes**; no closures (use named
  functions); no negative literals (write `(0 - N)`); parenthesize mixed
  `&&`/`||`. See [CLAUDE.md](CLAUDE.md) for the full list.

## Pull requests

- Branch from `main`; keep PRs scoped to one roadmap item where possible.
- Include the CHANGELOG entry and any `state.md` update in the same PR.
- New quirks → `docs/architecture/NNN-*.md`; new decisions →
  `docs/adr/` from `template.md`. **Never renumber either series.**

## License

By contributing you agree your contributions are licensed under
**GPL-3.0-only**, matching the project ([LICENSE](LICENSE)).
