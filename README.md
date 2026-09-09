# Numen

**Numen** is a 2D action-exploration game about a neutral spirit — an unaligned
vessel drifting through a world of elemental essences. When spirits fall, they
leave behind **numen**: small sparks of will. Gather them, attune to the
essences (Ember, Stone, Wind, and more to come), and mix them into your own way
to fight and move.

The fantasy is simple: you begin with nothing and borrow everything. Every
power in the game was once someone else's nature.

## How it plays

- **Explore and fight.** Fast, movement-first combat — jump, dash, and strike
  through rooms of wild spirits.
- **Gather numen.** Fallen spirits release sparks; collect enough to grow.
- **Attune.** Spend numen to take on an elemental essence and change how your
  attacks behave.
- **Mix.** Combine essences into hybrid builds (a preview of Stone + Wind
  exists in the current slice).

## What's playable now

A single Ember combat-room slice: the Neutral Spirit, easy lunge and medium
charge enemies with warnings/recovery, auto-collected graphical numen, paused
Ember choices (Searing Claws burn / Flame Arc reach, repeatable to rank 8),
the shared earning-window ladder (thresholds 8–42, eight-selection cap with a
Fully evolved state), and checkpoint retry that retains numen and upgrades.
It's the feel foundation the rest of the game builds on.

## Run it

Requires **Godot 4.7.2** (pinned in `.godot-version`) and desktop **Chrome**
for the web build.

**In the editor** (fastest): open `project.godot` in Godot, press Play,
then **Enter** in-game.

**In a browser:** serve the checked-in web build and open it in Chrome:

```sh
python3 -m http.server 8774 --directory docs --bind 127.0.0.1
# http://127.0.0.1:8774/ — press Enter to start
```

**Controls:** A/D or arrows to move, Space to jump, J/X to attack, Shift to
dash, Esc to pause, E/K to retry near the checkpoint, N for a fresh run.

## For contributors

- `main.gd` — room, session state, enemies, HUD.
- `player.gd` — gameplay feel (speed, jump, dash, attack timing).
- `visual.gd` — presentation only; safe to tweak without changing feel.
- `tuning.gd` — central gameplay numbers (swipe windows, reach, burn,
  enemy warn/recovery); edit feel here, never in `visual.gd`.
- `progression.gd` — earning-window rules (thresholds, ties, overflow,
  ranks, cap); later elements live in its catalog but only Ember is offered.
- `tests/test_progression.gd`, `tests/test_session.gd` — focused rule and
  session cases: `godot --headless --path . --script tests/test_progression.gd`
  (same for `test_session.gd`).
- `node browser-check.cjs` — Chrome smoke check (needs `npm ci` and
  `npx playwright install chromium`).
- `python3 export.py --godot /path/to/Godot --templates /path/to/templates` —
  rebuild the web export; see `docs/EXPORT.md`.

## License

MIT — see `LICENSE`.
