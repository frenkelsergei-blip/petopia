class_name BallGame
extends Node2D
## The player controls the child and the throw. The companion handles fetch.

signal updated(text: String)
signal finished(catches: int, throws: int)

const PLAY_LEFT = 390.0
const PLAY_RIGHT = 530.0
const FLIGHT_SECONDS = 1.8
const PET_HOME = Vector2(385,288)
var game: GameState
var practice = true
var throws = 0
var catches = 0
var phase = 0.0
var aim_time = 0.0
var done = false
var waiting = false
var in_flight = false
var retry_save = false
var bringing_back = false
## Seconds since Foxy let go of the ball at the child's feet (-1: not dropping).
var drop_time = -1.0
var drop_from = Vector2.ZERO
const DROP_SECONDS = 0.7
## The ball came back this turn (dropped at the child's feet, then in hand).
var returned = false
## Thrown inside Foxy's reach (the gold band, with a little slack).
var catchable = false
var throw_from = 0.0
var throw_animation = 0.0
var landing_x = 460.0
var throw_start = Vector2.ZERO
## P52: the child winds up before letting go (the flight waits for it).
const WINDUP=0.24
var windup = 0.0
## Paper puppets: hand and mouth come from the drawings themselves.
func paper() -> bool:
	return is_instance_valid(child.puppet) and is_instance_valid(foxy.puppet) and not child.puppet.frames_data.is_empty()
var session = GameState.event_id("ball")
var child: GrayboxActor
var foxy: GrayboxActor
var background: GardenPlayground
var camera: Camera2D
## Visible world height (the full-screen stage trims sky on wide screens).
var view_height=360.0

func _ready() -> void:
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	process_mode = Node.PROCESS_MODE_PAUSABLE
	background = GardenPlayground.new()
	background.reduced_motion = game.state.settings.reduced_motion
	add_child(background)
	child = GrayboxActor.new()
	child.kind = "child"
	child.position = Vector2(145,288)
	child.scale = Vector2(2,2)
	child.reduced_motion = background.reduced_motion
	add_child(child)
	foxy = GrayboxActor.new()
	foxy.position = Vector2(450,288)
	foxy.scale = Vector2(2,2)
	foxy.child_stage = game.pet().growth_stage != "baby"
	foxy.collar = game.pet().equipped_items.has("collar")
	foxy.reduced_motion = background.reduced_motion
	add_child(foxy)
	camera=Camera2D.new()
	camera.process_callback=Camera2D.CAMERA2D_PROCESS_IDLE
	camera.position=Vector2(320,180)
	add_child(camera)
	updated.emit("Practice: you throw. Foxy chases, catches and brings the ball back.")

## Throw distance in front of the child: the aim bar picks it, and walking
## forward or back moves where it lands. Foxy wanders across the garden while
## you aim, so the catch spot (gold band) moves; the practice throw is easy.
const AIM_SPEED=2.3
const MIN_THROW=185.0
const MAX_THROW=445.0
const CATCH_REACH=24.0
const PRACTICE_REACH=60.0
func aim_fraction() -> float:
	return (sin(aim_time*AIM_SPEED-PI/2)+1.0)/2.0

func target_x() -> float:
	return child.position.x+lerpf(MIN_THROW,MAX_THROW,aim_fraction())

func reach() -> float:
	return PRACTICE_REACH if practice else CATCH_REACH

## Where Foxy waits (and where its mouth catches) at a given aiming time.
func foxy_wait_x(time: float) -> float:
	return 450.0 if practice else 480.0+sin(time*0.9)*70.0
func catch_x() -> float:
	return foxy.position.x+8*foxy.scale.x

## The gold band on the aim bar, as fractions of the throw range.
func band() -> Vector2:
	var span=MAX_THROW-MIN_THROW
	var center=(catch_x()-child.position.x-MIN_THROW)/span
	return Vector2(center-reach()/span,center+reach()/span)

func in_throw_zone() -> bool:
	return absf(target_x()-catch_x())<=reach()

