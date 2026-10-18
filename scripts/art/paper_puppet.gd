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
var shadows: Dictionary={}
var rest: Dictionary={}
var root: Node2D
var shadow_root: Node2D
static var _rigs: Dictionary={}

static func rig(name: String) -> Dictionary:
	if not _rigs.has(name): _rigs[name]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/paper-v1/%s.json"%name))
	return _rigs[name]

func _ready() -> void:
	shadow_root=Node2D.new()
	add_child(shadow_root)
	root=Node2D.new()
	add_child(root)
	for p in rig(who).parts:
		var tex: Texture2D=ArtTexture.load_texture("res://assets/art/paper-v1/%s.png"%p.name)
		for layer in [shadow_root,root]:
			var s=Sprite2D.new()
			s.texture=tex
			s.centered=false
			s.offset=-Vector2(p.pivot[0],p.pivot[1])
			s.position=Vector2(p.at[0],p.at[1])
			s.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
			s.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
			if layer==shadow_root:
				s.modulate=Color(0.12,0.07,0.04,0.32)
				shadows[p.name]=s
			else: parts[p.name]=s
			layer.add_child(s)
		rest[p.name]=Vector2(p.at[0],p.at[1])

func _process(delta: float) -> void:
	if not reduced_motion: t+=delta
	gait+=travel_speed*delta*(0.11 if who=="explorer" else 0.14)
	var k=height/float(rig(who).height)
	scale=Vector2(k*facing,k)
	pose()
	# Paper shadow: the same pieces, a little down and behind, softly dark.
	shadow_root.position=Vector2(5,7)/maxf(k,0.001)*0.12
	for n in parts:
		shadows[n].position=parts[n].position
		shadows[n].rotation=parts[n].rotation
		shadows[n].scale=parts[n].scale

func set_part(n: String, angle: float, lift=Vector2.ZERO) -> void:
	if not parts.has(n): return
	parts[n].rotation=deg_to_rad(angle)
	parts[n].position=rest[n]+lift

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
			arm_f=-125.0
			arm_b=-95.0
			bob=Vector2(0,-6)
		elif mood=="happy":
			arm_f=-150.0+sin(t*12.0)*18.0
			arm_b=-140.0
			bob=Vector2(0,-absf(sin(t*6.0))*10.0)
		elif mood=="throw":
			arm_f=-120.0
		else:
			arm_f=breathe*3.0
			arm_b=-breathe*3.0
		set_part("ex_leg_front",leg_f,bob*0.3)
		set_part("ex_leg_back",leg_b,bob*0.3)
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
			front=s*32.0
			hind=-s*32.0
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
		elif mood=="sleep":
			front=-70.0
			hind=70.0
			head=12.0
			bob=Vector2(0,40)
		set_part("fx_leg_front_near",front,bob*0.3)
		set_part("fx_leg_front_far",-front*0.8,bob*0.3)
		set_part("fx_leg_hind_near",hind,bob*0.3)
		set_part("fx_leg_hind_far",-hind*0.8,bob*0.3)
		set_part("fx_body",-2.0 if run else 0.0,bob)
		set_part("fx_head",head,bob)
		set_part("fx_tail",tail,bob)
