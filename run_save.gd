extends RefCounted
## Production run-save boundary (issue #21).
##
## This is deliberately not Progression.to_state(): progression's small state
## helper is useful to rule fixtures, while this envelope is the durable game
## contract. Future world slices extend stable IDs below rather than replacing
## this save with a second format.
const VERSION := 1
const SAVE_PATH := 'user://numen-run-v1.json'
const EMPTY_WORLD := {'objectives': {}, 'modifier_assignments': {}}


class FileStorage:
	extends RefCounted
	var force_unavailable := false

	func _init() -> void:
		# A narrow browser-smoke seam: it exercises the same failure path as a
		# blocked store without claiming to emulate every privacy policy.
		if OS.has_feature('web'):
			force_unavailable = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('numen_storage') === 'unavailable'")

	func read_text(path: String) -> Dictionary:
		if force_unavailable:
			return {'found': false, 'unavailable': true}
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return {'found': false, 'unavailable': FileAccess.get_open_error() != ERR_FILE_NOT_FOUND}
		return {'found': true, 'text': file.get_as_text()}

	func write_text(path: String, text: String) -> bool:
		if force_unavailable:
			return false
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return false
		file.store_string(text)
		return file.get_error() == OK

	func erase(path: String) -> bool:
		if force_unavailable:
			return false
		return not FileAccess.file_exists(path) or DirAccess.remove_absolute(path) == OK


var storage
var last_error := ''


func _init(storage_override = null) -> void:
	storage = storage_override if storage_override != null else FileStorage.new()


func make_run(checkpoint_id: String, progression, world_state: Dictionary = {}) -> Dictionary:
	var world := EMPTY_WORLD.duplicate(true)
	for key in world_state:
		world[key] = world_state[key]
	return {
		'version': VERSION,
		'checkpoint_id': checkpoint_id,
		'progression': {
			'typed_earning_window': progression.window_queue.duplicate(),
			'total_numen': progression.lifetime,
			'total_selections': progression.selections,
			'path_ranks': progression.ranks.duplicate(),
			'pending_element': progression.pending_element,
		},
		# Stable extension points. Values are keyed by authored IDs, not scene
		# positions or transient combat objects.
		'world': world,
	}


func save_run(run: Dictionary) -> bool:
	last_error = ''
	if not storage.write_text(SAVE_PATH, JSON.stringify(run)):
		last_error = 'Persistent storage is unavailable. This run lasts only for this browser session.'
		return false
	return true


func load_run() -> Dictionary:
	last_error = ''
	var result: Dictionary = storage.read_text(SAVE_PATH)
	if not result.get('found', false):
		if result.get('unavailable', false):
			last_error = 'Persistent storage is unavailable. This run lasts only for this browser session.'
		return {}
	var parsed = JSON.parse_string(String(result.get('text', '')))
	if not is_valid_run(parsed):
		last_error = 'Saved run could not be read. Start a new run.'
		return {}
	return parsed


func clear_run() -> bool:
	last_error = ''
	if not storage.erase(SAVE_PATH):
		last_error = 'Persistent storage is unavailable. This run lasts only for this browser session.'
		return false
	return true


func is_valid_run(value) -> bool:
	if not value is Dictionary or int(value.get('version', -1)) != VERSION:
		return false
	if String(value.get('checkpoint_id', '')) == '':
		return false
	var progress = value.get('progression', {})
	return progress is Dictionary and progress.get('typed_earning_window', null) is Array and progress.get('path_ranks', null) is Dictionary


func restore_progression(progression, run: Dictionary) -> void:
	var state: Dictionary = run['progression']
	# Translate the production contract explicitly instead of coupling file
	# contents to the progression fixture format.
	progression.from_state({
		'window_queue': state['typed_earning_window'],
		'ranks': state['path_ranks'],
		'lifetime': state.get('total_numen', 0),
		'selections': state.get('total_selections', 0),
		'pending_element': state.get('pending_element', ''),
	})
