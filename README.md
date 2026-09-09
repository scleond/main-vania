# Throwaway Ember combat/evolution slice

Question: do approachable movement/combat and the first earned elemental upgrade feel rewarding enough to expand?

Open the locally served export in Chrome. Run `python3 -m http.server 8774 --directory docs --bind 127.0.0.1`, then visit http://127.0.0.1:8774/. Alternatively open project.godot in Godot 4.7.2 and run.

## Try it

- Enter starts. A/D or arrows move, Space jumps, J/X swipes, Shift dashes.
- Fight small groups: three groups of two easy enemies, then one medium. Easy enemies grant one soul; medium two. The room repeats so retries and post-upgrade comparisons remain possible.
- Earn eight Ember souls to pause and choose Searing Claws (1) or Flame Arc (2). Burn damages enemies over time; Arc extends the swipe. Both show the shared Ember attachments. This experiment implements only the first selection; subsequent souls are retained against the next threshold but no second level-up is offered.
- M toggles a clearly labeled Stone/Wind preview: reduced damage, one air jump and shorter dash cooldown, with layered parts. This does not spend souls or stand in for the final progression rules.
- E rests near the glowing checkpoint. K triggers a nearby respawn for comparison. Death/rest repopulate the room and retain earned souls/upgrade. N starts fresh to try the other choice. Escape pauses; losing focus pauses.
- Session state only: refreshing or closing resets the experiment. Browser-save feasibility was tested separately; this is not a new production save system.

One particle per soul depicts reward quantity. Rewards are credited immediately and the particles are cosmetic; the choice waits briefly so their travel is visible. Exact particle treatment remains deferred. The medium is larger, has more health and a longer warning/charge/recovery. Orange ground warnings indicate attack direction; a blue dot indicates recovery. Dash briefly avoids damage. Timing and damage are provisional, not accepted balance.

Gamepad mappings exist (left stick, A jump, X swipe, right shoulder dash); hardware remains unverified. No audio, shrine, miniboss, other native enemy elements, full upgrade tree, enemy modifiers, guardian, or whole-world pacing is demonstrated.

## Sources and scope

Godot 4.7.2/GDScript, Compatibility, non-threaded web export. Original draft spirit atlas and modular renderer reused from the animation experiment. Enemies/environment are deliberately simple original code-drawn placeholders. The atlas still needs production cleanup. No new art polish was undertaken.

main.gd holds the disposable room, encounters and session state. player.gd handles movement/swipe and uses visual.gd for the shared draft art. The inherited art prompts identify the generated source. Prior evidence on this branch relates to earlier experiments; see FEEL-EVIDENCE.md for this slice.

Re-export: `python3 export.py --godot /path/to/Godot --templates /path/to/templates`, using matching web_nothreads templates. build/ is fresh output; docs/ is the captured web export.

Decision: [Validate the smallest movement combat and evolution slice](https://github.com/scleond/main-vania/issues/8). Human feedback is required before closure. Check responsiveness, warning/recovery fairness, soul readability, the difference after upgrading, and mixed-form clarity. This is a disposable decision experiment, not a production scaffold.
