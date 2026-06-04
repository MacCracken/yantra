# 002 — The WebDriver backend uses its own HTTP client, not `sandhi`

> **RESOLVED in 0.4.0 (2026-06-03).** sandhi **1.4.1** fixed the close-path
> drain described below, so `src/protocol/webdriver.cyr` was migrated onto
> sandhi's WebDriver RPC dialect (`sandhi_wd_*`) and no longer ships its own
> HTTP client. The history below is kept for the record. M3 (Appium) rides the
> same sandhi layer (`sandhi_wd_*` + `sandhi_ap_*`). The CDP backend still uses
> its own one-shot discovery GET (architecture 001) — unrelated and unaffected.

---

**Original constraint (0.3.0).** `src/protocol/webdriver.cyr` did **not** use the
stdlib `sandhi` HTTP client, even though `sandhi` is the full-featured HTTP/1.1+2
client (POST, headers, HTTPS) and is the obvious choice for a WebDriver wire.
It rolled its own minimal Content-Length-framed HTTP/1.1 client over `net.cyr`
(`_wd_request`). This was non-obvious — `sandhi` was *right there* — so it was
recorded here.

## Why

`sandhi`'s default `Connection: close` request path reads the response by
**draining the socket until EOF** and only then frames/parses it
(`_sandhi_http_exchange_a` → `sandhi_conn_recv_all_deadline`). Chromium-family
WebDriver/debug servers — **chromedriver** and Chromium's own DevTools HTTP
endpoint — send a complete, `Content-Length`-framed response with
`Connection: close` but then **keep the socket open**. So `sandhi` blocks until
its read deadline and returns `SANDHI_ERR_TIMEOUT`, discarding the full response
it already buffered. Verified directly: a `sandhi_http_get` to chromedriver's
`/status` times out; `curl` (which frames by Content-Length) succeeds.

This is the same server quirk that made the CDP backend roll its own discovery
GET (see [001](001-chromium-devtools-requires-http11.md)). The two backends now
share the pattern: a small purpose-built HTTP/1.1 client that **stops reading
once `Content-Length` bytes have arrived** (with a recv-timeout backstop), so it
never waits for an EOF the server won't send. It also tolerates headers with no
space after the colon (`Content-Length:249`), which the chromium family emits.

## Status / exit criteria

Filed as a sandhi-side bug:
`sandhi/docs/issues/2026-06-03-http-close-path-drains-until-eof.md` (the
framed-recv logic already exists on sandhi's keep-alive path; the close path
should share it). Once sandhi frames the close path by Content-Length, yantra
should switch the WebDriver transport (and the M3/M4 Appium transport) to
`sandhi` — it is otherwise exactly the right client (HTTPS, auth, pooling,
retry), which matters for non-localhost Appium grids. Until then, the in-tree
client is correct and dependency-light (`net` + `json`, no TLS).

## Scope

Localhost WebDriver/Appium is plain HTTP, so no TLS is involved and the minimal
client suffices. If/when yantra talks to a remote WebDriver grid over HTTPS, the
`sandhi` adoption above becomes the path (it carries the TLS stack), not an
expansion of this in-tree client.
