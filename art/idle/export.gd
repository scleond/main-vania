extends "res://art/run/export.gd"
# Reuse the approved run's pixel parts, palette, and fixed limb lengths.
func ready_arm(canvas: Image, phase, leading: bool, far: bool, offset: int):
 var layer = Image.create(64,64,false,Image.FORMAT_RGBA8)
 arm(layer,phase,leading,far)
 canvas.blend_rect(layer,Rect2i(0,0,64,64),Vector2i(offset,0))

func _initialize():
 var shared = JSON.parse_string(FileAccess.get_file_as_string('res://art/run/run-poses.json'))
 load_parts(shared)
 var spec = JSON.parse_string(FileAccess.get_file_as_string('res://art/idle/idle-poses.json'))
 assert(point(spec.cell) == Vector2(64,64) and point(spec.pivot) == Vector2(32,60))
 assert(spec.frames.size() == 8 and spec.fps == 4)
 var atlas = Image.create(512,64,false,Image.FORMAT_RGBA8)
 var soles = []
 for i in spec.frames.size():
  var phase = spec.frames[i]
  var frame = Image.create(64,64,false,Image.FORMAT_RGBA8)
  var far_sole = leg(frame,phase,false,true)
  ready_arm(frame,phase,false,true,spec.torso_x)
  var near_sole = leg(frame,phase,true,false)
  frame.blend_rect(torso,Rect2i(0,0,64,64),Vector2i(spec.torso_x,phase.bob))
  frame.blend_rect(animated_head(phase),Rect2i(0,0,64,64),Vector2i(spec.head_x,phase.bob))
  ready_arm(frame,phase,true,false,spec.torso_x)
  assert(touches_floor(near_sole) and touches_floor(far_sole),'Idle feet must stay planted')
  if i == 0:
   soles = [near_sole.get_data(),far_sole.get_data()]
  else:
   assert(near_sole.get_data() == soles[0] and far_sole.get_data() == soles[1],'Foot drift')
  assert(frame.get_region(Rect2i(0,60,64,4)).is_invisible(),'Pixels below shared pivot')
  atlas.blit_rect(frame,Rect2i(0,0,64,64),Vector2i(i*64,0))
  print(i+1,' ',phase.name,'; breath offset=',phase.bob,'; both feet fixed')
 for y in 64:
  for x in 512:
   var color = atlas.get_pixel(x,y)
   assert(color.a == 0.0 or color.a == 1.0)
   if color.a > 0.0: assert(palette.has(color),'Palette drift')
 assert(atlas.save_png('res://assets/spirit-idle.png') == OK)
 var sheet = Image.create(1152,224,false,Image.FORMAT_RGBA8)
 sheet.fill(Color('#18202c'))
 for i in 9:
  var pose = atlas.get_region(Rect2i((i%8)*64,0,64,64))
  sheet.blend_rect(pose,Rect2i(0,0,64,64),Vector2i(i*128+32,152))
  pose.resize(128,128,Image.INTERPOLATE_NEAREST)
  sheet.blend_rect(pose,Rect2i(0,0,128,128),Vector2i(i*128,8))
  for x in range(-3,4):
   sheet.set_pixel(i*128+64+x,128,Color('#70bf85'))
   sheet.set_pixel(i*128+64+x,212,Color('#70bf85'))
 assert(sheet.save_png('res://art/idle/contact-sheet.png') == OK)
 print('PASS: fixed feet, shared look/limb lengths/pivot, exact palette, binary alpha; 2-second breath')
 quit()
