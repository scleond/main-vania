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
const CHECKPOINT_POSITION = Vector2(70, 299)
const CHECKPOINT_ID := 'ember_trial_entry'
const PATH_IDS := ['searing_claws', 'flame_arc']
const LEGACY_NAMES := {'searing_claws': 'burn', 'flame_arc': 'arc'}
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
var wave_wait = 0.0
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
var platforms = [Rect2(0, 300, 640, 60), Rect2(165, 240, 95, 10), Rect2(375, 217, 105, 10)]

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
	label_at('EMBER TRIAL / combat room', Vector2(16, 8), 18)
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
	label_at('Searing Claws adds fiery fingers; Flame Arc reveals a furnace core.', Vector2(18, 118), 11, choice)
	label_at('Strongest affinity colors the head spikes. Both repeat to rank 8.', Vector2(18, 139), 11, choice)
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
	respawn(false)
	sync_derived()
	note('Continued from checkpoint. Numen and upgrades restored.')

func persist_run():
	if not playing:
		return
	var run = run_store.make_run(CHECKPOINT_ID, progression)
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
	player.position = CHECKPOINT_POSITION
	player.velocity = Vector2.ZERO
	player.invulnerable = Tuning.INVULNERABLE_DURATION
	player.attack_left = 0
	player.dash_left = 0
	player.dash_wait = 0
	player.attack_wait = 0
	particles.clear()
	enemies.clear()
	wave = 0
	wave_wait = Tuning.WAVE_WAIT_INITIAL
	note('Checkpoint restored. Numen and upgrades retained.' if count else 'Defeat the Ember creatures. Earn Numen toward evolution.')
	if playing:
		persist_run()

func note(value):
	message = value
	message_left = 4.0

func can_retry_nearby():
	return player.position.distance_to(CHECKPOINT_POSITION) <= Tuning.CHECKPOINT_RETRY_DISTANCE

func burn_rank():
	return progression.rank_of('searing_claws')

func arc_rank():
	return progression.rank_of('flame_arc')

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
	# Routes the two visible choice buttons: tied-element picks when the offer
	# asks for an element, path picks otherwise. Single-element Ember play
	# always lands on the path branch; ties are exercised by rule fixtures.
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
		wave_wait = Tuning.WAVE_WAIT_AFTER_CHOICE
	persist_run()

func spawn_wave():
	wave += 1
	if wave % 4 == 0:
		add_enemy(475, true)
	else:
		add_enemy(330, false)
		add_enemy(555, false)

func add_enemy(x, medium):
	enemies.append({
		'x': float(x),
		'hp': Tuning.MEDIUM_HP if medium else Tuning.EASY_HP,
		'max_hp': Tuning.MEDIUM_HP if medium else Tuning.EASY_HP,
		'medium': medium, 'mode': 'approach', 'timer': 0.0, 'dir': -1.0,
		'hit_id': -1, 'burn': 0.0, 'burn_tick': 0.0, 'flash': 0.0,
	})

