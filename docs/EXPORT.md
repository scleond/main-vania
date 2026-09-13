# Web export status

The checked-in Web loader and artifacts (`index.html`, `index.js`, `index.pck`, and
`index.wasm`) are generated from the issue-21 source and reference one another by
their checked-in names. Regenerate them rather than editing export artifacts manually.

The export requires these matching Godot 4.7.2 templates:

- `web_nothreads_debug.zip`
- `web_nothreads_release.zip`

The successful regeneration used matching templates from the local template cache.

After installing those templates, regenerate rather than editing export artifacts
manually:

```sh
python3 export.py --godot "$(command -v godot)" --templates /path/to/templates
cp build/index.* docs/
```
