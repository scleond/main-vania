extends SceneTree
# Static art review/export, not a gameplay test or animation viewer.
# godot --path . --script art/ember/preview.gd
class Plate extends Node2D:
	var kit = preload('res://ember_art.gd').new()
	var section = preload('res://main.gd')
	func _draw():
		kit.environment(self,1760,section.EMBER_PLATFORMS)
		kit.stamp(self,'checkpoint',Vector2(110,300))
		kit.stamp(self,'shrine-ready',Vector2(440,300))
		kit.creature(self,'easy',Vector2(160,300),1,'warn',false,0)
		kit.creature(self,'medium',Vector2(230,300),-1,'recover',false,0)
		kit.creature(self,'miniboss',Vector2(330,300),1,'fire_tell',false,0)
		draw_line(Vector2(160,297),Vector2(200,297),Color('#ffb859'),2)
		draw_circle(Vector2(230,241),2,Color('#9bbcaf'))
		for x in [160,230,330]:
			draw_line(Vector2(x,304),Vector2(x,309),Color('#a6f4d7'))
func _initialize():
	call_deferred('capture')
func capture():
	root.size = Vector2i(640,360)
	var plate = Plate.new()
	root.add_child(plate)
	for i in 3:
		var spirit = preload('res://visual.gd').new()
		spirit.position = Vector2(65+i*230,300)
		spirit.playback_paused = true
		if i == 1: spirit.path_ranks = {'searing_claws':2,'chain_spark':2,'stonehide':2,'airborne':2}
		if i == 2: spirit.path_ranks = {'flame_arc':2,'barb_shot':2,'reprisal':2,'slipstream':2}
		plate.add_child(spirit)
	var title = Label.new()
	title.text = 'EMBER / furnace court — native 640 × 360\nNeutral Spirit · mixed Spirits · easy / medium / Miniboss'
	title.position = Vector2(12,12)
	title.add_theme_font_size_override('font_size',12)
	plate.add_child(title)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://art/ember/review.png')
	quit()
