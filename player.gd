extends CharacterBody2D
# Gameplay tuning lives in tuning.gd (authoritative). visual.gd holds only
# presentation settings; changing sprites, frame counts, or playback speeds
# cannot change movement, collision, or attack outcomes.
const Tuning = preload('res://tuning.gd')
var active=false
var upgrade=''
var arc_rank=0
var burn_rank=0
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
func swipe_reach():
 return Tuning.swipe_reach(arc_rank)
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
  coyote=Tuning.COYOTE_DURATION
 if Input.is_action_just_pressed('jump'):jump_buffer=Tuning.JUMP_BUFFER_DURATION
 if jump_buffer>0 and coyote>0:
  velocity.y=-Tuning.JUMP_SPEED
  coyote=0
  jump_buffer=0
 var axis=Input.get_axis('left','right')
 if axis!=0 and attack_left<=0:facing=signf(axis)
 if Input.is_action_just_pressed('dash') and dash_wait<=0:
  dash_left=Tuning.DASH_DURATION
  dash_wait=Tuning.DASH_COOLDOWN
 if Input.is_action_just_pressed('attack') and attack_wait<=0 and dash_left<=0:
  attack_left=Tuning.SWIPE_DURATION
  attack_wait=Tuning.SWIPE_COOLDOWN
  attack_id+=1
 velocity.y+=Tuning.GRAVITY*delta
 velocity.x=facing*Tuning.PLAYER_DASH_SPEED if dash_left>0 else axis*Tuning.PLAYER_MOVE_SPEED
 move_and_slide()
 position.x=clampf(position.x,Tuning.ROOM_LEFT_BOUND,Tuning.ROOM_RIGHT_BOUND)
 visual.scale.x=facing
 visual.present(velocity,is_on_floor(),attack_left,dash_left,attack_id)
 visual.path_ranks={'searing_claws':burn_rank,'flame_arc':arc_rank}
 visual.modulate.a=0.45 if invulnerable>0 and int(clock*15)%2==0 else 1.0
 visual.queue_redraw()
 queue_redraw()
func _draw():
 if dash_left>0:
  draw_line(Vector2(-facing*35,-18),Vector2(-facing*10,-18),Color('#83dcca'),3)
 if Tuning.swipe_is_active(attack_left):
  var reach=swipe_reach()
  var center=Vector2(facing*12,-21)
  var start=-1.1 if facing>0 else PI-1.1
  draw_arc(center,reach,start,start+2.2,12,Color('#ffb75c') if upgrade!='' else Color('#e3f2dd'),3)
