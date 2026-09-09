# Browser feasibility evidence

Godot 4.7.2 stable, Compatibility, explicit non-threaded web templates. Source and captured export are disposable.

Chrome for Testing 151.0.7922.34 on macOS: all 12 automated checks passed, no recorded console/page errors. Checks cover movement, jump, dash, visible upgrade, shrine flag, checkpoint respawn, save/reload/browser restart, and simulated session-only behavior. See evidence/chromium-results.json.

Latest local startup sample: 1001 ms. RAF sample: median 16.7 ms, p95 17.2 ms over 120 frames. These are local fixture samples, not cold internet startup or full-game performance guarantees. WASM size: 39514754 bytes uncompressed.

User feedback: “I tried the chrome fixture, feels great. Let's move on”. Hands-on Chrome responsiveness accepted. Chrome is the supported browser; Firefox automated evidence is supplementary and Safari is deferred. No hardware controller or explicit audible-output verification is claimed.

Initial export failed because the custom template was threaded, despite the preset flag. Explicit web_nothreads templates resolved the SharedArrayBuffer/isolation failure. Failure records retained in evidence/.

Original block placeholders validate runtime feasibility, not final art quality, real combat, or modular sprite production. Browser-denied storage is simulated, not exhaustively tested. Hosted deployment behavior remains separate from the local check.
