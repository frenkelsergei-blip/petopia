class_name MeadowWorld
extends Node2D
## V2 connected Green Meadows (GDD V2 "Metroidvania connected world").
## Rooms come from data/world/green_meadows.json; progress lives in
## GameState.world(). Scenery is a seven-layer parallax built from separate
## transparent strips (GDD scroll factors), terrain is drawn from the meadow
## kit over plain rectangle colliders, and the child/Foxy reuse V1 actors.
signal status(message: String)
signal left_world
signal ability_learned(title: String, text: String)

const ART="res://assets/art/meadows-v2/"
## [layer, scroll factor, bottom as fraction of view height, height fraction]
const BACK=[["sky",0.05,1.15,1.35],["mountains",0.10,0.78,0.55],["hills",0.20,0.86,0.42],["town",0.35,0.95,0.40],["midground",0.60,1.06,0.74]]
const FRONT=["foreground",1.20,1.10,0.38]
## Hidden Cave depth: far cavern, distant formations, near pillars (each
## layer has hanging stalactites at its top and rocks at its bottom), and a
## dark foreground frame in front of the play area.
const CAVE_BACK=[["cave_far",0.08,1.0,1.0],["cave_back",0.20,1.0,1.0],["cave_mid",0.45,1.02,1.0]]
const PAPER_CAVE_BACK=[["cave_far",0.08,0.62,0.5],["cave_back",0.2,0.82,0.5],["cave_mid",0.45,1.0,0.5]]
const CAVE_FRONT=["cave_front",1.20,1.04,1.0]
## Piece: fraction of image height from its top to the walking surface.
const SURFACE={"ground_top":0.24,"float_big":0.2,"float_small":0.22,"stone_ledge":0.24,"crystal_ledge":0.3,"scaffold":0.08,"stone":0.12,"bridge":0.62,"cap_left":0.22,"cap_right":0.22}

var game: GameState
var reduced_motion=false
var room_id=""
var room: Dictionary
var title="Green Meadows"
var prompt=""
var player: Explorer
var companion: Companion
var camera: WorldCamera
var content: Node2D
var fade: ColorRect
var transitioning=false
var elapsed=0.0
var near: Dictionary={}
var safe_point=Vector2.ZERO
var opened_at: Dictionary={}
var textures: Dictionary={}
var crate_bodies: Array[StaticBody2D]=[]
var digging=""
var dig_until=0.0
var popped: Dictionary={}
## What the two context buttons do right now: action -> [caption, icon].
var faces={"interact":["Use","act_use"],"pet_ability":["Find","act_find"]}
const CRATE=24.0
## Challenge (kid-friendly): hearts are lost on thorns, critters and falls;
## at zero the child returns to the last lantern with full hearts and keeps
## everything collected. No game over.
const MAX_HEARTS=3
var hearts=MAX_HEARTS
var hurt_until=0.0
var critters: Array[Dictionary]=[]
const GATES={"home":"gate_home","meadow_fields":"gate_meadow","river_crossing":"gate_river"}
## Friendly critters per place: they bump you back gently; hop on top to make
## them dizzy for a moment. Flyers bob up and down on their path.
const CRITTERS={
	"hedgehog":{"art":"hedgehog","h":22.0,"speed":28.0,"fly":false,"anim":5.0,"stomp":"Boing! The hedgehog curls up for a moment.","bump":"The hedgehog bumped you! Hop on top of it."},
	"crab":{"art":"crab","h":20.0,"speed":22.0,"fly":false,"anim":6.0,"stomp":"Boing! The crystal crab takes a little nap.","bump":"The crystal crab pinched you! Hop on top of it."},
	"frog":{"art":"frog","h":20.0,"speed":26.0,"fly":false,"anim":3.0,"stomp":"Boing! The frog sits down, a bit dizzy.","bump":"The frog bumped you! Hop on top of it."},
	"bat":{"art":"bat","h":20.0,"speed":34.0,"fly":true,"anim":8.0,"stomp":"Boing! The bat flips over, dizzy.","bump":"The bat flapped into you! Jump on it or wait for it to pass."},
	"bee":{"art":"bee","h":18.0,"speed":26.0,"fly":true,"anim":10.0,"stomp":"Boing! The bumblebee buzzes in circles.","bump":"The bumblebee bumped you! Jump on it or wait for it to pass."}}
var movers: Array[Dictionary]=[]
var crumbles: Array[Dictionary]=[]
var arrival_title=""
var entry_point=Vector2.ZERO
var bridge_progress=1.0
var moss: PicnicResident
var lag_time=0.0
var regrow_at: Dictionary={}
var super_jump=false
## Crates stay in the bag until you choose "Place a crate" there; only then
## does Use become Place with a see-through crate in front of you.
var placing=false
var crank_angle=0.0
var bridge_body: StaticBody2D
var plate_gates: Dictionary={}
var leaves: Array[Vector3]=[]
var arrival_until=0.0
signal hearts_changed(value: int)

class WorldCamera extends FollowCamera:
	var course_height=360.0
	## Smooth view: follow the child's interpolated (on-screen) position every
	## rendered frame, so the parallax layers drawn from this camera never
	## shake against the screen.
	func _init() -> void:
		super._init()
		process_callback=Camera2D.CAMERA2D_PROCESS_IDLE
		physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var prev_at=Vector2.ZERO
	var cur_at=Vector2.ZERO
	# Runs after the child moved (priority 100): remember the last two steps.
	func _physics_process(_delta: float) -> void:
		if not is_instance_valid(target): return
		prev_at=cur_at
		cur_at=target.position
	func _process(_delta: float) -> void: follow_target()
	func _ready() -> void:
		limit_left=0
		limit_right=int(course_width)
		limit_top=0
		limit_bottom=int(course_height)
		snap_to_target()
	## Horizontal follow as V1; vertical follow only outside a small dead zone,
	## so ordinary jumps do not bob the view but tall rooms scroll.
	func follow_target() -> void:
		if not is_instance_valid(target): return
		var half=get_viewport_rect().size*0.5/zoom
		if cur_at==Vector2.ZERO or cur_at.distance_to(target.position)>60:
			prev_at=target.position
			cur_at=target.position
		var at: Vector2=prev_at.lerp(cur_at,Engine.get_physics_interpolation_fraction())
		# The HUD covers the top of the screen: keep the child in the lower middle.
		# Tall rooms: the child about three quarters down, the floor above in view.
		var want_y=clampf(at.y-(56.0 if course_height<=400.0 else half.y*0.5),half.y,course_height-half.y)
		var y=position.y
		if absf(want_y-y)>14: y=lerpf(y,want_y-signf(want_y-y)*14.0,clampf(get_process_delta_time()*8.0,0.0,1.0))
		position=Vector2(clampf(at.x,half.x,course_width-half.x),clampf(y,half.y,course_height-half.y))
	func snap_to_target() -> void:
		if not is_instance_valid(target): return
		var half=get_viewport_rect().size*0.5/zoom
		prev_at=target.position
		cur_at=target.position
		position=Vector2(clampf(target.position.x,half.x,course_width-half.x),clampf(target.position.y-56,half.y,course_height-half.y))
		reset_physics_interpolation()
		reset_smoothing()

## A55: paper-theater pieces replace the pixel ones of the same role.
const PAPER_ART="res://assets/art/paper-v1/"
const PAPER={"ground_top":"ground_top","earth":"earth","cap_left":"cap_left","cap_right":"cap_right","float_big":"float_big","float_small":"float_small","bridge":"bridge","stone":"stone","crate":"crate","chest":"chest","chest_open":"chest_open","lantern":"lantern","lantern_unlit":"lantern","lantern_lit":"lantern_lit","fence":"fence","windmill":"windmill","windmill_sails":"windmill_sails","sign":"signpost","flower_bush":"flowers","boulder":"stone","lamp":"lantern_lit","sky":"sky"}
const PAPER_SURFACE={"ground_top":0.2,"cap_left":0.13,"cap_right":0.13,"float_big":0.13,"float_small":0.12,"bridge":0.35,"cave_ground":0.18}
func tex(name: String) -> Texture2D:
	if not textures.has(name):
		var path=ART+name+".png"
		if ArtStyle.paper:
			var paper_name: String=PAPER.get(name,name)
			if ResourceLoader.exists(PAPER_ART+paper_name+".png"): path=PAPER_ART+paper_name+".png"
			# Green Meadows from concept P31 (torn-paper collage) where it has the piece.
			var p31: String=P31.get(name,name)
			# A57: every room draws from the current world style when it has the piece.
			if ResourceLoader.exists(P31_ART+p31+".png"): path=P31_ART+p31+".png"
			# Each environment has its own kit with the meadow's piece names
			# (same pipeline, its own concept): the room uses only that kit.
			var envdir=env_dir()
			if not envdir.is_empty():
				var en: String=ENV_NAMES.get(name,p31)
				if ResourceLoader.exists(envdir+name+".png"): path=envdir+name+".png"
				elif ResourceLoader.exists(envdir+en+".png"): path=envdir+en+".png"
		textures[name]=ArtTexture.load_texture(path)
		used_art[room_id+"|"+name]=path
	return textures[name]
## Every world picture drawn this run (tools/audit_world_art.gd checks that
## all of them come from the current world style).
static var used_art: Dictionary={}
const P31_ART="res://assets/art/meadow-p31/"
## Piece names the room asks for -> the environment kit's names.
const ENV_NAMES={"tower_arch_open":"door","tower_arch_unlocked":"door","tower_arch_locked":"door_locked","wall_closed":"gate_closed","wall_open":"gate_open","stone":"ground_top","stone_fill":"earth","ce_ground":"ground_top","ce_fill":"earth","log_platform":"float_big","lantern":"checkpoint","lantern_lit":"checkpoint","thorns":"crystals","cave":"exit","crystals":"crystals","cave_vines":"vines","flag_up":"checkpoint","flag_down":"checkpoint","sign":"signpost","crumble":"crumble","crystal_ledge":"float_big","stone_ledge":"float_big","cave_ground":"ground_top","cave_fill":"earth","mound":"dig","mound_glint":"dig","shrine":"shrine","shrine_empty":"shrine_empty","flower_bush":"mushrooms","boulder":"stone","fern":"crystals"}
func env_dir() -> String:
	var env={"cave":"cave"}.get(room.get("scenery","meadow"),"")
	if room_id in ["windmill_cellar","windmill_vault"]: env="cellar"
	elif room.get("scenery","")=="tower": env="tower"
	var d="res://assets/art/meadow-p31/%s/"%env
	return d if not env.is_empty() and ResourceLoader.exists(d+"ground_top.png") else ""
const P31={"float_small":"float_big","sign":"signpost","flag_up":"flag","flag_down":"flag","flower_bush":"flowers","boulder":"stone","lamp":"bush"}
const P31_SURFACE={"ce_ground":0.08,"cave_ground":0.08,"stone":0.06,"stone_ledge":0.08,"crystal_ledge":0.38,"scaffold":0.04,"ground_top":0.22,"cap_left":0.03,"cap_right":0.03,"float_big":0.035,"float_small":0.035,"bridge":0.3}
const KIT_SURFACE={"tower":{"ground_top":0.015,"stone":0.015,"cap_left":0.03,"cap_right":0.03,"float_big":0.04,"stone_ledge":0.04,"crumble":0.07,"scaffold":0.03},"cellar":{"ground_top":0.01,"ce_ground":0.01,"stone":0.01,"cap_left":0.14,"cap_right":0.14,"float_big":0.05,"stone_ledge":0.05,"crumble":0.05,"scaffold":0.05},"cave":{"ground_top":0.28,"cave_ground":0.28,"cap_left":0.15,"cap_right":0.15,"float_big":0.37,"crystal_ledge":0.37,"stone_ledge":0.37,"crumble":0.03}}
func surface(name: String) -> float:
	var kit=env_dir()
	if ArtStyle.paper and not kit.is_empty():
		var ks: Dictionary=KIT_SURFACE.get(kit.get_slice("/",5),{})
		if ks.has(name): return ks[name]
	if ArtStyle.paper and P31_SURFACE.has(name) and ResourceLoader.exists(P31_ART+P31.get(name,name)+".png"): return P31_SURFACE[name]
	if ArtStyle.paper and PAPER_SURFACE.has(name): return PAPER_SURFACE[name]
	return float(SURFACE.get(name,0.2))

## Scenery is redrawn every rendered frame from the smooth camera.
func _process(_delta: float) -> void:
	if not is_instance_valid(content): return
	for node in content.get_children():
		if node is Node2D and node.name in ["Parallax","Walls","Terrain","Critters","Foreground","Painted","SetPieces","SetPiecesFront","Ladders"]: node.queue_redraw()

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_PAUSABLE
	var overlay=CanvasLayer.new()
	overlay.layer=5
	add_child(overlay)
	fade=ColorRect.new()
	fade.color=Color(0.05,0.08,0.14,0)
	fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fade)
	var w=game.world()
	enter(w.room,w.spawn)

## Build a room. Everything room-specific lives under `content`.
func enter(id: String, spawn: String) -> void:
	if not GameState.world_data().rooms.has(id): id=GameState.world_data().start[0]
	if not room_id.is_empty() and room_id!=id: bring_crates_along()
	var place: String=GameState.world_data().rooms[id].get("scenery","meadow")
	Sound.music("meadow" if place=="meadow" else "cave")
	placing=false
	foxy_holding={}
	found={}
	skipped=[]
	room_id=id
	room=GameState.world_data().rooms[id]
	if id=="windmill_vault": game.world_flag("cellar_gate_open")
	# Each environment has its own art kit: pictures are looked up per room.
	textures.clear()
	shadow_cache.clear()
	title=room.title
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content=Node2D.new()
	content.name="Room_"+id
	add_child(content)
	move_child(content,0)
	var size=Vector2(room.size[0],room.size[1])
	var spawns: Dictionary=room.spawns
	var at=spawns.get(spawn,spawns.values()[0])
	safe_point=Vector2(at[0],at[1])
	entry_point=safe_point
	# Strips must not wrap: with repeat on, each layer's top edge sampled its
	# own opaque bottom row and drew a dark line across the screen.
	var back=Node2D.new()
	back.name="Parallax"
	back.z_index=-10
	back.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	back.draw.connect(func(): draw_backdrop(back))
	content.add_child(back)
	var walls=Node2D.new()
	walls.name="Walls"
	walls.z_index=-9
	walls.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	walls.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	walls.draw.connect(func(): draw_walls(walls))
	content.add_child(walls)
	# Only true tiling fills repeat. Every other sprite draws with repeat off:
	# with it on, phones' odd scaling sampled each sprite's opposite edge and
	# drew thin dark lines along tops of ground strips, props and gates.
	# A60 (P71a): painted set pieces (the windmill cliff, burrow, bridge...)
	# stand behind the terrain strips; the ground follows their surfaces.
	if room.has("painted"):
		var pn=Node2D.new()
		pn.name="Painted"
		pn.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		pn.draw.connect(func(): draw_painted_play(pn))
		content.add_child(pn)
	var sets=Node2D.new()
	sets.name="SetPieces"
	sets.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sets.draw.connect(func(): draw_sets(sets,false))
	content.add_child(sets)
	var fills=Node2D.new()
	fills.name="TerrainFill"
	fills.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	fills.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	fills.draw.connect(func(): draw_fills(fills))
	content.add_child(fills)
	var ground=Node2D.new()
	ground.name="Terrain"
	ground.texture_repeat=CanvasItem.TEXTURE_REPEAT_DISABLED
	ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ground.draw.connect(func(): draw_room(ground))
	content.add_child(ground)
	# Set pieces marked "front" (burrow, gate, bridge) cover the plain ground
	# where they meet it, so their painted edges blend into the path.
	var sets_front=Node2D.new()
	sets_front.name="SetPiecesFront"
	sets_front.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sets_front.draw.connect(func(): draw_sets(sets_front,true))
	content.add_child(sets_front)
	# A60: ladders lean in front of the ledges they climb (above the terrain,
	# behind the characters).
	var ladder_layer=Node2D.new()
	ladder_layer.name="Ladders"
	ladder_layer.z_index=1
	ladder_layer.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ladder_layer.draw.connect(func(): for l in room.get("ladders",[]): draw_ladder(ladder_layer,l))
	content.add_child(ladder_layer)
	# Animals on their own layer above the terrain's grass edge, so their
	# ground ovals are not hidden under it.
	var critter_layer=Node2D.new()
	critter_layer.name="Critters"
	critter_layer.z_index=2
	critter_layer.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	critter_layer.draw.connect(func(): for c in critters: draw_critter(critter_layer,c))
	content.add_child(critter_layer)
	# A62: ramps (stairs) are sloped ground: [x0,y0,x1,y1] from one floor to the next.
	for rp in room.get("ramps",[]):
		var body=StaticBody2D.new()
		body.collision_layer=1
		body.collision_mask=0
		var cs=CollisionPolygon2D.new()
		var lo=maxf(float(rp[1]),float(rp[3]))
		cs.polygon=PackedVector2Array([Vector2(rp[0],rp[1]),Vector2(rp[2],rp[3]),Vector2(rp[2],lo+4),Vector2(rp[0],lo+4)])
		body.add_child(cs)
		content.add_child(body)
	var bridge_spec=room.get("bridge",[])
	bridge_progress=0.0 if bridge_locked() else 1.0
	# A63 painted rooms: walk lines follow the painted grass, stairs and log
	# ({pts:[[x,y]...], depth, one_way}); "logic" ground rects only describe
	# them for the guide arrow, hazards and checks (no collision, no drawing).
	for ln in room.get("lines",[]):
		var body=StaticBody2D.new()
		body.collision_layer=1
		body.collision_mask=0
		var poly=PackedVector2Array()
		var depth=float(ln.get("depth",30))
		for q in ln.pts: poly.append(Vector2(q[0],q[1]))
		for i in range(ln.pts.size()-1,-1,-1): poly.append(Vector2(ln.pts[i][0],ln.pts[i][1]+depth))
		var cp=CollisionPolygon2D.new()
		cp.polygon=poly
		cp.one_way_collision=bool(ln.get("one_way",false))
		body.add_child(cp)
		content.add_child(body)
	for r in rects("ground"):
		if ground_style(r)=="logic": continue
		var is_bridge=not bridge_spec.is_empty() and r==Rect2(bridge_spec[0],bridge_spec[1],bridge_spec[2],bridge_spec[3])
		if is_bridge and bridge_locked(): continue
		var made=collider(r,r.size.y<=20 and not is_bridge)
		if is_bridge: bridge_body=made
	if room.has("ceiling"):
		var c=room.ceiling
		collider(Rect2(c[0],c[1],c[2],c[3]))
	for gate in room.get("gates",[]):
		if not game.has_ability(gate.ability): collider(Rect2(gate.rect[0],gate.rect[1],gate.rect[2],gate.rect[3]))
	build_challenge()
	player=Explorer.new()
	player.position=safe_point
	player.air_jumps=1 if game.has_ability("foxy_boost") else 0
	# A60: ladders and climbing vines ([centre x, top, bottom]).
	player.ladders.clear()
	player.ladder_steps.clear()
	for l in room.get("ladders",[]):
		player.ladders.append(Rect2(float(l[0])-8.0,float(l[1]),16.0,float(l[2])-float(l[1])))
		player.ladder_steps.append(float(l[4]) if l.size()>4 else 0.0)
	player.boosted.connect(func(): boost_at=player.position; boost_until=elapsed+0.35)
	player.landed.connect(func(): dust(player.position,5,8.0))
	content.add_child(player)
	player.art.reduced_motion=reduced_motion
	companion=Companion.new()
	companion.recovered.connect(func(at: Vector2): dust(at,6,8.0))
	companion.leader=player
	companion.position=safe_point-Vector2(30,0)
	companion.anchor=safe_point
	companion.fall_limit=size.y+30
	companion.safe_anchors=safe_anchors()
	companion.jump_links=jump_links()
	content.add_child(companion)
	companion.art.child_stage=game.pet().growth_stage!="baby"
	companion.art.growth=game.pet().growth_stage
	companion.art.collar=game.pet().equipped_items.has("collar")
	companion.art.reduced_motion=reduced_motion
	build_crates()
	moss=null
	if room.has("npc"):
		moss=PicnicResident.new()
		moss.reduced_motion=reduced_motion
		moss.position=Vector2(room.npc.pos[0],room.npc.pos[1])
		content.add_child(moss)
	var front=Node2D.new()
	front.name="Foreground"
	front.z_index=4
	front.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	front.draw.connect(func():
		var scenery_kind: String=room.get("scenery","meadow")
		if scenery_kind=="cave" and not ArtStyle.paper: draw_layer(front,CAVE_FRONT)
		elif not ArtStyle.paper: draw_layer(front,FRONT)
		# (A55 close-up blurred layer removed after the play-test.)
		if ArtStyle.paper: draw_kit_front(front)
		draw_ambient(front))
	content.add_child(front)
	camera=WorldCamera.new()
	camera.target=player
	camera.course_width=size.x
	camera.course_height=size.y
	camera.position_smoothing_enabled=false
	# A60 (P71a): tall layered rooms show more at once (the floor above too).
	# Wide phones (landscape, about 2:1) keep full size: the characters stay
	# big and sharp; taller screens (tablets, desktop) see more of the floors.
	var ws=DisplayServer.window_get_size()
	var aspect=float(ws.x)/float(maxi(1,ws.y))
	camera.zoom=Vector2.ONE*(float(room.get("zoom",1.0)) if aspect<1.9 else 1.0)
	content.add_child(camera)
	camera.make_current()
	game.world_enter(id,spawn)
	arrival_title=room.title
	arrival_until=elapsed+1.6
	status.emit(room.title)

