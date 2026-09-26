extends RefCounted
# Presentation only: receives positions/states by value, never an actor dictionary.
# SVG look and JSON flicker sequences are independent of authoritative timers.
var look = JSON.parse_string(FileAccess.get_file_as_string('res://assets/ember-kit.json'))
var motions = JSON.parse_string(FileAccess.get_file_as_string('res://assets/ember-motions.json'))
var textures: Dictionary = {}

func texture(name: String) -> Texture2D:
	if not textures.has(name):
		var source = Image.new()
		source.load_svg_from_string(FileAccess.get_file_as_string('res://assets/ember/'+name+'.svg'))
		textures[name] = ImageTexture.create_from_image(source)
	return textures[name]

func stamp(canvas: CanvasItem, name: String, feet: Vector2, tint := Color.WHITE):
	var tex = texture(name)
	canvas.draw_texture(tex, feet - Vector2(tex.get_width()/2.0, tex.get_height()), tint)

func environment(canvas: CanvasItem, camera: float, platforms: Array):
	for x in range(0, 2400, int(look.environment.arch_spacing)):
		stamp(canvas, 'arch', Vector2(x+64-camera, 300))
	for x in look.environment.furnaces:
		stamp(canvas, 'furnace', Vector2(x-camera, 300))
		stamp(canvas, 'charcoal', Vector2(x+36-camera, 300))
	for decoration in look.environment.decorations:
		stamp(canvas, decoration.asset, Vector2(decoration.x-camera, decoration.y))
	for platform in platforms:
		var rect = Rect2(platform.position-Vector2(camera,0), platform.size)
		masonry(canvas, rect, look.palette)

# Shared sanctuary construction; section treatments supply only a palette.
func masonry(canvas: CanvasItem, rect: Rect2, palette: Dictionary):
	canvas.draw_rect(rect, Color(palette.stone))
	# The first opaque row is the real landing surface, including thin ledges.
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x,2)), Color(palette.edge))
	for x in range(0, int(rect.size.x), 24):
		canvas.draw_line(rect.position+Vector2(x,3), rect.position+Vector2(x,rect.size.y), Color(palette.joint))
	if rect.size.y > 20:
		for x in range(16, int(rect.size.x)-10, 96):
			var at = rect.position+Vector2(x,12)
			canvas.draw_polyline(PackedVector2Array([at,at+Vector2(7,7),at+Vector2(4,13),at+Vector2(12,19)]), Color(palette.crack),1)

func creature(canvas: CanvasItem, kind: String, feet: Vector2, facing: float, state: String, flash: bool, seconds: float):
	var size = look.creatures[kind].size
	var extent = Vector2(size[0],size[1])
	canvas.draw_set_transform(feet,0,Vector2(facing,1))
	var tint = Color('#fff1dc') if flash else Color.WHITE
	if state == 'recover': tint = Color('#a3b1ba')
	canvas.draw_texture_rect(texture(kind),Rect2(Vector2(-extent.x/2,-extent.y),extent),false,tint)
	# Only a tiny vent flickers. Feet, silhouette and action tells remain stable.
	var sequence = motions.states.get(state,[0])
	var frame = int(seconds*float(motions.fps)) % sequence.size()
	var glow = Color('#ffd295') if state in ['warn','warn_slam','fire_tell','lunge','slam'] else Color('#d88759')
	if state == 'recover': glow = Color('#91bcb4')
	canvas.draw_rect(Rect2(-2,-9+float(sequence[frame]),3,2),glow)
	canvas.draw_set_transform(Vector2.ZERO)
