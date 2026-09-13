# Issue #23 — elemental presentation handoff, 2026-09-13

## Bounded presentation follow-up

The shared source recipes now refine the non-Ember preview families without
opening them in released gameplay. Thunderbeat is a small blue belly swirl in
`body_effect`, below Flame Arc; Stonehide is rocky belly skin in `body_under`;
Reprisal is a static facet texture on the head spikes using the dominant
family's spike palette; Airborne is a pair of small foot clouds; and Slipstream
is a shorter, closer wind wisp. Distinct saturated spike palettes make the
five families readable. At eight selections the released Ember-family spirit
draws a matching presentation aura. Numen remains the collected resource;
Ember remains the released elemental family.

This follow-up does not alter mechanics, timing, collision, attack IDs, reach,
burn/damage behavior, progression, save semantics, preview gating, Ember hand
layering, Flame Arc occlusion, or Chain Spark.

## Earlier source pass — parent-verified Ember foundation

This is the parent-verified Ember foundation retained by the bounded follow-up
above. The current pass adds only presentation recipes and compositor layers;
issue #23 remains subject to the parent's validation boundary.

- Searing Claws retains the original four-frame fire silhouette and 90 ms
  flicker. Rank one now mounts that fire on both hands. The existing near
  instance retains phase zero; the far instance uses phase one. Repeated ranks
  never add flames, tongues, offshoots, cinders or any other geometry.
- Flame Arc retains the original three-frame heart/core and 140 ms cadence,
  chest anchor and offset. Its pixels are drawn after the body but skipped
  wherever the approved foreground hand is present. The near claw flame draws
  afterward, so neither the core nor a later hand repaint covers it.
- Each path independently selects one of eight four-color heat palettes:
  original red/orange → brighter orange → gold/orange → pale gold → pale blue
  → saturated blue → bright blue → blue/white-hot. Masks, clock, size and mounts
  are rank-independent. The split-flame replacement follows the same rule.
- Ember order: **far flame → body → core excluding near-hand pixels → near
  flame**. Both facings mirror the completed composition; near/far mean depth,
  not screen left/right. All eight motions have far-wrist sockets and
  foreground-hand occlusion placement derived from their approved source
  poses, including run arm swaps and the death transform. Alternate swipe
  sampling selects the displayed pose's matching metadata.
- Shared compositor additions are limited to multiple attachment instances,
  optional rank palettes, a `body_front` pass and an opt-in pose hand mask.
  Storm, Thorn, Stone and Wind artwork, mounts, growth and clocks are unchanged.
- The workshop adds Claws-only and Arc-only presets, a far-hand crosshair and
  effective Ember mount data. Existing per-path/batch ranks, all eight motions,
  both facings, native/4× views, body hold, element stepping/scrubbing, guardian
  reuse and simultaneous replacement comparison remain available.
- Copy now calls the resource Numen in the HUD and the historical feel-slice
  menu/HUD/readme. The workshop explicitly says Numen earns Ember upgrades.
  Valid Ember family, room, path, affinity and progression identifiers remain.

Files edited: `assets/element-parts.json`, `assets/element-attachments.json`,
`elemental_parts.gd`, `visual.gd`, `art/elements/viewer.js`,
`art/elements/viewer.html`, `art/elements/README.md`, this handoff, `main.gd`
(HUD text only), `prototypes/feel-slice/main.gd` (text only), and
`prototypes/feel-slice/README.md` (resource wording only).

Approved body atlases and pose sources, mechanics, progression, tuning, attack
IDs, hit windows, reach, burn duration and replacement playback configuration
were not changed. No test files were created or modified.

## Execution boundary and parent follow-up

Per the user's explicit constraint, this pass ran **no validation commands**:
no tests, builds, syntax checks, browser checks, screenshot/render checks or
exports. Existing reference images and source files were inspected; metadata
and code were authored. The hand mask is metadata transcribed from the source
hand alpha, not a newly rendered/exported body layer. The checked-in game export
has not been rebuilt. Visual correctness and engine/Canvas parity are unverified.

The parent verified the source workshop with Claws-only rank 1/rank 8 captures,
Arc-only swipe mode, both facings, anchors and elemental stepping. Remaining
human review should compare both paths independently and together at every
rank with a fixed pose/element phase, especially run opposite strides, swipe
wind-up/recovery and death collapse. Confirm rear fire disappears behind the
body naturally, the core remains readable around the actual foreground hand,
and the near fire stays in front of the core. Compare default and replacement
samples with both elemental clocks held equal. Pixel-mask rounding and
runtime/Canvas parity still deserve gameplay-scale inspection.

The parent owns all loading, regression checks, performance checks, renders,
exports and final gameplay-scale art acceptance. Full pass-specific schema,
rank and layering details are in [README.md](README.md).

---

## Archived broader redesign handoff

The record below predates the Ember follow-up. Its Ember growth descriptions
and verification results describe that earlier implementation only.

### Earlier parent handoff, 2026-09-13

## Delivered source changes

