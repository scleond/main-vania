extends Node2D
# Presentation-only configuration. Changing these values cannot change gameplay.
@export var idle_playback_speed=4.0
@export var run_playback_speed=8.0
@export var attack_playback_speed=16.0
@export var alternate_idle_playback_speed=7.0
@export var alternate_run_playback_speed=3.0
@export var alternate_attack_playback_speed=10.0
var atlas = preload('res://assets/spirit-atlas-magenta.png')
enum Motion { IDLE, RUN, SWIPE, JUMP, FALL, DASH, HURT, DEATH }
const MOTION_NAMES = ['idle','run','swipe','jump','fall','dash','hurt','death']
const Tuning = preload('res://tuning.gd')
var motion_data = JSON.parse_string(FileAccess.get_file_as_string('res://assets/spirit-motions.json')).motions
var motion_atlases = {
 'idle':preload('res://assets/spirit-idle.png'),
 'run':preload('res://assets/spirit-run.png'),
 'swipe':preload('res://assets/spirit-swipe.png'),
 'jump':preload('res://assets/spirit-jump.png'),
 'fall':preload('res://assets/spirit-fall.png'),
 'dash':preload('res://assets/spirit-dash.png'),
 'hurt':preload('res://assets/spirit-hurt.png'),
 'death':preload('res://assets/spirit-death.png'),
}
var motion = Motion.IDLE:
 set(value):
  if motion != value:
   motion = value
   presentation_clock = 0.0
   frame = 0
var last_attack_id = -1
var hurt_remaining = 0.0
var transient_death = false
var playback_paused = false
var frame = 0
var elements = [false,false,false,false,false]
var mirror = false
var anchors = false
var alternate_presentation = false
var presentation_clock = 0.0
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
func use_alternate_presentation(enabled):
 alternate_presentation=enabled
 presentation_clock=0.0
 queue_redraw()
# Receives authoritative state. This code never changes a timer, hitbox or velocity.
func present(velocity: Vector2, grounded: bool, attack_left: float, dash_left: float, attack_id: int):
 if hurt_remaining > 0:
  motion = Motion.HURT
 elif dash_left > 0:
  motion = Motion.DASH
  presentation_clock = Tuning.DASH_DURATION-dash_left
 elif attack_left > 0:
  motion = Motion.SWIPE
  if last_attack_id != attack_id:
   presentation_clock = 0.0
   last_attack_id = attack_id
  presentation_clock = Tuning.SWIPE_DURATION-attack_left
 elif not grounded:
  motion = Motion.JUMP if velocity.y < 0 else Motion.FALL
 else:
  motion = Motion.RUN if absf(velocity.x)>1 else Motion.IDLE
 update_frame()

func play_hurt():
 hurt_remaining = duration('hurt')
 motion = Motion.HURT
 presentation_clock = 0.0
 update_frame()

func reset_presentation():
 hurt_remaining = 0.0
 motion = Motion.IDLE
 presentation_clock = 0.0
 update_frame()

func leave_death_pose(parent: Node, at: Vector2):
 var remnant = get_script().new()
 remnant.position = at
 remnant.scale = scale
 remnant.motion = Motion.DEATH
 remnant.transient_death = true
 parent.add_child(remnant)
 return remnant

func duration(name: String) -> float:
 var milliseconds = 0.0
 for pose in motion_data[name].frames: milliseconds += pose.duration_ms
 return milliseconds/1000.0

func frame_at(name: String, seconds: float) -> int:
 var spec = motion_data[name]
 var milliseconds = maxf(seconds,0.0)*1000.0
 var total = duration(name)*1000.0
 if spec.loop and milliseconds >= total:
  var entry = 0.0
  for i in int(spec.loop_from): entry += spec.frames[i].duration_ms
  milliseconds = entry+fmod(milliseconds-entry,total-entry)
 for i in spec.frames.size():
  if milliseconds < spec.frames[i].duration_ms: return i
  milliseconds -= spec.frames[i].duration_ms
 return spec.frames.size()-1

func update_frame():
 var name = MOTION_NAMES[motion]
 var speed = 1.0
 if motion == Motion.IDLE:
  speed = (alternate_idle_playback_speed if alternate_presentation else idle_playback_speed)/4.0
 elif motion == Motion.RUN:
  speed = (alternate_run_playback_speed if alternate_presentation else run_playback_speed)/8.0
 elif motion == Motion.SWIPE:
  speed = (alternate_attack_playback_speed if alternate_presentation else attack_playback_speed)/16.0
 frame = frame_at(name,presentation_clock*speed)
 # The presentation demo intentionally samples fewer attack poses.
 if alternate_presentation and motion == Motion.SWIPE: frame = 2 if frame<3 else 5
 var pose = motion_data[name].frames[frame]
 head = Vector2(pose.head[0],pose.head[1])
 chest = Vector2(pose.chest[0],pose.chest[1])
 hand = Vector2(pose.hand[0],pose.hand[1])
 queue_redraw()

func _process(delta):
 if playback_paused: return
 presentation_clock += delta
 hurt_remaining = maxf(0.0,hurt_remaining-delta)
 if transient_death and presentation_clock >= duration('death'):
  queue_free()
  return
 update_frame()
func piece(region:Rect2,where:Vector2,size:Vector2):
 draw_texture_rect_region(atlas,Rect2(where,size),region)
func _draw():
 material.set_shader_parameter('mirror_form',mirror)
 # Rear attachments, then shared body, then foreground attachments.
 if elements[4]: piece(Rect2(1080,845,64,126),Vector2(-15,-19),Vector2(10,16))
 if elements[2]: piece(Rect2(550,829,78,135),Vector2(-22,-26),Vector2(13,25))
 if elements[3]: piece(Rect2(802,840,87,127),Vector2(-19,-26),Vector2(16,24))
 draw_texture_rect_region(motion_atlases[MOTION_NAMES[motion]],Rect2(-32,-60,64,64),Rect2(frame*64,0,64,64))
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