## Aiming time at which the throw lands right in Foxy's mouth (for tests).
func aim_time_for_catch() -> float:
	var f=clampf((catch_x()-child.position.x-MIN_THROW)/(MAX_THROW-MIN_THROW),0.0,1.0)
	return (asin(f*2.0-1.0)+PI/2)/AIM_SPEED

func _process(delta: float) -> void:
	if done or retry_save: return
	throw_animation = maxf(0,throw_animation-delta)
	if drop_time>=0:
		drop_time+=delta
		if drop_time>=DROP_SECONDS: drop_time=-1.0
	child.mood = "throw" if throw_animation>0 else "idle"
	if paper():
		# Ball in hand: ready pose; wind-up, release, follow-through.
		if windup>0: child.mood="windup"
		elif throw_animation>0: child.mood="throw"
		elif not in_flight and not waiting and drop_time<0: child.mood="hold"
	if in_flight and windup>0:
		windup-=delta
		if windup<=0:
			# Let go from the hand of the release drawing.
			child.mood="throw"
			child.puppet.show_frame("throw",0)
			throw_start=child.puppet.anchor_global()
			throw_animation=0.4
		foxy.mood="idle"
		queue_redraw()
	elif in_flight:
		# With the wind-up the whole throw still takes FLIGHT_SECONDS.
		phase = minf(1.0,phase+delta/(FLIGHT_SECONDS-(WINDUP if paper() else 0.0)))
		# Foxy jumps for it but can only stretch so far.
		var goal=Vector2(clampf(landing_x-8*foxy.scale.x,throw_from-reach(),throw_from+reach()),288)
		foxy.position=foxy.position.move_toward(goal,delta*240)
		foxy.position.y=288-sin(clampf((phase-0.65)/0.35,0,1)*PI)*12
		foxy.mood="run"
		foxy.facing=1 if phase>=0.65 else signf(goal.x-foxy.position.x)
		# The leap: Foxy stretches up, mouth open, as the ball comes down.
		if paper() and phase>=0.62 and catchable: foxy.mood="catch"
		if phase>=1.0:
			resolve_throw(catchable and ball_position().distance_to(foxy_mouth())<=17)
	elif waiting:
		var goal=child.position+Vector2(35,0) if bringing_back else Vector2(foxy_wait_x(0.0),288)
		foxy.facing=signf(goal.x-foxy.position.x)
		foxy.position=foxy.position.move_toward(goal,delta*240)
		foxy.mood="run" if foxy.position.distance_to(goal)>2 else "happy"
		if paper() and foxy.mood=="happy": foxy.mood="carry" if bringing_back else "sit"
		if foxy.position.distance_to(goal)<1:
			if bringing_back:
				bringing_back=false
				# Foxy lets go: the ball drops and bounces at the child's feet.
				drop_from=foxy_mouth()
				drop_time=0.0
				Sound.play("bounce",0.08)
				returned=true
				updated.emit("Ball returned! Foxy is getting ready for your next throw.")
			else:
				waiting=false
				aim_time=0
				updated.emit("Your turn: Space / E to throw when the marker is in the gold band.")
	else:
		aim_time+=delta
		child.position.x=clampf(child.position.x+Input.get_axis("move_left","move_right")*90*delta,60,300)
		var wander=foxy_wait_x(aim_time)
		foxy.travel_speed=absf(wander-foxy.position.x)/maxf(delta,0.001)
		foxy.mood="run" if absf(wander-foxy.position.x)>0.05 else "idle"
		foxy.position.x=wander
		foxy.facing=-1
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact"): throw_ball()
	child.travel_speed=absf(Input.get_axis("move_left","move_right"))*80 if not in_flight and not waiting else 0.0
	if child.travel_speed>0 and throw_animation<=0: child.mood="run"
	if in_flight or waiting: foxy.travel_speed=240.0
	foxy.grounded=foxy.position.y>=287.5
	if not foxy.grounded and foxy.mood!="catch": foxy.mood="jump"
	# Portrait shows a closer playground. Keep both friends in view at rest,
	# follow the ball after the throwing pose, then return with Foxy.
	var half_width=get_viewport_rect().size.x*0.5
	var focus=(child.position.x+foxy.position.x)*0.5
	if in_flight: focus=lerpf(focus,landing_x,smoothstep(0.3,0.9,phase))
	var desired=clampf(focus,half_width,640-half_width)
	camera.position.x=move_toward(camera.position.x,desired,delta*260)
	# Keep the grass at the bottom edge; wide screens lose only sky.
	camera.position.y=360.0-view_height*0.5
	queue_redraw()

