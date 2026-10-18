class_name Companion
extends CharacterBody2D

enum State { FOLLOW, NAVIGATE, WAIT, INVESTIGATE, ABILITY, CELEBRATE, RECOVER }
var current_state = State.FOLLOW
var leader: Explorer
var art: GrayboxActor
var anchor = Vector2.ZERO
var safe_trail: Array[Vector2] = []
var stuck = 0.0
var last_position = Vector2.ZERO
var recovery_count = 0
var reaction_timer = 0.0
var jump_links: Array[Vector4] = []
var safe_anchors: Array[Vector2] = []
var landing_target = Vector2.ZERO
var navigating_jump = false
var authored_jump_count = 0
var _shape: CapsuleShape2D
var ability_target = Vector2.INF
## Foxy found something: run there and sit by it until the child comes.
var point_target = Vector2.INF
## Rooms taller than V1 levels raise the fall limit used for recovery.
var fall_limit = 390.0

func request_help(point: Vector2) -> void:
	ability_target=point
	react(State.ABILITY,8)

func finish_help() -> void:
	ability_target=Vector2.INF
	react(State.CELEBRATE,1.2)

func _ready() -> void:
	z_index=2
	collision_layer = 4
	collision_mask = 1 | 8 # Terrain plus companion-only sandbox blockers.
	var collision = CollisionShape2D.new()
	var rect = CapsuleShape2D.new()
	rect.radius = 8
	rect.height = 18
	_shape = rect
	collision.shape = rect
	collision.position.y = -9
	add_child(collision)
	art = GrayboxActor.new()
	add_child(art)

func react(next_state: State, duration: float = 1.5) -> void:
	# Foxy's little voice: a happy yip when celebrating, a whine when it can't help.
	if next_state==State.CELEBRATE and current_state!=State.CELEBRATE: Sound.play("fox_happy",0.08)
	elif next_state==State.WAIT and current_state!=State.WAIT: Sound.play("fox_whine",0.05)
	current_state = next_state
	reaction_timer = duration

func _physics_process(delta: float) -> void:
	if not is_instance_valid(leader): return
	if leader.is_on_floor():
		if safe_trail.is_empty() or safe_trail[-1].distance_to(leader.position) > 12:
			safe_trail.append(leader.position)
			if safe_trail.size() > 120: safe_trail.pop_front()
	var target = leader.position - Vector2(34 * leader.art.facing, 0)
	# A short/new trail ends at the leader. Targeting it would walk Foxy into
	# the child's silhouette whenever both stop, or immediately after a reset.
	if safe_trail.size()>=4:
		var trail_index = maxi(0, safe_trail.size() - 4)
		target = safe_trail[trail_index]
	if point_target!=Vector2.INF: target=point_target
	if ability_target!=Vector2.INF: target=ability_target
	var distance = absf(target.x - position.x)
	reaction_timer = maxf(0, reaction_timer - delta)
	if reaction_timer <= 0 and not navigating_jump:
		current_state = State.FOLLOW if distance > 14 else State.WAIT
	if not navigating_jump:
		velocity.x = signf(target.x - position.x) * minf(distance * 4, 138.0) if distance > 8 else 0.0
	if current_state in [State.ABILITY, State.CELEBRATE] and (ability_target==Vector2.INF or distance<10): velocity.x = 0
	if is_on_floor() and not navigating_jump and reaction_timer <= 0:
		if not _try_authored_jump(target) and ((is_on_wall() and distance > 20) or target.y < position.y - 15):
			velocity.y = -275
			current_state = State.NAVIGATE
	velocity.y += 760.0 * delta
	move_and_slide()
	if navigating_jump and is_on_floor() and velocity.y >= 0: navigating_jump = false
	if distance > 40 and absf(position.x-last_position.x) < 0.35 and reaction_timer <= 0: stuck += delta
	else: stuck = 0.0
	last_position = position
	if stuck > 2.0 or position.y > fall_limit or position.distance_to(leader.position) > 500:
		recover()
	if absf(velocity.x) > 2: art.facing = signf(velocity.x)
	art.grounded=is_on_floor()
	art.travel_speed=absf(velocity.x)
	var pointing=point_target!=Vector2.INF and absf(point_target.x-position.x)<12 and is_on_floor()
	if pointing:
		art.mood="happy"
		art.facing=signf(point_target.x-position.x+0.01) if absf(point_target.x-position.x)>2 else art.facing
		return
	art.mood = "ability" if current_state in [State.ABILITY,State.INVESTIGATE] else ("happy" if current_state == State.CELEBRATE else ("jump" if not is_on_floor() else ("run" if absf(velocity.x) > 10 else "idle")))

func _try_authored_jump(target: Vector2) -> bool:
	for link in jump_links:
		var a = Vector2(link.x,link.y)
		var b = Vector2(link.z,link.w)
		if target.x < position.x:
			var swap = a
			a = b
			b = swap
		if absf(position.x-a.x)>16 or absf(position.y-a.y)>7: continue
		var direction = signf(b.x-a.x)
		if (target.x-b.x)*direction < -16: continue
		var height_delta = b.y-position.y
		var discriminant = 275.0*275.0+2.0*760.0*height_delta
		if discriminant <= 0: continue
		var flight_time = (275.0+sqrt(discriminant))/760.0
		velocity = Vector2((b.x-position.x)/flight_time,-275)
		landing_target = b
		navigating_jump = true
		current_state = State.NAVIGATE
		authored_jump_count += 1
		return true
	return false

func valid_anchor(point: Vector2) -> bool:
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.transform = Transform2D(0,point-Vector2(0,10))
	query.collision_mask = collision_mask
	var space = get_world_2d().direct_space_state
	if not space.intersect_shape(query,1).is_empty(): return false
	var floor_query = PhysicsRayQueryParameters2D.create(point-Vector2(0,1),point+Vector2(0,5),1)
	return not space.intersect_ray(floor_query).is_empty()

func recover() -> bool:
	var candidates: Array[Vector2] = [anchor]
	candidates.append_array(safe_anchors)
	var selected = Vector2.INF
	var nearest = INF
	for point in candidates:
		var separation = point.distance_to(leader.position)
		if separation < nearest and valid_anchor(point):
			nearest = separation
			selected = point
	if selected == Vector2.INF: return false
	current_state = State.RECOVER
	position = selected
	reset_physics_interpolation()
	velocity = Vector2.ZERO
	navigating_jump = false
	safe_trail.clear()
	stuck = 0
	recovery_count += 1
	reaction_timer = 0.4
	return true
