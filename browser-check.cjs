// Chrome smoke check for the production movement boundary.
const { chromium } = require('playwright');
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
  const exercisePresentation = async presentation => {
    state = await read();
    if (state.presentation !== presentation) {
      await page.keyboard.press('p'); await page.waitForTimeout(100); state = await read();
    }
    check(`${presentation} presentation is selectable`, state.presentation === presentation, state);
    await page.keyboard.press('k'); await page.waitForTimeout(150);
    const starting = await read();
    await page.keyboard.down('d'); await page.waitForTimeout(350); await page.keyboard.up('d');
    const moved = await read();
    const actionStartedAt = await page.evaluate(() => performance.now());
    await page.keyboard.press('j');
    await page.waitForFunction(() => window.__vania_probe.attack_active, null, { timeout: 500 });
    const active = await read();
    await page.waitForFunction(() => !window.__vania_probe.attack_active, null, { timeout: 1000 });
    const actionDurationMs = await page.evaluate(startedAt => performance.now() - startedAt, actionStartedAt);
    const acted = await read();
    return {
      movement: moved.x - starting.x,
      actions: acted.attack - starting.attack,
      attackStarted: active.attack_active,
      attackDurationMs,
    };
  };
  const defaultOutcome = await exercisePresentation('default');
  const alternateOutcome = await exercisePresentation('alternate');
  check('presentation preserves movement and action timing',
    defaultOutcome.movement > 20 && alternateOutcome.movement > 20 &&
    Math.abs(defaultOutcome.movement - alternateOutcome.movement) < 5 &&
    defaultOutcome.actions === 1 && alternateOutcome.actions === 1 &&
    defaultOutcome.attackStarted && alternateOutcome.attackStarted &&
    defaultOutcome.attackDurationMs > 160 && defaultOutcome.attackDurationMs < 420 &&
    alternateOutcome.attackDurationMs > 160 && alternateOutcome.attackDurationMs < 420 &&
    Math.abs(defaultOutcome.attackDurationMs - alternateOutcome.attackDurationMs) < 80,
    { default: defaultOutcome, alternate: alternateOutcome });
  state = await read(); check('keyboard movement', state.x > 90, state);
  const startY = state.y; await page.keyboard.press('Space');  await page.waitForFunction(y => window.__vania_probe.y < y - 5, startY);
  state = await read(); check('keyboard jump', state.y < startY - 5, state);
  await page.keyboard.press('Escape'); await page.waitForTimeout(100); state = await read();
  check('pause boundary', state.paused, state);
  await page.keyboard.press('Escape'); await page.waitForTimeout(100);
  await page.keyboard.press('k'); await page.waitForTimeout(150); state = await read();
  check('nearby retry boundary', state.retries >= 1 && Math.abs(state.x - 70) < 8, state);
  // Earn a numen choice through real combat (no debug grant): steer to the
  // nearest living enemy and swipe until the paused choice opens, then pick
  // Searing Claws and confirm the burn rank applies with a visible change.
  const deadline = Date.now() + 150000;
  while (Date.now() < deadline) {
    state = await read();
    if (state.choosing || (state.selections || 0) >= 1) break;
    if (state.paused) { await page.keyboard.press('Escape'); await page.waitForTimeout(100); continue; }
    const foes = (state.enemies || []).filter(e => e.hp > 0)
      .sort((a, b) => Math.abs(a.x - state.x) - Math.abs(b.x - state.x));
    const target = foes[0];
    if (!target) { await page.waitForTimeout(300); continue; }
    const dx = target.x - state.x;
    if (Math.abs(dx) > 34) {
      const key = dx > 0 ? 'd' : 'a';
      await page.keyboard.down(key); await page.waitForTimeout(140); await page.keyboard.up(key);
    } else {
      await page.keyboard.press('j'); await page.waitForTimeout(480);
    }
  }
  state = await read();
  check('combat earns a paused numen choice', !!state.choosing, state);
  check('session offers two Ember paths', state.offer_kind === 'paths', state);
  await page.keyboard.press('1'); await page.waitForTimeout(200); state = await read();
  check('Searing Claws applies burn rank', !state.choosing && state.burn_rank === 1 && state.burn_duration > 0 && state.upgrade === 'burn', state);
  check('no page errors', result.errors.length === 0, result.errors);
  result.status = 'passed'; await page.screenshot({ path: path.join(__dirname, 'chromium.png') });
  await browser.close();
} catch (error) { result.status = 'failed'; result.failure = String(error); }
finally { fs.writeFileSync(path.join(__dirname, 'chromium-results.json'), JSON.stringify(result, null, 2)); console.log(JSON.stringify(result, null, 2)); process.exitCode = result.status === 'passed' ? 0 : 1; }
})();