func throw_ball() -> bool:
	if retry_save:
		_save_result()
		return false
	if waiting or in_flight or done: return false
	landing_x=target_x()
	returned=false
	catchable=in_throw_zone()
	throw_from=foxy.position.x
	throw_start=child.position+Vector2(14,-19)*child.scale
	phase=0
	in_flight=true
	throw_animation=0.45
	child.mood="throw"
	if paper():
		windup=WINDUP
		throw_animation=0.0
		child.mood="windup"
	Sound.play("throw")
	updated.emit("You threw the ball. Foxy is chasing it — no catch button needed!")
	return true

func resolve_throw(success: bool) -> void:
	in_flight=false
	if success:
		Sound.play("catch",0.03)
		Sound.play("fox_yip",0.08)
	else:
		Sound.play("bounce")
		Sound.play("miss",0.0,-4.0)
	foxy.position.y=288
	foxy.mood="happy" if success else "idle"
	if practice:
		practice=false
		updated.emit("Practice done! Now ten throws. You throw; Foxy catches automatically.")
	else:
		throws+=1
		if success: catches+=1
		updated.emit("%s • Throw %d / 10 • %d catches"%["Foxy caught it!" if success else "A good try! Aim for the gold band.",throws,catches])
	if throws>=10:
		_save_result()
		return
	waiting=true
	bringing_back=success

func _save_result() -> void:
	if game.minigame_result(session,catches,throws):
		done=true
		retry_save=false
		finished.emit(catches,throws)
	else:
		retry_save=true
		waiting=true
		updated.emit("Saving needs another try. Press Retry save.")

func ball_position() -> Vector2:
	if paper():
		if in_flight and windup>0: return child.puppet.anchor_global()
		if not in_flight and not (waiting and bringing_back) and drop_time<0 and not waiting: return child.puppet.anchor_global()
	if in_flight:
		var arc=throw_start.lerp(Vector2(landing_x,288-10*foxy.scale.y),phase)+Vector2(0,-sin(phase*PI)*100)
		# The last moment homes in on Foxy's mouth so the catch lands in it.
		return arc.lerp(foxy_mouth(),smoothstep(0.85,1.0,phase)) if catchable else arc
	if waiting and bringing_back: return foxy_mouth()
	var hand=child.position+Vector2(8,-13)*child.scale
	if paper(): hand=child.puppet.anchor_global()
	if drop_time>=0:
		var feet=child.position+Vector2(22,-6)
		var k=drop_time/DROP_SECONDS
		if k<0.6:
			# Fall from the mouth, one small bounce.
			var f=k/0.6
			return drop_from.lerp(feet,f)+Vector2(0,-absf(sin(f*PI*1.5))*10*(1.0-f))
		return feet.lerp(hand,smoothstep(0.6,1.0,k))
	return hand

## Where the ball sits while Foxy carries it: in front of the muzzle, below the eye.
func foxy_mouth() -> Vector2:
	if paper(): return foxy.puppet.anchor_global()
	# Leaping lifts the head up and forward.
	var offset=Vector2(10,-13) if foxy.position.y<287.5 else Vector2(8,-10)
	return foxy.position+Vector2(offset.x*foxy.facing,offset.y)*foxy.scale

func ball_carried() -> bool:
	return waiting and bringing_back
