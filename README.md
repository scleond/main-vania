# Throwaway Godot browser-feasibility experiment

Question: can the selected Godot approach deliver a tiny desktop-browser scene with responsive input, stepped sprite motion, a visible upgrade, and persistent checkpoint state?

This is an original block-art fixture, **not the chosen final pixel art, combat prototype, or production scaffold**. Godot is pinned to **4.7.2 stable**, GDScript, Compatibility renderer, non-threaded web template.

## Try it

The `docs/` export is ready for GitHub Pages. Locally, run:

```sh
python3 -m http.server 8766 --directory docs --bind 127.0.0.1
```

Open `http://127.0.0.1:8766/`. Start using the New Game button or N; C continues. A/D or arrows move, Space jumps, Shift dashes. U adds a fixture upgrade and three souls; H sets a shrine flag; R records the current checkpoint; K respawns. These shortcuts exercise storage rather than implement the actual progression rules.

Use `?storage=off` to simulate session-only operation. This is a controlled bypass, not proof of behavior under every browser privacy policy. All saves use a prototype-specific versioned file, separate from any eventual game save.

Gamepad left stick, A, and X are mapped to movement, jump, and dash but hardware verification is pending. A short tone should play after starting/interacting; audible output needs human verification.

## Re-export

Get the official [Godot 4.7.2 editor and matching templates](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable). Extract `web_nothreads_debug.zip` and `web_nothreads_release.zip` from the template archive. Then:

```sh
python3 export.py --godot /path/to/Godot --templates /path/to/templates
```

The script temporarily supplies template paths and restores the checked-in preset. `web_release.zip` is the threaded template and fails this no-isolation-header hosting approach; use the explicit `nothreads` files. The ignored `build/` folder is the fresh output; `docs/` is a captured runnable export.

## Evidence and remaining checks

See `EVIDENCE.md` and the JSON records in `evidence/`. Browser automation uses an existing local Playwright 1.62.1 installation; adjust the require path in `browser-check.cjs` or install that version in a disposable directory to rerun. Browser profiles are isolated under OS temp. No new dependency was installed in the main repository.

Chrome is the supported browser for this demo. The user tried the Chrome fixture and reported that it feels great. Safari and Firefox support are deferred. Real controller mappings and audible output still need explicit verification. This experiment does not establish full-game performance or validate the animation-production workflow.

Decision: [Validate a tiny Godot desktop-browser export](https://github.com/scleond/main-vania/issues/17). The parent engine decision remains open until the necessary evidence and human feedback are complete.
