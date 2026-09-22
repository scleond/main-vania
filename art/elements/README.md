# Elemental composition — issue #23 redesign

The broader redesign replaced static badges with living native pixel parts.
The latest pass preserves the verified Ember treatment and refines the
remaining families: leg-wrapped Bramble vines, fitted Stone torso
armor, a small Storm belly swirl, textured family-colored spikes for Reprisal,
and compact Wind forms.
The visual source is the **selected B detailed-pixel concept**, the
animation-workflow accessory atlas, and the approved idle/run/eight-motion
spirit. Preserve the cream hood, dark face, tiny body and asymmetrical spikes.
The original concepts are references, not runtime textures.

Open `viewer.html` through a repository-root HTTP server. The workshop loads
source JSON and body atlases directly; no export is needed to see source edits.
The checked-in game export has **not** been rebuilt for this pass. See
[REDESIGN-HANDOFF.md](REDESIGN-HANDOFF.md) for parent verification work.

## Design

Elements grow from the spirit rather than sitting beside it as collectible
icons. Orange hands and a furnace core return Ember to the original concept.
Lightning is gold, reserving violet for guardian ownership. Rear wind trails
leave the face and feet open. Thorns curl into asymmetrical shoots and leaves.
Stone uses dark, broad, overlapping facets with no autonomous movement.

| Family | First acquisition | Motion language | Repeated investment |
| --- | --- | --- | --- |
| Ember | Searing Claws wraps both wrists in fire; Flame Arc reveals a furnace core. | Original four flame contours at 90 ms; original three core frames at 140 ms. | Eight heat palettes, red/orange through blue/white-hot; no additional geometry. |
| Storm | Chain Spark branches above the hood; Thunderbeat is a small blue-ish belly swirl below Flame Arc. | Chain Spark keeps its five branch states; Thunderbeat stays a small pulse-like sparkle. | Additional forks and secondary discharge nodes. |
| Thorn | Barb Shot curls up from the wrist; Bramble Trail wraps both lower legs. | Slow terminal leaf changes at 420/500 ms; rooted stems stay coherent. | Barb Shot adds leaves/shoots; Bramble adds veins within its leg wraps. |
| Stone | Stonehide is fitted, overlapping torso armor; Reprisal textures the existing head spikes. | Stonehide is static; Reprisal is texture-only and has no effect animation. | Stonehide gains inset mineral highlights; armor stays within the torso footprint. |
| Wind | Slipstream is a short, faint waist wisp; Airborne wraps both ankles in translucent mist. | Slipstream keeps its compact 150 ms wisp; Airborne mist stays still. | Compact Slipstream offshoots; Airborne gains internal mist density without expanding. |

Rank zero draws nothing. Rank one is the complete first-acquisition motif.
For Storm, Thorn, Stone and Wind, ranks 2–8 each reveal one internal highlight **only where the current animated
mask has a pixel**; no floating row of rank bars is drawn. Those four families also add authored offshoots at ranks 3, 5 and 8, except Bramble Trail, Stonehide and Airborne: their wraps, armor and mist keep the same body-attached footprints.
Ember has no rank marks, cinders, secondary tongues or growth stamps. These growth stages give silhouette changes while
keeping the footprint bounded. Exact rank remains visible in the controls;
internal highlights are a secondary density cue at gameplay scale, not a
promise that eight ranks can be counted during combat.

### Ember heat and layers

Numen is the collected resource; Ember is the elemental family. Each Ember
path selects its own palette from its own rank; one path never heats the other.
The four ink roles retain a dark edge, flame body, light and hottest center.

| Rank | Heat color |
| --- | --- |
| 1 | Original red/orange with a warm pale center |
| 2 | Brighter orange |
| 3 | Gold/orange with a cream center |
| 4 | Pale gold with an almost white center |
| 5 | Pale blue with a white center |
| 6 | Saturated blue with an icy light |
| 7 | Bright blue with a pale cyan light |
| 8 | Blue edge, luminous ice blue and white-hot center |

For a fixed pose and elemental phase, all ranks use the exact same masks,
attachment count, offsets and cadence. Searing Claws keeps its original fire
motif and near-hand phase. The second instance uses the same motif at the far
wrist, staggered by one frame; both flames exist from rank one. Flame Arc keeps
its original heart motif and chest offset. The split-flame replacement retains
its separately authored motif but uses the same eight palettes and no growth.

