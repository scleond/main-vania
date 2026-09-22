# Ember sanctuary kit — issue #25

Original SVG artwork lives in `assets/ember/`. PNG siblings are native-size,
transparent RGBA exports; SVG is the editable source used by the game. The
renderer caches rasterized SVGs, so a source edit needs no atlas rebuild. Shared
shapes use hard edges and a restrained basalt/ash/copper palette.

- Architecture: repeating broken arch, jointed platform stone, charcoal piles,
  recessed barred furnaces and glowing cracks below the landing plane.
- Three signature decorations: split votive bell, blind ash effigy, suspended censer.
- Easy: Cinder Skitter, low single-crack shell. Medium: Coalback, larger body,
  doubled armor ribs. Miniboss: Kiln Warden, broken furnace wheel and hot core.
- Shared Checkpoint: mint suspended seed and forked plinth. Shrine: dormant,
  available and awakened core variants. Placement follows existing section state.

`assets/ember-kit.json` controls placement, sizes and masonry colors;
`assets/ember-motions.json` independently controls vent-flicker sequences and FPS.
`ember_art.gd` only receives presentation values. It cannot write actor state.
Flicker never gates warning/recovery, attacks, damage, collision or rewards.
Feet stay fixed while the vent animates. Existing warning lines, recovery dots,
health bars, burn markers, fire waves and Shrine progress remain in `main.gd`.

Regenerate transparent exports:

```sh
godot --headless --path . --script art/ember/export.gd
```

Produce the static native-resolution environment review plate (requires a display):

```sh
godot --path . --script art/ember/preview.gd
```

`review.png` uses the runtime renderer and section platforms, with neutral and two
mixed-element Spirits. It is an art review composition, not a gameplay capture.
Full animation viewer and playback/frame UI are omitted as requested. The existing
Spirit viewers remain available; this slice adds only a static environment preview.

## Artistic review and corrections

Reviewed `review.png` at native 640×360 resolution. Background furnaces use subdued
copper, leaving cream eyes and orange warning lines in the foreground. Architecture
uses darker values than enemies. Checkpoint mint and Shrine gold remain distinct.
Mixed Spirits retain bright body/face outlines against arches and the furnace;
Coalback ribs and the Warden wheel preserve tier recognition without relying only
on color. Charcoal has sparse dim embers instead of competing bright flames.

Platform top rows coincide with the authored collision rectangles. Enemy feet
anchor at y=300, matching the previous drawings. Sprite extents preserve the old
26×30, 38×39 and 56×55 body-plus-spike envelopes. Decorative arches and hanging
objects are background art and do not imply walkable ledges. Cracks are below the
landing edge; this avoids suggesting gaps in the continuous floor.

Gameplay tuning: none. Existing combat uses horizontal center-distance checks
(`ENEMY_CONTACT_RANGE = 25`) and a player-height threshold, not sprite alpha.
Thus pointed backs and the Warden wheel are decorative, not new attack/hurt boxes.
This inherited approximation remains visible; art changes do not claim pixel-exact
collision. Manual playthrough and broader accessibility review remain follow-ups.
