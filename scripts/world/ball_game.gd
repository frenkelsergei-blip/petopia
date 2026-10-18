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
var throw_animation = 0.0
var landing_x = 460.0
var throw_start = Vector2.ZERO
var session = GameState.event_id("ball")
var child: GrayboxActor
var foxy: GrayboxActor
var background: GardenPlayground
var camera: Camera2D
## Visible world height (the full-screen stage trims sky on wide screens).
var view_height=360.0

## Pixel Foxy carry frames (A52): running back with the sun ball in its mouth.
var carry_frames: Array[AtlasTexture]=[]
var carry_pivot=Vector2.ZERO
var carry_body=1.0
func _load_carry() -> void:
	var meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/pet-v2/frames.json"))
	var sheet: Texture2D=ArtTexture.load_texture("res://assets/art/pet-v2/carry.png")
	for f in meta.sets.carry:
		var atlas=AtlasTexture.new()
		atlas.atlas=sheet
		atlas.region=Rect2(f.region[0],f.region[1],f.region[2],f.region[3])
		carry_frames.append(atlas)
	var first: Dictionary=meta.sets.carry[0]
	carry_pivot=Vector2(first.pivot[0]-first.region[0],first.pivot[1]-first.region[1])
	carry_body=float(meta.sets.eat[1].content[3])

func ball_carried_in_art() -> bool:
	return ArtStyle.enabled and not carry_frames.is_empty() and ball_carried()

func _ready() -> void:
	_load_carry()
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
	foxy.position = PET_HOME
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

func aim_fraction() -> float:
	return (sin(aim_time*1.7-PI/2)+1.0)/2.0

func target_x() -> float:
	return lerpf(330,590,aim_fraction())

func in_throw_zone() -> bool:
	return target_x()>=PLAY_LEFT and target_x()<=PLAY_RIGHT

func _process(delta: float) -> void:
	if done or retry_save: return
	foxy.home_pose=null
	throw_animation = maxf(0,throw_animation-delta)
	if drop_time>=0:
		drop_time+=delta
		if drop_time>=DROP_SECONDS: drop_time=-1.0
	child.mood = "throw" if throw_animation>0 else "idle"
	if in_flight:
		phase = minf(1.0,phase+delta/FLIGHT_SECONDS)
		var goal=Vector2(clampf(landing_x,PLAY_LEFT,PLAY_RIGHT)-8*foxy.scale.x,288)
		foxy.position=foxy.position.move_toward(goal,delta*240)
		foxy.position.y=288-sin(clampf((phase-0.65)/0.35,0,1)*PI)*12
		foxy.mood="run"
		foxy.facing=1 if phase>=0.65 else signf(goal.x-foxy.position.x)
		if phase>=1.0:
			resolve_throw(catchable and ball_position().distance_to(foxy_mouth())<=17)
	elif waiting:
		var goal=child.position+Vector2(35,0) if bringing_back else PET_HOME
		foxy.facing=signf(goal.x-foxy.position.x)
		foxy.position=foxy.position.move_toward(goal,delta*240)
		foxy.mood="run" if foxy.position.distance_to(goal)>2 else "happy"
		# Running back with the ball: the carry frames have it in Foxy's mouth.
		if bringing_back and ArtStyle.enabled and not carry_frames.is_empty():
			foxy.mood="carry"
			foxy.home_pose=carry_frames[int(foxy.position.x/18.0)%2]
			foxy.home_pose_pivot=carry_pivot
			foxy.home_pose_body_height=carry_body
			foxy.home_pose_flip=foxy.facing<0
		if foxy.position.distance_to(goal)<1:
			if bringing_back:
				bringing_back=false
				# Foxy lets go: the ball drops and bounces at the child's feet.
				drop_from=foxy_mouth()
				drop_time=0.0
				returned=true
				updated.emit("Ball returned! Foxy is getting ready for your next throw.")
			else:
				waiting=false
				aim_time=0
				updated.emit("Your turn: Space / E to throw when the marker is in the gold band.")
	else:
		aim_time+=delta
		child.position.x=clampf(child.position.x+Input.get_axis("move_left","move_right")*80*delta,95,205)
		foxy.mood="idle"
		foxy.facing=-1
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact"): throw_ball()
	child.travel_speed=absf(Input.get_axis("move_left","move_right"))*80 if not in_flight and not waiting else 0.0
	if child.travel_speed>0 and throw_animation<=0: child.mood="run"
	foxy.travel_speed=240.0 if in_flight or waiting else 0.0
	foxy.grounded=foxy.position.y>=287.5
	if not foxy.grounded: foxy.mood="jump"
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
	catchable=absf(clampf(landing_x,PLAY_LEFT,PLAY_RIGHT)-landing_x)<=17
	throw_start=child.position+Vector2(14,-19)*child.scale
	phase=0
	in_flight=true
	throw_animation=0.45
	child.mood="throw"
	updated.emit("You threw the ball. Foxy is chasing it — no catch button needed!")
	return true

func resolve_throw(success: bool) -> void:
	in_flight=false
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
	if in_flight:
		var arc=throw_start.lerp(Vector2(landing_x,288-10*foxy.scale.y),phase)+Vector2(0,-sin(phase*PI)*100)
		# The last moment homes in on Foxy's mouth so the catch lands in it.
		return arc.lerp(foxy_mouth(),smoothstep(0.85,1.0,phase)) if catchable else arc
	if waiting and bringing_back: return foxy_mouth()
	var hand=child.position+Vector2(8,-13)*child.scale
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
	# Leaping lifts the head up and forward.
	var offset=Vector2(10,-13) if foxy.position.y<287.5 else Vector2(8,-10)
	return foxy.position+Vector2(offset.x*foxy.facing,offset.y)*foxy.scale

func ball_carried() -> bool:
	return waiting and bringing_back
