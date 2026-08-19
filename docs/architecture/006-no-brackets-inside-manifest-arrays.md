# 006 — A bracketed token inside a `cyrius.cyml` array silently truncates it

> **Why** the `stdlib = [...]` array in `cyrius.cyml` carries a shouty `DO NOT`
> comment forbidding `[deps]`-shaped text *inside the array* — including inside
> comments. Recorded here because the failure is silent, the blast radius is
> large, and the obvious reading of the file gives no hint of it.

## The quirk

The cyml manifest parser scans for `[section]` headers **without stripping
comments first**. So a bracketed token written inside a comment that sits
*within* a multi-line array is read as the start of a new section, and the array
**terminates at that line**. Every entry below it is dropped. There is no
warning, no error, and no diagnostic — the manifest simply parses to something
smaller than what it says.

yantra hit the worst version of this. The `[deps] stdlib` array declared 27
leaves, with an explanatory comment in the middle:

```cyml
stdlib = [
    "syscalls", ..., "assert",          # 17 leaves above the comment
    # Transports the backends ride on. Consumers of dist/yantra.cyr get
    # these resolved from their own [deps] stdlib; listed here so the   <-- HERE
    # manifest documents the real graph.
    "net", "ws", "bayan", "sandhi", "tls",
    "dynlib", "fdlopen", "mmap", "sakshi", "sigil",   # 10 leaves NEVER PARSED
]
```

The `[deps]` on the marked line ended the array. cyrius saw **17 of 27** leaves.
The ten it never saw were the entire transport chain.

## What it broke — two symptoms, three releases apart, one cause

**1. `cyrius lib sync` appeared to need `--full`.** Plain sync vendors the
*declared* `[deps] stdlib` subset. Working from a truncated list, it faithfully
copied the 17 core leaves and skipped `net`/`ws`/`sandhi`/`sigil`/… — so a fresh
clone (vendored `lib/` is gitignored) failed the smoke build with
`cannot open include file: lib/sandhi.cyr`. This was misdiagnosed in 1.0.1 as a
6.4.x *wrapper* quirk and worked around by switching CI and the quick start to
`cyrius lib sync --full`. The wrapper was never at fault.

**2. `cyrius distlib` hard-failed on the 6.5.29 pin.** The bundle self-check
became real in cyrius **6.5.14** (before that it aborted with
`cannot write output: /dev/null` and downgraded everything to a note), and in
**6.5.17** it started compiling the bundle with the manifest's `[deps] stdlib`
prepended — the right question to ask. But prepending a *truncated* list left
three stdlib enums undefined, and unlike an undefined **function** (which
`--allow-undef` downgrades) an undefined **variable** is a parse-time abort that
`--allow-undef` cannot reach:

```
error: dist/yantra.cyr:223: undefined variable 'SIG_ALG_ED25519'   # sigil
error: dist/yantra.cyr:234: undefined variable 'SIG_ALG_HYBRID'    # sigil
error: dist/yantra.cyr:604: undefined variable 'WS_OPEN'           # ws
error: distlib: the generated bundle does not compile
```

The bundle was **not** defective. `dist/yantra.cyr` compiles and runs against a
hand-written consumer that includes the stdlib and then the bundle. Only the
manifest the check consulted was short.

## How it was pinned down

- Bisected across installed toolchains: **6.5.13 clean, 6.5.14 fails** — which
  dated the *symptom*, not the cause.
- `lib/ws.cyr` is byte-identical between the 6.5.1 and 6.5.29 snapshots, and
  `SIG_ALG_*` / `WS_OPEN` are defined identically in both. So the libs were not
  the regression.
- `dist/yantra.deps` (distlib's generated sidecar) listed exactly **17** leaves —
  precisely the entries above the comment.
- Decisive test: change the single token `[deps]` → plain prose *inside that
  comment*, changing nothing else. The parse moves **17 → 27** leaves and
  `distlib` passes.

## The rule

**Never write a `[...]` section-header shape inside a `cyrius.cyml` array — not
in a value, not in a trailing comment, not in a comment-only line.** Refer to
sections in prose ("the deps stdlib list"), or put the comment *outside* the
array. Trailing inline comments after an entry (`"net",  # sockets`) are fine as
long as they contain no brackets.

## Status

Fixed yantra-side in **1.0.3** by rewording the comment; the array now carries a
guard comment so it cannot regress silently. The underlying parser bug is
**upstream in cyrius** (confirmed present in 6.5.29) — comments should be
stripped before header scanning. Not yet filed: a standalone reproducer and
write-up are prepared. Until that fix ships, this rule stands for every
first-party `cyrius.cyml`, not just yantra's.

A sweep of all 125 first-party `cyrius.cyml` files found two other repos with the
same pattern in their `[deps] stdlib` array: **shakti** (actively broken — silently
drops `mmap`, `dynlib`, `fdlopen`, the exact trio its comment exists to explain)
and **bote** (latent — the comment sits below the last entry, so nothing is
dropped today, but any appended entry would vanish). Neither is fixed here.

Verification that the fix is real, not cosmetic: plain `cyrius lib sync` now
vendors 54 files and covers all ten transports; `cyrius distlib` reports
27 leaf requirements and writes `dist/yantra.cyr` v1.0.3 clean. CI keeps
`--full` as belt-and-braces.
