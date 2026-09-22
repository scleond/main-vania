# Representative section tuning — issue #26

The **baseline** is the values before this pass. The **review candidate** is the
current `tuning.gd`. Revert any candidate value to its baseline value to undo
that part of the pass; no look assets were changed.

| Gameplay value | Baseline | Review candidate | Intended feel |
| --- | ---: | ---: | --- |
| `PLAYER_GROUND_ACCELERATION` | instant speed | 900 px/s² | Short ground takeoff |
| `PLAYER_GROUND_STOPPING` | instant stop | 1250 px/s² | Firm release without a snap |
| `PLAYER_AIR_ACCELERATION` | instant speed | 510 px/s² | Useful, limited air steering |
| `PLAYER_AIR_STOPPING` | instant stop | 230 px/s² | Preserve jump momentum |
| `DASH_DURATION` | 0.13 s | 0.16 s | About 54 px instead of 44 px at 340 px/s |
| `DASH_COOLDOWN` | 0.65 s | 0.58 s | More frequent traversal/dodges |
| `JUMP_SPEED` | 310 px/s | 320 px/s | Slightly higher platform clearance |
| `INVULNERABLE_DURATION` | 0.85 s | 0.95 s | More time to recover after damage |
| `SWIPE_DURATION` | 0.26 s | 0.30 s | Readable attack motion |
| `SWIPE_COOLDOWN` | 0.38 s | 0.36 s | Quicker repeat opportunity |
| `SWIPE_ACTIVE_LATE` | 0.22 s remaining | 0.23 s remaining | 0.07 s anticipation |
| `SWIPE_ACTIVE_EARLY` | 0.07 s remaining | 0.08 s remaining | 0.08 s recovery |
| `SWIPE_BASE_REACH` | 38 px | 42 px | More forgiving baseline swipe |
| `SWIPE_ARC_RANK1_REACH` | 58 px | 66 px | Rank 1 Flame Arc adds 24 px reach |
| `SWIPE_KNOCKBACK` | 7 px | 10 px | Clearer hit impact |
| `EASY_WARN_DURATION` | 0.65 s | 0.72 s | Readable lunge tell |
| `EASY_RECOVER_DURATION` | 0.85 s | 0.95 s | Punish window after miss |
| `MEDIUM_WARN_DURATION` | 0.85 s | 0.95 s | Readable charge tell |
| `MEDIUM_RECOVER_DURATION` | 1.25 s | 1.35 s | Punish window after charge |
| `CHECKPOINT_RETRY_RANGE` | 45 px | 55 px | Easier nearby retry interaction |
| `MINIBOSS_HP` | 18 | 16 | Shorter baseline fight |
| `MINIBOSS_WARN_DURATION` | 0.95 s | 1.05 s | Clear slam tell |
| `MINIBOSS_SLAM_RECOVER` | 1.4 s | 1.55 s | Longer punish window |

Unchanged by design: Spirit HP 6; easy/medium/Miniboss contact damage 1/2/2;
swipe damage 1; Searing Claws burn timing and damage; Flame Arc reach gain per
later Rank 6 px; dash speed 340 px/s; enemy lunge speeds and durations. These
retain the existing three-hit medium damage danger and each Upgrade path's
distinct value. Numen, Level-up, and Rank rules remain in `progression.gd`.

## Timing alignment

The Spirit swipe has 0.07 s anticipation, 0.15 s active, and 0.08 s recovery
within its 0.30 s motion. `player.gd` starts the timer and `main.gd` calls
`Tuning.swipe_is_active`; `visual.gd` maps its wind-up, strike, and recovery
poses to those phase boundaries without changing the hit window.
Enemy warning, lunge, and recovery states are timed in `main.gd` from
`tuning.gd`. `ember_art.gd` receives those semantic states for warning and
recovery colors. Miniboss slam and fire wave states use the same separation.
Sprite frame counts and animation playback cannot start or extend damage.

## Review status

The running `main.tscn` scene launched headlessly without errors. The session
and Ember-section checks exercised route encounters, warning/lunge/recovery,
Miniboss phases, Shrine, Checkpoint, retries, and Upgrade path state. These are
mechanical checks; a human still needs to play the complete route to judge feel.

The focused `art/ember/preview.gd` viewer launched headlessly and produced
`art/ember/review.png`. Inspection of that plate shows distinct orange warning
and cool recovery cues for easy/medium creatures beside the Miniboss and
Checkpoint. This static plate cannot prove motion timing. No look assets were
changed. Remaining review: hands-on movement, combat, retry, and upgrade feel,
plus real-time observation of swipe anticipation/active/recovery. User hands-on
feedback is required before this gate is complete or other Elements are added.
