#!/usr/bin/env bash
# bench-history.sh — run yantra's benchmarks and append normalized results
# to bench-history.csv. Matches the AGNOS bench-history convention: one row
# per benchmark per run, keyed by UTC timestamp + git short-sha, with all
# times normalized to nanoseconds so the CSV is directly plottable.
#
# Usage:
#   scripts/bench-history.sh [bench-file]   # default: tests/yantra.bcyr
#
# Env:
#   BENCH_HISTORY_CSV   output CSV path (default: bench-history.csv)
set -euo pipefail

BENCH_FILE="${1:-tests/yantra.bcyr}"
CSV="${BENCH_HISTORY_CSV:-bench-history.csv}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"

if [ ! -f "$CSV" ]; then
  echo "timestamp,commit,benchmark,avg_ns,min_ns,max_ns,iters" > "$CSV"
fi

# bench output lines look like:
#   session_kind: 5ns avg (min=5ns max=6ns) [5000000 iters]
cyrius bench "$BENCH_FILE" 2>/dev/null | awk -v ts="$TS" -v sha="$SHA" '
  function to_ns(v,   n,u) {
    n = v + 0; u = v; sub(/^[0-9.]+/, "", u)
    if (u == "us") return n * 1000
    if (u == "ms") return n * 1000000
    if (u == "s")  return n * 1000000000
    return n   # ns or unitless
  }
  /avg .min=.*max=.* iters./ {
    name = $1; sub(/:$/, "", name)
    avg = $2
    match($0, /min=[^ ]+/);  mn = substr($0, RSTART+4, RLENGTH-4)
    match($0, /max=[^)]+/);  mx = substr($0, RSTART+4, RLENGTH-4)
    match($0, /\[[0-9]+/);   it = substr($0, RSTART+1, RLENGTH-1)
    printf "%s,%s,%s,%d,%d,%d,%s\n", ts, sha, name, to_ns(avg), to_ns(mn), to_ns(mx), it
  }
' | tee -a "$CSV"

echo "appended results to $CSV"
