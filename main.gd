extends Node2D
# Session state, persistence, and input boundary for the Ember combat room.
# Progression rules live in progression.gd (earning windows, thresholds, ties,
# overflow, repeatable ranks, eight-selection cap). Gameplay numbers live in
# tuning.gd. visual.gd is presentation-only. Death/rest restores encounters and
# health at the checkpoint while retaining numen and upgrades; this room has no
# room transitions, and crossing boundaries would not reset encounters either.
const Tuning = preload('res://tuning.gd')
const Progression = preload('res://progression.gd')
const RunSave = preload('res://run_save.gd')
var ember_art = preload('res://ember_art.gd').new()
const CHECKPOINT_POSITION = Vector2(70, 299)
const CHECKPOINT_ID := 'ember_trial_entry'
const PATH_IDS := ['searing_claws', 'flame_arc']
const LEGACY_NAMES := {'searing_claws': 'burn', 'flame_arc': 'arc'}
# Section connection points for later world assembly (stable IDs, no positions).
const SECTION_CONNECTION := {'id': Tuning.SECTION_EMBER, 'objective': Tuning.SECTION_OBJECTIVE_EMBER, 'influence_slots': Tuning.INFLUENCE_SLOTS}
const STORM_SECTION_CONNECTION := {'id': Tuning.SECTION_STORM, 'objective': Tuning.SECTION_OBJECTIVE_STORM, 'influence_slots': Tuning.INFLUENCE_SLOTS}
const THORN_SECTION_CONNECTION := {'id': Tuning.SECTION_THORN, 'objective': Tuning.SECTION_OBJECTIVE_THORN, 'influence_slots': Tuning.INFLUENCE_SLOTS}
const STONE_SECTION_CONNECTION := {'id': Tuning.SECTION_STONE, 'objective': Tuning.SECTION_OBJECTIVE_STONE, 'influence_slots': Tuning.INFLUENCE_SLOTS}
const WIND_SECTION_CONNECTION := {'id': Tuning.SECTION_WIND, 'objective': Tuning.SECTION_OBJECTIVE_WIND, 'influence_slots': Tuning.INFLUENCE_SLOTS}
# Authored encounter layout: ~18 easy, 2 medium across the route.
# Each entry: {x, medium, room} — room groups enable zone-based spawning.
const EMBER_ROUTE_ENCOUNTERS := [
	{'x': 350, 'medium': false, 'room': 'entry'},
	{'x': 440, 'medium': false, 'room': 'entry'},
	{'x': 570, 'medium': false, 'room': 'route1'},
	{'x': 650, 'medium': false, 'room': 'route1'},
	{'x': 740, 'medium': true, 'room': 'route1'},
	{'x': 820, 'medium': false, 'room': 'route1'},
	{'x': 900, 'medium': false, 'room': 'route2'},
	{'x': 970, 'medium': false, 'room': 'route2'},
	{'x': 1050, 'medium': false, 'room': 'route2'},
	{'x': 1120, 'medium': false, 'room': 'route2'},
	{'x': 1190, 'medium': true, 'room': 'route2'},
	{'x': 1260, 'medium': false, 'room': 'route2'},
	{'x': 1330, 'medium': false, 'room': 'route3'},
	{'x': 1400, 'medium': false, 'room': 'route3'},
	{'x': 1470, 'medium': false, 'room': 'route3'},
	{'x': 1530, 'medium': false, 'room': 'route3'},
	{'x': 1600, 'medium': false, 'room': 'route3'},
	{'x': 1660, 'medium': false, 'room': 'route3'},
	{'x': 1720, 'medium': false, 'room': 'route3'},
	{'x': 1780, 'medium': false, 'room': 'route3'},
]
const STORM_ROUTE_ENCOUNTERS := [
	{'x': 2470, 'medium': false, 'room': 'storm1'},
	{'x': 2560, 'medium': false, 'room': 'storm1'},
	{'x': 2660, 'medium': false, 'room': 'storm1'},
	{'x': 2720, 'medium': false, 'room': 'storm1'},
	{'x': 2760, 'medium': true, 'room': 'storm1'},
	{'x': 2780, 'medium': false, 'room': 'storm1'},
	{'x': 2800, 'medium': false, 'room': 'storm1'},
	{'x': 2815, 'medium': false, 'room': 'storm1'},
	{'x': 2890, 'medium': false, 'room': 'storm2'},
	{'x': 2990, 'medium': false, 'room': 'storm2'},
	{'x': 3100, 'medium': false, 'room': 'storm2'},
	{'x': 3210, 'medium': true, 'room': 'storm2'},
	{'x': 3230, 'medium': false, 'room': 'storm2'},
	{'x': 3250, 'medium': false, 'room': 'storm2'},
	{'x': 3280, 'medium': false, 'room': 'storm2'},
	{'x': 3300, 'medium': false, 'room': 'storm2'},
	{'x': 3320, 'medium': false, 'room': 'storm2'},
	{'x': 3330, 'medium': false, 'room': 'storm2'},
	{'x': 3338, 'medium': false, 'room': 'storm2'},
	{'x': 3340, 'medium': false, 'room': 'storm2'},
]
const THORN_ROUTE_ENCOUNTERS := [
	{'x': 3610, 'medium': false, 'room': 'thorn1'},
	{'x': 3650, 'medium': false, 'room': 'thorn1'},
	{'x': 3710, 'medium': false, 'room': 'thorn1'},
	{'x': 3760, 'medium': false, 'room': 'thorn1'},
	{'x': 3820, 'medium': false, 'room': 'thorn1'},
	{'x': 3880, 'medium': false, 'room': 'thorn1'},
	{'x': 3940, 'medium': true, 'room': 'thorn1'},
	{'x': 3980, 'medium': false, 'room': 'thorn1'},
	{'x': 4020, 'medium': false, 'room': 'thorn1'},
	{'x': 4070, 'medium': false, 'room': 'thorn2'},
	{'x': 4110, 'medium': false, 'room': 'thorn2'},
	{'x': 4170, 'medium': false, 'room': 'thorn2'},
	{'x': 4230, 'medium': false, 'room': 'thorn2'},
	{'x': 4290, 'medium': false, 'room': 'thorn2'},
	{'x': 4360, 'medium': true, 'room': 'thorn2'},
	{'x': 4420, 'medium': false, 'room': 'thorn2'},
	{'x': 4490, 'medium': false, 'room': 'thorn2'},
	{'x': 4550, 'medium': false, 'room': 'thorn2'},
	{'x': 4580, 'medium': false, 'room': 'thorn2'},
	{'x': 4600, 'medium': false, 'room': 'thorn2'},
]
const STONE_ROUTE_ENCOUNTERS := [
	{'x': 4850, 'medium': false, 'room': 'stone1'},
	{'x': 4900, 'medium': false, 'room': 'stone1'},
	{'x': 4950, 'medium': false, 'room': 'stone1'},
	{'x': 5000, 'medium': false, 'room': 'stone1'},
	{'x': 5050, 'medium': true, 'room': 'stone1'},
	{'x': 5090, 'medium': false, 'room': 'stone1'},
	{'x': 5130, 'medium': false, 'room': 'stone1'},
	{'x': 5170, 'medium': false, 'room': 'stone1'},
	{'x': 5210, 'medium': false, 'room': 'stone1'},
	{'x': 5290, 'medium': false, 'room': 'stone2'},
	{'x': 5330, 'medium': false, 'room': 'stone2'},
	{'x': 5370, 'medium': false, 'room': 'stone2'},
	{'x': 5410, 'medium': true, 'room': 'stone2'},
	{'x': 5450, 'medium': false, 'room': 'stone2'},
	{'x': 5490, 'medium': false, 'room': 'stone2'},
	{'x': 5530, 'medium': false, 'room': 'stone2'},
	{'x': 5570, 'medium': false, 'room': 'stone2'},
	{'x': 5600, 'medium': false, 'room': 'stone2'},
	{'x': 5630, 'medium': false, 'room': 'stone2'},
	{'x': 5660, 'medium': false, 'room': 'stone2'},
]
const WIND_ROUTE_ENCOUNTERS := [
	{'x': 6050, 'medium': false, 'room': 'wind1'},
	{'x': 6110, 'medium': false, 'room': 'wind1'},
	{'x': 6170, 'medium': false, 'room': 'wind1'},
	{'x': 6230, 'medium': false, 'room': 'wind1'},
	{'x': 6290, 'medium': true, 'room': 'wind1'},
	{'x': 6350, 'medium': false, 'room': 'wind1'},
	{'x': 6410, 'medium': false, 'room': 'wind1'},
	{'x': 6470, 'medium': false, 'room': 'wind1'},
	{'x': 6490, 'medium': false, 'room': 'wind1'},
	{'x': 6540, 'medium': false, 'room': 'wind2'},
	{'x': 6600, 'medium': false, 'room': 'wind2'},
	{'x': 6660, 'medium': false, 'room': 'wind2'},
	{'x': 6720, 'medium': false, 'room': 'wind2'},
	{'x': 6780, 'medium': true, 'room': 'wind2'},
	{'x': 6840, 'medium': false, 'room': 'wind2'},
	{'x': 6900, 'medium': false, 'room': 'wind2'},
	{'x': 6960, 'medium': false, 'room': 'wind2'},
	{'x': 7020, 'medium': false, 'room': 'wind2'},
	{'x': 7080, 'medium': false, 'room': 'wind2'},
	{'x': 7120, 'medium': false, 'room': 'wind2'},
]
const EMBER_ROOM_BOUNDS := {
	'entry': {'left': 15.0, 'right': 500.0},
	'route1': {'left': 450.0, 'right': 900.0},
	'route2': {'left': 850.0, 'right': 1350.0},
	'route3': {'left': 1300.0, 'right': 1850.0},
	'boss': {'left': 1800.0, 'right': 2350.0},
	'storm1': {'left': 2370.0, 'right': 2830.0},
	'storm2': {'left': 2830.0, 'right': 3350.0},
	'storm_boss': {'left': 3350.0, 'right': 3550.0},
	'thorn1': {'left': 3550.0, 'right': 4050.0},
	'thorn2': {'left': 4050.0, 'right': 4620.0},
	'thorn_boss': {'left': 4620.0, 'right': 4750.0},
	'stone1': {'left': 4750.0, 'right': 5250.0},
	'stone2': {'left': 5250.0, 'right': 5800.0},
	'stone_boss': {'left': 5800.0, 'right': 5950.0},
	'wind1': {'left': 5950.0, 'right': 6500.0},
	'wind2': {'left': 6500.0, 'right': 7180.0},
	'wind_boss': {'left': 7180.0, 'right': 7450.0},
	'sanctuary': {'left': 2000.0, 'right': 2400.0},
	'guardian': {'left': 2100.0, 'right': 2300.0},
}
const EMBER_PLATFORMS := [
	Rect2(0, 300, 7450, 60),
	Rect2(165, 240, 95, 10),
	Rect2(375, 217, 105, 10),
	Rect2(560, 235, 80, 10),
	Rect2(700, 210, 90, 10),
	Rect2(870, 245, 70, 10),
	Rect2(1020, 225, 85, 10),
	Rect2(1180, 240, 75, 10),
	Rect2(1350, 215, 90, 10),
	Rect2(1520, 235, 80, 10),
	Rect2(1680, 220, 85, 10),
	Rect2(1900, 250, 120, 10),
	Rect2(2100, 230, 100, 10),
	# Elevated Wind ledges are optional paths; the ground reaches the Shrine.
	Rect2(6110, 235, 105, 10),
	Rect2(6310, 218, 100, 10),
	Rect2(6610, 230, 110, 10),
	Rect2(6890, 215, 105, 10),
	# Sanctuary hub platforms between Ember boss and Storm entry.
	Rect2(2000, 300, 400, 60),
	# Guardian area beneath the sanctuary.
	Rect2(2100, 350, 200, 60),
]
const CHECKPOINT_EMBER_ENTRY_POS := Vector2(70, 299)
const CHECKPOINT_EMBER_PREBOSS_POS := Vector2(1870, 299)
const SHRINE_POSITION := Vector2(2200, 299)
const MINIBOSS_POSITION := Vector2(2050, 299)
const CHECKPOINT_STORM_ENTRY_POS := Vector2(2400, 299)
const CHECKPOINT_STORM_PREBOSS_POS := Vector2(3370, 299)
const STORM_MINIBOSS_POSITION := Vector2(3460, 299)
const STORM_SHRINE_POSITION := Vector2(3520, 299)
const CHECKPOINT_THORN_ENTRY_POS := Vector2(3580, 299)
const CHECKPOINT_THORN_PREBOSS_POS := Vector2(4625, 299)
const THORN_MINIBOSS_POSITION := Vector2(4700, 299)
const THORN_SHRINE_POSITION := Vector2(4735, 299)
const CHECKPOINT_STONE_ENTRY_POS := Vector2(4770, 299)
const CHECKPOINT_STONE_PREBOSS_POS := Vector2(5730, 299)
const STONE_MINIBOSS_POSITION := Vector2(5870, 299)
const STONE_SHRINE_POSITION := Vector2(5920, 299)
const CHECKPOINT_WIND_ENTRY_POS := Vector2(5990, 299)
const CHECKPOINT_WIND_PREBOSS_POS := Vector2(7150, 299)
const WIND_MINIBOSS_POSITION := Vector2(7300, 270)
const WIND_SHRINE_POSITION := Vector2(7400, 299)
const CHECKPOINT_SANCTUARY_POS := Vector2(2200, 299)
const CHECKPOINT_GUARDIAN_POS := Vector2(2200, 349)
var progression
var run_store
var saved_run: Dictionary = {}
var session_only := false
var player
var hp = 6.0
var numen = 0
var upgrade = ''
var playing = false
var choosing = false
var paused = false
var choice_mode = 'paths'
var enemies = []
var particles = []
var wave = 0
var choice_delay = 0.0
var kills = 0
var deaths = 0
var retries = 0
var clock = 0.0
var message = ''
var message_left = 0.0
var ui
var hud
var status
var menu
var menu_title
var menu_detail
var choice
var choice_title
var choice_detail
var slot_buttons = []
var pause_label
var platforms = EMBER_PLATFORMS
# --- Ember section state (issue #24) ---
var section := Tuning.SECTION_EMBER
var room := 'entry'
var miniboss: Dictionary = {}
var miniboss_defeated := false
var shrine_awakened := false
var shrine_interact := false
var shrine_timer := 0.0
var active_checkpoint_id := ''
var active_checkpoint_pos := Vector2.ZERO
var fire_waves: Array = []
var section_kills := 0
var section_total := 0
var route_cleared := false
var miniboss_spawned := false
var encounter_index := 0
var encounter_wait := 0.0
var miniboss_fire_cooldown := 0.0
var spawn_queue: Array = []
var storm_shots: Array = []
var storm_encounter_index := 0
var storm_miniboss: Dictionary = {}
var storm_miniboss_defeated := false
var storm_shrine_awakened := false
var storm_shrine_timer := 0.0
var storm_boss_spawned := false
var storm_strikes := 0
var storm_route_kills := 0
var storm_spawned_encounters: Dictionary = {}
var thorn_shots: Array = []
var thorn_encounter_index := 0
var thorn_spawned_encounters: Dictionary = {}
var thorn_route_kills := 0
var thorn_miniboss: Dictionary = {}
var thorn_miniboss_defeated := false
var thorn_shrine_awakened := false
var thorn_shrine_timer := 0.0
var thorn_boss_spawned := false
var thorn_patterns := 0
var stone_encounter_index := 0
var stone_spawned_encounters: Dictionary = {}
var stone_route_kills := 0
var stone_miniboss: Dictionary = {}
var stone_miniboss_defeated := false
var stone_shrine_awakened := false
var stone_shrine_timer := 0.0
var stone_boss_spawned := false
var wind_encounter_index := 0
var wind_spawned_encounters: Dictionary = {}
var wind_route_kills := 0
var wind_miniboss: Dictionary = {}
var wind_miniboss_defeated := false
var wind_shrine_awakened := false
var wind_shrine_timer := 0.0
var wind_boss_spawned := false
var wind_attack_count := 0
var reprisal_cooldown := 0.0
var barb_shots: Array = []
var bramble_patches: Array = []
var last_barb_attack := -1
var last_bramble_dash := -1
var last_bramble_x := 0.0
var secondary_cues: Array = []
var last_pulse_attack := -1
# --- World connections and shrine influence (issue #40) ---
var active_influence_sites: Array = []  # IDs of currently active influence sites
var influence_timers: Dictionary = {}   # site_id -> timer for cyclic effects
var shrine_pulses: Array = []          # active pulse effects [{x, timer, element}]
var guardian_unlocked := false          # true when all 5 shrines awakened

func label_at(text_value, at, size = 12, parent = null):
	var label = Label.new()
	label.text = text_value
	label.position = at
	label.add_theme_font_size_override('font_size', size)
	(ui if parent == null else parent).add_child(label)
	return label