## Moving log rafts, crumbling stone and critters for this room.
func build_challenge() -> void:
	critters.clear()
	movers.clear()
	crumbles.clear()
	for c in room.get("critters",[]):
		var kind: String=c.get("kind","hedgehog")
		critters.append({"kind":kind,"x":float(c.x0),"x0":float(c.x0),"x1":float(c.x1),"y":float(c.y),"cy":float(c.y),"dir":1.0,"dizzy":0.0,"seed":float(c.x0)*0.01})
	for m in room.get("movers",[]):
		var r=Rect2(m.rect[0],m.rect[1],m.rect[2],m.rect[3])
		var body=AnimatableBody2D.new()
		body.sync_to_physics=true
		body.position=r.get_center()
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=r.size
		shape.shape=box
		shape.one_way_collision=true
		body.add_child(shape)
		content.add_child(body)
		movers.append({"body":body,"base":r.get_center(),"to":Vector2(m.to[0],m.to[1]),"period":float(m.period),"size":r.size})
	plate_gates.clear()
	for g in room.get("plate_gates",[]):
		var r=Rect2(g.rect[0],g.rect[1],g.rect[2],g.rect[3])
		var body=StaticBody2D.new()
		body.position=r.get_center()
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=r.size
		shape.shape=box
		body.add_child(shape)
		content.add_child(body)
		plate_gates[g.id]={"shape":shape,"rect":r,"open":false}
	for c in room.get("crumbles",[]):
		var r=Rect2(c[0],c[1],c[2],c[3])
		var body=StaticBody2D.new()
		body.position=r.get_center()
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=r.size
		shape.shape=box
		body.add_child(shape)
		content.add_child(body)
		crumbles.append({"body":body,"shape":shape,"rect":r,"timer":-1.0,"gone":0.0})

## Placed crates are solid boxes you can stand on (and stack two high).
func build_crates() -> void:
	for body in crate_bodies:
		if is_instance_valid(body): body.queue_free()
	crate_bodies.clear()
	for point in game.world().placed.get(room_id,[]):
		var body=StaticBody2D.new()
		body.position=Vector2(point[0],point[1]-CRATE*0.5)
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=Vector2(CRATE,CRATE)
		shape.shape=box
		body.add_child(shape)
		content.add_child(body)
		crate_bodies.append(body)

## A60 (P71a): a ground rect may carry a 5th entry, its look: "cliff" (ivy
## stone cliff), "under" (underground earth, no grass) or "log" (log bridge).
func ground_style(r: Rect2) -> String:
	for g in room.get("ground",[]):
		if g.size()>4 and Rect2(g[0],g[1],g[2],g[3])==r: return String(g[4])
	return ""
func rects(key: String) -> Array[Rect2]:
	var out: Array[Rect2]=[]
	for r in room.get(key,[]): out.append(Rect2(r[0],r[1],r[2],r[3]))
	return out

## Thin ledges are one-way: jump up through them from below, land on top.
func collider(rect: Rect2, one_way=false) -> StaticBody2D:
	var body=StaticBody2D.new()
	body.position=rect.get_center()
	body.collision_layer=1
	body.collision_mask=0
	var shape=CollisionShape2D.new()
	var box=RectangleShape2D.new()
	box.size=rect.size
	shape.shape=box
	shape.one_way_collision=one_way
	body.add_child(shape)
	content.add_child(body)
	return body

func safe_anchors() -> Array[Vector2]:
	var out: Array[Vector2]=[]
	for r in rects("ground"):
		var x=r.position.x+12
		while x<r.end.x-12:
			out.append(Vector2(x,r.position.y))
			x+=80
	return out

## Foxy follows across ledges a single jump apart (her own jump reaches ~48).
func jump_links() -> Array[Vector4]:
	var out: Array[Vector4]=[]
	var ground=rects("ground")
	for a in ground:
		for b in ground:
			if a==b: continue
			var rise=a.position.y-b.position.y
			if rise<-120 or rise>44: continue
			if b.position.x>=a.end.x-4 and b.position.x-a.end.x<=90:
				out.append(Vector4(a.end.x-6,a.position.y,b.position.x+14,b.position.y))
			elif b.end.x<=a.position.x+4 and a.position.x-b.end.x<=90:
				out.append(Vector4(a.position.x+6,a.position.y,b.end.x-14,b.position.y))
	return out

func view_rect() -> Rect2:
	var inverse=get_viewport().canvas_transform.affine_inverse()
	var size=Vector2(get_viewport().get_visible_rect().size)
	var a=inverse*Vector2.ZERO
	var b=inverse*size
	return Rect2(a,b-a)

## --- Parallax -------------------------------------------------------------
func draw_layer(canvas: CanvasItem, spec: Array, tint=Color.WHITE) -> void:
	var view=view_rect()
	var texture=tex(spec[0])
	var factor: float=spec[1]
	var height=view.size.y*float(spec[3])
	var width=height*texture.get_width()/texture.get_height()
	# Lower in the room = reference. Climbing moves far layers down slowly.
	var reference_top=float(room.size[1])-view.size.y
	var bottom=view.position.y+view.size.y*float(spec[2])-(view.position.y-reference_top)*factor*0.6
	var base=view.position.x*(1.0-factor)
	var first=floorf((view.position.x-base)/width)
	var x=base+first*width
	var shade=ArtStyle.paper and spec[0]!="sky" and not String(spec[0]) in ["mountains","hills","near"]
	# Paper flats stand a little apart: each casts a soft shadow behind it
	# (all shadows first, so a tile's shadow never darkens its neighbour).
	if shade:
		var sx=x
		while sx<view.end.x:
			paper_shadow(canvas,String(spec[0]),Rect2(sx,bottom-height,width+0.6,height),Vector2(3,4),0.35)
			sx+=width
	while x<view.end.x:
		canvas.draw_texture_rect(texture,Rect2(x,bottom-height,width+0.6,height),false,tint)
		x+=width

func draw_backdrop(canvas: CanvasItem) -> void:
	var view=view_rect()
	if room.has("painted"):
		draw_painted_back(canvas,view)
		return
	# P63 Treasure Vault: its own warm wall with beams and gears.
	if room_id=="windmill_vault" and has_piece("vault_far"):
		draw_room_layers(canvas,view,Color8(92,62,34),[["vault_far",0.12,0.82,0.8]],"")
		return
	if not env_dir().is_empty():
		draw_kit_backdrop(canvas,view)
		return
	match room.get("scenery","meadow"):
		"cave" when ResourceLoader.exists(P31_ART+"cv_far.png"):
			draw_room_layers(canvas,view,Color8(22,18,52),[["cv_far",0.08,0.75,0.75],["cv_mid",0.3,1.0,0.62]],"cv_top")
		"tower" when ResourceLoader.exists(P31_ART+"tw_far.png"):
			if room_id=="windmill_cellar" and ResourceLoader.exists(P31_ART+"ce_far.png"):
				draw_room_layers(canvas,view,Color8(92,62,34),[["ce_far",0.1,0.7,0.62],["ce_mid",0.35,1.0,0.55]],"")
			else:
				draw_room_layers(canvas,view,Color8(214,184,130),[["tw_far",0.12,0.95,0.95],["tw_mid",0.4,1.02,0.75]],"")
		"cave":
			if ArtStyle.paper:
				# A55 paper cave: deep indigo card, then three paper strips by depth.
				canvas.draw_rect(view.grow(4),Color8(28,24,62))
				for spec in PAPER_CAVE_BACK: draw_layer(canvas,spec)
			else:
				for spec in CAVE_BACK: draw_layer(canvas,spec)
		"tower": draw_tower_inside(canvas,view)
		_:
			if ArtStyle.paper: draw_paper_backdrop(canvas,view)
			else:
				for spec in BACK: draw_layer(canvas,spec)

## The nearest paper flat (P02 "foreground layer"): big leaves, ferns and
## flowers standing on the bottom of the screen in front of the play, moving
## faster than the world. Sparse, so the play stays readable.
const PAPER_FRONT=["fg_fern","fg_leaves","fg_bush","fg_grass","fg_flower","fg_rock","fg_mushroom","fg_blue"]
func draw_paper_front(canvas: CanvasItem) -> void:
	var view=view_rect()
	var factor=1.6
	var spacing=view.size.x*0.6
	var reach=view.size.x*0.5
	var first=int(floorf((view.position.x*factor-reach)/spacing))
	var last=int(ceilf((view.end.x*factor-view.position.x*(factor-1.0)+reach)/spacing))
	for i in range(first,last+1):
		var r1=fposmod(sin(i*12.9898)*43758.5453,1.0)
		var r2=fposmod(sin(i*78.233)*12543.137,1.0)
		if r1<0.4: continue
		var texture=tex(PAPER_FRONT[int(r2*PAPER_FRONT.size())%PAPER_FRONT.size()])
		var h=view.size.y*(0.2+0.1*r1)
		var w=h*texture.get_width()/texture.get_height()
		var x=i*spacing+r2*spacing*0.5-view.position.x*(factor-1.0)
		if x+w*0.5<view.position.x or x-w*0.5>view.end.x: continue
		var foot=Vector2(x,view.end.y+h*0.12)
		var sway=0.0 if reduced_motion else sin(elapsed*1.2+i*1.9)*0.025
		canvas.draw_set_transform(foot,sway,Vector2(-1.0 if r2>0.5 else 1.0,1.0))
		canvas.draw_texture_rect(texture,Rect2(-w*0.5,-h,w,h),false,Color(0.78,0.84,0.76))
	canvas.draw_set_transform(Vector2.ZERO)

## Layered paper river: the water strip tiled along, gently sliding.
func draw_paper_water(canvas: CanvasItem, r: Rect2) -> void:
	var water=tex("river_water")
	var h=26.0
	if room.get("scenery","meadow")=="meadow" and ResourceLoader.exists(P31_ART+"river_water.png"):
		# P31: the torn-paper river fills the whole channel, gently sliding.
		var th=r.size.y+10.0
		var tw=th*water.get_width()/water.get_height()
		var sl=0.0 if reduced_motion else fposmod(elapsed*10.0,tw)
		var xx=r.position.x-sl
		while xx<r.end.x:
			var left=maxf(0,r.position.x-xx)
			var cut=minf(tw,r.end.x-xx)
			if cut>left: canvas.draw_texture_rect_region(water,Rect2(xx+left,r.position.y-6,cut-left,th),Rect2(water.get_width()*left/tw,0,water.get_width()*(cut-left)/tw,water.get_height()))
			xx+=tw
		return
	var w=h*water.get_width()/water.get_height()
	var shift=0.0 if reduced_motion else fposmod(elapsed*12.0,w)
	canvas.draw_rect(Rect2(r.position+Vector2(0,h*0.5),Vector2(r.size.x,r.size.y-h*0.5)),Color8(41,104,170))
	var x=r.position.x-shift
	while x<r.end.x:
		var cut=minf(w,r.end.x-x)
		var left=maxf(0,r.position.x-x)
		if cut>left: canvas.draw_texture_rect_region(water,Rect2(x+left,r.position.y-h*0.15,cut-left,h),Rect2(water.get_width()*left/w,0,water.get_width()*(cut-left)/w,water.get_height()))
		x+=w

## A55 paper theater: painted paper sky, a paper sun and clouds that drift and
## sway a little (no strings: kept simple and clean), then four paper scenery flats at different depths.
## Three flats far apart in depth: pale far mountains high up, the village
## in the middle distance, the woods close behind the play (clear gaps of
## sky and haze between them so each layer reads at its own speed).
const PAPER_BACK=[["far",0.06,0.64,0.3],["village",0.25,0.76,0.26],["woods",0.55,1.0,0.3]]
## P31: torn-paper sky, a calm layered paper sun, drifting paper clouds and
## three landscape strips far apart in depth (mountains, village hills, lake).
const P31_BACK=[["mountains",0.06,0.62,0.3],["hills",0.2,0.8,0.34],["near",0.42,0.98,0.26]]
func draw_p31_backdrop(canvas: CanvasItem, view: Rect2) -> void:
	canvas.draw_rect(view.grow(4),Color8(170,206,232))
	var sky=tex("sky")
	var sh=view.size.y*0.62
	var sw=sh*sky.get_width()/sky.get_height()
	var x=view.position.x-fposmod(view.position.x*0.03,sw)
	while x<view.end.x:
		canvas.draw_texture_rect(sky,Rect2(x,view.position.y,sw+1,sh),false)
		x+=sw
	var sun=tex("sun")
	var s=view.size.y*0.34
	canvas.draw_texture_rect(sun,Rect2(view.position.x+view.size.x*0.66,view.position.y+view.size.y*0.06,s,s),false)
	for i in 2:
		var c=tex("cloud_a" if i==0 else "cloud_b")
		var ch=view.size.y*0.13
		var cw=ch*c.get_width()/c.get_height()
		var span=view.size.x+cw*2
		var cx=view.position.x+fposmod((0.15+i*0.5)*span+elapsed*(4.0+i*2.0)*(0.0 if reduced_motion else 1.0)-view.position.x*0.05,span)-cw
		canvas.draw_texture_rect(c,Rect2(cx,view.position.y+view.size.y*(0.1+i*0.12),cw,ch),false)
	for spec in P31_BACK: draw_layer(canvas,spec)

## A57 environment layer kits (tools/env_layers.py): far backdrop, far
## silhouettes, middle shapes, light shafts and ceiling, each its own sharp
## layer at its own depth; the foreground framing clumps sit at the screen
## edges in front of the play (drawn by draw_env_front).
func env_kit() -> String:
	if not ArtStyle.paper: return ""
	var env={"cave":"cave","tower":"tower"}.get(room.get("scenery","meadow"),"")
	if room_id=="windmill_cellar": env="cellar"
	return env if ResourceLoader.exists(P31_ART+"L_%s_far.png"%env) else ""
func env_strip(canvas: CanvasItem, view: Rect2, name: String, factor: float, top: float, h: float, additive=false) -> void:
	var t=tex(name)
	var w=h*t.get_width()/t.get_height()
	var x=view.position.x-fposmod(view.position.x*factor,w)
	if additive: canvas.draw_set_transform(Vector2.ZERO)
	while x<view.end.x:
		canvas.draw_texture_rect(t,Rect2(x,top,w+1,h),false,Color(1,1,1,0.9) if additive else Color.WHITE)
		x+=w
func draw_env_back(canvas: CanvasItem, view: Rect2, env: String) -> void:
	var H=view.size.y
	var y0=view.position.y
	# The far wall sits deep in shadow (concept: darker, bluer with depth).
	var far_tint={"cave":Color(0.42,0.46,0.75),"tower":Color(0.85,0.8,0.72),"cellar":Color(0.7,0.6,0.5)}.get(env,Color.WHITE)
	var ft=tex("L_%s_far"%env)
	var fh=H*1.1
	var fw=fh*ft.get_width()/ft.get_height()
	var fx=view.position.x-fposmod(view.position.x*0.05,fw)
	while fx<view.end.x:
		canvas.draw_texture_rect(ft,Rect2(fx,y0-H*0.05,fw+1,fh),false,far_tint)
		fx+=fw
	env_strip(canvas,view,"L_%s_silo"%env,0.18,y0+H*0.86-H*0.55,H*0.55)
	env_strip(canvas,view,"L_%s_mid"%env,0.38,y0+H*1.0-H*0.62,H*0.62)
	env_strip(canvas,view,"L_%s_light"%env,0.1,y0,H,true)
	env_strip(canvas,view,"L_%s_ceiling"%env,0.5,y0-2,H*0.32)
## The near foreground flat (concept: soft clumps low at the screen bottom):
## a few clumps spread through the room that scroll FASTER than the play
## (factor 1.35), small, mostly below the floor line so the floor stays clear.
func draw_kit_front(canvas: CanvasItem) -> void:
	var t=tex("mf_front_leaves_a" if room.has("kit") and has_piece("mf_front_leaves_a") else "front_leaves")
	var view=view_rect()
	var factor=1.35
	var spacing=view.size.x*0.9
	var h=view.size.y*0.2
	var w=h*t.get_width()/t.get_height()
	var shift=view.position.x*(factor-1.0)
	var first=int(floor((view.position.x+shift-w)/spacing))
	for i in range(first,first+4):
		var r=fposmod(sin(i*12.9898)*43758.5453,1.0)
		var x=i*spacing+r*spacing*0.4-shift
		if x+w<view.position.x or x>view.end.x: continue
		var flip=-1.0 if r>0.5 else 1.0
		var hh=h*(0.8+0.4*r)
		var ww=hh*t.get_width()/t.get_height()
		canvas.draw_texture_rect(t,Rect2(x if flip>0 else x+ww,view.end.y-hh*0.55,ww*flip,hh),false)
func draw_env_front(canvas: CanvasItem) -> void:
	var env=env_kit()
	if env.is_empty(): return
	var view=view_rect()
	for side in ["left","right"]:
		var t=tex("L_%s_front_%s"%[env,side])
		var h=view.size.y*0.62
		var w=h*t.get_width()/t.get_height()
		var x=view.position.x-w*0.35 if side=="left" else view.end.x-w*0.65
		canvas.draw_texture_rect(t,Rect2(x,view.end.y-h*0.8,w,h),false,Color(1,1,1,0.95))

## A57 interiors (P33 cave, P34 tower, P36 cellar): a base colour, two
## concept layers far apart in depth, and an optional ceiling strip that
## hangs from the top of the view.
func draw_room_layers(canvas: CanvasItem, view: Rect2, base: Color, specs: Array, ceiling: String) -> void:
	canvas.draw_rect(view.grow(4),base)
	for spec in specs: draw_layer(canvas,spec)
	if not ceiling.is_empty():
		var t=tex(ceiling)
		var h=view.size.y*0.3
		var w=h*t.get_width()/t.get_height()
		var x=view.position.x-fposmod(view.position.x*0.25,w)
		while x<view.end.x:
			canvas.draw_texture_rect(t,Rect2(x,view.position.y-4,w+1,h),false)
			x+=w

## Tall rooms (the tower climb): the far hall tiles up the whole height and
## scrolls slowly both ways; the pillar and balustrade strips stand on the
## room floor, so climbing reveals more of the hall, never a cut edge.
func draw_kit_tall(canvas: CanvasItem, view: Rect2) -> void:
	# P34 depth: a pale hazy far hall (slow), then the near wall with big
	# arched windows and an opening onto the hall (faster); each one tall
	# picture that slides a little as you climb (no stacked tiles).
	big_layer(canvas,view,"hall_far",0.12,1.5)
	big_layer(canvas,view,"hall_mid",0.4,1.75)
func big_layer(canvas: CanvasItem, view: Rect2, name: String, f: float, hfrac: float) -> void:
	var t=tex(name)
	var h=view.size.y*hfrac
	var w=h*t.get_width()/t.get_height()
	var top=view.position.y*(1.0-f)-(h-view.size.y)*clampf(view.position.y/maxf(1.0,float(room.size[1])-view.size.y),0.0,1.0)*0.0
	# Bottom of the picture meets the room floor when the view is at the floor.
	var span=maxf(1.0,float(room.size[1])-view.size.y)
	var k=clampf(view.position.y/span,0.0,1.0)
	top=view.position.y-(h-view.size.y)*k
	var ox=view.position.x*(1.0-f)
	var x=floorf((view.position.x-ox)/w)*w+ox
	while x<view.end.x:
		canvas.draw_texture_rect(t,Rect2(x,top,w+1,h),false)
		x+=w
