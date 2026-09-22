extends SceneTree
## Issue #23: replay the attached production player, world collisions and combat.
## Run: godot --headless --path . --script tests/test_elemental_presentation.gd
## Uses memory storage. No saved run or art-preview ranks enter the player.
const Tuning = preload('res://tuning.gd')
const Progression = preload('res://progression.gd')
const RunSave = preload('res://run_save.gd')
const ACTIONS = ['left', 'right', 'jump', 'dash', 'attack', 'pause', 'retry', 'descend']
const TICKS = 180
var failures := 0
var checks := 0

class MemoryStorage extends RefCounted:
	var files := {}
	func read_text(path: String) -> Dictionary:
		return {'found': files.has(path), 'text': files.get(path, '')}
	func write_text(path: String, text: String) -> bool:
		files[path] = text
		return true
	func erase(path: String) -> bool:
		files.erase(path)
		return true

func check(label: String, condition: bool, detail = ''):
	checks += 1
	if not condition:
		failures += 1
		printerr('FAIL: ', label, ' :: ', detail)
	else:
		print('PASS: ', label)

func _initialize():
	Engine.physics_ticks_per_second = 60
	call_deferred('verify')

func release_actions():
	for action in ACTIONS:
		if InputMap.has_action(action): Input.action_release(action)

func mechanical_sample(m) -> Dictionary:
	var p = m.player
	return {
		'position': p.position, 'velocity': p.velocity, 'grounded': p.is_on_floor(),
		'facing': p.facing, 'attack_id': p.attack_id, 'attack_left': p.attack_left,
		'attack_wait': p.attack_wait, 'active_hit': Tuning.swipe_is_active(p.attack_left),
		'dash_id': p.dash_id, 'dash_left': p.dash_left, 'dash_wait': p.dash_wait,
		'air_jump_used': p.air_jump_used, 'invulnerable': p.invulnerable,
		'coyote': p.coyote, 'jump_buffer': p.jump_buffer,
		'hp': m.hp, 'kills': m.kills, 'deaths': m.deaths,
		'progression': m.progression.to_state().duplicate(true),
		'player_ranks': p.path_ranks.duplicate(), 'visual_ranks': p.visual.path_ranks.duplicate(),
		'reach': p.swipe_reach(), 'collision': p.get_child(0).shape.size,
		# Retain hit IDs, burn clocks and knockback, not just final enemy HP.
		'enemies': m.enemies.duplicate(true),
		'barbs': m.barb_shots.duplicate(true), 'brambles': m.bramble_patches.duplicate(true),
		'cues': m.secondary_cues.duplicate(true),
	}

func replay(paths: Array, facing: float, alternate: bool) -> Dictionary:
	release_actions()
	var m = load('res://main.tscn').instantiate()
	m.run_store = RunSave.new(MemoryStorage.new())
	# Keep real collision objects in the tree; manually drive each production
	# callback exactly once per real physics tick, in parent-before-child order.
	root.add_child(m)
	m.set_process(false)
	m.set_physics_process(false)
	m.player.set_physics_process(false)
	m.player.visual.set_process(false)
	m.start_run()
	for path in paths:
		m.progression.earn(Progression.PATH_CATALOG[path].element, m.progression.window_requirement())
		m.apply_path_choice(path)
	check('earned replay build', m.progression.selections == paths.size(), str(m.progression.ranks))
	m.enemies.clear()
	m.spawn_queue.clear()
	m.encounter_wait = 60.0
	m.player.position = Vector2(300, 299)
	m.player.facing = facing
	m.player.visual.use_alternate_presentation(alternate)
	m.add_enemy(300 + facing * 30, true)
	m.enemies[0].mode = 'recover'
	m.enemies[0].timer = 60.0
	var target: Dictionary = m.enemies[0]
	var trace := []
	var poses := []
	var swipe_poses := []
	var contacts := []
	var previous_hit := -1
	var forward = 'right' if facing > 0 else 'left'
	var backward = 'left' if facing > 0 else 'right'
	# Let the real physics world register the new floor/player shapes first.
	await physics_frame
	await process_frame
	for tick in TICKS:
		await physics_frame
		if tick == 10 or tick == 34: Input.action_press('attack')
		if tick == 11 or tick == 35: Input.action_release('attack')
		if tick == 60: Input.action_press(forward)
		if tick == 84: Input.action_release(forward)
		if tick == 70 or tick == 82: Input.action_press('jump')
		if tick == 71 or tick == 83: Input.action_release('jump')
		if tick == 90: Input.action_press('dash')
		if tick == 91: Input.action_release('dash')
		if tick == 120: Input.action_press(backward)
		if tick == 145: Input.action_release(backward)
		m._physics_process(1.0 / 60.0)
		m.player._physics_process(1.0 / 60.0)
		m.player.visual._process(1.0 / 60.0)
		trace.append(mechanical_sample(m))
		poses.append([m.player.visual.motion, m.player.visual.frame, m.player.visual.hand])
		if m.player.attack_left > 0:
			swipe_poses.append([tick, m.player.visual.frame, m.player.visual.hand])
		if target.hit_id != previous_hit:
			contacts.append(tick)
			previous_hit = target.hit_id
		await process_frame
	var result = {'trace': trace, 'poses': poses, 'swipe_poses': swipe_poses, 'contacts': contacts, 'damage': target.max_hp - target.hp}
	release_actions()
	m.free()
	# main._ready installs bindings; remove them before the next fresh scene.
	for action in ACTIONS: InputMap.erase_action(action)
	await physics_frame
	await process_frame
	return result

