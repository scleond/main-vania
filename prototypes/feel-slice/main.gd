extends Node2D
# Disposable feel experiment. Session state only; this is not production progression.
var player
var hp=6.0
var souls=0
var upgrade=''
var mixed=false
var playing=false
var choosing=false
var paused=false
var enemies=[]
var particles=[]
var wave=0
var wave_wait=0.0
var choice_delay=0.0
var kills=0
var deaths=0
var clock=0.0
var message=''
var message_left=0.0
var ui
var hud
var status
var menu
var choice
var pause_label
var platforms=[Rect2(0,300,640,60),Rect2(165,240,95,10),Rect2(375,217,105,10)]
func label_at(text_value,at,size=12,parent=null):
 var label=Label.new()
 label.text=text_value
 label.position=at
 label.add_theme_font_size_override('font_size',size)
 (ui if parent==null else parent).add_child(label)
 return label
func button_at(text_value,at,callback,parent):
 var b=Button.new()
 b.text=text_value
 b.position=at
 b.add_theme_font_size_override('font_size',13)
 b.pressed.connect(callback)
 parent.add_child(b)
 return b
func _ready():
 for action in ['left','right','jump','dash','attack']:InputMap.add_action(action)
 for pair in [['left',KEY_A],['left',KEY_LEFT],['right',KEY_D],['right',KEY_RIGHT],['jump',KEY_SPACE],['dash',KEY_SHIFT],['attack',KEY_J],['attack',KEY_X]]:
  var e=InputEventKey.new()
  e.physical_keycode=pair[1]
  InputMap.action_add_event(pair[0],e)
 for pair in [['jump',JOY_BUTTON_A],['attack',JOY_BUTTON_X],['dash',JOY_BUTTON_RIGHT_SHOULDER]]:
  var e=InputEventJoypadButton.new()
  e.button_index=pair[1]
  InputMap.action_add_event(pair[0],e)
 for pair in [['left',-1.0],['right',1.0]]:
  var e=InputEventJoypadMotion.new()
  e.axis=JOY_AXIS_LEFT_X
  e.axis_value=pair[1]
  InputMap.action_add_event(pair[0],e)
 for rect in platforms:
  var body=StaticBody2D.new()
  var c=CollisionShape2D.new()
  var shape=RectangleShape2D.new()
  shape.size=rect.size
  c.shape=shape
  body.position=rect.get_center()
  body.add_child(c)
  add_child(body)
 player=load('res://player.gd').new()
 player.position=Vector2(70,300)
 add_child(player)
 ui=CanvasLayer.new()
 add_child(ui)
 label_at('EMBER HALL / feel experiment',Vector2(16,8),18)
 hud=label_at('',Vector2(16,33))
 status=label_at('',Vector2(16,53),11)
 label_at('A/D move · Space jump · J/X swipe · Shift dash · M mixed preview',Vector2(16,315),11)
 label_at('E rest at checkpoint · K respawn · Esc pause · N new run',Vector2(16,332),11)
 menu=Panel.new()
 menu.position=Vector2(110,90)
 menu.size=Vector2(420,165)
 ui.add_child(menu)
 label_at('Earn 8 Numen to evolve',Vector2(24,15),20,menu)
 label_at('Fight small groups. Orange warning → lunge → recovery.\nEasy: 1 soul. Medium: 2 souls. Jump or dash past attacks.\nDeath keeps souls and your chosen upgrade.\nTemporary art; no audio. Refresh starts a new session.',Vector2(24,49),12,menu)
 button_at('Start [Enter]',Vector2(24,120),start_run,menu)
 choice=Panel.new()
 choice.position=Vector2(40,88)
 choice.size=Vector2(560,172)
 ui.add_child(choice)
 label_at('EVOLVE / Ember',Vector2(18,12),20,choice)
 label_at('Choose one permanent upgrade. Play is paused.',Vector2(18,40),12,choice)
 button_at('1 · Searing Claws\nSwipes ignite enemies',Vector2(18,72),func():select_upgrade('burn'),choice)
 button_at('2 · Flame Arc\nSwipes reach farther',Vector2(285,72),func():select_upgrade('arc'),choice)
 label_at('Both add fiery claws. N starts a fresh run to try the other.',Vector2(18,139),11,choice)
 choice.hide()
 pause_label=label_at('PAUSED — Esc to resume',Vector2(195,165),19)
 pause_label.hide()
 refresh()
