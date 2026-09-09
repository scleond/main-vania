extends CharacterBody2D

var playing = false
var upgraded = false
var animation_clock = 0.0
var dash_left = 0.0
var dash_wait = 0.0
var facing = 1.0

func _ready():
	var shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(14, 26)
	shape.shape = rectangle
	add_child(shape)
	queue_redraw()

func _physics_process(delta):
	if not playing:
		return
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		facing = direction
	dash_wait = maxf(0, dash_wait - delta)
	dash_left = maxf(0, dash_left - delta)
	if Input.is_action_just_pressed("dash") and dash_wait == 0:
		dash_left = 0.13
		dash_wait = 0.65
	if not is_on_floor():
		velocity.y += 850 * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -310
	velocity.x = facing * 340 if dash_left > 0 else direction * 115
	move_and_slide()
	position.x = clampf(position.x, 12, 628)
	animation_clock += delta if direction != 0 else delta * 0.3
	queue_redraw()

func _draw():
	# Original block-art placeholder; six stepped poses at 8 fps, movement remains 60 Hz.
	var frame = int(animation_clock * 8) % 6
	var leg = [-2, 0, 2, 2, 0, -2][frame] if absf(velocity.x) > 1 else 0
	draw_rect(Rect2(-7, -14, 14, 18), Color("e8e0c4"))
	draw_rect(Rect2(-4, -19, 5, 6), Color("e8e0c4"))
	draw_rect(Rect2(-5, -10, 10, 8), Color("182132"))
	draw_rect(Rect2(-3, -8, 2, 3), Color("91e7e1"))
	draw_rect(Rect2(2, -8, 2, 3), Color("91e7e1"))
	draw_rect(Rect2(-5 + leg, 4, 4, 9), Color("babcb4"))
	draw_rect(Rect2(2 - leg, 4, 4, 9), Color("babcb4"))
	if upgraded:
		draw_rect(Rect2(-11, -1, 5, 7), Color("f4a24e"))
		draw_rect(Rect2(7, -1, 5, 7), Color("f4a24e"))
		draw_rect(Rect2(-2, -1, 4, 5), Color("fff0a4"))