func button_at(text_value, at, callback, parent):
	var b = Button.new()
	b.text = text_value
	b.position = at
	b.add_theme_font_size_override('font_size', 13)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _ready():
	progression = Progression.new()
	if run_store == null:
		run_store = RunSave.new()
	saved_run = run_store.load_run()
	session_only = run_store.last_error != ''
	for action in ['left', 'right', 'jump', 'dash', 'attack', 'pause', 'retry']:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	for pair in [['left', KEY_A], ['left', KEY_LEFT], ['right', KEY_D], ['right', KEY_RIGHT], ['jump', KEY_SPACE], ['dash', KEY_SHIFT], ['attack', KEY_J], ['attack', KEY_X]]:
		var e = InputEventKey.new()
		e.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], e)
	for pair in [['pause', KEY_ESCAPE], ['retry', KEY_K], ['retry', KEY_E]]:
		var e = InputEventKey.new()
		e.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], e)
	for pair in [['jump', JOY_BUTTON_A], ['attack', JOY_BUTTON_X], ['dash', JOY_BUTTON_RIGHT_SHOULDER]]:
		var e = InputEventJoypadButton.new()
		e.button_index = pair[1]
		InputMap.action_add_event(pair[0], e)
	for pair in [['pause', JOY_BUTTON_START], ['retry', JOY_BUTTON_BACK]]:
		var e = InputEventJoypadButton.new()
		e.button_index = pair[1]
		InputMap.action_add_event(pair[0], e)
	for pair in [['left', -1.0], ['right', 1.0]]:
		var e = InputEventJoypadMotion.new()
		e.axis = JOY_AXIS_LEFT_X
		e.axis_value = pair[1]
		InputMap.action_add_event(pair[0], e)
	for rect in platforms:
		var body = StaticBody2D.new()
		var c = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = rect.size
		c.shape = shape
		body.position = rect.get_center()
		body.add_child(c)
		add_child(body)
	player = load('res://player.gd').new()
	player.position = CHECKPOINT_POSITION
	add_child(player)
	ui = CanvasLayer.new()
	add_child(ui)
	label_at('EMBER + STORM + THORN + STONE + WIND / exploration route', Vector2(16, 8), 18)
	hud = label_at('', Vector2(16, 33))
	status = label_at('', Vector2(16, 53), 11)
	label_at('A/D or arrows move · Space jump · J/X action · Shift dash', Vector2(16, 315), 11)
	label_at('E/K retry nearby · Esc pause · P presentation demo · N new game', Vector2(16, 332), 11)
	menu = Panel.new()
	menu.position = Vector2(110, 90)
	menu.size = Vector2(420, 165)
	ui.add_child(menu)
	menu_title = label_at('', Vector2(24, 15), 20, menu)
	menu_detail = label_at('', Vector2(24, 49), 12, menu)
	button_at('Continue [Enter]', Vector2(24, 120), continue_run, menu)
	button_at('New Game [N]', Vector2(190, 120), new_game, menu)
	refresh_menu()
	choice = Panel.new()
	choice.position = Vector2(40, 88)
	choice.size = Vector2(560, 172)
	ui.add_child(choice)
	choice_title = label_at('EVOLVE / Ember family', Vector2(18, 12), 20, choice)
	choice_detail = label_at('Choose one permanent Ember upgrade with Numen. Play is paused.', Vector2(18, 40), 12, choice)
	slot_buttons.append(button_at('1 · Searing Claws', Vector2(18, 72), func(): choose_current_slot(0), choice))
	slot_buttons.append(button_at('2 · Flame Arc', Vector2(285, 72), func(): choose_current_slot(1), choice))
	label_at('All five Element paths accumulate with each selection.', Vector2(18, 118), 11, choice)
	label_at('Eight selections reach the Cap. No extra action button is needed.', Vector2(18, 139), 11, choice)
	choice.hide()
	pause_label = label_at('PAUSED — Esc to resume', Vector2(195, 165), 19)
	pause_label.hide()
	sync_derived()
	refresh()

func refresh_menu():
	menu_title.text = 'Continue a saved run' if not saved_run.is_empty() else 'New game'
	if session_only:
		menu_detail.text = 'Persistent storage is unavailable. You can play, but this run lasts only for this browser session.'
	elif not saved_run.is_empty():
		menu_detail.text = 'Continue from the checkpoint with your typed Numen window and upgrade ranks, or begin fresh.'
	else:
		menu_detail.text = 'Move, jump, dash and retry from the nearby checkpoint. Your progress saves automatically.'

func new_game():
	run_store.clear_run()
	session_only = session_only or run_store.last_error != ''
	progression.reset()
	kills = 0
	deaths = 0
	playing = true
	choosing = false
	paused = false
	choice_mode = 'paths'
	menu.hide()
	choice.hide()
	_init_section()
	respawn(false)

func start_run():
	# Kept for the existing session boundary and tests; it is New Game.
	new_game()

func continue_run():
	if saved_run.is_empty():
		new_game()
		return
	run_store.restore_progression(progression, saved_run)
	kills = 0
	deaths = 0
	playing = true
	choosing = false
	paused = false
	choice_mode = 'paths'
	menu.hide()
	choice.hide()
	_init_section()
	_restore_section_state()
	respawn(false)
	sync_derived()
	note('Continued from checkpoint. Numen and upgrades restored.')

func persist_run():
	if not playing:
		return
	var world_state = {
		'defeated_minibosses': ([Tuning.SHRINE_EMBER] if miniboss_defeated else []) + ([Tuning.SHRINE_STORM] if storm_miniboss_defeated else []) + ([Tuning.SHRINE_THORN] if thorn_miniboss_defeated else []) + ([Tuning.SHRINE_STONE] if stone_miniboss_defeated else []) + ([Tuning.SHRINE_WIND] if wind_miniboss_defeated else []),
		'awakened_shrines': ([Tuning.SHRINE_EMBER] if shrine_awakened else []) + ([Tuning.SHRINE_STORM] if storm_shrine_awakened else []) + ([Tuning.SHRINE_THORN] if thorn_shrine_awakened else []) + ([Tuning.SHRINE_STONE] if stone_shrine_awakened else []) + ([Tuning.SHRINE_WIND] if wind_shrine_awakened else []),
		'objectives': {Tuning.SECTION_OBJECTIVE_EMBER: shrine_awakened, Tuning.SECTION_OBJECTIVE_STORM: storm_shrine_awakened, Tuning.SECTION_OBJECTIVE_THORN: thorn_shrine_awakened, Tuning.SECTION_OBJECTIVE_STONE: stone_shrine_awakened, Tuning.SECTION_OBJECTIVE_WIND: wind_shrine_awakened},
		'active_influence_sites': active_influence_sites.duplicate(),
		'guardian_unlocked': guardian_unlocked,
	}
	var run = run_store.make_run(active_checkpoint_id if active_checkpoint_id != '' else CHECKPOINT_ID, progression, world_state)
	if run_store.save_run(run):
		saved_run = run
	else:
		session_only = true
		note(run_store.last_error)

func respawn(count = true):
	# Death/rest checkpoint restore: encounters and health reset, while earned
	# numen, window position, ranks, and selections are retained. Room
	# transitions alone never call this, so they never reset encounters.
	if count:
		deaths += 1
		if is_instance_valid(player.visual):
			player.visual.leave_death_pose(self, player.position)
	if is_instance_valid(player.visual):
		player.visual.reset_presentation()
	hp = Tuning.PLAYER_MAX_HP
	var spawn_pos = active_checkpoint_pos if active_checkpoint_id != '' else CHECKPOINT_EMBER_ENTRY_POS
	player.position = spawn_pos
	player.velocity = Vector2.ZERO
	player.invulnerable = Tuning.INVULNERABLE_DURATION
	player.attack_left = 0
	player.attack_wait = 0.0
	player.dash_left = 0
	player.dash_wait = 0.0
	player.air_jump_used = false
	particles.clear()
	enemies.clear()
	fire_waves.clear()
	encounter_index = 0
	encounter_wait = 0.0
	miniboss = {}
	miniboss_spawned = false
	miniboss_fire_cooldown = 0.0
	shrine_interact = false
	shrine_timer = 0.0
	spawn_queue.clear()
	storm_shots.clear()
	thorn_shots.clear()
	stone_encounter_index = 0
	stone_spawned_encounters.clear()
	stone_route_kills = 0
	stone_miniboss = {}
	stone_boss_spawned = false
	stone_shrine_timer = 0.0
	wind_encounter_index = 0
	wind_spawned_encounters.clear()
	wind_route_kills = 0
	wind_miniboss = {}
	wind_boss_spawned = false
	wind_shrine_timer = 0.0
	wind_attack_count = 0
	reprisal_cooldown = 0.0
	barb_shots.clear()
	bramble_patches.clear()
	secondary_cues.clear()
	storm_encounter_index = 0
	storm_miniboss = {}
	storm_boss_spawned = false
	storm_shrine_timer = 0.0
	storm_strikes = 0
	storm_route_kills = 0
	storm_spawned_encounters.clear()
	thorn_encounter_index = 0
	thorn_spawned_encounters.clear()
	thorn_route_kills = 0
	thorn_miniboss = {}
	thorn_boss_spawned = false
	thorn_shrine_timer = 0.0
	thorn_patterns = 0
	last_pulse_attack = player.attack_id
	last_barb_attack = player.attack_id
	last_bramble_dash = player.dash_id
	last_bramble_x = player.position.x
	section_kills = 0
	# Don't reset route_cleared — only new_game should reset the authored route.
	_update_room()
	# Delay next enemy spawn so cleared encounters stay clear briefly.
	encounter_wait = Tuning.WAVE_WAIT_AFTER_KILL
	note('Checkpoint restored. Numen and upgrades retained.' if count else 'Defeat the Ember creatures. Earn Numen toward evolution.')
	if playing:
		persist_run()

func note(value):
	message = value
	message_left = 4.0

func can_retry_nearby():
	var entry_dist = player.position.distance_to(CHECKPOINT_EMBER_ENTRY_POS)
	var preboss_dist = player.position.distance_to(CHECKPOINT_EMBER_PREBOSS_POS)
	return entry_dist <= Tuning.CHECKPOINT_RETRY_RANGE or preboss_dist <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_STORM_ENTRY_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_STORM_PREBOSS_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_THORN_ENTRY_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_THORN_PREBOSS_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_STONE_ENTRY_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_STONE_PREBOSS_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_WIND_ENTRY_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_WIND_PREBOSS_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_SANCTUARY_POS) <= Tuning.CHECKPOINT_RETRY_RANGE or player.position.distance_to(CHECKPOINT_GUARDIAN_POS) <= Tuning.CHECKPOINT_RETRY_RANGE

func burn_rank():
	return progression.rank_of('searing_claws')

func arc_rank():
	return progression.rank_of('flame_arc')

func chain_rank():
	return progression.rank_of('chain_spark')

func thunder_rank():
	return progression.rank_of('thunderbeat')

func barb_rank():
	return progression.rank_of('barb_shot')

func bramble_rank():
	return progression.rank_of('bramble_trail')

func stonehide_rank():
	return progression.rank_of('stonehide')

func reprisal_rank():
	return progression.rank_of('reprisal')

# --- Section initialization (issue #24) ---

func _init_section():
	room = 'entry'
	miniboss_defeated = false
	shrine_awakened = false
	shrine_interact = false
	shrine_timer = 0.0
	active_checkpoint_id = Tuning.CHECKPOINT_EMBER_ENTRY
	active_checkpoint_pos = CHECKPOINT_EMBER_ENTRY_POS
	fire_waves.clear()
	section_kills = 0
	section_total = EMBER_ROUTE_ENCOUNTERS.size()
	route_cleared = false
	miniboss_spawned = false
	encounter_index = 0
	encounter_wait = 0.0
	miniboss = {}
	miniboss_fire_cooldown = 0.0
	spawn_queue.clear()
	storm_shots.clear()
	storm_encounter_index = 0
	storm_miniboss = {}
	storm_miniboss_defeated = false
	storm_shrine_awakened = false
	storm_shrine_timer = 0.0
	storm_boss_spawned = false
	storm_strikes = 0
	storm_route_kills = 0
	storm_spawned_encounters.clear()
	thorn_shots.clear()
	thorn_encounter_index = 0
	thorn_spawned_encounters.clear()
	thorn_route_kills = 0
	thorn_miniboss = {}
	thorn_miniboss_defeated = false
	thorn_shrine_awakened = false
	thorn_shrine_timer = 0.0
	thorn_boss_spawned = false
	thorn_patterns = 0
	stone_encounter_index = 0
	stone_spawned_encounters.clear()
	stone_route_kills = 0
	stone_miniboss = {}
	stone_miniboss_defeated = false
	stone_shrine_awakened = false
	stone_shrine_timer = 0.0
	stone_boss_spawned = false
	wind_encounter_index = 0
	wind_spawned_encounters.clear()
	wind_route_kills = 0
	wind_miniboss = {}
	wind_boss_spawned = false
	wind_shrine_timer = 0.0
	wind_miniboss_defeated = false
	wind_shrine_awakened = false
	wind_attack_count = 0
	reprisal_cooldown = 0.0
	barb_shots.clear()
	bramble_patches.clear()
	secondary_cues.clear()
	active_influence_sites.clear()
	influence_timers.clear()
	shrine_pulses.clear()
	guardian_unlocked = false

func _restore_section_state():
	# Restore persistent section state from the saved run.
	if saved_run.is_empty():
		return
	var world = saved_run.get('world', {})
	var defeated = world.get('defeated_minibosses', [])
	miniboss_defeated = defeated.has(Tuning.SHRINE_EMBER)
	storm_miniboss_defeated = defeated.has(Tuning.SHRINE_STORM)
	thorn_miniboss_defeated = defeated.has(Tuning.SHRINE_THORN)
	stone_miniboss_defeated = defeated.has(Tuning.SHRINE_STONE)
	wind_miniboss_defeated = defeated.has(Tuning.SHRINE_WIND)
	var shrines = world.get('awakened_shrines', [])
	shrine_awakened = shrines.has(Tuning.SHRINE_EMBER)
	storm_shrine_awakened = shrines.has(Tuning.SHRINE_STORM)
	thorn_shrine_awakened = shrines.has(Tuning.SHRINE_THORN)
	stone_shrine_awakened = shrines.has(Tuning.SHRINE_STONE)
	wind_shrine_awakened = shrines.has(Tuning.SHRINE_WIND)
	var objectives = world.get('objectives', {})
	if objectives.has(Tuning.SECTION_OBJECTIVE_EMBER):
		shrine_awakened = shrine_awakened or objectives[Tuning.SECTION_OBJECTIVE_EMBER]
	if objectives.has(Tuning.SECTION_OBJECTIVE_STORM):
		storm_shrine_awakened = storm_shrine_awakened or objectives[Tuning.SECTION_OBJECTIVE_STORM]
	if objectives.has(Tuning.SECTION_OBJECTIVE_THORN):
		thorn_shrine_awakened = thorn_shrine_awakened or objectives[Tuning.SECTION_OBJECTIVE_THORN]
	if objectives.has(Tuning.SECTION_OBJECTIVE_STONE):
		stone_shrine_awakened = stone_shrine_awakened or objectives[Tuning.SECTION_OBJECTIVE_STONE]
	if objectives.has(Tuning.SECTION_OBJECTIVE_WIND):
		wind_shrine_awakened = wind_shrine_awakened or objectives[Tuning.SECTION_OBJECTIVE_WIND]
	# Restore influence sites and guardian unlock.
	active_influence_sites = Array(world.get('active_influence_sites', [])).duplicate()
	guardian_unlocked = bool(world.get('guardian_unlocked', false))
	# Rebuild influence timers for active sites.
	for site_id in active_influence_sites:
		if not influence_timers.has(site_id):
			influence_timers[site_id] = 0.0
	# Determine checkpoint from saved position or default to entry.
	var saved_checkpoint = saved_run.get('checkpoint_id', '')
	if saved_checkpoint == Tuning.CHECKPOINT_WIND_PREBOSS:
		active_checkpoint_id = Tuning.CHECKPOINT_WIND_PREBOSS
		active_checkpoint_pos = CHECKPOINT_WIND_PREBOSS_POS
	elif saved_checkpoint == Tuning.CHECKPOINT_WIND_ENTRY:
		active_checkpoint_id = Tuning.CHECKPOINT_WIND_ENTRY
		active_checkpoint_pos = CHECKPOINT_WIND_ENTRY_POS
	elif saved_checkpoint == Tuning.CHECKPOINT_STONE_PREBOSS:
		active_checkpoint_id = Tuning.CHECKPOINT_STONE_PREBOSS
		active_checkpoint_pos = CHECKPOINT_STONE_PREBOSS_POS
	elif saved_checkpoint == Tuning.CHECKPOINT_STONE_ENTRY:
		active_checkpoint_id = Tuning.CHECKPOINT_STONE_ENTRY
		active_checkpoint_pos = CHECKPOINT_STONE_ENTRY_POS
	elif saved_checkpoint == Tuning.CHECKPOINT_THORN_PREBOSS:
		active_checkpoint_id = Tuning.CHECKPOINT_THORN_PREBOSS
		active_checkpoint_pos = CHECKPOINT_THORN_PREBOSS_POS
	elif saved_checkpoint == Tuning.CHECKPOINT_THORN_ENTRY:
		active_checkpoint_id = Tuning.CHECKPOINT_THORN_ENTRY
		active_checkpoint_pos = CHECKPOINT_THORN_ENTRY_POS
	elif saved_checkpoint == Tuning.CHECKPOINT_STORM_PREBOSS:
		active_checkpoint_id = Tuning.CHECKPOINT_STORM_PREBOSS
		active_checkpoint_pos = CHECKPOINT_STORM_PREBOSS_POS
	elif saved_checkpoint == Tuning.CHECKPOINT_STORM_ENTRY:
		active_checkpoint_id = Tuning.CHECKPOINT_STORM_ENTRY
		active_checkpoint_pos = CHECKPOINT_STORM_ENTRY_POS
	elif miniboss_defeated or shrine_awakened:
		active_checkpoint_id = Tuning.CHECKPOINT_EMBER_PREBOSS
		active_checkpoint_pos = CHECKPOINT_EMBER_PREBOSS_POS
	else:
		active_checkpoint_id = Tuning.CHECKPOINT_EMBER_ENTRY
		active_checkpoint_pos = CHECKPOINT_EMBER_ENTRY_POS

func _update_room():
	# Map player position to the current room for encounter spawning.
	var px = player.position.x
	if px >= EMBER_ROOM_BOUNDS['wind1']['left']:
		room = 'wind_boss' if px >= EMBER_ROOM_BOUNDS['wind_boss']['left'] else ('wind2' if px >= EMBER_ROOM_BOUNDS['wind2']['left'] else 'wind1')
		return
	if px >= EMBER_ROOM_BOUNDS['stone1']['left']:
		room = 'stone_boss' if px >= EMBER_ROOM_BOUNDS['stone_boss']['left'] else ('stone2' if px >= EMBER_ROOM_BOUNDS['stone2']['left'] else 'stone1')
		return
	if px >= EMBER_ROOM_BOUNDS['thorn1']['left']:
		room = 'thorn_boss' if px >= EMBER_ROOM_BOUNDS['thorn_boss']['left'] else ('thorn2' if px >= EMBER_ROOM_BOUNDS['thorn2']['left'] else 'thorn1')
		return
	if px >= EMBER_ROOM_BOUNDS['storm1']['left']:
		room = 'storm_boss' if px >= EMBER_ROOM_BOUNDS['storm_boss']['left'] else ('storm2' if px >= EMBER_ROOM_BOUNDS['storm2']['left'] else 'storm1')
		return
	if px >= EMBER_ROOM_BOUNDS['sanctuary']['left'] and px <= EMBER_ROOM_BOUNDS['sanctuary']['right']:
		room = 'sanctuary'
		return
	if px >= EMBER_ROOM_BOUNDS['guardian']['left'] and px <= EMBER_ROOM_BOUNDS['guardian']['right']:
		room = 'guardian'
		return
	for r in EMBER_ROOM_BOUNDS:
		var bounds = EMBER_ROOM_BOUNDS[r]
		if px >= bounds['left'] and px <= bounds['right']:
			room = r
			return

