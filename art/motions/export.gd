extends "res://art/run/export.gd"
# Native pixel authoring; poses and timing are separate from the shared look.
const ORIGIN = Vector2(31,49)

func transform_point(value: Vector2, pose) -> Vector2:
 return (value-ORIGIN).rotated(deg_to_rad(pose.transform.angle))+point(pose.transform.at)

func offset_arm(canvas: Image, pose, near: bool):
 var layer = Image.create(64,64,false,Image.FORMAT_RGBA8)
 arm(layer,pose,near,not near)
 canvas.blend_rect(layer,Rect2i(0,0,64,64),Vector2i(pose.torso_x,0))

func render_pose(pose) -> Image:
 var local = Image.create(64,64,false,Image.FORMAT_RGBA8)
 leg(local,pose,false,true)
 offset_arm(local,pose,false)
 leg(local,pose,true,false)
 local.blend_rect(torso,Rect2i(0,0,64,64),Vector2i(pose.torso_x,pose.bob))
 local.blend_rect(animated_head(pose),Rect2i(0,0,64,64),Vector2i(pose.head_x,pose.bob))
 offset_arm(local,pose,true)
 for y in 64:
  for x in 64:
   if local.get_pixel(x,y).a > 0.0:
    var at = transform_point(Vector2(x,y),pose)
    assert(at.x>=0.5 and at.x<62.5 and at.y>=0.5 and at.y<59.5,'Transformed part would clip: '+pose.name)
 var result = Image.create(64,64,false,Image.FORMAT_RGBA8)
 stamp(result,local,point(pose.transform.at),ORIGIN,pose.transform.angle,false)
 return result

func _initialize():
 var shared = JSON.parse_string(FileAccess.get_file_as_string('res://art/run/run-poses.json'))
 load_parts(shared)
 var spec = JSON.parse_string(FileAccess.get_file_as_string('res://art/motions/poses.json'))
 var manifest = {'cell':[64,64],'pivot':[32,60],'motions':{}}
 for name in ['idle','run']:
  var source = JSON.parse_string(FileAccess.get_file_as_string('res://art/'+name+'/'+name+'-poses.json'))
  var frames = []
  for i in source.frames.size():
   frames.append({'name':source.frames[i].name,'duration_ms':1000.0/source.fps,'head':[0,-31],'chest':[0,-13],'hand':[12,-10]})
  if name == 'run':
   var legacy_hands = [[12,-11],[10,-13],[12,-11],[11,-12],[10,-14],[9,-9]]
   for i in frames.size(): frames[i].hand = legacy_hands[i%6]
  manifest.motions[name] = {'atlas':'spirit-'+name+'.png','loop':true,'loop_from':0,'frames':frames}
 for name in spec.motions:
  var motion_spec = spec.motions[name]
  var atlas = Image.create(motion_spec.frames.size()*64,64,false,Image.FORMAT_RGBA8)
  var frames = []
  for i in motion_spec.frames.size():
   var pose = motion_spec.frames[i]
   var frame = render_pose(pose)
   assert(not frame.is_invisible(),'Empty '+name)
   for y in 64:
    for x in 64:
     var color = frame.get_pixel(x,y)
     assert(color.a == 0.0 or color.a == 1.0,'Nonbinary alpha')
     if color.a > 0.0:
      assert(palette.has(color),'Palette drift')
      assert(x>0 and x<63 and y>0 and y<60,'Clipping/floor: '+name+' '+pose.name+' '+str(Vector2i(x,y)))
   atlas.blit_rect(frame,Rect2i(0,0,64,64),Vector2i(i*64,0))
   var wrist = Vector2(27+pose.torso_x,43+pose.bob)+point(pose.lead_arm[1])
   var anchors_for_frame = {'name':pose.name,'duration_ms':pose.duration_ms}
   for entry in [['head',Vector2(31+pose.head_x,29+pose.bob)],['chest',Vector2(31+pose.torso_x,46+pose.bob)],['hand',wrist]]:
    var at = transform_point(entry[1],pose)-point(spec.pivot)
    anchors_for_frame[entry[0]] = [snappedf(at.x,0.01),snappedf(at.y,0.01)]
   frames.append(anchors_for_frame)
  assert(atlas.save_png('res://assets/spirit-'+name+'.png') == OK)
  manifest.motions[name] = {'atlas':'spirit-'+name+'.png','loop':motion_spec.loop,'loop_from':motion_spec.loop_from,'frames':frames}
  print('PASS: ',name,'; ',frames.size(),' frames; native palette, alpha, bounds, fixed limb lengths')
 var file = FileAccess.open('res://assets/spirit-motions.json',FileAccess.WRITE)
 file.store_string(JSON.stringify(manifest,'  ')+'\n')
 quit()
