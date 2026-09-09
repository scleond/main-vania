# Neutral spirit movement room

Production vertical slice for issue #19: a small Godot room with keyboard movement, jump, dash, pause, and nearby retry. Gameplay is authored in GDScript and the presentation layer is independently configurable.

## Local run

Open `project.godot` in Godot 4.7.2 and run the project, or serve the checked-in web export:

```sh
python3 -m http.server 8774 --directory docs --bind 127.0.0.1
```

Open `http://127.0.0.1:8774/` in desktop Chrome. Enter starts; A/D or arrows move, Space jumps, Shift dashes, Escape pauses, and K retries at the nearby checkpoint. Controller actions are mapped to the same actions as keyboard input; hardware controller verification is pending.

## Export and hosted verification

Install the official Godot 4.7.2 editor and matching `web_nothreads_debug.zip` and `web_nothreads_release.zip` templates. Run:

```sh
python3 export.py --godot /path/to/Godot --templates /path/to/templates
```

The script writes ignored `build/` output and preserves the checked-in preset. Deploy the resulting web files to the repository's GitHub Pages route and run the same Chrome smoke check against it:

```sh
VANIA_URL=https://<owner>.github.io/<repo>/ node browser-check.cjs
```

The smoke check observes `window.__vania_probe`, the high-level session boundary exposed by the game. It verifies session start, movement, jump, pause, nearby retry, and page errors. Chrome is the supported browser; other browsers are not claimed.

## Separation of concerns

`player.gd` owns collision, movement, jump, dash, action timing, and named gameplay tuning constants. `visual.gd` owns atlas regions, pose sequences, attachment anchors, and presentation playback speeds. Changing its frame arrays or playback speeds cannot alter player physics or action durations. `main.gd` owns the room/session boundary and input mapping.
