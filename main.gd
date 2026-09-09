extends Node2D
# THROWAWAY: frame animation and reusable attachment workflow, not game combat.
const Spirit = preload('res://spirit.gd')
var sprites = []
var motion = 1
var frame = 0
var elapsed = 0.0
var paused = false
var procedural = false
var show_anchors = false
var build = [true,true,true,true,true]
var status:Label
var time = 0.0
func label_at(text_value:String,at:Vector2,size:int=13)->Label:
 var l=Label.new()
 l.text=text_value
 l.position=at
 l.add_theme_font_size_override('font_size',size)
 add_child(l)
 return l
func button_at(title:String,x:float,y:float,action:Callable):
 var b=Button.new()
 b.text=title
 b.position=Vector2(x,y)
 b.add_theme_font_size_override('font_size',12)
 b.pressed.connect(action)
 add_child(b)
func _ready():
 label_at('SPIRIT / animation workshop',Vector2(18,8),20)
 label_at('Original art study • shared poses + reusable elemental parts',Vector2(18,34),12)
 button_at('Idle [I]',18,57,func():set_motion(0))
 button_at('Run [R]',85,57,func():set_motion(1))
 button_at('Swipe [S]',156,57,func():set_motion(2))
 button_at('Pause [Space]',242,57,func():paused=not paused)
 button_at('Step [.]',355,57,func():paused=true;frame+=1)
 button_at('Anchors [A]',430,57,func():show_anchors=not show_anchors)
 for i in range(5):
  var n=i
  button_at(['1 Ember','2 Storm','3 Thorn','4 Stone','5 Wind'][i],18+i*85,85,func():build[n]=not build[n])
 button_at('Motion A/B [V]',456,85,func():procedural=not procedural;update_url())
 var names=['NEUTRAL','EMBER','MIXED','GUARDIAN COPY']
 for row in range(2):
  for i in range(4):
   var s=Spirit.new()
   s.position=Vector2(85+i*156,228 if row==0 else 302)
   s.scale=Vector2(2,2) if row==0 else Vector2.ONE
   add_child(s)
   sprites.append(s)
   if row==0:label_at(names[i],Vector2(40+i*156,117),12)
 label_at('GAMEPLAY SIZE',Vector2(18,246),10)
 status=label_at('',Vector2(18,320),11)
 label_at('A: changing poses   B: fixed-pose bob • Mixed toggles also change the copy',Vector2(18,341),10)
 if OS.has_feature('web'):
  procedural=JavaScriptBridge.eval("new URLSearchParams(location.search).get('variant') === 'B'") == true
func update_url():
 if OS.has_feature('web'):
  JavaScriptBridge.eval("history.replaceState({},'', '?variant=%s')" % ('B' if procedural else 'A'))
func set_motion(value):
 motion=value
 frame=0
 elapsed=0
func _input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_I:set_motion(0)
   KEY_R:set_motion(1)
   KEY_S:set_motion(2)
   KEY_SPACE:paused=not paused
   KEY_PERIOD:paused=true;frame+=1
   KEY_A:show_anchors=not show_anchors
   KEY_V:procedural=not procedural;update_url()
   KEY_1,KEY_2,KEY_3,KEY_4,KEY_5:
    var n=event.keycode-KEY_1
    build[n]=not build[n]
func _process(delta):
 var count=[4,6,4][motion]
 var fps=[4.0,8.0,9.0][motion]
 if not paused:
  time+=delta
  elapsed+=delta
  if elapsed>=1.0/fps:
   elapsed=fmod(elapsed,1.0/fps)
   frame+=1
 frame=frame%count
 for j in range(sprites.size()):
  var s=sprites[j]
  var i=j%4
  s.motion=motion
  s.frame=0 if procedural else frame
  s.elements=[false,false,false,false,false] if i==0 else ([true,false,false,false,false] if i==1 else build.duplicate())
  s.mirror=i==3
  s.anchors=show_anchors
  s.position.y=(228 if j<4 else 302)+(round(sin(time*8)*2) if procedural else 0)
  s.queue_redraw()
 status.text='%s  |  %s  |  Frame %d/%d @ %d fps  |  %s  |  Parts: %s' % ['B: fixed-pose bob' if procedural else 'A: frame poses',['Idle','Run','Swipe'][motion],frame+1,count,int(fps),'PAUSED' if paused else 'PLAYING',str(build)]
 if OS.has_feature('web'):
  JavaScriptBridge.eval('window.__animation_probe = '+JSON.stringify({'ready':true,'motion':motion,'frame':frame,'paused':paused,'parts':build,'variant':'B' if procedural else 'A','instances':sprites.size()}))
 queue_redraw()
func _draw():
 draw_rect(Rect2(0,137,640,103),Color('#171f32'))
 for i in range(4):
  draw_rect(Rect2(25+i*156,230,117,4),Color('#466270'))
 draw_rect(Rect2(0,304,640,9),Color('#31494f'))
 for i in range(32):
  draw_rect(Rect2(i*20,309,18,4),Color('#23383e'))
