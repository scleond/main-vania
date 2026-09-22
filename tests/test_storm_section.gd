extends SceneTree
## Storm objective and saved retry through the production session boundary.
var Tuning = load('res://tuning.gd')
var RunSave = load('res://run_save.gd')
var failures := 0
var checks := 0

class MemoryStorage extends RefCounted:
	var files := {}
	func read_text(path: String) -> Dictionary:
		return {'found': files.has(path), 'text': files.get(path, '')}
	func write_text(path: String, value: String) -> bool:
		files[path] = value
		return true
	func erase(path: String) -> bool:
		files.erase(path)
		return true

func check(name: String, condition: bool) -> void:
	checks += 1
	if condition:
		print('PASS: ', name)
	else:
		failures += 1
		printerr('FAIL: ', name)

func scene(storage):
	var m = load('res://main.tscn').instantiate()
	m.run_store = RunSave.new(storage)
	m._ready()
	return m

func _initialize() -> void:
	var storage = MemoryStorage.new()
	var m = scene(storage)
	m.new_game()
	var easy := 0
	var medium := 0
	for encounter in m.STORM_ROUTE_ENCOUNTERS:
		if encounter.medium:
			medium += 1
		else:
			easy += 1
	check('Storm route has 18 easy and 2 medium enemies', easy == 18 and medium == 2)
	check('Storm section connection is stable', m.STORM_SECTION_CONNECTION.id == Tuning.SECTION_STORM and m.STORM_SECTION_CONNECTION.objective == Tuning.SECTION_OBJECTIVE_STORM and m.STORM_SECTION_CONNECTION.influence_slots.size() == 2)
	m.choice_delay = 999.0
	for room_x in [2500.0, 3000.0]:
		m.player.position = Vector2(room_x, 299)
		m._update_room()
		while m.storm_route_kills < (8 if room_x < 2800 else 20):
			m._spawn_storm_encounters()
			check('room threat cap', m.enemies.size() <= Tuning.MAX_ACTIVE_THREATS_PER_ROOM)
			for enemy in m.enemies:
				enemy.hp = 0
			m._physics_process(0.016)
	check('entire Storm route cleared in session', m.storm_route_kills == 20)
	m.player.position = m.CHECKPOINT_STORM_PREBOSS_POS
	m._physics_process(0.016)
	check('preboss checkpoint heals and saves', m.active_checkpoint_id == Tuning.CHECKPOINT_STORM_PREBOSS and m.hp == Tuning.PLAYER_MAX_HP)
	m._spawn_storm_miniboss()
	check('Storm miniboss spawns', not m.storm_miniboss.is_empty())
	m.storm_miniboss.phase = 'warn_lightning'
	m.storm_miniboss.safe_lane = 0
	m.storm_miniboss.timer = 0
	m._process_storm_miniboss(0.016)
	check('marked lightning becomes active', m.storm_miniboss.phase == 'lightning')
	m.player.invulnerable = 0
	m.player.position = Vector2(Tuning.STORM_BOSS_LEFT + Tuning.STORM_BOSS_LANE_WIDTH * 0.5, 299)
	var hp_before: float = m.hp
	m._process_storm_miniboss(0.016)
	check('unmarked ground lane is safe', m.hp == hp_before)
	m.player.position.x += Tuning.STORM_BOSS_LANE_WIDTH
	m._process_storm_miniboss(0.016)
	check('marked ground lane deals damage', m.hp < hp_before)
	m.storm_miniboss.timer = 0
	m._process_storm_miniboss(0.016)
	check('lightning has recovery', m.storm_miniboss.phase == 'recover')
	m.respawn()
	check('saved retry restores the preboss checkpoint', m.player.position == m.CHECKPOINT_STORM_PREBOSS_POS and m.storm_miniboss.is_empty())
	m._spawn_storm_miniboss()
	check('miniboss returns after retry', not m.storm_miniboss.is_empty())
	m.player.position = Vector2(m.STORM_MINIBOSS_POSITION.x - 25, 299)
	m.player.facing = 1
	m.player.attack_id += 1
	m.player.attack_left = (Tuning.SWIPE_ACTIVE_LATE + Tuning.SWIPE_ACTIVE_EARLY) * 0.5
	m.storm_miniboss.hp = 1
	m.storm_miniboss.phase = 'recover'
	var earned_before: int = m.progression.lifetime
	m._process_storm_miniboss(0.016)
	check('baseline swipe defeats miniboss for five Storm Numen', m.storm_miniboss_defeated and m.progression.lifetime == earned_before + 5)
	m.player.position = m.STORM_SHRINE_POSITION
	Input.action_press('attack')
	m._try_shrine_interaction(Tuning.SHRINE_AWAKEN_DURATION)
	Input.action_release('attack')
	check('Storm Shrine completes objective', m.storm_shrine_awakened)
	var continued = scene(storage)
	continued.continue_run()
	check('Continue retains defeat and Shrine', continued.storm_miniboss_defeated and continued.storm_shrine_awakened)
	check('Continue retains checkpoint and Storm Numen', continued.active_checkpoint_id == Tuning.CHECKPOINT_STORM_PREBOSS and continued.progression.lifetime == m.progression.lifetime)
	continued.respawn()
	check('death retains completed Storm objective', continued.storm_miniboss_defeated and continued.storm_shrine_awakened)
	print('Storm checks: ', checks - failures, '/', checks)
	quit(1 if failures > 0 else 0)