func _physics_process(delta):
	process_session_actions()
	sync_derived()
	player.active = playing and not choosing and not paused
	player.upgrade = upgrade
	player.arc_rank = arc_rank()
	player.burn_rank = burn_rank()
	if is_instance_valid(player.visual):
		player.visual.path_ranks = {'searing_claws': burn_rank(), 'flame_arc': arc_rank()}
		player.visual.fully_evolved = progression.is_fully_evolved()
		player.visual.playback_paused = not player.active
	if not player.active:
		return
	clock += delta
	message_left = maxf(0, message_left - delta)
	choice_delay = maxf(0, choice_delay - delta)
	if progression.pending_level_ups() > 0 and choice_delay <= 0:
		choosing = true
		player.active = false
		refresh_choice_panel()
		choice.show()
		return
	if enemies.is_empty():
		wave_wait -= delta
		if wave_wait <= 0:
			spawn_wave()
	for enemy in enemies:
		enemy.flash = maxf(0, enemy.flash - delta)
		var difference = player.position.x - enemy.x
		enemy.timer -= delta
		if enemy.mode == 'approach':
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
		enemy.x = clampf(enemy.x, Tuning.ENEMY_MIN_X, Tuning.ENEMY_MAX_X)
		var reach = Tuning.swipe_reach(arc_rank())
		var relative = enemy.x - player.position.x
		if Tuning.swipe_is_active(player.attack_left) and enemy.hit_id != player.attack_id and relative * player.facing > Tuning.SWIPE_BACK_ALLOW and absf(relative) < reach + Tuning.SWIPE_HITBOX_PAD and absf(player.position.y - 300) < Tuning.SWIPE_HIT_HEIGHT:
			enemy.hit_id = player.attack_id
			enemy.hp -= Tuning.SWIPE_DAMAGE
			enemy.flash = Tuning.ENEMY_HIT_FLASH
			enemy.x += player.facing * Tuning.SWIPE_KNOCKBACK
			if burn_rank() > 0:
				enemy.burn = Tuning.burn_duration(burn_rank())
		if enemy.burn > 0:
			enemy.burn -= delta
			enemy.burn_tick += delta
			if enemy.burn_tick >= Tuning.BURN_TICK_INTERVAL:
				enemy.burn_tick = 0
				enemy.hp -= Tuning.BURN_TICK_DAMAGE
				enemy.flash = 0.1
		if enemy.hp > 0 and enemy.mode == 'lunge' and absf(enemy.x - player.position.x) < Tuning.ENEMY_CONTACT_RANGE and player.position.y > 266 and player.invulnerable <= 0 and player.dash_left <= 0:
			hp -= Tuning.MEDIUM_DAMAGE if enemy.medium else Tuning.EASY_DAMAGE
			player.invulnerable = Tuning.INVULNERABLE_DURATION
			player.velocity.y = Tuning.HIT_LAUNCH_Y
			if hp > 0 and is_instance_valid(player.visual):
				player.visual.play_hurt()
			note('Hit! Watch the warning, then punish the recovery.')
	var living = []
	for enemy in enemies:
		if enemy.hp <= 0:
			var reward = Tuning.MEDIUM_NUMEN if enemy.medium else Tuning.EASY_NUMEN
			progression.earn('ember', reward)
			kills += 1
			choice_delay = Tuning.CHOICE_DELAY
			# Graphical quantities: one particle per numen earned.
			for i in range(reward):
				particles.append({'start': Vector2(enemy.x + i * 12, 277 - i * 8), 'time': 0.0})
			wave_wait = Tuning.WAVE_WAIT_AFTER_KILL
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

func path_label(path_id, slot):
	var info = Progression.PATH_CATALOG[path_id]
	var rank = progression.rank_of(path_id)
	var key = '1' if slot == 0 else '2'
	if path_id == 'searing_claws':
		return '%s · %s  rank %d → %d\nSwipes ignite (burn %.1fs, tick %.1fs)' % [key, info['name'], rank, rank + 1, Tuning.burn_duration(rank + 1), Tuning.BURN_TICK_INTERVAL]
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
		var element_name = String(current.get('element', 'ember')).capitalize()
		var selected = progression.selections
		choice_title.text = 'EVOLVE / %s family  (%d/%d)' % [element_name, selected + 1, Progression.SELECTION_CAP]
		choice_detail.text = 'Choose one permanent %s upgrade with Numen (repeatable to rank 8). Play is paused.' % element_name.capitalize()
		for i in range(slot_buttons.size()):
			slot_buttons[i].text = path_label(PATH_IDS[i], i) if i < PATH_IDS.size() else '—'

func refresh():
	var requirement = progression.window_requirement()
	var leaders = progression.dominant_elements()
	var leader_text = 'none' if leaders.is_empty() else '/'.join(leaders)
	if progression.is_fully_evolved():
		hud.text = 'Health %.1f / %d   |   Fully evolved / Ember aura %d/%d   |   Claws r%d · Arc r%d' % [hp, int(Tuning.PLAYER_MAX_HP), progression.selections, Progression.SELECTION_CAP, burn_rank(), arc_rank()]
	elif requirement > 0:
		hud.text = 'Health %.1f / %d   |   Numen %d / %d   |   Claws r%d · Arc r%d (%d/%d)' % [hp, int(Tuning.PLAYER_MAX_HP), numen, requirement, burn_rank(), arc_rank(), progression.selections, Progression.SELECTION_CAP]
	else:
		hud.text = 'Health %.1f / %d   |   Claws r%d · Arc r%d (%d/%d)' % [hp, int(Tuning.PLAYER_MAX_HP), burn_rank(), arc_rank(), progression.selections, Progression.SELECTION_CAP]
	if session_only:
		hud.text += '   |   Session-only (storage unavailable)'
	if choosing:
		refresh_choice_panel()
		status.text = message if message_left > 0 else ('Wave %d  |  Leading %s  |  Next %d Numen' % [wave, leader_text, requirement] if not progression.is_fully_evolved() else 'Wave %d  |  Fully evolved — Ember aura active; Numen no longer accumulates' % wave)

func probe_enemies():
	var out = []
	for enemy in enemies:
		out.append({'x': enemy.x, 'medium': enemy.medium, 'mode': enemy.mode, 'hp': enemy.hp})
	return out

