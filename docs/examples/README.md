# yantra examples

Runnable `.tcyr` examples per backend. Consumers drive these with the
**same `cyrius test` runner** they already use — yantra ships no separate
runner, config schema, or CI plugin (see [ADR 0001](../adr/0001-yantra-is-a-library-not-a-framework.md)).

| Example | Backend | Status |
|---------|---------|--------|
| [`examples/web-consumer/login.tcyr`](../../examples/web-consumer/login.tcyr) | Chromium (CDP) | scaffold — runnable at M1 |

> Examples track the public API surface as each backend lands. Until the
> M1 Chromium/CDP backend ships, the files document the target verbs and
> are not yet runnable end-to-end. See [`../development/roadmap.md`](../development/roadmap.md).

## How a consumer uses yantra

1. Add yantra as a dependency; `cyrius deps` vendors `dist/yantra.cyr` as `lib/yantra.cyr`.
2. `include "lib/yantra.cyr"` in a `.tcyr` test.
3. Call the verbs (`yantra_web_open`, `yantra_navigate`, `yantra_click`, …).
4. Run `cyrius test path/to/test.tcyr`. Same assertions, same runner.

yantra's own E2E suite ([`tests/e2e/`](../../tests/e2e/)) dogfoods this exact path against live headless targets.