func _check_checkpoint_heal():
	# Heal at checkpoints when player touches them. Triggers on re-visit
	# if the player is damaged, not only on first activation.
	var at_entry = player.position.distance_to(CHECKPOINT_EMBER_ENTRY_POS) < Tuning.CHECKPOINT_RETRY_RANGE
	var at_preboss = player.position.distance_to(CHECKPOINT_EMBER_PREBOSS_POS) < Tuning.CHECKPOINT_RETRY_RANGE
	var at_storm_entry = player.position.distance_to(CHECKPOINT_STORM_ENTRY_POS) < Tuning.CHECKPOINT_RETRY_RANGE
	var at_storm_preboss = player.position.distance_to(CHECKPOINT_STORM_PREBOSS_POS) < Tuning.CHECKPOINT_RETRY_RANGE and (storm_route_kills >= STORM_ROUTE_ENCOUNTERS.size() or active_checkpoint_id == Tuning.CHECKPOINT_STORM_PREBOSS)
	var at_thorn_entry = player.position.distance_to(CHECKPOINT_THORN_ENTRY_POS) < Tuning.CHECKPOINT_RETRY_RANGE
	var at_thorn_preboss = player.position.distance_to(CHECKPOINT_THORN_PREBOSS_POS) < Tuning.CHECKPOINT_RETRY_RANGE and (thorn_route_kills >= THORN_ROUTE_ENCOUNTERS.size() or active_checkpoint_id == Tuning.CHECKPOINT_THORN_PREBOSS)
	var at_stone_entry = player.position.distance_to(CHECKPOINT_STONE_ENTRY_POS) < Tuning.CHECKPOINT_RETRY_RANGE
	var at_stone_preboss = player.position.distance_to(CHECKPOINT_STONE_PREBOSS_POS) < Tuning.CHECKPOINT_RETRY_RANGE and (stone_route_kills >= STONE_ROUTE_ENCOUNTERS.size() or active_checkpoint_id == Tuning.CHECKPOINT_STONE_PREBOSS)
	var at_wind_entry = player.position.distance_to(CHECKPOINT_WIND_ENTRY_POS) < Tuning.CHECKPOINT_RETRY_RANGE
	var at_wind_preboss = player.position.distance_to(CHECKPOINT_WIND_PREBOSS_POS) < Tuning.CHECKPOINT_RETRY_RANGE and (wind_route_kills >= WIND_ROUTE_ENCOUNTERS.size() or active_checkpoint_id == Tuning.CHECKPOINT_WIND_PREBOSS)
	if at_entry:
		if active_checkpoint_id != Tuning.CHECKPOINT_EMBER_ENTRY:
			active_checkpoint_id = Tuning.CHECKPOINT_EMBER_ENTRY
			active_checkpoint_pos = CHECKPOINT_EMBER_ENTRY_POS
		if hp < Tuning.PLAYER_MAX_HP:
			hp = Tuning.PLAYER_MAX_HP
			note('Entry checkpoint reached. Health restored.')
			persist_run()
	elif at_preboss:
		if active_checkpoint_id != Tuning.CHECKPOINT_EMBER_PREBOSS:
			active_checkpoint_id = Tuning.CHECKPOINT_EMBER_PREBOSS
			active_checkpoint_pos = CHECKPOINT_EMBER_PREBOSS_POS
		if hp < Tuning.PLAYER_MAX_HP:
			hp = Tuning.PLAYER_MAX_HP
			note('Pre-boss checkpoint reached. Health restored.')
			persist_run()
	elif at_storm_entry or at_storm_preboss:
		var checkpoint_id = Tuning.CHECKPOINT_STORM_PREBOSS if at_storm_preboss else Tuning.CHECKPOINT_STORM_ENTRY
		var checkpoint_pos = CHECKPOINT_STORM_PREBOSS_POS if at_storm_preboss else CHECKPOINT_STORM_ENTRY_POS
		var changed = active_checkpoint_id != checkpoint_id
		active_checkpoint_id = checkpoint_id
		active_checkpoint_pos = checkpoint_pos
		if hp < Tuning.PLAYER_MAX_HP:
			hp = Tuning.PLAYER_MAX_HP
			note('Storm checkpoint reached. Health restored.')
			changed = true
		if changed:
			persist_run()
	elif at_thorn_entry or at_thorn_preboss:
		var checkpoint_id = Tuning.CHECKPOINT_THORN_PREBOSS if at_thorn_preboss else Tuning.CHECKPOINT_THORN_ENTRY
		var checkpoint_pos = CHECKPOINT_THORN_PREBOSS_POS if at_thorn_preboss else CHECKPOINT_THORN_ENTRY_POS
		var changed = active_checkpoint_id != checkpoint_id
		active_checkpoint_id = checkpoint_id
		active_checkpoint_pos = checkpoint_pos
		if hp < Tuning.PLAYER_MAX_HP:
			hp = Tuning.PLAYER_MAX_HP
			note('Thorn checkpoint reached. Health restored.')
			changed = true
		if changed:
			persist_run()
	elif at_stone_entry or at_stone_preboss:
		var checkpoint_id = Tuning.CHECKPOINT_STONE_PREBOSS if at_stone_preboss else Tuning.CHECKPOINT_STONE_ENTRY
		var checkpoint_pos = CHECKPOINT_STONE_PREBOSS_POS if at_stone_preboss else CHECKPOINT_STONE_ENTRY_POS
		var changed = active_checkpoint_id != checkpoint_id
		active_checkpoint_id = checkpoint_id
		active_checkpoint_pos = checkpoint_pos
		if hp < Tuning.PLAYER_MAX_HP:
			hp = Tuning.PLAYER_MAX_HP
			note('Stone checkpoint reached. Health restored.')
			changed = true
		if changed:
			persist_run()
	elif at_wind_entry or at_wind_preboss:
		var checkpoint_id = Tuning.CHECKPOINT_WIND_PREBOSS if at_wind_preboss else Tuning.CHECKPOINT_WIND_ENTRY
		var checkpoint_pos = CHECKPOINT_WIND_PREBOSS_POS if at_wind_preboss else CHECKPOINT_WIND_ENTRY_POS
		var changed = active_checkpoint_id != checkpoint_id
		active_checkpoint_id = checkpoint_id
		active_checkpoint_pos = checkpoint_pos
		if hp < Tuning.PLAYER_MAX_HP:
			hp = Tuning.PLAYER_MAX_HP
			note('Wind Checkpoint reached. Health restored.')
			changed = true
		if changed:
			persist_run()
	# Sanctuary checkpoint (hub between Ember and Storm).
	var at_sanctuary = player.position.distance_to(CHECKPOINT_SANCTUARY_POS) < Tuning.CHECKPOINT_RETRY_RANGE
	if at_sanctuary:
		var changed = active_checkpoint_id != Tuning.CHECKPOINT_GUARDIAN
		active_checkpoint_id = Tuning.CHECKPOINT_GUARDIAN
		active_checkpoint_pos = CHECKPOINT_SANCTUARY_POS
		if hp < Tuning.PLAYER_MAX_HP:
			hp = Tuning.PLAYER_MAX_HP
			note('Sanctuary reached. The Guardian stirs below.')
			changed = true
		if changed:
			persist_run()
	# Guardian checkpoint (beneath the sanctuary, unlocked after all shrines).
	var at_guardian = player.position.distance_to(CHECKPOINT_GUARDIAN_POS) < Tuning.CHECKPOINT_RETRY_RANGE and guardian_unlocked
	if at_guardian:
		var changed = active_checkpoint_id != Tuning.CHECKPOINT_GUARDIAN
		active_checkpoint_id = Tuning.CHECKPOINT_GUARDIAN
		active_checkpoint_pos = CHECKPOINT_GUARDIAN_POS
		if hp < Tuning.PLAYER_MAX_HP:
			hp = Tuning.PLAYER_MAX_HP
			note('Guardian checkpoint reached. Prepare for the encounter.')
			changed = true
		if changed:
			persist_run()

func _try_shrine_interaction(delta):
	# Require explicit hold input near the shrine for 1.5s. Frame-rate-independent.
	if miniboss_defeated and not shrine_awakened and player.position.distance_to(SHRINE_POSITION) < 60 and Input.is_action_pressed('attack'):
		shrine_interact = true
		shrine_timer += delta
		if shrine_timer >= Tuning.SHRINE_AWAKEN_DURATION:
			shrine_awakened = true
			shrine_interact = false
			note('Shrine awakened! Section objective complete.')
			_activate_shrine_influence(Tuning.SHRINE_EMBER)
			_check_guardian_unlock()
			persist_run()
	else:
		shrine_interact = false
		shrine_timer = 0.0
	if storm_miniboss_defeated and not storm_shrine_awakened and player.position.distance_to(STORM_SHRINE_POSITION) < Tuning.STORM_SHRINE_RANGE and Input.is_action_pressed('attack'):
		storm_shrine_timer += delta
		if storm_shrine_timer >= Tuning.SHRINE_AWAKEN_DURATION:
			storm_shrine_awakened = true
			note('Storm Shrine awakened! Section objective complete.')
			_activate_shrine_influence(Tuning.SHRINE_STORM)
			_check_guardian_unlock()
			persist_run()
	else:
		storm_shrine_timer = 0.0
	if thorn_miniboss_defeated and not thorn_shrine_awakened and player.position.distance_to(THORN_SHRINE_POSITION) < Tuning.THORN_SHRINE_RANGE and Input.is_action_pressed('attack'):
		thorn_shrine_timer += delta
		if thorn_shrine_timer >= Tuning.SHRINE_AWAKEN_DURATION:
			thorn_shrine_awakened = true
			note('Thorn Shrine awakened! Section objective complete.')
			_activate_shrine_influence(Tuning.SHRINE_THORN)
			_check_guardian_unlock()
			persist_run()
	else:
		thorn_shrine_timer = 0.0
	if stone_miniboss_defeated and not stone_shrine_awakened and player.position.distance_to(STONE_SHRINE_POSITION) < Tuning.STONE_SHRINE_RANGE and Input.is_action_pressed('attack'):
		stone_shrine_timer += delta
		if stone_shrine_timer >= Tuning.SHRINE_AWAKEN_DURATION:
			stone_shrine_awakened = true
			note('Stone Shrine awakened! Section objective complete.')
			_activate_shrine_influence(Tuning.SHRINE_STONE)
			_check_guardian_unlock()
			persist_run()
	else:
		stone_shrine_timer = 0.0
	if wind_miniboss_defeated and not wind_shrine_awakened and player.position.distance_to(WIND_SHRINE_POSITION) < Tuning.WIND_SHRINE_RANGE and Input.is_action_pressed('attack'):
		wind_shrine_timer += delta
		if wind_shrine_timer >= Tuning.SHRINE_AWAKEN_DURATION:
			wind_shrine_awakened = true
			note('Wind Shrine awakened! Section objective complete.')
			_activate_shrine_influence(Tuning.SHRINE_WIND)
			_check_guardian_unlock()
			persist_run()
	else:
		wind_shrine_timer = 0.0

# --- World connections and shrine influence (issue #40) ---

func _activate_shrine_influence(shrine_id: String) -> void:
	# Activate influence sites for a newly awakened shrine.
	for site in Tuning.INFLUENCE_SITES:
		if site['shrine'] == shrine_id and not active_influence_sites.has(site['id']):
			active_influence_sites.append(site['id'])
			influence_timers[site['id']] = 0.0
	_emit_shrine_pulse(shrine_id)

func _emit_shrine_pulse(shrine_id: String) -> void:
	# Emit a pulse effect when a shrine awakens; highlights map changes.
	var section := ''
	match shrine_id:
		Tuning.SHRINE_EMBER: section = Tuning.SECTION_EMBER
		Tuning.SHRINE_STORM: section = Tuning.SECTION_STORM
		Tuning.SHRINE_THORN: section = Tuning.SECTION_THORN
		Tuning.SHRINE_STONE: section = Tuning.SECTION_STONE
		Tuning.SHRINE_WIND: section = Tuning.SECTION_WIND
	if section != '':
		shrine_pulses.append({'section': section, 'timer': Tuning.SHRINE_PULSE_DURATION})

func _check_guardian_unlock() -> void:
	# Unlock the guardian beneath the sanctuary when all 5 shrines are awakened.
	if guardian_unlocked:
		return
	var all_awakened := shrine_awakened and storm_shrine_awakened and thorn_shrine_awakened and stone_shrine_awakened and wind_shrine_awakened
	if all_awakened:
		guardian_unlocked = true
		note('All five shrines awakened! The Guardian stirs beneath the Sanctuary.')
		persist_run()

func _section_for_position(px: float) -> String:
	# Return the section name for a given x position.
	if px < Tuning.SANCTUARY_LEFT:
		return Tuning.SECTION_EMBER
	if px < Tuning.STORM_ENEMY_MIN_X:
		return 'sanctuary'
	if px < Tuning.THORN_ENEMY_MIN_X:
		return Tuning.SECTION_STORM
	if px < Tuning.STONE_ENEMY_MIN_X:
		return Tuning.SECTION_THORN
	if px < Tuning.WIND_ENEMY_MIN_X:
		return Tuning.SECTION_STONE
	return Tuning.SECTION_WIND

func _process_influence_effects(delta: float) -> void:
	# Process all active influence effects each frame.
	for site_id in active_influence_sites:
		var site: Dictionary = {}
		for s in Tuning.INFLUENCE_SITES:
			if s['id'] == site_id:
				site = s
				break
		if site.is_empty():
			continue
		match site['effect']:
			'vent':
				_process_vent(site, delta)
			'burst':
				_process_burst(site)
			'bounce':
				_process_bounce(site)
			'cover':
				_process_cover(site)
			'updraft':
				_process_updraft(site, delta)

func _process_vent(site: Dictionary, delta: float) -> void:
	# Ember timed vents: periodic bursts that damage enemies in range.
	var timer: float = influence_timers.get(site['id'], 0.0)
	timer += delta
	var cycle: float = float(site['interval'])
	if timer >= cycle:
		timer -= cycle
	influence_timers[site['id']] = timer
	# Active phase: damage enemies in radius.
	if timer < float(site['active_time']):
		for enemy in enemies:
			if enemy.hp > 0 and absf(enemy.x - float(site['x'])) < float(site['radius']):
				enemy.hp -= float(site['damage'])
				enemy.flash = Tuning.ENEMY_HIT_FLASH

func _process_burst(site: Dictionary) -> void:
	# Storm strikeable conductive bursts: when the player strikes near the
	# burst position during an active swipe, it releases an electrical burst
	# damaging nearby enemies. Consumed until next shrine reactivation.
	if not Tuning.swipe_is_active(player.attack_left):
		return
	if absf(player.position.x - float(site['x'])) > float(site['strike_reach']):
		return
	# Burst fires once per swipe.
	var burst_key: String = str(site['id']) + '_fired'
	if influence_timers.has(burst_key) and influence_timers[burst_key] > 0:
		return
	influence_timers[burst_key] = 0.5
	for enemy in enemies:
		if enemy.hp > 0 and absf(enemy.x - float(site['x'])) < float(site['radius']):
			enemy.hp -= float(site['damage'])
			enemy.flash = Tuning.ENEMY_HIT_FLASH
	secondary_cues.append({'from': float(site['x']), 'to': float(site['radius']), 'timer': Tuning.SECONDARY_CUE_DURATION, 'pulse': true})

func _process_bounce(site: Dictionary) -> void:
	# Thorn bounce plants: launch the player upward when nearby.
	if player.position.y < 280:
		return
	if absf(player.position.x - float(site['x'])) > float(site['reach']):
		return
	if player.velocity.y >= 0:
		player.velocity.y = float(site['bounce_speed'])

func _process_cover(site: Dictionary) -> void:
	# Stone cover: static obstacle that blocks projectiles. Handled by drawing
	# a blocking zone; projectiles that intersect are destroyed.
	var sw: float = float(site['width'])
	var sh: float = float(site['height'])
	for shot in storm_shots:
		if absf(shot.position.x - float(site['x'])) < sw * 0.5 and absf(shot.position.y - 275) < sh:
			shot.timer = 0.0
	for shot in thorn_shots:
		if absf(shot.position.x - float(site['x'])) < sw * 0.5 and absf(shot.position.y - 275) < sh:
			shot.timer = 0.0

func _process_updraft(site: Dictionary, delta: float) -> void:
	# Wind updrafts: vertical air current that lifts the player.
	var w: float = float(site['width'])
	if absf(player.position.x - float(site['x'])) > w * 0.5:
		return
	if player.position.y > 200:
		player.velocity.y = minf(player.velocity.y, float(site['force']) * delta * 10)

func _spawn_neighbor_visitors() -> void:
	# Spawn occasional enemy visitors near section connections using existing types.
	if encounter_wait > 0:
		return
	if enemies.size() >= Tuning.MAX_ACTIVE_THREATS_PER_ROOM + Tuning.VISITOR_MAX:
		return
	var px: float = player.position.x
	for conn_id in Tuning.SECTION_CONNECTIONS:
		var bounds: Array = []
		match conn_id:
			Tuning.SECTION_EMBER: bounds = [EMBER_ROOM_BOUNDS['entry']['left'], EMBER_ROOM_BOUNDS['route3']['right']]
			Tuning.SECTION_STORM: bounds = [EMBER_ROOM_BOUNDS['storm1']['left'], EMBER_ROOM_BOUNDS['storm2']['right']]
			Tuning.SECTION_THORN: bounds = [EMBER_ROOM_BOUNDS['thorn1']['left'], EMBER_ROOM_BOUNDS['thorn2']['right']]
			Tuning.SECTION_STONE: bounds = [EMBER_ROOM_BOUNDS['stone1']['left'], EMBER_ROOM_BOUNDS['stone2']['right']]
			Tuning.SECTION_WIND: bounds = [EMBER_ROOM_BOUNDS['wind1']['left'], EMBER_ROOM_BOUNDS['wind2']['right']]
		if bounds.size() < 2:
			continue
		# Only spawn visitors in the player's current section or neighbors.
		if px < float(bounds[0]) - Tuning.VISITOR_SPAWN_RANGE or px > float(bounds[1]) + Tuning.VISITOR_SPAWN_RANGE:
			continue
		# Determine element type for the visitor based on the section.
		var visitor_element: String = str(conn_id)
		var visitor_x: float = clampf(px + randf_range(-Tuning.VISITOR_SPAWN_RANGE, Tuning.VISITOR_SPAWN_RANGE), float(bounds[0]), float(bounds[1]))
		# Don't stack too many visitors.
		var near_count: int = 0
		for e in enemies:
			if e.element == visitor_element and absf(e.x - visitor_x) < Tuning.VISITOR_SPAWN_RANGE:
				near_count += 1
		if near_count >= 2:
			continue
		add_enemy(visitor_x, false, visitor_element)