func _process(_delta):
	refresh()
	pause_label.visible = paused
	if OS.has_feature('web'):
		JavaScriptBridge.eval('window.__vania_probe = ' + JSON.stringify({
			'ready': true, 'playing': playing, 'choosing': choosing, 'paused': paused,
			'hp': hp, 'numen': numen, 'upgrade': upgrade, 'mixed': false,
			'numen_window': progression.window_total(), 'window_counts': progression.window_counts(),
			'next_threshold': progression.next_threshold(), 'window_requirement': progression.window_requirement(),
			'selections': progression.selections, 'pending': progression.pending_level_ups(),
			'dominant': progression.dominant_elements(), 'fully_evolved': progression.is_fully_evolved(),
			'offer_kind': progression.session_offer()['kind'],
			'ranks': {'searing_claws': burn_rank(), 'flame_arc': arc_rank()},
			'burn_rank': burn_rank(), 'arc_rank': arc_rank(),
			'swipe_reach': Tuning.swipe_reach(arc_rank()), 'burn_duration': Tuning.burn_duration(burn_rank()),
			'wave': wave, 'kills': kills, 'deaths': deaths, 'retries': retries,
			'checkpoint_id': CHECKPOINT_ID, 'has_saved_run': not saved_run.is_empty(), 'session_only': session_only,
			'x': player.position.x, 'y': player.position.y,
			'attack': player.attack_id, 'attack_active': player.attack_left > 0,
			'attack_remaining': player.attack_left,
			'enemies': probe_enemies(),
			'presentation': 'alternate' if player.visual.alternate_presentation else 'default',
			'actions': {'move': 'left/right', 'jump': 'jump', 'dash': 'dash', 'pause': 'pause', 'retry': 'retry'},
		}))
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing:
		paused = true

func _draw():
	for i in range(8):
		draw_rect(Rect2(i * 90 + 15, 125 + (i % 3) * 12, 32, 175), Color('#172637'))
		draw_rect(Rect2(i * 90 + 24, 156, 8, 28), Color('#46352c'))
	for rect in platforms:
		draw_rect(rect, Color('#354340'))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color('#8a9c73'))
	draw_rect(Rect2(CHECKPOINT_POSITION.x - 8, 273, 16, 27), Color('#537f83'))
	draw_circle(CHECKPOINT_POSITION + Vector2(0, -30), 5, Color('#a6f4d7'))
	for enemy in enemies:
		var x = enemy.x
		var w = 19 if enemy.medium else 13
		var h = 28 if enemy.medium else 19
		var color = Color('#f3dec1') if enemy.flash > 0 else (Color('#ab553b') if enemy.medium else Color('#cf7049'))
		draw_rect(Rect2(x - w, 300 - h, w * 2, h), color)
		for i in range(3):
			draw_colored_polygon(PackedVector2Array([Vector2(x - w + i * w * 0.7, 300 - h), Vector2(x - w + 3 + i * w * 0.7, 289 - h), Vector2(x - w + 7 + i * w * 0.7, 300 - h)]), Color('#f9ad5a'))
		draw_rect(Rect2(x + enemy.dir * 7 - 2, 285, 4, 4), Color('#fff0bc'))
		draw_line(Vector2(x - w, 265 - h), Vector2(x - w + 2 * w * enemy.hp / enemy.max_hp, 265 - h), Color('#c87f55'), 2)
		if enemy.mode == 'warn':
			draw_line(Vector2(x, 297), Vector2(x + enemy.dir * (64 if enemy.medium else 40), 297), Color('#ffb859'), 2)
			draw_rect(Rect2(x - 2, 268 - h, 4, 7), Color('#ffe3a0'))
		if enemy.mode == 'recover':
			draw_circle(Vector2(x, 269 - h), 2, Color('#9bbcaf'))
		if enemy.burn > 0:
			draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 275 - h), Vector2(x, 263 - h), Vector2(x + 4, 275 - h)]), Color('#ff8b35'))
	if progression.window_total() > 0 and not progression.is_fully_evolved():
		var need = maxi(progression.window_requirement(), 1)
		var fill = clampf(float(progression.window_total()) / float(need), 0.0, 1.0)
		draw_rect(Rect2(16, 68, 120, 6), Color('#223544'))
		draw_rect(Rect2(16, 68, 120 * fill, 6), Color('#ffc074'))
	for particle in particles:
		var t = particle.time / Tuning.PARTICLE_LIFETIME
		var at = particle.start.lerp(player.position - Vector2(0, 23), t) + Vector2(0, -sin(t * PI) * 25)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -5), at + Vector2(4, 1), at + Vector2(0, 4), at + Vector2(-4, 1)]), Color('#ffc074'))
