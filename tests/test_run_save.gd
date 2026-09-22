extends SceneTree
## Production save behavior (issue #21).
## Run: godot --headless --path . --script tests/test_run_save.gd
## Uses a controlled storage seam and compares observable restored state, never
## JSON field order or progression's fixture-oriented serialization.
var RunSave = load('res://run_save.gd')
var failures := 0
var checks := 0


class MemoryStorage:
	extends RefCounted
	var files := {}
	var available := true

	func read_text(path: String) -> Dictionary:
		if not available:
			return {'found': false, 'unavailable': true}
		return {'found': files.has(path), 'text': files.get(path, '')}

	func write_text(path: String, text: String) -> bool:
		if not available:
			return false
		files[path] = text
		return true

	func erase(path: String) -> bool:
		if not available:
			return false
		files.erase(path)
		return true


func check(name, cond, detail = ''):
	checks += 1
	if cond:
		print('PASS: ', name)
	else:
		failures += 1
		printerr('FAIL: ', name, ' :: ', detail)


func make_scene(storage):
	var packed = load('res://main.tscn')
	var scene = packed.instantiate()
	scene.run_store = RunSave.new(storage)
	scene._ready()
	return scene


func _initialize():
	var storage = MemoryStorage.new()
	var first = make_scene(storage)
	check('new-game menu communicates automatic saving', first.menu_detail.text.contains('saves automatically'), first.menu_detail.text)
	first.new_game()
	# Simulate combat earning a typed mixed window, then apply one Ember path.
	first.progression.earn('ember', 8)
	first.choosing = true
	first.select_upgrade('burn')
	first.progression.earn('ember', 2)
	first.progression.earn('storm', 1)
	first.persist_run()
	first.respawn(false) # Explicit retry/checkpoint save boundary.
	var expected_window = first.progression.window_counts()
	var expected_selections = first.progression.selections
	var expected_burn_rank = first.burn_rank()
	check('automatic save exists after combat upgrade and retry', storage.files.has(RunSave.SAVE_PATH), str(storage.files.keys()))

	# A fresh scene represents reload/browser restart. It receives only storage,
	# not the prior session object.
	var reloaded = make_scene(storage)
	check('reload offers Continue and New Game', reloaded.menu_title.text == 'Continue a saved run', reloaded.menu_title.text)
	reloaded.continue_run()
	check('Continue restores checkpoint', reloaded.player.position.distance_to(reloaded.CHECKPOINT_POSITION) < 1.0, str(reloaded.player.position))
	check('Continue restores typed earning window', reloaded.progression.window_counts() == expected_window, str(reloaded.progression.window_counts()))
	check('Continue restores total selections and path ranks', reloaded.progression.selections == expected_selections and reloaded.burn_rank() == expected_burn_rank, '%d/%d' % [reloaded.progression.selections, reloaded.burn_rank()])
	check('save envelope reserves stable world state', reloaded.saved_run['world'].has('objectives') and reloaded.saved_run['world'].has('modifier_assignments'), str(reloaded.saved_run.get('world', {})))
	reloaded.new_game()
	check('New Game starts fresh and replaces saved run', reloaded.progression.window_total() == 0 and reloaded.progression.selections == 0 and reloaded.burn_rank() == 0, 'dirty')

	# Persist the decision made during a tied dominant-element offer before a
	# path has been chosen; a reload must remain on the selected element paths.
	var tied = make_scene(storage)
	tied.new_game()
	tied.progression.earn('ember', 4)
	tied.progression.earn('wind', 4)
	tied.choosing = true
	tied.choose_current_slot(1) # ELEMENTS order makes this Wind.
	check('tied element choice is immediately saved', tied.progression.pending_element == 'wind' and storage.files.has(RunSave.SAVE_PATH), tied.progression.pending_element)
	var tied_reloaded = make_scene(storage)
	tied_reloaded.continue_run()
	var tied_offer = tied_reloaded.progression.offer()
	check('reload restores pending tied-element path offer', tied_reloaded.progression.pending_element == 'wind' and tied_offer['kind'] == 'paths' and tied_offer['element'] == 'wind', str(tied_offer))

	var mixed = make_scene(storage)
	mixed.new_game()
	mixed.progression.earn('ember', 8)
	mixed.choosing = true
	mixed.apply_path_choice('searing_claws')
	mixed.progression.earn('storm', 6)
	mixed.choosing = true
	mixed.apply_path_choice('chain_spark')
	mixed.progression.earn('storm', 6)
	mixed.choosing = true
	mixed.apply_path_choice('thunderbeat')
	mixed.respawn(false)
	var mixed_reloaded = make_scene(storage)
	mixed_reloaded.continue_run()
	check('Continue retains mixed Ember and Storm paths', mixed_reloaded.burn_rank() == 1 and mixed_reloaded.chain_rank() == 1 and mixed_reloaded.thunder_rank() == 1 and mixed_reloaded.progression.selections == 3, str(mixed_reloaded.progression.ranks))

	# A full mixed build keeps every rank, the typed remainder, and its cap
	# through both checkpoint death and a fresh Continue scene.
	mixed_reloaded.new_game()
	var build_paths := ['searing_claws', 'chain_spark', 'barb_shot', 'stonehide', 'slipstream', 'flame_arc', 'thunderbeat', 'bramble_trail']
	var build_elements := ['ember', 'storm', 'thorn', 'stone', 'wind', 'ember', 'storm', 'thorn']
	for i in range(build_paths.size()):
		var reward: int = mixed_reloaded.progression.window_requirement() + (2 if i == build_paths.size() - 1 else 0)
		mixed_reloaded.progression.earn(build_elements[i], reward)
		mixed_reloaded.apply_path_choice(build_paths[i])
	var expected_ranks: Dictionary = mixed_reloaded.progression.ranks.duplicate()
	var capped_window: Dictionary = mixed_reloaded.progression.window_counts()
	mixed_reloaded.respawn()
	check('death keeps all mixed ranks and typed cap remainder', mixed_reloaded.progression.ranks == expected_ranks and mixed_reloaded.progression.window_counts() == capped_window and mixed_reloaded.progression.is_fully_evolved(), str(mixed_reloaded.progression.ranks))
	var capped = make_scene(storage)
	capped.continue_run()
	var restored_ranks_match: bool = capped.progression.ranks.size() == expected_ranks.size()
	for path_id in expected_ranks:
		restored_ranks_match = restored_ranks_match and capped.progression.rank_of(path_id) == int(expected_ranks[path_id])
	check('Continue keeps all mixed ranks and typed cap remainder', restored_ranks_match and capped.progression.window_counts() == capped_window and capped.progression.is_fully_evolved(), str(capped.progression.ranks))
	var lifetime_at_cap: int = capped.progression.lifetime
	capped.progression.earn('stone', 7)
	check('Fully evolved stops accumulation after Continue', capped.progression.lifetime == lifetime_at_cap and capped.progression.window_counts() == capped_window and capped.progression.offer()['kind'] == 'none')

	var unavailable = MemoryStorage.new()
	unavailable.available = false
	var fallback = make_scene(unavailable)
	check('unavailable storage communicates session-only fallback', fallback.session_only and fallback.menu_detail.text.contains('session'), fallback.menu_detail.text)
	fallback.new_game()
	fallback.progression.earn('ember', 3)
	fallback.persist_run()
	check('session-only fallback keeps gameplay authoritative', fallback.playing and fallback.progression.window_total() == 3 and fallback.session_only, str(fallback.progression.window_total()))
	first.free()
	reloaded.free()
	tied.free()
	tied_reloaded.free()
	mixed.free()
	mixed_reloaded.free()
	capped.free()
	fallback.free()

	print('---')
	print('checks: %d failures: %d' % [checks, failures])
	if failures > 0:
		printerr('RUN SAVE TESTS FAILED')
		quit(1)
	else:
		print('ALL RUN SAVE TESTS PASSED')
		quit(0)