func tile_layer(canvas: CanvasItem, view: Rect2, name: String, f: float, hfrac: float, tint: Color) -> void:
	var t=tex(name)
	var h=view.size.y*hfrac
	var w=h*t.get_width()/t.get_height()
	var ox=view.position.x*(1.0-f)
	var oy=view.position.y*(1.0-f)
	var x=floorf((view.position.x-ox)/w)*w+ox
	while x<view.end.x:
		var y=floorf((view.position.y-oy)/h)*h+oy
		while y<view.end.y:
			canvas.draw_texture_rect(t,Rect2(x,y,w+1,h+1),false,tint)
			y+=h
		x+=w

## Interiors with their own kit: exactly the meadow's layering (backdrop
## strip, then three strips far apart in depth), from the kit's layers sheet.
func draw_kit_backdrop(canvas: CanvasItem, view: Rect2) -> void:
	if float(room.size[1])>view.size.y*1.3 and env_dir().ends_with("tower/") and room_id=="old_tower":
		draw_kit_tall(canvas,view)
		return
	var sky=tex("sky")
	canvas.draw_rect(view.grow(4),sky.get_image().get_pixel(int(sky.get_width()/2),2) if false else Color8(24,22,58))
	var sh=view.size.y*0.95
	var sw=sh*sky.get_width()/sky.get_height()
	var x=view.position.x-fposmod(view.position.x*0.03,sw)
	while x<view.end.x:
		canvas.draw_texture_rect(sky,Rect2(x,view.position.y-view.size.y*0.12,sw+1,sh),false)
		x+=sw
	for spec in P31_BACK: draw_layer(canvas,spec)

func draw_paper_backdrop(canvas: CanvasItem, view: Rect2) -> void:
	if ResourceLoader.exists(P31_ART+"near.png"):
		draw_p31_backdrop(canvas,view)
		return
	canvas.draw_texture_rect(tex("sky"),view.grow(4),false)
	# Hanging paper elements on twine (P02 close-up): each swings from its
	# string, which always runs up out of the top of the view.
	var meta: Dictionary=PaperPuppet.rig("hanging")
	var hang=[["hang_sun",0.82,0.1,44.0],["hang_cloud_a",0.12,0.12,34.0],["hang_cloud_b",0.38,0.07,20.0],["hang_cloud_c",0.62,0.15,26.0],["hang_bird",0.5,0.24,16.0]]
	for i in hang.size():
		var h: Array=hang[i]
		var texture: Texture2D=tex(h[0])
		var m: Dictionary=meta[h[0]]
		var span=view.size.x+200.0
		var x=view.position.x+fposmod(float(h[1])*span-view.position.x*0.06,span)-100.0
		var body=float(h[3])
		var full=body/(1.0-float(m.body_top))
		var w=full*texture.get_width()/texture.get_height()
		var top=minf(view.position.y+view.size.y*float(h[2])-full*float(m.body_top),view.position.y-4.0)
		var swing=0.0 if reduced_motion else sin(elapsed*0.8+i*1.7)*0.035
		canvas.draw_set_transform(Vector2(x,top),swing,Vector2.ONE)
		canvas.draw_texture_rect(texture,Rect2(-w*float(m.string_x)+2,3,w,full),false,Color(0.1,0.12,0.25,0.18))
		canvas.draw_texture_rect(texture,Rect2(-w*float(m.string_x),0,w,full),false)
		canvas.draw_set_transform(Vector2.ZERO)
	# Aerial haze: the farther the flat, the paler and bluer, so the play reads.
	var haze=[Color(1.12,1.2,1.42),Color(1.04,1.1,1.22),Color(0.8,0.86,0.8)]
	for i in PAPER_BACK.size(): draw_layer(canvas,PAPER_BACK[i],haze[i])

## Inside the Old Tower: one continuous round tower wall (windows, torches,
## far stairs) moving a little slower than the climb, so it has depth.
func draw_tower_inside(canvas: CanvasItem, view: Rect2) -> void:
	var t=tex("tower_in")
	var size=Vector2(room.size[0],room.size[1])
	var w=150.0 if ArtStyle.paper else 420.0
	var h=w*t.get_height()/t.get_width()
	var factor=0.85
	var shift=view.position*(1.0-factor)
	var x=floorf((view.position.x-shift.x)/w)*w+shift.x
	while x<view.end.x:
		var y=floorf((view.position.y-shift.y)/h)*h+shift.y
		while y<view.end.y:
			canvas.draw_texture_rect(t,Rect2(x,y,w+0.5,h+0.5),false,Color(0.7,0.66,0.66) if ArtStyle.paper else Color.WHITE)
			y+=h
		x+=w
	# Soft shade at the bottom so the floor reads as the ground.
	canvas.draw_rect(Rect2(view.position.x,size.y-90,view.size.x,90),Color(0.1,0.07,0.05,0.18))

## Interior parallax: a far, dark wall slowly behind a nearer, brighter one
## (cave: crystal glow; tower: open arches show the sky layers behind).
func draw_walls(canvas: CanvasItem) -> void:
	var view=view_rect().grow(4)
	match room.get("scenery","meadow"):
		"cave": pass
		"tower": pass

## Fill `area` with a tiling texture that scrolls at `factor`.
func draw_tiled(canvas: CanvasItem, name: String, area: Rect2, factor: float, scale_value: float, tint=Color.WHITE) -> void:
	var texture=tex(name)
	var offset=area.position*(1.0-factor)
	canvas.draw_set_transform(offset,0,Vector2.ONE*scale_value)
	var local=Rect2((area.position-offset)/scale_value,area.size/scale_value)
	canvas.draw_texture_rect(texture,local,true,tint)
	canvas.draw_set_transform(Vector2.ZERO)

## --- Living world: moving water, drifting leaves, cave fireflies and beams.
func draw_ambient(canvas: CanvasItem) -> void:
	if reduced_motion: return
	var view=view_rect()
	var scenery: String=room.get("scenery","meadow")
	if scenery=="meadow":
		for k in range(14):
			var seed_x=fposmod(k*211.0,1000.0)
			var t=elapsed*(0.18+0.05*(k%4))+k*0.37
			var x=view.position.x+fposmod(seed_x+t*90.0-view.position.x*0.15,view.size.x+60)-30
			var y=view.position.y+fposmod(k*57.0+t*38.0,view.size.y*0.9)
			var a=t*3.0+k
			var c=Color(0.55,0.75,0.25,0.85) if k%3 else Color(0.95,0.6,0.25,0.85)
			canvas.draw_set_transform(Vector2(x+sin(t*2.0)*10.0,y),a,Vector2(1,0.5))
			canvas.draw_circle(Vector2.ZERO,2.6,c)
			canvas.draw_set_transform(Vector2.ZERO)
	elif scenery=="cave":
		for k in range(4):
			var bx=fposmod(k*380.0+120.0,float(room.size[0]))
			var pulse=0.06+0.03*sin(elapsed*0.8+k)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(bx,150),Vector2(bx+40,150),Vector2(bx+120,290),Vector2(bx+30,290)]),Color(0.7,0.85,1.0,pulse))
		for k in range(16):
			var t=elapsed*0.4+k*1.7
			var x=fposmod(k*97.0+sin(t)*30.0,float(room.size[0]))
			var y=190.0+fposmod(k*23.0,80.0)+cos(t*1.3)*10.0
			var glow=0.5+0.5*sin(elapsed*3.0+k)
			canvas.draw_circle(Vector2(x,y),5.0,Color(0.6,1.0,0.7,0.12*glow))
			canvas.draw_circle(Vector2(x,y),1.6,Color(0.85,1.0,0.6,0.9*glow))

## Friendly animals: birds cross the sky, butterflies drift, and one or two
## ground animals sit near the path (set per room in the data as "fauna").
func draw_fauna(canvas: CanvasItem) -> void:
	var scenery: String=room.get("scenery","meadow")
	var view=view_rect()
	if scenery=="meadow":
		# Birds live in the world and always fly forward across the room at
		# their own pace, so walking back never drags them backwards.
		var span=float(room.size[0])+400.0
		for k in range(int(span/700.0)+1):
			var speed=34.0+k%3*9.0
			var x=fposmod(elapsed*speed+k*700.0+k*k*37.0,span)-200.0
			if x<view.position.x-60 or x>view.end.x+60: continue
			var y=view.position.y+view.size.y*(0.16+0.06*(k%3))+sin(elapsed*1.5+k)*6
			var frame="bird_a" if reduced_motion or int(elapsed*6+k)%2==0 else "bird_b"
			piece(canvas,frame,Vector2(x,y),12,Color.WHITE,false,false)
		for k in range(3):
			var bx=float(k*700+300)
			var y=ground_y_at(bx)-22-sin(elapsed*1.7+k)*8
			var x=bx+sin(elapsed*0.6+k)*40
			piece(canvas,"butterfly_a" if reduced_motion or int(elapsed*8+k)%2==0 else "butterfly_b",Vector2(x,y),9,Color.WHITE,false,false)
	for f in room.get("fauna",[]):
		var feet=Vector2(f.pos[0],f.pos[1]+2)
		var kind: String=f.kind
		if kind=="bunny":
			var hop=fposmod(elapsed+f.pos[0],5.0)
			var up=0.0 if reduced_motion or hop>0.6 else sin(hop/0.6*PI)*8.0
			# The shadow stays on the ground and shrinks as the bunny rises.
			paper_contact(canvas,feet,6.5*(1.0-up/16.0))
			var land=0.0 if reduced_motion else clampf(1.0-absf(hop-0.66)/0.08,0.0,1.0)
			piece(canvas,"bunny_hop" if up>1 else "bunny_sit",feet-Vector2(0,up),15,Color.WHITE,f.get("flip",false),false,0.0,Vector2(1.0+land*0.08,1.0-land*0.08),false)
		else: piece(canvas,kind,feet,15 if kind=="squirrel" else 11,Color.WHITE,f.get("flip",false))

## Moving shimmer and sparkles over every stretch of water.
func draw_water_motion(canvas: CanvasItem) -> void:
	if reduced_motion: return
	for w in room.get("waters",[]):
		var r=Rect2(w[0],w[1],w[2],w[3])
		for k in range(10):
			var y=r.position.y+6+fposmod(k*13.0,r.size.y*0.6)
			var len=18.0+float((k*7)%14)
			var x=r.position.x+fposmod(k*53.0+elapsed*(26.0+k*3.0),r.size.x-len)
			canvas.draw_line(Vector2(x,y),Vector2(x+len,y),Color(1,1,1,0.35+0.25*sin(elapsed*2.0+k)),1.4)
		for k in range(6):
			var sp=Vector2(r.position.x+fposmod(k*71.0+elapsed*12.0,r.size.x),r.position.y+4+fposmod(k*19.0,r.size.y*0.5))
			var tw=maxf(0,sin(elapsed*4.0+k*1.9))
			canvas.draw_circle(sp,1.5*tw+0.2,Color(1,1,1,0.9*tw))

## --- Room -------------------------------------------------------------------
func piece(canvas: CanvasItem, name: String, feet: Vector2, height: float, tint=Color.WHITE, flip=false, grounded=true, rot=0.0, squash=Vector2.ONE, silhouette=true) -> void:
	var texture=tex(name)
	var width=height*texture.get_width()/texture.get_height()
	var size=Vector2(width,height)*squash
	# Paper lighting: a soft contact shadow on the ground under the piece.
	# Only what really stands on the ground gets the oval (an arrow or sign
	# hanging in the sky does not).
	if ArtStyle.paper and grounded and ground_below(feet.x,feet.y-3)-feet.y>4.0: grounded=false
	# A61: on the same line as the boy and Foxy (callers pass ground y +2),
	# with only a light shadow tucked under the base (a dark oval below it
	# made things look like floating).
	if ArtStyle.paper and grounded: feet.y-=2.0
	if ArtStyle.paper and grounded: paper_contact(canvas,feet,width*0.36,tint.a*0.45,0.22,-1.0)
	canvas.draw_set_transform(feet,rot,Vector2(-1 if flip else 1,1))
	# A cut-out lifted off the page: a soft, blurred shadow just behind it
	# (light from the top left), never a hard dark copy.
	# Things in the air cast theirs further down and lighter (lifted off the page).
	var lift=Vector2(1,1)*(2.5 if grounded else size.y*0.35)
	# Things in the air (birds, butterflies, bees) never get an outline copy:
	# it floated beside them in the sky.
	if ArtStyle.paper and silhouette and grounded and not airy(name): paper_shadow(canvas,name,Rect2(Vector2(-size.x*0.5,-size.y),size),Vector2(lift.x*(-1 if flip else 1),lift.y),(0.3 if grounded else 0.22)*tint.a)
	# A60: things in the air get no ground oval, only a small light shadow
	# just behind them (basic, hardly wider than the piece).
	elif ArtStyle.paper and silhouette and not grounded: air_shadow(canvas,texture,Rect2(Vector2(-size.x*0.5,-size.y),size),tint.a)
	canvas.draw_texture_rect(texture,Rect2(Vector2(-size.x*0.5,-size.y),size),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)

func air_shadow(canvas: CanvasItem, texture: Texture2D, r: Rect2, alpha=1.0) -> void:
	canvas.draw_texture_rect(texture,Rect2(r.position+Vector2(0.8,1.2),r.size),false,Color(0.1,0.12,0.06,0.16*alpha))

## A63: the level painted from its concept panorama, in screen tiles
## (phones: one texture per screen). Back = sky and valley (parallax),
## play = everything you walk on and in front of it.
func painted_tile(kind: String, i: int) -> Texture2D:
	var n="%s%s%d"%[room.painted.prefix,kind,i]
	if not textures.has("@"+n): textures["@"+n]=ArtTexture.load_texture(P31_ART+"painted/"+n+".png")
	return textures["@"+n]
func draw_painted_play(canvas: CanvasItem) -> void:
	var tw=float(room.painted.tile_w)
	var th=float(room.size[1])
	var view=view_rect()
	for i in int(room.painted.tiles):
		var x=i*tw
		if x>view.end.x+2 or x+tw<view.position.x-2: continue
		canvas.draw_texture_rect(painted_tile("play",i),Rect2(x-0.5,0,tw+1.0,th),false)
func draw_painted_back(canvas: CanvasItem, view: Rect2) -> void:
	# The far valley moves at 40%; its tiles overlap and fade into each other.
	var f=0.4
	var tw=float(room.painted.tile_w)
	var th=float(room.size[1])
	var off=view.position.x*(1.0-f)
	var ov=tw*0.12
	for i in int(room.painted.tiles):
		var x=off+i*(tw-ov)
		if x>view.end.x or x+tw<view.position.x: continue
		canvas.draw_texture_rect(painted_tile("back",i),Rect2(x,0,tw,th),false)
static var _sets_meta: Dictionary={}
func draw_sets(canvas: CanvasItem, front: bool) -> void:
	if room.get("sets",[]).is_empty(): return
	if _sets_meta.is_empty() and FileAccess.file_exists(P31_ART+"sets.json"): _sets_meta=JSON.parse_string(FileAccess.get_file_as_string(P31_ART+"sets.json"))
	for sp in room.get("sets",[]):
		if bool(sp.get("front",false))!=front: continue
		var m: Dictionary=_sets_meta.get(sp.name,{})
		if m.is_empty() or not has_piece("set_"+String(sp.name)): continue
		var t=tex("set_"+String(sp.name))
		var k=float(sp.k)
		var sc=float(m.scale)
		var at=Vector2(sp.origin[0],sp.origin[1])+Vector2(m.crop[0],m.crop[1])*k
		canvas.draw_texture_rect(t,Rect2(at,Vector2(t.get_width(),t.get_height())/sc*k),false)
	# Plants over the joints where a painting meets the plain path.
	if front:
		for fd in room.get("front_decor",[]): piece(canvas,fd.art,Vector2(fd.pos[0],fd.pos[1]+2),float(fd.h),Color.WHITE,fd.get("flip",false),false,0.0,Vector2.ONE,false)

## A62 (P71a kit): rooms built from the Meadow building blocks. Every
## piece stands on its measured grass line (fraction of its height where the
## feet go), so the walk line is always the drawn grass.
const KIT_LINE={"mf_grass_top":0.29,"mf_cliff_top":0.23,"mf_ledge_s":0.27,"mf_ledge_m":0.25,"mf_ledge_l":0.21,"mf_log":0.33,"mf_chamber_floor":0.2}
func kt(name: String) -> Texture2D:
	if not textures.has("@"+name): textures["@"+name]=ArtTexture.load_texture(P31_ART+name+".png")
	return textures["@"+name]
func kit_strip(canvas: CanvasItem, name: String, x0: float, x1: float, y: float, h: float) -> void:
	var t=kt(name)
	var w=h*t.get_width()/t.get_height()
	var top=y-h*float(KIT_LINE.get(name,0.25))
	var x=x0
	while x<x1-0.5:
		var phase=fposmod(x,w)
		if w-phase<0.05: phase=0.0
		var seg=minf(w-phase,x1-x)
		if seg<0.05: break
		canvas.draw_texture_rect_region(t,Rect2(x,top,seg+0.4,h),Rect2(t.get_width()*phase/w,0,t.get_width()*seg/w,t.get_height()))
		x+=seg
func kit_tile(canvas: CanvasItem, name: String, r: Rect2, k: float) -> void:
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*k)
	canvas.draw_texture_rect(kt(name),Rect2(r.position/k,r.size/k),true)
	canvas.draw_set_transform(Vector2.ZERO)
func kit_fill(canvas: CanvasItem, r: Rect2, style: String) -> void:
	match style:
		"cliff": kit_tile(canvas,"mf_cliff_face_b" if has_piece("mf_cliff_face_b") else "mf_cliff_face",Rect2(r.position.x+4,r.position.y+10,r.size.x-8,r.size.y-10),0.26)
		"", "slab": if r.size.y>20: kit_tile(canvas,"mf_earth",Rect2(r.position.x,r.position.y+16,r.size.x,r.size.y-16),0.3)
func kit_top(canvas: CanvasItem, r: Rect2, style: String) -> void:
	match style:
		"", "slab": kit_strip(canvas,"mf_grass_top",r.position.x,r.end.x,r.position.y,40.0)
		"cliff":
			if has_piece("mf_cliff_a"):
				kit_cliff(canvas,r)
				return
			kit_strip(canvas,"mf_cliff_top",r.position.x,r.end.x,r.position.y,44.0)
			for side in [-1.0,1.0]:
				if not exposed(r,side): continue
				var n="mf_cliff_left" if side<0 else "mf_cliff_right"
				var t=kt(n)
				var h=minf(r.size.y+18.0,96.0)
				var w=h*t.get_width()/t.get_height()
				var x=r.position.x-w*0.45 if side<0 else r.end.x-w*0.55
				canvas.draw_texture_rect(t,Rect2(x,r.position.y-h*0.1,w,h),false)
		"log":
			kit_strip(canvas,"mf_log",r.position.x-6,r.end.x+6,r.position.y,26.0)
			for x in [r.position.x-2,r.end.x+2]: piece(canvas,"mf_log_post",Vector2(x,r.position.y+12),30,Color.WHITE,false,false,0.0,Vector2.ONE,false)
		"chamber": kit_strip(canvas,"mf_chamber_floor",r.position.x,r.end.x,r.position.y,22.0)
		"ledge_s", "ledge_m", "ledge_l":
			var n="mf_"+style
			var t=kt(n)
			var w=r.size.x*1.1
			var h=w*t.get_height()/t.get_width()
			canvas.draw_texture_rect(t,Rect2(r.get_center().x-w*0.5,r.position.y-h*float(KIT_LINE[n]),w,h),false)
