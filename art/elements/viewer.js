// Presentation-only consumer of the same JSON and body atlases as visual.gd.
const $ = id => document.getElementById(id);
const order = ['idle', 'run', 'jump', 'fall', 'swipe', 'dash', 'hurt', 'death'];
let art, attachments, alternate, motions, paths, images = {};
let name = 'idle', frame = 0, time = 0, elementTime = 0, playing = true, last;
const bodyCache = new Map();
const enabled = {}, ranks = {};
const buffer = document.createElement('canvas');
buffer.width = buffer.height = 128;
const ink = buffer.getContext('2d');
function total(m) { return m.frames.reduce((sum, f) => sum + f.duration_ms, 0); }
function frameAt(m, t) {
  const length = total(m);
  if (m.loop && t >= length) {
    const entry = m.frames.slice(0, m.loop_from).reduce((sum, f) => sum + f.duration_ms, 0);
    t = entry + (t - entry) % (length - entry);
  }
  for (let i = 0; i < m.frames.length; i++) {
    if (t < m.frames[i].duration_ms) return i;
    t -= m.frames[i].duration_ms;
  }
  return m.frames.length - 1;
}
function displayFrame(i, replacement) {
  return replacement && alternate.sequences[name] ? alternate.sequences[name][i] : i;
}
function dominantFamily() {
  let winner = '', highest = 0;
  for (const family of art.family_order) {
    const total = paths.reduce((sum, p) => sum + (enabled[p] && art.parts[p].family === family ? ranks[p] : 0), 0);
    if (total > highest) { highest = total; winner = family; }
  }
  return winner;
}
function bodyImage(family, reprisal) {
  if (!family) return images[name];
  const key = name + ':' + family + (reprisal ? ':reprisal' : '');
  if (bodyCache.has(key)) return bodyCache.get(key);
  const body = document.createElement('canvas');
  body.width = images[name].width; body.height = 64;
  const ctx = body.getContext('2d'); ctx.drawImage(images[name], 0, 0);
  const image = ctx.getImageData(0, 0, body.width, 64), data = image.data;
  const palette = (art.spike_palettes[family] ?? art.palettes[family]).map(hex => [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16)));
  const stoneTexture = reprisal;
  attachments.motions[name].forEach((pose, f) => {
    const angle = pose.angle * Math.PI / 180;
    for (let y = 0; y < 64; y++) for (let x = 0; x < 64; x++) {
      const dx = x - 32 - pose.head[0], dy = y - 60 - pose.head[1];
      const localX = dx * Math.cos(angle) + dy * Math.sin(angle);
      const localY = -dx * Math.sin(angle) + dy * Math.cos(angle);
      if (localY >= -3) continue;
      const i = (y * body.width + f * 64 + x) * 4;
      const [r, g, b, alpha] = data.slice(i, i + 4);
      if (!alpha || g <= r * 1.2 || b <= r * 1.2 || g <= .25 * 255) continue;
      const light = Math.max(r, g, b) / 255;
      const tint = stoneTexture
        ? palette[Math.abs((Math.floor(localX) + Math.floor(localY) * 2) % 5) === 0 ? 1 : (Math.abs((Math.floor(localX) + Math.floor(localY) * 2) % 5) === 4 ? 3 : 2)]
        : palette[light > .85 ? 3 : light > .55 ? 2 : 1];
      data.set(tint, i);
    }
  });
  ctx.putImageData(image, 0, 0); bodyCache.set(key, body); return body;
}
function nativeRound(value) { return Math.sign(value) * Math.floor(Math.abs(value) + .5); }
function occluded(x, y, pose, maskId) {
  if (!maskId) return false;
  const mask = attachments.occlusion_masks[maskId], placement = pose.occluders[maskId];
  const angle = pose.angle * Math.PI / 180, c = Math.cos(angle), s = Math.sin(angle);
  const dx = x + 32 - placement.transform_at[0], dy = y + 60 - placement.transform_at[1];
  // Same two nearest samples as the approved body: whole pose, then hand.
  const localX = nativeRound(dx * c + dy * s + placement.transform_origin[0]);
  const localY = nativeRound(-dx * s + dy * c + placement.transform_origin[1]);
  const px = nativeRound(localX - placement.wrist[0] + mask.pivot[0]);
  const py = nativeRound(localY - placement.wrist[1] + mask.pivot[1]);
  return py >= 0 && py < mask.rows.length && px >= 0 && px < mask.rows[py].length && mask.rows[py][px] !== '.';
}
function motif(ctx, id, ox, oy, angle, palette, phase, marks = [], rank = 1, pose = {}, maskId = '') {
  const spec = art.motifs[id];
  const pixels = spec.frames[(Math.floor(elementTime / spec.frame_ms) + phase) % spec.frames.length];
  const width = Math.max(...pixels.map(row => row.length)), height = pixels.length;
  const c = Math.cos(angle), s = Math.sin(angle);
  const corners = [[0, 0], [width, 0], [0, height], [width, height]].map(([x, y]) => [ox + x * c - y * s, oy + x * s + y * c]);
  const lowX = Math.floor(Math.min(...corners.map(p => p[0]))), highX = Math.ceil(Math.max(...corners.map(p => p[0])));
  const lowY = Math.floor(Math.min(...corners.map(p => p[1]))), highY = Math.ceil(Math.max(...corners.map(p => p[1])));
  for (let y = lowY; y < highY; y++) for (let x = lowX; x < highX; x++) {
    const dx = x + .5 - ox, dy = y + .5 - oy;
    const px = Math.floor(dx * c + dy * s), py = Math.floor(-dx * s + dy * c);
    if (py < 0 || py >= height || px < 0 || px >= pixels[py].length) continue;
    let color = art.ink.indexOf(pixels[py][px]);
    if (color < 0) continue;
    if (occluded(x, y, pose, maskId)) continue;
    if (marks.slice(0, rank - 1).some(([mx, my]) => mx === px && my === py)) color = 3;
    ctx.fillStyle = palette[color]; ctx.fillRect(x, y, 1, 1);
  }
}
function layer(ctx, pose, side, replacement) {
  for (const path of paths) {
    const rank = enabled[path] ? ranks[path] : 0;
    if (!rank) continue;
    const recipe = attachments.mounts[path];
    if (art.parts[path].texture) continue;
    const part = art.parts[replacement ? (alternate.part_overrides[path] ?? path) : path];
    const palette = part.rank_palette ? art.rank_palettes[part.rank_palette][rank - 1] : art.palettes[part.palette ?? part.family];
    for (const mount of recipe.instances ?? [recipe]) {
      if (mount.layer !== side) continue;
      const offset = replacement ? (alternate.offset_overrides[path] ?? mount.offset) : mount.offset;
      const anchor = pose[mount.anchor], angle = pose.angle * Math.PI / 180;
      const ox = Math.round(anchor[0] + offset[0] * Math.cos(angle) - offset[1] * Math.sin(angle));
      const oy = Math.round(anchor[1] + offset[0] * Math.sin(angle) + offset[1] * Math.cos(angle));
      const maskId = mount.occluder ?? '', phase = mount.phase ?? 0;
      part.growth.forEach((growth, i) => {
        if (rank < growth.min_rank) return;
        const [x, y] = growth.offset;
        motif(ctx, growth.motif, Math.round(ox + x * Math.cos(angle) - y * Math.sin(angle)), Math.round(oy + x * Math.sin(angle) + y * Math.cos(angle)), angle, palette, i + 1 + phase, [], 1, pose, maskId);
      });
      motif(ctx, part.motif, ox, oy, angle, palette, phase, part.rank_marks, rank, pose, maskId);
    }
  }
}
function sprite(ctx, i, x, y, scale, left, copy, replacement) {
  const f = displayFrame(i, replacement), pose = attachments.motions[name][f];
  ink.clearRect(0, 0, 128, 128); ink.save(); ink.translate(64, 84);
  ink.imageSmoothingEnabled = false;
  const family = dominantFamily(), maxed = paths.reduce((sum, p) => sum + (enabled[p] ? ranks[p] : 0), 0) >= 8;
  if (maxed && family) {
    ink.strokeStyle = art.spike_palettes[family][2]; ink.lineWidth = 1;
    ink.beginPath(); ink.arc(0, -24, 29, 0, Math.PI * 2); ink.stroke();
    ink.strokeStyle = art.spike_palettes[family][3];
    ink.beginPath(); ink.arc(0, -24, 31, -2.5, -0.7); ink.stroke();
  }
  layer(ink, pose, 'rear', replacement);
  ink.drawImage(bodyImage(family, ranks.reprisal > 0), f * 64, 0, 64, 64, -32, -60, 64, 64);
  layer(ink, pose, 'body_under', replacement);
  layer(ink, pose, 'body_effect', replacement);
  layer(ink, pose, 'body_front', replacement);
  layer(ink, pose, 'front', replacement);
  ink.restore();
  if (copy) {
    // Same tint as the runtime mirror shader; no alternate copy assets.
    const pixels = ink.getImageData(0, 0, 128, 128);
    for (let i = 0; i < pixels.data.length; i += 4) {
      const light = Math.max(pixels.data[i], pixels.data[i + 1], pixels.data[i + 2]);
      pixels.data[i] = light * .85; pixels.data[i + 1] = light * .48; pixels.data[i + 2] = light;
    }
    ink.putImageData(pixels, 0, 0);
  }
  ctx.save(); ctx.translate(x, y); ctx.scale(left ? -scale : scale, scale);
  ctx.imageSmoothingEnabled = false; ctx.drawImage(buffer, -64, -84);
  if (copy) {
    ctx.strokeStyle = '#c59bff'; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.arc(0, -25, 31, 0, Math.PI * 2); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-19, 3); ctx.lineTo(22, 3); ctx.stroke();
  }
  if ($('anchors').checked) {
    for (const [anchor, color] of [['hand', '#77ff77'], ['far_hand', '#ff88bb'], ['head', '#ffda77'], ['chest', '#77ddff']]) {
      const [ax, ay] = pose[anchor];
      ctx.fillStyle = color; ctx.fillRect(ax - 2, ay, 5, 1); ctx.fillRect(ax, ay - 2, 1, 5);
    }
  }
  ctx.restore();
}
function label(ctx, text, x, y) { ctx.fillStyle = '#bacaca'; ctx.font = '13px system-ui'; ctx.fillText(text, x, y); }
function draw() {
  if (!motions) return;
  const m = motions[name], replacement = $('alternate').checked, left = $('flip').checked;
  const ctx = $('stage').getContext('2d');
  ctx.fillStyle = $('backdrop').value; ctx.fillRect(0, 0, 1120, 345);
  ctx.fillStyle = '#71877b44';
  for (const [x, y, w] of [[12, 113, 210], [225, 283, 465], [723, 228, 375]]) ctx.fillRect(x, y, w, 1);
  sprite(ctx, frame, 65, 110, 1, left, false, replacement);
  sprite(ctx, frame, 160, 110, 1, left, true, replacement);
  label(ctx, 'Player 1×', 32, 139); label(ctx, 'Copy 1×', 130, 139);
  sprite(ctx, frame, 310, 280, 4, left, false, replacement);
  sprite(ctx, frame, 570, 280, 4, left, true, replacement);
  label(ctx, 'Player 4×', 270, 322); label(ctx, 'Guardian 4×', 530, 322);
  sprite(ctx, frame, 805, 225, 3, left, false, false);
  sprite(ctx, frame, 1015, 225, 3, left, false, true);
  label(ctx, 'Baseline', 780, 270); label(ctx, 'Replacement', 975, 270);
  const shown = displayFrame(frame, replacement);
  $('status').textContent = `${name} · slot ${frame + 1}/${m.frames.length} · displayed pose ${shown + 1}: ${m.frames[shown].name} · ${m.frames[frame].duration_ms} ms · element clock ${Math.floor(elementTime)} ms`;
  const count = paths.reduce((sum, p) => sum + (enabled[p] ? ranks[p] : 0), 0);
  $('identity').textContent = dominantFamily() ? `${dominantFamily()} spike tips · strongest family by total ranks${count >= 8 ? ' · maxed Numen aura' : ''}` : 'Neutral cyan spike tips';
  $('effect-time').value = Math.floor(elementTime % 2400);
  $('budget').textContent = `${count}/8 selections${count > 8 ? ' — impossible stress preview' : ''}`;
  $('sockets').textContent = $('anchors').checked ? JSON.stringify({
    pose: attachments.motions[name][shown],
    emberMounts: Object.fromEntries(['searing_claws', 'flame_arc'].map(path => [path,
      (attachments.mounts[path].instances ?? [attachments.mounts[path]]).map(mount => ({...mount,
        offset: replacement ? (alternate.offset_overrides[path] ?? mount.offset) : mount.offset
      }))]))
  }, null, 2) : '';
  const strip = $('strip').getContext('2d'); strip.clearRect(0, 0, 1280, 170);
  for (let i = 0; i < m.frames.length; i++) {
    const x = 160 * i;
    sprite(strip, i, x + 38, 65, 1, false, false, replacement);
    sprite(strip, i, x + 113, 65, 1, false, true, replacement);
    sprite(strip, i, x + 38, 135, 1, true, false, replacement);
    sprite(strip, i, x + 113, 135, 1, true, true, replacement);
    label(strip, `${i + 1} ${m.frames[i].name}`, x + 3, 163);
  }
}
function pause() { playing = false; $('pause').textContent = 'Play'; }
function step(delta) {
  pause(); frame = (frame + delta + motions[name].frames.length) % motions[name].frames.length;
  time = motions[name].frames.slice(0, frame).reduce((sum, f) => sum + f.duration_ms, 0); draw();
}
function refreshControls() {
  for (const p of paths) { $(p).checked = enabled[p]; $(p + '-rank').value = ranks[p]; }
  draw();
}
function preset(value) {
  for (const p of paths) { enabled[p] = false; ranks[p] = 1; }
  if (value === 'claws' || value === 'arc') enabled[value === 'claws' ? 'searing_claws' : 'flame_arc'] = true;
  else if (value === 'stress') for (const p of paths) enabled[p] = true;
  else if (value === 'mixed') {
    for (const p of ['searing_claws', 'flame_arc', 'chain_spark', 'barb_shot', 'stonehide', 'airborne']) enabled[p] = true;
    ranks.searing_claws = 2; ranks.stonehide = 2;
  } else for (const p of paths) if (art.parts[p].family === value) { enabled[p] = true; ranks[p] = 4; }
  refreshControls();
}
function tick(now) {
  if (playing) {
    const m = motions[name], delta = Math.min(now - (last ?? now), 100) * Number($('speed').value);
    elementTime += delta;
    if (!$('hold-pose').checked) time += delta;
    if (!m.loop && $('repeat').checked && time >= total(m) + 500) time %= total(m) + 500;
    frame = frameAt(m, time); draw();
  }
  last = now; requestAnimationFrame(tick);
}
async function json(file) {
  const response = await fetch('../../assets/' + file);
  if (!response.ok) throw new Error(`Cannot load ${file}: ${response.status}`);
  return response.json();
}
try {
  [art, attachments, alternate, { motions }] = await Promise.all([
    json('element-parts.json'), json('element-attachments.json'), json('element-presentation-alternate.json'), json('spirit-motions.json')
  ]);
  paths = Object.keys(attachments.mounts);
  for (const family of Object.keys(art.palettes)) {
    const box = document.createElement('fieldset'), legend = document.createElement('legend');
    legend.textContent = family; box.append(legend);
    for (const p of paths.filter(p => art.parts[p].family === family)) {
      const row = document.createElement('div'); row.className = 'path';
      const label = document.createElement('label'), toggle = document.createElement('input');
      toggle.type = 'checkbox'; toggle.id = p;
      label.append(toggle, document.createTextNode(art.parts[p].name));
      const rank = document.createElement('input'); rank.type = 'number'; rank.min = 1; rank.max = 8; rank.value = 1; rank.id = p + '-rank'; rank.setAttribute('aria-label', art.parts[p].name + ' rank');
      row.append(label, rank); box.append(row);
      toggle.onchange = () => { enabled[p] = toggle.checked; $('build').value = 'custom'; draw(); };
      rank.onchange = () => { ranks[p] = Math.max(1, Math.min(8, Math.trunc(Number(rank.value) || 1))); rank.value = ranks[p]; $('build').value = 'custom'; draw(); };
    }
    $('parts').append(box);
  }
  for (const n of order) {
    const option = document.createElement('option'); option.value = option.textContent = n; $('motion').append(option);
    images[n] = new Image(); images[n].src = '../../assets/' + motions[n].atlas; await images[n].decode();
  }
  $('build').onchange = () => { if ($('build').value !== 'custom') preset($('build').value); };
  $('apply').onclick = () => { const rank = Math.max(1, Math.min(8, Math.trunc(Number($('rank').value) || 1))); $('rank').value = rank; for (const p of paths) if (enabled[p]) ranks[p] = rank; $('build').value = 'custom'; refreshControls(); };
  $('motion').onchange = () => { name = $('motion').value; frame = time = 0; draw(); };
  $('pause').onclick = () => { playing = !playing; $('pause').textContent = playing ? 'Pause' : 'Play'; };
  $('step').onclick = () => step(1); $('back').onclick = () => step(-1);
  $('restart').onclick = () => { frame = time = elementTime = 0; draw(); };
  $('effect-step').onclick = () => { pause(); elementTime += 65; draw(); };
  $('effect-time').oninput = () => { pause(); elementTime = Number($('effect-time').value); draw(); };
  for (const id of ['flip', 'anchors', 'alternate', 'backdrop']) $(id).onchange = draw;
  $('speed').oninput = () => { $('rate').textContent = $('speed').value + '×'; };
  preset('ember'); for (const p of paths) ranks[p] = 1; $('build').value = 'custom'; refreshControls(); requestAnimationFrame(tick);
} catch (error) { $('status').textContent = 'Could not load workshop: ' + error.message; }