func start_run():
 souls=0
 upgrade=''
 mixed=false
 kills=0
 deaths=0
 playing=true
 choosing=false
 paused=false
 menu.hide()
 choice.hide()
 respawn(false)
func respawn(count=true):
 if count:deaths+=1
 hp=6
 player.position=Vector2(70,299)
 player.velocity=Vector2.ZERO
 player.invulnerable=1.0
 player.attack_left=0
 player.dash_left=0
 player.dash_wait=0
 player.attack_wait=0
 particles.clear()
 enemies.clear()
 wave=0
 wave_wait=0.6
 note('Checkpoint restored. Numen and upgrade retained.' if count else 'Defeat the Ember creatures. Earn 8 Numen.')
func note(value):
 message=value
 message_left=4.0
func _unhandled_key_input(event):
 if not event.pressed or event.echo:return
 match event.physical_keycode:
  KEY_ENTER:
   if not playing:start_run()
  KEY_N:start_run()
  KEY_ESCAPE:
   if playing and not choosing:paused=not paused
  KEY_1:
   if choosing:select_upgrade('burn')
  KEY_2:
   if choosing:select_upgrade('arc')
  KEY_M:
   if playing and not choosing:
    mixed=not mixed
    note('Preview: Stone protection + Wind air-jump / faster dash' if mixed else 'Mixed preview off. Earned Ember upgrade retained.')
  KEY_K:
   if playing and not choosing:respawn()
  KEY_E:
   if playing and not choosing and absf(player.position.x-70)<45:respawn(false)
func select_upgrade(value):
 if not choosing:return
 upgrade=value
 souls-=8
 choosing=false
 choice.hide()
 note('Evolved! Fight again to feel the change. M adds Stone/Wind preview.')
 wave_wait=0.8
func spawn_wave():
 wave+=1
 if wave%4==0:
  add_enemy(475,true)
 else:
  add_enemy(330,false)
  add_enemy(555,false)
func add_enemy(x,medium):
 enemies.append({'x':float(x),'hp':6.0 if medium else 3.0,'max_hp':6.0 if medium else 3.0,'medium':medium,'mode':'approach','timer':0.0,'dir':-1.0,'hit_id':-1,'burn':0.0,'burn_tick':0.0,'flash':0.0})
func _physics_process(delta):
 player.active=playing and not choosing and not paused
 player.upgrade=upgrade
 player.mixed=mixed
 if not player.active:return
 clock+=delta
 message_left=maxf(0,message_left-delta)
 choice_delay=maxf(0,choice_delay-delta)
 if upgrade=='' and souls>=8 and choice_delay<=0:
  choosing=true
  player.active=false
  choice.show()
  return
 if enemies.is_empty():
  wave_wait-=delta
  if wave_wait<=0:spawn_wave()
 for enemy in enemies:
  enemy.flash=maxf(0,enemy.flash-delta)
  var difference=player.position.x-enemy.x
  enemy.timer-=delta
  if enemy.mode=='approach':
   if absf(difference)<72 and player.position.y>250:
    enemy.mode='warn'
    enemy.timer=0.85 if enemy.medium else 0.65
    enemy.dir=signf(difference) if difference!=0 else 1.0
   elif absf(difference)<240:
    enemy.x+=signf(difference)*(30 if enemy.medium else 40)*delta
  elif enemy.mode=='warn' and enemy.timer<=0:
   enemy.mode='lunge'
   enemy.timer=0.32 if enemy.medium else 0.22
  elif enemy.mode=='lunge':
   enemy.x+=enemy.dir*(200 if enemy.medium else 140)*delta
   if enemy.timer<=0:
    enemy.mode='recover'
    enemy.timer=1.25 if enemy.medium else 0.85
  elif enemy.mode=='recover' and enemy.timer<=0:enemy.mode='approach'
  enemy.x=clampf(enemy.x,145,615)
  var reach=58 if upgrade=='arc' else 38
  var relative=enemy.x-player.position.x
  if player.attack_left<0.22 and player.attack_left>0.07 and enemy.hit_id!=player.attack_id and relative*player.facing>-10 and absf(relative)<reach+14 and absf(player.position.y-300)<43:
   enemy.hit_id=player.attack_id
   enemy.hp-=1
   enemy.flash=0.12
   enemy.x+=player.facing*7
   if upgrade=='burn':enemy.burn=2.2
  if enemy.burn>0:
   enemy.burn-=delta
   enemy.burn_tick+=delta
   if enemy.burn_tick>=0.7:
    enemy.burn_tick=0
    enemy.hp-=1
    enemy.flash=0.1
  if enemy.hp>0 and enemy.mode=='lunge' and absf(enemy.x-player.position.x)<25 and player.position.y>266 and player.invulnerable<=0 and player.dash_left<=0:
   hp-=(2.0 if enemy.medium else 1.0)*(0.5 if mixed else 1.0)
   player.invulnerable=0.85
   player.velocity.y=-135
   note('Hit! Watch the warning, then punish the recovery.')
 var living=[]
 for enemy in enemies:
  if enemy.hp<=0:
   var reward=2 if enemy.medium else 1
   souls+=reward
   kills+=1
   choice_delay=0.65
   for i in range(reward):particles.append({'start':Vector2(enemy.x+i*12,277-i*8),'time':0.0})
   wave_wait=1.2
  else:living.append(enemy)
 enemies=living
 if hp<=0 or player.position.y>380:respawn()
 for particle in particles:particle.time+=delta
 particles=particles.filter(func(p):return p.time<0.65)
