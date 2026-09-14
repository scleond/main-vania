extends RefCounted
## Artwork and pose sockets only; the effect clock is never a gameplay clock.
var artwork = JSON.parse_string(FileAccess.get_file_as_string('res://assets/element-parts.json'))
var attachments = JSON.parse_string(FileAccess.get_file_as_string('res://assets/element-attachments.json'))
var replacement = JSON.parse_string(FileAccess.get_file_as_string('res://assets/element-presentation-alternate.json'))
var body_cache: Dictionary = {}
var aura_cache: Dictionary = {}

func aura_texture(name: String, frame: int, atlas: Texture2D, family: String) -> Texture2D:
 var key = name+':'+str(frame)+':'+family
 if aura_cache.has(key): return aura_cache[key]
 # Diffuse the actual pose alpha, with transparent padding. No contour geometry.
 var spec = artwork.aura
 var radius = int(spec.blur_radius)
 var passes = int(spec.blur_passes)
 var pad = radius*passes
 var size = 64+pad*2
 var source = atlas.get_image()
 var alpha = PackedFloat32Array()
 alpha.resize(size*size)
 for y in 64:
  for x in 64:
   alpha[(y+pad)*size+x+pad] = source.get_pixel(frame*64+x,y).a
 for step in passes*2:
  var softened = PackedFloat32Array()
  softened.resize(size*size)
  for y in size:
   for x in size:
    var total = 0.0
    for offset in range(-radius,radius+1):
     var sx = x+offset if step%2 == 0 else x
     var sy = y if step%2 == 0 else y+offset
     if sx >= 0 and sx < size and sy >= 0 and sy < size:
      total += alpha[sy*size+sx]
    softened[y*size+x] = total/float(radius*2+1)
  alpha = softened
 var glow = Image.create(size,size,false,Image.FORMAT_RGBA8)
 var tint = Color(artwork.spike_palettes[family][2])
 for y in size:
  for x in size:
   tint.a = alpha[y*size+x]*float(spec.opacity)
   glow.set_pixel(x,y,tint)
 var texture = ImageTexture.create_from_image(glow)
 aura_cache[key] = texture
 return texture

func pose(name: String, frame: int) -> Dictionary:
 return attachments.motions[name][frame]

func displayed_frame(name: String, frame: int, alternate: bool) -> int:
 if alternate and replacement.sequences.has(name):
  return int(replacement.sequences[name][frame])
 return frame

func dominant_family(ranks: Dictionary) -> String:
 # Strongest total investment wins. Stable art-order ties need no save migration.
 var winner = ''
 var highest = 0
 for family in artwork.family_order:
  var total = 0
  for path in attachments.mounts:
   if artwork.parts[path].family == family:
    total += clampi(int(ranks.get(path,0)),0,8)
  if total > highest:
   winner = family
   highest = total
 return winner

func body_texture(name: String, atlas: Texture2D, family: String, ranks: Dictionary = {}) -> Texture2D:
 if family == '': return atlas
 var reprisal_rank = clampi(int(ranks.get('reprisal',0)),0,8)
 var texture_key = ':reprisal:'+str(reprisal_rank)
 var key = name+':'+family+texture_key
 if body_cache.has(key): return body_cache[key]
 # Recolor only existing cyan spike pixels, in each pose's local head space.
 # Eyes, cream hood, alpha, flexing silhouettes and original atlases stay intact.
 var pixels = atlas.get_image()
 pixels.convert(Image.FORMAT_RGBA8)
 var palette = artwork.palettes[family]
 var spike_palette = artwork.spike_palettes.get(family,palette)
 var stone_texture = reprisal_rank > 0
 for frame in attachments.motions[name].size():
  var sockets = pose(name,frame)
  var head = Vector2(sockets.head[0],sockets.head[1])
  var angle = deg_to_rad(sockets.angle)
  for y in 64:
   for x in 64:
    var local = (Vector2(x-32,y-60)-head).rotated(-angle)
    if local.y >= -3: continue
    var color = pixels.get_pixel(frame*64+x,y)
    if color.a == 0 or color.g <= color.r*1.2 or color.b <= color.r*1.2 or color.g <= 0.25: continue
    var light = maxf(color.r,maxf(color.g,color.b))
    var tint
    if stone_texture:
     # Reprisal is a static facet pattern on the existing spikes. Its colors
     # stay inside the selected dominant family instead of using stone ink.
     var facet = absi((floori(local.x) + floori(local.y) * 2) % 5)
     tint = Color(spike_palette[1 if facet == 0 else (3 if facet == 4 else 2)])
     if facet > 0 and facet < 4:
      tint = tint.lerp(Color(spike_palette[3]),float(artwork.parts.reprisal.rank_polish[reprisal_rank-1]))
    else:
     tint = Color(spike_palette[3 if light > 0.85 else (2 if light > 0.55 else 1)])
    tint.a = color.a
    pixels.set_pixel(frame*64+x,y,tint)
 var texture = ImageTexture.create_from_image(pixels)
 body_cache[key] = texture
 return texture