## Stone steps up a ramp (each step a block from its top to the ground),
## with the wooden handrail along them.
func kit_stairs(canvas: CanvasItem, rp: Array) -> void:
	var x0=float(rp[0]); var y0=float(rp[1]); var x1=float(rp[2]); var y1=float(rp[3])
	var low=maxf(y0,y1)
	var high=minf(y0,y1)
	var left_low=y0>y1
	var n=maxi(2,int(round((low-high)/15.0)))
	var run=absf(x1-x0)/n
	var rise=(low-high)/n
	var st=kt("mf_stair_step")
	var face="mf_cliff_face_b" if has_piece("mf_cliff_face_b") else "mf_cliff_face"
	# Rock under the steps, then each step block at its own shape on top.
	for i in n:
		var top=low-rise*(i+1)
		var sx=(x0+run*i) if left_low else (x1-run*(i+1))
		kit_tile(canvas,face,Rect2(sx,top+6,run+1,low-top-4),0.22)
	for i in n:
		var top=low-rise*(i+1)
		var sx=(x0+run*i) if left_low else (x1-run*(i+1))
		var sw=run*1.5
		var sh=sw*st.get_height()/st.get_width()
		canvas.draw_texture_rect(st,Rect2(sx+run*0.5-sw*0.5,top-sh*0.2,sw,sh),false)
	# Handrail along the slope, its posts on the steps.
	var rail=kt("mf_stair_rail")
	var rw=absf(x1-x0)
	var rx=minf(x0,x1)
	var rh=(low-high)*1.3
	if left_low: canvas.draw_texture_rect(rail,Rect2(rx,high-rh*0.3,rw,rh),false)
	else:
		canvas.draw_set_transform(Vector2(rx+rw,0),0,Vector2(-1,1))
		canvas.draw_texture_rect(rail,Rect2(0,high-rh*0.3,rw,rh),false)
		canvas.draw_set_transform(Vector2.ZERO)

## Fences along cliff edges: [x0, x1, y].
func kit_fences(canvas: CanvasItem) -> void:
	for f in room.get("fences",[]):
		var t=kt("mf_fence_edge")
		var h=20.0
		var w=h*t.get_width()/t.get_height()
		var x=float(f[0])
		var y=float(f[2])+2.0
		while x<float(f[1])-w*0.3:
			var seg=minf(w,float(f[1])-x)
			canvas.draw_texture_rect_region(t,Rect2(x,y-h,seg,h),Rect2(0,0,t.get_width()*seg/w,t.get_height()))
			x+=seg-1.0
		var post=kt("mf_fence_end")
		var ph=21.0
		var pw=ph*post.get_width()/post.get_height()
		canvas.draw_texture_rect(post,Rect2(float(f[1])-pw*0.5,y-ph,pw,ph),false)

## P72 variety: a cliff is a row of hand-painted cliff blocks (three kinds,
## mixed by position) on one grass line, overhanging ends, a rocky fern
## base and ivy curtains from the lip.
const CLIFF_LINE={"mf_cliff_a":0.14,"mf_cliff_b":0.12,"mf_cliff_c":0.12,"mf_overhang_l":0.1,"mf_overhang_r":0.07}
func kit_cliff(canvas: CanvasItem, r: Rect2) -> void:
	var names=["mf_cliff_a","mf_cliff_b","mf_cliff_c"]
	var bh=(r.size.y+6.0)/(1.0-0.13)
	var bw0=bh*360.0/221.0
	var n=maxi(1,int(round(r.size.x/bw0)))
	var bw=r.size.x/n
	for i in n:
		var pick=names[int(absf(sin((r.position.x+i*97.0)*0.013))*100.0)%3]
		var t=kt(pick)
		var hh=bw*1.04*t.get_height()/t.get_width()
		hh=maxf(hh,bh)
		canvas.draw_texture_rect(t,Rect2(r.position.x+i*bw-bw*0.02,r.position.y-hh*float(CLIFF_LINE[pick]),bw*1.04,hh),false)
	for side in [-1.0,1.0]:
		if not exposed(r,side): continue
		var on="mf_overhang_l" if side<0 else "mf_overhang_r"
		var ot=kt(on)
		var oh=(r.size.y+8.0)/(1.0-float(CLIFF_LINE[on]))
		var ow=oh*ot.get_width()/ot.get_height()
		canvas.draw_texture_rect(ot,Rect2(r.position.x-ow*0.55 if side<0 else r.end.x-ow*0.45,r.position.y-oh*float(CLIFF_LINE[on]),ow,oh),false)
	# Ivy curtains from the lip, one every couple of blocks.
	for i in range(0,n,2):
		var iv=kt("mf_ivy_a" if i%4==0 else "mf_ivy_b")
		var ih=minf(r.size.y*0.7,60.0)
		var iw=ih*iv.get_width()/iv.get_height()
		canvas.draw_texture_rect(iv,Rect2(r.position.x+(i+0.6)*bw-iw*0.5,r.position.y-3,iw,ih),false)
	# Boulders and ferns where the cliff meets the ground.
	var base=kt("mf_cliff_base")
	var bsh=26.0
	var bsw=bsh*base.get_width()/base.get_height()
	var x=r.position.x-6
	while x<r.end.x-bsw*0.3:
		canvas.draw_texture_rect(base,Rect2(x,r.end.y+3-bsh,bsw,bsh),false)
		x+=bsw*0.9

## A ladder built to its exact height: foot piece on the ground, the rail
## middle repeated, the top posts just above the ledge (one rung there).
func kit_ladder(canvas: CanvasItem, l: Array, name: String) -> void:
	var x=float(l[0])
	var top=float(l[1])
	var foot=float(l[2])
	if name.begins_with("vine"):
		var mid=kt("mf_vine_mid")
		var k=22.0/float(mid.get_width())
		var mh=mid.get_height()*k
		var y=foot+4.0
		while y>top+2.0 and mh>1.0:
			var seg=minf(mh,y-top)
			canvas.draw_texture_rect_region(mid,Rect2(x-11,y-seg,22,seg),Rect2(0,mid.get_height()*(1.0-seg/mh),mid.get_width(),mid.get_height()*seg/mh))
			y-=seg
		var vt=kt("mf_vine_top")
		canvas.draw_texture_rect(vt,Rect2(x-vt.get_width()*k*0.5,top-vt.get_height()*k*0.06,vt.get_width()*k,vt.get_height()*k),false)
		return
	if has_piece("mf_ladder_long"):
		# The concept's ladder: rope-tied rungs every 41.5 px of the 339 px
		# piece; tiled from the foot, capped by its rounded rail tops.
		var L=kt("mf_ladder_long")
		var lk=24.0/float(L.get_width())
		var period=41.5*7.0
		var tile_h=period*lk
		var cap=16.0*lk
		var foot_part=(339.0-306.5)*lk
		canvas.draw_texture_rect_region(L,Rect2(x-12,foot+2-foot_part,24,foot_part),Rect2(0,306.5,84,32.5))
		var yy=foot+2-foot_part
		var top_y=top-6.0
		while yy>top_y+cap+0.5:
			var seg=minf(tile_h,yy-(top_y+cap))
			canvas.draw_texture_rect_region(L,Rect2(x-12,yy-seg,24,seg),Rect2(0,16.0+period*(1.0-seg/tile_h),84,period*seg/tile_h))
			yy-=seg
		canvas.draw_texture_rect_region(L,Rect2(x-12,top_y,24,cap),Rect2(0,0,84,16))
		return
	var m=kt("mf_ladder_mid")
	var k=22.0/float(m.get_width())
	var mh=m.get_height()*k
	var b=kt("mf_ladder_bottom")
	var bh=b.get_height()*k
	var tp=kt("mf_ladder_top")
	var th=tp.get_height()*k
	var mid_top=top-th*0.25
	var y=foot-bh*0.55
	while y>mid_top+0.5 and mh>1.0:
		var seg=minf(mh,y-mid_top)
		canvas.draw_texture_rect_region(m,Rect2(x-11,y-seg,22,seg),Rect2(0,m.get_height()*(1.0-seg/mh),m.get_width(),m.get_height()*seg/mh))
		y-=seg
	canvas.draw_texture_rect(b,Rect2(x-b.get_width()*k*0.5,foot+2-bh,b.get_width()*k,bh),false)
	canvas.draw_texture_rect(tp,Rect2(x-tp.get_width()*k*0.5,top-th*0.75,tp.get_width()*k,th),false)

## A piece repeated along x at its own proportions (log bridges).
func strip_piece(canvas: CanvasItem, name: String, x0: float, x1: float, top: float, h: float) -> void:
	var t=tex(name)
	var w=h*t.get_width()/t.get_height()
	var n=maxi(1,int(round((x1-x0)/w)))
	var seg=(x1-x0)/n
	for i in n: canvas.draw_texture_rect(t,Rect2(x0+i*seg-1,top,seg+2,h),false)

## A60 (P71a): a ladder (or vine) from its foot on the ground up to the
## ledge, repeated at its own size so the rungs keep one even spacing (the
## climb frames step one hand per half rung).
const LADDER_W=18.0
func draw_ladder(canvas: CanvasItem, l: Array) -> void:
	var name: String=l[3] if l.size()>3 else "ladder"
	if room.has("kit") or room.has("painted"):
		# Painted rooms paint their ladders; "vine" adds a climbing vine piece.
		if name=="none": return
		kit_ladder(canvas,l,name)
		return
	if not has_piece(name): return
	var t=tex(name)
	var k=LADDER_W/t.get_width()
	# One seamless tile: seven rung periods (rungs at 17 + 42.6 n of 360).
	var src0=17.0/360.0*t.get_height()
	var src_h=7.0*42.6/360.0*t.get_height()
	var h=src_h*k
	var x=float(l[0])-LADDER_W*0.5
	# Rails end just above the ledge lip (something to hold when stepping on).
	var top=float(l[1])-3.0
	var bottom=float(l[2])+1.0
	# Its feet on the ground: soft oval (it stands there).
	paper_contact(canvas,Vector2(float(l[0]),float(l[2])),LADDER_W*0.7,0.8)
	var y=bottom
	while y>top+0.5:
		var seg=minf(h,y-top)
		canvas.draw_texture_rect_region(t,Rect2(x,y-seg,LADDER_W,seg),Rect2(0,src0+src_h*(1.0-seg/h),t.get_width(),src_h*seg/h))
		y-=seg

## A61: a hazard patch sits on the ground under it; its art per place.
func hazard_rect(t: Array) -> Rect2:
	var g=ground_below(float(t[0])+float(t[2])*0.5,float(t[1])-2.0)
	var y=g if g<INF else float(t[1])+float(t[3])
	return Rect2(float(t[0]),y-float(t[3]),float(t[2]),float(t[3]))
func hazard_art() -> String:
	var sc: String=room.get("scenery","meadow")
	var n="hz_crystal" if sc=="cave" else ("hz_spikes" if sc=="tower" or room_id.begins_with("windmill") else "hz_thorns")
	return n if ResourceLoader.exists(P31_ART+n+".png") else "thorns"
## Centre of a signpost's board (fraction of the picture), measured once.
static var _boards: Dictionary={}
static func sign_board(t: Texture2D) -> Vector2:
	var key=t.get_rid()
	if _boards.has(key): return _boards[key]
	var out=Vector2(0.5,0.25)
	var img: Image=t.get_image()
	if img!=null:
		if img.is_compressed(): img.decompress()
		var w=img.get_width()
		var h=img.get_height()
		var widths=[]
		var best=0
		for y in range(0,int(h*0.6)):
			var n=0
			for x in range(0,w,2):
				if img.get_pixel(x,y).a>0.5: n+=1
			widths.append(n)
			best=maxi(best,n)
		var rows=[]
		for y in widths.size(): if widths[y]>best*0.75: rows.append(y)
		if not rows.is_empty():
			var cy=int((rows[0]+rows[-1])*0.5)
			var left=0
			for x in range(w):
				if img.get_pixel(x,cy).a>0.5:
					left=x
					break
			var right=w-1
			for x in range(w-1,-1,-1):
				if img.get_pixel(x,cy).a>0.5:
					right=x
					break
			var bh=float(rows[-1]-rows[0])
			out=Vector2((float(left)+float(right)-bh*0.5)*0.5/float(w),float(cy)/float(h))
	_boards[key]=out
	return out

## Thin or airy pieces (flags, signs, lanterns, plants) keep only their soft
## ground oval: a dark copy of their outline floated on the sky like a ghost.
const AIRY=["flag","sign","lantern","checkpoint","rope_post","vines","ivy","banner","flower","bush","fern","mushroom","crystal","sails","lamp","mark_","twinkle","arrow","scaffold","thorn","grass","plant","tree"]
func airy(name: String) -> bool:
	for k in AIRY:
		if name.contains(k): return true
	return false

## Critters walk frame by frame with the distance they cover (feet never
## slide), bob a little on each step; the frog crouches, pushes off, flies
## and lands. Flyers flap; their shadow is only the soft one behind them.
func draw_critter(canvas: CanvasItem, c: Dictionary) -> void:
	var spec: Dictionary=CRITTERS[c.kind]
	var feet=Vector2(c.x,c.cy+2)
	var name: String=spec.art+("_a" if reduced_motion or int(elapsed*spec.anim)%2==0 else "_b")
	var rot=0.0
	var squash=Vector2.ONE
	if c.dizzy>0:
		name="hedgehog_ball" if c.kind=="hedgehog" else spec.art+"_dizzy"
	elif c.kind=="frog":
		var k=fposmod(elapsed+c.seed,1.6)
		var walk=has_piece("frog_w0")
		if k<0.5: name=("frog_w1" if k<0.14 else "frog_w2" if k<0.36 else "frog_w3") if walk else "frog_b"
		elif k<0.62:
			name="frog_w3" if walk else "frog_a"
			var l=1.0-(k-0.5)/0.12
			squash=Vector2(1.0+l*0.1,1.0-l*0.1)
		else: name="frog_w0" if walk else "frog_a"
		if reduced_motion: name="frog_w0" if walk else "frog_a"
	elif not spec.fly and not reduced_motion:
		# One step per ~third of the body length walked.
		var step=absf(c.x-c.x0)/(spec.h*0.32)
		if has_piece(spec.art+"_w0"): name=spec.art+"_w%d"%(int(step)%4)
		else: name=spec.art+("_a" if int(step)%2==0 else "_b")
		feet.y-=absf(sin(step*PI))*1.2
		rot=sin(step*PI)*0.035
	# Animals cast one soft oval on the ground, like the heroes (no dark copy
	# of the drawing behind them). Flyers' ovals sit on the ground straight
	# below, smaller and fainter the higher they fly (P31 shadow research).
	if ArtStyle.paper:
		var ground=ground_below(c.x,feet.y-2)
		if ground<INF:
			var lift=maxf(0.0,ground-feet.y)
			var t=clampf(1.0-lift/170.0,0.0,1.0)
			if t>0.05 and not spec.fly: paper_contact(canvas,Vector2(c.x,ground),spec.h*float(tex(name).get_width())/tex(name).get_height()*(0.62 if not spec.fly else 0.42)*lerpf(0.55,1.0,t),lerpf(0.3,1.0,t)*(1.0 if spec.fly else 1.35),0.34,2.0)
	piece(canvas,name,feet,spec.h,Color.WHITE,c.dir<0,false,rot,squash,spec.fly)

## The top of the first ground under a point (INF when there is none).
func ground_below(x: float, y: float) -> float:
	var best=INF
	for ln in room.get("lines",[]):
		var pts: Array=ln.pts
		for i in range(pts.size()-1):
			if x>=float(pts[i][0]) and x<=float(pts[i+1][0]):
				var t=(x-float(pts[i][0]))/maxf(0.01,float(pts[i+1][0])-float(pts[i][0]))
				var gy=lerpf(float(pts[i][1]),float(pts[i+1][1]),t)
				if gy>=y-1: best=minf(best,gy)
	if room.has("lines"): return best
	for r in rects("ground"):
		if x>=r.position.x and x<=r.end.x and r.position.y>=y-1: best=minf(best,r.position.y)
	return best

func has_piece(name: String) -> bool:
	var envdir=env_dir()
	return ResourceLoader.exists(P31_ART+name+".png") or (not envdir.is_empty() and ResourceLoader.exists(envdir+name+".png"))

## Soft oval contact shadow (same paper shadow as the heroes).
func paper_contact(canvas: CanvasItem, feet: Vector2, half: float, alpha=1.0, squash=0.22, drop=0.5) -> void:
	# A60 (P70): the same gentle oval as under the boy and Foxy.
	var p70=ContactShadow._p70("idle")
	if p70!=null:
		var hh=half*float(p70.get_height())/float(p70.get_width())
		canvas.draw_texture_rect(p70,Rect2(feet.x-half,feet.y+drop-hh,half*2,hh*2),false,Color(1,1,1,minf(1.0,alpha)))
		return
	canvas.draw_set_transform(feet+Vector2(0,drop),0,Vector2(1,squash))
	canvas.draw_texture_rect(ContactShadow.soft(),Rect2(-half,-half,half*2,half*2),false,Color(1,1,1,0.55*alpha))
	canvas.draw_set_transform(Vector2.ZERO)

## The piece's silhouette, blurred, drawn a little offset behind it.
var shadow_cache: Dictionary={}
const SHADOW_PAD=0.12
func paper_shadow(canvas: CanvasItem, name: String, rect: Rect2, offset: Vector2, alpha: float) -> void:
	# The same even, blurred silhouette as the UI pieces (exactly aligned:
	# the halo's padding is known), lit from the top left.
	var soft=ConceptScreen.soft_shadow(tex(name))
	if soft==null: return
	var r=ConceptScreen.shadow_rect(rect,soft)
	canvas.draw_texture_rect(soft,Rect2(r.position+offset,r.size),false,Color(1,1,1,alpha))
func blurred(name: String) -> Texture2D:
	if shadow_cache.has(name): return shadow_cache[name]
	var src: Image=tex(name).get_image()
	if src==null:
		shadow_cache[name]=null
		return null
	src=src.duplicate()
	if src.is_compressed(): src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var w=maxi(6,src.get_width()/8)
	var h=maxi(6,src.get_height()/8)
	src.resize(w,h,Image.INTERPOLATE_BILINEAR)
	var pw=int(round(w*SHADOW_PAD))
	var ph=int(round(h*SHADOW_PAD))
	var img=Image.create(w+pw*2,h+ph*2,false,Image.FORMAT_RGBA8)
	var ink=Color(0.16,0.1,0.06)
	for y in range(h):
		for x in range(w):
			img.set_pixel(x+pw,y+ph,Color(ink,src.get_pixel(x,y).a))
	# Blur: shrink and grow back twice (bilinear), cheap and soft.
	var full=img.get_size()
	for k in range(2):
		img.resize(maxi(2,full.x/3),maxi(2,full.y/3),Image.INTERPOLATE_BILINEAR)
		img.resize(full.x,full.y,Image.INTERPOLATE_BILINEAR)
	var t=ImageTexture.create_from_image(img)
	shadow_cache[name]=t
	return t

## Repeat a strip piece across [x0,x1], top of the walking surface at y.
func strip(canvas: CanvasItem, name: String, x0: float, x1: float, y: float, height: float, tint=Color.WHITE, shift=0.0) -> void:
	var texture=tex(name)
	var width=height*texture.get_width()/texture.get_height()
	var top=y-height*surface(name)
	# World-aligned phase: neighbouring surfaces continue the same pattern.
	var x=x0
	while x<x1-0.5:
		var phase=fposmod(x+shift,width)
		if width-phase<0.05: phase=0.0
		var w=minf(width-phase,x1-x)
		if w<0.05: break
		canvas.draw_texture_rect_region(texture,Rect2(x,top,w+0.4,height),Rect2(texture.get_width()*phase/width,0,texture.get_width()*w/width,texture.get_height()),tint)
		x+=w

## A room with a crank keeps its bridge raised until the wheel is turned.
func bridge_locked() -> bool:
	return room.has("crank") and not room.crank.id in game.world().opened

## Exits plus secret doors that have been opened.
func door_locked(exit: Dictionary) -> bool:
	return exit.has("lock") and not (exit.lock+"_used") in game.world().opened

func active_exits() -> Array:
	var out: Array=room.get("exits",[]).filter(func(e): return not e.has("gate") or gate_open(e.gate))
	for sd in room.get("secret_doors",[]):
		if sd.id in game.world().opened:
			out.append({"door":sd.door,"kind":"secret","to":sd.to,"spawn":sd.spawn,"label":sd.label})
	return out

## From the bag: get ready to put a crate down (Use becomes Place).
func start_placing() -> void:
	if game.world_crates_free()<=0: return
	placing=true
	status.emit("Walk to a spot and tap Place to put the crate down. Open the bag to keep it instead.")

