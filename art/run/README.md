# Approved run animation

Open `viewer.html` for the run-only preview, or serve the repository and open `art/motions/viewer.html` for all eight motions and their native/4x GIFs. The complete validation report is [../motions/REVIEW.md](../motions/REVIEW.md).

`rig-look.png` is the canonical editable native pixel look. `run-poses.json` holds the eight poses, fixed limb lengths, spike masks/angles, timing and shared (32,60) pivot. `export.gd` renders the transparent 512x64 runtime atlas and contact sheet. It also supplies the shared pixel-part renderer for idle and the other motions.

From the repository root:

```sh
godot --headless --path . --script art/run/export.gd --quit-after 1
python3 art/run/export-gif.py
```

The cycle alternates contact, recoil, push-off and flight at 8 fps. At most one foot touches the floor in each frame. Opposite stride halves share the same limb lengths and choreography. The spikes flex around contact/push-off; the wider contact and flight poses are the user-approved baseline.

The visual direction comes from `prototype/pixel-art-direction` / 619bb5e (selected detailed pixel direction B) and the original animation-workflow / 218fb61. The approved native parts retain the cream oversized hood, three asymmetrical cyan-tipped spikes, dark face, two cyan eyes, small body and cyan extremities.

`source.png`, `frame-5-source.png`, `frame-1-source.png` and `frame-5-flight-source.png` preserve earlier art drafts. They are not consumed by the final exporter. The final source is the native look plus pose metadata above.
