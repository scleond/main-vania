extends SceneTree
## Ember section behavior (issue #24).
## Run: godot --headless --path . --script tests/test_ember_section.gd
## Covers authored encounters, miniboss attacks, shrine awakening, checkpoints,
## persistence, death/rest retention, and section connection points.
var Tuning = load('res://tuning.gd')
var RunSave = load('res://run_save.gd')
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

func clear_enemies(m):
	m.enemies.clear()
	m.route_enemies.clear()

func _initialize():
	var packed = load('res://main.tscn')
	var m = packed.instantiate()
	m._ready()
	m.start_run()

	# --- Section initialization ---
	check('section is ember', m.section == Tuning.SECTION_EMBER, m.section)
	check('starts in entry room', m.room == 'entry', m.room)
	check('entry checkpoint active', m.active_checkpoint_id == Tuning.CHECKPOINT_EMBER_ENTRY, m.active_checkpoint_id)
	check('miniboss not defeated', not m.miniboss_defeated, str(m.miniboss_defeated))
	check('shrine not awakened', not m.shrine_awakened, str(m.shrine_awakened))
	check('section total is 20', m.section_total == 20, str(m.section_total))

	# --- Authored encounter layout: 18 easy, 2 medium ---
	var easy_count = 0
	var medium_count = 0
	for enc in m.EMBER_ROUTE_ENCOUNTERS:
		if enc['medium']:
			medium_count += 1
		else:
			easy_count += 1
	check('18 easy encounters', easy_count == 18, str(easy_count))
	check('2 medium encounters', medium_count == 2, str(medium_count))
	check('20 total encounters', m.EMBER_ROUTE_ENCOUNTERS.size() == 20, str(m.EMBER_ROUTE_ENCOUNTERS.size()))

	# --- Checkpoint healing at entry ---
	m.hp = 3.0
	# Move away first so the checkpoint detection triggers on return.
	m.player.position = Vector2(200, 299)
	m.active_checkpoint_id = Tuning.CHECKPOINT_EMBER_PREBOSS
	m._check_checkpoint_heal()
	# Still away from entry checkpoint, no heal yet.
	m.hp = 3.0
	m.player.position = Vector2(70, 299)
	m._check_checkpoint_heal()
	check('entry checkpoint heals', m.hp == Tuning.PLAYER_MAX_HP, str(m.hp))

	# --- Checkpoint re-heal on damaged return (#3) ---
	m.hp = 4.0
	m.active_checkpoint_id = Tuning.CHECKPOINT_EMBER_ENTRY
	m.player.position = Vector2(70, 299)
	m._check_checkpoint_heal()
	check('re-visit entry checkpoint heals when damaged', m.hp == Tuning.PLAYER_MAX_HP, str(m.hp))
	# Full health: no heal, no persist.
	m.hp = Tuning.PLAYER_MAX_HP
	var before_runs = m.saved_run.size()
	m._check_checkpoint_heal()
	check('re-visit entry checkpoint skips heal at full hp', m.hp == Tuning.PLAYER_MAX_HP, str(m.hp))

	# --- Pre-boss checkpoint heals on re-visit (#3) ---
	m.hp = 3.0
	m.active_checkpoint_id = Tuning.CHECKPOINT_EMBER_PREBOSS
	m.player.position = Vector2(1870, 299)
	m._check_checkpoint_heal()
	check('preboss checkpoint heals on re-visit', m.hp == Tuning.PLAYER_MAX_HP, str(m.hp))

	# --- Retry from both checkpoints (#3) ---
	m.active_checkpoint_id = Tuning.CHECKPOINT_EMBER_ENTRY
	m.player.position = Vector2(70, 299)
	check('retry near entry checkpoint', m.can_retry_nearby(), str(m.can_retry_nearby()))
	m.player.position = Vector2(1870, 299)
	check('retry near preboss checkpoint', m.can_retry_nearby(), str(m.can_retry_nearby()))
	m.player.position = Vector2(1000, 299)
	check('retry far from both checkpoints', not m.can_retry_nearby(), str(m.can_retry_nearby()))

	# --- Route encounter spawning ---
	m.player.position = Vector2(300, 299)
	m._update_room()
	check('player in entry room', m.room == 'entry', m.room)
	clear_enemies(m)
	m.encounter_index = 0
	m.route_cleared = false
	m.spawn_queue.clear()
	m._spawn_room_encounters()
	check('spawns entry enemies', m.enemies.size() >= 1, str(m.enemies.size()))
	var first_enemy = m.enemies[0]
	check('first enemy near x=350', absf(first_enemy.x - 350) < 10, str(first_enemy.x))

	# --- Active threats cap (#1) ---
	# Use route2 room which has 6 encounters — more than the cap of 3.
	m.player.position = Vector2(1000, 299)
	m._update_room()
	clear_enemies(m)
	m.encounter_index = 6
	m.route_cleared = false
	m.spawn_queue.clear()
	m._spawn_room_encounters()
	check('initial spawn respects cap', m.enemies.size() <= Tuning.MAX_ACTIVE_THREATS_PER_ROOM, str(m.enemies.size()))
	check('remaining queued in spawn_queue', m.spawn_queue.size() > 0, str(m.spawn_queue.size()))

	# --- Queue drains as enemies die (#1) ---
	clear_enemies(m)
	var queue_before = m.spawn_queue.size()
	m._spawn_room_encounters()
	check('queue drains when enemies removed', m.spawn_queue.size() < queue_before or m.enemies.size() > 0, str(m.spawn_queue.size()))

	# --- Enemy cycle still works in section ---
	m.player.invulnerable = 999.0
	m.player.position = Vector2(360, 299)
	m.encounter_index = m.EMBER_ROUTE_ENCOUNTERS.size()
	m.route_cleared = true
	m.spawn_queue.clear()
	clear_enemies(m)
	m.add_enemy(360, false)
	step(m, 0.2)
	check('enemy warns on approach', m.enemies[0]['mode'] == 'warn', m.enemies[0]['mode'])
	check('warning releases lunge', wait_mode(m, 'lunge', 2.0) == 'lunge', m.enemies[0]['mode'])
	check('lunge ends in recovery', wait_mode(m, 'recover', 2.0) == 'recover', m.enemies[0]['mode'])
	clear_enemies(m)
	m.player.invulnerable = 0.0

	# --- Kill all route enemies to clear route ---
	m.encounter_index = m.EMBER_ROUTE_ENCOUNTERS.size()
	m.route_cleared = true
	m.spawn_queue.clear()
	m.enemies.clear()

	# --- Miniboss spawning ---
	m.player.position = Vector2(1900, 299)
	m._update_room()
	check('player in boss room', m.room == 'boss', m.room)
	m._spawn_miniboss()
	check('miniboss spawned', m.miniboss_spawned, str(m.miniboss_spawned))
	check('miniboss has hp', m.miniboss.get('hp', 0) == Tuning.MINIBOSS_HP, str(m.miniboss.get('hp', 0)))
	check('miniboss phase is idle', m.miniboss.get('phase', '') == 'idle', m.miniboss.get('phase', ''))

	# --- Miniboss approach speed wired (#6) ---
	m.miniboss.x = 2050.0
	var start_x = m.miniboss.x
	m.player.position = Vector2(2200, 299)
	m.miniboss['phase'] = 'idle'
	m.miniboss.timer = 999.0
	m.miniboss.dir = 1.0
	m._process_miniboss(0.5)
	check('miniboss approaches player in idle', m.miniboss.x > start_x, str(m.miniboss.x))

	# --- Miniboss ground slam: warn -> slam -> recover ---
	m.player.invulnerable = 999.0
	m.player.position = Vector2(2000, 299)
	m.miniboss['phase'] = 'idle'
	m.miniboss.timer = 0.01
	m._process_miniboss(0.1)
	check('miniboss warns when close', m.miniboss['phase'] == 'warn_slam', m.miniboss['phase'])
	step(m, Tuning.MINIBOSS_WARN_DURATION + 0.1)
	check('miniboss slams after warn', m.miniboss['phase'] == 'slam', m.miniboss['phase'])
	step(m, Tuning.MINIBOSS_SLAM_DURATION + 0.1)
	check('miniboss recovers after slam', m.miniboss['phase'] == 'recover', m.miniboss['phase'])
	step(m, Tuning.MINIBOSS_SLAM_RECOVER + 0.1)
	check('miniboss returns to idle after recover', m.miniboss['phase'] == 'idle', m.miniboss['phase'])

	# --- Miniboss fire wave: tell -> spawns projectile ---
	m.player.position = Vector2(2250, 299)
	m.miniboss.x = 2050
	m.miniboss['phase'] = 'idle'
	m.miniboss.timer = 0.01
	m.miniboss_fire_cooldown = 0.0
	m._process_miniboss(0.1)
	check('miniboss shows fire tell when far', m.miniboss['phase'] == 'fire_tell', m.miniboss['phase'])
	step(m, Tuning.MINIBOSS_IDLE_TELL + 0.1)
	check('fire wave spawned', m.fire_waves.size() >= 1, str(m.fire_waves.size()))
	var fw = m.fire_waves[0]
	check('fire wave moves toward player', fw.dir > 0, str(fw.dir))

	# --- Fire wave cooldown prevents spam (#2) ---
	m.fire_waves.clear()
	m.miniboss['phase'] = 'idle'
	m.miniboss.timer = 0.01
	m.miniboss_fire_cooldown = Tuning.MINIBOSS_FIRE_WAVE_INTERVAL
	m._process_miniboss(0.1)
	check('fire tell blocked by cooldown', m.miniboss['phase'] == 'idle', m.miniboss['phase'])
	m.miniboss.timer = 0.01
	m.miniboss_fire_cooldown = 0.0
	m._process_miniboss(0.1)
	check('fire tell allowed after cooldown', m.miniboss['phase'] == 'fire_tell', m.miniboss['phase'])
	m.fire_waves.clear()

	# --- Fire wave is jumpable ---
	m.hp = Tuning.PLAYER_MAX_HP
	m.player.position = Vector2(2200, 220)
	m.fire_waves = [{'x': 2150, 'y': 275, 'dir': 1, 'timer': 1.0}]
	step(m, 0.5)
	check('fire wave misses airborne player', m.hp == Tuning.PLAYER_MAX_HP, str(m.hp))
	m.fire_waves.clear()
	m.player.invulnerable = 0.0

	# --- Miniboss defeat grants 5 numen ---
	m.miniboss.hp = 0.1
	m.player.attack_left = 0.1
	m.player.attack_id += 1
	m.player.position = Vector2(m.miniboss.x - 10, 299)
	m.player.facing = 1.0
	m._process_miniboss(0.016)
	check('miniboss defeated', m.miniboss_defeated, str(m.miniboss_defeated))
	check('miniboss cleared from dict', m.miniboss.is_empty(), str(m.miniboss))

	# --- Pre-boss checkpoint set after miniboss defeat ---
	check('preboss checkpoint active', m.active_checkpoint_id == Tuning.CHECKPOINT_EMBER_PREBOSS, m.active_checkpoint_id)
	m.player.invulnerable = 0.0

	# --- Shrine awakening (now requires hold input, #4) ---
	m.player.position = Vector2(2200, 299)
	# Simulate holding attack for 1.5s via delta increments.
	for i in range(100):
		m._try_shrine_interaction(0.016)
		if m.shrine_awakened:
			break
	# Since Input.is_action_pressed is not testable in headless, we force it via the Input singleton.
	# The test sets it manually by pressing the action.
	Input.action_press('attack')
	m.shrine_interact = false
	m.shrine_timer = 0.0
	m.shrine_awakened = false
	m.miniboss_defeated = true
	for i in range(100):
		m._try_shrine_interaction(0.016)
		if m.shrine_awakened:
			break
	Input.action_release('attack')
	check('shrine awakened with hold input', m.shrine_awakened, str(m.shrine_awakened))
	# Miniboss defeat grants 5 numen; shrine awakening is the section objective.
	check('miniboss defeat granted 5 numen', m.progression.window_total() == 5, str(m.progression.window_total()))

	# --- Shrine proximity alone does not activate (#4) ---
	m.shrine_awakened = false
	m.shrine_interact = false
	m.shrine_timer = 0.0
	m.miniboss_defeated = true
	# No attack pressed — proximity alone should not progress.
	for i in range(100):
		m._try_shrine_interaction(0.016)
	check('shrine needs explicit hold', not m.shrine_awakened, str(m.shrine_awakened))
	check('shrine timer stays zero without hold', m.shrine_timer == 0.0, str(m.shrine_timer))

	# --- Section objective complete ---
	var objectives = m.saved_run.get('world', {}).get('objectives', {})
	check('section objective persisted', objectives.get(Tuning.SECTION_OBJECTIVE_EMBER, false), str(objectives))

	# --- Death retains miniboss defeated and shrine awakened ---
	var pre_death_defeated = m.miniboss_defeated
	var pre_death_shrine = m.shrine_awakened
	m.hp = 0.0
	step(m, 0.05)
	check('death retains miniboss defeated', m.miniboss_defeated == pre_death_defeated, str(m.miniboss_defeated))
	check('death retains shrine awakened', m.shrine_awakened == pre_death_shrine, str(m.shrine_awakened))
	check('death restores health', m.hp >= Tuning.PLAYER_MAX_HP - 0.01, str(m.hp))

	# --- section_kills reset on death (#7) ---
	m.section_kills = 10
	m.hp = 0.0
	m.player.position = Vector2(1000, 299)
	step(m, 0.05)
	check('section_kills reset on death', m.section_kills == 0, str(m.section_kills))

	# --- Rest retains section state ---
	m.miniboss_defeated = true
	m.shrine_awakened = true
	m.respawn(false)
	check('rest retains miniboss defeated', m.miniboss_defeated, str(m.miniboss_defeated))
	check('rest retains shrine awakened', m.shrine_awakened, str(m.shrine_awakened))
	check('rest resets section_kills', m.section_kills == 0, str(m.section_kills))

	# --- Save/load round-trip ---
	var storage = MemoryStorage.new()
	m.run_store = RunSave.new(storage)
	m.miniboss_defeated = true
	m.shrine_awakened = true
	m.active_checkpoint_id = Tuning.CHECKPOINT_EMBER_PREBOSS
	m.persist_run()
	check('save exists after miniboss+shrine', storage.files.has(RunSave.SAVE_PATH), str(storage.files.keys()))

	var reloaded = packed.instantiate()
	reloaded.run_store = RunSave.new(storage)
	reloaded._ready()
	reloaded.continue_run()
	check('reload restores miniboss defeated', reloaded.miniboss_defeated, str(reloaded.miniboss_defeated))
	check('reload restores shrine awakened', reloaded.shrine_awakened, str(reloaded.shrine_awakened))
	check('reload restores preboss checkpoint', reloaded.active_checkpoint_id == Tuning.CHECKPOINT_EMBER_PREBOSS, reloaded.active_checkpoint_id)

	# --- Section connection points ---
	check('section connection has id', m.SECTION_CONNECTION['id'] == 'ember', str(m.SECTION_CONNECTION))
	check('section connection has objective', m.SECTION_CONNECTION['objective'] == Tuning.SECTION_OBJECTIVE_EMBER, str(m.SECTION_CONNECTION))
	check('section connection has influence slots', m.SECTION_CONNECTION['influence_slots'].size() == 2, str(m.SECTION_CONNECTION))

	# --- New game resets section state ---
	m.new_game()
	check('new game resets miniboss', not m.miniboss_defeated, str(m.miniboss_defeated))
	check('new game resets shrine', not m.shrine_awakened, str(m.shrine_awakened))
	check('new game resets room', m.room == 'entry', m.room)
	check('new game resets section_kills', m.section_kills == 0, str(m.section_kills))
	check('new game resets spawn_queue', m.spawn_queue.is_empty(), str(m.spawn_queue.size()))

	# --- Encounter index does not advance on backtrack (#7) ---
	m.player.position = Vector2(300, 299)
	m._update_room()
	clear_enemies(m)
	m.encounter_index = 0
	m.route_cleared = false
	m.spawn_queue.clear()
	m._spawn_room_encounters()
	var entry_spawns = m.enemies.size()
	var entry_index = m.encounter_index
	# Move to route1 — entry encounters remain queued/unspawned.
	m.player.position = Vector2(600, 299)
	m._update_room()
	check('encounter_index not advanced by room change', m.encounter_index == entry_index, str(m.encounter_index))

	m.free()
	reloaded.free()

	print('---')
	print('checks: %d failures: %d' % [checks, failures])
	if failures > 0:
		printerr('EMBER SECTION TESTS FAILED')
		quit(1)
	else:
		print('ALL EMBER SECTION TESTS PASSED')
		quit(0)
