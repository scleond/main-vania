# Browser delivery research

Research for [issue #2](https://github.com/scleond/main-vania/issues/2), consulted 2026-09-08. This is a shortlist and experiment proposal, not an engine decision or a measured benchmark. Scope: original art made by us, a 20–30 minute desktop-browser demo for friends, five connected sections, and cumulative visible character transformations.

## Recommendation

Shortlist **Godot with GDScript** and **Phaser with TypeScript**. Test Godot first if visual scene/animation authoring is the priority; favor Phaser if browser-native iteration and code review are the priority. Defold is a credible third candidate, but adding a third prototype before encountering a concrete blocker would spend effort without resolving the main choice. This ordering is a project-specific judgment, not an engine performance ranking.

All three can author on macOS and deliver to a browser. None makes our character art, animation consistency, combat feel, or upgrade combinations automatic. There is no evidence here establishing that one is better at LLM-assisted development: that must be judged through a small change-and-debug exercise.

## Documented capabilities and relevant costs

| Area | Godot | Phaser | Defold |
| --- | --- | --- | --- |
| macOS workflow | Native editor; see [system requirements](https://docs.godotengine.org/en/stable/about/system_requirements.html). Integrated visual workflow suits manually arranging rooms and animation. | JavaScript/TypeScript browser framework; use local web tooling on macOS. The framework itself is free; no paid editor is required. [Overview](https://docs.phaser.io/) | Native macOS editor, including installation instructions for Apple Silicon/Intel. [Installation](https://defold.com/manuals/install/) |
| Web build | Godot 4 requires WebAssembly and WebGL 2, Compatibility renderer, and presently cannot export C#. Default single-thread export avoids cross-origin isolation requirements. Safari has documented WebGL issues; it is a test target, not an assumed pass. [Web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) | WebGL/Canvas browser rendering rather than a native-engine WebAssembly export. Pin the major version: current docs include Phaser 4 alongside Phaser 3 tutorials, so generated code must not mix APIs. [Overview](https://docs.phaser.io/), [Phaser 4 tutorial](https://www.phaser.io/news/2026/07/phaser-4-tutorial-project-setup-core-concepts) | Bundles HTML5 through editor; modern WebAssembly browser required. HTTP server needed; serve WASM with correct MIME. Non-threaded and threaded architectures exist; threaded requires cross-origin isolation. HTML5 has no editor hot reload; Chrome debug verification can be slow. Benchmark release builds. [HTML5 manual](https://defold.com/manuals/html5/) |
| Original modular character | Sprite hierarchies and AnimationPlayer support cutout animation; shared pivots and swappable parts are a natural fit. [Cutout tutorial](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html) | Containers transform and order child images/sprites. Keep appearance children separate from the authoritative collision body: nested child physics has documented transform limitations. [Containers](https://docs.phaser.io/phaser/concepts/gameobjects/container) | Sprites support flipbooks and properties can be tweened; game-object hierarchies compose parts. [Animation](https://defold.com/manuals/animation/), [building blocks](https://defold.com/manuals/building-blocks/) |
| Lighting and effects | Built-in 2D lights, shadows and normal/specular maps. Additive animated sprites are a documented cheaper alternative for transient glow. Test the actual Compatibility export; native rendering features are not a web guarantee. [2D lights](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html) | Dynamic lighting exists in WebGL, with normal-map support; Canvas is not an equivalent lighting fallback. Check version-specific APIs before implementing effects. [Phaser 4 lighting](https://docs.phaser.io/api-documentation/4.0.0/namespace/gameobjects-components-lighting) | Current official example uses Light components introduced in 1.13.1 plus sprite materials. “Defold has no 2D lighting” is outdated. Custom effects can require render-script/material work. [2D example](https://defold.com/examples/render/basic_lights_2d/), [render pipeline](https://defold.com/manuals/render/) |

For original art, propose a body with a few named attachment points, one collision silhouette, and shared idle/run/jump timing. Test simultaneous offensive, defensive and movement parts before choosing an asset resolution or animation technique. Swapping a sprite is easy; preventing clipping and keeping the result readable is the production risk. This is an integration recommendation, not a final art specification. No asset packs or paid skeletal-animation tools are necessary for this experiment.

## Input, saves and browser expectations

Keyboard and controller input are available in all candidates. Godot gamepads require HTTPS and a button press for detection; browser/OS mappings can differ. Its browser saves use IndexedDB-backed `user://`, with private-mode and iframe persistence caveats. Default sample audio lacks several engine audio effects. [Godot web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

Phaser exposes keyboard and gamepad input; use a small versioned save object in browser storage rather than treating the runtime data manager as persistence. `localStorage` persists per origin, may throw when storage is blocked, and private-session data is cleared. [Phaser input](https://docs.phaser.io/phaser/concepts/input), [MDN localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)

Defold exposes keyboard and Gamepad API input; an iframe needs the gamepad permission. File saves use a virtual filesystem backed by IndexedDB in HTML5. [Input](https://defold.com/manuals/input/), [gamepads](https://defold.com/manuals/input-gamepads/), [files](https://defold.com/manuals/file-access/)

In every candidate, test Safari, Chrome and Firefox on the actual Mac and record browser versions. General browser support is not proof that our effects, controller and host combination works. Keep keyboard sufficient to finish the demo. Allow play when storage is unavailable; explain that progress then lasts only for the session. Start audio through an explicit Play interaction. These are proposed product behaviors.

## Free hosting shortlist

| Route | Fit and constraints |
| --- | --- |
| itch.io | Convenient game page and browser embed. Upload a ZIP containing `index.html`; use relative, case-correct asset paths. The embed adds input/focus/storage checks. HTML5 hosting is free. [Creator guide](https://itch.io/docs/creators/html5) |
| GitHub Pages | Simple standalone URL alongside the existing repo. Free for public repositories; published site limit 1 GB and soft bandwidth limit 100 GB/month. Use relative base paths for a project site. Start with a non-threaded export so custom isolation headers are unnecessary. [About Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages), [limits](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits) |
| Cloudflare Pages | Alternative when explicit response headers are useful. Free-plan constraints include a 25 MiB per-file limit, which must be checked against engine WASM and packed assets; `_headers` supports static response headers. This adds an account/deployment workflow. [Limits](https://developers.cloudflare.com/pages/platform/limits/), [headers](https://developers.cloudflare.com/pages/configuration/headers/) |

Provisional delivery preference: a standalone GitHub Pages URL for the browser experiment, with itch.io as a later presentation option. No account backend, paid hosting, analytics, or custom domain is needed for this scope. Confirm final artifact sizes and current service limits when publishing.

## No room/map addon yet

Godot already provides tile painting, collision and layered tilemaps; Defold has a tilemap component/editor. [Godot TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html), [Defold tilemaps](https://defold.com/manuals/tilemap/)

For five sections, the necessary game-specific information can be a small room/connection list, objective flags, checkpoints and optional-shortcut conditions. A Metroidvania addon is not inherently necessary. This is a scope judgment: evaluate one only if manual layout/minimap authoring becomes a demonstrated bottleneck. An addon introduces its own data format, version compatibility, export behavior and maintenance dependency; require a pinned version, readable source, license review and a browser export test before adopting it. Do not conflate five world sections with five enormous simultaneously active scenes.

## Disposable feasibility experiment

Use a throwaway branch, not a production scaffold. First build in the preferred candidate; build the same scene in the other shortlisted engine only if the first fails a criterion or the authoring choice remains close.

1. One original placeholder spirit with body, claw, shell and wings; idle/run/jump, direction flip and simultaneous attachment combinations. One small platform room, neighboring room transition, checkpoint, damage and respawn. No progression tree or final art.
2. One attack burst, approximately ten moving enemies, three parallax layers and a toggle for glow/lighting. Compare effects on/off; select scene loads as a stress fixture, not a claim about final density.
3. Keyboard controls, one available controller, explicit Play/audio start, pause on lost focus, versioned local save and reset. Record untested controller hardware explicitly.
4. Release web build on the intended HTTPS host. Check cold load, cached reload, room transition, fullscreen/resize, audio start, tab return, controller reconnect, normal reload persistence, and blocked/private storage. Run Safari, Chrome and Firefox.
5. Record exact engine/browser versions, Mac model, compressed transfer bytes, cold and warm time-to-play across three runs, and median/p95 frame times during a fixed 60-second sequence. Provisional targets: cold playable within 5 seconds on an explicitly recorded network profile, p95 frame time at most 20 ms at the chosen resolution, no visible sustained stutter, and no progression/input blocker. Targets require agreement; they are not measured results.
6. Make one small requested change—add a body part and change respawn behavior—then assess how confidently a novice can locate, review and verify it with agent help. Capture friction and actual edit scope.

The deliverable is a results table, screenshots of combined transformations, the disposable build URL, and a reasoned engine choice. No download-size, startup-speed, universal Safari compatibility, or “best for AI” claim should be promoted from preliminary notes without this evidence. Native export is a fallback to reconsider if both browser candidates fail; it does not satisfy the current browser acceptance target by itself.
