// Chrome smoke check for the production movement boundary.
const { chromium } = require('playwright');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const result = { browser: 'chromium', checks: {}, errors: [] };
const check = (name, pass, detail) => { result.checks[name] = { pass, detail }; if (!pass) throw Error(name); };
(async () => { let context; let profile; try {
  profile = fs.mkdtempSync(path.join(os.tmpdir(), 'numen-browser-'));
  context = await chromium.launchPersistentContext(profile, { headless: true, viewport: { width: 1280, height: 720 } });
  let page = await context.newPage();
  page.on('pageerror', e => result.errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') result.errors.push(m.text()); });
  await page.goto(process.env.VANIA_URL || 'http://127.0.0.1:8774/');
  await page.waitForFunction(() => window.__vania_probe?.ready, null, { timeout: 60000 });
  const read = () => page.evaluate(() => window.__vania_probe);
  await page.keyboard.press('Enter');
  let state = await read();
  check('session starts', state.playing, state);
  // Fail fast if docs/ has not been regenerated from the source carrying the
  // issue-21 browser-save probe. This prevents a stale export from passing a
  // movement-only smoke check while silently omitting Continue/New Game.
  check('web build includes issue-21 save boundary',
    typeof state.has_saved_run === 'boolean' && typeof state.session_only === 'boolean' &&
    typeof state.checkpoint_id === 'string', state);
  const exercisePresentation = async presentation => {
    await page.keyboard.press('n'); await page.waitForTimeout(150);
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
      attackDurationMs: actionDurationMs,
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
  await page.keyboard.down('a'); await page.waitForTimeout(350); await page.keyboard.up('a');
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
  const durableBrowserSave = await page.evaluate(() => {
    const encoded = window.localStorage.getItem('numen-run-v1');
    return encoded === null ? null : JSON.parse(encoded);
  });
  check('upgrade reaches durable browser storage before reload',
    durableBrowserSave?.progression?.total_selections === 1 &&
    durableBrowserSave?.progression?.path_ranks?.searing_claws === 1,
    durableBrowserSave);
  // A checkpoint retry is a save boundary. Verify reload and a new browser
  // process observe the persisted run, then verify New Game replaces it.
  await page.keyboard.press('k'); await page.waitForTimeout(150);
  const saved = await read();
  const sameProgress = candidate => candidate.selections === saved.selections &&
    candidate.numen_window === saved.numen_window &&
    candidate.burn_rank === saved.burn_rank && candidate.arc_rank === saved.arc_rank &&
    candidate.checkpoint_id === saved.checkpoint_id;
  check('retry creates a saved run', saved.has_saved_run, saved);
  await page.reload(); await page.waitForFunction(() => window.__vania_probe?.ready, null, { timeout: 60000 });
  state = await read(); check('reload offers Continue', !state.playing && state.has_saved_run, state);
  await page.keyboard.press('Enter'); await page.waitForTimeout(150); state = await read();
  check('reload Continue preserves progress', state.playing && sameProgress(state), { saved, state });
  await context.close();
  context = await chromium.launchPersistentContext(profile, { headless: true, viewport: { width: 1280, height: 720 } });
  page = await context.newPage();
  page.on('pageerror', e => result.errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') result.errors.push(m.text()); });
  await page.goto(process.env.VANIA_URL || 'http://127.0.0.1:8774/');
  await page.waitForFunction(() => window.__vania_probe?.ready, null, { timeout: 60000 });
  state = await read(); check('browser restart offers Continue', !state.playing && state.has_saved_run, state);
  await page.keyboard.press('Enter'); await page.waitForTimeout(150); state = await read();
  check('browser restart Continue preserves progress', state.playing && sameProgress(state), { saved, state });
  await page.keyboard.press('n'); await page.waitForTimeout(150); state = await read();
  check('New Game clears saved progress', state.playing && state.selections === 0 && state.numen_window === 0 && state.burn_rank === 0 && state.arc_rank === 0, state);
  const fallback = await context.newPage();
  await fallback.goto((process.env.VANIA_URL || 'http://127.0.0.1:8774/') + '?numen_storage=unavailable');
  await fallback.waitForFunction(() => window.__vania_probe?.ready, null, { timeout: 60000 });
  const fallbackState = await fallback.evaluate(() => window.__vania_probe);
  check('unavailable storage exposes session-only fallback', fallbackState.session_only && !fallbackState.has_saved_run, fallbackState);
  await fallback.keyboard.press('Enter'); await fallback.waitForTimeout(150);
  check('session-only fallback starts gameplay', (await fallback.evaluate(() => window.__vania_probe)).playing, await fallback.evaluate(() => window.__vania_probe));
  check('no page errors', result.errors.length === 0, result.errors);
  result.status = 'passed'; await page.screenshot({ path: path.join(__dirname, 'chromium.png') });
} catch (error) { result.status = 'failed'; result.failure = String(error); }
finally { if (context) await context.close(); if (profile) fs.rmSync(profile, { recursive: true, force: true }); fs.writeFileSync(path.join(__dirname, 'chromium-results.json'), JSON.stringify(result, null, 2)); console.log(JSON.stringify(result, null, 2)); process.exitCode = result.status === 'passed' ? 0 : 1; }
})();