## From the bag: eat a jump carrot, the next jump is a big one.
func use_carrot() -> void:
	if super_jump or not game.world_use_carrot(): return
	Sound.play("carrot")
	super_jump=true
	status.emit("Crunch! Your next jump is a big one.")

## Crates travel with you: leaving a room puts the crates you placed back in
## the bag, unless one is holding a pressure plate (a gate stays open).
func bring_crates_along() -> void:
	var keep=[]
	var placed: Array=game.world().placed.get(room_id,[])
	for plate in room.get("plates",[]):
		var r=Rect2(plate.rect[0],plate.rect[1]-30,plate.rect[2],plate.rect[3]+34)
		for i in placed.size():
			if r.has_point(Vector2(placed[i][0],placed[i][1]-2)): keep.append(i)
	var back=game.world_collect_crates(room_id,keep)
	if back>0: status.emit("%d crate%s came along in your bag."%[back,"" if back==1 else "s"])

## A plate gate is open while its plate is held, and for good once the room
## behind it has been visited (the cellar gate after the Treasure Vault).
func gate_open(id: String) -> bool:
	if id+"_open" in game.world().opened: return true
	return plate_gates.has(id) and plate_gates[id].open
func plate_pressed(plate: Dictionary) -> bool:
	if String(plate.opens)+"_open" in game.world().opened: return true
	var r=Rect2(plate.rect[0],plate.rect[1]-30,plate.rect[2],plate.rect[3]+34)
	for point in game.world().placed.get(room_id,[]):
		if r.has_point(Vector2(point[0],point[1]-2)): return true
	if not foxy_holding.is_empty() and foxy_holding.id==plate.id and is_instance_valid(companion) and r.has_point(companion.position): return true
	return is_instance_valid(player) and player.is_on_floor() and r.has_point(player.position)

func ground_y_at(x: float) -> float:
	var best=float(room.size[1])
	for ln in room.get("lines",[]):
		var pts: Array=ln.pts
		for i in range(pts.size()-1):
			if x>=float(pts[i][0]) and x<=float(pts[i+1][0]):
				var t=(x-float(pts[i][0]))/maxf(0.01,float(pts[i+1][0])-float(pts[i][0]))
				best=minf(best,lerpf(float(pts[i][1]),float(pts[i+1][1]),t))
	if room.has("lines"): return best
	for r in rects("ground"):
		if r.size.y>20 and x>=r.position.x and x<=r.end.x: best=minf(best,r.position.y)
	return best

func exposed(r: Rect2, side: float) -> bool:
	var probe=Vector2(r.position.x-2 if side<0 else r.end.x+2,r.position.y+6)
	for other in rects("ground"):
		if other!=r and other.size.y>20 and other.has_point(probe): return false
	return true

func draw_room(canvas: CanvasItem) -> void:
	var scenery: String=room.get("scenery","meadow")
	var tint=Color(0.62,0.68,0.9) if scenery=="cave" else (Color(0.85,0.86,0.9) if scenery=="tower" else Color.WHITE)
	# A60: painted backs of underground spaces (the burrow tunnel).
	for b in room.get("backs",[]):
		if has_piece(b.art): canvas.draw_texture_rect(tex(b.art),Rect2(b.rect[0],b.rect[1],b.rect[2],b.rect[3]),false)
	for lm in room.get("landmarks",[]): landmark(canvas,lm)
	if room.has("kit"): kit_fences(canvas)
	for rp in room.get("ramps",[]):
		if has_piece("mf_stair_step"):
			kit_stairs(canvas,rp)
			continue
		if not has_piece("mf_stairs"): continue
		var st=kt("mf_stairs")
		var w=absf(float(rp[2])-float(rp[0]))*1.15
		var h=w*st.get_height()/st.get_width()
		var low=maxf(float(rp[1]),float(rp[3]))
		var right_up=float(rp[3])<float(rp[1])
		var x=minf(float(rp[0]),float(rp[2]))-w*0.06
		canvas.draw_texture_rect(st,Rect2(x if right_up else x+w,low+3-h,w if right_up else -w,h),false)
	for w in room.get("waters",[]):
		if ArtStyle.paper: draw_paper_water(canvas,Rect2(w[0],w[1],w[2],w[3]))
		else: MeadowCrossingKit.draw_river(canvas,Rect2(w[0],w[1],w[2],w[3]))
	draw_water_motion(canvas)
	draw_fauna(canvas)
	decorate(canvas,scenery)
	var bridge=room.get("bridge",[])
	var index=0
	var kit_mode=room.has("kit")
	if room.has("painted"): kit_mode=true
	for r in rects("ground"):
		if room.has("painted"): break
		index+=1
		if kit_mode:
			kit_top(canvas,r,ground_style(r))
			continue
		if not bridge.is_empty() and r==Rect2(bridge[0],bridge[1],bridge[2],bridge[3]):
			# The bridge slides out from under the near bank across the river
			# (its planks travel with it), using only the bridge art.
			if ArtStyle.paper:
				# Double drawbridge: two halves hinged at each bank. Raised they
				# stand tilted up on their ropes (always visible, never vanish);
				# the wheel lowers them to meet over the river with a small bounce.
				var half=(r.size.x+12)*0.5
				var up=(1.0-bridge_progress)*deg_to_rad(58)
				var hl=Vector2(r.position.x-6,r.position.y)
				var hr=Vector2(r.end.x+6,r.position.y)
				var tip_l=hl+Vector2(cos(-up),sin(-up))*half
				var tip_r=hr+Vector2(-cos(-up),sin(-up))*half
				for side in [[hl,tip_l,1.0],[hr,tip_r,-1.0]]:
					var hinge: Vector2=side[0]
					var dir: float=side[2]
					# Rope post on the bank and the rope to the bridge tip.
					var post_top=hinge+Vector2(-dir*10,-74)
					canvas.draw_line(hinge+Vector2(-dir*10,2),post_top,Color("5a3a22"),5.0)
					canvas.draw_line(hinge+Vector2(-dir*10,2),post_top,Color("8a5a34"),3.0)
					canvas.draw_circle(post_top,4.0,Color("6b4428"))
					var tip: Vector2=side[1]+Vector2(0,-6)
					canvas.draw_line(post_top,tip,Color(0.25,0.16,0.08,0.9),2.4)
					canvas.draw_line(post_top,tip,Color("d9b77a"),1.2)
					canvas.draw_set_transform(hinge,-up*dir if dir>0 else PI+up,Vector2(1,1) if dir>0 else Vector2(1,-1))
					strip(canvas,"bridge",0,half,0,30)
					canvas.draw_set_transform(Vector2.ZERO)
			elif bridge_progress>0.01:
				var length=r.size.x+12
				strip(canvas,"bridge",r.position.x-6,r.position.x-6+length*bridge_progress,r.position.y,30,Color.WHITE,length*(1.0-bridge_progress))
		elif r.size.y<=20 and ground_style(r)=="log" and has_piece("log_bridge"):
			strip_piece(canvas,"log_bridge",r.position.x-8,r.end.x+8,r.position.y-5,22)
		elif ground_style(r) in ["under","set","fill"]:
			pass
		elif r.size.y<=20:
			var name="crystal_ledge" if scenery=="cave" else ("stone_ledge" if scenery=="tower" and index%2==0 else ("scaffold" if scenery=="tower" else ("float_big" if r.size.x>=110 else "float_small")))
			var texture=tex(name)
			# Wide ledges repeat the piece at its own size instead of stretching it.
			var count=maxi(1,int(round(r.size.x/130.0)))
			var seg=r.size.x/count
			for k in range(count):
				var width=seg*1.12
				var height=width*texture.get_height()/texture.get_width()
				canvas.draw_texture_rect(texture,Rect2(r.position.x+k*seg-seg*0.06,r.position.y-height*float(surface(name)),width,height),false,Color(0.82,0.78,0.76) if scenery=="tower" and ArtStyle.paper else Color.WHITE)
		else:
			# Earth body (TerrainFill), then the grassy top strip, then cliff ends.
			var lip="ground_top" if scenery=="meadow" else ("cave_ground" if ArtStyle.paper and scenery=="cave" else "stone")
			if room_id=="windmill_cellar" and ResourceLoader.exists(P31_ART+"ce_ground.png"): lip="ce_ground"
			if not env_dir().is_empty(): lip="ground_top"
			var lip_tint=Color.WHITE if ArtStyle.paper else (Color(0.5,0.56,0.82) if scenery=="cave" else tint)
			strip(canvas,lip,r.position.x,r.end.x,r.position.y,(40 if ResourceLoader.exists(P31_ART+"near.png") else 66) if lip=="ground_top" else 44,lip_tint)
			# Ivy stone cliffs: ivy hangs over their edges instead of the
			# meadow's grassy earth ends.
			if ground_style(r)=="cliff" and has_piece("ivy_hang"):
				for side in [-1.0,1.0]:
					if not exposed(r,side): continue
					var iv=tex("ivy_hang")
					var ih=minf(r.size.y*0.75,70.0)
					var iw=ih*iv.get_width()/iv.get_height()
					var ix=r.position.x-iw*0.35 if side<0 else r.end.x-iw*0.65
					canvas.draw_texture_rect(iv,Rect2(ix,r.position.y-4,iw,ih),false)
				continue
			for side in [-1.0,1.0]:
				if scenery=="meadow" and exposed(r,side):
					var cap="cap_left" if side<0 else "cap_right"
					var h=78.0
					var w=h*tex(cap).get_width()/tex(cap).get_height()
					var x=r.position.x-w*0.3 if side<0 else r.end.x-w*0.7
					canvas.draw_texture_rect(tex(cap),Rect2(x,r.position.y-h*surface(cap),w,h),false,tint)
	props(canvas)

## Tiling fills only (earth under the ground strips, the cave ceiling rock).
func draw_fills(canvas: CanvasItem) -> void:
	# A60: earth behind painted set pieces (no collision), so nothing of the
	# far background shows through their ragged edges.
	for b in room.get("backings",[]):
		var tile=String(b[4]) if b.size()>4 else "earth"
		if not has_piece(tile): continue
		canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.32)
		canvas.draw_texture_rect(tex(tile),Rect2(Vector2(b[0],b[1])/0.32,Vector2(b[2],b[3])/0.32),true)
		canvas.draw_set_transform(Vector2.ZERO)
	var scenery: String=room.get("scenery","meadow")
	var tint=Color(0.62,0.68,0.9) if scenery=="cave" else (Color(0.85,0.86,0.9) if scenery=="tower" else Color.WHITE)
	if room.has("painted"): return
	if room.has("kit"):
		for r in rects("ground"): kit_fill(canvas,r,ground_style(r))
		return
	for r in rects("ground"):
		if r.size.y<=20: continue
		var fill=Rect2(r.position.x,r.position.y+10,r.size.x,r.size.y-10)
		var gs=ground_style(r)
		if gs=="set": continue
		if ArtStyle.paper and gs in ["cliff","under"] and has_piece("cliff_fill"):
			var tile="cliff_fill" if gs=="cliff" else "roots_fill"
			if gs=="under": fill=Rect2(r.position,r.size)
			canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.34)
			canvas.draw_texture_rect(tex(tile),Rect2(fill.position/0.34,fill.size/0.34),true)
			canvas.draw_set_transform(Vector2.ZERO)
			continue
		var body="cave_wall" if scenery=="cave" else ("tower_wall" if scenery=="tower" else "earth")
		if ArtStyle.paper and body!="earth":
			# A57: the cave and tower fills are their own patterned paper tiles.
			var tile="earth" if not env_dir().is_empty() else "cave_fill" if scenery=="cave" else ("ce_fill" if room_id=="windmill_cellar" and ResourceLoader.exists(P31_ART+"ce_fill.png") else "stone_fill")
			if ResourceLoader.exists(P31_ART+tile+".png"):
				canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.3)
				canvas.draw_texture_rect(tex(tile),Rect2(fill.position/0.3,fill.size/0.3),true)
				canvas.draw_set_transform(Vector2.ZERO)
			else: canvas.draw_rect(fill,Color8(42,56,79)*tint)
			continue
		var k=0.32 if body=="earth" else 0.26
		canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*k)
		canvas.draw_texture_rect(tex(body),Rect2(fill.position/k,fill.size/k),true,tint if body=="earth" else Color(0.55,0.58,0.72) if scenery=="cave" else Color(0.7,0.7,0.74))
		canvas.draw_set_transform(Vector2.ZERO)
	if scenery=="cave" and room.has("ceiling"):
		var c=room.ceiling
		if ArtStyle.paper:
			if not env_dir().is_empty():
				# Kit rock above, with the torn edge hanging down (flipped top strip).
				canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.3)
				canvas.draw_texture_rect(tex("cave_fill"),Rect2(Vector2(c[0],c[1])/0.3,Vector2(c[2],c[3])/0.3),true)
				canvas.draw_set_transform(Vector2.ZERO)
				var t=tex("cave_ground")
				var th=40.0
				var tw=th*t.get_width()/t.get_height()
				var x=float(c[0])
				while x<c[0]+c[2]:
					canvas.draw_texture_rect(t,Rect2(x,c[1]+c[3]+th-6,tw+1,-th),false)
					x+=tw
				for i in range(int(c[2]/260)):
					var v=tex("cave_vines")
					var vh=70.0
					canvas.draw_texture_rect(v,Rect2(c[0]+130+i*260,c[1]+c[3]-4,vh*v.get_width()/v.get_height(),vh),false)
				return
			canvas.draw_rect(Rect2(c[0],c[1],c[2],c[3]+6),Color8(30,27,66))
			canvas.draw_rect(Rect2(c[0],c[1]+c[3]-4,c[2],10),Color8(52,48,104))
			return
		canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.38)
		canvas.draw_texture_rect(tex("cave_wall"),Rect2(Vector2(c[0],c[1])/0.38,Vector2(c[2],c[3]+6)/0.38),true,Color(0.42,0.46,0.66))
		canvas.draw_set_transform(Vector2.ZERO)

## Grounded decoration on the wide floors, deterministic per room.
func decorate(canvas: CanvasItem, scenery: String) -> void:
	var kinds=[["flower_bush",30.0],["boulder",24.0],["fence",22.0],["lamp",56.0]]
	# A55: no street lamps on the paper meadow (they did not belong there).
	if ArtStyle.paper: kinds=[["flower_bush",24.0],["boulder",22.0],["fern",22.0]]
	if scenery=="cave": kinds=[["crystals",34.0],["boulder",22.0]]
	if scenery=="tower": kinds=[["crate",26.0],["boulder",22.0]] if not ArtStyle.paper else [["crate",26.0]]
	var busy: Array[float]=[]
	for key in ["chests","signs"]:
		for entry in room.get(key,[]): busy.append(float(entry.pos[0]))
	for exit in room.get("exits",[]):
		if exit.has("door"): busy.append(float(exit.door[0]))
	if room.has("shrine"): busy.append(float(room.shrine.pos[0]))
	for r in rects("ground"):
		if r.size.y<=20: continue
		var x=r.position.x+70
		var i=int(r.position.x/37)
		while x<r.end.x-60:
			var clear=true
			for b in busy: clear=clear and absf(b-x)>60
			if clear:
				var kind=kinds[i%kinds.size()]
				piece(canvas,kind[0],Vector2(x,r.position.y+3),kind[1],Color(0.92,0.95,0.92) if scenery=="meadow" else Color(0.75,0.8,0.95),i%3==0)
			x+=150+float((i*53)%90)
			i+=1
	if scenery=="cave" and room.has("ceiling"):
		var c=room.ceiling
		var bottom=float(c[1]+c[3])
		# The rock ceiling itself is drawn by draw_fills (it tiles).
		# Rocky rim: the crystal ledge piece upside down, repeated along the edge.
		var rim=tex("crystal_ledge")
		var rh=34.0
		var rw=rh*rim.get_width()/rim.get_height()
		var x=float(c[0])-rw*0.3
		while x<float(c[0]+c[2]):
			canvas.draw_set_transform(Vector2(0,bottom*2+rh*0.35),0,Vector2(1,-1))
			canvas.draw_texture_rect(rim,Rect2(x,bottom-rh*0.65+rh*0.35-rh*0.35,rw,rh),false,Color(0.7,0.74,0.92))
			canvas.draw_set_transform(Vector2.ZERO)
			x+=rw*0.82
		for k in range(int(float(room.size[0])/240)):
			var vines=tex("cave_vines")
			var h=70.0
			var w=h*vines.get_width()/vines.get_height()
			canvas.draw_texture_rect(vines,Rect2(130+k*240-w*0.5,bottom-4,w,h),false,Color(0.82,0.88,1))
	if scenery=="tower":
		for k in range(int(float(room.size[1])/180)):
			piece(canvas,"lantern",Vector2(40 if k%2==0 else float(room.size[0])-40,120+k*180),44)

func landmark(canvas: CanvasItem, lm: Dictionary) -> void:
	if lm.kind=="sails":
		# Painted level: the windmill's lattice sails turn on its painted hub.
		var d=float(lm.d)
		canvas.draw_set_transform(Vector2(lm.pos[0],lm.pos[1]),0.0 if reduced_motion else elapsed*0.5,Vector2.ONE)
		canvas.draw_texture_rect(kt("mf_windmill_sails"),Rect2(-d*0.5,-d*0.5,d,d),false)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	if lm.kind=="mf_windmill":
		# P71a windmill on its hill, the lattice sails turning on the hub.
		var feet=Vector2(lm.pos[0],lm.pos[1]+3)
		piece(canvas,"mf_windmill",feet,float(lm.h),Color.WHITE,false,false,0.0,Vector2.ONE,false)
		var body=kt("mf_windmill")
		var w=float(lm.h)*body.get_width()/body.get_height()
		var hub=feet+Vector2((float(lm.get("hub",[0.42,0.2])[0])-0.5)*w,-float(lm.h)*(1.0-float(lm.get("hub",[0.42,0.2])[1])))
		var d=float(lm.h)*0.8
		canvas.draw_set_transform(hub,0.0 if reduced_motion else elapsed*0.5,Vector2.ONE)
		canvas.draw_texture_rect(kt("mf_windmill_sails"),Rect2(-d*0.5,-d*0.5,d,d),false)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	if lm.kind=="windmill" and lm.h>0:
		var feet=Vector2(lm.pos[0],lm.pos[1]+4)
		# A landmark stands back in the field: slightly hazy, behind the path.
		piece(canvas,"windmill",feet,lm.h,Color(0.9,0.93,1.0))
		var body=tex("windmill")
		var w=lm.h*body.get_width()/body.get_height()
		var hub=feet+Vector2(0,-lm.h*0.70)
		var sails=tex("windmill_sails")
		var d=lm.h*0.9
		var angle=0.0 if reduced_motion else elapsed*0.6
		canvas.draw_set_transform(hub,angle,Vector2.ONE)
		canvas.draw_texture_rect(sails,Rect2(-d*0.5,-d*0.5,d,d),false,Color(0.9,0.93,1.0))
		canvas.draw_set_transform(Vector2.ZERO)

## The Old Tower seen from outside: a whole round tower whose own doorway
## is the room exit (drawn instead of a separate door piece).
const TOWER_H=250.0
func draw_facade(canvas: CanvasItem, at: Array) -> void:
	var t=tex("tower_ext")
	var w=TOWER_H*t.get_width()/t.get_height()
	var base=Vector2(at[0],at[1]+10)
	canvas.draw_texture_rect(t,Rect2(base.x-w*0.5,base.y-TOWER_H,w,TOWER_H),false)

