# Neutral spirit movement room

Production vertical slice for issue #19: a small Godot room with keyboard movement, jump, dash, pause, and nearby retry. Gameplay is authored in GDScript and the presentation layer is independently configurable.

## Local run

Install Godot 4.7.2 (the required version is recorded in `.godot-version`; on macOS, `brew install --cask godot`), then open `project.godot` and run the project. You can also serve the checked-in web export:

```sh
python3 -m http.server 8774 --directory docs --bind 127.0.0.1
```

Open `http://127.0.0.1:8774/` in desktop Chrome. Enter starts; A/D or arrows move, Space jumps, Shift dashes, Escape pauses, and E/K retries when near the checkpoint. Controller Start and Back use those same pause/retry actions; hardware controller verification is pending. P swaps to an alternate frame/playback profile, which the smoke check verifies without changing movement outcomes.

## Export and hosted verification

Install the official Godot 4.7.2 editor and matching `web_nothreads_debug.zip` and `web_nothreads_release.zip` templates. Run:

```sh
python3 export.py --godot /path/to/Godot --templates /path/to/templates
```

The script writes ignored `build/` output and preserves the checked-in preset. It also normalizes the Godot loader to the exported `index.wasm` filename. A human can validate the game locally with Godot and validate the export locally by serving `build/`; the hosted check is still useful for the actual GitHub Pages boundary. Deploy the resulting web files to the repository's GitHub Pages route and run the same Chrome smoke check against it:

```sh
VANIA_URL=https://<owner>.github.io/<repo>/ node browser-check.cjs
```

The smoke check observes `window.__vania_probe`, the high-level session boundary exposed by the game. It verifies session start, movement, jump, pause, nearby retry, and page errors. Chrome is the supported browser; other browsers are not claimed.

For a local smoke check, run `npm ci`, install the Playwright browser with `npx playwright install chromium`, serve the export, and run `node browser-check.cjs`. CI performs these steps automatically on every push and pull request.

## Separation of concerns

`player.gd` owns collision, movement, jump, dash, action timing, and named gameplay tuning constants. `visual.gd` owns atlas regions, pose sequences, attachment anchors, and presentation playback speeds. Changing its frame arrays or playback speeds cannot alter player physics or action durations. `main.gd` owns the room/session boundary and input mapping.
