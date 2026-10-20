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
signal landed
const BOOST = -250.0
var air_jumps = 0
var _air_left = 0
## The double jump always goes its full height (a quick second tap must not
## cut it short, which looked like a stutter).
var _boosting = false
var _air_time = 0.0
var _stride = 0.0
## A60 climbing (P71): ladders and vines as Rect2 (x = centre-8, width 16,
## top = the platform it leads onto, bottom = the ground below). Climbing
## holds the explorer on the ladder's centre line; the drawing changes with
## the distance climbed (hands and feet never slide on the rungs).
const CLIMB_SPEED=72.0
const MOUNT_ZONE=22.0
var ladders: Array[Rect2]=[]
## Per ladder: a sideways hop at the top onto the ledge beside it (0 = the
## ledge is right there).
var ladder_steps: Array[float]=[]
var climbing: Rect2=Rect2()
var climb_distance=0.0
func is_climbing() -> bool: return climbing.size.y>0
func climb_axis() -> float:
	var v=Input.get_axis("move_up","move_down")
	if absf(TouchControls.stick_y)>absf(v): v=TouchControls.stick_y
	return v
func ladder_here(going_up: bool) -> Rect2:
	for idx in ladders.size():
		var l=ladders[idx]
		var reach=12.0
		# From the ledge above, the ladder beside it is grabbed from the edge.
		if not going_up and idx<ladder_steps.size(): reach+=absf(ladder_steps[idx])+8.0
		if absf(position.x-l.get_center().x)>reach: continue
		# From below: anywhere on it below the top. From above: standing on the top.
		if going_up and position.y>l.position.y+1 and position.y<=l.end.y+8: return l
		if not going_up and absf(position.y-l.position.y)<3: return l
	return Rect2()
func start_climb(l: Rect2) -> void:
	climbing=l
	collision_mask=0
	velocity=Vector2.ZERO
	_air_left=air_jumps
var climb_lock=false
var hop_time=0.0
func stop_climb(hop=false) -> void:
	climb_lock=true
	climbing=Rect2()
	collision_mask=1
	velocity=Vector2(0,-140) if hop else Vector2.ZERO
func climb_step(delta: float) -> void:
	var v=climb_axis()
	var l=climbing
	position.x=move_toward(position.x,l.get_center().x,delta*160)
	var dy=v*CLIMB_SPEED*delta
	position.y=clampf(position.y+dy,l.position.y,l.end.y)
	climb_distance+=absf(dy)
	velocity=Vector2.ZERO
	if Input.is_action_just_pressed("jump"):
		stop_climb(true)
		Sound.play("jump",0.04,-3.0)
		return
	# Off at the top onto the ledge, or at the bottom onto the ground.
	# Near the top the child steps off onto the ledge (never hangs with the
	# hands above the end of the ladder).
	if position.y<=l.position.y+MOUNT_ZONE and v<0:
		position.y=l.position.y
		var i=ladders.find(l)
		var step=ladder_steps[i] if i>=0 and i<ladder_steps.size() else 0.0
		stop_climb()
		if step!=0.0:
			# A short step-off hop that carries him fully onto the ledge.
			velocity=Vector2(signf(step)*absf(step)*2.6,-170.0)
			art.facing=signf(step)
			hop_time=0.38
	elif position.y>=l.end.y-0.01 and v>0: stop_climb()
	art.grounded=true
	art.travel_speed=0.0
	art.mood="climb"
	art.climb_distance=climb_distance
	art.climb_moving=absf(v)>0.05

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
	if is_climbing():
		climb_step(delta)
		return
	var cv=climb_axis()
	# After stepping off, Up must be let go before grabbing a ladder again.
	if absf(cv)<0.2: climb_lock=false
	if absf(cv)>0.5 and not climb_lock:
		var l=ladder_here(cv<0)
		if l.size.y>0 and (cv<0 or is_on_floor()):
			start_climb(l)
			climb_step(delta)
			return
	var axis = Input.get_axis("move_left", "move_right")
	if hop_time>0: hop_time-=delta
	else: velocity.x = move_toward(velocity.x, axis * SPEED, delta * 1000)
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
		Sound.play("jump",0.04,-3.0)
	elif Input.is_action_just_pressed("jump") and coyote <= 0 and _air_left > 0:
		velocity.y = BOOST
		buffer = 0
		_air_left -= 1
		_boosting = true
		Sound.play("double_jump")
		boosted.emit()
	if Input.is_action_just_released("jump") and velocity.y < -100 and not _boosting: velocity.y *= 0.55
	velocity.y += GRAVITY * delta
	move_and_slide()
	# Landing thump after a real fall; soft footsteps while running.
	if is_on_floor():
		# Only a real fall makes a soft landing sound (no footsteps: they
		# sounded like constant knocking).
		if _air_time>0.6: Sound.play("land",0.1,-6.0)
		if _air_time>0.3: landed.emit()
		_air_time=0.0
	else: _air_time+=delta
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
