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
	check('Flame Arc rank 1 widens reach', m.arc_rank() == 1 and Tuning.swipe_reach(m.arc_rank()) == 58.0, 'r=%d reach=%s' % [m.arc_rank(), str(Tuning.swipe_reach(m.arc_rank()))])
	check('medium reward is two numen graphically', Tuning.MEDIUM_NUMEN == 2, 'reward')

	# --- Death retains souls/upgrades, restores health + encounters ---
	var selections = m.progression.selections
	var window = m.progression.window_total()
	m.progression.earn('ember', 2)
	window = m.progression.window_total()
	m.hp = 0.0
	step(m, 0.05)
	check('death restores full health', m.hp == Tuning.PLAYER_MAX_HP, str(m.hp))
	check('death returns to checkpoint', m.player.position.distance_to(m.CHECKPOINT_POSITION) < 1.0, str(m.player.position))
	check('death clears regular encounters', m.enemies.is_empty(), str(m.enemies.size()))
	check('death retains selections', m.progression.selections == selections, str(m.progression.selections))
	check('death retains window souls', m.progression.window_total() == window, str(m.progression.window_total()))
	check('death retains ranks', m.burn_rank() == 1 and m.arc_rank() == 1, '%d/%d' % [m.burn_rank(), m.arc_rank()])
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
	check('repeatable ranks accumulate', m.burn_rank() + m.arc_rank() == 8, '%d/%d' % [m.burn_rank(), m.arc_rank()])
	var frozen = m.progression.window_total()
	m.progression.earn('ember', 2)
	check('post-cap souls rest', m.progression.window_total() == frozen, str(m.progression.window_total()))

	print('---')
	print('checks: %d failures: %d' % [checks, failures])
	if failures > 0:
		printerr('SESSION TESTS FAILED')
		quit(1)
	else:
		print('ALL SESSION TESTS PASSED')
		quit(0)
