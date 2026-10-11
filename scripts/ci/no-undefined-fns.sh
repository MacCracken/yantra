#!/usr/bin/env bash
# scripts/ci/no-undefined-fns.sh — every test, bench, fuzz harness and program
# builds without an `undefined function` warning.
#
# WHY: cyrius refuses an undefined function that a path REACHES, but one that no
# path reaches is only a warning, so a file whose include list misses a module
# still builds rc 0 and its tests still pass. Through 1.0.9, nine tests and
# programs/benchmarks.cyr included src/web.cyr / src/mobile.cyr without
# src/security.cyr, and every build of them printed
#   warning: undefined function 'yantra_tls_pin_verify_ed25519'
#   warning: undefined function 'yantra_tls_pin_verify_hybrid'
# A standing warning of the same shape as a real one trains readers to skip it.
#
# Each file is built the way `cyrius test` / `cyrius build` build it (the
# `[deps] stdlib` prepend). Run from the repo root after `cyrius lib sync --full`
# and `cyrius distlib` (tests/yantra_raw_include.tcyr includes dist/yantra.cyr).
set -euo pipefail

# The files present at 1.0.10 (16 under tests/, 3 programs). The floor fails a
# find that matches nothing instead of passing it silently.
FLOOR=19

mkdir -p build
out=build/no-undefined-fns
n=0
bad=0
for f in $(find tests programs -type f \( -name '*.tcyr' -o -name '*.bcyr' -o -name '*.fcyr' -o -name '*.cyr' \) | sort); do
  n=$((n + 1))
  if ! cyrius build "$f" "$out" > /dev/null 2> "$out.err"; then
    echo "FAIL $f: does not build"
    cat "$out.err"
    bad=1
    continue
  fi
  if grep -q "undefined function" "$out.err"; then
    echo "FAIL $f:"
    grep "undefined function" "$out.err"
    bad=1
  fi
done
rm -f "$out" "$out.err"

if [ "$n" -lt "$FLOOR" ]; then
  echo "FAIL: $n files found under tests/ and programs/ (floor $FLOOR)"
  exit 1
fi
if [ "$bad" -ne 0 ]; then
  exit 1
fi
echo "ok: $n files build without an undefined function"
