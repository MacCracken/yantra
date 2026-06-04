// scripts/parity-playwright.mjs — the Playwright side of yantra's parity
// benchmark. Runs the SAME workload programs/benchmarks.cyr times against the
// SAME data: URL, so the two columns are comparable. Kept out of the build —
// this is a reference harness you run on a machine with Node + Playwright:
//
//   npm i -D playwright && npx playwright install chromium
//   node scripts/parity-playwright.mjs
//
// To reuse a system Chromium instead of Playwright's bundled browser
// (no 150MB download), install just the driver and point at the binary:
//   npm i -D playwright   # driver only
//   CHROMIUM_BIN=/usr/bin/chromium node scripts/parity-playwright.mjs
//
// It prints avg/min/max per operation in the same shape as the Cyrius side.
// yantra never bundles or fabricates these numbers; this is how you obtain
// the incumbent column for the ROADMAP M6 / v1.0 comparison.

import { chromium } from 'playwright';

const DATA = 'data:text/html,<input id=n><input type=checkbox id=c>';

function stats(name, samplesNs) {
  const n = samplesNs.length;
  const avg = samplesNs.reduce((a, b) => a + b, 0) / n;
  const min = Math.min(...samplesNs);
  const max = Math.max(...samplesNs);
  const us = (x) => (x / 1000).toFixed(1) + 'us';
  console.log(`  ${name}: ${us(avg)} avg (min=${us(min)} max=${us(max)}) [${n} iters]`);
}

async function bench(name, iters, fn) {
  const s = [];
  for (let i = 0; i < iters; i++) {
    const t0 = process.hrtime.bigint();
    await fn();
    s.push(Number(process.hrtime.bigint() - t0));
  }
  stats(name, s);
}

const launchOpts = { headless: true, args: ['--no-sandbox', '--disable-gpu'] };
if (process.env.CHROMIUM_BIN) launchOpts.executablePath = process.env.CHROMIUM_BIN;
const browser = await chromium.launch(launchOpts);
const page = await browser.newPage();
await page.goto(DATA); // warmup

console.log('playwright (Chromium), per-operation round trip:');
await bench('web.navigate(data)', 50, () => page.goto(DATA));
await bench('web.eval(querySelector)', 100, () => page.evaluate('document.querySelector("#c")!=null'));
await bench('web.click', 100, () => page.click('#c'));
await bench('web.type', 100, () => page.fill('#n', 'x'));
await bench('flow: navigate+click+assert', 30, async () => {
  await page.goto(DATA);
  await page.click('#c');
  await page.evaluate('document.querySelector("#c").checked');
});

await browser.close();
