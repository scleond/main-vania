# Web export status

The checked-in Web loader and artifacts (`index.html`, `index.js`, `index.pck`, and
`index.wasm`) remain from the last successful export and continue to reference one
another by their checked-in names. They predate issue #21 and **do not contain**
its Continue/New Game, versioned browser-save, or session-only fallback behavior.
Do not use `docs/` to validate those behaviors until it is regenerated.

This workspace could not regenerate that export for issue #21: Godot 4.7.2
requires these matching templates, which are not installed here:

- `web_nothreads_debug.zip`
- `web_nothreads_release.zip`

After installing those templates, regenerate rather than editing export artifacts
manually:

```sh
python3 export.py --godot "$(command -v godot)" --templates /path/to/templates
cp build/index.* docs/
```