func verify():
	var parts = preload('res://elemental_parts.gd').new()
	var replacement = parts.replacement
	var changed_part = replacement.part_overrides.searing_claws
	check('replacement changes actual claw motif', parts.artwork.parts[changed_part].motif != parts.artwork.parts.searing_claws.motif)
	for mount in parts.attachments.mounts.searing_claws.instances:
		check('replacement moves ' + mount.anchor + ' attachment', replacement.offset_overrides.searing_claws != mount.offset)
	var baseline_sequence := []
	var replacement_sequence := []
	for frame in parts.attachments.motions.swipe.size():
		baseline_sequence.append(parts.displayed_frame('swipe', frame, false))
		replacement_sequence.append(parts.displayed_frame('swipe', frame, true))
	check('replacement changes consumed swipe sequence', baseline_sequence != replacement_sequence, str(replacement_sequence))

	var builds = {
		'first Ember': ['searing_claws', 'flame_arc'],
		'rank eight Ember': ['searing_claws', 'searing_claws', 'searing_claws', 'searing_claws', 'searing_claws', 'searing_claws', 'searing_claws', 'searing_claws'],
		'five-family cap': ['searing_claws', 'flame_arc', 'chain_spark', 'barb_shot', 'stonehide', 'bramble_trail', 'slipstream', 'airborne'],
	}
	for build in builds:
		for facing in [1.0, -1.0]:
			var baseline = await replay(builds[build], facing, false)
			var alternate = await replay(builds[build], facing, true)
			var label = '%s facing %d' % [build, facing]
			var mismatch := -1
			for tick in TICKS:
				if baseline.trace[tick] != alternate.trace[tick]:
					mismatch = tick
					break
			check(label + ': every movement/combat tick identical', mismatch == -1,
				'tick %d: %s / %s' % [mismatch, str(baseline.trace[maxi(0, mismatch)]), str(alternate.trace[maxi(0, mismatch)])])
			check(label + ': different rendered poses/sockets', baseline.poses != alternate.poses)
			check(label + ': different displayed swipe poses', baseline.swipe_poses != alternate.swipe_poses)
			check(label + ': actual hits and damage', not baseline.contacts.is_empty() and baseline.damage > 0, str(baseline.contacts))
			check(label + ': identical hit ticks and damage', baseline.contacts == alternate.contacts and baseline.damage == alternate.damage)
			check(label + ': actual running', absf(baseline.trace[80].position.x - baseline.trace[60].position.x) > 10)
			check(label + ': actual jump and dash', baseline.trace[75].velocity.y < 0 and baseline.trace[91].dash_id == 1)
			check(label + ': earned ranks reach attached visual', baseline.trace[0].visual_ranks == baseline.trace[0].progression.ranks)
			print('MEASURED ', label, ': ticks=', TICKS, ' hit_ticks=', baseline.contacts,
				' damage=', baseline.damage, ' run_dx=', baseline.trace[80].position.x - baseline.trace[60].position.x,
				' jump_vy=', baseline.trace[75].velocity.y, ' dash_vx=', baseline.trace[91].velocity.x)
	print('Elemental presentation checks: ', checks, '; failures: ', failures)
	quit(1 if failures else 0)
