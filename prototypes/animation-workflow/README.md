# Throwaway spirit animation workshop

Can short pixel animations carry cumulative elemental attachments without drawing each build combination?

Run `python3 -m http.server 8772 --directory docs --bind 127.0.0.1`, then open http://127.0.0.1:8772/?variant=A in Chrome. Or open project.godot in Godot 4.7.2 and run the scene.

I/R/S select four-frame idle, six-frame run, four-frame swipe. Space pauses; period steps. Keys 1–5 toggle mixed-build elements; the guardian copy uses the same parts. A shows anchors. V compares frame poses with a fixed-pose procedural bob; `?variant=B` opens that comparison. The latter is a deliberately cheap alternative, not a completed skeletal cutout implementation. Top row enlarges the sprites; bottom row shows the roughly 48-pixel body at gameplay scale.

## Source and export workflow

Original B concept -> built-in image generation of pose/accessory atlas -> background correction using built-in image editing -> explicit source rectangles and per-pose anchors in spirit.gd -> nearest-filtered Godot Compatibility web rendering. No downloaded/purchased art pack, new editor dependency, or generated full sprite set for each build. Exact generation prompts are in prompts.json. assets/spirit-atlas-magenta.png is the preserved source. The shader removes magenta at runtime; the source is RGB, not a transparent production atlas.

The body has fourteen pose slots. Six accessory regions supply the five elemental motifs. Every displayed form reuses these assets, including the tinted guardian. First acquisitions are demonstrated; repeat-rank visual scaling and distinct visuals for both paths per element are not yet demonstrated. Per-frame hand anchors move the Ember claw; head/chest/rear anchors are approximate and need further cleanup. Large and gameplay views share the same compositing code.

The generated grid was imperfect and its first claimed transparency was a painted checkerboard. Explicit rectangles avoid cell clipping. The correction preserved usable poses but did not establish a clean common logical pixel grid. The 48-pixel display is sampled from a larger source; final production needs a deliberately cleaned native-resolution atlas. Idle poses are very similar, and the run has some head/body drift. Wind fins were reduced after Chrome inspection to keep the feet clearer. Guardian recoloring makes ownership distinct while retaining the exact parts.

## Evidence and proposed decision

Chrome automation loaded the export without recorded console or page errors, captured run/swipe screenshots, and exercised animation selection, frame stepping, elemental toggles and A/B mode. This is visual prototype inspection, not a production test suite or evidence of final combat performance. See evidence/animation-*.png. Browser-feasibility evidence inherited from the parent branch is separate and does not validate these new sprites.

Proposed workflow: low-frame body poses plus reusable attachments, with manual alignment/pixel cleanup before production. Plan on fourteen cleaned base pose slots for this subset, attachment anchor checks on every slot, and extra work for jumping, falling, hurt, death, transformation and attack effects. We have no measured production-hours estimate yet. Pure procedural bob saves pose work but cannot express the swipe or running stride on its own. A full cutout rig was not built and is not ruled out by this experiment.

User feedback is required before resolving [Prove an original character animation workflow](https://github.com/scleond/main-vania/issues/3). In particular, judge animation cadence, mixed silhouette and player/copy distinction at gameplay size. This is not the complete production asset inventory or a final visual-quality acceptance.

## Re-export

`python3 export.py --godot /path/to/Godot --templates /path/to/templates`

Use matching Godot 4.7.2 web_nothreads_debug.zip and web_nothreads_release.zip templates. Fresh output is build/; docs/ captures the current runnable export. No production game changes are on this branch.