func sync_derived():
	# Legacy probe/HUD fields derived from the rule model.
	numen = progression.window_total()
	if burn_rank() > 0 or arc_rank() > 0:
		upgrade = 'burn' if burn_rank() >= arc_rank() else 'arc'
	else:
		upgrade = ''

func _unhandled_key_input(event):
	if not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_ENTER:
			if not playing:
				continue_run()
		KEY_N:
			new_game()
		KEY_1:
			if choosing:
				choose_current_slot(0)
		KEY_2:
			if choosing:
				choose_current_slot(1)
		KEY_P:
			if playing:
				player.visual.use_alternate_presentation(not player.visual.alternate_presentation)

func process_session_actions():
	if not playing or choosing:
		return
	if Input.is_action_just_pressed('pause'):
		paused = not paused
	if not paused and Input.is_action_just_pressed('retry') and can_retry_nearby():
		retries += 1
		respawn(false)

func choose_current_slot(slot):
	# Routes the two visible choice buttons for tied elements or paths.
	if not choosing:
		return
	var current = progression.session_offer()
	if current['kind'] == 'elements':
		var tied = current['elements']
		if slot < tied.size() and progression.choose_element(tied[slot]):
			# The tied-element decision is part of the durable earning window;
			# persist it before the player selects a path or reloads the browser.
			persist_run()
			refresh_choice_panel()
		return
	if current['kind'] != 'paths':
		return
	var paths = current['paths']
	if slot < paths.size():
		apply_path_choice(paths[slot])

func select_upgrade(value):
	# Legacy entry kept for the session boundary: 'burn'/'arc' path picks.
	if not choosing:
		return
	var path_id = 'searing_claws' if value == 'burn' else ('flame_arc' if value == 'arc' else '')
	if path_id == '':
		return
	apply_path_choice(path_id)

func apply_path_choice(path_id):
	if not progression.select_path(path_id):
		return
	sync_derived()
	if progression.pending_level_ups() > 0:
		# Chained level-up (overflow carried into the next window): stay paused
		# on the refreshed offer instead of closing the choice.
		refresh_choice_panel()
		note('Evolved again! Another upgrade is ready — choose.')
	else:
		choosing = false
		choice.hide()
		note('Evolved! Ranks persist through death. Keep fighting toward Fully evolved (8).')
	persist_run()

func _spawn_room_encounters():
	# Section encounter spawning: place enemies from the authored route,
	# capping concurrent active threats per room to prevent overwhelming the player.
	if route_cleared:
		return
	var active_count = 0
	for e in enemies:
		var b = EMBER_ROOM_BOUNDS.get(room, {'left': 0.0, 'right': 0.0})
		if e.x >= b['left'] and e.x <= b['right']:
			active_count += 1
	# Drain any queued encounters that fit within the cap.
	while not spawn_queue.is_empty() and active_count < Tuning.MAX_ACTIVE_THREATS_PER_ROOM:
		var enc_idx = spawn_queue.pop_front()
		var enc = EMBER_ROUTE_ENCOUNTERS[enc_idx]
		add_enemy(enc['x'], enc['medium'])
		active_count += 1
	# Push encounters from the route into the queue up to the cap.
	while encounter_index < EMBER_ROUTE_ENCOUNTERS.size():
		var enc = EMBER_ROUTE_ENCOUNTERS[encounter_index]
		if enc['room'] == room:
			if active_count < Tuning.MAX_ACTIVE_THREATS_PER_ROOM:
				add_enemy(enc['x'], enc['medium'])
				active_count += 1
			else:
				spawn_queue.append(encounter_index)
			encounter_index += 1
		elif EMBER_ROOM_BOUNDS.has(enc['room']) and EMBER_ROOM_BOUNDS[enc['room']]['left'] > EMBER_ROOM_BOUNDS[room]['right']:
			break
		else:
			encounter_index += 1
	if not spawn_queue.is_empty():
		return
	if encounter_index >= EMBER_ROUTE_ENCOUNTERS.size() and enemies.is_empty():
		route_cleared = true

func _spawn_storm_encounters():
	if room != 'storm1' and room != 'storm2':
		return
	var active := 0
	for enemy in enemies:
		if enemy.element == Tuning.SECTION_STORM and enemy.x >= EMBER_ROOM_BOUNDS[room]['left'] and enemy.x < EMBER_ROOM_BOUNDS[room]['right']:
			active += 1
	for index in range(STORM_ROUTE_ENCOUNTERS.size()):
		if active >= Tuning.MAX_ACTIVE_THREATS_PER_ROOM:
			break
		var encounter = STORM_ROUTE_ENCOUNTERS[index]
		if encounter['room'] != room or storm_spawned_encounters.has(index):
			continue
		add_enemy(encounter['x'], encounter['medium'], Tuning.SECTION_STORM)
		storm_spawned_encounters[index] = true
		storm_encounter_index = storm_spawned_encounters.size()
		active += 1

func _spawn_storm_miniboss():
	if room != 'storm_boss' or storm_boss_spawned or storm_miniboss_defeated or (storm_route_kills < STORM_ROUTE_ENCOUNTERS.size() and active_checkpoint_id != Tuning.CHECKPOINT_STORM_PREBOSS):
		return
	storm_boss_spawned = true
	storm_miniboss = {'x': STORM_MINIBOSS_POSITION.x, 'hp': Tuning.STORM_BOSS_HP, 'max_hp': Tuning.STORM_BOSS_HP, 'phase': 'idle', 'timer': Tuning.STORM_BOSS_IDLE, 'safe_lane': 1, 'hit_id': -1, 'flash': 0.0}
	note('Storm Miniboss: the unmarked lane stays safe. Strike during recovery.')

func _process_storm_miniboss(delta: float) -> void:
	if storm_miniboss.is_empty() or storm_miniboss_defeated:
		return
	storm_miniboss.flash = maxf(0.0, storm_miniboss.flash - delta)
	storm_miniboss.timer -= delta
	match storm_miniboss.phase:
		'idle':
			if storm_miniboss.timer <= 0:
				storm_miniboss.safe_lane = storm_strikes % Tuning.STORM_BOSS_LANE_COUNT
				storm_strikes += 1
				storm_miniboss.phase = 'warn_lightning'
				storm_miniboss.timer = Tuning.STORM_BOSS_WARN
		'warn_lightning':
			if storm_miniboss.timer <= 0:
				storm_miniboss.phase = 'lightning'
				storm_miniboss.timer = Tuning.STORM_BOSS_ACTIVE
		'lightning':
			var lane = int(floor((player.position.x - Tuning.STORM_BOSS_LEFT) / Tuning.STORM_BOSS_LANE_WIDTH))
			if lane >= 0 and lane < Tuning.STORM_BOSS_LANE_COUNT and lane != storm_miniboss.safe_lane and absf(player.position.y - Tuning.STORM_BOSS_GROUND_Y) < Tuning.STORM_BOSS_HIT_HEIGHT:
				_hurt_player(Tuning.STORM_BOSS_DAMAGE, 'Ground lightning! Move to the unmarked lane.')
			if storm_miniboss.timer <= 0:
				storm_miniboss.phase = 'recover'
				storm_miniboss.timer = Tuning.STORM_BOSS_RECOVER
		'recover':
			if storm_miniboss.timer <= 0:
				storm_miniboss.phase = 'idle'
				storm_miniboss.timer = Tuning.STORM_BOSS_IDLE
	var relative = storm_miniboss.x - player.position.x
	if storm_miniboss.phase == 'recover' and Tuning.swipe_is_active(player.attack_left) and storm_miniboss.hit_id != player.attack_id and relative * player.facing > Tuning.SWIPE_BACK_ALLOW and absf(relative) < Tuning.swipe_reach(arc_rank()) + Tuning.SWIPE_HITBOX_PAD and absf(player.position.y - Tuning.STORM_BOSS_GROUND_Y) < Tuning.SWIPE_HIT_HEIGHT:
		storm_miniboss.hit_id = player.attack_id
		storm_miniboss.hp -= Tuning.SWIPE_DAMAGE
		storm_miniboss.flash = Tuning.ENEMY_HIT_FLASH
	if storm_miniboss.hp <= 0:
		storm_miniboss_defeated = true
		storm_miniboss = {}
		progression.earn(Tuning.SECTION_STORM, Tuning.STORM_BOSS_NUMEN)
		choice_delay = Tuning.CHOICE_DELAY
		note('Storm Miniboss defeated! Activate the Shrine.')
		persist_run()

func _spawn_thorn_encounters():
	if room != 'thorn1' and room != 'thorn2':
		return
	var active := 0
	for enemy in enemies:
		if enemy.element == Tuning.SECTION_THORN and enemy.x >= EMBER_ROOM_BOUNDS[room]['left'] and enemy.x < EMBER_ROOM_BOUNDS[room]['right']:
			active += 1
	for index in range(THORN_ROUTE_ENCOUNTERS.size()):
		if active >= Tuning.MAX_ACTIVE_THREATS_PER_ROOM:
			break
		var encounter = THORN_ROUTE_ENCOUNTERS[index]
		if encounter['room'] != room or thorn_spawned_encounters.has(index):
			continue
		add_enemy(encounter['x'], encounter['medium'], Tuning.SECTION_THORN)
		thorn_spawned_encounters[index] = true
		thorn_encounter_index = thorn_spawned_encounters.size()
		active += 1

func _spawn_thorn_miniboss():
	if room != 'thorn_boss' or thorn_boss_spawned or thorn_miniboss_defeated or (thorn_route_kills < THORN_ROUTE_ENCOUNTERS.size() and active_checkpoint_id != Tuning.CHECKPOINT_THORN_PREBOSS):
		return
	thorn_boss_spawned = true
	thorn_miniboss = {'x': THORN_MINIBOSS_POSITION.x, 'hp': Tuning.THORN_BOSS_HP, 'max_hp': Tuning.THORN_BOSS_HP, 'phase': 'idle', 'timer': Tuning.THORN_BOSS_IDLE, 'safe_lane': 0, 'hit_id': -1, 'flash': 0.0}
	note('Thorn Miniboss: bramble roots mark the danger. Use the clear lane, then strike during recovery.')

func _process_thorn_miniboss(delta: float) -> void:
	if thorn_miniboss.is_empty() or thorn_miniboss_defeated:
		return
	thorn_miniboss.flash = maxf(0.0, thorn_miniboss.flash - delta)
	thorn_miniboss.timer -= delta
	match thorn_miniboss.phase:
		'idle':
			if thorn_miniboss.timer <= 0:
				thorn_miniboss.safe_lane = thorn_patterns % Tuning.THORN_BOSS_LANE_COUNT
				thorn_patterns += 1
				thorn_miniboss.phase = 'warn_roots'
				thorn_miniboss.timer = Tuning.THORN_BOSS_WARN
		'warn_roots':
			if thorn_miniboss.timer <= 0:
				thorn_miniboss.phase = 'brambles'
				thorn_miniboss.timer = Tuning.THORN_BOSS_ACTIVE
		'brambles':
			var lane = int(floor((player.position.x - Tuning.THORN_BOSS_LEFT) / Tuning.THORN_BOSS_LANE_WIDTH))
			if lane >= 0 and lane < Tuning.THORN_BOSS_LANE_COUNT and lane != thorn_miniboss.safe_lane and absf(player.position.y - Tuning.THORN_BOSS_GROUND_Y) < Tuning.THORN_BOSS_HIT_HEIGHT:
				_hurt_player(Tuning.THORN_BOSS_DAMAGE, 'Bramble thicket! Move through the clear opening.')
			if thorn_miniboss.timer <= 0:
				thorn_miniboss.phase = 'recover'
				thorn_miniboss.timer = Tuning.THORN_BOSS_RECOVER
		'recover':
			if thorn_miniboss.timer <= 0:
				thorn_miniboss.phase = 'idle'
				thorn_miniboss.timer = Tuning.THORN_BOSS_IDLE
	var relative: float = thorn_miniboss.x - player.position.x
	if thorn_miniboss.phase == 'recover' and Tuning.swipe_is_active(player.attack_left) and thorn_miniboss.hit_id != player.attack_id and relative * player.facing > Tuning.SWIPE_BACK_ALLOW and absf(relative) < Tuning.swipe_reach(arc_rank()) + Tuning.SWIPE_HITBOX_PAD and absf(player.position.y - Tuning.THORN_BOSS_GROUND_Y) < Tuning.SWIPE_HIT_HEIGHT:
		thorn_miniboss.hit_id = player.attack_id
		thorn_miniboss.hp -= Tuning.SWIPE_DAMAGE
		thorn_miniboss.flash = Tuning.ENEMY_HIT_FLASH
	if thorn_miniboss.hp <= 0:
		thorn_miniboss_defeated = true
		thorn_miniboss = {}
		progression.earn(Tuning.SECTION_THORN, Tuning.THORN_BOSS_NUMEN)
		choice_delay = Tuning.CHOICE_DELAY
		note('Thorn Miniboss defeated! Activate the Shrine.')
		persist_run()

func _spawn_stone_encounters():
	if room != 'stone1' and room != 'stone2':
		return
	var active := 0
	for enemy in enemies:
		if enemy.element == Tuning.SECTION_STONE and enemy.get('encounter_room', room) == room:
			active += 1
	for index in range(STONE_ROUTE_ENCOUNTERS.size()):
		if active >= Tuning.MAX_ACTIVE_THREATS_PER_ROOM:
			break
		var encounter = STONE_ROUTE_ENCOUNTERS[index]
		if encounter['room'] != room or stone_spawned_encounters.has(index):
			continue
		add_enemy(encounter['x'], encounter['medium'], Tuning.SECTION_STONE)
		enemies[-1]['encounter_room'] = room
		stone_spawned_encounters[index] = true
		stone_encounter_index = stone_spawned_encounters.size()
		active += 1

func _spawn_stone_miniboss():
	if room != 'stone_boss' or stone_boss_spawned or stone_miniboss_defeated or (stone_route_kills < STONE_ROUTE_ENCOUNTERS.size() and active_checkpoint_id != Tuning.CHECKPOINT_STONE_PREBOSS):
		return
	stone_boss_spawned = true
	stone_miniboss = {'x': STONE_MINIBOSS_POSITION.x, 'hp': Tuning.STONE_BOSS_HP, 'max_hp': Tuning.STONE_BOSS_HP, 'phase': 'idle', 'timer': Tuning.STONE_BOSS_IDLE, 'dir': -1.0, 'hit_id': -1, 'flash': 0.0}
	note('Stone Miniboss: jump the heavy charge, then strike its exposed trailing side while stuck.')

func _process_stone_miniboss(delta: float) -> void:
	if stone_miniboss.is_empty() or stone_miniboss_defeated:
		return
	stone_miniboss.flash = maxf(0.0, stone_miniboss.flash - delta)
	stone_miniboss.timer -= delta
	match stone_miniboss.phase:
		'idle':
			if stone_miniboss.timer <= 0:
				var difference: float = player.position.x - stone_miniboss.x
				stone_miniboss.dir = signf(difference) if absf(difference) > Tuning.STONE_BOSS_WEAK_SIDE_MARGIN else stone_miniboss.dir
				stone_miniboss.phase = 'warn_charge'
				stone_miniboss.timer = Tuning.STONE_BOSS_WARN
		'warn_charge':
			if stone_miniboss.timer <= 0:
				stone_miniboss.phase = 'charge'
				stone_miniboss.timer = Tuning.STONE_BOSS_CHARGE_DURATION
		'charge':
			stone_miniboss.x = clampf(stone_miniboss.x + stone_miniboss.dir * Tuning.STONE_BOSS_CHARGE_SPEED * delta, Tuning.STONE_BOSS_LEFT, Tuning.STONE_BOSS_RIGHT)
			if absf(player.position.x - stone_miniboss.x) < Tuning.STONE_BOSS_CONTACT_RANGE and absf(player.position.y - Tuning.STONE_BOSS_GROUND_Y) < Tuning.STONE_BOSS_HIT_HEIGHT:
				_hurt_player(Tuning.STONE_BOSS_DAMAGE, 'Heavy Stone charge! Jump or dash through the warning.')
			var at_wall: bool = stone_miniboss.x <= Tuning.STONE_BOSS_LEFT or stone_miniboss.x >= Tuning.STONE_BOSS_RIGHT
			if at_wall or stone_miniboss.timer <= 0:
				stone_miniboss.phase = 'stuck'
				stone_miniboss.timer = Tuning.STONE_BOSS_STUCK
		'stuck':
			if stone_miniboss.timer <= 0:
				stone_miniboss.phase = 'recover'
				stone_miniboss.timer = Tuning.STONE_BOSS_RECOVER
		'recover':
			if stone_miniboss.timer <= 0:
				stone_miniboss.phase = 'idle'
				stone_miniboss.timer = Tuning.STONE_BOSS_IDLE
	var relative: float = stone_miniboss.x - player.position.x
	var on_weak_side: bool = (player.position.x - stone_miniboss.x) * -stone_miniboss.dir > Tuning.STONE_BOSS_WEAK_SIDE_MARGIN
	if stone_miniboss.phase == 'stuck' and on_weak_side and Tuning.swipe_is_active(player.attack_left) and stone_miniboss.hit_id != player.attack_id and relative * player.facing > Tuning.SWIPE_BACK_ALLOW and absf(relative) < Tuning.swipe_reach(arc_rank()) + Tuning.SWIPE_HITBOX_PAD and absf(player.position.y - Tuning.STONE_BOSS_GROUND_Y) < Tuning.SWIPE_HIT_HEIGHT:
		stone_miniboss.hit_id = player.attack_id
		stone_miniboss.hp -= Tuning.SWIPE_DAMAGE
		stone_miniboss.flash = Tuning.ENEMY_HIT_FLASH
	if stone_miniboss.hp <= 0:
		stone_miniboss_defeated = true
		stone_miniboss = {}
		progression.earn(Tuning.SECTION_STONE, Tuning.STONE_BOSS_NUMEN)
		choice_delay = Tuning.CHOICE_DELAY
		note('Stone Miniboss defeated! Activate the Shrine.')
		persist_run()