Ember composition order is **far claw → body → chest core (excluding near-hand
pixels) → near claw**. The other families retain their existing rear/front
passes. The core's `body_front` pass skips the approved hand mask, letting the
actual body-atlas hand remain in front without cutting a rectangular hole or
painting a second hand over other elements. This works with Flame Arc alone.

Thunderbeat uses `body_effect`, while Stonehide uses `body_under`; both are
drawn over the body and below Flame Arc's `body_front` pass. Reprisal sets a
static spike texture flag instead of mounting a separate effect. Its facets
sample the same dominant-family spike palette used for the main spike color.

`far_hand` comes from the background arm in each approved pose: idle uses the
trail arm, run uses the opposite of its near-arm lead selection, and the six
other motions use the trail arm with torso shift and whole-pose transform.
The existing `hand` socket remains the near wrist. These camera-depth roles do
not swap when facing left: mirror the entire composition, including its mask.
Replacement swipe slots select all sockets and occlusion metadata from the
actual displayed pose, not the original timeline slot.

### Leg wraps and torso armor

Bramble Trail uses two five-by-six-pixel vine wraps over the lower legs,
mounted at the existing near/far ankle positions in `body_under`. Each winding
stem crosses the calf with pale veins and dark edge pixels; the two frames
keep the stem attached and change only a leaf highlight at the original
500 ms cosmetic cadence. No waist vine or ground trail is drawn.

`lower_leg_angle` and `far_lower_leg_angle` follow the knee-to-ankle segment,
not the foot rotation. They are derived from the approved pose's hip, knee
hint and ankle using the original 4.5-pixel limb hinge, then include the
whole-pose angle. Run retains its near/far lead selection. The existing ankle
positions and foot angles used by Airborne are unchanged. A local offset of
(-2, -5) lays each wrap along that calf, ending at its ankle.

Stonehide's static shell follows the original torso crop's stepped silhouette:
shoulder straps, overlapping breast/rib plates, dark seams and a tapered hem.
The chest offset (-6, -3) maps its origin to the source torso's (25, 43),
including the existing torso shift, bob and whole-pose transform. It occupies
`body_under`, below Thunderbeat and Flame Arc. The approved near-hand mask
keeps the foreground hand visible over both armor and vines.

Ranks 2–8 add seven internal vein/mineral highlights to these two paths.
Neither adds external growth stamps, so higher ranks cannot produce detached
vines or stones. These are cosmetic recipes; the named paths'
mechanical definitions, strength, timing and release gating are unchanged.

### Foot mist and fully evolved glow

Airborne uses two sparse translucent pixel masks at each ankle: a rear veil
and a front strand wrapping across the foot. Pale Wind ink has per-role alpha
of 4–23%, with no dark outline. Rank highlights add a little density inside
that footprint; no cloud growth stamps extend along the floor. Slipstream
uses the same faint ink treatment on its existing short waist wisp.

`foot` and `far_foot` sockets are the approved near/far ankles, calculated from
`lead_foot`/`trail_foot` placements plus the rotated (0, -2) ankle offset.
Run swaps depth roles with its lead selection. The six other motions apply
the source whole-pose transform around (31, 49), then subtract (32, 60).
Each socket also records its foot angle plus the whole-pose angle. Mount
`angle_anchor` selects that angle and `motif` selects the rear/front mask.
The metadata follows lifted feet and death poses rather than the torso bob.

The fully evolved aura diffuses the original body pose's alpha behind the
spirit, tinted with the dominant family's main spike color. Two separable
box-blur passes of radius four soften the silhouette through eight pixels of
transparent padding; opacity is capped at 22%. These shared settings live in
`artwork.aura`. Both consumers cache the resulting texture per motion, pose
and family. It has no circular geometry, contour stroke, autonomous animation
or gameplay effect. The existing violet guardian ownership marker is separate.
Family selection and the eight-selection trigger retain their baseline rules;
Numen is the earned resource, not another elemental family.

### Head-spike identity

The family with the highest sum of equipped path ranks colors the existing
cyan spike tips. Ties use the explicit artwork order: Ember, Storm, Thorn,
Stone, Wind. The concept is **strongest affinity**, not first acquisition:
no historical field or save migration is necessary. Either first Ember upgrade immediately warms all three spike tips; earned
other-element ranks select their own dominant-family color.

The recolor samples existing cyan pixels above the local head center, using
each pose's inverse rotation. It retains the approved spike flex, outlines,
cream hood, eyes and transparency, including collapse poses. The original
body PNGs are untouched. Each renderer caches the recolored body atlas per
motion/family; there is no separately authored sprite set per build.