func refresh():
 hud.text='Health %.1f / 6   |   Numen %s   |   %s' % [hp,(str(souls)+' / 8') if upgrade=='' else str(souls),'Neutral' if upgrade=='' else ('Searing Claws' if upgrade=='burn' else 'Flame Arc')]
 status.text=message if message_left>0 else ('Mixed preview ON: Stone + Wind  |  Wave %d' % wave if mixed else 'Wave %d  |  One earned upgrade in this experiment' % wave)
func _process(_delta):
 refresh()
 pause_label.visible=paused
 if OS.has_feature('web'):
  JavaScriptBridge.eval('window.__feel_probe = '+JSON.stringify({'ready':true,'playing':playing,'choosing':choosing,'paused':paused,'hp':hp,'souls':souls,'upgrade':upgrade,'mixed':mixed,'wave':wave,'kills':kills,'deaths':deaths,'x':player.position.x,'y':player.position.y,'attack':player.attack_id,'enemies':enemies}))
 queue_redraw()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and playing:paused=true
func _draw():
 for i in range(8):
  draw_rect(Rect2(i*90+15,125+(i%3)*12,32,175),Color('#172637'))
  draw_rect(Rect2(i*90+24,156,8,28),Color('#46352c'))
 for rect in platforms:
  draw_rect(rect,Color('#354340'))
  draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color('#8a9c73'))
 draw_rect(Rect2(62,273,16,27),Color('#537f83'))
 draw_circle(Vector2(70,269),5,Color('#a6f4d7'))
 for enemy in enemies:
  var x=enemy.x
  var w=19 if enemy.medium else 13
  var h=28 if enemy.medium else 19
  var color=Color('#f3dec1') if enemy.flash>0 else (Color('#ab553b') if enemy.medium else Color('#cf7049'))
  draw_rect(Rect2(x-w,300-h,w*2,h),color)
  for i in range(3):
   draw_colored_polygon(PackedVector2Array([Vector2(x-w+i*w*0.7,300-h),Vector2(x-w+3+i*w*0.7,289-h),Vector2(x-w+7+i*w*0.7,300-h)]),Color('#f9ad5a'))
  draw_rect(Rect2(x+enemy.dir*7-2,285,4,4),Color('#fff0bc'))
  draw_line(Vector2(x-w,265-h),Vector2(x-w+2*w*enemy.hp/enemy.max_hp,265-h),Color('#c87f55'),2)
  if enemy.mode=='warn':
   draw_line(Vector2(x,297),Vector2(x+enemy.dir*(64 if enemy.medium else 40),297),Color('#ffb859'),2)
   draw_rect(Rect2(x-2,268-h,4,7),Color('#ffe3a0'))
  if enemy.mode=='recover':draw_circle(Vector2(x,269-h),2,Color('#9bbcaf'))
  if enemy.burn>0:
   draw_colored_polygon(PackedVector2Array([Vector2(x-4,275-h),Vector2(x,263-h),Vector2(x+4,275-h)]),Color('#ff8b35'))
 for particle in particles:
  var t=particle.time/0.65
  var at=particle.start.lerp(player.position-Vector2(0,23),t)+Vector2(0,-sin(t*PI)*25)
  draw_colored_polygon(PackedVector2Array([at+Vector2(0,-5),at+Vector2(4,1),at+Vector2(0,4),at+Vector2(-4,1)]),Color('#ffc074'))