func _spawn_wind_encounters():
	if room != 'wind1' and room != 'wind2':
		return
	var active := 0
	for enemy in enemies:
		if enemy.element == Tuning.SECTION_WIND and enemy.get('encounter_room', room) == room:
			active += 1
	for index in range(WIND_ROUTE_ENCOUNTERS.size()):
		if active >= Tuning.MAX_ACTIVE_THREATS_PER_ROOM:
			break
		var encounter = WIND_ROUTE_ENCOUNTERS[index]
		if encounter['room'] != room or wind_spawned_encounters.has(index):
			continue
		add_enemy(encounter['x'], encounter['medium'], Tuning.SECTION_WIND)
		enemies[-1]['encounter_room'] = room
		wind_spawned_encounters[index] = true
		wind_encounter_index = wind_spawned_encounters.size()
		active += 1

func _spawn_wind_miniboss():
	if room != 'wind_boss' or wind_boss_spawned or wind_miniboss_defeated or (wind_route_kills < WIND_ROUTE_ENCOUNTERS.size() and active_checkpoint_id != Tuning.CHECKPOINT_WIND_PREBOSS):
		return
	wind_boss_spawned = true
	wind_miniboss = {'x': WIND_MINIBOSS_POSITION.x, 'y': WIND_MINIBOSS_POSITION.y, 'hp': Tuning.WIND_BOSS_HP, 'max_hp': Tuning.WIND_BOSS_HP, 'phase': 'idle', 'timer': Tuning.WIND_BOSS_IDLE, 'dir': -1.0, 'target_x': WIND_MINIBOSS_POSITION.x, 'hit_id': -1, 'flash': 0.0}
	note('Wind Miniboss: jump the low swoop, dash against gusts, swipe during recovery.')

func _process_wind_miniboss(delta: float) -> void:
	if wind_miniboss.is_empty() or wind_miniboss_defeated:
		return
	wind_miniboss.flash = maxf(0.0, wind_miniboss.flash - delta)
	wind_miniboss.timer -= delta
	match wind_miniboss.phase:
		'idle':
			if wind_miniboss.timer <= 0:
				wind_miniboss.dir = signf(player.position.x - wind_miniboss.x) if absf(player.position.x - wind_miniboss.x) > Tuning.WIND_BOSS_FACE_MARGIN else wind_miniboss.dir
				wind_miniboss.target_x = clampf(player.position.x, Tuning.WIND_BOSS_LEFT, Tuning.WIND_BOSS_RIGHT)
				wind_miniboss.phase = 'warn_swoop' if wind_attack_count % 2 == 0 else 'warn_gust'
				wind_miniboss.timer = Tuning.WIND_BOSS_SWOOP_WARN if wind_attack_count % 2 == 0 else Tuning.WIND_BOSS_GUST_WARN
				wind_attack_count += 1
		'warn_swoop':
			if wind_miniboss.timer <= 0:
				wind_miniboss.phase = 'swoop'
				wind_miniboss.timer = Tuning.WIND_BOSS_SWOOP_ACTIVE
		'warn_gust':
			if wind_miniboss.timer <= 0:
				wind_miniboss.phase = 'gust'
				wind_miniboss.timer = Tuning.WIND_BOSS_GUST_ACTIVE
		'swoop':
			wind_miniboss.x = move_toward(wind_miniboss.x, wind_miniboss.target_x, Tuning.WIND_BOSS_SWOOP_SPEED * delta)
			wind_miniboss.y = move_toward(wind_miniboss.y, Tuning.WIND_BOSS_SWOOP_HEIGHT, Tuning.WIND_BOSS_DROP_SPEED * delta)
			if absf(player.position.x - wind_miniboss.x) < Tuning.WIND_BOSS_CONTACT_RANGE and absf(player.position.y - wind_miniboss.y) < Tuning.WIND_BOSS_CONTACT_HEIGHT:
				_hurt_player(Tuning.WIND_BOSS_SWOOP_DAMAGE, 'Low Wind swoop! Jump above it.')
			if wind_miniboss.timer <= 0:
				wind_miniboss.phase = 'recover'
				wind_miniboss.timer = Tuning.WIND_BOSS_SWOOP_RECOVER
				wind_miniboss.y = Tuning.WIND_BOSS_RECOVERY_HEIGHT
		'gust':
			if absf(player.position.x - wind_miniboss.x) < Tuning.WIND_BOSS_GUST_RANGE and absf(player.position.y - Tuning.WIND_BOSS_GROUND_Y) < Tuning.WIND_BOSS_GUST_HEIGHT:
				player.velocity.x += wind_miniboss.dir * Tuning.WIND_BOSS_GUST_FORCE * delta
				_hurt_player(Tuning.WIND_BOSS_GUST_DAMAGE, 'Wind gust! Dash against the push.')
			if wind_miniboss.timer <= 0:
				wind_miniboss.phase = 'recover'
				wind_miniboss.timer = Tuning.WIND_BOSS_GUST_RECOVER
				wind_miniboss.x = clampf(player.position.x + Tuning.WIND_BOSS_RECOVERY_OFFSET, Tuning.WIND_BOSS_LEFT, Tuning.WIND_BOSS_RIGHT)
				wind_miniboss.y = Tuning.WIND_BOSS_RECOVERY_HEIGHT
		'recover':
			if wind_miniboss.timer <= 0:
				wind_miniboss.phase = 'idle'
				wind_miniboss.timer = Tuning.WIND_BOSS_IDLE
	var relative: float = wind_miniboss.x - player.position.x
	if wind_miniboss.phase == 'recover' and Tuning.swipe_is_active(player.attack_left) and wind_miniboss.hit_id != player.attack_id and relative * player.facing > Tuning.SWIPE_BACK_ALLOW and absf(relative) < Tuning.swipe_reach(arc_rank()) + Tuning.SWIPE_HITBOX_PAD and absf(player.position.y - wind_miniboss.y) < Tuning.SWIPE_HIT_HEIGHT:
		wind_miniboss.hit_id = player.attack_id
		wind_miniboss.hp -= Tuning.SWIPE_DAMAGE
		wind_miniboss.flash = Tuning.ENEMY_HIT_FLASH
	if wind_miniboss.hp <= 0:
		wind_miniboss_defeated = true
		wind_miniboss = {}
		progression.earn(Tuning.SECTION_WIND, Tuning.WIND_BOSS_NUMEN)
		choice_delay = Tuning.CHOICE_DELAY
		note('Wind Miniboss defeated! Activate the Shrine.')
		persist_run()

func add_enemy(x, medium, element = Tuning.SECTION_EMBER):
	var enemy_hp = (Tuning.STONE_MEDIUM_HP if medium else Tuning.STONE_EASY_HP) if element == Tuning.SECTION_STONE else (Tuning.MEDIUM_HP if medium else Tuning.EASY_HP)
	enemies.append({
		'x': float(x),
		'hp': enemy_hp,
		'max_hp': enemy_hp,
		'medium': medium, 'element': element, 'mode': 'approach', 'timer': 0.0, 'dir': -1.0,
		'aim': Vector2.ZERO, 'relocate_target': 0.0, 'y': Tuning.WIND_MEDIUM_CIRCLE_HEIGHT if medium else Tuning.WIND_EASY_HOVER_HEIGHT, 'circle_time': 0.0, 'target_x': float(x),
		'hit_id': -1, 'burn': 0.0, 'burn_tick': 0.0, 'flash': 0.0,
	})

func _spawn_miniboss():
	# Spawn the Ember miniboss after all route enemies are cleared.
	if miniboss_spawned or miniboss_defeated:
		return
	if not route_cleared and not enemies.is_empty():
		return
	if not route_cleared and encounter_index < EMBER_ROUTE_ENCOUNTERS.size():
		return
	miniboss_spawned = true
	miniboss_fire_cooldown = Tuning.MINIBOSS_FIRE_WAVE_INTERVAL
	miniboss = {
		'x': MINIBOSS_POSITION.x,
		'hp': Tuning.MINIBOSS_HP,
		'max_hp': Tuning.MINIBOSS_HP,
		'phase': 'idle',
		'timer': Tuning.MINIBOSS_IDLE_DURATION,
		'dir': -1.0,
		'hit_id': -1,
		'burn': 0.0,
		'burn_tick': 0.0,
		'flash': 0.0,
	}
	note('The Ember miniboss awakens! Watch for ground slam and fire waves.')

func _process_miniboss(delta):
	if miniboss.is_empty() or miniboss_defeated:
		return
	miniboss.flash = maxf(0, miniboss.flash - delta)
	miniboss.timer -= delta
	var difference = player.position.x - miniboss['x']
	miniboss.dir = signf(difference) if absf(difference) > 10 else miniboss.dir
	match miniboss.phase:
		'idle':
			# Approach the player while idle.
			if absf(difference) > Tuning.MINIBOSS_TRIGGER_RANGE:
				miniboss.x += miniboss.dir * Tuning.MINIBOSS_APPROACH_SPEED * delta
			if miniboss.timer <= 0:
				# Choose attack: slam or fire wave.
				if absf(difference) < Tuning.MINIBOSS_TRIGGER_RANGE:
					miniboss.phase = 'warn_slam'
					miniboss.timer = Tuning.MINIBOSS_WARN_DURATION
				elif miniboss_fire_cooldown <= 0:
					miniboss.phase = 'fire_tell'
					miniboss.timer = Tuning.MINIBOSS_IDLE_TELL
				else:
					miniboss.timer = Tuning.MINIBOSS_IDLE_DURATION
		'warn_slam':
			# Visual tell: warning line drawn toward player.
			if miniboss.timer <= 0:
				miniboss.phase = 'slam'
				miniboss.timer = Tuning.MINIBOSS_SLAM_DURATION
		'slam':
			# Rush toward player position.
			miniboss.x += miniboss.dir * Tuning.MINIBOSS_SLAM_SPEED * delta
			if miniboss.timer <= 0:
				miniboss.phase = 'recover'
				miniboss.timer = Tuning.MINIBOSS_SLAM_RECOVER
		'recover':
			# Stunned: vulnerable to attacks.
			if miniboss.timer <= 0:
				miniboss.phase = 'idle'
				miniboss.timer = Tuning.MINIBOSS_IDLE_DURATION
		'fire_tell':
			# Brief tell before fire wave.
			if miniboss.timer <= 0:
				# Spawn a fire wave projectile.
				fire_waves.append({
					'x': miniboss['x'],
					'y': 275,
					'dir': miniboss.dir,
					'timer': Tuning.MINIBOSS_FIRE_WAVE_DURATION,
				})
				miniboss.phase = 'idle'
				miniboss.timer = Tuning.MINIBOSS_IDLE_DURATION
				miniboss_fire_cooldown = Tuning.MINIBOSS_FIRE_WAVE_INTERVAL
	miniboss_fire_cooldown = maxf(0, miniboss_fire_cooldown - delta)
	miniboss['x'] = clampf(miniboss['x'], EMBER_ROOM_BOUNDS['boss']['left'], EMBER_ROOM_BOUNDS['boss']['right'])
	# Miniboss contact damage.
	if miniboss.hp > 0 and miniboss.phase == 'slam' and absf(miniboss['x'] - player.position.x) < Tuning.ENEMY_CONTACT_RANGE and player.position.y > 266 and player.invulnerable <= 0 and player.dash_left <= 0:
		_hurt_player(Tuning.MINIBOSS_SLAM_DAMAGE, 'Hit by ground slam! Wait for the tell, then dodge.')
	# Miniboss swipe hit detection.
	var reach = Tuning.swipe_reach(arc_rank())
	var relative = miniboss['x'] - player.position.x
	if Tuning.swipe_is_active(player.attack_left) and miniboss.hit_id != player.attack_id and relative * player.facing > Tuning.SWIPE_BACK_ALLOW and absf(relative) < reach + Tuning.SWIPE_HITBOX_PAD and absf(player.position.y - 300) < Tuning.SWIPE_HIT_HEIGHT:
		miniboss.hit_id = player.attack_id
		miniboss.hp -= Tuning.SWIPE_DAMAGE
		miniboss.flash = Tuning.ENEMY_HIT_FLASH
		miniboss['x'] += player.facing * Tuning.SWIPE_KNOCKBACK
		if burn_rank() > 0:
			miniboss.burn = Tuning.burn_duration(burn_rank())
	if miniboss.burn > 0:
		miniboss.burn -= delta
		miniboss.burn_tick += delta
		if miniboss.burn_tick >= Tuning.BURN_TICK_INTERVAL:
			miniboss.burn_tick = 0
			miniboss.hp -= Tuning.BURN_TICK_DAMAGE
			miniboss.flash = 0.1
	# Miniboss defeated.
	if miniboss.hp <= 0:
		miniboss_defeated = true
		miniboss = {}
		fire_waves.clear()
		active_checkpoint_id = Tuning.CHECKPOINT_EMBER_PREBOSS
		active_checkpoint_pos = CHECKPOINT_EMBER_PREBOSS_POS
		progression.earn(Tuning.SECTION_EMBER, Tuning.MINIBOSS_NUMEN)
		note('Ember miniboss defeated! Approach the shrine to awaken it.')
		persist_run()

func _process_fire_waves(delta):
	var living = []
	for fw in fire_waves:
		fw.timer -= delta
		fw.x += fw.dir * Tuning.MINIBOSS_FIRE_WAVE_SPEED * delta
		# Fire wave contact damage.
		if fw.timer > 0 and absf(fw.x - player.position.x) < 20 and absf(player.position.y - fw.y) < Tuning.MINIBOSS_FIRE_WAVE_HEIGHT and player.invulnerable <= 0 and player.dash_left <= 0:
			_hurt_player(Tuning.MINIBOSS_FIRE_WAVE_DAMAGE, 'Hit by fire wave! Jump over it.')
		if fw.timer > 0:
			living.append(fw)
	fire_waves = living

func _hurt_by_storm_shot():
	if player.invulnerable > 0 or player.dash_left > 0:
		return
	_hurt_player(Tuning.STORM_SHOT_DAMAGE, 'Storm shot! Move during the charge, then punish recovery.')

func _hurt_player(amount: float, cue: String) -> void:
	# A genuine hit is the only trigger. Reduction has a hard ceiling and the
	# burst deals direct enemy damage, so retaliation cannot reflect itself.
	if player.invulnerable > 0 or player.dash_left > 0:
		return
	hp -= amount * (1.0 - Tuning.stonehide_reduction(stonehide_rank()))
	player.invulnerable = Tuning.INVULNERABLE_DURATION
	player.velocity.y = Tuning.HIT_LAUNCH_Y
	if hp > 0 and is_instance_valid(player.visual):
		player.visual.play_hurt()
	note(cue)
	if reprisal_rank() > 0 and reprisal_cooldown <= 0:
		reprisal_cooldown = Tuning.REPRISAL_COOLDOWN
		for enemy in enemies:
			if enemy.hp > 0 and absf(enemy.x - player.position.x) <= Tuning.reprisal_radius(reprisal_rank()):
				_secondary_damage(enemy, Tuning.reprisal_damage(reprisal_rank()), player.position.x)
		secondary_cues.append({'from': player.position.x, 'to': Tuning.reprisal_radius(reprisal_rank()), 'timer': Tuning.SECONDARY_CUE_DURATION, 'pulse': true})

func _process_storm_shots(delta):
	var living: Array = []
	for shot in storm_shots:
		shot.position += shot.velocity * delta
		shot.timer -= delta
		if shot.timer > 0 and shot.position.distance_to(player.position - Vector2(0, 22)) < Tuning.STORM_SHOT_RADIUS:
			_hurt_by_storm_shot()
			continue
		if shot.timer > 0:
			living.append(shot)
	storm_shots = living

func _process_storm_enemy(enemy: Dictionary, delta: float) -> void:
	var difference: float = player.position.x - enemy.x
	match enemy.mode:
		'approach':
			if absf(difference) < Tuning.STORM_SHOT_TRIGGER_RANGE:
				enemy.dir = signf(difference) if difference != 0 else 1.0
				if enemy.medium:
					enemy.mode = 'relocate'
					enemy.timer = Tuning.STORM_MEDIUM_RELOCATE_TIME
					enemy.relocate_target = clampf(enemy.x - enemy.dir * Tuning.STORM_RELOCATE_DISTANCE, Tuning.STORM_ENEMY_MIN_X, Tuning.STORM_ENEMY_MAX_X)
				else:
					enemy.mode = 'warn'
					enemy.timer = Tuning.STORM_EASY_CHARGE
			elif absf(difference) < Tuning.ENEMY_LEASH_RANGE:
				enemy.x += signf(difference) * Tuning.EASY_APPROACH_SPEED * delta
		'relocate':
			enemy.x = move_toward(enemy.x, enemy.relocate_target, Tuning.STORM_RELOCATE_SPEED * delta)
			if enemy.timer <= 0:
				enemy.mode = 'warn'
				enemy.timer = Tuning.STORM_MEDIUM_AIM_TIME
				enemy.aim = (player.position - Vector2(0, 22) - Vector2(enemy.x, Tuning.STORM_SHOT_HEIGHT)).normalized()
		'warn':
			if enemy.timer <= 0:
				var origin := Vector2(enemy.x, Tuning.STORM_SHOT_HEIGHT)
				var direction := Vector2(enemy.dir, 0)
				if enemy.medium:
					direction = enemy.aim
				storm_shots.append({'position': origin, 'velocity': direction * Tuning.STORM_SHOT_SPEED, 'timer': Tuning.STORM_SHOT_LIFETIME})
				enemy.mode = 'recover'
				enemy.timer = Tuning.STORM_MEDIUM_RECOVER if enemy.medium else Tuning.STORM_EASY_RECOVER
		'recover':
			if enemy.timer <= 0:
				enemy.mode = 'approach'

