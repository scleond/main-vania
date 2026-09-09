extends CharacterBody2D
# Gameplay tuning is intentionally isolated from presentation settings in visual.gd.
const MOVE_SPEED=115.0
const DASH_SPEED=340.0
const DASH_DURATION=0.13
const DASH_COOLDOWN=0.65
const MIXED_DASH_COOLDOWN=0.4
const JUMP_SPEED=310.0
const GRAVITY=850.0
const COYOTE_DURATION=0.1
const JUMP_BUFFER_DURATION=0.1
const ROOM_LEFT_BOUND=15.0
const ROOM_RIGHT_BOUND=625.0
const ATTACK_DURATION=0.26
const ATTACK_COOLDOWN=0.38
var active=false
var mixed=false
var upgrade=''
var facing=1.0
var dash_left=0.0
var dash_wait=0.0
var attack_left=0.0
var attack_wait=0.0
var attack_id=0
var invulnerable=0.0
var clock=0.0
var coyote=0.0
var jump_buffer=0.0
var air_used=false
var visual
func _ready():
 collision_layer=2
 collision_mask=1
 var collision=CollisionShape2D.new()
 var shape=RectangleShape2D.new()
 shape.size=Vector2(18,34)
 collision.shape=shape
 collision.position.y=-17
 add_child(collision)
 visual=load('res://visual.gd').new()
 add_child(visual)
func _physics_process(delta):
 if not active:return
 clock+=delta
 invulnerable=maxf(0,invulnerable-delta)
 dash_left=maxf(0,dash_left-delta)
 dash_wait=maxf(0,dash_wait-delta)
 attack_left=maxf(0,attack_left-delta)
 attack_wait=maxf(0,attack_wait-delta)
 coyote=maxf(0,coyote-delta)
 jump_buffer=maxf(0,jump_buffer-delta)
 if is_on_floor():
  coyote=COYOTE_DURATION
  air_used=false
 if Input.is_action_just_pressed('jump'):jump_buffer=JUMP_BUFFER_DURATION
 if jump_buffer>0 and (coyote>0 or (mixed and not air_used)):
  if coyote<=0:air_used=true
  velocity.y=-JUMP_SPEED
  coyote=0
  jump_buffer=0
 var axis=Input.get_axis('left','right')
 if axis!=0 and attack_left<=0:facing=signf(axis)
 if Input.is_action_just_pressed('dash') and dash_wait<=0:
  dash_left=DASH_DURATION
  dash_wait=MIXED_DASH_COOLDOWN if mixed else DASH_COOLDOWN
 if Input.is_action_just_pressed('attack') and attack_wait<=0 and dash_left<=0:
  attack_left=ATTACK_DURATION
  attack_wait=ATTACK_COOLDOWN
  attack_id+=1
 velocity.y+=GRAVITY*delta
 velocity.x=facing*DASH_SPEED if dash_left>0 else axis*MOVE_SPEED
 move_and_slide()
 position.x=clampf(position.x,ROOM_LEFT_BOUND,ROOM_RIGHT_BOUND)
 visual.scale.x=facing
 visual.motion=2 if attack_left>0 else (1 if absf(velocity.x)>1 else 0)
 visual.elements=[upgrade!='',false,false,mixed,mixed]
 visual.modulate.a=0.45 if invulnerable>0 and int(clock*15)%2==0 else 1.0
 visual.queue_redraw()
 queue_redraw()
func _draw():
 if dash_left>0:
  draw_line(Vector2(-facing*35,-18),Vector2(-facing*10,-18),Color('#83dcca'),3)
 if attack_left>0.07 and attack_left<0.22:
  var reach=58 if upgrade=='arc' else 38
  var center=Vector2(facing*12,-21)
  var start=-1.1 if facing>0 else PI-1.1
  draw_arc(center,reach,start,start+2.2,12,Color('#ffb75c') if upgrade!='' else Color('#e3f2dd'),3)