func props(canvas: CanvasItem) -> void:
	var opened: Array=game.world().opened
	if room.has("tower_facade"): draw_facade(canvas,room.tower_facade)
	var size=Vector2(room.size[0],room.size[1])
	for exit in room.get("exits",[]):
		if exit.get("kind","") in ["vault","vault_back"]:
			# The cellar gate draws itself; inside the vault the way back is
			# its own archway (P63).
			if exit.kind=="vault_back": piece(canvas,"vault_arch",Vector2(exit.door[0],exit.door[1]+2),96)
			continue
		if exit.has("door"):
			# Doorways built into their walls (tower interior and its locked top door).
			var kind="cave" if exit.kind=="cave" else "tower_arch_open"
			if exit.has("lock"): kind="tower_arch_locked" if door_locked(exit) else "tower_arch_unlocked"
			var facade: Array=room.get("tower_facade",[])
			# The tower drawing already has its doorway; no second door on top.
			if not (facade.size()==2 and absf(float(facade[0])-float(exit.door[0]))<4):
				piece(canvas,kind,Vector2(exit.door[0],exit.door[1]+2),72 if kind=="cave" else 86)
			pass
		elif exit.has("edge"):
			# A gate themed for the place it leads to, with its picture on top
			# (cottage = home, windmill = Meadow Fields, waves = River Crossing).
			var x=40.0 if exit.edge=="left" else size.x-40.0
			var y=ground_y_at(x)
			piece(canvas,GATES.get(exit.to,"gate_meadow"),Vector2(x,y+3),104)
	if room.has("crank"):
		var cp=Vector2(room.crank.pos[0],room.crank.pos[1])
		if ArtStyle.paper:
			# A wooden stand with the round wheel turning on its axle (fixes
			# sheet: the axle hole is 51% across, 12.6% down the stand).
			var sh=42.0
			piece(canvas,"crank_stand",cp+Vector2(0,2),sh)
			var st=tex("crank_stand")
			var axle=cp+Vector2(0,2)+Vector2((0.51-0.5)*sh*st.get_width()/st.get_height(),-sh*(1.0-0.126))
			var wheel=tex("crank_round")
			# The wheel art is a square centred on the hub (knob on the rim).
			var ws=34.0*382.0/340.0
			canvas.draw_set_transform(axle,crank_angle,Vector2.ONE)
			canvas.draw_texture_rect(wheel,Rect2(-Vector2(ws,ws)*0.5,Vector2(ws,ws)),false)
			canvas.draw_set_transform(Vector2.ZERO)
		else: MeadowCrossingKit.draw_crank(canvas,cp,crank_angle)
	var w_state=game.world()
	if room.has("basket") and not room.basket.id in w_state.opened:
		var bob=0.0 if reduced_motion else sin(elapsed*2.0)*1.5
		ArtStyle.draw_prop(canvas,"basket",Vector2(room.basket.pos[0],room.basket.pos[1]+bob),Vector2(28,29))
	if room.has("npc") and "picnic_done" in w_state.opened:
		ArtStyle.draw_picnic(canvas,Vector2(room.npc.pos[0]+46,room.npc.pos[1]),true)
	for sd in room.get("secret_doors",[]): draw_secret_door(canvas,sd)
	for lever in room.get("levers",[]):
		if String(lever.get("dig","")).is_empty() or lever.dig in w_state.dug:
			piece(canvas,"lever_on" if lever.opens in w_state.opened else "lever_off",Vector2(lever.pos[0],lever.pos[1]+3),30)
	for plate in room.get("plates",[]):
		var pr=Rect2(plate.rect[0],plate.rect[1],plate.rect[2],plate.rect[3])
		var art=tex("plate_down" if plate_pressed(plate) else "plate_up")
		var ph=pr.size.x*1.3*art.get_height()/art.get_width()
		canvas.draw_texture_rect(art,Rect2(pr.position.x-pr.size.x*0.15,pr.end.y-ph+3,pr.size.x*1.3,ph),false)
	for gid in plate_gates:
		var g=plate_gates[gid]
		var open_art="vault_arch" if room_id=="windmill_cellar" and has_piece("vault_arch") else "wall_open"
		piece(canvas,open_art if g.open else "wall_closed",Vector2(g.rect.get_center().x,g.rect.end.y+2),g.rect.size.y*(1.06 if g.open and open_art=="vault_arch" else 1.0))
	var lit: Array=game.world().lit
	var lanterns: Array=room.get("lanterns",[])
	for i in range(lanterns.size()):
		var on="%s:%d"%[room_id,i] in lit
		var feet=Vector2(lanterns[i][0],lanterns[i][1]+2)
		if ArtStyle.paper:
			# A55 checkpoint: a paper pennant that is raised when you arrive.
			piece(canvas,"flag_up" if on else "flag_down",feet,46)
			continue
		if on:
			# Soft steady glow; only the brightness flickers a little.
			var flick=0.0 if reduced_motion else 0.03*sin(elapsed*7.0+i*2.0)
			for ring in range(4):
				canvas.draw_circle(feet-Vector2(-9,40),10.0+ring*6.0,Color(1,0.82,0.4,0.07+flick))
		piece(canvas,"lantern_lit" if on else "lantern_unlit",feet,56)
	for t in room.get("thorns",[]):
		var r=hazard_rect(t)
		# A61: hazards look dangerous (red tips) and stand on the ground.
		var hz=hazard_art()
		if hz!="thorns" and not textures.has("@"+hz): textures["@"+hz]=ArtTexture.load_texture(P31_ART+hz+".png")
		var th: Texture2D=textures["@"+hz] if hz!="thorns" else tex("thorns")
		var h=20.0
		var seg=h*th.get_width()/th.get_height()
		var count=maxi(1,int(round(r.size.x/seg)))
		var step=r.size.x/count
		for k in range(count):
			canvas.draw_texture_rect(th,Rect2(r.position.x+k*step+(step-seg)*0.5,r.end.y-h+2,seg,h),false)
	for m in movers:
		var body: AnimatableBody2D=m.body
		var logs=tex("log_platform")
		var w=m.size.x*1.15
		var h=w*logs.get_height()/logs.get_width()
		canvas.draw_texture_rect(logs,Rect2(body.position.x-w*0.5,body.position.y-m.size.y*0.5-h*0.18,w,h),false)
	for c in crumbles:
		if c.gone>0: continue
		var r: Rect2=c.rect
		var shake=Vector2(sin(elapsed*60)*1.2,0) if c.timer>=0 and not reduced_motion else Vector2.ZERO
		var st=tex("crumble")
		var h=r.size.x*st.get_height()/st.get_width()
		canvas.draw_texture_rect(st,Rect2(r.position+shake-Vector2(0,h*0.15),Vector2(r.size.x,h)),false,Color(1,0.85,0.8) if c.timer>=0 else Color.WHITE)
	for sign in room.get("signs",[]):
		var feet=Vector2(sign.pos[0],sign.pos[1]+2)
		piece(canvas,"sign",feet,40)
		# A small painted hint symbol, centred on the board (measured in
		# sign.png: board centre at 51%/31%, ~9 px tall at this size).
		# The full hint shows when you Read the sign.
		# The paper hint badge (fixes sheet), centred on the board of the
		# signpost (board centre 53% across, 25% down the drawing).
		var badge=tex("sign_hint")
		var mark=11.0
		var sp=tex("sign")
		var bc=sign_board(sp)
		var sw=40.0*sp.get_width()/sp.get_height()
		var centre=feet-Vector2(0,2)+Vector2((bc.x-0.5)*sw,-40.0*(1.0-bc.y))
		canvas.draw_texture_rect(badge,Rect2(centre-Vector2.ONE*mark*0.5,Vector2.ONE*mark),false)
	for gate in room.get("gates",[]):
		if not game.has_ability(gate.ability):
			var r=Rect2(gate.rect[0],gate.rect[1],gate.rect[2],gate.rect[3])
			piece(canvas,"thorn_gate",Vector2(r.get_center().x,r.end.y+2),r.size.y)
	# The Sky Feather on its stand; once taken the stand stays, empty and
	# softly glowing, and the feather flies up into the bag.
	if room.has("shrine"):
		var at=Vector2(room.shrine.pos[0],room.shrine.pos[1]+2)
		if not game.has_ability(room.shrine.ability):
			var bob=0.0 if reduced_motion else sin(elapsed*2.2)*2.0
			piece(canvas,"shrine",at+Vector2(0,bob*0.3),56)
		else:
			piece(canvas,"shrine_empty",at,27)
			if elapsed<feather_until:
				var k=1.0-(feather_until-elapsed)/1.8
				var from=at+Vector2(0,-30)
				# Rise and hover over the stand, then fly to the bag button.
				var view=view_rect()
				var hover=from+Vector2(0,-36+sin(elapsed*6.0)*2.0)
				var to=Vector2(view.end.x-60,view.position.y+20)
				var p=from.lerp(hover,smoothstep(0.0,0.25,k)) if k<0.45 else hover.lerp(to,smoothstep(0.45,1.0,k))
				var feather_h=40.0 if k<0.45 else lerpf(40.0,16.0,(k-0.45)/0.55)
				if not reduced_motion: canvas.draw_circle(p+Vector2(0,-feather_h*0.5),feather_h*0.7,Color(0.7,0.95,1.0,0.25*(1.0-k)))
				piece(canvas,"sky_feather",p,feather_h,Color(1,1,1,1.0-maxf(0.0,k-0.8)*5.0))
	for chest in room.get("chests",[]):
		var open=chest.id in opened
		if chest.get("big",false):
			# P63: the big vault chest, overflowing with coins once open.
			piece(canvas,"vault_chest_open" if open else "vault_chest",Vector2(chest.pos[0],chest.pos[1]+2),72.0 if open else 48.0)
			if open and not opened_at.has(chest.id): piece(canvas,"propeller",Vector2(chest.pos[0]+4,chest.pos[1]-36),15)
		else: piece(canvas,"chest_open" if open else "chest",Vector2(chest.pos[0],chest.pos[1]+2),28)
		if opened_at.has(chest.id):
			var t=elapsed-float(opened_at[chest.id])
			if t<2.2:
				var lift=minf(t,0.6)/0.6
				piece(canvas,chest.part,Vector2(chest.pos[0],chest.pos[1]-30-lift*22),26)
	for dc in room.get("decor",[]):
		if dc.get("hang",false):
			# Hanging from the beams: the top of the piece at pos.
			var t=tex(dc.art)
			var hw=float(dc.h)*t.get_width()/t.get_height()
			canvas.draw_texture_rect(t,Rect2(dc.pos[0]-hw*0.5,dc.pos[1]-float(dc.h),hw,float(dc.h)),false)
		else: piece(canvas,dc.art,Vector2(dc.pos[0],dc.pos[1]+2),float(dc.h))
	for tr in room.get("treasures",[]):
		if tr.id in opened: continue
		var bob=0.0 if reduced_motion else sin(elapsed*2.4+float(tr.pos[0]))*1.5
		if not reduced_motion: canvas.draw_circle(Vector2(tr.pos[0],tr.pos[1]-float(tr.h)*0.5+bob),float(tr.h)*0.7,Color(1,0.9,0.5,0.12+0.06*sin(elapsed*3.0)))
		piece(canvas,tr.art,Vector2(tr.pos[0],tr.pos[1]+2+bob),float(tr.h))
	for point in game.world().placed.get(room_id,[]):
		piece(canvas,"crate",Vector2(point[0],point[1]+1),CRATE+2)
	for dig in room.get("digs",[]):
		if dig.id in game.world().dug:
			if popped.has(dig.id) and elapsed-float(popped[dig.id])<1.6:
				var t=minf(elapsed-float(popped[dig.id]),0.5)/0.5
				var at=Vector2(dig.pos[0],dig.pos[1]-14-t*24)
				var shown={"crate":"crate","key":"pickup_key","snack":"pickup_apple","carrot":"pickup_carrot"}
				if shown.has(dig.item): piece(canvas,shown[dig.item],at,18)
				elif dig.item!="lever": canvas.draw_texture_rect(ArtTexture.load_texture(PetUI.COIN_PATH),Rect2(at-Vector2(7,14),Vector2(14,14)),false)
			# The little hole stays where Foxy dug.
			piece(canvas,"dug_hole",Vector2(dig.pos[0],dig.pos[1]+2),8)
			continue
		# Foxy can smell it: a small mound and sparkle appear when she is close.
		if is_instance_valid(companion) and companion.position.distance_to(Vector2(dig.pos[0],dig.pos[1]))<smell_range():
			var base=Vector2(dig.pos[0],dig.pos[1]+2)
			var glint=not reduced_motion and int(elapsed*2.0+dig.pos[0])%3==0
			piece(canvas,"mound_glint" if glint else "mound",base,(14.0*166/113) if glint else 14.0)
			if not reduced_motion:
				for k in 2:
					var tw=fposmod(elapsed*0.8+k*0.5+dig.pos[0]*0.01,1.0)
					var sp=base+Vector2(-8+k*16,-14-tw*14)
					piece(canvas,"twinkle",sp,8.0*sin(tw*PI)+0.5,Color(1,1,1,sin(tw*PI)))
	# Bouncing marker over a door, cave or arch you can go through right now.
	if near.get("kind","")=="door" or near.get("kind","") in ["lever","chest","shrine"]:
		var target: Array=near.data.get("door",near.data.get("pos",[0,0]))
		var bob=0.0 if reduced_motion else absf(sin(elapsed*4.0))*5.0
		piece(canvas,"mark_down",Vector2(target[0],target[1]-(92 if near.kind=="door" else 42)-bob),16)
	# Ghost crate where Place would put it.
	if faces.interact[0]=="Place" and is_instance_valid(player):
		var spot=crate_spot()
		if spot!=Vector2.INF:
			var a=0.35+(0.0 if reduced_motion else 0.15*sin(elapsed*5.0))
			piece(canvas,"crate",spot+Vector2(0,1),CRATE+2,Color(1,1,1,a))
	for item in room.get("pickups",[]):
		if not pickup_visible(item): continue
		var bob=0.0 if reduced_motion else sin(elapsed*2.6+item.pos[0])*1.5
		var h=18.0 if item.kind in ["apple","fish"] else (26.0 if item.kind=="carrot" else 18.0)
		if item.kind=="carrot" and not reduced_motion: canvas.draw_circle(Vector2(item.pos[0],item.pos[1]-14),15,Color(1,0.85,0.3,0.15+0.1*sin(elapsed*4.0)))
		piece(canvas,"pickup_"+item.kind,Vector2(item.pos[0],item.pos[1]-2+bob),h)
	# Foxy found something: a bouncing "!" bubble over Foxy.
	if not found.is_empty() and is_instance_valid(companion):
		var hop=0.0 if reduced_motion else absf(sin(elapsed*5.0))*4.0
		piece(canvas,"mark_found",companion.position+Vector2(0,-28-hop),22)
	# Guide: on screen a bouncing arrow over the goal; off screen a golden
	# arrow at the screen edge with where it leads ("To Hidden Cave").
	if game.preferences().show_goal and is_instance_valid(player):
		var target=goal_target()
		if target!=Vector2.INF and target.distance_to(player.position)>60:
			var view=view_rect()
			var bob=0.0 if reduced_motion else sin(elapsed*4.0)*3.0
			if view.grow(-20).has_point(target):
				piece(canvas,"mark_down",target+Vector2(0,-62+bob),22)
			else:
				# A63: at the side of the screen the way leads, halfway up.
				var right=target.x>player.position.x
				var x=(view.end.x-26.0-bob) if right else (view.position.x+26.0+bob)
				var y=view.get_center().y
				piece(canvas,"mark_arrow",Vector2(x,y+12),26,Color.WHITE,not right,false,0.0,Vector2.ONE,false)
	draw_bits(canvas)
	# Double jump: a soft puff of air under the feet, fading out.
	if elapsed<boost_until:
		var k=1.0-(boost_until-elapsed)/0.35
		for i in range(5):
			var a=PI*(0.15+0.7*i/4.0)
			canvas.draw_circle(boost_at+Vector2(cos(a)*(6+k*14),sin(a)*3+k*4),3.5*(1.0-k)+1.0,Color(1,1,1,0.75*(1.0-k)))
	if not snack_icon.is_empty() and elapsed<snack_until and is_instance_valid(companion):
		var t=1.0-(snack_until-elapsed)/1.8
		var at=companion.position+Vector2(0,-30-t*10)
		canvas.draw_circle(at,11,Color(1,1,1,0.9))
		canvas.draw_texture_rect(CareArt.icon("food_"+snack_icon),Rect2(at-Vector2(8,8),Vector2(16,16)),false,Color(1,1,1,1.0-maxf(0,t-0.7)*3))
		if t<0.8 and int(elapsed*6)%2==0: canvas.draw_texture_rect(CareArt.icon("heart"),Rect2(at+Vector2(8,-14),Vector2(8,8)),false)
	var taken: Array=game.world().coins
	var coin=tex("coin") if ArtStyle.paper else ArtTexture.load_texture(PetUI.COIN_PATH)
	var coins: Array=room.get("coins",[])
	for i in range(coins.size()):
		if "%s:%d"%[room_id,i] in taken: continue
		var bob=0.0 if reduced_motion else sin(elapsed*2.4+i)*1.5
		if ArtStyle.paper: air_shadow(canvas,coin,Rect2(coins[i][0]-7,coins[i][1]-7+bob,14,14))
		canvas.draw_texture_rect(coin,Rect2(coins[i][0]-7,coins[i][1]-7+bob,14,14),false)

func dust(at: Vector2, count: int, spread=14.0) -> void:
	if reduced_motion: return
	for i in count:
		bits.append({"p":at+Vector2(randf_range(-spread,spread),randf_range(-3,2)),"v":Vector2(randf_range(-30,30),randf_range(-34,-8)),"life":0.0,"max":randf_range(0.45,0.8),"kind":"dust","size":randf_range(3.0,6.0)})
func sparkle(at: Vector2, count: int, color=Color("ffe27a")) -> void:
	if reduced_motion: return
	for i in count:
		var a=randf()*TAU
		bits.append({"p":at,"v":Vector2(cos(a),sin(a))*randf_range(40,90),"life":0.0,"max":randf_range(0.4,0.7),"kind":"spark","size":randf_range(2.0,3.5),"color":color})
## Paper scraps flutter out (bumps, hits, landings on paper).
func scraps(at: Vector2, count: int) -> void:
	if reduced_motion: return
	var colors=[Color("f4e6c8"),Color("e9a86b"),Color("8fc46a"),Color("d9c3a0")]
	for i in count:
		bits.append({"p":at+Vector2(randf_range(-6,6),randf_range(-6,2)),"v":Vector2(randf_range(-60,60),randf_range(-110,-40)),"life":0.0,"max":randf_range(0.7,1.1),"kind":"scrap","size":randf_range(2.5,4.5),"rot":randf()*TAU,"spin":randf_range(-9,9),"color":colors[i%colors.size()]})

## A crumbling stone tears like paper: it rips apart along a jagged line into
## two halves that tip over and fall, with scraps fluttering out.
func break_apart(r: Rect2) -> void:
	dust(r.get_center()+Vector2(0,r.size.y*0.5),8,r.size.x*0.4)
	if reduced_motion: return
	if ArtStyle.paper:
		var st=tex("crumble")
		var h=r.size.x*st.get_height()/st.get_width()
		var box=Rect2(r.position.x,r.position.y-h*0.15,r.size.x,h)
		# Jagged tear from top to bottom near the middle.
		var tear: Array[Vector2]=[]
		for i in 7:
			var f=i/6.0
			tear.append(Vector2(0.5+randf_range(-0.07,0.07),f))
		for side in [0,1]:
			var pts=PackedVector2Array()
			if side==0:
				pts.append(Vector2(0,0))
				for p in tear: pts.append(p)
				pts.append(Vector2(0,1))
			else:
				pts.append(Vector2(1,0))
				pts.append(Vector2(1,1))
				for k in range(tear.size()-1,-1,-1): pts.append(tear[k])
			var centre=box.position+box.size*Vector2(0.25 if side==0 else 0.75,0.5)
			bits.append({"p":centre,"v":Vector2(-40 if side==0 else 40,-60),"life":0.0,"max":1.3,"kind":"tear","uv":pts,"box":box,"origin":centre,"rot":0.0,"spin":-2.5 if side==0 else 2.5})
		scraps(box.get_center(),10)
		return
	var st=tex("crumble")
	var h=r.size.x*st.get_height()/st.get_width()
	for i in 4:
		var src=Rect2(st.get_width()*i/4.0,0,st.get_width()/4.0,st.get_height())
		var at=Vector2(r.position.x+r.size.x*(i+0.5)/4.0,r.position.y-h*0.15+h*0.5)
		bits.append({"p":at,"v":Vector2(randf_range(-30,30),randf_range(-60,-20)),"life":0.0,"max":1.4,"kind":"chunk","size":r.size.x/4.0,"h":h,"rot":0.0,"spin":randf_range(-5,5),"src":src})
func update_bits(delta: float) -> void:
	for b in bits:
		b.life+=delta
		b.p+=b.v*delta
		match b.kind:
			"chunk","tear","scrap":
				b.v.y+=(520 if b.kind!="scrap" else 160)*delta
				if b.kind=="scrap": b.v.x*=0.97
				b.rot+=b.spin*delta
			"dust": b.v*=0.9
			"spark": b.v*=0.88
	bits=bits.filter(func(b): return b.life<b.max)
