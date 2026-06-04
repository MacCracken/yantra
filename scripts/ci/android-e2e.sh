#!/usr/bin/env bash
# scripts/ci/android-e2e.sh — the Android e2e body for the CI emulator job.
#
# WHY a separate script: reactivecircus/android-emulator-runner runs its
# `script:` input line-by-line as independent `sh -c "<line>"` invocations, so a
# backgrounded `appium &` would die with its line's shell and a multi-line
# `for … do … done` breaks ("end of file unexpected"). Invoking THIS file as a
# single line (`bash scripts/ci/android-e2e.sh`) runs everything in one shell,
# so backgrounding + the wait loop work normally.
#
# Runs from the workspace root (the emulator-runner's CWD). cyrius is on PATH
# via setup-cyrius; appium via setup-node's global bin — both prepended
# defensively below.
set -euo pipefail

# Prepend the npm global bin (appium) and ~/.cyrius/bin (cyrius). Compute the
# npm prefix tolerantly so a missing npm can't abort the script under `set -e`.
NPM_PREFIX="$(npm config get prefix 2>/dev/null || true)"
[ -n "$NPM_PREFIX" ] && export PATH="$NPM_PREFIX/bin:$PATH"
export PATH="$HOME/.cyrius/bin:$PATH"

appium --port 4723 --log-level error >/tmp/appium.log 2>&1 &
for i in $(seq 1 30); do
  curl -sf http://127.0.0.1:4723/status >/dev/null 2>&1 && break
  sleep 1
done
curl -sf http://127.0.0.1:4723/status >/dev/null 2>&1 \
  || { echo "appium did not come up"; cat /tmp/appium.log; exit 1; }

cyrius test tests/e2e/android-appium-smoke.tcyr