## Editable boundaries

| Source | Responsibility |
| --- | --- |
| `assets/element-parts.json` | Family palettes, distinct spike palettes, eight Ember rank palettes, motifs, per-path growth recipes and dominance tie order. |
| `assets/element-attachments.json` | Singleton or multiple mounts per path; rear/body_under/body_effect/body_front/front layers; head/chest/both wrists and near-hand occlusion placement for every pose. |
| `assets/element-presentation-alternate.json` | Replacement fire recipe, shifted wrist offset and swipe pose sampling. |
| `assets/spirit-motions.json`, `assets/spirit-*.png` | Approved body art, pose sequence and duration data. Unchanged. |
| `elemental_parts.gd`, `visual.gd` | Runtime composition, cached spike recoloring, independent cosmetic clock. |
| `art/elements/viewer.js` | Browser consumer of the same artwork, growth, palette and pose data. |
| `progression.gd`, `tuning.gd`, `player.gd` | Earned ranks and mechanical behavior. Unchanged by this redesign. |

Optional motif `ink_alpha` values multiply palette alpha per ink role; opaque
Ember and Chain Spark recipes are unchanged.

Pixel strings use `.` for transparency and `o`, `x`, `+`, `*` for outline,
shadow/body color, light and hottest highlight. A motif supplies `frames` and
`frame_ms`. A path references one primary motif, an optional `rank_palette`, and growth stamps with
`min_rank`, `motif` and local `offset`. Single-frame motifs remain still even
when the elemental clock advances. Growth stamps are drawn before their root
motif and use staggered frame phases to avoid synchronized flame/wind copies.

An attachment recipe either supplies a single mount or an `instances` array;
each instance supplies its own `anchor`, `offset`, `layer` and optional `phase`.
A path-wide replacement offset applies to both claw instances. Flame Arc, Stonehide and Bramble Trail
use `occluder: near_hand`. Its mask is the alpha of the approved hand crop
(`rig-look.png`, rectangle 39,46,7,4; pivot 2,2), encoded as rows in metadata.
Each pose records the local wrist and whole-pose origin/placement. Both
consumers undo the body transform and round to a source pixel, then sample the
hand mask with the same rounding as the approved authoring renderer. If body
poses ever change, update these sockets and occluder placements together.
No body raster or new body-part atlas is authored by this Ember pass.

Both renderers inverse-sample rotated masks onto whole logical pixels instead
of rotating individual pixel rectangles into subpixel diamonds. Anchor
positions and rotated growth origins are snapped. Existing authored pose
sockets remain the alignment source; paths have newly authored local offsets.
Canvas/Godot rasterization parity remains outside this pass’s browser inspection.

## Workshop controls

- Searing Claws-only and Flame Arc-only rank-one presets for quick isolation.
- All ten path toggles, per-path ranks, batch rank changes, five specialists,
  eight-selection mixed form and explicitly impossible all-ten stress form.
- All eight motions, native/4× player and guardian, both facings, speed,
  pause, restart, body-frame stepping and every-pose strip.
- **Hold body pose; animate elements** isolates material animation on one pose.
- **Step elements +65 ms** and the element-phase scrubber pause both clocks
  and change only the elemental time. Body stepping preserves elemental time.
- Dark ruins, midtone moss and light mist backgrounds expose contrast issues.
- Head, body, near-wrist (green), far-wrist (pink), near-ankle (white) and far-ankle (lavender) crosshairs, plus numeric
  pose, occluder and effective Ember mount/offset data.
- Simultaneous baseline/replacement samples use the same elemental time.

Initial view is both Ember paths at rank one. Specialist presets use four
ranks in each of their two paths. The mixed preset spends eight selections
across five elements. Manually exceeding eight remains labeled impossible.
The guardian is the exact composite recolored with the existing violet
luminance tint, enclosing ring and underfoot ownership marker.

## Runtime and replacement boundary

`visual.gd` advances `element_clock` independently of motion transitions,
attack/dash pose sampling and alternate playback speeds. Pause stops it; a
death remnant snapshots it with ranks so the effect does not restart on death.
Body sampling, duration, state selection and gameplay timers are unchanged.

The released player receives **all earned path ranks**, including Storm, Thorn,
Stone and Wind, from `progression.ranks`. All five mechanics have landed since
this issue was written. At eight selections, the strongest family receives
the diffuse glow. Paused upgrade synchronization and death snapshots retain
those earned ranks. The workshop's custom builds, impossible all-ten stress
build and guardian-copy display remain appearance previews: the viewer has no
progression write, save field or bridge into the released player. No earning
or mechanic is disabled to recreate the older Ember-only release.