func draw_bits(canvas: CanvasItem) -> void:
	for b in bits:
		var k=b.life/b.max
		match b.kind:
			"dust": canvas.draw_circle(b.p,b.size*(0.6+k),Color(0.93,0.88,0.76,0.55*(1.0-k)))
			"spark":
				var s=b.size*(1.0-k*0.5)
				var c: Color=b.color
				c.a=1.0-k
				canvas.draw_colored_polygon(PackedVector2Array([b.p+Vector2(0,-s*2),b.p+Vector2(s*0.5,0),b.p+Vector2(0,s*2),b.p+Vector2(-s*0.5,0)]),c)
				canvas.draw_colored_polygon(PackedVector2Array([b.p+Vector2(-s*2,0),b.p+Vector2(0,s*0.5),b.p+Vector2(s*2,0),b.p+Vector2(0,-s*0.5)]),c)
			"scrap":
				canvas.draw_set_transform(b.p,b.rot,Vector2(1,0.6+0.4*sin(b.life*14.0)))
				var c: Color=b.color
				c.a=1.0-maxf(0.0,k-0.6)*2.5
				canvas.draw_rect(Rect2(-b.size,-b.size*0.6,b.size*2,b.size*1.2),c)
				canvas.draw_set_transform(Vector2.ZERO)
			"tear":
				var box: Rect2=b.box
				var st=tex("crumble")
				var pts=PackedVector2Array()
				var uvs=PackedVector2Array()
				var rot=Transform2D(b.rot,b.p)
				for q in b.uv:
					uvs.append(q)
					pts.append(rot*(box.position+q*box.size-b.origin))
				canvas.draw_colored_polygon(pts,Color(1,1,1,1.0-maxf(0.0,k-0.7)*3.3),uvs,st)
			"chunk":
				canvas.draw_set_transform(b.p,b.rot,Vector2.ONE)
				canvas.draw_texture_rect_region(tex("crumble"),Rect2(-b.size*0.5,-b.h*0.5,b.size,b.h),b.src,Color(1,1,1,1.0-maxf(0.0,k-0.7)*3.3))
				canvas.draw_set_transform(Vector2.ZERO)

## The secret hillside door: the opening, with the paw slab sliding into the
## ground as it opens (and back up as it closes).
func draw_secret_door(canvas: CanvasItem, sd: Dictionary) -> void:
	var feet=Vector2(sd.door[0],sd.door[1]+2)
	if sd.has("art") and (has_piece(sd.art) or float(sd.get("h",70))<=0.0):
		# A60 (P71a): the sun gate swings open (closed / open drawings).
		var k2: float=door_open.get(sd.id,1.0 if sd.id in game.world().opened else 0.0)
		# h 0: the closed gate is part of the painted set piece; only the open
		# gate is drawn over it.
		if float(sd.get("h",70))<=0.0:
			if k2>0.5 and has_piece(sd.art+"_open"): piece(canvas,sd.art+"_open",feet,50.0,Color.WHITE,false,false,0.0,Vector2.ONE,false)
			return
		piece(canvas,sd.art+"_open" if k2>0.5 else sd.art,feet,float(sd.get("h",70)))
		return
	var t=tex("secret_open")
	var h=86.0
	var w=h*t.get_width()/t.get_height()
	var box=Rect2(feet-Vector2(w*0.5,h),Vector2(w,h))
	canvas.draw_texture_rect(t,box,false)
	var k: float=door_open.get(sd.id,1.0 if sd.id in game.world().opened else 0.0)
	if k>=0.999: return
	var slab=tex("secret_slab")
	var r=Rect2(box.position+Vector2(box.size.x*0.228,box.size.y*0.277),Vector2(box.size.x*0.556,box.size.y*0.679))
	r.position.y+=r.size.y*k
	# Only the part above the ground shows; the rest has sunk into the earth.
	var visible=clampf(feet.y-r.position.y,0.0,r.size.y)
	if visible<=0.5: return
	var src=Rect2(0,0,slab.get_width(),slab.get_height()*visible/r.size.y)
	var shake=Vector2(sin(elapsed*50)*0.8,0) if k>0.01 and k<0.99 and not reduced_motion else Vector2.ZERO
	canvas.draw_texture_rect_region(slab,Rect2(r.position+shake,Vector2(r.size.x,visible)),src)

func slide_secret_door(id: String, opening: bool, at: Vector2) -> void:
	door_open[id]=0.0 if opening else 1.0
	var t=create_tween()
	t.tween_method(func(v: float): door_open[id]=v,door_open[id],1.0 if opening else 0.0,0.0 if reduced_motion else 1.1).set_trans(Tween.TRANS_SINE)
	for i in 4: t.parallel().tween_callback(func(): dust(at,5,30.0)).set_delay(i*0.25)

## Foxy helps on its own: when you come near something hidden, Foxy runs to
## the spot, sits by it with a "!" and barks until you come and press Dig.
func foxy_discovers(delta: float) -> void:
	var dug: Array=game.world().dug
	# Walking on past it: Foxy lets it go and catches up (asks again next visit).
	if not found.is_empty() and (found.id in dug or player.position.distance_to(Vector2(found.pos[0],found.pos[1]))>100):
		if not found.id in dug: skipped.append(found.id)
		found={}
		companion.point_target=Vector2.INF
	if found.is_empty():
		if not game.pet_too_weak().is_empty() or companion.ability_target!=Vector2.INF or not foxy_holding.is_empty(): return
		var best=INF
		for d in room.get("digs",[]):
			if d.id in dug or d.id in skipped: continue
			var at=Vector2(d.pos[0],d.pos[1])
			var gap=absf(at.x-player.position.x)
			if gap<smell_range() and absf(at.y-player.position.y)<90 and gap<best:
				best=gap
				found=d
		if found.is_empty(): return
		var side=-1.0 if player.position.x<float(found.pos[0]) else 1.0
		companion.point_target=Vector2(float(found.pos[0])+side*16.0,float(found.pos[1]))
		found_yip=0.6
		status.emit("%s found something! Go to %s and press Dig."%[game.pet().name,game.pet().name])
	# A happy bark now and then while you are not there yet.
	if player.position.distance_to(Vector2(found.pos[0],found.pos[1]))>50:
		found_yip-=delta
		if found_yip<=0:
			found_yip=2.6
			Sound.play("fox_yip",0.1)
			Sound.play("ui_open",0.1,-10.0)

## Where the next goal is: in this room its own spot, otherwise the exit that
## leads there (shortest way through the rooms). INF when there is no goal.
func goal_target() -> Vector2:
	var goal: Dictionary=game.world_goal()
	if String(goal.get("room","")).is_empty(): return Vector2.INF
	if goal.room==room_id:
		goal_label="Goal"
		var at: Array=goal.get("at",[])
		return Vector2(at[0],at[1]) if at.size()==2 else Vector2.INF
	var rooms: Dictionary=GameState.world_data().rooms
	var opened: Array=game.world().opened
	var links=func(id: String) -> Array:
		var out=[]
		for e in rooms[id].exits: out.append(e.to)
		for sd in rooms[id].get("secret_doors",[]):
			if sd.id in opened: out.append(sd.to)
		return out
	# Breadth-first search for the first step toward the goal room.
	var first: Dictionary={}
	var queue=[]
	for to in links.call(room_id):
		if rooms.has(to) and not first.has(to):
			first[to]=to
			queue.append(to)
	while not queue.is_empty() and not first.has(goal.room):
		var here: String=queue.pop_front()
		for to in links.call(here):
			if rooms.has(to) and not first.has(to) and to!=room_id:
				first[to]=first[here]
				queue.append(to)
	if not first.has(goal.room): return Vector2.INF
	var step: String=first[goal.room]
	goal_label="To "+String(rooms[step].title)
	for e in active_exits():
		if e.to!=step: continue
		if e.has("door"): return Vector2(e.door[0],e.door[1])
		var x=40.0 if e.edge=="left" else float(room.size[0])-40.0
		return Vector2(x,ground_y_at(x))
	return Vector2.INF

## --- Play -------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	elapsed+=delta
	if not is_instance_valid(player) or transitioning: return
	var size=Vector2(room.size[0],room.size[1])
	var open_left=false
	var open_right=false
	for exit in room.get("exits",[]):
		if not exit.has("edge"): continue
		if exit.edge=="left": open_left=true
		if exit.edge=="right": open_right=true
		if (exit.edge=="left" and player.position.x<=10) or (exit.edge=="right" and player.position.x>=size.x-10):
			go(exit.to,exit.spawn)
			return
	# Walls only where there is no exit, so walking off an open edge always leaves.
	player.position.x=clampf(player.position.x,2.0 if open_left else 8.0,size.x-(2.0 if open_right else 8.0))
	# A safe point only where there is solid ground on both sides of the feet,
	# so coming back never lands on an edge that slides straight back in.
	if player.is_on_floor() and not on_moving_or_crumbling() and solid_at(player.position.x-18,player.position.y) and solid_at(player.position.x+18,player.position.y): safe_point=player.position
	if player.position.y>size.y+40 or in_water():
		recover_from_fall()
		return
	update_challenge(delta)
	keep_foxy_close(delta)
	collect_pickups()
	game.world_tick(delta)
	var weak=game.pet_too_weak()
	player.air_jumps=1 if game.has_ability("foxy_boost") and weak.is_empty() else 0
	collect_coins()
	if region_complete() and not "meadows_complete" in game.world().opened and game.world_finish():
		companion.react(Companion.State.CELEBRATE,2.0)
		Sound.play("fanfare",0.0)
		world_completed.emit()
	foxy_discovers(delta)
	update_bits(delta)
	find_near()
	if super_jump and Input.is_action_just_pressed("jump") and player.is_on_floor():
		super_jump=false
		player.velocity.y=-390.0
		Sound.play("super_jump",0.0)
	if Input.is_action_just_pressed("interact"): use()
	if Input.is_action_just_pressed("pet_ability"): sniff()


## Foxy never gets left behind: if far away or well below while the child
## stands somewhere, Foxy hops to the child's side.
func keep_foxy_close(delta: float) -> void:
	var gap=companion.position.distance_to(player.position)
	var below=companion.position.y>player.position.y+50
	if foxy_holding: return
	# Climbing (or about to climb) a ladder is not being left behind.
	if companion.climbing.size.y>0 or player.is_climbing() or companion.ladder_to_leader().size.y>0:
		lag_time=0.0
		return
	if player.is_on_floor() and (gap>150 or (below and gap>60)): lag_time+=delta
	else: lag_time=0.0
	if lag_time>0.8:
		lag_time=0.0
		dust(companion.position,6,8.0)
		companion.position=player.position-Vector2(22.0*player.art.facing,4)
		dust(companion.position,6,8.0)
		companion.velocity=Vector2(0,-120)
		companion.reset_physics_interpolation()
		companion.safe_trail.clear()
		companion.react(Companion.State.CELEBRATE,0.6)

func pickup_visible(item: Dictionary) -> bool:
	if item.get("regrow",false): return elapsed>=float(regrow_at.get(item.id,0.0))
	return not item.id in game.world().opened

func collect_pickups() -> void:
	var data=GameState.world_data()
	for item in room.get("pickups",[]):
		if not pickup_visible(item): continue
		if (player.position-Vector2(0,10)).distance_to(Vector2(item.pos[0],item.pos[1]-10))>20: continue
		var info: Dictionary=data.items[item.kind]
		match item.kind:
			"apple","fish":
				# Into the bag as a snack: give it to Foxy whenever you like.
				if game.world_pick_food(item.id,"apple" if item.kind=="apple" else "fish_treat"):
					companion.react(Companion.State.CELEBRATE,0.8)
					Sound.play("pickup")
					status.emit("%s in your bag! Open the bag to give it to %s."%[info.name,game.pet().name])
			"carrot":
				if game.world_add_carrot():
					regrow_at[item.id]=elapsed+20.0
					Sound.play("pickup")
					status.emit("Jump carrot in your bag (%d). Open the bag and tap it for one big jump."%game.world().carrots)
				elif not super_jump:
					regrow_at[item.id]=elapsed+20.0
					super_jump=true
					status.emit("Your bag is full of carrots, so you ate this one: your next jump is a big one!")
			"key":
				game.world_flag(item.id)
				Sound.play("key",0.0)
				ability_learned.emit("Golden key","You found a golden key! It must open a locked door somewhere... maybe at the top of the Old Tower.")
			"note":
				game.world_flag(item.id)
				Sound.play("pickup")
				ability_learned.emit("Clue",item.get("clue","A clue!"))

func in_water() -> bool:
	for w in room.get("waters",[]):
		if Rect2(w[0],w[1]+10,w[2],w[3]).has_point(player.position): return true
	return false

func on_moving_or_crumbling() -> bool:
	var feet=player.position+Vector2(0,2)
	for m in movers:
		if Rect2(m.body.position-m.size*0.5-Vector2(4,6),m.size+Vector2(8,10)).has_point(feet): return true
	for c in crumbles:
		if c.rect.grow(6).has_point(feet): return true
	return false

## Lose one heart. Knock back unless it was a fall (already moved to safety).
func hurt(message: String, knock=true, from_x=0.0) -> void:
	if elapsed<hurt_until: return
	hurt_until=elapsed+1.2
	Sound.play("hurt")
	Sound.play("child_ouch",0.08)
	# Gentle mode (Settings): bumps still push you back, but no heart is lost.
	if game.preferences().gentle:
		if knock:
			var away=-1.0 if from_x>player.position.x else 1.0
			player.velocity=Vector2(away*170,-210)
		status.emit(message)
		return
	hearts-=1
	hearts_changed.emit(hearts)
	if ArtStyle.paper: scraps(player.position+Vector2(0,-20),5)
	if knock:
		var dir=-1.0 if from_x>player.position.x else 1.0
		player.velocity=Vector2(dir*170,-210)
	if hearts<=0:
		respawn()
		return
	status.emit(message)

## Out of hearts: never jump to another room. Return to the lit lantern in
## this room, or to where you came in, with a short fade so it is clear.
## Ground (floor or ledge) right under this point?
func solid_at(x: float, y: float) -> bool:
	var bridge: Array=room.get("bridge",[])
	for r in rects("ground"):
		if not bridge.is_empty() and bridge_locked() and r==Rect2(bridge[0],bridge[1],bridge[2],bridge[3]): continue
		if x>=r.position.x and x<=r.end.x and absf(r.position.y-y)<3.0: return true
	for point in game.world().placed.get(room_id,[]):
		if absf(point[0]-x)<CRATE*0.5 and absf(point[1]-CRATE-y)<3.0: return true
	return false

## Fell in the water or off the bottom: one smooth splash, a short fade, and
## you stand back on safe ground (no repeated snapping back and forth).
func recover_from_fall() -> void:
	var wet=in_water()
	transitioning=true
	player.enabled=false
	player.velocity=Vector2.ZERO
	TouchControls.release_actions()
	if wet: Sound.play("splash")
	var back=func():
		player.reset_to(safe_point)
		companion.position=safe_point-Vector2(24,0)
		companion.reset_physics_interpolation()
		camera.snap_to_target()
	var done=func():
		player.enabled=true
		transitioning=false
		hurt_until=0.0
		hurt("Splash! Back on solid ground." if wet else "Oops! Back on solid ground.",false)
	if reduced_motion:
		back.call()
		done.call()
		return
	var tween=create_tween()
	tween.tween_property(fade,"color:a",0.85,0.22)
	tween.tween_callback(back)
	tween.tween_interval(0.15)
	tween.tween_property(fade,"color:a",0.0,0.3)
	tween.tween_callback(done)

func respawn() -> void:
	hearts=MAX_HEARTS
	hearts_changed.emit(hearts)
	var point=entry_point
	var lanterns: Array=room.get("lanterns",[])
	var lit: Array=game.world().lit
	var best=INF
	for i in range(lanterns.size()):
		var at=Vector2(lanterns[i][0],lanterns[i][1])
		if "%s:%d"%[room_id,i] in lit and absf(at.x-player.position.x)<best:
			best=absf(at.x-player.position.x)
			point=at
	var where="the lantern" if best<INF else "where you came in"
	Sound.play("heart",0.0)
	status.emit("Foxy helps you up! Back at %s, hearts full. You kept everything you found."%where)
	var move=func():
		player.reset_to(point)
		companion.position=point-Vector2(24,0)
		companion.reset_physics_interpolation()
		camera.snap_to_target()
	if reduced_motion:
		move.call()
		return
	transitioning=true
	var tween=create_tween()
	tween.tween_property(fade,"color:a",0.85,0.25)
	tween.tween_callback(move)
	tween.tween_interval(0.25)
	tween.tween_property(fade,"color:a",0.0,0.3)
	tween.tween_callback(func(): transitioning=false)

func update_challenge(delta: float) -> void:
	var body_point=player.position-Vector2(0,14)
	if elapsed>=hurt_until and not reduced_motion: player.art.modulate.a=1.0
	elif elapsed<hurt_until: player.art.modulate.a=0.45+0.45*float(int(elapsed*10)%2) if not reduced_motion else 0.7
	for t in room.get("thorns",[]):
		var hr=hazard_rect(t)
		if Rect2(hr.position.x,hr.end.y-14,hr.size.x,16).has_point(player.position): hurt("Ouch, thorns! Jump over them.",true,t[0]+t[2]*0.5)
	for c in critters:
		var spec: Dictionary=CRITTERS[c.kind]
		if c.dizzy>0:
			c.dizzy-=delta
			# Dizzy flyers drift down a little, then float back up.
			if spec.fly: c.cy=move_toward(c.cy,c.y+10,delta*20)
			continue
		var hop=0.0
		if c.kind=="frog":
			# Frogs hop: move only while in the air.
			var k=fposmod(elapsed+c.seed,1.6)
			if k<0.5:
				hop=sin(k/0.5*PI)*18.0
				c.x+=c.dir*spec.speed*3.2*delta
		else: c.x+=c.dir*spec.speed*delta
		if c.x>c.x1: c.dir=-1.0
		if c.x<c.x0: c.dir=1.0
		c.cy=c.y-hop+(sin(elapsed*2.2+c.seed)*14.0 if spec.fly else 0.0)
		# Contact box around the critter; landing on top is a bounce.
		var top=c.cy-spec.h
		if absf(player.position.x-c.x)<spec.h*0.7 and player.position.y>top-4 and player.position.y<c.cy+(38.0 if spec.fly else 2.0):
			if player.velocity.y>40 and player.position.y<top+spec.h*0.5:
				c.dizzy=3.0
				player.velocity.y=-240
				Sound.play("boing")
				if ArtStyle.paper: scraps(Vector2(c.x,c.cy-spec.h*0.6),6)
				status.emit(spec.stomp)
			else: hurt(spec.bump,true,c.x)
	for m in movers:
		var phase=0.5-0.5*cos(elapsed*TAU/m.period)
		m.body.position=m.base+m.to*phase
	for c in crumbles:
		if c.gone>0:
			c.gone-=delta
			if c.gone<=0: c.shape.set_deferred("disabled",false)
			continue
		var standing=player.is_on_floor() and c.rect.grow(4).has_point(player.position+Vector2(0,2))
		if standing and c.timer<0: c.timer=1.1
		if c.timer>=0:
			c.timer-=delta
			if c.timer<0:
				c.gone=2.6
				c.shape.set_deferred("disabled",true)
				break_apart(c.rect)
				Sound.play("crate_place",0.1)
	for plate in room.get("plates",[]):
		# Foxy helps by itself: when the child walks up to a button whose gate
		# is shut, Foxy hops on and holds it until the child heads back left,
		# well away from it (Come still calls it back at any time).
		var pr=Rect2(plate.rect[0],plate.rect[1],plate.rect[2],plate.rect[3])
		if plate_gates.has(plate.opens) and is_instance_valid(companion):
			if foxy_holding.is_empty() and elapsed>plate_auto_after and not plate_pressed(plate) and absf(player.position.x-pr.get_center().x)<70 and absf(player.position.y-pr.position.y)<40 and companion.ability_target==Vector2.INF:
				foxy_holding=plate
				companion.point_target=Vector2(pr.get_center().x,pr.position.y+6)
				Sound.play("fox_yip",0.05)
				status.emit("%s hops on the button and holds the gate open!"%game.pet().name)
			elif not foxy_holding.is_empty() and foxy_holding.id==plate.id and player.position.x<pr.position.x-260:
				foxy_holding={}
				companion.point_target=Vector2.INF
		if plate_gates.has(plate.opens):
			var g=plate_gates[plate.opens]
			var open=plate_pressed(plate)
			if open!=g.open:
				g.open=open
				Sound.play("rumble",0.0,-6.0)
				g.shape.set_deferred("disabled",open)
				if open: status.emit("The stone gate slides open!")
	var lanterns: Array=room.get("lanterns",[])
	for i in range(lanterns.size()):
		var at=Vector2(lanterns[i][0],lanterns[i][1])
		if player.position.distance_to(at)<30 and not "%s:%d"%[room_id,i] in game.world().lit:
			game.world_light(room_id,i,at)
			Sound.play("lantern",0.0)
			hearts=MAX_HEARTS
			hearts_changed.emit(hearts)
			game.world_rest(20.0)
			status.emit("Lantern lit! A little rest for %s, hearts refilled, and you come back here if you get hurt."%game.pet().name)

