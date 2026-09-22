extends SceneTree
# Deterministic transparent RGBA exports at SVG native resolution.
# godot --headless --path . --script art/ember/export.gd
func _initialize():
	for filename in DirAccess.get_files_at('res://assets/ember'):
		if not filename.ends_with('.svg'): continue
		var image = Image.new()
		var error = image.load_svg_from_string(FileAccess.get_file_as_string('res://assets/ember/'+filename))
		if error != OK:
			push_error('Cannot rasterize '+filename)
			quit(1)
			return
		image.convert(Image.FORMAT_RGBA8)
		if image.save_png('res://assets/ember/'+filename.get_basename()+'.png') != OK:
			quit(1)
			return
	quit()
