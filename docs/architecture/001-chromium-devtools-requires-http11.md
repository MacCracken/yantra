# 001 — Chromium's DevTools HTTP endpoint requires HTTP/1.1

**Constraint.** The CDP backend (`src/protocol/cdp.cyr`) does **not** use the
stdlib `http_get` for target discovery (`GET /json`). It issues its own
request over `net.cyr` instead. The reason is non-obvious and cost real
debugging time, so it is recorded here.

## What's going on

`cyrius` stdlib `lib/http.cyr` sends **HTTP/1.0** requests
(`_http_build_request` emits `... HTTP/1.0\r\nHost: ...\r\nConnection: close`).
Chromium's built-in DevTools HTTP server **silently rejects HTTP/1.0**: it
accepts the connection, sends nothing, and closes. Verified directly against
Chromium 148:

- `GET /json HTTP/1.0` → connection succeeds, `0` bytes returned, clean close.
- `GET /json HTTP/1.1` → `HTTP/1.1 200 OK`, `Content-Length: 964`, body served,
  then closed (because we send `Connection: close`).

Because `http_get` reads until EOF and Chromium-on-1.0 closes with no body, the
naïve path *looks* like it works (no error) but yields an empty body — and on
some builds blocks instead. Either way, discovery fails.

## What the code does

`_cdp_http_get(port, path)` in `src/protocol/cdp.cyr`:

1. opens a TCP socket, sets a 5s recv timeout (`sock_set_recv_timeout`),
2. sends `GET <path> HTTP/1.1\r\nHost: 127.0.0.1:<port>\r\nConnection: close\r\n\r\n`,
3. reads until EOF (guaranteed to terminate by `Connection: close` + the recv
   timeout backstop),
4. returns the body after the `\r\n\r\n` header terminator.

CDP commands after discovery ride `lib/ws.cyr` and have no HTTP dependency, so
this is the *only* place yantra speaks HTTP for the Chromium backend.

## Implication for the roadmap

This is unrelated to the M2–M4 `http.cyr` POST/headers gap. That gap blocks
WebDriver/Appium (which need POST + JSON bodies). M1 only needs a GET, and once
the HTTP/1.1 requirement is met a hand-rolled GET is trivial — which is why M1
shipped ahead of the `http.cyr` depth work.