func _process_thorn_enemy(enemy: Dictionary, delta: float) -> void:
	var difference: float = player.position.x - enemy.x
	match enemy.mode:
		'approach':
			if absf(difference) < Tuning.THORN_TRIGGER_RANGE:
				enemy.dir = signf(difference) if difference != 0 else 1.0
				enemy.aim = (player.position - Vector2(0, 22) - Vector2(enemy.x, Tuning.THORN_SHOT_HEIGHT)).normalized()
				enemy.mode = 'warn'
				enemy.timer = Tuning.THORN_MEDIUM_WARN if enemy.medium else Tuning.THORN_EASY_WARN
			elif absf(difference) < Tuning.ENEMY_LEASH_RANGE:
				enemy.x += signf(difference) * Tuning.EASY_APPROACH_SPEED * delta
		'warn':
			if enemy.timer <= 0:
				var count: int = Tuning.THORN_FAN_COUNT if enemy.medium else 1
				for i in range(count):
					var angle: float = (float(i) - float(count - 1) * 0.5) * Tuning.THORN_FAN_ANGLE
					thorn_shots.append({'position': Vector2(enemy.x, Tuning.THORN_SHOT_HEIGHT), 'velocity': enemy.aim.rotated(angle) * Tuning.THORN_SHOT_SPEED, 'timer': Tuning.THORN_SHOT_LIFETIME})
				enemy.mode = 'recover'
				enemy.timer = Tuning.THORN_MEDIUM_RECOVER if enemy.medium else Tuning.THORN_EASY_RECOVER
		'recover':
			if enemy.timer <= 0:
				enemy.mode = 'approach'

func _process_thorn_shots(delta: float) -> void:
	var living: Array = []
	for shot in thorn_shots:
		shot.position += shot.velocity * delta
		shot.timer -= delta
		if shot.timer > 0 and shot.position.distance_to(player.position - Vector2(0, 22)) < Tuning.THORN_SHOT_RADIUS:
			if player.invulnerable <= 0 and player.dash_left <= 0:
				_hurt_player(Tuning.THORN_SHOT_DAMAGE, 'Thorn shot! Dodge the warning, then punish recovery.')
			continue
		if shot.timer > 0:
			living.append(shot)
	thorn_shots = living

func _process_stone_enemy(enemy: Dictionary, delta: float) -> void:
	var difference: float = player.position.x - enemy.x
	match enemy.mode:
		'approach':
			if absf(difference) <= (Tuning.STONE_MEDIUM_TRIGGER_RANGE if enemy.medium else Tuning.STONE_EASY_TRIGGER_RANGE) and player.position.y > 250:
				enemy.dir = signf(difference) if difference != 0 else enemy.dir
				enemy.mode = 'warn'
				enemy.timer = Tuning.STONE_MEDIUM_WARN if enemy.medium else Tuning.STONE_EASY_WARN
			elif absf(difference) < Tuning.ENEMY_LEASH_RANGE:
				enemy.dir = signf(difference) if difference != 0 else enemy.dir
				enemy.x += enemy.dir * (Tuning.STONE_MEDIUM_APPROACH_SPEED if enemy.medium else Tuning.STONE_EASY_APPROACH_SPEED) * delta
		'warn':
			if enemy.timer <= 0:
				enemy.mode = 'swipe'
				enemy.timer = Tuning.STONE_MEDIUM_SWIPE_DURATION if enemy.medium else Tuning.STONE_EASY_SWIPE_DURATION
		'swipe':
			if enemy.timer <= 0:
				enemy.mode = 'recover'
				enemy.timer = Tuning.STONE_MEDIUM_RECOVER if enemy.medium else Tuning.STONE_EASY_RECOVER
		'recover':
			if enemy.timer <= 0:
				enemy.mode = 'approach'
	if enemy.hp > 0 and enemy.mode == 'swipe' and absf(difference) <= (Tuning.STONE_MEDIUM_SWIPE_REACH if enemy.medium else Tuning.STONE_EASY_SWIPE_REACH) and difference * enemy.dir >= 0 and player.position.y > 266:
		_hurt_player(Tuning.STONE_MEDIUM_DAMAGE if enemy.medium else Tuning.STONE_EASY_DAMAGE, 'Stone swipe! Dodge, then strike during recovery.')

func _process_wind_enemy(enemy: Dictionary, delta: float) -> void:
	var difference: float = player.position.x - enemy.x
	match enemy.mode:
		'approach':
			enemy.circle_time += delta
			var offset: float = sin(enemy.circle_time * Tuning.WIND_CIRCLE_SPEED) * Tuning.WIND_CIRCLE_RADIUS if enemy.medium else 0.0
			var target: float = player.position.x + offset
			var speed: float = Tuning.WIND_MEDIUM_APPROACH_SPEED if enemy.medium else Tuning.WIND_EASY_APPROACH_SPEED
			enemy.x = move_toward(enemy.x, target, speed * delta)
			enemy.y = Tuning.WIND_MEDIUM_CIRCLE_HEIGHT if enemy.medium else Tuning.WIND_EASY_HOVER_HEIGHT
			if absf(difference) <= Tuning.WIND_TRIGGER_RANGE:
				enemy.mode = 'warn'
				enemy.timer = Tuning.WIND_MEDIUM_WARN if enemy.medium else Tuning.WIND_EASY_WARN
				enemy.target_x = player.position.x
				enemy.dir = signf(difference) if difference != 0 else enemy.dir
		'warn':
			if enemy.timer <= 0:
				enemy.mode = 'lunge'
				enemy.timer = Tuning.WIND_MEDIUM_DIVE_DURATION if enemy.medium else Tuning.WIND_EASY_SWOOP_DURATION
		'lunge':
			var speed: float = Tuning.WIND_MEDIUM_DIVE_SPEED if enemy.medium else Tuning.WIND_EASY_SWOOP_SPEED
			enemy.x = move_toward(enemy.x, enemy.target_x, speed * delta)
			enemy.y = move_toward(enemy.y, Tuning.WIND_ATTACK_HEIGHT, speed * delta)
			if enemy.timer <= 0:
				enemy.mode = 'recover'
				enemy.timer = Tuning.WIND_MEDIUM_RECOVER if enemy.medium else Tuning.WIND_EASY_RECOVER
		'recover':
			# Return to the player's swipe lane before circling again.
			enemy.x = move_toward(enemy.x, player.position.x, Tuning.WIND_RETURN_SPEED * delta)
			enemy.y = move_toward(enemy.y, Tuning.WIND_ATTACK_HEIGHT, Tuning.WIND_RETURN_SPEED * delta)
			if enemy.timer <= 0:
				enemy.mode = 'approach'
	if enemy.hp > 0 and enemy.mode == 'lunge' and absf(enemy.x - player.position.x) < Tuning.WIND_CONTACT_RANGE and absf(enemy.y - (player.position.y - 18.0)) < Tuning.WIND_SWIPE_VERTICAL_REACH:
		_hurt_player(Tuning.WIND_MEDIUM_DAMAGE if enemy.medium else Tuning.WIND_EASY_DAMAGE, 'Wind dive! Dodge the tell, then swipe during recovery.')

func _stone_guard_blocks(enemy: Dictionary, source_x: float) -> bool:
	return enemy.element == Tuning.SECTION_STONE and enemy.medium and enemy.mode != 'recover' and (source_x - enemy.x) * enemy.dir >= Tuning.STONE_GUARD_FRONT_MARGIN

func _spawn_player_effects() -> void:
	if barb_rank() > 0 and player.attack_id > last_barb_attack:
		last_barb_attack = player.attack_id
		barb_shots.append({'position': Vector2(player.position.x + player.facing * Tuning.BARB_SPAWN_OFFSET, Tuning.BARB_HEIGHT), 'direction': player.facing, 'timer': Tuning.BARB_LIFETIME, 'hits': []})
	if bramble_rank() > 0 and player.dash_id > last_bramble_dash:
		last_bramble_dash = player.dash_id
		last_bramble_x = player.position.x
		bramble_patches.append({'x': player.position.x, 'timer': Tuning.BRAMBLE_LIFETIME, 'hits': []})
	if bramble_rank() > 0 and player.dash_left > 0 and absf(player.position.x - last_bramble_x) >= Tuning.BRAMBLE_SPACING:
		last_bramble_x = player.position.x
		bramble_patches.append({'x': player.position.x, 'timer': Tuning.BRAMBLE_LIFETIME, 'hits': []})

func _process_player_effects(delta: float) -> void:
	var living_barbs: Array = []
	for shot in barb_shots:
		shot.position.x += shot.direction * Tuning.BARB_SPEED * delta
		shot.timer -= delta
		if shot.timer <= 0:
			continue
		for enemy in enemies:
			if enemy.hp > 0 and not shot.hits.has(enemy) and absf(enemy.x - shot.position.x) <= Tuning.BARB_RADIUS:
				_secondary_damage(enemy, Tuning.barb_damage(barb_rank()), enemy.x - shot.direction * Tuning.BARB_RADIUS, true)
				shot.hits.append(enemy)
		living_barbs.append(shot)
	barb_shots = living_barbs
	var living_patches: Array = []
	for patch in bramble_patches:
		patch.timer -= delta
		if patch.timer <= 0:
			continue
		for enemy in enemies:
			if enemy.hp > 0 and not patch.hits.has(enemy) and absf(enemy.x - patch.x) <= Tuning.BRAMBLE_RADIUS:
				_secondary_damage(enemy, Tuning.bramble_damage(bramble_rank()), patch.x)
				patch.hits.append(enemy)
		living_patches.append(patch)
	bramble_patches = living_patches

func _secondary_damage(enemy: Dictionary, amount: float, source_x: float, carries_claws: bool = false) -> void:
	# Secondary hits never enter swipe handling. Only Chain Spark and Barb Shot
	# inherit owned Searing Claws; burn ticks and other effects cannot proc more hits.
	if _stone_guard_blocks(enemy, source_x):
		return
	enemy.hp -= amount
	enemy.flash = Tuning.ENEMY_HIT_FLASH
	if carries_claws and burn_rank() > 0:
		enemy.burn = Tuning.burn_duration(burn_rank())

func _chain_from(source: Dictionary) -> void:
	if chain_rank() <= 0:
		return
	var nearest: Dictionary = {}
	var distance := Tuning.chain_reach(chain_rank())
	for target in enemies:
		if target == source or target.hp <= 0:
			continue
		var gap: float = absf(target.x - source.x)
		if gap <= distance:
			nearest = target
			distance = gap
	if not nearest.is_empty():
		_secondary_damage(nearest, Tuning.chain_damage(chain_rank()), source.x, true)
		secondary_cues.append({'from': source.x, 'to': nearest.x, 'timer': Tuning.SECONDARY_CUE_DURATION, 'pulse': false})

func _pulse_if_due() -> void:
	if thunder_rank() <= 0 or player.attack_id <= last_pulse_attack:
		return
	last_pulse_attack = player.attack_id
	if player.attack_id % Tuning.THUNDERBEAT_EVERY_SWIPES != 0:
		return
	for enemy in enemies:
		if enemy.hp > 0 and absf(enemy.x - player.position.x) <= Tuning.thunderbeat_reach(thunder_rank()):
			_secondary_damage(enemy, Tuning.thunderbeat_damage(thunder_rank()), player.position.x)
	secondary_cues.append({'from': player.position.x, 'to': Tuning.thunderbeat_reach(thunder_rank()), 'timer': Tuning.SECONDARY_CUE_DURATION, 'pulse': true})

func _physics_process(delta):
	process_session_actions()
	sync_derived()
	player.active = playing and not choosing and not paused
	player.upgrade = upgrade
	player.arc_rank = arc_rank()
	player.burn_rank = burn_rank()
	player.path_ranks = progression.ranks.duplicate()
	if is_instance_valid(player.visual):
		player.visual.path_ranks = progression.ranks.duplicate()
		player.visual.fully_evolved = progression.is_fully_evolved()
		player.visual.playback_paused = not player.active
	if not player.active:
		return
	clock += delta
	reprisal_cooldown = maxf(0.0, reprisal_cooldown - delta)
	message_left = maxf(0, message_left - delta)
	choice_delay = maxf(0, choice_delay - delta)
	_update_room()
	_check_checkpoint_heal()
	_try_shrine_interaction(delta)
	if progression.pending_level_ups() > 0 and choice_delay <= 0:
		choosing = true
		player.active = false
		refresh_choice_panel()
		choice.show()
		return
	# Spawn route encounters when the room is clear.
	if enemies.is_empty() and not route_cleared and not miniboss_spawned and not room.begins_with('storm') and not room.begins_with('thorn') and not room.begins_with('stone') and not room.begins_with('wind'):
		encounter_wait -= delta
		if encounter_wait <= 0:
			_spawn_room_encounters()
			encounter_wait = Tuning.WAVE_WAIT_AFTER_KILL
	if room == 'storm1' or room == 'storm2':
		encounter_wait -= delta
		if encounter_wait <= 0:
			_spawn_storm_encounters()
			encounter_wait = Tuning.WAVE_WAIT_AFTER_KILL
	if room == 'thorn1' or room == 'thorn2':
		encounter_wait -= delta
		if encounter_wait <= 0:
			_spawn_thorn_encounters()
			encounter_wait = Tuning.WAVE_WAIT_AFTER_KILL
	if room == 'stone1' or room == 'stone2':
		encounter_wait -= delta
		if encounter_wait <= 0:
			_spawn_stone_encounters()
			encounter_wait = Tuning.WAVE_WAIT_AFTER_KILL
	if room == 'wind1' or room == 'wind2':
		encounter_wait -= delta
		if encounter_wait <= 0:
			_spawn_wind_encounters()
			encounter_wait = Tuning.WAVE_WAIT_AFTER_KILL
	# Spawn miniboss after route is cleared.
	if not miniboss_defeated and not miniboss_spawned:
		_spawn_miniboss()
	_spawn_storm_miniboss()
	_spawn_thorn_miniboss()
	_spawn_stone_miniboss()
	_spawn_wind_miniboss()
	# Process miniboss.
	if not miniboss.is_empty():
		_process_miniboss(delta)
	if not storm_miniboss.is_empty():
		_process_storm_miniboss(delta)
	if not thorn_miniboss.is_empty():
		_process_thorn_miniboss(delta)
	if not stone_miniboss.is_empty():
		_process_stone_miniboss(delta)
	if not wind_miniboss.is_empty():
		_process_wind_miniboss(delta)
	# Process fire waves.
	_process_fire_waves(delta)
	_process_storm_shots(delta)
	_process_thorn_shots(delta)
	_spawn_player_effects()
	_pulse_if_due()
	for cue in secondary_cues:
		cue.timer -= delta
	secondary_cues = secondary_cues.filter(func(cue): return cue.timer > 0)
	for enemy in enemies:
		enemy.flash = maxf(0, enemy.flash - delta)
		var difference = player.position.x - enemy.x
		enemy.timer -= delta
		if enemy.element == Tuning.SECTION_STORM:
			_process_storm_enemy(enemy, delta)
		elif enemy.element == Tuning.SECTION_THORN:
			_process_thorn_enemy(enemy, delta)
		elif enemy.element == Tuning.SECTION_STONE:
			_process_stone_enemy(enemy, delta)
		elif enemy.element == Tuning.SECTION_WIND:
			_process_wind_enemy(enemy, delta)
		elif enemy.mode == 'approach':
			if absf(difference) < Tuning.EASY_TRIGGER_RANGE and player.position.y > 250:
				enemy.mode = 'warn'
				enemy.timer = Tuning.warn_duration(enemy.medium)
				enemy.dir = signf(difference) if difference != 0 else 1.0
			elif absf(difference) < Tuning.ENEMY_LEASH_RANGE:
				var speed = Tuning.MEDIUM_APPROACH_SPEED if enemy.medium else Tuning.EASY_APPROACH_SPEED
				enemy.x += signf(difference) * speed * delta
		elif enemy.mode == 'warn' and enemy.timer <= 0:
			enemy.mode = 'lunge'
			enemy.timer = Tuning.lunge_duration(enemy.medium)
		elif enemy.mode == 'lunge':
			enemy.x += enemy.dir * Tuning.lunge_speed(enemy.medium) * delta
			if enemy.timer <= 0:
				enemy.mode = 'recover'
				enemy.timer = Tuning.recover_duration(enemy.medium)
		elif enemy.mode == 'recover' and enemy.timer <= 0:
			enemy.mode = 'approach'
		# Clamp to current room bounds.
		var bounds = EMBER_ROOM_BOUNDS.get(room, {'left': Tuning.ENEMY_MIN_X, 'right': Tuning.ENEMY_MAX_X})
		if enemy.element == Tuning.SECTION_STORM:
			bounds = {'left': Tuning.STORM_ENEMY_MIN_X, 'right': Tuning.STORM_ENEMY_MAX_X}
		elif enemy.element == Tuning.SECTION_THORN:
			bounds = {'left': Tuning.THORN_ENEMY_MIN_X, 'right': Tuning.THORN_ENEMY_MAX_X}
		elif enemy.element == Tuning.SECTION_STONE:
			bounds = EMBER_ROOM_BOUNDS.get(enemy.get('encounter_room', room), {'left': Tuning.STONE_ENEMY_MIN_X, 'right': Tuning.STONE_ENEMY_MAX_X})
		elif enemy.element == Tuning.SECTION_WIND:
			bounds = EMBER_ROOM_BOUNDS.get(enemy.get('encounter_room', room), {'left': Tuning.WIND_ENEMY_MIN_X, 'right': Tuning.WIND_ENEMY_MAX_X})
		enemy.x = clampf(enemy.x, bounds['left'], bounds['right'])
		var reach = Tuning.swipe_reach(arc_rank())
		var relative = enemy.x - player.position.x
		if Tuning.swipe_is_active(player.attack_left) and enemy.hit_id != player.attack_id and relative * player.facing > Tuning.SWIPE_BACK_ALLOW and absf(relative) < reach + Tuning.SWIPE_HITBOX_PAD and absf(player.position.y - (enemy.y if enemy.element == Tuning.SECTION_WIND else 300.0)) < (Tuning.WIND_SWIPE_VERTICAL_REACH if enemy.element == Tuning.SECTION_WIND else Tuning.SWIPE_HIT_HEIGHT):
			enemy.hit_id = player.attack_id
			if not _stone_guard_blocks(enemy, player.position.x):
				enemy.hp -= Tuning.SWIPE_DAMAGE
				enemy.flash = Tuning.ENEMY_HIT_FLASH
				enemy.x += player.facing * Tuning.SWIPE_KNOCKBACK
				if burn_rank() > 0:
					enemy.burn = Tuning.burn_duration(burn_rank())
				_chain_from(enemy)
		if enemy.burn > 0:
			enemy.burn -= delta
			enemy.burn_tick += delta
			if enemy.burn_tick >= Tuning.BURN_TICK_INTERVAL:
				enemy.burn_tick = 0
				enemy.hp -= Tuning.BURN_TICK_DAMAGE
				enemy.flash = 0.1
		if enemy.hp > 0 and enemy.element == Tuning.SECTION_EMBER and enemy.mode == 'lunge' and absf(enemy.x - player.position.x) < Tuning.ENEMY_CONTACT_RANGE and player.position.y > 266:
			_hurt_player(Tuning.MEDIUM_DAMAGE if enemy.medium else Tuning.EASY_DAMAGE, 'Hit! Watch the warning, then punish the recovery.')
	_process_player_effects(delta)
	var living = []
	for enemy in enemies:
		if enemy.hp <= 0:
			var reward = Tuning.MEDIUM_NUMEN if enemy.medium else Tuning.EASY_NUMEN
			progression.earn(enemy.element, reward)
			kills += 1
			section_kills += 1
			if enemy.element == Tuning.SECTION_STORM:
				storm_route_kills += 1
			elif enemy.element == Tuning.SECTION_THORN:
				thorn_route_kills += 1
			elif enemy.element == Tuning.SECTION_STONE:
				stone_route_kills += 1
			elif enemy.element == Tuning.SECTION_WIND:
				wind_route_kills += 1
			choice_delay = Tuning.CHOICE_DELAY
			# Graphical quantities: one particle per numen earned.
			for i in range(reward):
				particles.append({'start': Vector2(enemy.x + i * 12, 277 - i * 8), 'time': 0.0})
			encounter_wait = Tuning.WAVE_WAIT_AFTER_KILL
			persist_run()
		else:
			living.append(enemy)
	enemies = living
	sync_derived()
	if hp <= 0 or player.position.y > 380:
		respawn()
	for particle in particles:
		particle.time += delta
	particles = particles.filter(func(p): return p.time < Tuning.PARTICLE_LIFETIME)
	# Process shrine influence effects and pulses.
	_process_influence_effects(delta)
	for pulse in shrine_pulses:
		pulse.timer -= delta
	shrine_pulses = shrine_pulses.filter(func(p): return p.timer > 0)
	# Process burst cooldown timers.
	for key in influence_timers.keys():
		if key.ends_with('_fired'):
			influence_timers[key] = maxf(0.0, influence_timers[key] - delta)
	# Spawn neighbor visitors near section connections.
	_spawn_neighbor_visitors()

