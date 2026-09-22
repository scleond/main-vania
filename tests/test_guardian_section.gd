extends SceneTree
## Guardian elemental phase (issue #43).
## Run: godot --headless --path . --script tests/test_guardian_section.gd
## Covers access gating, the playable first phase, readable elemental attacks
## with recovery openings, the half-health transformation boundary that keeps
## remaining health, death/retry from the outside checkpoint, and the gameplay
## tuning that stays independent of guardian presentation.
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

func check(name: String, condition: bool, detail: String = '') -> void:
	checks += 1
	if condition:
		print('PASS: ', name)
	else:
		failures += 1
		printerr('FAIL: ', name, ' :: ', detail)

func scene(storage):
	var m = load('res://main.tscn').instantiate()
	m.run_store = RunSave.new(storage)
	m._ready()
	return m

func awaken_all(m) -> void:
	m.shrine_awakened = true
	m.storm_shrine_awakened = true
	m.thorn_shrine_awakened = true
	m.stone_shrine_awakened = true
	m.wind_shrine_awakened = true

func _initialize() -> void:
	var storage = MemoryStorage.new()
	var m = scene(storage)
	m.new_game()
	m.enemies.clear()
	m.route_cleared = true

	# --- Access gating: locked until all five shrines are awakened ---
	check('guardian starts locked', not m.guardian_unlocked)
	m.in_guardian_arena = true
	m._spawn_guardian()
	check('guardian never spawns while locked', m.guardian.is_empty())
	m.in_guardian_arena = false
	awaken_all(m)
	m._check_guardian_unlock()
	check('all five shrines unlock the guardian', m.guardian_unlocked)

	# Descending into the arena requires the seal input.
	m.player.position = Vector2(m._guardian_center(), Tuning.GUARDIAN_GROUND_Y)
	m._update_room()
	check('sanctuary room before descending', m.room == 'sanctuary', m.room)
	m._try_enter_guardian_arena()
	check('no descent without the seal input', not m.in_guardian_arena)
	Input.action_press('descend')
	m._try_enter_guardian_arena()
	Input.action_release('descend')
	check('descend enters the arena', m.in_guardian_arena)
	check('guardian checkpoint sits outside the arena', m.active_checkpoint_id == Tuning.CHECKPOINT_GUARDIAN and m.active_checkpoint_pos == m.CHECKPOINT_GUARDIAN_POS)
	m._spawn_guardian()
	check('guardian spawns once unlocked', not m.guardian.is_empty())
	check('guardian uses tuned health', m.guardian.hp == Tuning.GUARDIAN_HP and m.guardian.max_hp == Tuning.GUARDIAN_HP)
	check('guardian starts idle', m.guardian.phase == 'idle', m.guardian.phase)

	# --- Elemental attack cycle: warning, active window, recovery opening ---
	m.player.invulnerable = 999.0
	m.player.position = Vector2(m._guardian_center(), Tuning.GUARDIAN_GROUND_Y)

	m.guardian.attack_index = 0
	m.guardian.phase = 'idle'
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('ember slam is telegraphed', m.guardian.phase == 'ember_warn', m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('ember slam becomes active', m.guardian.phase == 'ember_slam', m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('ember slam ends in a recovery opening', m.guardian.phase == 'recover' and m._guardian_vulnerable(), m.guardian.phase)

	m.guardian.attack_index = 1
	m.guardian.phase = 'idle'
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('storm lightning is telegraphed', m.guardian.phase == 'storm_warn', m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('storm lightning becomes active', m.guardian.phase == 'storm_lightning', m.guardian.phase)
	var lane_width: float = Tuning.GUARDIAN_LANE_WIDTH
	m.guardian.safe_lane = 0
	m.player.position = Vector2(Tuning.GUARDIAN_LEFT + 0.5 * lane_width, Tuning.GUARDIAN_GROUND_Y)
	check('the safe lane is safe', not m._guardian_lane_hit())
	m.player.position = Vector2(Tuning.GUARDIAN_LEFT + 1.5 * lane_width, Tuning.GUARDIAN_GROUND_Y)
	check('a non-safe lane is unsafe', m._guardian_lane_hit())
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('storm lightning recovers', m.guardian.phase == 'recover', m.guardian.phase)

	m.guardian.attack_index = 2
	m.guardian.phase = 'idle'
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('thorn brambles are telegraphed', m.guardian.phase == 'thorn_warn', m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('thorn brambles become active with a clear lane', m.guardian.phase == 'thorn_brambles', m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('thorn brambles recover', m.guardian.phase == 'recover', m.guardian.phase)

	m.guardian.attack_index = 3
	m.guardian.phase = 'idle'
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('stone charge is telegraphed', m.guardian.phase == 'stone_warn', m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('stone charge becomes active', m.guardian.phase == 'stone_charge', m.guardian.phase)
	m.guardian.x = Tuning.GUARDIAN_LEFT
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('stone charge ends stuck and exposed', m.guardian.phase == 'stone_stuck' and m._guardian_vulnerable(), m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('stone stuck recovers', m.guardian.phase == 'recover', m.guardian.phase)

	m.guardian.attack_index = 4
	m.guardian.phase = 'idle'
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('wind swoop is telegraphed', m.guardian.phase == 'wind_warn', m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('wind swoop becomes active', m.guardian.phase == 'wind_swoop', m.guardian.phase)
	m.guardian.timer = 0.0
	m._process_guardian(0.01)
	check('wind swoop recovers', m.guardian.phase == 'recover', m.guardian.phase)

	# --- Baseline swipe connects only during recovery openings ---
	m.guardian.phase = 'recover'
	m.guardian.timer = 5.0
	m.guardian.hit_id = -1
	m.player.facing = 1.0
	m.player.position = Vector2(m.guardian.x - 12.0, Tuning.GUARDIAN_GROUND_Y)
	m.player.attack_id += 1
	m.player.attack_left = 0.15
	var hp_before: float = m.guardian.hp
	m._process_guardian(0.01)
	check('baseline swipe damages the recovery opening', m.guardian.hp == hp_before - Tuning.SWIPE_DAMAGE, str(m.guardian.hp))
	m.guardian.phase = 'ember_slam'
	m.guardian.timer = 5.0
	m.guardian.hit_id = -1
	m.player.attack_id += 1
	m.player.attack_left = 0.15
	hp_before = m.guardian.hp
	m._process_guardian(0.01)
	check('active guardian is not vulnerable', m.guardian.hp == hp_before, str(m.guardian.hp))

	# --- Half-health transformation keeps remaining health ---
	m.guardian.phase = 'recover'
	m.guardian.timer = 5.0
	m.guardian.hit_id = -1
	m.guardian.hp = Tuning.GUARDIAN_HP * 0.5 + 0.5
	m.player.attack_id += 1
	m.player.attack_left = 0.15
	m.player.position = Vector2(m.guardian.x - 12.0, Tuning.GUARDIAN_GROUND_Y)
	m._process_guardian(0.01)
	var remaining: float = Tuning.GUARDIAN_HP * 0.5 - 0.5
	check('half health enters the transformation transition', m.guardian.phase == 'transform', m.guardian.phase)
	check('transformation keeps remaining health', m.guardian.hp == remaining, str(m.guardian.hp))
	check('transformation does not refill health', m.guardian.hp < Tuning.GUARDIAN_HP, str(m.guardian.hp))
	for i in range(int(Tuning.GUARDIAN_TRANSFORM_DURATION / 0.016) + 4):
		m._process_guardian(0.016)
	check('transformation ends at the mirror boundary', m.guardian.phase == 'mirror' and m.guardian_phase_one_complete, m.guardian.phase)
	check('mirror boundary holds the retained health', m.guardian.hp == remaining, str(m.guardian.hp))
	m.guardian.hit_id = -1
	m.player.attack_id += 1
	m.player.attack_left = 0.15
	hp_before = m.guardian.hp
	m._process_guardian(0.01)
	check('mirror boundary is inert in this slice', m.guardian.hp == hp_before, str(m.guardian.hp))

	# --- Death retries the first phase from the outside checkpoint ---
	m.progression.earn('ember', 5)
	var window_before: int = m.progression.window_total()
	var selections_before: int = m.progression.selections
	m.hp = 0.0
	m.respawn()
	check('death restarts the first phase', m.guardian.is_empty() and not m.guardian_phase_one_complete and not m.in_guardian_arena)
	check('death returns to the outside guardian checkpoint', m.player.position == m.CHECKPOINT_GUARDIAN_POS, str(m.player.position))
	check('death restores health', m.hp == Tuning.PLAYER_MAX_HP, str(m.hp))
	check('death retains the earning window', m.progression.window_total() == window_before and m.progression.selections == selections_before, '%d/%d' % [m.progression.window_total(), m.progression.selections])
	check('retry checkpoint is saved', m.saved_run.get('checkpoint_id', '') == Tuning.CHECKPOINT_GUARDIAN, str(m.saved_run.get('checkpoint_id', '')))

	m.in_guardian_arena = true
	m._spawn_guardian()
	check('re-entry restarts a full first phase', m.guardian.hp == Tuning.GUARDIAN_HP and m.guardian.phase == 'idle', str(m.guardian))

	# --- Continue restores unlock, checkpoint and permanent progress ---
	m.persist_run()
	var continued = scene(storage)
	continued.continue_run()
	check('Continue restores the guardian unlock', continued.guardian_unlocked)
	check('Continue restores the outside guardian checkpoint', continued.active_checkpoint_id == Tuning.CHECKPOINT_GUARDIAN and continued.active_checkpoint_pos == continued.CHECKPOINT_GUARDIAN_POS, continued.active_checkpoint_id)
	check('Continue restores permanent progress', continued.progression.window_total() == window_before, str(continued.progression.window_total()))

	# --- Baseline attacks alone carry the first phase to the boundary ---
	m.start_run()
	m.enemies.clear()
	m.route_cleared = true
	awaken_all(m)
	m._check_guardian_unlock()
	m.in_guardian_arena = true
	m._spawn_guardian()
	m.player.invulnerable = 999.0
	m.player.facing = 1.0
	var swings := 0
	while m.guardian.phase != 'transform' and swings < 40:
		m.guardian.phase = 'recover'
		m.guardian.timer = 5.0
		m.guardian.hit_id = -1
		m.player.position = Vector2(m.guardian.x - 12.0, Tuning.GUARDIAN_GROUND_Y)
		m.player.attack_id += 1
		m.player.attack_left = 0.15
		m._process_guardian(0.01)
		swings += 1
	check('baseline swipes alone reach the first phase boundary', m.guardian.phase == 'transform' and m.guardian.hp <= Tuning.GUARDIAN_HP * 0.5 and swings <= int(Tuning.GUARDIAN_HP), 'swings=%d' % swings)

	# --- Tuning independence: values are exposed and ordered ---
	check('guardian health is gameplay tuning', Tuning.GUARDIAN_HP > 0.0 and Tuning.GUARDIAN_TRANSFORM_DURATION > 0.0)
	check('every elemental attack has a warning then a recovery or opening', Tuning.GUARDIAN_SLAM_WARN > 0.0 and Tuning.GUARDIAN_SLAM_RECOVER > 0.0 and Tuning.GUARDIAN_STORM_WARN > 0.0 and Tuning.GUARDIAN_STORM_RECOVER > 0.0 and Tuning.GUARDIAN_THORN_WARN > 0.0 and Tuning.GUARDIAN_THORN_RECOVER > 0.0 and Tuning.GUARDIAN_STONE_WARN > 0.0 and Tuning.GUARDIAN_STONE_STUCK > 0.0 and Tuning.GUARDIAN_WIND_WARN > 0.0 and Tuning.GUARDIAN_WIND_RECOVER > 0.0)
	check('lane attacks expose a safe lane', Tuning.GUARDIAN_LANE_COUNT >= 3 and Tuning.GUARDIAN_LANE_WIDTH > 0.0)

	print('Guardian checks: ', checks - failures, '/', checks)
	quit(1 if failures > 0 else 0)
