class_name Explorer
extends CharacterBody2D

const SPEED = 120.0
const GRAVITY = 760.0
const JUMP = -270.0
var art: GrayboxActor
var coyote = 0.0
var buffer = 0.0
var enabled = true
## V2 Foxy Boost: extra jumps in the air (0 keeps V1 behaviour).
signal boosted
const BOOST = -250.0
var air_jumps = 0
var _air_left = 0
## The double jump always goes its full height (a quick second tap must not
## cut it short, which looked like a stutter).
var _boosting = false

func _ready() -> void:
	z_index=2
	collision_layer = 2
	collision_mask = 1
	var shape = CollisionShape2D.new()
	var rect = CapsuleShape2D.new()
	rect.radius = 7
	rect.height = 30
	shape.shape = rect
	shape.position.y = -15
	add_child(shape)
	art = GrayboxActor.new()
	art.kind = "child"
	add_child(art)

func _physics_process(delta: float) -> void:
	if not enabled: return
	var axis = Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, axis * SPEED, delta * 1000)
	if is_on_floor():
		coyote = 0.10
		_air_left = air_jumps
		_boosting = false
	else: coyote -= delta
	buffer -= delta
	if Input.is_action_just_pressed("jump"): buffer = 0.12
	if buffer > 0 and coyote > 0:
		velocity.y = JUMP
		buffer = 0
		coyote = 0
	elif Input.is_action_just_pressed("jump") and coyote <= 0 and _air_left > 0:
		velocity.y = BOOST
		buffer = 0
		_air_left -= 1
		_boosting = true
		boosted.emit()
	if Input.is_action_just_released("jump") and velocity.y < -100 and not _boosting: velocity.y *= 0.55
	velocity.y += GRAVITY * delta
	move_and_slide()
	if absf(axis) > 0: art.facing = signf(axis)
	art.grounded=is_on_floor()
	art.travel_speed=absf(velocity.x)
	art.mood = "jump" if not is_on_floor() else ("run" if absf(velocity.x) > 5 else "idle")

func reset_to(point: Vector2) -> void:
	position = point
	reset_physics_interpolation()
	velocity = Vector2.ZERO
	coyote = 0.0
	buffer = 0.0