func path_label(path_id, slot):
	var info = Progression.PATH_CATALOG[path_id]
	var rank = progression.rank_of(path_id)
	var key = '1' if slot == 0 else '2'
	if path_id == 'searing_claws':
		return '%s · %s  rank %d → %d\nSwipes ignite (burn %.1fs, tick %.1fs)' % [key, info['name'], rank, rank + 1, Tuning.burn_duration(rank + 1), Tuning.BURN_TICK_INTERVAL]
	if path_id == 'chain_spark':
		return '%s · %s  rank %d → %d\nArc reach %d · damage %.1f' % [key, info['name'], rank, rank + 1, int(Tuning.chain_reach(rank + 1)), Tuning.chain_damage(rank + 1)]
	if path_id == 'thunderbeat':
		return '%s · %s  rank %d → %d\nEvery %d swipes · radius %d · damage %.1f' % [key, info['name'], rank, rank + 1, Tuning.THUNDERBEAT_EVERY_SWIPES, int(Tuning.thunderbeat_reach(rank + 1)), Tuning.thunderbeat_damage(rank + 1)]
	if path_id == 'barb_shot':
		return '%s · %s  rank %d → %d\nSwipe projectile · damage %.1f · %.1fs' % [key, info['name'], rank, rank + 1, Tuning.barb_damage(rank + 1), Tuning.BARB_LIFETIME]
	if path_id == 'bramble_trail':
		return '%s · %s  rank %d → %d\nDash patch · damage %.1f · %.1fs' % [key, info['name'], rank, rank + 1, Tuning.bramble_damage(rank + 1), Tuning.BRAMBLE_LIFETIME]
	if path_id == 'slipstream':
		return '%s · %s  rank %d → %d\nDash cooldown %.2fs' % [key, info['name'], rank, rank + 1, Tuning.slipstream_cooldown(rank + 1)]
	if path_id == 'airborne':
		return '%s · %s  rank %d → %d\nOne air jump · air control %d' % [key, info['name'], rank, rank + 1, int(Tuning.airborne_acceleration(rank + 1))]
	if path_id == 'stonehide':
		return '%s · %s  rank %d → %d\nDamage reduction %d%% (cap %d%%)' % [key, info['name'], rank, rank + 1, int(Tuning.stonehide_reduction(rank + 1) * 100.0), int(Tuning.STONEHIDE_MAX_REDUCTION * 100.0)]
	if path_id == 'reprisal':
		return '%s · %s  rank %d → %d\nHurt burst %.2f damage · %d radius · %.2fs cooldown' % [key, info['name'], rank, rank + 1, Tuning.reprisal_damage(rank + 1), int(Tuning.reprisal_radius(rank + 1)), Tuning.REPRISAL_COOLDOWN]
	return '%s · %s  rank %d → %d\nSwipes reach farther (reach %d)' % [key, info['name'], rank, rank + 1, int(Tuning.swipe_reach(rank + 1))]

func refresh_choice_panel():
	var current = progression.session_offer()
	if current['kind'] == 'elements':
		choice_mode = 'elements'
		choice_title.text = 'EVOLVE / tied elements'
		choice_detail.text = 'Numen tie for the lead. Choose which element to evolve first. Play is paused.'
		var tied = current['elements']
		for i in range(slot_buttons.size()):
			slot_buttons[i].text = '%d · %s' % [i + 1, String(tied[i]).capitalize()] if i < tied.size() else '—'
	else:
		choice_mode = 'paths'
		var element_name = String(current.get('element', Tuning.SECTION_EMBER)).capitalize()
		var selected = progression.selections
		choice_title.text = 'EVOLVE / %s family  (%d/%d)' % [element_name, selected + 1, Progression.SELECTION_CAP]
		choice_detail.text = 'Choose one permanent %s upgrade with Numen (repeatable to rank 8). Play is paused.' % element_name.capitalize()
		var paths: Array = current.get('paths', [])
		for i in range(slot_buttons.size()):
			slot_buttons[i].text = path_label(paths[i], i) if i < paths.size() else '—'

func refresh():
	var requirement = progression.window_requirement()
	var leaders = progression.dominant_elements()
	var leader_text = 'none' if leaders.is_empty() else '/'.join(leaders)
	if progression.is_fully_evolved():
		hud.text = 'Health %.1f / %d   |   Fully evolved %d/%d   |   Claws r%d · Arc r%d' % [hp, int(Tuning.PLAYER_MAX_HP), progression.selections, Progression.SELECTION_CAP, burn_rank(), arc_rank()]
	elif requirement > 0:
		hud.text = 'Health %.1f / %d   |   Numen %d / %d   |   Claws r%d · Arc r%d (%d/%d)' % [hp, int(Tuning.PLAYER_MAX_HP), numen, requirement, burn_rank(), arc_rank(), progression.selections, Progression.SELECTION_CAP]
	else:
		hud.text = 'Health %.1f / %d   |   Claws r%d · Arc r%d (%d/%d)' % [hp, int(Tuning.PLAYER_MAX_HP), burn_rank(), arc_rank(), progression.selections, Progression.SELECTION_CAP]
	hud.text += '   |   Chain r%d · Beat r%d' % [chain_rank(), thunder_rank()]
	hud.text += '   |   Barb r%d · Bramble r%d' % [barb_rank(), bramble_rank()]
	hud.text += '   |   Wind Dash r%d (%.2fs) · Air r%d' % [progression.rank_of('slipstream'), Tuning.slipstream_cooldown(progression.rank_of('slipstream')), progression.rank_of('airborne')]
	hud.text += '   |   Hide r%d (%d%%) · Reprisal r%d (%.1fs)' % [stonehide_rank(), int(Tuning.stonehide_reduction(stonehide_rank()) * 100.0), reprisal_rank(), reprisal_cooldown]
	if session_only:
		hud.text += '   |   Session-only (storage unavailable)'
	hud.text += '   |   Room: %s' % room.capitalize()
	if miniboss_defeated and not shrine_awakened:
		hud.text += '   |   Shrine ready'
	elif shrine_awakened:
		hud.text += '   |   Section complete'
	if guardian_unlocked:
		hud.text += '   |   Guardian unlocked'
	if active_influence_sites.size() > 0:
		hud.text += '   |   Influence: %d sites' % active_influence_sites.size()
	if choosing:
		refresh_choice_panel()
		status.text = message if message_left > 0 else ('Wave %d  |  Leading %s  |  Next %d Numen' % [wave, leader_text, requirement] if not progression.is_fully_evolved() else 'Wave %d  |  Fully evolved; Numen no longer accumulates' % wave)

func probe_enemies():
	var out = []
	for enemy in enemies:
		out.append({'x': enemy.x, 'medium': enemy.medium, 'element': enemy.element, 'mode': enemy.mode, 'hp': enemy.hp, 'facing': enemy.dir, 'guarding': enemy.element == Tuning.SECTION_STONE and enemy.medium and enemy.mode != 'recover', 'recovery_left': maxf(0.0, enemy.timer) if enemy.mode == 'recover' else 0.0, 'y': enemy.y if enemy.element == Tuning.SECTION_WIND else 300.0})
	return out

func probe_section():
	return {
		'section': section,
		'room': room,
		'miniboss_defeated': miniboss_defeated,
		'shrine_awakened': shrine_awakened,
		'route_cleared': route_cleared,
		'section_kills': section_kills,
		'section_total': section_total,
		'checkpoint_id': active_checkpoint_id,
		'miniboss_phase': miniboss.get('phase', ''),
		'miniboss_hp': miniboss.get('hp', 0) if not miniboss.is_empty() else 0,
		'fire_waves': fire_waves.size(),
		'storm_shots': storm_shots.size(),
		'storm_encounters': storm_encounter_index,
		'storm_route_kills': storm_route_kills,
		'storm_miniboss_defeated': storm_miniboss_defeated,
		'storm_shrine_awakened': storm_shrine_awakened,
		'storm_miniboss_phase': storm_miniboss.get('phase', ''),
		'storm_miniboss_hp': storm_miniboss.get('hp', 0),
		'storm_safe_lane': storm_miniboss.get('safe_lane', -1),
		'thorn_shots': thorn_shots.size(),
		'thorn_encounters': thorn_encounter_index,
		'thorn_route_kills': thorn_route_kills,
		'thorn_miniboss_defeated': thorn_miniboss_defeated,
		'thorn_shrine_awakened': thorn_shrine_awakened,
		'thorn_miniboss_phase': thorn_miniboss.get('phase', ''),
		'thorn_miniboss_hp': thorn_miniboss.get('hp', 0),
		'thorn_safe_lane': thorn_miniboss.get('safe_lane', -1),
		'stone_encounters': stone_encounter_index,
		'stone_route_kills': stone_route_kills,
		'stone_miniboss_defeated': stone_miniboss_defeated,
		'stone_shrine_awakened': stone_shrine_awakened,
		'stone_miniboss_phase': stone_miniboss.get('phase', ''),
		'stone_miniboss_hp': stone_miniboss.get('hp', 0),
		'stone_weak_side': -stone_miniboss.get('dir', 0.0),
		'wind_encounters': wind_encounter_index,
		'wind_route_kills': wind_route_kills,
		'wind_miniboss_defeated': wind_miniboss_defeated,
		'wind_shrine_awakened': wind_shrine_awakened,
		'wind_miniboss_phase': wind_miniboss.get('phase', ''),
		'wind_miniboss_hp': wind_miniboss.get('hp', 0),
		'reprisal_cooldown': reprisal_cooldown,
		'barb_shots': barb_shots.size(),
		'bramble_patches': bramble_patches.size(),
		'active_influence_sites': active_influence_sites.duplicate(),
		'guardian_unlocked': guardian_unlocked,
		'shrine_pulses': shrine_pulses.size(),
	}

func _process(_delta):
	refresh()
	pause_label.visible = paused
	if OS.has_feature('web'):
		JavaScriptBridge.eval('window.__vania_probe = ' + JSON.stringify({
			'ready': true, 'playing': playing, 'choosing': choosing, 'paused': paused,
			'hp': hp, 'numen': numen, 'upgrade': upgrade, 'mixed': (burn_rank() + arc_rank()) > 0 and (chain_rank() + thunder_rank()) > 0,
			'numen_window': progression.window_total(), 'window_counts': progression.window_counts(),
			'next_threshold': progression.next_threshold(), 'window_requirement': progression.window_requirement(),
			'selections': progression.selections, 'pending': progression.pending_level_ups(),
			'dominant': progression.dominant_elements(), 'fully_evolved': progression.is_fully_evolved(),
			'offer_kind': progression.session_offer()['kind'],
			'ranks': progression.ranks.duplicate(),
			'burn_rank': burn_rank(), 'arc_rank': arc_rank(),
			'swipe_reach': Tuning.swipe_reach(arc_rank()), 'burn_duration': Tuning.burn_duration(burn_rank()),
			'chain_reach': Tuning.chain_reach(chain_rank()), 'chain_damage': Tuning.chain_damage(chain_rank()),
			'thunderbeat_reach': Tuning.thunderbeat_reach(thunder_rank()), 'thunderbeat_damage': Tuning.thunderbeat_damage(thunder_rank()),
			'storm_shots': storm_shots.size(), 'storm_encounters': storm_encounter_index,
			'thorn_shots': thorn_shots.size(), 'thorn_encounters': thorn_encounter_index,
			'stone_encounters': stone_encounter_index, 'stone_route_kills': stone_route_kills,
			'wind_encounters': wind_encounter_index, 'wind_route_kills': wind_route_kills,
			'barb_shots': barb_shots.size(), 'bramble_patches': bramble_patches.size(),
			'dash_cooldown': Tuning.slipstream_cooldown(progression.rank_of('slipstream')), 'air_jumps_available': 1 if progression.rank_of('airborne') > 0 and not player.air_jump_used else 0, 'air_acceleration': Tuning.airborne_acceleration(progression.rank_of('airborne')),
			'stonehide_reduction': Tuning.stonehide_reduction(stonehide_rank()), 'reprisal_damage': Tuning.reprisal_damage(reprisal_rank()), 'reprisal_radius': Tuning.reprisal_radius(reprisal_rank()), 'reprisal_cooldown': reprisal_cooldown,
			'wave': wave, 'kills': kills, 'deaths': deaths, 'retries': retries,
			'checkpoint_id': active_checkpoint_id if active_checkpoint_id != '' else CHECKPOINT_ID, 'has_saved_run': not saved_run.is_empty(), 'session_only': session_only,
			'x': player.position.x, 'y': player.position.y, 'vx': player.velocity.x, 'vy': player.velocity.y, 'dash_wait': player.dash_wait,
			'attack': player.attack_id, 'attack_active': player.attack_left > 0,
			'attack_remaining': player.attack_left,
			'enemies': probe_enemies(),
			'section': probe_section(),
			'presentation': 'alternate' if player.visual.alternate_presentation else 'default',
			'actions': {'move': 'left/right', 'jump': 'jump', 'dash': 'dash', 'pause': 'pause', 'retry': 'retry'},
		}))
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing:
		paused = true