func collect_coins() -> void:
	for tr in room.get("treasures",[]):
		if player.position.distance_to(Vector2(tr.pos[0],tr.pos[1]))<26 and game.world_take_treasure(tr.id,int(tr.coins)):
			Sound.play("chest",0.06)
			sparkle(Vector2(tr.pos[0],tr.pos[1]-14),14)
			companion.react(Companion.State.CELEBRATE,1.0)
			status.emit("You found %s! (+%d coins)"%[tr.name,int(tr.coins)])
	var coins: Array=room.get("coins",[])
	var body=player.position-Vector2(0,15)
	for i in range(coins.size()):
		if body.distance_to(Vector2(coins[i][0],coins[i][1]))<16 and game.world_collect_coin(room_id,i):
			Sound.play("coin")
			sparkle(Vector2(coins[i][0],coins[i][1]),6)

func find_near() -> void:
	near={}
	var feet=player.position
	var w=game.world()
	for chest in room.get("chests",[]):
		if not chest.id in w.opened and feet.distance_to(Vector2(chest.pos[0],chest.pos[1]))<34: near={"kind":"chest","data":chest}
	for exit in active_exits():
		if exit.has("door") and feet.distance_to(Vector2(exit.door[0],exit.door[1]))<36: near={"kind":"door","data":exit}
	if room.has("npc") and feet.distance_to(Vector2(room.npc.pos[0],room.npc.pos[1]))<44: near={"kind":"npc","data":room.npc}
	if room.has("basket") and not room.basket.id in w.opened and feet.distance_to(Vector2(room.basket.pos[0],room.basket.pos[1]))<34: near={"kind":"basket","data":room.basket}
	if room.has("crank") and feet.distance_to(Vector2(room.crank.pos[0],room.crank.pos[1]))<36: near={"kind":"crank","data":room.crank}
	for lever in room.get("levers",[]):
		if lever.dig in w.dug and feet.distance_to(Vector2(lever.pos[0],lever.pos[1]))<34: near={"kind":"lever","data":lever}
	if room.has("shrine") and not game.has_ability(room.shrine.ability) and feet.distance_to(Vector2(room.shrine.pos[0],room.shrine.pos[1]))<42: near={"kind":"shrine","data":room.shrine}
	if near.is_empty():
		var placed: Array=w.placed.get(room_id,[])
		for i in range(placed.size()):
			if absf(feet.x-placed[i][0])<30 and absf(feet.y-placed[i][1])<30: near={"kind":"crate","index":i}
	if near.is_empty():
		for plate in room.get("plates",[]):
			var pr=Rect2(plate.rect[0],plate.rect[1],plate.rect[2],plate.rect[3])
			if absf(feet.x-pr.get_center().x)<60 and absf(feet.y-pr.position.y)<30: near={"kind":"plate","data":plate}
	if near.is_empty():
		for sign in room.get("signs",[]):
			if feet.distance_to(Vector2(sign.pos[0],sign.pos[1]))<44: near={"kind":"sign","data":sign}
	# The context button says exactly what Use will do here.
	var face=["Use","act_use"]
	match near.get("kind",""):
		"chest": face=["Open","act_open"]
		"door": face=["Open","act_open"] if door_locked(near.data) and near.data.lock in w.opened else (["Locked","act_enter"] if door_locked(near.data) else ["Enter","act_enter"])
		"shrine": face=["Touch","act_use"]
		"lever": face=["Pull","act_use"]
		"crank": face=["Lower","act_use"] if bridge_locked() else ["Raise","act_use"]
		"npc": face=["Talk","act_read"]
		"basket": face=["Take","act_pick"]
		"crate": face=["Pick up","act_pick"]
		"sign": face=["Read","act_read"]
		"plate": face=["Come","act_use"] if not foxy_holding.is_empty() else ["Sit","act_use"]
		_:
			if placing and game.world_crates_free()>0 and player.is_on_floor(): face=["Place","act_place"]
	faces.interact=face
	faces.pet_ability=["Dig","act_dig"] if dig_spot()!={} else ["Find","act_find"]
	var line=""
	match near.get("kind",""):
		"chest": line="Open the treasure chest!"
		"door":
			if door_locked(near.data): line="Unlock the door with the golden key!" if near.data.lock in w.opened else "Locked! A golden key must be hidden somewhere..."
			else: line="Enter: "+near.data.label
		"shrine": line="The Sky Feather! Touch it to take it: Foxy learns Double Jump."
		"lever": line="Pull the lever to close the secret wall again." if near.data.opens in w.opened else "An old lever! Pull it."
		"crank": line="Turn the wheel to lower the bridge!" if bridge_locked() else "Turn the wheel to raise the bridge again."
		"npc": line="Moss the bunny. Talk to Moss!"
		"basket": line="Moss's picnic basket! Take it."
		"crate": line="Pick up the crate to put it back in your bag."
		"sign": line=sign_text(near.data)
		"plate": line="Tap Come to call %s back."%game.pet().name if not foxy_holding.is_empty() else "Tap Sit: %s sits on the button and holds the gate open for you!"%game.pet().name
	if line.is_empty():
		if dig_spot()!={}: line="Foxy smells something here! Press Dig."
		for gate in room.get("gates",[]):
			if not game.has_ability(gate.ability) and absf(feet.x-gate.rect[0])<90: line=gate.text
		for exit in room.get("exits",[]):
			if exit.has("edge") and ((exit.edge=="left" and feet.x<140) or (exit.edge=="right" and feet.x>float(room.size[0])-140)):
				line="Path home" if exit.to=="home" else "Path to "+exit.label
		if room.has("boost_hint") and not game.has_ability("foxy_boost") and feet.x>room.boost_hint[0] and feet.x<room.boost_hint[1]:
			line="The glowing paw marks a Boost jump! Foxy learns Boost in the Hidden Cave." if room_id=="meadow_fields" else "Too high to jump. Something in the Hidden Cave can help!"
	if line.is_empty() and not found.is_empty(): line="%s found something! Go to the ! and press Dig."%game.pet().name
	if line.is_empty(): line=objective()
	prompt=line

## A51: an older Foxy with a strong bond smells from farther and digs faster.
const SMELL={"baby":120.0,"child":150.0,"teen":190.0,"adult":230.0}
const DIG_TIME={"baby":1.1,"child":0.9,"teen":0.7,"adult":0.6}
func smell_range() -> float:
	return SMELL.get(game.pet().growth_stage,150.0)+minf(60.0,float(game.pet().bond_xp)*0.3)

## The undug spot Foxy is close enough to dig (within reach of the child).
func dig_spot() -> Dictionary:
	for dig in room.get("digs",[]):
		if not dig.id in game.world().dug and player.position.distance_to(Vector2(dig.pos[0],dig.pos[1]))<46: return dig
	return {}

func region_complete() -> bool:
	var w=game.world()
	if not "picnic_done" in w.opened: return false
	for r in GameState.world_data().rooms.values():
		for chest in r.get("chests",[]):
			if chest.part.begins_with("robot_") and not chest.id in w.opened: return false
	return true

## Signs can change once you have what they hint at (e.g. the Sky Feather).
func sign_text(sign: Dictionary) -> String:
	var after: Dictionary=sign.get("after",{})
	if not after.is_empty() and game.has_ability(after.ability): return after.text
	return sign.text

func objective() -> String:
	if room.get("challenge",false): return "Challenge room: reach the treasure at the end!"
	if not "picnic_asked" in game.world().opened and room_id=="meadow_fields": return "Moss the bunny looks worried. Go and talk to Moss."
	return String(game.world_goal().text)+"."

func use() -> void:
	match near.get("kind",""):
		"chest":
			var chest=near.data
			if game.world_open_chest(chest.id,chest.part,int(chest.get("coins",0))):
				opened_at[chest.id]=elapsed
				Sound.play("chest",0.0)
				sparkle(Vector2(chest.pos[0],chest.pos[1]-20),16 if not chest.get("big",false) else 40)
				companion.react(Companion.State.CELEBRATE)
				status.emit("You found a toy part: %s! (+%d coins)"%[GameState.world_data().parts[chest.part],10+int(chest.get("coins",0))])
				found_item.emit(chest.part)
		"door":
			if door_locked(near.data):
				if near.data.lock in game.world().opened and game.world_flag(near.data.lock+"_used"):
					companion.react(Companion.State.CELEBRATE)
					Sound.play("key",0.0)
					status.emit("Click! The golden key opens the door.")
				else:
					Sound.play("ui_error")
					status.emit("Locked! Find the golden key first.")
			else:
				Sound.play("ui_open",0.0,-4.0)
				go(near.data.to,near.data.spawn)
		"npc": talk_to_moss()
		"basket":
			if game.world_flag("picnic_basket"):
				Sound.play("pickup",0.0)
				companion.react(Companion.State.CELEBRATE)
				status.emit(GameState.world_data().quest.steps.carry)
		"crank":
			if not bridge_locked():
				if game.world_unflag(near.data.id):
					if is_instance_valid(bridge_body): bridge_body.queue_free()
					Sound.play("crank",0.0)
					Sound.play("bridge",0.0)
					var up=create_tween()
					up.tween_property(self,"bridge_progress",0.0,0.0 if reduced_motion else 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					up.parallel().tween_property(self,"crank_angle",crank_angle-TAU*2.0,0.0 if reduced_motion else 1.2)
					status.emit("Creak... the bridge goes back up.")
			elif game.world_flag(near.data.id):
				var r=Rect2(room.bridge[0],room.bridge[1],room.bridge[2],room.bridge[3])
				bridge_body=collider(r,false)
				Sound.play("crank",0.0)
				Sound.play("bridge",0.0)
				var t=create_tween()
				t.tween_property(self,"bridge_progress",1.0,0.0 if reduced_motion else 1.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				t.parallel().tween_property(self,"crank_angle",crank_angle+TAU*2.0,0.0 if reduced_motion else 1.4)
				companion.react(Companion.State.CELEBRATE)
				status.emit("Creak, creak... the bridge comes down!")
		"lever":
			# Levers work both ways: pull again to close the wall.
			if near.data.opens in game.world().opened:
				if game.world_unflag(near.data.opens):
					for sd in room.get("secret_doors",[]):
						if sd.id==near.data.opens: slide_secret_door(sd.id,false,Vector2(sd.door[0],sd.door[1]))
					Sound.play("lever")
					Sound.play("rumble",0.0)
					status.emit("Rumble... the secret wall slides shut. Pull again to open it.")
			elif game.world_flag(near.data.opens):
				for sd in room.get("secret_doors",[]):
					if sd.id==near.data.opens: slide_secret_door(sd.id,true,Vector2(sd.door[0],sd.door[1]))
				Sound.play("lever")
				Sound.play("rumble",0.0)
				companion.react(Companion.State.CELEBRATE)
				status.emit("Rumble... a secret wall slid open by the windmill!")
		"crate":
			if game.world_pick_crate(room_id,near.index):
				Sound.play("crate_pick")
				build_crates()
				status.emit("Crate back in your bag (%d ready). Place it in any room."%game.world_crates_free())
		"plate":
			if foxy_holding.is_empty():
				foxy_holding=near.data
				var pr=Rect2(near.data.rect[0],near.data.rect[1],near.data.rect[2],near.data.rect[3])
				companion.point_target=Vector2(pr.get_center().x,pr.position.y+6)
				Sound.play("fox_yip",0.05)
				status.emit("Good %s! It sits on the button and holds the gate open."%game.pet().name)
			else:
				foxy_holding={}
				companion.point_target=Vector2.INF
				# Called back: it does not hop on again by itself straight away.
				plate_auto_after=elapsed+6.0
				Sound.play("fox_happy",0.05)
				status.emit("%s comes running back to you."%game.pet().name)
		"sign":
			Sound.play("ui_open")
			status.emit(sign_text(near.data))
		"":
			if placing and game.world_crates_free()>0: place_crate()
		"shrine":
			var ability: String=near.data.ability
			if not game.has_ability(ability) and game.world_learn(ability):
				player.air_jumps=1
				feather_until=elapsed+1.8
				companion.react(Companion.State.CELEBRATE)
				Sound.play("ability",0.0)
				status.emit("The Sky Feather is in your bag!")
				var info=GameState.world_data().abilities[ability]
				# Let the feather fly to the child first, then explain the ability.
				get_tree().create_timer(0.0 if reduced_motion else 1.9).timeout.connect(func(): ability_learned.emit(info.title,info.text))

## Foxy points the way to the nearest unopened chest in this room.
func sniff() -> void:
	var weak=game.pet_too_weak()
	if not weak.is_empty():
		companion.react(Companion.State.WAIT)
		status.emit("%s is too %s to help. Give a snack from your bag, or rest at home."%[game.pet().name,"hungry" if weak=="hungry" else "sleepy"])
		return
	var spot=dig_spot()
	if spot!={}:
		dig(spot)
		return
	var opened: Array=game.world().opened
	var best=Vector2.INF
	for chest in room.get("chests",[]):
		var at=Vector2(chest.pos[0],chest.pos[1])
		if not chest.id in opened and (best==Vector2.INF or at.distance_to(player.position)<best.distance_to(player.position)): best=at
	companion.react(Companion.State.INVESTIGATE)
	Sound.play("fox_sniff")
	if best==Vector2.INF:
		status.emit("Foxy sniffs around... nothing hidden here.")
		return
	var way="to the right" if best.x>player.position.x+20 else ("to the left" if best.x<player.position.x-20 else "close by")
	if best.y<player.position.y-40: way+=", up high"
	status.emit("Foxy smells treasure "+way+"!")

func talk_to_moss() -> void:
	var w=game.world()
	var steps: Dictionary=GameState.world_data().quest.steps
	if is_instance_valid(moss): moss.react("wave",1.6)
	if "picnic_done" in w.opened:
		status.emit("Moss: Thank you again! Come back for another picnic any time.")
	elif "picnic_basket" in w.opened:
		if game.world_finish_picnic():
			if is_instance_valid(moss): moss.react("happy",2.5)
			companion.react(Companion.State.CELEBRATE)
			ability_learned.emit("Picnic time!",steps.done)
	else:
		game.world_flag("picnic_asked")
		ability_learned.emit("The Lost Picnic",steps.ask)

## Snack from the bag: Foxy eats it right here, with a little food bubble.
var snack_icon=""
var snack_until=0.0
var boost_at=Vector2.ZERO
var boost_until=0.0
var feather_until=0.0
## Foxy's own discovery: the dig spot it is pointing at (empty: none).
var found: Dictionary={}
var found_yip=0.0
var goal_label=""
## Foxy sitting on a pressure plate to hold its gate open (plate dictionary).
var foxy_holding: Dictionary={}
## A journey goal was just reached (part id, "picnic", "foxy_boost", ...).
signal found_item(id: String)
## P66: every main goal done (rewards already saved).
signal world_completed
var plate_auto_after=0.0
## Finds you walked past in this room visit (Foxy won't stop for them again).
var skipped: Array=[]
## Little effects: dust puffs, sparkles, falling stone chunks.
## Each: {p,v,life,max,kind,size,rot,spin,src}
var bits: Array[Dictionary]=[]
## Secret doors: 0 closed .. 1 open (slides the slab into the ground).
var door_open: Dictionary={}
func give_snack(id: String) -> void:
	var taste=game.food_taste(id)
	if not game.feed_food(id): return
	Sound.play("fox_eat")
	snack_icon=id
	snack_until=elapsed+1.8
	companion.react(Companion.State.CELEBRATE,1.4)
	var name: String=game.pet().name
	status.emit("%s loved it! More energy for exploring."%name if taste!="dislike" else "%s ate it... not a favourite, but it helps."%name)

func dig(spot: Dictionary) -> void:
	var at=Vector2(spot.pos[0],spot.pos[1])
	companion.ability_target=at+Vector2(-14 if companion.position.x<at.x else 14,0)
	companion.react(Companion.State.ABILITY,1.2)
	Sound.play("fox_dig")
	await get_tree().create_timer(DIG_TIME.get(game.pet().growth_stage,0.9)).timeout
	if not is_instance_valid(companion): return
	companion.ability_target=Vector2.INF
	if game.world_dig(spot.id,spot.item):
		popped[spot.id]=elapsed
		dust(at,10,12.0)
		sparkle(at+Vector2(0,-10),10)
		Sound.play("pickup" if spot.item=="crate" else "coins_many")
		if spot.item=="crate" and not "crate_help" in game.world().opened:
			game.world_flag("crate_help")
			ability_learned.emit("Crate","The crate is in your bag. When you need to reach higher, open the bag and tap Place a crate, then tap Place where you want it. Stand next to it and tap Pick up to put it back.")
		if spot.item=="key":
			Sound.play("key",0.0)
			ability_learned.emit("Golden key","%s dug up a golden key! It opens the locked door at the top of the Old Tower."%game.pet().name)
		var said={"crate":"Foxy dug up a crate! It's in your bag.","lever":"Foxy dug up an old lever! Try pulling it.","key":"The golden key is yours!","snack":"Foxy dug up an apple! It's in your bag.","carrot":"Foxy dug up a jump carrot! It's in your bag."}
		status.emit(said.get(spot.item,"Foxy dug up 5 coins!"))

## Put a crate on the ground in front of the child (or on another crate).
func crate_spot() -> Vector2:
	var x=player.position.x+player.art.facing*26
	var top=INF
	if room.has("lines"): top=ground_below(x,player.position.y-2)
	else:
		for r in rects("ground"):
			if x>=r.position.x+4 and x<=r.end.x-4 and r.position.y>=player.position.y-2 and r.position.y<top: top=r.position.y
	for point in game.world().placed.get(room_id,[]):
		if absf(point[0]-x)<CRATE and absf(point[1]-player.position.y)<CRATE+4 and point[1]-CRATE<top: top=point[1]-CRATE
	if top==INF or top>player.position.y+40: return Vector2.INF
	return Vector2(x,top)

func place_crate() -> void:
	var x=player.position.x+player.art.facing*26
	var top=INF
	if room.has("lines"): top=ground_below(x,player.position.y-2)
	else:
		for r in rects("ground"):
			if x>=r.position.x+4 and x<=r.end.x-4 and r.position.y>=player.position.y-2 and r.position.y<top: top=r.position.y
	for point in game.world().placed.get(room_id,[]):
		if absf(point[0]-x)<CRATE and point[1]-CRATE>=player.position.y-2-CRATE and point[1]-CRATE<top and absf(point[1]-player.position.y)<CRATE+4: top=point[1]-CRATE
	if top==INF or top>player.position.y+40:
		status.emit("There's no ground there for a crate.")
		return
	for point in game.world().placed.get(room_id,[]):
		if absf(point[0]-x)<CRATE*0.8 and absf(point[1]-top)<2:
			status.emit("Something is already there.")
			return
	if game.world_place_crate(room_id,Vector2(x,top)):
		placing=false
		Sound.play("crate_place")
		build_crates()
		status.emit("Crate placed. Jump on it! Stand next to it and tap Pick up to put it back in your bag.")

func go(to: String, spawn: String) -> void:
	if to=="home":
		left_world.emit()
		return
	transitioning=true
	TouchControls.release_actions()
	if reduced_motion:
		enter(to,spawn)
		transitioning=false
		return
	var tween=create_tween()
	tween.tween_property(fade,"color:a",1.0,0.3)
	tween.tween_callback(func(): enter(to,spawn))
	tween.tween_interval(0.35)
	tween.tween_property(fade,"color:a",0.0,0.35)
	tween.tween_callback(func(): transitioning=false)
