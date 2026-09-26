extends RefCounted
# Presentation only. No actor dictionaries, damage, collision, rewards or timers
# are owned here. State/elapsed time come from the game; poses cannot advance it.
var look: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://assets/storm-kit.json'))
var motions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://assets/storm-motions.json'))
var textures: Dictionary = {}
var remnants: Array = []

func texture(asset: String) -> Texture2D:
	if not textures.has(asset):
		var image = Image.new()
		var error = image.load_svg_from_string(FileAccess.get_file_as_string('res://assets/storm/' + asset + '.svg'))
		if error != OK:
			push_error('Cannot rasterize Storm asset: ' + asset)
			return null
		textures[asset] = ImageTexture.create_from_image(image)
	return textures[asset]

func stamp(canvas: CanvasItem, asset: String, feet: Vector2):
	var tex = texture(asset)
	if tex != null:
		canvas.draw_texture(tex, feet - Vector2(tex.get_width() / 2.0, tex.get_height()))

func environment(canvas: CanvasItem, camera: float, platforms: Array, shared):
	# Reuse the sanctuary arches, landing edges, joints and crack construction.
	# Only this section's surface interval receives the cool Storm palette.
	for x in look.environment.arches:
		shared.stamp(canvas, 'arch', Vector2(x - camera, 300), Color('#8299ad'))
	for x in look.environment.towers:
		stamp(canvas, 'tower', Vector2(x - camera, 300))
	for decoration in look.environment.decorations:
		stamp(canvas, decoration.asset, Vector2(decoration.x - camera, decoration.y))
	for platform in platforms:
		var left = maxf(platform.position.x, look.environment.left)
		var right = minf(platform.end.x, look.environment.right)
		if right > left:
			shared.masonry(canvas, Rect2(left - camera, platform.position.y, right - left, platform.size.y), look.palette)

func pose_at(state: String, seconds: float) -> Dictionary:
	var motion: Dictionary = motions.states.get(state, motions.states.idle)
	var frame = maxi(0, int(seconds * float(motion.fps)))
	frame = frame % motion.frames.size() if motion.loop else mini(frame, motion.frames.size() - 1)
	return motions.poses[motion.frames[frame]]

func creature(canvas: CanvasItem, kind: String, feet: Vector2, facing: float, state: String, flash: bool, seconds: float, modifier := ''):
	var creature_look: Dictionary = look.creatures[kind]
	var pose = pose_at(state, seconds)
	var alpha = float(pose.alpha)
	if alpha <= 0:
		return
	var tint = Color('#fff1dc') if flash else Color.WHITE
	tint.a = alpha
	var pivot = Vector2(look.pivot[0], look.pivot[1])
	canvas.draw_set_transform(feet.round(), 0, Vector2(facing, float(pose.scale_y)))
	var leg_color = Color(look.palette.leg, alpha)
	for i in range(creature_look.feet.size()):
		var x = float(creature_look.feet[i])
		var step = float(pose.stride) * (1 if i == 0 else -1)
		canvas.draw_line(Vector2(x, -8), Vector2(x + step, -3), leg_color, 2)
		canvas.draw_rect(Rect2(x + step - 2, -3, 5, 3), leg_color)
	var body = texture(creature_look.body)
	var antenna = texture(creature_look.antenna)
	if body != null:
		canvas.draw_texture(body, -pivot + Vector2(pose.body[0], pose.body[1]), tint)
	if antenna != null:
		canvas.draw_texture(antenna, -pivot + Vector2(pose.antenna[0], pose.antenna[1]), tint)
	# Charge is confined to the antenna socket. Ground lanes and aim lines remain
	# the authoritative tells, drawn by main.gd above this composite.
	if pose.charge > 0:
		var tip = Vector2(creature_look.charge[0] + pose.antenna[0], creature_look.charge[1] + pose.antenna[1])
		var radius = float(pose.charge)
		canvas.draw_rect(Rect2(tip - Vector2(radius, 1), Vector2(radius * 2 + 1, 2)), Color(look.palette.charge, alpha))
		canvas.draw_rect(Rect2(tip - Vector2(1, radius), Vector2(2, radius * 2 + 1)), Color(look.palette.charge, alpha))
	if look.modifiers.has(modifier):
		var attachment: Dictionary = look.modifiers[modifier]
		var points = PackedVector2Array()
		for point in attachment.points:
			points.append(Vector2(point[0], point[1]))
		canvas.draw_colored_polygon(points, Color(attachment.color, alpha))
	canvas.draw_set_transform(Vector2.ZERO)

func defeat(kind: String, feet: Vector2, facing: float, seconds: float):
	# Snapshot values only; the actor is removed/rewarded immediately as before.
	remnants.append({'kind': kind, 'feet': feet, 'facing': facing, 'started': seconds})
	if remnants.size() > 32:
		remnants.pop_front()

func draw_remnants(canvas: CanvasItem, camera: float, seconds: float):
	var motion: Dictionary = motions.states.defeat
	var duration = motion.frames.size() / maxf(float(motion.fps), 0.001)
	remnants = remnants.filter(func(remnant): return seconds - remnant.started < duration)
	for remnant in remnants:
		creature(canvas, remnant.kind, remnant.feet - Vector2(camera, 0), remnant.facing, 'defeat', false, seconds - remnant.started)

func clear():
	remnants.clear()
