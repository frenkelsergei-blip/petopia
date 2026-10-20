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
signal recovered(at: Vector2)
## A60: Foxy climbs the boy's ladders too (same frames, just below him).
var climbing: Rect2=Rect2()
var climb_distance=0.0
var climb_target=0.0
const CLIMB_GAP=54.0
var climb_wait=0.0
## A ladder linking where Foxy is to where the child is (or is climbing).
func ladder_to_leader() -> Rect2:
	for l in leader.ladders:
		var on=leader.is_climbing() and leader.climbing==l
		var leader_top=absf(leader.position.y-l.position.y)<6 and absf(leader.position.x-l.get_center().x)<160
		var leader_bottom=absf(leader.position.y-l.end.y)<6 and absf(leader.position.x-l.get_center().x)<160
		var me_top=absf(position.y-l.position.y)<6
		var me_bottom=absf(position.y-l.end.y)<6
		if (on or leader_top) and me_bottom and absf(position.x-l.get_center().x)<200: return l
		if (on or leader_bottom) and me_top and absf(position.x-l.get_center().x)<200: return l
	return Rect2()
func climb_step(delta: float) -> bool:
	var l=climbing
	# Stay a little below the child while they climb; go to their end after.
	var goal=l.end.y if leader.position.y>=l.end.y-2 else l.position.y
	# The child still standing at that end of the ladder: wait a body's
	# length away on it until they step aside.
	if not leader.is_climbing() and absf(leader.position.x-l.get_center().x)<16 and climb_wait<2.5:
		goal=clampf(goal+(-CLIMB_GAP if goal==l.end.y else CLIMB_GAP),l.position.y,l.end.y)
		climb_wait+=delta
	else: climb_wait=0.0
	# A body's length apart (the boy is ~48 tall): never on his head or feet.
	if leader.is_climbing() and leader.climbing==l: goal=clampf(leader.position.y+(CLIMB_GAP if leader.position.y<position.y+1 else -CLIMB_GAP),l.position.y,l.end.y)
	position.x=move_toward(position.x,l.get_center().x+(0.0),delta*160)
	var before=position.y
	position.y=move_toward(position.y,goal,delta*76.0)
	climb_distance+=absf(position.y-before)
	velocity=Vector2.ZERO
	art.mood="climb"
	art.grounded=true
	art.travel_speed=0.0
	art.climb_distance=climb_distance
	art.climb_moving=absf(position.y-before)>0.01
	# Off at the end it is heading for: also when the child climbs toward
	# Foxy (it steps off and makes room instead of being climbed onto).
	var at_end=absf(position.y-l.position.y)<0.5 or absf(position.y-l.end.y)<0.5
	var done=at_end and absf(position.y-goal)<0.5 and (absf(goal-l.position.y)<0.5 or absf(goal-l.end.y)<0.5)
	if done:
		climbing=Rect2()
		collision_mask=1|8
		safe_trail.clear()
	return true

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
	if climbing.size.y>0:
		climb_step(delta)
		return
	var lad=ladder_to_leader()
	if lad.size.y>0 and is_on_floor():
		# Walk to the ladder's foot (or top), then climb.
		# Stands beside the ladder while waiting (not on its centre line).
		var dx=lad.get_center().x-position.x
		if leader.is_climbing() and absf(leader.position.y-position.y)<CLIMB_GAP: dx=lad.get_center().x-14.0*signf(lad.get_center().x-position.x+0.01)-position.x
		# Waits at its end until the child has climbed a body's length away.
		var room=absf(leader.position.y-position.y)>=CLIMB_GAP or not leader.is_climbing()
		if absf(dx)<4 and not room:
			velocity.x=0
			art.mood="idle"
			art.facing=signf(leader.position.x-position.x+0.01)
			return
		if absf(dx)<4:
			climbing=lad
			collision_mask=0
			climb_step(delta)
			return
		velocity.x=signf(dx)*minf(absf(dx)*6.0,170.0)
		velocity.y+=760.0*delta
		move_and_slide()
		art.facing=signf(dx)
		art.grounded=true
		art.travel_speed=absf(velocity.x)
		art.mood="run"
		return
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
	# While the child keeps jumping the trail stops growing; when they are
	# far ahead, head straight for them instead of waiting at an old spot.
	if position.distance_to(leader.position)>80 and target.distance_to(position)<20:
		target=leader.position-Vector2(30*leader.art.facing,0)
	# A60: never a spot past a ledge's edge (Foxy walked off after climbing):
	# the other side of the child, or right by them.
	if leader.is_on_floor() and target.y<=leader.position.y+2 and not valid_anchor(target):
		var other=leader.position+Vector2(26*leader.art.facing,0)
		target=other if valid_anchor(other) else leader.position
	if point_target!=Vector2.INF: target=point_target
	if ability_target!=Vector2.INF: target=ability_target
	var distance = absf(target.x - position.x)
	reaction_timer = maxf(0, reaction_timer - delta)
	if reaction_timer <= 0 and not navigating_jump:
		current_state = State.FOLLOW if distance > 14 else State.WAIT
	if not navigating_jump:
		# Runs faster the farther behind it is, so it keeps up with the child.
		var top_speed=150.0+clampf(distance-40.0,0.0,150.0)*1.2
		velocity.x = signf(target.x - position.x) * minf(distance * 4, top_speed) if distance > 8 else 0.0
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
	# Never lose the child: a short stall or a big gap brings Foxy back to them.
	if stuck > 0.7 or position.y > fall_limit or position.distance_to(leader.position) > 300:
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
	# With the child standing on solid ground, hop in right behind them
	# (never pop up ahead of the child).
	if is_instance_valid(leader) and leader.is_on_floor():
		position=leader.position-Vector2(22.0*leader.art.facing,4)
		reset_physics_interpolation()
		velocity=Vector2(0,-110)
		navigating_jump=false
		safe_trail.clear()
		stuck=0
		recovery_count+=1
		current_state=State.RECOVER
		reaction_timer=0.3
		recovered.emit(position)
		return true
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
