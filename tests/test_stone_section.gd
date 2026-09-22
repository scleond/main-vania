extends SceneTree
## Stone Section objective and saved retry through the running session.
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
	m.choice_delay = 999.0
	var easy := 0
	var medium := 0
	for encounter in m.STONE_ROUTE_ENCOUNTERS:
		if encounter.medium:
			medium += 1
		else:
			easy += 1
	check('Stone route has 18 easy and 2 medium Regular enemies', easy == 18 and medium == 2)
	check('Stone Section connection exposes objective and influence slots', m.STONE_SECTION_CONNECTION.id == Tuning.SECTION_STONE and m.STONE_SECTION_CONNECTION.objective == Tuning.SECTION_OBJECTIVE_STONE and m.STONE_SECTION_CONNECTION.influence_slots.size() == 2)
	check('required route has continuous ground', m.platforms[0].end.x >= m.STONE_SHRINE_POSITION.x)
	m.player.position = m.CHECKPOINT_STONE_ENTRY_POS
	m.hp = 2
	m._physics_process(0.016)
	check('entrance Checkpoint heals and saves', m.active_checkpoint_id == Tuning.CHECKPOINT_STONE_ENTRY and m.hp == Tuning.PLAYER_MAX_HP)
	m.player.position = Vector2(4900, 299)
	m._update_room()
	m._spawn_stone_encounters()
	var first_count: int = m.stone_encounter_index
	m.player.position = Vector2(5400, 299)
	m._update_room()
	m._spawn_stone_encounters()
	m.player.position = Vector2(4900, 299)
	m._update_room()
	m._spawn_stone_encounters()
	check('crossing rooms preserves spawned Regular enemies', m.stone_encounter_index == first_count + Tuning.MAX_ACTIVE_THREATS_PER_ROOM)
	m.respawn(false)
	check('rest resets Regular enemy arrangement', m.stone_encounter_index == 0 and m.enemies.is_empty())
	m.choice_delay = 999.0
	m.player.invulnerable = 999.0
	for room_x in [4900.0, 5400.0]:
		m.player.position = Vector2(room_x, 299)
		m._update_room()
		var room_total: int = 9 if room_x < 5250 else 20
		var rounds := 0
		while m.stone_route_kills < room_total and rounds < 20:
			m._spawn_stone_encounters()
			var active := 0
			for enemy in m.enemies:
				if enemy.element == Tuning.SECTION_STONE and enemy.x >= m.EMBER_ROOM_BOUNDS[m.room].left and enemy.x < m.EMBER_ROOM_BOUNDS[m.room].right:
					active += 1
				enemy.hp = 0
			check('Stone room threat cap', active <= Tuning.MAX_ACTIVE_THREATS_PER_ROOM)
			m._physics_process(0.016)
			rounds += 1
	check('complete Stone route cleared in session', m.stone_route_kills == 20)
	m.player.position = m.CHECKPOINT_STONE_PREBOSS_POS
	m.hp = 2
	m._physics_process(0.016)
	check('pre-encounter Checkpoint heals and saves', m.active_checkpoint_id == Tuning.CHECKPOINT_STONE_PREBOSS and m.hp == Tuning.PLAYER_MAX_HP)
	m.player.position = Vector2(Tuning.STONE_BOSS_LEFT + 20, 299)
	m._update_room()
	m._spawn_stone_miniboss()
	check('Stone Miniboss spawns after route', not m.stone_miniboss.is_empty())
	m.stone_miniboss.phase = 'warn_charge'
	m.stone_miniboss.timer = 0
	m._process_stone_miniboss(0.016)
	check('heavy charge follows warning', m.stone_miniboss.phase == 'charge')
	m.player.invulnerable = 0
	m.player.position = Vector2(m.stone_miniboss.x - 12, 299)
	var hp_before: float = m.hp
	m._process_stone_miniboss(0.016)
	check('heavy charge damages grounded Spirit', m.hp < hp_before)
	m.player.invulnerable = 999.0
	m.player.position.y = 200
	for i in range(60):
		if m.stone_miniboss.phase == 'stuck':
			break
		m._process_stone_miniboss(0.016)
	check('charge ends stuck at wall', m.stone_miniboss.phase == 'stuck' and m.stone_miniboss.x == Tuning.STONE_BOSS_LEFT)
	m.respawn()
	check('death gives short saved retry', m.player.position == m.CHECKPOINT_STONE_PREBOSS_POS and m.stone_miniboss.is_empty())
	var continued = scene(storage)
	continued.continue_run()
	check('Continue restores pre-encounter Checkpoint', continued.active_checkpoint_id == Tuning.CHECKPOINT_STONE_PREBOSS and continued.player.position == continued.CHECKPOINT_STONE_PREBOSS_POS)
	check('saved retry returns undefeated Miniboss', not continued.stone_miniboss_defeated)
	continued.player.position = Vector2(Tuning.STONE_BOSS_LEFT + 20, 299)
	continued._update_room()
	continued._spawn_stone_miniboss()
	continued.stone_miniboss.phase = 'stuck'
	continued.stone_miniboss.x = Tuning.STONE_BOSS_LEFT
	continued.stone_miniboss.dir = -1.0
	continued.stone_miniboss.timer = Tuning.STONE_BOSS_STUCK
	continued.player.position = Vector2(Tuning.STONE_BOSS_LEFT - 20, 299)
	continued.player.facing = 1
	continued.player.attack_id += 1
	continued.player.attack_left = (Tuning.SWIPE_ACTIVE_LATE + Tuning.SWIPE_ACTIVE_EARLY) * 0.5
	var boss_hp: float = continued.stone_miniboss.hp
	continued._process_stone_miniboss(0.016)
	check('armored front rejects baseline swipe', continued.stone_miniboss.hp == boss_hp)
	continued.player.position = Vector2(Tuning.STONE_BOSS_LEFT + 25, 299)
	continued.player.facing = -1
	continued.player.attack_id += 1
	continued._process_stone_miniboss(0.016)
	check('exposed trailing side takes baseline swipe', continued.stone_miniboss.hp == boss_hp - Tuning.SWIPE_DAMAGE)
	continued.stone_miniboss.hp = 1
	continued.player.attack_id += 1
	var earned_before: int = continued.progression.lifetime
	continued._process_stone_miniboss(0.016)
	check('baseline swipe defeats Miniboss for five Stone Numen', continued.stone_miniboss_defeated and continued.progression.lifetime == earned_before + Tuning.STONE_BOSS_NUMEN)
	continued.player.position = continued.STONE_SHRINE_POSITION
	Input.action_press('attack')
	continued._try_shrine_interaction(Tuning.SHRINE_AWAKEN_DURATION)
	Input.action_release('attack')
	check('Stone Shrine completes Section objective', continued.stone_shrine_awakened)
	var finished = scene(storage)
	finished.continue_run()
	check('Continue retains Miniboss defeat, Shrine, and Numen', finished.stone_miniboss_defeated and finished.stone_shrine_awakened and finished.progression.lifetime == continued.progression.lifetime)
	finished.respawn()
	check('death retains completed Stone objective', finished.stone_miniboss_defeated and finished.stone_shrine_awakened)
	print('Stone checks: ', checks - failures, '/', checks)
	quit(1 if failures > 0 else 0)
