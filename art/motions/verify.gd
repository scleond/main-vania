extends SceneTree
# Focused animation integration checks. Existing gameplay tests stay untouched.
const Visual = preload('res://visual.gd')
const Tuning = preload('res://tuning.gd')
var checks = 0
var failures = 0
func check(condition: bool, message: String):
 checks += 1
 if not condition:
  failures += 1
  printerr('FAIL: ',message)

func _initialize():
 call_deferred('verify')

func verify():
 var visual = Visual.new()
 root.add_child(visual)
 visual.set_process(false)
 visual.present(Vector2.ZERO,true,0,0,0)
 check(visual.motion == Visual.Motion.IDLE,'Grounded rest selects idle')
 visual.present(Vector2(115,0),true,0,0,0)
 check(visual.motion == Visual.Motion.RUN,'Ground movement selects run')
 visual.present(Vector2(115,-200),false,0,0,0)
 check(visual.motion == Visual.Motion.JUMP,'Upward velocity selects jump even while moving')
 visual.present(Vector2(115,20),false,0,0,0)
 check(visual.motion == Visual.Motion.FALL,'Downward velocity selects fall')
 visual.present(Vector2.ZERO,true,Tuning.SWIPE_DURATION,0,1)
 check(visual.motion == Visual.Motion.SWIPE and visual.frame==0,'Attack starts at wind-up')
 visual.present(Vector2.ZERO,true,0.14,0,1)
 check(visual.frame==3,'Attack follows authoritative elapsed time')
 visual.present(Vector2.ZERO,true,Tuning.SWIPE_DURATION,0,2)
 check(visual.frame==0,'Next attack restarts without stale phase')
 visual.present(Vector2(340,-100),false,0.2,0.08,2)
 check(visual.motion==Visual.Motion.DASH,'Dash overrides locomotion and attack presentation')
 visual.play_hurt()
 visual.present(Vector2.ZERO,false,0,0,2)
 check(visual.motion==Visual.Motion.HURT,'Actual hurt event overrides locomotion')
 visual._process(0.31)
 visual.present(Vector2(0,20),false,0,0,2)
 check(visual.motion==Visual.Motion.FALL,'Hurt releases back to authoritative motion')
 visual.reset_presentation()
 check(visual.hurt_remaining==0 and visual.motion==Visual.Motion.IDLE,'Respawn clears hurt')
 check(visual.frame_at('run',1.0)==0,'Run 8-to-1 seam')
 check(visual.frame_at('idle',2.0)==0,'Idle 8-to-1 seam')
 check(visual.frame_at('fall',0.43)==1,'Fall loops bracing poses after entry')
 check(visual.frame_at('jump',50)==5,'Jump holds apex instead of replaying takeoff')
 check(visual.frame_at('death',50)==7,'Death holds final pose')
 visual.playback_paused=true
 var before=visual.presentation_clock
 visual._process(0.2)
 check(visual.presentation_clock==before,'Paused presentation freezes')
 visual.playback_paused=false
 var remnant=visual.leave_death_pose(root,Vector2(200,300))
 check(remnant.motion==Visual.Motion.DEATH and remnant.position==Vector2(200,300),'Death visual remains at event location')
 remnant._process(2)
 check(remnant.is_queued_for_deletion(),'Death visual cleans itself up')
 visual.free()

 # Run the production session twice against identical inputs, with deliberately
 # different art speeds/frame sampling. Compare gameplay results at every step.
 var outcomes=[]
 for alternate in [false,true]:
  var m=load('res://main.tscn').instantiate()
  root.add_child(m)
  m.set_physics_process(false)
  m.set_process(false)
  m.player.set_physics_process(false)
  m.player.visual.set_process(false)
  m.start_run()
  m.player.visual.use_alternate_presentation(alternate)
  m.player.position=Vector2(190,299)
  m.add_enemy(220,false)
  m.enemies[0].mode='recover'
  m.enemies[0].timer=10
  var trace=[]
  for i in 40:
   m.player.attack_left=maxf(0,Tuning.SWIPE_DURATION-i/60.0)
   m.player.attack_id=1
   m.player.visual.present(Vector2.ZERO,true,m.player.attack_left,0,1)
   m._physics_process(1.0/60.0)
   trace.append([m.hp,m.kills,m.player.position,m.player.attack_left,m.probe_enemies()])
  outcomes.append(trace)
  # A lethal event must preserve immediate checkpoint restoration.
  m.player.position=Vector2(250,299)
  m.hp=0
  m._physics_process(1.0/60.0)
  check(m.hp==Tuning.PLAYER_MAX_HP and m.player.position==m.CHECKPOINT_POSITION,'Death art does not delay respawn')
  check(m.player.get_child(0).shape.size==Vector2(18,34),'Collision size stays authoritative')
  m.free()
  for action in ['left','right','jump','dash','attack','pause','retry']:
   InputMap.erase_action(action)
 check(outcomes[0]==outcomes[1],'Alternate art timing/frame sampling leaves all combat results identical')
 print('Animation checks: ',checks,'; failures: ',failures)
 quit(1 if failures else 0)
