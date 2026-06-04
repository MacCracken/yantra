# Architecture notes

Non-obvious constraints, quirks, and invariants that a reader cannot derive from the code alone. Numbered chronologically — never renumber.

Not decisions (those live in [`../adr/`](../adr/)) and not guides (those live in [`../guides/`](../guides/)). An item here describes *how the world is*, not *what we chose* or *how to do something*.

## Items

- [001 — Chromium's DevTools HTTP endpoint requires HTTP/1.1](001-chromium-devtools-requires-http11.md) — why the CDP backend rolls its own discovery GET instead of using stdlib `http_get`.
