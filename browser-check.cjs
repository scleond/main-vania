// Chrome smoke check for the production movement boundary.
const { chromium } = require('/Users/cleon/projects/cbs-fantasy-digest/node_modules/playwright');
const fs = require('node:fs');
const path = require('node:path');
const result = { browser: 'chromium', checks: {}, errors: [] };
const check = (name, pass, detail) => { result.checks[name] = { pass, detail }; if (!pass) throw Error(name); };
(async () => { try {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', e => result.errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') result.errors.push(m.text()); });
  await page.goto(process.env.VANIA_URL || 'http://127.0.0.1:8774/');
  await page.waitForFunction(() => window.__vania_probe?.ready, null, { timeout: 60000 });
  const read = () => page.evaluate(() => window.__vania_probe);
  await page.keyboard.press('Enter');
  let state = await read();
  check('session starts', state.playing, state);
  const startX = state.x;
  await page.keyboard.down('d'); await page.waitForTimeout(350); await page.keyboard.up('d');
  state = await read(); check('keyboard movement', state.x > startX + 20, state);
  const startY = state.y; await page.keyboard.press('Space');
  await page.waitForFunction(y => window.__vania_probe.y < y - 5, startY);
  state = await read(); check('keyboard jump', state.y < startY - 5, state);
  await page.keyboard.press('Escape'); await page.waitForTimeout(100); state = await read();
  check('pause boundary', state.paused, state);
  await page.keyboard.press('Escape'); await page.waitForTimeout(100);
  await page.keyboard.press('k'); await page.waitForTimeout(150); state = await read();
  check('nearby retry boundary', state.deaths >= 1 && Math.abs(state.x - 70) < 8, state);
  check('no page errors', result.errors.length === 0, result.errors);
  result.status = 'passed'; await page.screenshot({ path: path.join(__dirname, 'chromium.png') });
  await browser.close();
} catch (error) { result.status = 'failed'; result.failure = String(error); }
finally { fs.writeFileSync(path.join(__dirname, 'chromium-results.json'), JSON.stringify(result, null, 2)); console.log(JSON.stringify(result, null, 2)); process.exitCode = result.status === 'passed' ? 0 : 1; }
})();
