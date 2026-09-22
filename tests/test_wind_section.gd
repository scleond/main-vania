extends SceneTree
## Wind gameplay checks through the production session and save seam.
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

func earn_path(m, path: String) -> void:
	m.progression.earn('wind', m.progression.window_requirement())
	check('Wind offer for ' + path, m.progression.session_offer().get('element') == 'wind')
	check('select ' + path, m.progression.select_path(path))
	m.sync_derived()
	m.player.path_ranks = m.progression.ranks.duplicate()
	m.persist_run()

func _initialize() -> void:
	var storage = MemoryStorage.new()
	var m = scene(storage)
	m.new_game()
	check('baseline dash cooldown', Tuning.slipstream_cooldown(0) == Tuning.DASH_COOLDOWN)
	check('baseline route is continuous', m.platforms[0].end.x >= Tuning.WIND_ENEMY_MAX_X)
	m.player.position = Vector2(6100, 299)
	m._update_room()
	m._spawn_wind_encounters()
	check('Wind encounter spawned', m.enemies.size() > 0 and m.enemies[0].element == 'wind')
	m.enemies.clear()
	m.add_enemy(6100, false, 'wind')
	m._process_wind_enemy(m.enemies[0], 0.05)
	check('low hover warns', m.enemies[0].mode == 'warn' and m.enemies[0].y == Tuning.WIND_EASY_HOVER_HEIGHT)
	m.enemies[0].timer = 0
	m._process_wind_enemy(m.enemies[0], 0.05)
	check('swoop starts', m.enemies[0].mode == 'lunge')
	m.enemies[0].timer = 0
	m._process_wind_enemy(m.enemies[0], 0.05)
	check('swoop recovers', m.enemies[0].mode == 'recover')
	var before: float = absf(m.enemies[0].x - m.player.position.x)
	m.enemies[0].x += 80
	before = absf(m.enemies[0].x - m.player.position.x)
	m._process_wind_enemy(m.enemies[0], 0.1)
	check('recovery returns to swipe range', absf(m.enemies[0].x - m.player.position.x) < before)
	m.enemies.clear()
	m.add_enemy(6100, true, 'wind')
	m._process_wind_enemy(m.enemies[0], 0.05)
	check('circling enemy warns', m.enemies[0].medium and m.enemies[0].mode == 'warn')
	m.enemies.clear()
	m.player.position = Vector2(70, 299)
	earn_path(m, 'slipstream')
	check('Slipstream shortens dash cooldown', Tuning.slipstream_cooldown(1) < Tuning.DASH_COOLDOWN)
	earn_path(m, 'airborne')
	check('mixed build retains Slipstream and Airborne', m.progression.rank_of('slipstream') == 1 and m.progression.rank_of('airborne') == 1)
	var first_control: float = Tuning.airborne_acceleration(1)
	earn_path(m, 'airborne')
	check('repeat Airborne rank improves control', Tuning.airborne_acceleration(2) > first_control)
	check('Airborne keeps one air jump', m.progression.rank_of('airborne') == 2 and not m.player.air_jump_used)
	m.player.air_jump_used = true
	check('spent air jump is unavailable', m.player.air_jump_used)
	m.respawn()
	check('retry retains mixed mobility build', m.progression.rank_of('slipstream') == 1 and m.progression.rank_of('airborne') == 2 and not m.player.air_jump_used)
	m.persist_run()
	var continued = scene(storage)
	continued.continue_run()
	check('Continue restores both paths', continued.progression.rank_of('slipstream') == 1 and continued.progression.rank_of('airborne') == 2)
	check('Continue restores dash and control tuning', Tuning.slipstream_cooldown(continued.progression.rank_of('slipstream')) < Tuning.DASH_COOLDOWN and Tuning.airborne_acceleration(continued.progression.rank_of('airborne')) > Tuning.PLAYER_AIR_ACCELERATION)
	print('Wind checks: ', checks - failures, '/', checks)
	quit(1 if failures > 0 else 0)
