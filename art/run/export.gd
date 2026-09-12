extends SceneTree
# Edit rig-look.png for the look, run-poses.json for the run choreography.
# godot --headless --path . --script art/run/export.gd
var look: Image
var palette: Array[Color] = []
var shadow_cache = {}
var head: Image
var torso: Image
var foot: Image
var hand: Image
var outline: Color
var skin: Color
var skin_shadow: Color
var skin_light: Color
var leg_length = 4.5
var arm_length = 4.0
var spikes: Array[Image] = []
var spike_roots: Array[Vector2] = []

func point(pair): return Vector2(pair[0],pair[1])

func shade(color: Color, far: bool) -> Color:
 if not far or color.a == 0.0: return color
 if shadow_cache.has(color): return shadow_cache[color]
 var target = Vector3(color.r,color.g,color.b) * 0.86
 var distance = INF
 var nearest = color
 for candidate in palette:
  var difference = (target-Vector3(candidate.r,candidate.g,candidate.b)).length_squared()
  if difference < distance:
   distance = difference
   nearest = candidate
 shadow_cache[color] = nearest
 return nearest

func hinge(start: Vector2, end: Vector2, length: float, hint: Vector2) -> Vector2:
 var distance = start.distance_to(end)
 assert(distance <= length*2.0,'Limb target would stretch the shared segment')
 var axis = (end-start).normalized()
 var normal = Vector2(-axis.y,axis.x)
 var middle = (start+end)*0.5
 var height = sqrt(maxf(0.0,length*length-distance*distance*0.25))
 var first = middle+normal*height
 var second = middle-normal*height
 var joint = first if first.distance_squared_to(hint) < second.distance_squared_to(hint) else second
 assert(absf(start.distance_to(joint)-length)<0.001 and absf(joint.distance_to(end)-length)<0.001)
 return joint

func limb(canvas: Image, start: Vector2, joint: Vector2, end: Vector2, radius: float, far: bool):
 # Shade the union of both segments, avoiding an artificial dark joint seam.
 for y in 64:
  for x in 64:
   var pixel = Vector2(x,y)
   var closest = Geometry2D.get_closest_point_to_segment(pixel,start,joint)
   var other = Geometry2D.get_closest_point_to_segment(pixel,joint,end)
   var axis = (joint-start).normalized()
   if pixel.distance_squared_to(other) < pixel.distance_squared_to(closest):
    closest = other
    axis = (end-joint).normalized()
   var normal = Vector2(-axis.y,axis.x)
   var distance = pixel.distance_to(closest)
   if distance > radius: continue
   var color = outline
   if distance < radius-0.65:
    var side = (pixel-closest).dot(normal)
    color = skin_shadow if side > 0.45 else (skin_light if side < -0.45 else skin)
   canvas.set_pixel(x,y,shade(color,far))

func stamp(canvas: Image, part: Image, at: Vector2, pivot: Vector2, angle: float, far: bool):
 # Inverse nearest sampling keeps rotated sprite parts on the native pixel grid.
 for y in 64:
  for x in 64:
   var uv = (Vector2(x,y)-at).rotated(-deg_to_rad(angle))+pivot
   var px = roundi(uv.x)
   var py = roundi(uv.y)
   if px < 0 or py < 0 or px >= part.get_width() or py >= part.get_height(): continue
   var color = part.get_pixel(px,py)
   if color.a > 0.0: canvas.set_pixel(x,y,shade(color,far))

func leg(canvas: Image, phase, leading: bool, far: bool) -> Image:
 var joints = phase.lead_leg if leading else phase.trail_leg
 var placement = phase.lead_foot if leading else phase.trail_foot
 var ankle = Vector2(placement[0],placement[1])+Vector2(0,-2).rotated(deg_to_rad(placement[2]))
 var knee = hinge(point(joints[0]),ankle,leg_length,point(joints[1]))
 limb(canvas,point(joints[0]),knee,ankle,2.0,far)
 var sole = Image.create(64,64,false,Image.FORMAT_RGBA8)
 stamp(sole,foot,Vector2(placement[0],placement[1]),Vector2(1,2),placement[2],far)
 canvas.blend_rect(sole,Rect2i(0,0,64,64),Vector2i.ZERO)
 return sole

func arm(canvas: Image, phase, leading: bool, far: bool):
 var pose = phase.lead_arm if leading else phase.trail_arm
 var shoulder = Vector2(35,44) if far else Vector2(27,43)
 shoulder.y += phase.bob
 var wrist = shoulder+point(pose[1])
 var elbow = hinge(shoulder,wrist,arm_length,shoulder+point(pose[0]))
 limb(canvas,shoulder,elbow,wrist,1.8,far)
 stamp(canvas,hand,wrist,Vector2(2,2),0,far)

func touches_floor(sole: Image) -> bool:
 for x in 64:
  if sole.get_pixel(x,59).a > 0.0: return true
 return false