func occluded(pixel: Vector2, sockets: Dictionary, mask_id: String) -> bool:
 if mask_id == '': return false
 var mask = attachments.occlusion_masks[mask_id]
 var placement = sockets.occluders[mask_id]
 # Match the approved body authoring's two nearest-sampling steps: undo the
 # whole-pose transform, then sample the original hand at its local wrist.
 var local = ((pixel+Vector2(32,60)-Vector2(placement.transform_at[0],placement.transform_at[1])).rotated(-deg_to_rad(sockets.angle))+Vector2(placement.transform_origin[0],placement.transform_origin[1])).round()
 var uv = (local-Vector2(placement.wrist[0],placement.wrist[1])+Vector2(mask.pivot[0],mask.pivot[1])).round()
 var x = int(uv.x)
 var y = int(uv.y)
 return y >= 0 and y < mask.rows.size() and x >= 0 and x < mask.rows[y].length() and mask.rows[y][x] != '.'

func draw_motif(canvas: Node2D, motif_id: String, origin: Vector2, angle: float, palette: Array, seconds: float, phase: int, marks: Array = [], rank: int = 1, sockets: Dictionary = {}, mask_id: String = ''):
 var motif = artwork.motifs[motif_id]
 var index = (int(floor(maxf(seconds,0.0)*1000.0/float(motif.frame_ms)))+phase)%motif.frames.size()
 var pixels = motif.frames[index]
 var width = 0
 for row in pixels: width = maxi(width,row.length())
 # Inverse nearest sampling lands every rotated attachment on the body pixel grid.
 var low = Vector2(INF,INF)
 var high = Vector2(-INF,-INF)
 for corner in [Vector2.ZERO,Vector2(width,0),Vector2(0,pixels.size()),Vector2(width,pixels.size())]:
  var at = origin+corner.rotated(angle)
  low = low.min(at)
  high = high.max(at)
 for y in range(floori(low.y),ceili(high.y)):
  for x in range(floori(low.x),ceili(high.x)):
   var uv = (Vector2(x+0.5,y+0.5)-origin).rotated(-angle)
   var px = floori(uv.x)
   var py = floori(uv.y)
   if py < 0 or py >= pixels.size() or px < 0 or px >= pixels[py].length(): continue
   var ink = artwork.ink.find(pixels[py][px])
   if ink < 0: continue
   if occluded(Vector2(x,y),sockets,mask_id): continue
   # Veins/inclusions live inside the motif, never as floating rank tally bars.
   for i in mini(rank-1,marks.size()):
    if px == int(marks[i][0]) and py == int(marks[i][1]): ink = 3
   var color = Color(palette[ink])
   if motif.has('ink_alpha'): color.a *= float(motif.ink_alpha[ink])
   canvas.draw_rect(Rect2(x,y,1,1),color)

func draw_layer(canvas: Node2D, name: String, frame: int, ranks: Dictionary, layer: String, alternate: bool, seconds: float = 0.0):
 var sockets = pose(name,frame)
 for path in attachments.mounts:
  var rank = clampi(int(ranks.get(path,0)),0,8)
  if rank == 0: continue
  var recipe = attachments.mounts[path]
  if artwork.parts[path].has('texture'): continue
  var part_id = replacement.part_overrides.get(path,path) if alternate else path
  var part = artwork.parts[part_id]
  var palette = artwork.palettes[part.get('palette',part.family)]
  if part.has('rank_palette'): palette = artwork.rank_palettes[part.rank_palette][rank-1]
  for mount in recipe.get('instances',[recipe]):
   if mount.layer != layer: continue
   var anchor = sockets[mount.anchor]
   var offset = replacement.offset_overrides.get(path,mount.offset) if alternate else mount.offset
   var angle = deg_to_rad(sockets.get(mount.get('angle_anchor','angle'),sockets.angle))
   var origin = (Vector2(anchor[0],anchor[1])+Vector2(offset[0],offset[1]).rotated(angle)).round()
   var mask_id = mount.get('occluder','')
   var phase = int(mount.get('phase',0))
   for i in part.growth.size():
    var growth = part.growth[i]
    if rank < int(growth.min_rank): continue
    var at = origin+Vector2(growth.offset[0],growth.offset[1]).rotated(angle)
    draw_motif(canvas,growth.motif,at.round(),angle,palette,seconds,i+1+phase,[],1,sockets,mask_id)
   draw_motif(canvas,mount.get('motif',part.motif),origin,angle,palette,seconds,phase,part.rank_marks,rank,sockets,mask_id)