A fresh art pass replaces the previous static badge masks and external rank
bars. Shared animated pixel motifs now supply flame, electric discharge,
flowing air, organic shoots and fixed stone. Rank growth adds related motifs
rather than scaling whole attachments. The approved body art stays intact;
a cached per-pose recolor gives the head spikes the strongest equipped
family's color. The runtime and workshop consume the same source recipes.

Changed files in this pass:

- `assets/element-parts.json`: version 2 artwork schema, palettes, animated
  motifs, growth stages and internal rank highlights.
- `assets/element-attachments.json`: version 2 path offsets/layers; existing
  eight-motion pose socket coordinates retained.
- `elemental_parts.gd`: motif composition, integer pixel rasterization,
  family dominance and cached spike recoloring.
- `visual.gd`: independent elemental presentation clock, remnant clock
  snapshot and body recolor integration.
- `art/elements/viewer.js`, `viewer.html`: matching compositor, independent
  effect controls, body hold, contrast backgrounds and affinity readout.
- `art/elements/README.md`, this handoff: current design and review boundary.

The replacement configuration, player/session/progression/tuning code,
neutral poses/atlases, export settings and tests were not edited in this pass.
No game/web export or screenshot evidence was generated.

## Explicit execution boundary

The user prohibited **all validation commands** for the implementation agent,
including tests, builds, syntax, browser and render checks. The parent
subsequently owned validation. The agent's commands only read sources and
issue #23, inspected existing reference images, and authored files.
Implementation completeness was not an agent-side claim of engine/browser
correctness, measured performance or approved art. Parent-side results are
recorded below; remaining visual acceptance is still called out explicitly.

## Parent verification

On 2026-09-13 the parent ran progression (52 checks), session (27), run save
(12), animation (24), JSON, JavaScript and diff checks; all passed. The
source workshop loaded in Chromium with five families, ten paths, eight
motions, mixed 8/8 selections, anchors, left-facing mode, replacement mode
and elemental stepping, with no page errors. Native/4× mixed and all-ten
stress captures were inspected. The checked-in game export was not rebuilt;
final human gameplay-scale art approval remains outstanding.

## Parent verification priorities

1. Load the source workshop and Godot project; resolve any engine/JS loading
   errors before judging art. Both consumers now require version 2 artwork.
2. Hold idle and advance elemental time: flame contours should flicker, wind
   bends should travel, lightning should branch and drop into quiet gaps,
   thorn tips should move slowly, stone should remain pixel-identical. Pause
   must freeze both clocks; stepping either clock must isolate it.
3. Review every path alone at ranks 1, 2, 3, 4, 5, 7 and 8, then legal mixed
   forms and all-ten stress. Look especially for obscured Flame Arc cores,
   Searing Claws/Barb Shot overlap, Stonehide/Reprisal crowding, and wind/vine
   separation. Internal highlights may be too subtle to read at 1×; growth
   stages carry the primary silhouette progression cue.
4. Step all eight motions in both facings. Inspect run near-arm swaps, swipe
   reach/recovery, airborne wrists, dash lean and death collapse. Check each
   growth stamp, not just its primary root. Flame/wind shapes are body-local:
   they rotate with the collapsed spirit rather than simulating world gravity.
5. Inspect all three spike tips after each family wins or ties dominance.
   Confirm cyan eyes and cream hood survive recoloring; watch extreme death
   rotation and tilted dash poses. The mask uses cyan color plus inverse
   head-space height, not separate exported spike masks. If a pose exposes a
   cyan non-spike pixel above that cutoff, refine the presentation mask.
6. Compare native and enlarged views on all three backgrounds. Check that
   gold Storm and violet guardian identity remain separate, and that the
   guardian keeps the exact mixed silhouette. The ring remains a preview
   ownership cue, not a hitbox or new gameplay effect.
7. Compare runtime and Canvas attachment rasterization and recoloring. Both
   inverse-sample masks on the native grid, but cross-platform parity has
   not been observed. Measure runtime cost with mixed forms; motif stamping
   issues individual pixel draws, and first-use recoloring builds a cached
   atlas synchronously. This pass has no performance measurements.
8. Exercise earned Ember selection while paused, resume, both paths and
   repeated ranks, death/respawn and saved-rank restoration. Confirm the
   released flow still offers only Ember and cannot activate preview forms.
9. Run the existing animation, session, progression and save coverage and
   the attachment/sequence replacement outcome comparison. Confirm movement,
   collision, cooldowns, attack IDs, burn/reach and hit windows are identical
   under default/alternate art and differing effect phases.
10. Rebuild the web game and capture fresh moving native/4× evidence only
    after source acceptance. Existing exported game files and earlier review
    captures do not contain this redesign. Obtain human gameplay-scale art
    approval before claiming issue #23 complete.

## Deliberate decisions

Strongest-family spike color was chosen over first-upgrade history because
it is reconstructible from existing ranks and communicates the current build.
Tie priority is explicit artwork data, not the progression model's numen
leader selection. Ember always wins in today's released Ember-only scope.

The effect clock does not reset on run/idle/swipe transitions, preventing
repeated attacks from replaying the same first flame frame. It is independent
of mechanics and is preserved by a death remnant. No body animation duration,
authoritative timer or progression rule was changed.
