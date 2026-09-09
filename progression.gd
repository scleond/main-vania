extends RefCounted
## Shared earning-window progression rules (issue #20).
##
## Numen earned since the previous level-up form the current earning window.
## Cumulative lifetime totals unlock level-ups at THRESHOLDS; selecting an
## upgrade consumes one window requirement from the front of the queue while
## excess numen keep their elements for the next window. After SELECTION_CAP
## selections the spirit is Fully evolved and progression numen stop
## accumulating. All ten paths of the five elements live in PATH_CATALOG so
## later slices can reuse this model; the session UI gates offers to Ember.
const ELEMENTS: Array = ['ember', 'storm', 'thorn', 'stone', 'wind']
const THRESHOLDS: Array = [8, 14, 20, 26, 30, 34, 38, 42]
const SELECTION_CAP := 8
const PATH_CATALOG: Dictionary = {
	'searing_claws': {'element': 'ember', 'name': 'Searing Claws', 'blurb': 'Swipes ignite enemies'},
	'flame_arc': {'element': 'ember', 'name': 'Flame Arc', 'blurb': 'Swipes reach farther'},
	'chain_spark': {'element': 'storm', 'name': 'Chain Spark', 'blurb': 'Swipe hits arc to nearby enemies'},
	'thunderbeat': {'element': 'storm', 'name': 'Thunderbeat', 'blurb': 'Every third swipe releases a pulse'},
	'barb_shot': {'element': 'thorn', 'name': 'Barb Shot', 'blurb': 'Swipes launch a thorn projectile'},
	'bramble_trail': {'element': 'thorn', 'name': 'Bramble Trail', 'blurb': 'Dashes leave a damaging patch'},
	'stonehide': {'element': 'stone', 'name': 'Stonehide', 'blurb': 'Reduces incoming damage'},
	'reprisal': {'element': 'stone', 'name': 'Reprisal', 'blurb': 'Retaliatory burst when hurt'},
	'slipstream': {'element': 'wind', 'name': 'Slipstream', 'blurb': 'Reduces dash cooldown'},
	'airborne': {'element': 'wind', 'name': 'Airborne', 'blurb': 'Adds an air jump and aerial control'},
}
## Elements whose paths the current slice may offer in the live session.
const PLAYABLE_ELEMENTS: Array = ['ember']

var window_queue: Array = []
var ranks: Dictionary = {}
var lifetime: int = 0
var selections: int = 0
var pending_element: String = ''


func _init() -> void:
	reset()


func reset() -> void:
	window_queue.clear()
	ranks.clear()
	lifetime = 0
	selections = 0
	pending_element = ''


func is_fully_evolved() -> bool:
	return selections >= SELECTION_CAP


## Number of thresholds the lifetime total has unlocked so far.
func unlocked() -> int:
	var count := 0
	for threshold in THRESHOLDS:
		if lifetime >= int(threshold) and count < SELECTION_CAP:
			count += 1
	return count


func pending_level_ups() -> int:
	return unlocked() - selections


func next_threshold() -> int:
	if is_fully_evolved():
		return -1
	return int(THRESHOLDS[mini(selections, THRESHOLDS.size() - 1)])


## Numen consumed from the window by the next selection.
func window_requirement() -> int:
	if is_fully_evolved():
		return 0
	var previous: int = 0 if selections == 0 else int(THRESHOLDS[mini(selections - 1, THRESHOLDS.size() - 1)])
	return next_threshold() - previous


func window_total() -> int:
	return window_queue.size()


func window_counts() -> Dictionary:
	var counts := {}
	for element in ELEMENTS:
		counts[element] = 0
	for numen in window_queue:
		counts[numen] = int(counts.get(numen, 0)) + 1
	return counts


## Earn numen into the window. Ignored once Fully evolved. Returns pending.
func earn(element: String, amount: int) -> int:
	if is_fully_evolved():
		return pending_level_ups()
	if not ELEMENTS.has(element):
		return pending_level_ups()
	for i in range(maxi(amount, 0)):
		if is_fully_evolved():
			break
		window_queue.append(element)
		lifetime += 1
	return pending_level_ups()


## Elements tied for the most window numen (empty when the window is empty).
func dominant_elements() -> Array:
	var counts := window_counts()
	var leaders: Array = []
	var best := 0
	for element in ELEMENTS:
		var value := int(counts[element])
		if value > best:
			best = value
			leaders = [element]
		elif value == best and value > 0:
			leaders.append(element)
	return leaders


func paths_of(element: String) -> Array:
	var paths: Array = []
	for path_id in PATH_CATALOG:
		if String(PATH_CATALOG[path_id]['element']) == element:
			paths.append(path_id)
	return paths


## Current offer: none, an element choice (tied leaders), or a path choice.
func offer() -> Dictionary:
	if pending_level_ups() <= 0 or is_fully_evolved():
		return {'kind': 'none'}
	if pending_element != '':
		return {'kind': 'paths', 'element': pending_element, 'paths': paths_of(pending_element)}
	var leaders := dominant_elements()
	if leaders.size() > 1:
		return {'kind': 'elements', 'elements': leaders}
	if leaders.size() == 1:
		return {'kind': 'paths', 'element': leaders[0], 'paths': paths_of(leaders[0])}
	return {'kind': 'none'}


## Session-gated offer: path choices only for playable elements, so later
## elements stay in the catalog (and rule fixtures) without appearing in play.
func session_offer() -> Dictionary:
	var current := offer()
	if current['kind'] == 'paths' and not PLAYABLE_ELEMENTS.has(current['element']):
		return {'kind': 'withheld', 'element': current['element']}
	return current


## Resolve a tied-leader choice before picking a path. Returns success.
func choose_element(element: String) -> bool:
	var current := offer()
	if current['kind'] != 'elements':
		return false
	if not current['elements'].has(element):
		return false
	pending_element = element
	return true


func rank_of(path_id: String) -> int:
	return int(ranks.get(path_id, 0))


## Select a repeatable path. Consumes one window requirement, keeps excess
## typed numen. Returns false when the selection is not currently legal.
func select_path(path_id: String) -> bool:
	if pending_level_ups() <= 0 or is_fully_evolved():
		return false
	if not PATH_CATALOG.has(path_id):
		return false
	var current := offer()
	if current['kind'] != 'paths':
		return false
	if String(PATH_CATALOG[path_id]['element']) != String(current['element']):
		return false
	var requirement := window_requirement()
	for i in range(mini(requirement, window_queue.size())):
		window_queue.pop_front()
	ranks[path_id] = rank_of(path_id) + 1
	selections += 1
	pending_element = ''
	return true


func to_state() -> Dictionary:
	return {
		'version': 1,
		'window_queue': window_queue.duplicate(),
		'ranks': ranks.duplicate(),
		'lifetime': lifetime,
		'selections': selections,
		'pending_element': pending_element,
	}


func from_state(state: Dictionary) -> void:
	reset()
	window_queue = Array(state.get('window_queue', [])).duplicate()
	ranks = Dictionary(state.get('ranks', {})).duplicate()
	lifetime = int(state.get('lifetime', 0))
	selections = int(state.get('selections', 0))
	pending_element = String(state.get('pending_element', ''))
