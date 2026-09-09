extends Node2D

const SAVE_PATH = "user://browser-feasibility-v1.json"
var state = {}
var player
var status_label
var menu
var persistent = true
var playing = false
var save_present = false
var save_ok = false
var time = 0.0
var telemetry_clock = 0.0
var frame_samples = []
var audio_player

func fresh_state():
	return {"version": 1, "souls": 0, "upgrades": [], "shrines": [], "modifiers": {"enemy-1": "Wind"}, "checkpoint": [80, 270]}

func _ready():
	for action in ["left", "right", "jump", "dash"]:
		InputMap.add_action(action)
	for entry in [["left", KEY_A], ["left", KEY_LEFT], ["right", KEY_D], ["right", KEY_RIGHT], ["jump", KEY_SPACE], ["dash", KEY_SHIFT]]:
		var event = InputEventKey.new()
		event.physical_keycode = entry[1]
		InputMap.action_add_event(entry[0], event)
	for entry in [["jump", JOY_BUTTON_A], ["dash", JOY_BUTTON_X]]:
		var event = InputEventJoypadButton.new()
		event.button_index = entry[1]
		InputMap.action_add_event(entry[0], event)
	for entry in [["left", -1.0], ["right", 1.0]]:
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_X
		event.axis_value = entry[1]
		InputMap.action_add_event(entry[0], event)
	if OS.has_feature("web"):
		persistent = OS.is_userfs_persistent()
		if JavaScriptBridge.eval("new URLSearchParams(location.search).get('storage') === 'off'"):
			persistent = false
	state = fresh_state()
	save_present = persistent and FileAccess.file_exists(SAVE_PATH)
	for rect in [Rect2(0, 300, 640, 60), Rect2(155, 258, 95, 12), Rect2(300, 214, 95, 12), Rect2(470, 260, 85, 12)]:
		var body = StaticBody2D.new()
		body.position = rect.position + rect.size / 2
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	player = CharacterBody2D.new()
	player.set_script(load("res://spirit.gd"))
	player.position = Vector2(80, 270)
	add_child(player)
	var ui = CanvasLayer.new()
	add_child(ui)
	var heading = Label.new()
	heading.text = "SPIRIT / BROWSER FEASIBILITY — THROWAWAY"
	heading.position = Vector2(16, 10)
	heading.add_theme_font_size_override("font_size", 14)
	ui.add_child(heading)
	status_label = Label.new()
	status_label.position = Vector2(16, 34)
	status_label.add_theme_font_size_override("font_size", 11)
	ui.add_child(status_label)
	var instructions = Label.new()
	instructions.text = "A/D or arrows: move · Space: jump · Shift: dash\nU: upgrade + souls · H: shrine · R: checkpoint · K: respawn"
	instructions.position = Vector2(16, 316)
	instructions.add_theme_font_size_override("font_size", 11)
	ui.add_child(instructions)
	menu = HBoxContainer.new()
	menu.position = Vector2(16, 96)
	ui.add_child(menu)
	for entry in [["New game / N", "new"], ["Continue / C", "continue"]]:
		var button = Button.new()
		button.text = entry[0]
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(command.bind(entry[1]))
		menu.add_child(button)
	_make_audio()
	refresh()

func _make_audio():
	# Offline PCM sample, not unsupported live audio generation in the web audio backend.
	var samples = PackedByteArray()
	for i in range(4410):
		var value = int(sin(float(i) / 44100.0 * TAU * 440) * 6000 * (1.0 - float(i) / 4410.0))
		samples.append(value & 255)
		samples.append((value >> 8) & 255)
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 44100
	sound.data = samples
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = sound
	add_child(audio_player)

func _unhandled_key_input(event):
	if not event.pressed or event.echo:
		return
	var commands = {KEY_N: "new", KEY_C: "continue", KEY_U: "upgrade", KEY_H: "shrine", KEY_R: "checkpoint", KEY_K: "die"}
	if commands.has(event.physical_keycode):
		command(commands[event.physical_keycode])

func command(action):
	if action == "new":
		state = fresh_state()
		playing = true
		respawn()
	elif action == "continue":
		if persistent and FileAccess.file_exists(SAVE_PATH):
			var loaded = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
			if loaded is Dictionary and loaded.get("version") == 1:
				state = loaded
		playing = true
		respawn()
	elif not playing:
		return
	elif action == "upgrade":
		state.souls += 3
		state.upgrades.append("Ember")
	elif action == "shrine":
		if not state.shrines.has("Ember"):
			state.shrines.append("Ember")
	elif action == "checkpoint":
		state.checkpoint = [int(player.position.x), int(player.position.y)]
	elif action == "die":
		respawn()
	player.playing = playing
	player.upgraded = state.upgrades.size() > 0
	menu.visible = not playing
	audio_player.play()
	save_game()
	refresh()

func respawn():
	player.position = Vector2(state.checkpoint[0], state.checkpoint[1])
	player.velocity = Vector2.ZERO

func save_game():
	if not persistent:
		save_ok = false
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state))
		file.close()
		save_ok = true
		save_present = true
	else:
		persistent = false
		save_ok = false

func refresh():
	status_label.text = "Godot %s · Compatibility / single-thread web\n%s · Souls %s · Upgrades %s · Shrines %s · Enemy modifier: Wind\nSave available: %s · Fixture actions test storage, not the progression rules." % [Engine.get_version_info().string, "Browser save" if persistent else "Session only — progress will not survive closing", state.souls, state.upgrades.size(), state.shrines.size(), save_present]

func _process(delta):
	time += delta
	telemetry_clock += delta
	if playing and frame_samples.size() < 3600:
		frame_samples.append(delta * 1000)
	if telemetry_clock > 0.2 and OS.has_feature("web"):
		telemetry_clock = 0
		var report = {"ready": true, "engine": Engine.get_version_info().string, "playing": playing, "persistent": persistent, "save_ok": save_ok, "state": state, "x": player.position.x, "y": player.position.y, "upgraded": player.upgraded, "frames": frame_samples.size(), "fps": Engine.get_frames_per_second(), "audio_playing": audio_player.playing, "gamepads": Input.get_connected_joypads()}
		JavaScriptBridge.eval("window.__vania_probe = " + JSON.stringify(report))
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(player):
		player.playing = false
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_instance_valid(player):
		player.playing = playing

func _draw():
	for i in range(14):
		var x = i * 52
		draw_rect(Rect2(x, 145 + (i % 3) * 15, 25, 180), Color("172737"))
	for rect in [Rect2(0, 300, 640, 60), Rect2(155, 258, 95, 12), Rect2(300, 214, 95, 12), Rect2(470, 260, 85, 12)]:
		draw_rect(rect, Color("35463c"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("8caa66"))
	for i in range(10):
		var x = 32 + i * 60
		draw_rect(Rect2(x, 289, 2, 11), Color("5d8174"))
		draw_rect(Rect2(x - 2, 285, 6, 5), Color("92dfcf"))
	# A dummy enemy with a persistent Wind marker, not enemy AI.
	draw_rect(Rect2(570, 281, 16, 19), Color("77868b"))
	draw_rect(Rect2(568, 276, 20, 2), Color("a0eeee"))
	if state.get("shrines", []).size() > 0:
		draw_rect(Rect2(410, 272, 10, 28), Color("f7a259"))
