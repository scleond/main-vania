extends SceneTree
## Session-behavior cases for issue #20, driven through the production scene.
## Run: godot --headless --path . --script tests/test_session.gd
## Verifies earned Ember choices, rank effects, death/rest retention at the
## checkpoint, and the warn → lunge → recover enemy cycle with 1/2 rewards.
var Tuning = load('res://tuning.gd')
var failures := 0
var checks := 0

func check(name, cond, detail = ''):
	checks += 1
	if cond:
		print('PASS: ', name)
	else:
		failures += 1
		printerr('FAIL: ', name, ' :: ', detail)

func step(m, seconds):
	var dt := 0.016
	var n := int(seconds / dt)
	for i in range(n):
		m._physics_process(dt)

## Advance until the first enemy reaches the target mode (or time out).
## Returns the mode actually observed.
func wait_mode(m, target, timeout):
	var dt := 0.05
	var elapsed := 0.0
	while elapsed < timeout:
		if m.enemies.is_empty():
			return 'gone'
		if m.enemies[0]['mode'] == target:
			return target
		m._physics_process(dt)
		elapsed += dt
	return m.enemies[0]['mode'] if not m.enemies.is_empty() else 'gone'

func _initialize():
	var packed = load('res://main.tscn')
	var m = packed.instantiate()
	# Drive outside the tree: _ready runs once here (never add to root, which
	# would dispatch it a second time), physics steps are manual below.
	m._ready()
	check('scene ready at checkpoint', m.player.position.distance_to(m.CHECKPOINT_POSITION) < 1.0, str(m.player.position))
	m.start_run()
	check('session starts fresh', m.playing and m.progression.selections == 0 and m.progression.window_total() == 0, 'dirty')

	# --- Enemy cycle: approach → warn → lunge → recover → approach ---
	m.player.invulnerable = 999.0
	m.add_enemy(150.0, false)
	m.player.position = Vector2(190, 299)
	step(m, 0.2)
	var e = m.enemies[0]
	check('easy enemy warns on approach', e['mode'] == 'warn', e['mode'])
	check('warning releases the lunge', wait_mode(m, 'lunge', 2.0) == 'lunge', m.enemies[0]['mode'])
	check('lunge ends in recovery', wait_mode(m, 'recover', 2.0) == 'recover', m.enemies[0]['mode'])
	check('recovery returns to approach', wait_mode(m, 'approach', 3.0) == 'approach', m.enemies[0]['mode'])
	m.enemies.clear()
	m.player.invulnerable = 0.0

	# --- Earned choice: 8 easy souls pause play and offer Ember paths ---
	for i in range(8):
		m.progression.earn('ember', Tuning.EASY_NUMEN)
	m.choice_delay = 0.0
	step(m, 0.05)
	check('8 souls pause for choice', m.choosing, 'not choosing')
	check('session offers two Ember paths', m.progression.session_offer()['paths'].size() == 2, str(m.progression.session_offer()))
	check('numen mirror window', m.numen == 8, str(m.numen))
	m.select_upgrade('burn')
	check('Searing Claws rank 1 applies', m.burn_rank() == 1 and not m.choosing, 'r=%d choosing=%s' % [m.burn_rank(), str(m.choosing)])
	check('burn duration tuned to 2.2s', Tuning.burn_duration(m.burn_rank()) == 2.2, str(Tuning.burn_duration(m.burn_rank())))
	check('legacy upgrade names burn', m.upgrade == 'burn', m.upgrade)

	# --- Second window (6 souls) offers Flame Arc reach ---
	for i in range(6):
		m.progression.earn('ember', Tuning.EASY_NUMEN)
	m.choice_delay = 0.0
	step(m, 0.05)
	check('second window pauses again', m.choosing, 'not choosing')
	m.select_upgrade('arc')
	check('Flame Arc rank 1 widens reach', m.arc_rank() == 1 and Tuning.swipe_reach(m.arc_rank()) == 66.0, 'r=%d reach=%s' % [m.arc_rank(), str(Tuning.swipe_reach(m.arc_rank()))])
	check('medium reward is two numen graphically', Tuning.MEDIUM_NUMEN == 2, 'reward')

	# --- Storm route, native rewards, and mixed path effects ---
	m.enemies.clear()
	m.add_enemy(2500.0, false, 'storm')
	m.add_enemy(2580.0, true, 'storm')
	m.player.position = Vector2(2510, 299)
	m.player.invulnerable = 999.0
	step(m, 0.05)
	check('Storm easy charges a straight shot', m.enemies[0].mode == 'warn', str(m.enemies[0].mode))
	check('Storm medium relocates before aiming', m.enemies[1].mode == 'relocate', str(m.enemies[1].mode))
	step(m, 0.5)
	check('Storm medium has aimed warning', m.enemies[1].mode == 'warn' and m.enemies[1].aim.length() > 0, str(m.enemies[1].mode))
	m.enemies.clear()
	m.storm_shots.clear()
	m.player.position = Vector2(70, 299)
	for i in range(m.progression.window_requirement()):
		m.progression.earn('storm', 1)
	m.choice_delay = 0.0
	step(m, 0.05)
	check('Storm path offer available', m.choosing and m.progression.session_offer().get('element') == 'storm', str(m.progression.session_offer()))
	m.apply_path_choice('chain_spark')
	check('mixed Ember and Storm ranks', m.burn_rank() == 1 and m.chain_rank() == 1, str(m.progression.ranks))
	m.add_enemy(120.0, false)
	m.add_enemy(165.0, false, 'storm')
	var target = m.enemies[1]
	m._chain_from(m.enemies[0])
	check('Chain Spark damages nearby target once', target.hp == Tuning.EASY_HP - Tuning.chain_damage(1), str(target.hp))
	check('Chain Spark does not recurse', m.secondary_cues.size() == 1, str(m.secondary_cues.size()))
	m.enemies.clear()
	for i in range(m.progression.window_requirement()):
		m.progression.earn('storm', 1)
	m.choice_delay = 0.0
	step(m, 0.05)
	m.apply_path_choice('thunderbeat')
	m.add_enemy(100.0, false, 'storm')
	m.player.attack_id = 3
	m.last_pulse_attack = 2
	m._pulse_if_due()
	check('Thunderbeat third swipe damages enemy', m.enemies[0].hp == Tuning.EASY_HP - Tuning.thunderbeat_damage(1), str(m.enemies[0].hp))
	m.enemies.clear()
	m.player.invulnerable = 0.0

	# --- Death retains souls/upgrades, restores health + encounters ---
	var selections = m.progression.selections
	var window = m.progression.window_total()
	m.progression.earn('ember', 2)
	window = m.progression.window_total()
	m.player.position = Vector2(190, 299)
	m.hp = 0.0
	step(m, 0.05)
	check('death restores full health', m.hp == Tuning.PLAYER_MAX_HP, str(m.hp))
	check('death returns to checkpoint', m.player.position.distance_to(m.CHECKPOINT_POSITION) < 1.0, str(m.player.position))
	check('death clears regular encounters', m.enemies.is_empty(), str(m.enemies.size()))
	check('death retains selections', m.progression.selections == selections, str(m.progression.selections))
	check('death retains window souls', m.progression.window_total() == window, str(m.progression.window_total()))
	check('death retains mixed ranks', m.burn_rank() == 1 and m.arc_rank() == 1 and m.chain_rank() == 1 and m.thunder_rank() == 1, str(m.progression.ranks))
	check('death counted', m.deaths == 1, str(m.deaths))

	# --- Deliberate rest near checkpoint retains progress too ---
	m.progression.earn('ember', 1)
	window = m.progression.window_total()
	m.respawn(false)
	check('rest retains window and ranks', m.progression.window_total() == window and m.burn_rank() == 1, '%d' % m.progression.window_total())
	check('rest restores encounters state', m.enemies.is_empty() and m.wave == 0, 'wave=%d' % m.wave)

	# --- Walk to the cap through the session boundary ---
	var paths := ['searing_claws', 'flame_arc']
	var flips := 0
	while not m.progression.is_fully_evolved():
		var need: int = m.progression.window_requirement() - m.progression.window_total()
		for i in range(need):
			m.progression.earn('ember', 1)
		m.choice_delay = 0.0
		step(m, 0.05)
		if not m.choosing:
			check('choice opens on the way to cap', false, 'sel=%d' % m.progression.selections)
			break
		m.apply_path_choice(paths[flips % 2])
		flips += 1
		if flips > 12:
			break
	check('session reaches Fully evolved', m.progression.is_fully_evolved() and m.progression.selections == 8, 'sel=%d' % m.progression.selections)
	check('repeatable ranks accumulate', m.burn_rank() + m.arc_rank() + m.chain_rank() + m.thunder_rank() == 8, str(m.progression.ranks))
	var frozen = m.progression.window_total()
	m.progression.earn('ember', 2)
	check('post-cap souls rest', m.progression.window_total() == frozen, str(m.progression.window_total()))

	# --- Thorn route, both earned paths, and saved retry with an Ember build ---
	m.start_run()
	m.player.position = Vector2(3650, 299)
	m.add_enemy(3700.0, false, 'thorn')
	m.add_enemy(3750.0, true, 'thorn')
	m.player.invulnerable = 999.0
	step(m, 0.05)
	check('Thorn easy and medium warn', m.enemies[0].mode == 'warn' and m.enemies[1].mode == 'warn', str(m.probe_enemies()))
	m.enemies[0].timer = 0.0
	m.enemies[1].timer = 0.0
	m._process_thorn_enemy(m.enemies[0], 0.01)
	m._process_thorn_enemy(m.enemies[1], 0.01)
	check('Thorn easy single and medium three shot fan', m.thorn_shots.size() == 4, str(m.thorn_shots.size()))
	check('Thorn enemies recover after shots', m.enemies[0].mode == 'recover' and m.enemies[1].mode == 'recover', str(m.probe_enemies()))
	m.enemies[0].hp = 0.0
	m.enemies[1].hp = 0.0
	step(m, 0.05)
	check('Thorn kills grant native easy and medium Numen', m.progression.window_counts()['thorn'] == Tuning.EASY_NUMEN + Tuning.MEDIUM_NUMEN, str(m.progression.window_counts()))
	m.start_run()
	m.enemies.clear()
	m.thorn_shots.clear()
	m.player.position = Vector2(70, 299)
	for i in range(8):
		m.progression.earn('ember', 1)
	m.choice_delay = 0.0
	step(m, 0.05)
	m.apply_path_choice('searing_claws')
	for i in range(m.progression.window_requirement()):
		m.progression.earn('thorn', 1)
	m.choice_delay = 0.0
	step(m, 0.05)
	check('Thorn offer follows earned Numen', m.choosing and m.progression.session_offer().get('element') == 'thorn', str(m.progression.session_offer()))
	m.apply_path_choice('barb_shot')
	check('Barb Shot joins Ember build', m.barb_rank() == 1 and m.burn_rank() == 1, str(m.progression.ranks))
	m.player.attack_id += 1
	m._spawn_player_effects()
	check('swipe launches one Barb Shot', m.barb_shots.size() == 1, str(m.barb_shots.size()))
	m.add_enemy(120.0, false, 'thorn')
	m._process_player_effects(0.05)
	check('Barb Shot deals tuned damage', m.enemies[0].hp == Tuning.EASY_HP - Tuning.barb_damage(1), str(m.enemies[0].hp))
	m.enemies.clear()
	m._process_player_effects(Tuning.BARB_LIFETIME + 0.01)
	check('Barb Shot expires by tuned lifetime', m.barb_shots.is_empty(), str(m.barb_shots.size()))
	for i in range(m.progression.window_requirement()):
		m.progression.earn('thorn', 1)
	m.choice_delay = 0.0
	step(m, 0.05)
	m.apply_path_choice('bramble_trail')
	m.player.dash_id += 1
	m._spawn_player_effects()
	check('dash leaves Bramble Trail patch', m.bramble_rank() == 1 and m.bramble_patches.size() == 1, str(m.bramble_patches.size()))
	m.add_enemy(m.player.position.x + 8, false, 'thorn')
	m._process_player_effects(0.05)
	check('Bramble patch deals damage once per enemy', m.enemies[0].hp == Tuning.EASY_HP - Tuning.bramble_damage(1), str(m.enemies[0].hp))
	m._process_player_effects(0.05)
	check('Bramble patch does not retrigger', m.enemies[0].hp == Tuning.EASY_HP - Tuning.bramble_damage(1), str(m.enemies[0].hp))
	m.enemies.clear()
	m._process_player_effects(Tuning.BRAMBLE_LIFETIME + 0.01)
	check('Bramble patch expires by tuned lifetime', m.bramble_patches.is_empty(), str(m.bramble_patches.size()))
	m.respawn(false)
	check('retry retains both Thorn ranks', m.barb_rank() == 1 and m.bramble_rank() == 1, str(m.progression.ranks))
	m.continue_run()
	check('Continue restores Ember and both Thorn ranks', m.burn_rank() == 1 and m.barb_rank() == 1 and m.bramble_rank() == 1, str(m.progression.ranks))

	print('---')
	print('checks: %d failures: %d' % [checks, failures])
	if failures > 0:
		printerr('SESSION TESTS FAILED')
		quit(1)
	else:
		print('ALL SESSION TESTS PASSED')
		quit(0)
