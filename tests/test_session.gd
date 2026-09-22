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

	# --- Stone route, guarded counterplay, durable paths, and a mixed build ---
	m.start_run()
	m.player.position = Vector2(4840, 299)
	m._update_room()
	check('Stone route is reachable', m.room == 'stone1' and Tuning.ROOM_RIGHT_BOUND > 5700, m.room)
	m.add_enemy(4880.0, false, 'stone')
	m.add_enemy(4900.0, true, 'stone')
	m.player.invulnerable = 999.0
	step(m, 0.05)
	check('Stone easy and medium warn', m.enemies[0].mode == 'warn' and m.enemies[1].mode == 'warn', str(m.probe_enemies()))
	m.enemies[0].timer = 0
	m._process_stone_enemy(m.enemies[0], 0.01)
	check('Stone easy swipes', m.enemies[0].mode == 'swipe', m.enemies[0].mode)
	m.enemies[0].timer = 0
	m._process_stone_enemy(m.enemies[0], 0.01)
	check('Stone easy recovers', m.enemies[0].mode == 'recover', m.enemies[0].mode)
	m.enemies[0].hp = 0.0
	m.enemies[1].hp = 0.0
	step(m, 0.05)
	check('Stone kills grant typed easy and medium Numen', m.progression.window_counts()['stone'] == Tuning.EASY_NUMEN + Tuning.MEDIUM_NUMEN, str(m.progression.window_counts()))
	m.start_run()
	m.enemies.clear()
	m.player.position = Vector2(70, 299)
	m.player.invulnerable = 0.0
	m.progression.earn('stone', 8)
	m.choice_delay = 0.0
	step(m, 0.05)
	check('Stone Numen opens both paths', m.choosing and m.progression.session_offer().get('element') == 'stone' and m.progression.session_offer().get('paths', []).size() == 2, str(m.progression.session_offer()))
	m.apply_path_choice('stonehide')
	check('Stonehide rank reduces but never negates hits', m.stonehide_rank() == 1 and Tuning.stonehide_reduction(8) < 1.0, str(m.progression.ranks))
	for i in range(m.progression.window_requirement()):
		m.progression.earn('stone', 1)
	m.choice_delay = 0.0
	step(m, 0.05)
	m.apply_path_choice('reprisal')
	check('Reprisal earned as second Stone path', m.reprisal_rank() == 1, str(m.progression.ranks))
	m.enemies.clear()
	m.add_enemy(110.0, false, 'stone')
	m.player.invulnerable = 0.0
	m.reprisal_cooldown = 0.0
	var hp_before = m.hp
	m._hurt_player(2.0, 'Stone test hit')
	check('Stonehide reduces actual damage', is_equal_approx(m.hp, hp_before - 2.0 * (1.0 - Tuning.stonehide_reduction(1))), str(m.hp))
	check('Reprisal bursts once on hurt', is_equal_approx(m.enemies[0].hp, Tuning.STONE_EASY_HP - Tuning.reprisal_damage(1)) and m.reprisal_cooldown > 0, str(m.enemies[0].hp))
	var burst_hp = m.enemies[0].hp
	m._hurt_player(2.0, 'Blocked repeat')
	check('hurt immunity and burst cooldown prevent repeated triggers', m.enemies[0].hp == burst_hp, str(m.enemies[0].hp))
	m.enemies.clear()
	m.player.position = Vector2(4820, 299)
	m.player.facing = 1.0
	m.add_enemy(4850.0, true, 'stone')
	var guard = m.enemies[0]
	guard.dir = -1.0
	check('medium guard blocks frontal attacks', m._stone_guard_blocks(guard, m.player.position.x), str(m.probe_enemies()))
	m.player.attack_id += 1
	m.player.attack_left = 0.15
	m._physics_process(0.01)
	check('front swipe is blocked by Stone guard', guard.hp == Tuning.STONE_MEDIUM_HP, str(guard.hp))
	guard.mode = 'recover'
	guard.timer = 1.0
	check('medium guard exposes during recovery', not m._stone_guard_blocks(guard, m.player.position.x), str(m.probe_enemies()))
	m.player.attack_id += 1
	m.player.attack_left = 0.15
	m._physics_process(0.01)
	check('baseline swipe damages recovering Stone medium', guard.hp < Tuning.STONE_MEDIUM_HP, str(guard.hp))
	m.enemies.clear()
	m.player.position = Vector2(70, 299)
	for i in range(m.progression.window_requirement()):
		m.progression.earn('ember', 1)
	m.choice_delay = 0.0
	step(m, 0.05)
	m.apply_path_choice('searing_claws')
	check('defensive mixed build earns Ember and Stone', m.burn_rank() == 1 and m.stonehide_rank() == 1 and m.reprisal_rank() == 1, str(m.progression.ranks))
	m.respawn(false)
	check('Stone paths survive retry', m.stonehide_rank() == 1 and m.reprisal_rank() == 1, str(m.progression.ranks))
	m.continue_run()
	check('Stone mixed build survives Continue', m.burn_rank() == 1 and m.stonehide_rank() == 1 and m.reprisal_rank() == 1, str(m.progression.ranks))

	# --- Dense earned build: bounded secondary hits and approved synergies ---
	m.start_run()
	m.enemies.clear()
	m.player.position = Vector2(70, 299)
	var mixed_paths := ['searing_claws', 'chain_spark', 'barb_shot', 'reprisal', 'bramble_trail', 'slipstream', 'thunderbeat', 'flame_arc']
	var mixed_elements := ['ember', 'storm', 'thorn', 'stone', 'thorn', 'wind', 'storm', 'ember']
	for i in range(mixed_paths.size()):
		m.progression.earn(mixed_elements[i], m.progression.window_requirement())
		var offer = m.progression.session_offer()
		check('earned mixed offer for ' + mixed_paths[i], offer.get('paths', []).has(mixed_paths[i]), str(offer))
		m.apply_path_choice(mixed_paths[i])
	check('eight distinct earned paths coexist at cap', m.progression.is_fully_evolved() and m.progression.ranks.size() == 8, str(m.progression.ranks))
	for x in [120.0, 140.0, 160.0, 180.0, 200.0]:
		m.add_enemy(x, true, 'thorn')
	var chained = m.enemies[1]
	m._chain_from(m.enemies[0])
	check('Chain Spark carries owned burn', chained.burn == Tuning.burn_duration(m.burn_rank()), str(chained.burn))
	check('dense Chain Spark stops at one secondary target', m.secondary_cues.size() == 1 and m.enemies[2].hp == Tuning.MEDIUM_HP, str(m.probe_enemies()))
	m.player.attack_id += 1
	m._spawn_player_effects()
	m._process_player_effects(0.05)
	check('Barb Shot carries owned burn', m.enemies[0].burn == Tuning.burn_duration(m.burn_rank()), str(m.enemies[0].burn))
	check('Barb Shot makes no projectile or chain on impact', m.barb_shots.size() == 1 and m.secondary_cues.size() == 1, '%d/%d' % [m.barb_shots.size(), m.secondary_cues.size()])
	var hp_after_barb: float = m.enemies[0].hp
	m._process_player_effects(0.01)
	check('one Barb Shot cannot hit the same enemy twice', m.enemies[0].hp == hp_after_barb, str(m.enemies[0].hp))
	m.player.position.x = 125.0
	m.player.invulnerable = 0.0
	m.reprisal_cooldown = 0.0
	var retaliation_before: float = m.enemies[0].hp
	m._hurt_player(1.0, 'Mixed retaliation check')
	check('Reprisal deals one bounded hit and does not reflect', is_equal_approx(m.enemies[0].hp, retaliation_before - Tuning.reprisal_damage(1)) and m.reprisal_cooldown > 0.0 and m.barb_shots.size() == 1 and m.secondary_cues.size() == 2, str(m.probe_enemies()))
	check('Reprisal does not inherit burn', m.enemies[2].burn == 0.0, str(m.enemies[2].burn))
	var baseline_dash: float = Tuning.slipstream_cooldown(0)
	var mixed_dash: float = Tuning.slipstream_cooldown(m.progression.rank_of('slipstream'))
	check('Slipstream allows more Bramble dashes per interval', mixed_dash < baseline_dash and floori(1.1 / mixed_dash) > floori(1.1 / baseline_dash), '%s/%s' % [mixed_dash, baseline_dash])
	m.bramble_patches.clear()
	m.player.dash_id += 1
	m._spawn_player_effects()
	m.player.dash_id += 1
	m._spawn_player_effects()
	check('each available dash can leave Bramble Trail', m.bramble_patches.size() == 2, str(m.bramble_patches.size()))
	# Actual attached-player movement/combat equivalence is replayed in
	# tests/test_elemental_presentation.gd; a detached Visual plus tuning
	# lookups cannot establish that boundary.

	print('---')
	print('checks: %d failures: %d' % [checks, failures])
	if failures > 0:
		printerr('SESSION TESTS FAILED')
		quit(1)
	else:
		print('ALL SESSION TESTS PASSED')
		quit(0)
