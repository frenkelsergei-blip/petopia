class_name PaperPuppet
extends Node2D
## A55 paper puppet: cut-out parts pinned at their joints (assets/art/paper-v1,
## rigs from tools/build_paper_rigs.py), animated procedurally so movement has
## a handmade, slightly springy feel. Feet at the origin, facing right.

var who="explorer"
var height=42.0
var facing=1.0
var mood="idle"
var travel_speed=0.0
var grounded=true
var reduced_motion=false
var t=0.0
var gait=0.0
var parts: Dictionary={}
var rest: Dictionary={}
var root: Node2D
static var _rigs: Dictionary={}
const AUTHORED={"explorer":428.0,"foxy":242.0}

static func rig(name: String) -> Dictionary:
	if not _rigs.has(name): _rigs[name]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/paper-v1/%s.json"%name))
	return _rigs[name]

## A55 frame-by-frame mode (tools/build_paper_frames.py): whole hand-made
## poses instead of rigid parts, when <who>-frames.json exists.
var frames_data: Dictionary={}
var frame_tex: Dictionary={}
var body: Sprite2D
var last_y=0.0
var vy=0.0
var was_air=false
var land_time=0.0
var takeoff_time=0.0
func frames_name() -> String: return "explorer" if who=="explorer" else "fox"
static var _frames: Dictionary={}
static func frames_of(name: String) -> Dictionary:
	if not _frames.has(name):
		# A57: the P31-style heroes first, then the earlier paper ones.
		var path="res://assets/art/heroes-p31/%s-frames.json"%name
		if not FileAccess.file_exists(path): path="res://assets/art/paper-v1/%s-frames.json"%name
		_frames[name]=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return _frames[name]

func _ready() -> void:
	frames_data=frames_of(frames_name())
	if not frames_data.is_empty():
		body=Sprite2D.new()
		body.centered=false
		body.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		body.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(body)
		for set_name in frames_data.sets:
			for f in frames_data.sets[set_name]:
				var dir="res://assets/art/heroes-p31/frames/" if ResourceLoader.exists("res://assets/art/heroes-p31/frames/"+String(f.file)) else "res://assets/art/paper-v1/frames/"
				frame_tex[f.file]=ArtTexture.load_texture(dir+String(f.file))
		return
	root=Node2D.new()
	add_child(root)
	for p in rig(who).parts:
		var tex: Texture2D=ArtTexture.load_texture("res://assets/art/paper-v1/%s.png"%p.name)
		for layer in [root]:
			var s=Sprite2D.new()
			s.texture=tex
			s.centered=false
			s.offset=-Vector2(p.pivot[0],p.pivot[1])
			s.position=Vector2(p.at[0],p.at[1])
			s.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			s.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
			parts[p.name]=s
			# P18 character shading: warm light on the near side, the far limbs
			# a darker paper layer behind.
			s.modulate=Color(1.06,1.03,0.97)
			if String(p.name).ends_with("_far") or String(p.name).ends_with("_back"): s.modulate=Color(0.72,0.66,0.64)
			layer.add_child(s)
		rest[p.name]=Vector2(p.at[0],p.at[1])

func _process(delta: float) -> void:
	if not reduced_motion: t+=delta
	gait+=travel_speed*delta*(0.11 if who=="explorer" else 0.14)
	distance+=travel_speed*delta/maxf(height/float(frames_data.get("height",1.0)),0.001) if not frames_data.is_empty() else 0.0
	if not frames_data.is_empty():
		play_frames(delta)
		return
	var k=height/float(rig(who).height)
	scale=Vector2(k*facing,k)
	pose()

## Picks the hand-made pose for the current state. Runs advance with distance
## (one cycle per stride, so feet never slide); jumps use take-off, rise, fall
## and a short landing squash; care moods map to the nearest pose.
func show_frame(set_name: String, index: int) -> void:
	var list: Array=frames_data.sets.get(set_name,frames_data.sets.idle)
	var f: Dictionary=list[index%list.size()]
	body.texture=frame_tex[f.file]
	body.offset=-Vector2(f.pivot[0],f.pivot[1])
func play_frames(delta: float) -> void:
	var k=height/float(frames_data.height)
	scale=Vector2(k*facing,k)
	var y=global_position.y
	if delta>0: vy=lerpf(vy,(y-last_y)/delta,0.5)
	last_y=y
	var air=not grounded
	if air and not was_air: takeoff_time=0.12
	if was_air and not air: land_time=0.14
	was_air=air
	takeoff_time=maxf(0,takeoff_time-delta)
	land_time=maxf(0,land_time-delta)
	body.rotation=0.0
	body.position=Vector2.ZERO
	if air:
		show_frame("takeoff" if takeoff_time>0 else ("rise" if vy<0 else "fall"),0)
		return
	if land_time>0:
		show_frame("land",0)
		return
	match mood:
		"run":
			# One 8-frame cycle per stride of the character's own size.
			# About 2.5 strides a second at full speed (12-20 drawings a second), so
			# the legs read as running, not stepping.
			var stride=float(frames_data.height)*(0.85 if who=="explorer" else 1.15)
			var n=frames_data.sets.run.size()
			show_frame("run",int(floor(distance/stride*n))%n)
		"happy","bath": show_frame("happy",0)
		"shake":
			show_frame("happy",0)
			body.rotation=0.0 if reduced_motion else sin(t*38.0)*0.12
		"use","throw","pour","pet": show_frame("use" if frames_data.sets.has("use") else "idle",0)
		"dig","ability","eat","drink": show_frame("dig" if frames_data.sets.has("dig") else "idle",0)
		"jump": show_frame("rise",0)
		_: show_frame("idle",0 if reduced_motion else int(t/0.6)%2)
