# Elemental Metroidvania

A small spirit explores a connected world and grows through the elemental numen of defeated enemies.

## Language

**Spirit**:
The player character, initially elementally neutral, whose permanent upgrades visibly transform its body.
_Avoid_: Vanilla flavor (the starting state is neutral, not food-themed)

**Element**:
One of five affinities shared by enemies, numen, and upgrades: Ember, Storm, Thorn, Stone, and Wind.

**Ember**:
The offensive element associated with burning and close-range aggression.

**Storm**:
The offensive element associated with attacks that chain between enemies.

**Thorn**:
The offensive element associated with projectiles and lingering damage.

**Stone**:
The defensive element associated with protection and retaliation.

**Wind**:
The movement element associated with agility and aerial control.

**Numen**:
An automatically collected elemental reward from a defeated enemy, including a respawned regular enemy. Easy enemies grant one numen, medium enemies two, and section minibosses provisionally five, until the spirit is fully evolved.

**Level-up**:
An opportunity triggered by a shared total-numen threshold that pauses play to offer two upgrades from the dominant element. Counts used for that selection reset afterward; excess numen retain their elements in the next earning window.

**Dominant element**:
The element with the most numen earned since the previous level-up. When elements tie for the lead at a level-up, the player chooses among them.

**Upgrade**:
A permanent change to the spirit's abilities and appearance that accumulates with previously chosen upgrades, including those from other elements.

**Upgrade path**:
One of two repeatable upgrade choices belonging to an element. Its first selection adds a mechanic and body feature; later selections strengthen them.

**Rank**:
The number of selections invested in an upgrade path. All paths share a limit of eight upgrade selections per playthrough.

**Fully evolved**:
The spirit's state after eight upgrade selections, when progression numen stop accumulating.

**Searing Claws**:
The Ember upgrade path that makes swipe hits ignite enemies.

**Flame Arc**:
The Ember upgrade path that gives swipes a wider fiery reach.

**Chain Spark**:
The Storm upgrade path that makes swipe hits arc to nearby enemies.

**Thunderbeat**:
The Storm upgrade path that releases a damaging pulse on every third swipe.

**Barb Shot**:
The Thorn upgrade path that launches a thorn projectile with a swipe.

**Bramble Trail**:
The Thorn upgrade path that leaves a short-lived damaging patch after a dash.

**Stonehide**:
The Stone upgrade path that reduces incoming damage.

**Reprisal**:
The Stone upgrade path that releases a retaliatory burst when the spirit takes damage.

**Slipstream**:
The Wind upgrade path that reduces dash cooldown.

**Airborne**:
The Wind upgrade path that adds one air jump and improves aerial control. Additional ranks improve control without adding more air jumps.

**Section**:
One of five connected regions of the single world, each populated mostly by enemies of one element and containing an objective.
_Avoid_: Level (when referring to a region)

**Section objective**:
Awakening a section's dormant shrine after its encounter, without requiring that section's elemental upgrades. Completing all five, in any order, unlocks the final encounter beneath the sanctuary.

**Sanctuary**:
The central safe area with an entrance to each of the five sections and the final encounter beneath it.

**Shrine**:
A dormant site in each section that the spirit awakens to complete its section objective. An awakened shrine stays completed after death or rest.

**Shrine influence**:
An awakened shrine's persistent environmental effect at two authored locations outside its home section. Each location receives one influence; activation order changes when the world gains these effects.

**Empowered section**:
One of the two sections whose shrines remain dormant when the third shrine awakens. Its regular enemies and remaining miniboss gain elemental modifiers that persist through death and rest.

**Enemy modifier**:
One visibly indicated elemental ability added to an enemy in an empowered section, chosen with equal probability from the four elements other than its native element. It preserves that enemy's original element, difficulty tier, and soul reward, and does not reroll or stack after further shrine activations.

**Regular enemy**:
An easy or medium enemy in deliberately placed encounters, with an approximate 90/10 easy-to-medium mix. Each section has two native regular enemy types, with occasional visitors from neighboring elements near connecting passages.

**Miniboss**:
A stronger enemy guarding a section's shrine, provisionally worth five numen. Defeating it unlocks that shrine, and it stays defeated after death or rest.

**Guardian**:
The two-phase final boss beneath the sanctuary, accessible after all five shrines are awakened. At half health it transforms from its elemental form into a copy of the spirit's current evolved appearance and upgrade paths, with separately tuned combat strength.

**Mirror phase**:
The guardian's final phase, using the spirit's build captured at the transformation and held stable for that attempt. It acts independently with readable attacks, recovery openings, and a contrasting outline and effects.

**Checkpoint**:
A healing and respawn point at a section entrance, before its shrine encounter, or outside the guardian encounter. Death or deliberate rest restores the regular enemy arrangement; crossing room boundaries alone does not.
