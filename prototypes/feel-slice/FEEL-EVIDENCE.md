# Feel-slice inspection

Chrome via the existing local Playwright installation on macOS. No recorded browser console/page errors in three keyboard-driven runs. Evidence JSON and screenshots are in evidence/feel-*.

The first neutral run exercised jump and dash, earned eight souls through combat with a death/retry, selected Searing Claws, toggled mixed preview, and verified that explicit respawn retained souls/upgrade and restored health. Two further runs with the mixed preview enabled reached the medium enemy, earned the choice, and selected each Ember path in separate runs. Continued combat showed active burning enemies in the burn branch; the Arc branch remained non-burning. Both continued after a combat death with their chosen upgrade retained. These actions used browser keyboard input, not injected souls or forced enemy deaths.

The inspection does not establish subjective fairness, pacing, final visual quality or full-game performance. The simple automation trades hits and is not a model of human play. It did not independently measure exact Arc reach, damage-reduction ratios, soul-particle counts, or controller hardware. The only change following the combat runs removes a misleading next-threshold denominator from the post-upgrade HUD, because this slice offers only one earned upgrade.

Build/export uses Godot 4.7.2 Compatibility and explicit non-threaded templates. macOS sandbox editor-settings/user-directory warnings occur during export; export succeeds and the web runtime loads. No persistent user save is part of this slice. Refresh resets session state.

Human feedback remains pending on the linked feel decision. Old browser/animation evidence inherited on this branch concerns the earlier prototypes, not this slice.