func animated_head(phase) -> Image:
 var result = Image.create(64,64,false,Image.FORMAT_RGBA8)
 for i in spikes.size():
  stamp(result,spikes[i],spike_roots[i],spike_roots[i],phase.spike_angles[i],false)
 # Keep each root tucked behind the unchanged hood so no gap opens at the join.
 result.blend_rect(head,Rect2i(0,0,64,64),Vector2i.ZERO)
 return result

func load_parts(spec):
 look = Image.load_from_file('res://art/run/rig-look.png')
 assert(look != null and look.get_size() == Vector2i(64,64))
 look.convert(Image.FORMAT_RGBA8)
 for y in 64:
  for x in 64:
   var color = look.get_pixel(x,y)
   if color.a > 0.0 and not palette.has(color): palette.append(color)
 outline = look.get_pixel(19,59)
 skin = look.get_pixel(31,47)
 skin_shadow = look.get_pixel(26,49)
 skin_light = look.get_pixel(31,50)
 head = Image.create(64,64,false,Image.FORMAT_RGBA8)
 for y in range(11,43):
  for x in 64:
   if y >= 41 and x < 27: continue
   head.set_pixel(x,y,look.get_pixel(x,y))
 torso = Image.create(64,64,false,Image.FORMAT_RGBA8)
 var rows = [[26,39],[27,39],[27,38],[26,38],[25,37],[25,37],[25,36],[25,36],[27,34]]
 for i in rows.size():
  for x in range(rows[i][0],rows[i][1]+1): torso.set_pixel(x,43+i,look.get_pixel(x,43+i))
 foot = look.get_region(Rect2i(34,57,8,3))
 hand = look.get_region(Rect2i(39,46,7,4))
 for definition in spec.spikes:
  var polygon = PackedVector2Array()
  for vertex in definition.polygon: polygon.append(point(vertex))
  var spike = Image.create(64,64,false,Image.FORMAT_RGBA8)
  for y in 64:
   for x in 64:
    if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),polygon):
     spike.set_pixel(x,y,head.get_pixel(x,y))
     head.set_pixel(x,y,Color(0,0,0,0))
  spikes.append(spike)
  spike_roots.append(point(definition.root))
 leg_length = spec.segment_lengths.leg[0]
 arm_length = spec.segment_lengths.arm[0]
 assert(leg_length == spec.segment_lengths.leg[1] and arm_length == spec.segment_lengths.arm[1])

func _initialize():
 var spec = JSON.parse_string(FileAccess.get_file_as_string('res://art/run/run-poses.json'))
 load_parts(spec)
 assert(spec.frames.size() == 8 and point(spec.pivot) == Vector2(32,60) and spec.fps == 8)
 var atlas = Image.create(512,64,false,Image.FORMAT_RGBA8)
 for i in 8:
  var sequence = spec.frames[i]
  var phase = spec.phases[sequence.phase]
  var near_leading = sequence.lead == 'right'
  var frame = Image.create(64,64,false,Image.FORMAT_RGBA8)
  var far_sole = leg(frame,phase,not near_leading,true)
  arm(frame,phase,not near_leading,true)
  var near_sole = leg(frame,phase,near_leading,false)
  frame.blend_rect(torso,Rect2i(0,0,64,64),Vector2i(0,phase.bob))
  frame.blend_rect(animated_head(phase),Rect2i(0,0,64,64),Vector2i(0,phase.bob))
  arm(frame,phase,near_leading,false)
  var contacts = int(touches_floor(near_sole))+int(touches_floor(far_sole))
  assert(contacts <= 1,'Both feet grounded in '+sequence.name)
  assert(contacts == (0 if sequence.phase == 3 else 1),'Incorrect contact phase: '+sequence.name)
  assert(touches_floor(near_sole) == (near_leading and sequence.phase != 3),'Wrong supporting leg')
  assert(touches_floor(far_sole) == (not near_leading and sequence.phase != 3),'Wrong supporting leg')
  var partner = spec.frames[(i+4)%8]
  assert(sequence.phase == partner.phase and sequence.lead != partner.lead,'Opposite pair mismatch')
  assert(frame.get_region(Rect2i(0,60,64,4)).is_invisible(),'Pixels below common floor')
  assert(not frame.get_region(Rect2i(0,0,64,64)).is_invisible())
  atlas.blit_rect(frame,Rect2i(0,0,64,64),Vector2i(i*64,0))
  print(i+1,' ',sequence.name,'; bob=',phase.bob,'; grounded feet=',contacts)
 for y in 64:
  for x in 512:
   var color = atlas.get_pixel(x,y)
   assert(color.a == 0.0 or color.a == 1.0)
   if color.a > 0.0: assert(palette.has(color),'Palette drift')
 assert(atlas.save_png('res://assets/spirit-run.png') == OK)
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
 assert(sheet.save_png('res://art/run/contact-sheet.png') == OK)
 print('PASS: single support or flight in every frame; shared look/pivot; exact palette; binary alpha; 8 frames at 8 fps')
 quit()