func _draw():
	# Camera: offset drawing based on player position for scrolling.
	var cam_x = clampf(player.position.x - 320, 0, 7200 - 640)
	ember_art.environment(self, cam_x, platforms)
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_EMBER_ENTRY_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_EMBER_PREBOSS_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_STORM_ENTRY_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_STORM_PREBOSS_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_THORN_ENTRY_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_THORN_PREBOSS_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_STONE_ENTRY_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_STONE_PREBOSS_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_WIND_ENTRY_POS + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_WIND_PREBOSS_POS + Vector2(-cam_x, 1))
	var shrine_art = 'shrine-awake' if shrine_awakened else ('shrine-ready' if miniboss_defeated else 'shrine-dormant')
	ember_art.stamp(self, shrine_art, SHRINE_POSITION + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'shrine-awake' if storm_shrine_awakened else ('shrine-ready' if storm_miniboss_defeated else 'shrine-dormant'), STORM_SHRINE_POSITION + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'shrine-awake' if thorn_shrine_awakened else ('shrine-ready' if thorn_miniboss_defeated else 'shrine-dormant'), THORN_SHRINE_POSITION + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'shrine-awake' if stone_shrine_awakened else ('shrine-ready' if stone_miniboss_defeated else 'shrine-dormant'), STONE_SHRINE_POSITION + Vector2(-cam_x, 1))
	ember_art.stamp(self, 'shrine-awake' if wind_shrine_awakened else ('shrine-ready' if wind_miniboss_defeated else 'shrine-dormant'), WIND_SHRINE_POSITION + Vector2(-cam_x, 1))
	if wind_shrine_timer > 0 and not wind_shrine_awakened:
		draw_rect(Rect2(WIND_SHRINE_POSITION.x - 20 - cam_x, 248, 40 * wind_shrine_timer / Tuning.SHRINE_AWAKEN_DURATION, 4), Color('#a5e5cf'))
	if stone_shrine_timer > 0 and not stone_shrine_awakened:
		draw_rect(Rect2(STONE_SHRINE_POSITION.x - 20 - cam_x, 248, 40 * stone_shrine_timer / Tuning.SHRINE_AWAKEN_DURATION, 4), Color('#c8cfbd'))
	if thorn_shrine_timer > 0 and not thorn_shrine_awakened:
		draw_rect(Rect2(THORN_SHRINE_POSITION.x - 20 - cam_x, 248, 40 * thorn_shrine_timer / Tuning.SHRINE_AWAKEN_DURATION, 4), Color('#92cf79'))
	if storm_shrine_timer > 0 and not storm_shrine_awakened:
		draw_rect(Rect2(STORM_SHRINE_POSITION.x - 20 - cam_x, 248, 40 * storm_shrine_timer / Tuning.SHRINE_AWAKEN_DURATION, 4), Color('#8bd7f7'))
	# Draw shrine interaction prompt.
	if shrine_interact and not shrine_awakened:
		var progress = shrine_timer / Tuning.SHRINE_AWAKEN_DURATION
		draw_rect(Rect2(SHRINE_POSITION.x - 20 - cam_x, 248, 40, 4), Color('#223544'))
		draw_rect(Rect2(SHRINE_POSITION.x - 20 - cam_x, 248, 40 * progress, 4), Color('#ffe3a0'))
	# Draw enemies.
	for enemy in enemies:
		var x = enemy.x - cam_x
		var w = 19 if enemy.medium else 13
		var h = 28 if enemy.medium else 19
		ember_art.creature(self, 'medium' if enemy.medium else 'easy', Vector2(x, enemy.y if enemy.element == Tuning.SECTION_WIND else 300), enemy.dir, 'lunge' if enemy.element == Tuning.SECTION_STONE and enemy.mode == 'swipe' else enemy.mode, enemy.flash > 0, clock)
		if enemy.element == Tuning.SECTION_STORM:
			draw_circle(Vector2(x, 272 - h), 5, Color('#8bd7f7'))
		elif enemy.element == Tuning.SECTION_THORN:
			draw_circle(Vector2(x, 272 - h), 5, Color('#92cf79'))
		elif enemy.element == Tuning.SECTION_WIND:
			draw_circle(Vector2(x, enemy.y - h), 5, Color('#a5e5cf'))
			if enemy.mode == 'warn':
				draw_line(Vector2(x, enemy.y), Vector2(enemy.target_x - cam_x, Tuning.WIND_ATTACK_HEIGHT), Color('#a5e5cf'), 3)
		elif enemy.element == Tuning.SECTION_STONE:
			draw_circle(Vector2(x, 272 - h), 5, Color('#aeb5bd'))
			if enemy.mode == 'swipe':
				draw_arc(Vector2(x + enemy.dir * 13, 281), 17, -1.2 if enemy.dir > 0 else PI - 1.2, 1.2 if enemy.dir > 0 else PI + 1.2, 10, Color('#e8c382'), 3)
			if enemy.medium:
				if enemy.mode == 'recover':
					draw_line(Vector2(x - 12, 261), Vector2(x + 12, 261), Color('#e8c382'), 3)
				else:
					draw_rect(Rect2(x + enemy.dir * 9 - 3, 270, 6, 20), Color('#b9c4cd'))
		var health_color = Color('#c87f55')
		match enemy.element:
			Tuning.SECTION_STORM: health_color = Color('#8bd7f7')
			Tuning.SECTION_THORN: health_color = Color('#92cf79')
			Tuning.SECTION_STONE: health_color = Color('#aeb5bd')
			Tuning.SECTION_WIND: health_color = Color('#a5e5cf')
		var health_y = enemy.y - h - 12 if enemy.element == Tuning.SECTION_WIND else 265 - h
		draw_line(Vector2(x - w, health_y), Vector2(x - w + 2 * w * enemy.hp / enemy.max_hp, health_y), health_color, 2)
		if enemy.mode == 'warn':
			if enemy.element == Tuning.SECTION_STORM:
				var direction: Vector2 = enemy.aim if enemy.medium else Vector2(enemy.dir, 0)
				draw_line(Vector2(x, Tuning.STORM_SHOT_HEIGHT), Vector2(x, Tuning.STORM_SHOT_HEIGHT) + direction * 115, Color('#8bd7f7'), 2)
			elif enemy.element == Tuning.SECTION_THORN:
				for i in range(Tuning.THORN_FAN_COUNT if enemy.medium else 1):
					var count: int = Tuning.THORN_FAN_COUNT if enemy.medium else 1
					var angle: float = (float(i) - float(count - 1) * 0.5) * Tuning.THORN_FAN_ANGLE
					draw_line(Vector2(x, Tuning.THORN_SHOT_HEIGHT), Vector2(x, Tuning.THORN_SHOT_HEIGHT) + enemy.aim.rotated(angle) * 100, Color('#92cf79'), 2)
			elif enemy.element != Tuning.SECTION_WIND:
				draw_line(Vector2(x, 297), Vector2(x + enemy.dir * (64 if enemy.medium else 40), 297), Color('#ffb859'), 2)
			draw_rect(Rect2(x - 2, enemy.y - h - 9 if enemy.element == Tuning.SECTION_WIND else 268 - h, 4, 7), Color('#a5e5cf') if enemy.element == Tuning.SECTION_WIND else Color('#ffe3a0'))
		if enemy.mode == 'recover':
			draw_circle(Vector2(x, 269 - h), 2, Color('#9bbcaf'))
		if enemy.burn > 0:
			draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 275 - h), Vector2(x, 263 - h), Vector2(x + 4, 275 - h)]), Color('#ff8b35'))
	for shot in storm_shots:
		draw_circle(shot.position - Vector2(cam_x, 0), 5, Color('#8bd7f7'))
	for shot in thorn_shots:
		draw_circle(shot.position - Vector2(cam_x, 0), 5, Color('#92cf79'))
	for shot in barb_shots:
		draw_circle(shot.position - Vector2(cam_x, 0), 5, Color('#d5f39b'))
	for patch in bramble_patches:
		draw_arc(Vector2(patch.x - cam_x, Tuning.BRAMBLE_HEIGHT), Tuning.BRAMBLE_RADIUS, PI, TAU, 12, Color('#709c5a'), 3)
	for cue in secondary_cues:
		if cue.pulse:
			draw_arc(Vector2(cue['from'] - cam_x, 278), cue['to'], PI, TAU, 28, Color('#8bd7f7'), 3)
		else:
			draw_line(Vector2(cue['from'] - cam_x, 270), Vector2(cue['to'] - cam_x, 270), Color('#8bd7f7'), 3)
	# Draw miniboss.
	if not miniboss.is_empty():
		var bx = miniboss['x'] - cam_x
		var bw = 28
		var bh = 40
		ember_art.creature(self, 'miniboss', Vector2(bx,300), miniboss.dir, miniboss.get('phase','idle'), miniboss.flash > 0, clock)
		# Health bar.
		draw_line(Vector2(bx - bw, 255 - bh), Vector2(bx - bw + 2 * bw * miniboss.hp / miniboss.max_hp, 255 - bh), Color('#c87f55'), 3)
		# Phase indicators.
		if miniboss.get('phase', '') == 'warn_slam':
			draw_line(Vector2(bx, 297), Vector2(bx + miniboss.dir * 80, 297), Color('#ff4444'), 3)
			draw_rect(Rect2(bx - 3, 255 - bh, 6, 10), Color('#ff6644'))
		elif miniboss.get('phase', '') == 'fire_tell':
			draw_circle(Vector2(bx, 270 - bh), 4, Color('#ff8833'))
		elif miniboss.get('phase', '') == 'recover':
			draw_circle(Vector2(bx, 265 - bh), 3, Color('#9bbcaf'))
		if miniboss.burn > 0:
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 6, 270 - bh), Vector2(bx, 255 - bh), Vector2(bx + 6, 270 - bh)]), Color('#ff8b35'))
	# Draw fire waves.
	if not storm_miniboss.is_empty():
		var sx = storm_miniboss.x - cam_x
		ember_art.creature(self, 'miniboss', Vector2(sx, 300), -1.0, storm_miniboss.phase, storm_miniboss.flash > 0, clock)
		draw_line(Vector2(sx - 28, 215), Vector2(sx - 28 + 56 * storm_miniboss.hp / storm_miniboss.max_hp, 215), Color('#8bd7f7'), 3)
		if storm_miniboss.phase == 'warn_lightning' or storm_miniboss.phase == 'lightning':
			for lane in range(Tuning.STORM_BOSS_LANE_COUNT):
				if lane == storm_miniboss.safe_lane:
					continue
				var lane_x = Tuning.STORM_BOSS_LEFT + lane * Tuning.STORM_BOSS_LANE_WIDTH - cam_x
				draw_rect(Rect2(lane_x, 290, Tuning.STORM_BOSS_LANE_WIDTH, 10), Color('#8bd7f7') if storm_miniboss.phase == 'lightning' else Color('#527d91'))
				if storm_miniboss.phase == 'lightning':
					draw_line(Vector2(lane_x + Tuning.STORM_BOSS_LANE_WIDTH * 0.5, 220), Vector2(lane_x + Tuning.STORM_BOSS_LANE_WIDTH * 0.5, 290), Color('#b7eeff'), 4)
		elif storm_miniboss.phase == 'recover':
			draw_circle(Vector2(sx, 235), 5, Color('#d5f7ff'))
	if not thorn_miniboss.is_empty():
		var tx = thorn_miniboss.x - cam_x
		ember_art.creature(self, 'miniboss', Vector2(tx, 300), -1.0, thorn_miniboss.phase, thorn_miniboss.flash > 0, clock)
		draw_line(Vector2(tx - 28, 215), Vector2(tx - 28 + 56 * thorn_miniboss.hp / thorn_miniboss.max_hp, 215), Color('#92cf79'), 3)
		if thorn_miniboss.phase == 'warn_roots' or thorn_miniboss.phase == 'brambles':
			for lane in range(Tuning.THORN_BOSS_LANE_COUNT):
				var lane_x = Tuning.THORN_BOSS_LEFT + lane * Tuning.THORN_BOSS_LANE_WIDTH - cam_x
				if lane == thorn_miniboss.safe_lane:
					draw_rect(Rect2(lane_x + 4, 292, Tuning.THORN_BOSS_LANE_WIDTH - 8, 3), Color('#d5f39b'))
					continue
				draw_rect(Rect2(lane_x, 291, Tuning.THORN_BOSS_LANE_WIDTH, 9), Color('#477a48') if thorn_miniboss.phase == 'brambles' else Color('#8faf73'))
				if thorn_miniboss.phase == 'brambles':
					for tip in range(3):
						draw_line(Vector2(lane_x + 10 + tip * 15, 292), Vector2(lane_x + 17 + tip * 15, 254), Color('#b6df91'), 3)
		elif thorn_miniboss.phase == 'recover':
			draw_circle(Vector2(tx, 235), 5, Color('#d5f39b'))
	if not stone_miniboss.is_empty():
		var sx = stone_miniboss.x - cam_x
		ember_art.creature(self, 'miniboss', Vector2(sx, 300), stone_miniboss.dir, stone_miniboss.phase, stone_miniboss.flash > 0, clock)
		draw_circle(Vector2(sx, 223), 7, Color('#aeb5bd'))
		draw_line(Vector2(sx - 28, 215), Vector2(sx - 28 + 56 * stone_miniboss.hp / stone_miniboss.max_hp, 215), Color('#c8cfbd'), 3)
		if stone_miniboss.phase == 'warn_charge':
			draw_line(Vector2(sx, 295), Vector2(sx + stone_miniboss.dir * (Tuning.STONE_BOSS_RIGHT - Tuning.STONE_BOSS_LEFT), 295), Color('#d9b873'), 4)
			draw_rect(Rect2(sx - 13, 250, 26, 7), Color('#d9b873'))
		elif stone_miniboss.phase == 'charge':
			draw_line(Vector2(sx - stone_miniboss.dir * 24, 280), Vector2(sx - stone_miniboss.dir * 55, 280), Color('#d9b873'), 5)
		elif stone_miniboss.phase == 'stuck':
			draw_circle(Vector2(sx - stone_miniboss.dir * 23, 275), 9, Color('#f2d696'))
			draw_line(Vector2(sx - stone_miniboss.dir * 12, 251), Vector2(sx - stone_miniboss.dir * 30, 239), Color('#f2d696'), 3)
	if not wind_miniboss.is_empty():
		var wx = wind_miniboss.x - cam_x
		ember_art.creature(self, 'miniboss', Vector2(wx, wind_miniboss.y), wind_miniboss.dir, wind_miniboss.phase, wind_miniboss.flash > 0, clock)
		draw_line(Vector2(wx - 28, 215), Vector2(wx - 28 + 56 * wind_miniboss.hp / wind_miniboss.max_hp, 215), Color('#a5e5cf'), 3)
		if wind_miniboss.phase == 'warn_swoop':
			draw_line(Vector2(wx, Tuning.WIND_BOSS_SWOOP_HEIGHT), Vector2(wind_miniboss.target_x - cam_x, Tuning.WIND_BOSS_SWOOP_HEIGHT), Color('#a5e5cf'), 3)
		elif wind_miniboss.phase == 'warn_gust':
			draw_line(Vector2(wx, 260), Vector2(wx + wind_miniboss.dir * Tuning.WIND_BOSS_GUST_RANGE, 260), Color('#d6f7eb'), 5)
		elif wind_miniboss.phase == 'gust':
			for band in range(3):
				draw_line(Vector2(wx + wind_miniboss.dir * 20, 265 + band * 12), Vector2(wx + wind_miniboss.dir * Tuning.WIND_BOSS_GUST_RANGE, 265 + band * 12), Color('#a5e5cf'), 2)
	for fw in fire_waves:
		var fx = fw.x - cam_x
		var fy = fw.y
		# Fire wave: three stacked triangles.
		for j in range(3):
			var offset = j * 12
			var alpha = 0.8 if fw.timer > 0.5 else fw.timer * 1.6
			draw_colored_polygon(PackedVector2Array([Vector2(fx - 8, fy + offset), Vector2(fx, fy - 8 + offset), Vector2(fx + 8, fy + offset)]), Color(1.0, 0.5, 0.1, alpha))
	# Draw numen progress bar.
	if progression.window_total() > 0 and not progression.is_fully_evolved():
		var need = maxi(progression.window_requirement(), 1)
		var fill = clampf(float(progression.window_total()) / float(need), 0.0, 1.0)
		draw_rect(Rect2(16, 68, 120, 6), Color('#223544'))
		draw_rect(Rect2(16, 68, 120 * fill, 6), Color('#ffc074'))
	# Draw particles.
	for particle in particles:
		var t = particle.time / Tuning.PARTICLE_LIFETIME
		var at = particle.start.lerp(player.position - Vector2(0, 23), t) + Vector2(0, -sin(t * PI) * 25)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -5), at + Vector2(4, 1), at + Vector2(0, 4), at + Vector2(-4, 1)]), Color('#ffc074'))
	# Draw sanctuary and guardian checkpoints.
	ember_art.stamp(self, 'checkpoint', CHECKPOINT_SANCTUARY_POS + Vector2(-cam_x, 1))
	if guardian_unlocked:
		ember_art.stamp(self, 'checkpoint', CHECKPOINT_GUARDIAN_POS + Vector2(-cam_x, 1))
	# Draw active influence sites.
	for site_id in active_influence_sites:
		var site: Dictionary = {}
		for s in Tuning.INFLUENCE_SITES:
			if s['id'] == site_id:
				site = s
				break
		if site.is_empty():
			continue
		var sx: float = site['x'] - cam_x
		var sy: float = 275.0
		match site['effect']:
			'vent':
				var active_timer: float = influence_timers.get(site_id, 0.0)
				var active: bool = active_timer < float(site['active_time'])
				var color: Color = Color('#ff6633') if active else Color('#553322')
				draw_circle(Vector2(sx, sy), 8.0, color)
				if active:
					draw_arc(Vector2(sx, sy), float(site['radius']) * 0.3, PI, TAU, 12, Color('#ff8844', 0.5), 2)
			'burst':
				var color: Color = Color('#8bd7f7') if not influence_timers.has(str(site_id) + '_fired') or influence_timers[str(site_id) + '_fired'] <= 0 else Color('#557d91')
				draw_circle(Vector2(sx, sy), 10.0, color)
				draw_arc(Vector2(sx, sy), 14.0, PI, TAU, 8, Color('#b7eeff'), 2)
			'bounce':
				draw_circle(Vector2(sx, sy + 10), 6.0, Color('#92cf79'))
				draw_line(Vector2(sx, sy + 10), Vector2(sx, sy - 20), Color('#b6df91'), 3)
			'cover':
				var cw: float = float(site['width'])
				var ch: float = float(site['height'])
				draw_rect(Rect2(sx - cw * 0.5, sy - ch, cw, ch), Color('#aeb5bd'))
				draw_rect(Rect2(sx - cw * 0.5, sy - ch, cw, ch), Color('#c8cfbd'), false, 2.0)
			'updraft':
				var col := Color('#a5e5cf', 0.4)
				var uh: float = float(site['height'])
				var uw: float = float(site['width'])
				for i in range(3):
					var offset_y: float = fmod(float(i) * 25.0 + clock * 60.0, uh)
					draw_line(Vector2(sx, sy - offset_y), Vector2(sx, sy - offset_y - 15), col, 2)
				draw_rect(Rect2(sx - uw * 0.5, sy - uh, uw, uh), Color('#a5e5cf', 0.15))
	# Draw shrine pulse effects.
	for pulse in shrine_pulses:
		var progress: float = 1.0 - pulse.timer / Tuning.SHRINE_PULSE_DURATION
		var pulse_radius: float = Tuning.SHRINE_PULSE_RADIUS * progress
		var alpha: float = 1.0 - progress
		var color: Color
		match pulse['section']:
			Tuning.SECTION_EMBER: color = Color('#ff6633', alpha * 0.3)
			Tuning.SECTION_STORM: color = Color('#8bd7f7', alpha * 0.3)
			Tuning.SECTION_THORN: color = Color('#92cf79', alpha * 0.3)
			Tuning.SECTION_STONE: color = Color('#c8cfbd', alpha * 0.3)
			Tuning.SECTION_WIND: color = Color('#a5e5cf', alpha * 0.3)
			_: color = Color('#ffffff', alpha * 0.3)
		var center_x: float = Tuning.SANCTUARY_LEFT + (Tuning.SANCTUARY_RIGHT - Tuning.SANCTUARY_LEFT) * 0.5 - cam_x
		draw_arc(Vector2(center_x, 300), pulse_radius, PI, TAU, 48, color, 3)
	# Draw guardian indicator when unlocked.
	if guardian_unlocked:
		var gx: float = (Tuning.GUARDIAN_LEFT + Tuning.GUARDIAN_RIGHT) * 0.5 - cam_x
		var gy: float = Tuning.GUARDIAN_GROUND_Y
		draw_arc(Vector2(gx, gy), 20.0 + sin(clock * 3.0) * 3.0, PI, TAU, 16, Color('#ff4444', 0.6), 2)