The replacement recipe changes Searing Claws to split flames, applies the
existing alternate wrist offset, and samples swipe poses `[0,0,2,2,5,5]`.
Each displayed body pose selects matching sockets. The in-game P presentation
demo retains its previously authored alternate playback rates. The new
cosmetic clock does not alter that demonstration or attack outcomes by design;
the measured replay described below remains for the parent’s test runner.

## Completion and validation status (2026-09-22)

The prior approved artwork, ten path recipes, socket metadata and both
compositors are preserved. This completion pass corrects obsolete Ember-only
workshop labels and replaces indirect test claims with an attached-player
replay. Historical redesign notes in [REDESIGN-HANDOFF.md](REDESIGN-HANDOFF.md)
describe older revisions and release gates; they are not current restrictions.
User acceptance of the art is automatic; no additional review gate is pending.

The parent’s test runner must execute (not run during implementation):

```sh
godot --headless --path . --script tests/test_elemental_presentation.gd
godot --headless --path . --script tests/test_progression.gd
godot --headless --path . --script tests/test_session.gd
```

The new replay uses the real scene, attached `CharacterBody2D`, world collision
shapes, input actions and production callbacks at 60 physics ticks per second.
Each 180-tick baseline/replacement pair earns the same build through progression:
first Ember claws/core, rank-eight claws, or eight paths across all five families.
Each pair runs in both facings. Memory storage isolates the runs from user saves.
It compares every tick’s position, velocity, grounding, jump/dash/attack timers,
attack IDs, collision size, enemy hit IDs/HP/knockback/burn clocks, secondary
effects, progression and synchronized visual ranks. It prints measured hit
ticks, damage, running displacement, jump velocity and dash velocity, and reports
the first mismatched tick. Positive checks require movement, jumping, dashing,
hits and different displayed poses, so an inert replay cannot establish success.
The claw motif, both wrist offsets and consumed swipe sequence must also differ.
The former detached-Visual tuning comparison and legacy `swipe_boxes` count
claim have been removed/replaced. The replay is bounded evidence, not an
exhaustive proof over every possible input/build.

No tests were run in this pass. The checked-in web game export was not rebuilt.
The parent independently reads the integration and owns test execution and commit.

### Non-test visual inspection

The existing Chromium workshop was used to capture its pose strips at fixed
cosmetic time, without test assertions or a new viewer. Inspected first Ember,
the eight-selection mixed build and the explicitly impossible all-ten stress
build across all eight motions, with native player/copy pairs in both facings.
[Native mixed contact sheet](inspection-native.png) records the cap build.
[Replacement alignment](inspection-replacement.png) records swipe slot four,
which displays pose three under replacement, with head/chest/wrist/ankle anchors
and simultaneous baseline/replacement samples.

In these captures the cream hood and dark face remain open; hand flames and
chest core follow the arm/body poses, fitted armor stays on the torso, and the
feet track lifted/run/collapse poses. The guardian retains the same composite
silhouette with an immediately different violet treatment. Wind mist remains
subtle at native size; exact rank is not reliably countable from internal pixels.
These are source-viewer stills, not proof of runtime rendering parity, temporal
smoothness or movement/combat equivalence. The test runner supplies the latter
measurement; no gameplay, tests or export were executed here.

### Acceptance coverage

| Criterion | Existing implementation / completion evidence |
| --- | --- |
| Five families, ten paths, first/repeat ranks to cap eight | Shared motif/palette/growth recipes preserved; per-path rank controls retained; replay includes first Ember, rank-eight claws and a legal mixed cap build. |
| Toggles, mixed/specialized builds, eight motions, facing, stepping, anchors | Existing workshop reused; native all-motion and replacement captures above. |
| Independently editable art, poses and mechanics | Artwork, attachment and replacement JSON remain separate from progression/player/tuning; no production mechanics changed. |
| Earned integration and isolated previews | All five earned families retained; obsolete Ember-only wording corrected; browser builds cannot write gameplay ranks or saves. |
| Distinguishable guardian copy, including heavy mixing | Same composition plus violet tint and ownership markers; mixed-cap and all-ten stress stills inspected. |
| Replacement and unchanged outcomes; silhouette/alignment | Existing split claw, both wrist offsets and swipe remap retained; actual-player replay added but awaits execution; source-viewer inspection recorded above. |
