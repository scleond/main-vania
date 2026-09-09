extends Node2D
# Presentation-only configuration. Changing these values cannot change gameplay.
@export var idle_playback_speed=4.0
@export var run_playback_speed=8.0
@export var attack_playback_speed=16.0
var atlas = preload('res://assets/spirit-atlas-magenta.png')
var motion = 0
var frame = 0
var elements = [false,false,false,false,false]
var mirror = false
var anchors = false
var idle_boxes = [Rect2(50,24,180,253),Rect2(310,24,175,253),Rect2(565,24,180,253),Rect2(810,24,178,253)]
var run_boxes = [Rect2(45,286,190,237),Rect2(310,286,175,237),Rect2(565,286,182,237),Rect2(818,286,177,237),Rect2(1080,286,178,237),Rect2(1335,286,182,237)]
var swipe_boxes = [Rect2(45,550,190,230),Rect2(308,550,226,230),Rect2(563,550,233,230),Rect2(833,550,179,230)]
var head = Vector2(0,-31)
var chest = Vector2(0,-13)
var hand = Vector2(12,-10)
func _ready():
 var shader = Shader.new()
 shader.code = '''shader_type canvas_item;
 uniform bool mirror_form = false;
 void fragment(){
 vec4 c = texture(TEXTURE,UV);
 if(c.r > 0.65 && c.b > 0.65 && c.g < 0.4) c.a=0.0;
 if(mirror_form && c.a>0.0){
 float light=max(c.r,max(c.g,c.b));
 c.rgb=vec3(light*0.85,light*0.48,light);
 }
 COLOR=c;
 }'''
 material = ShaderMaterial.new()
 material.shader = shader
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func piece(region:Rect2,where:Vector2,size:Vector2):
 draw_texture_rect_region(atlas,Rect2(where,size),region)
func _draw():
 material.set_shader_parameter('mirror_form',mirror)
 var boxes = [idle_boxes,run_boxes,swipe_boxes][motion]
 var box:Rect2 = boxes[frame % boxes.size()]
 # Separate body anchor and per-pose hand anchors avoid combinatorial sprites.
 var foot_x = [100.0,90.0,93.0,94.0][frame%4] if motion==0 else 100.0
 if motion==2: foot_x=[100.0,102.0,102.0,92.0][frame%4]
 hand=Vector2(12,-10)
 if motion==2: hand=[Vector2(-12,-15),Vector2(22,-20),Vector2(25,-19),Vector2(10,-10)][frame%4]
 if motion==1: hand=[Vector2(12,-11),Vector2(10,-13),Vector2(12,-11),Vector2(11,-12),Vector2(10,-14),Vector2(9,-9)][frame%6]
 # Rear attachments, then shared body, then foreground attachments.
 if elements[4]: piece(Rect2(1080,845,64,126),Vector2(-15,-19),Vector2(10,16))
 if elements[2]: piece(Rect2(550,829,78,135),Vector2(-22,-26),Vector2(13,25))
 if elements[3]: piece(Rect2(802,840,87,127),Vector2(-19,-26),Vector2(16,24))
 piece(box,Vector2(-foot_x*0.19,-48),Vector2(box.size.x*0.19,48))
 if elements[1]: piece(Rect2(295,829,78,126),head+Vector2(-8,-19),Vector2(14,23))
 if elements[0]:
  piece(Rect2(1360,842,100,116),chest-Vector2(4,7),Vector2(9,12))
  piece(Rect2(164,828,82,151),hand-Vector2(3,6),Vector2(10,20))
 if elements[4]: piece(Rect2(1167,845,65,126),Vector2(4,-16),Vector2(8,14))
 if mirror:
  draw_line(Vector2(-19,3),Vector2(22,3),Color('#c59bff'),1)
 if anchors:
  for point in [Vector2.ZERO,head,chest,hand]:
   draw_line(point-Vector2(2,0),point+Vector2(2,0),Color.GREEN,1)
   draw_line(point-Vector2(0,2),point+Vector2(0,2),Color.GREEN,1)
