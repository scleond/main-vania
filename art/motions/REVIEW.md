# Issue 22 animation review — 2026-09-12

Completed jump (6 frames), fall (4), swipe (6), dash (4), hurt (4), and death (8) from the approved pixel parts. Idle and run atlases and editable poses are byte-identical to the starting point of this pass. The user approved the complete neutral animation set for issue closure.

## Review

- Combined viewer/GIF gallery: `http://127.0.0.1:8778/art/motions/viewer.html`
- Current playable Chrome build: `http://127.0.0.1:8778/game/` (Enter to start).
- Portable viewer: serve the repository with `python3 -m http.server 8779 --bind 127.0.0.1`, then open `/art/motions/viewer.html`.
- `contact-sheet.png`: all eight motions at native and 2x size, with loop returns/held endpoints.
- `viewer.png`, `viewer-left.png`: actual Chrome viewer captures in both facings.
- `game-{idle,run,jump,fall,swipe,dash,hurt,death}.png`: captures from the freshly exported playable room.
- `game-death.gif`: native-resolution capture of actual death/instant respawn and the temporary collapse visual.
- `{idle,run,jump,fall,swipe,dash,hurt,death}.gif` and `*-4x.gif`: transparent review GIFs. One-shots have an extra 500 ms end hold before review restart; runtime does not loop them.

## Editable source and rebuild

The canonical look is `art/run/rig-look.png`. Spike masks and fixed limb lengths come from `art/run/run-poses.json`; `art/run/export.gd` supplies the shared native renderer. New motion poses, durations, rotations and spike angles live in `poses.json`. `export.gd` renders the six atlases and generates `assets/spirit-motions.json` with runtime timings/anchors. Previously generated high-resolution drafts in `art/run/` are not inputs to this workflow.

From the repository root (Godot 4.7.2 and Python/Pillow):

```sh
godot --headless --path . --script art/motions/export.gd --quit-after 1
python3 art/motions/export-gif.py
godot --headless --path . --script art/motions/verify.gd
godot --headless --path . --script tests/test_session.gd
git diff --check
```

When changing the earlier idle/run sources, run their own `export.gd` scripts first. For a new web build, use the existing `export.py` with matching Godot templates; the viewer reads source atlases directly.

## Evidence and practical limits

- Examined all poses at native size and enlarged; played the viewer in Chrome, stepped every pose, checked both facings, and exercised hold/loop boundaries. Native-size readability remains constrained by the deliberately small limbs beneath the oversized hood.
- Jump apex -> fall entry is pixel-identical. Swipe and hurt endpoints -> athletic idle frame 1 are pixel-identical. Fall loops its bracing poses after the entry; takeoff, swipe, dash, hurt and death are one-shots.
- Export assertions check the shared 64x64 cells, (32,60) pivot, binary alpha, original PNG palette, rigid limb lengths, and transformed-part bounds before and after rasterization. Rotated parts use nearest pixel sampling.
- GIF decoding checks alpha, disposal, shared quantized palette and duration. GIF's 256-color limit reduces the PNG's subtle color variation; PNG runtime atlases retain the exact source palette. GIF time rounding preserves total timing.
- 24 focused animation checks passed: state selection, authoritative attack/dash clocks, replay/hold behavior, hurt recovery, pause, death cleanup, immediate checkpoint restoration, unchanged 18x34 collision, and identical combat traces under different visual speeds/frame sampling.
- Existing 27 session checks passed; existing test files and `tuning.gd` are unchanged. Their pre-existing standalone teardown emits resource-leak diagnostics. Local Godot also prints certificate/editor-settings diagnostics; no animation script/parse errors remained.
- Chrome game captures verify actual movement, jump/fall, attack, dash, damage and lethal respawn. Death is a temporary visual at the old position because the existing game respawns immediately; no control lock or delayed respawn was added.
- The user approved the neutral animation set. Swipe/dash are necessarily brief at existing gameplay speeds. Elemental attachments/effects were not redesigned.

## Files changed in this completion pass

- `art/motions/REVIEW.md`
- `art/motions/contact-sheet.png`
- `art/motions/dash-4x.gif`
- `art/motions/dash.gif`
- `art/motions/death-4x.gif`
- `art/motions/death.gif`
- `art/motions/export-gif.py`
- `art/motions/export.gd`
- `art/motions/export.gd.uid`
- `art/motions/fall-4x.gif`
- `art/motions/fall.gif`
- `art/motions/game-dash.png`
- `art/motions/game-death.gif`
- `art/motions/game-death.png`
- `art/motions/game-fall.png`
- `art/motions/game-hurt.png`
- `art/motions/game-idle.png`
- `art/motions/game-jump.png`
- `art/motions/game-run.png`
- `art/motions/game-swipe.png`
- `art/motions/hurt-4x.gif`
- `art/motions/hurt.gif`
- `art/motions/idle-4x.gif`
- `art/motions/idle.gif`
- `art/motions/jump-4x.gif`
- `art/motions/jump.gif`
- `art/motions/poses.json`
- `art/motions/run-4x.gif`
- `art/motions/run.gif`
- `art/motions/swipe-4x.gif`
- `art/motions/swipe.gif`
- `art/motions/verify.gd`
- `art/motions/verify.gd.uid`
- `art/motions/viewer-left.png`
- `art/motions/viewer.html`
- `art/motions/viewer.png`
- `assets/spirit-dash.png`
- `assets/spirit-dash.png.import`
- `assets/spirit-death.png`
- `assets/spirit-death.png.import`
- `assets/spirit-fall.png`
- `assets/spirit-fall.png.import`
- `assets/spirit-hurt.png`
- `assets/spirit-hurt.png.import`
- `assets/spirit-jump.png`
- `assets/spirit-jump.png.import`
- `assets/spirit-motions.json`
- `assets/spirit-swipe.png`
- `assets/spirit-swipe.png.import`
- `export_presets.cfg`
- `main.gd`
- `player.gd`
- `visual.gd`

The local `build/` export was regenerated for the Chrome check; it is ignored by Git. The approved run/idle work is included with this animation set.

## Reusable implementation prompt

Implement only [motions] from [ticket], using [approved source/reference]. Preserve silhouette, palette, proportions, face, native grid, alpha and pivot. Use editable shared parts with separate poses/timings/anchors. Keep gameplay and unrelated art unchanged. Inspect every pose, opposite-limb pairs, adjacent transitions and loop/hold boundaries at gameplay size and enlarged. Provide native/4x GIFs, labeled contact sheets, a stepping/speed/facing viewer, and targeted in-game evidence. Run art/export checks and relevant integration tests; report exact changed files, rebuild instructions and remaining art uncertainty. Leave uncommitted.

## Reusable visual-review prompt

Review [motions] against [accepted baseline]. Inspect moving GIFs/viewer and native-size game evidence, then step every frame and each loop/hold transition. Check silhouette/palette/face fidelity, limb lengths and direction, support/flight, spike follow-through, pivot drift, alpha, clipping, timing and state transitions. Provide frame-specific defects with annotated evidence, checks performed, and remaining uncertainty. Distinguish technical correctness from art approval; do not approve smoothness from contact sheets alone.
