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

A single movement-room slice: the Neutral Spirit, basic combat, checkpoint
retry, and a first Ember attunement choice. It's the feel foundation the rest
of the game builds on.

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
- `node browser-check.cjs` — Chrome smoke check (needs `npm ci` and
  `npx playwright install chromium`).
- `python3 export.py --godot /path/to/Godot --templates /path/to/templates` —
  rebuild the web export; see `docs/EXPORT.md`.

## License

MIT — see `LICENSE`.
