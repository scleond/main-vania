# Throwaway spirit visual-direction experiment

Question: which original style makes the spirit, cumulative upgrades, and guardian copy readable and feasible?

Open `index.html` directly, or run from the repository root:

```sh
python3 -m http.server 8765 --directory prototypes/visual-direction --bind 127.0.0.1
```

Then visit `http://127.0.0.1:8765/?variant=A`. Use A/B/C buttons or left/right arrow keys. The 768 px view shows how detail survives reducing the entire sheet; it is not a locked game resolution.

## Artifacts

- `a-inked-cutout.png`: bold outlines and layered-looking parts.
- `b-detailed-pixel-art.png`: detailed pixel-style treatment.
- `c-soft-painted.png`: soft brush shading and atmospheric scenery.
- `prompts.json`: exact prompts; all three were produced using the built-in image generation tool, with no asset packs or input reference art.

Each sheet contains neutral, Ember, mixed, and mirror forms plus a small side-scrolling scene. These are flattened concept images, not segmented animation-ready assets. Pixel-grid consistency, source layers, exact sprite size, animation, and renderer performance have not been validated. The generated mirror and mixed designs are visually close but are not guaranteed identical geometry; production will reuse the same character parts.

Decision: the user selected B — Detailed pixel art, with deliberately low-frame-count animation. A and C remain comparison evidence only. Exact sprite size, palette, attachment layout, and frame counts will be validated in the animation workflow experiment. These concept sheets are not production game assets. Preserve this experiment on `prototype/pixel-art-direction`.

Decision: https://github.com/scleond/main-vania/issues/6
