extends SceneTree
## Thorn route, safe bramble lanes, objective, and saved retry in a live session.
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
	for encounter in m.THORN_ROUTE_ENCOUNTERS:
		if encounter.medium:
			medium += 1
		else:
			easy += 1
	check('Thorn route has 18 easy and 2 medium enemies', easy == 18 and medium == 2)
	check('Thorn connection exposes stable objective and influence slots', m.THORN_SECTION_CONNECTION.id == Tuning.SECTION_THORN and m.THORN_SECTION_CONNECTION.objective == Tuning.SECTION_OBJECTIVE_THORN and m.THORN_SECTION_CONNECTION.influence_slots.size() == 2)
	m.choice_delay = 999.0
	m.player.position = m.CHECKPOINT_THORN_ENTRY_POS
	m.hp = 2
	m._physics_process(0.016)
	check('entry checkpoint heals and saves', m.active_checkpoint_id == Tuning.CHECKPOINT_THORN_ENTRY and m.hp == Tuning.PLAYER_MAX_HP)
	for room_x in [3700.0, 4300.0]:
		m.player.position = Vector2(room_x, 299)
		m._update_room()
		while m.thorn_route_kills < (9 if room_x < 4000 else 20):
			m._spawn_thorn_encounters()
			var active := 0
			for enemy in m.enemies:
				if enemy.element == Tuning.SECTION_THORN and enemy.x >= m.EMBER_ROOM_BOUNDS[m.room].left and enemy.x < m.EMBER_ROOM_BOUNDS[m.room].right:
					active += 1
			check('room threat cap', active <= Tuning.MAX_ACTIVE_THREATS_PER_ROOM)
			for enemy in m.enemies:
				enemy.hp = 0
			m._physics_process(0.016)
	check('full Thorn route cleared', m.thorn_route_kills == 20)
	m.player.position = m.CHECKPOINT_THORN_PREBOSS_POS
	m.hp = 2
	m._physics_process(0.016)
	check('preboss checkpoint heals and saves', m.active_checkpoint_id == Tuning.CHECKPOINT_THORN_PREBOSS and m.hp == Tuning.PLAYER_MAX_HP)
	m._spawn_thorn_miniboss()
	check('Thorn miniboss spawns', not m.thorn_miniboss.is_empty())
	m.thorn_miniboss.phase = 'warn_roots'
	m.thorn_miniboss.safe_lane = 0
	m.thorn_miniboss.timer = 0
	m._process_thorn_miniboss(0.016)
	check('root warning becomes temporary brambles', m.thorn_miniboss.phase == 'brambles')
	m.player.invulnerable = 0
	m.player.position = Vector2(Tuning.THORN_BOSS_LEFT + Tuning.THORN_BOSS_LANE_WIDTH * 0.5, 299)
	var hp_before: float = m.hp
	m._process_thorn_miniboss(0.016)
	check('clear lane is safe', m.hp == hp_before)
	m.player.position.x += Tuning.THORN_BOSS_LANE_WIDTH
	m._process_thorn_miniboss(0.016)
	check('bramble lane damages', m.hp < hp_before)
	m.thorn_miniboss.timer = 0
	m._process_thorn_miniboss(0.016)
	check('brambles withdraw for recovery', m.thorn_miniboss.phase == 'recover')
	m.respawn()
	check('retry restores preboss checkpoint', m.player.position == m.CHECKPOINT_THORN_PREBOSS_POS and m.thorn_miniboss.is_empty())
	m._spawn_thorn_miniboss()
	check('miniboss returns after retry', not m.thorn_miniboss.is_empty())
	m.player.position = Vector2(m.THORN_MINIBOSS_POSITION.x - 25, 299)
	m.player.facing = 1
	m.player.attack_id += 1
	m.player.attack_left = (Tuning.SWIPE_ACTIVE_LATE + Tuning.SWIPE_ACTIVE_EARLY) * 0.5
	m.thorn_miniboss.hp = 1
	m.thorn_miniboss.phase = 'recover'
	var earned_before: int = m.progression.lifetime
	m._process_thorn_miniboss(0.016)
	check('baseline swipe grants five native Thorn Numen', m.thorn_miniboss_defeated and m.progression.lifetime == earned_before + 5)
	m.player.position = m.THORN_SHRINE_POSITION
	Input.action_press('attack')
	m._try_shrine_interaction(Tuning.SHRINE_AWAKEN_DURATION)
	Input.action_release('attack')
	check('Thorn Shrine completes objective', m.thorn_shrine_awakened)
	var continued = scene(storage)
	continued.continue_run()
	check('Continue retains defeat and Shrine', continued.thorn_miniboss_defeated and continued.thorn_shrine_awakened)
	check('Continue retains checkpoint and Thorn Numen', continued.active_checkpoint_id == Tuning.CHECKPOINT_THORN_PREBOSS and continued.progression.lifetime == m.progression.lifetime)
	continued.respawn()
	check('death retains completed objective', continued.thorn_miniboss_defeated and continued.thorn_shrine_awakened)
	print('Thorn checks: ', checks - failures, '/', checks)
	quit(1 if failures > 0 else 0)