var distance=0.0

func set_part(n: String, angle: float, lift=Vector2.ZERO) -> void:
	if not parts.has(n): return
	parts[n].rotation=deg_to_rad(angle)
	# Pose offsets are authored in the original rig units (before rescale).
	parts[n].position=rest[n]+lift*float(rig(who).height)/AUTHORED[who]

func pose() -> void:
	var run=mood=="run" and grounded
	var air=not grounded or mood=="jump"
	var s=sin(gait*TAU)
	var c=cos(gait*TAU)
	var breathe=0.0 if reduced_motion else sin(t*2.2)
	if who=="explorer":
		var bob=Vector2(0,-absf(s)*14.0) if run else Vector2(0,breathe*3.0)
		var arm_f=0.0
		var arm_b=0.0
		var leg_f=0.0
		var leg_b=0.0
		var head=breathe*1.5
		if run:
			leg_f=s*30.0
			leg_b=-s*30.0
			arm_f=-s*28.0
			arm_b=s*28.0
			head=-4.0+c*2.0
		elif air:
			leg_f=-28.0
			leg_b=22.0
			arm_f=-70.0
			arm_b=-45.0
			bob=Vector2(0,-6)
		elif mood=="happy":
			arm_f=-95.0+sin(t*12.0)*15.0
			arm_b=-60.0
			bob=Vector2(0,-absf(sin(t*6.0))*10.0)
		elif mood=="throw":
			arm_f=-120.0
		elif mood=="pour":
			# Holding the bag or can out in front, tipping it a little.
			arm_f=-78.0+(0.0 if reduced_motion else sin(t*5.0)*6.0)
			arm_b=-30.0
			head=8.0
		elif mood=="pet":
			arm_f=-55.0+(0.0 if reduced_motion else sin(t*7.0)*14.0)
			head=6.0
		else:
			arm_f=breathe*3.0
			arm_b=-breathe*3.0
		set_part("ex_leg_front",leg_f,bob)
		set_part("ex_leg_back",leg_b,bob)
		set_part("ex_torso",-3.0 if run else 0.0,bob)
		set_part("ex_head",head,bob)
		set_part("ex_arm_front",arm_f,bob)
		set_part("ex_arm_back",arm_b,bob)
	else:
		var bob=Vector2(0,-absf(s)*16.0) if run else Vector2(0,breathe*3.0)
		var front=0.0
		var hind=0.0
		var tail=(sin(t*3.0)*8.0 if not reduced_motion else 0.0)
		var head=breathe*2.0
		if run:
			# Trot: diagonal pairs move together (near front with far hind).
			front=s*24.0
			hind=-s*24.0
			tail=-10.0+c*10.0
			head=c*3.0
		elif air:
			front=-35.0
			hind=35.0
			tail=-18.0
			bob=Vector2(0,-8)
		elif mood=="happy":
			tail=sin(t*16.0)*22.0
			bob=Vector2(0,-absf(sin(t*7.0))*14.0)
			head=-6.0
		elif mood in ["ability","dig"]:
			head=22.0
			front=sin(t*18.0)*28.0-10.0
			bob=Vector2(0,6)
		elif mood=="eat":
			# Head down in the bowl, nibbling.
			head=34.0+(0.0 if reduced_motion else absf(sin(t*9.0))*10.0)
			front=-12.0
			bob=Vector2(0,5)
			tail=sin(t*5.0)*10.0
		elif mood=="drink":
			# Quick laps from the water bowl.
			head=30.0+(0.0 if reduced_motion else sin(t*16.0)*5.0)
			front=-10.0
			bob=Vector2(0,5)
		elif mood=="bath":
			# Sitting in the tub, swaying happily in the bubbles.
			head=-8.0+(0.0 if reduced_motion else sin(t*4.0)*6.0)
			tail=sin(t*6.0)*16.0
			bob=Vector2(0,(0.0 if reduced_motion else sin(t*4.0)*3.0))
		elif mood=="shake":
			# The big wet-dog shake: the whole body wiggles fast.
			var w=0.0 if reduced_motion else sin(t*38.0)
			head=w*14.0
			tail=-w*30.0
			front=w*10.0
			hind=-w*10.0
			bob=Vector2(w*4.0,-2)
		elif mood=="sleep":
			front=-70.0
			hind=70.0
			head=12.0
			bob=Vector2(0,40)
		# Legs stay pinned to the body: they follow its bob fully.
		set_part("fx_leg_front_near",front,bob)
		set_part("fx_leg_front_far",-front,bob)
		set_part("fx_leg_hind_near",-front if run else hind,bob)
		set_part("fx_leg_hind_far",front if run else -hind,bob)
		set_part("fx_body",-2.0 if run else 0.0,bob)
		set_part("fx_head",head,bob)
		set_part("fx_tail",tail,bob)
